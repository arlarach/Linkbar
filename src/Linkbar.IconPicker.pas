{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   Icon picker: modern icons (Windows symbol font on   }
{   a colored tile), PNG/ICO files or classic Windows   }
{   icons (Arlarach)                                    }
{*******************************************************}

unit Linkbar.IconPicker;

{$i linkbar.inc}

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes, System.Types, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Dialogs;

{ Icon spec stored in the settings:
    ''                    automatic (decided by the caller)
    'glyph:E80F:#0078D7'  modern icon: symbol E80F on a tile of that color
    'C:\x\icon.png'       PNG image
    'C:\x\file.ico'       ICO file
    'C:\x\file.dll,3'     icon 3 of an .exe/.dll }

  function IsGlyphSpec(const ASpec: string): Boolean;
  { Big and small icons for a spec (the caller destroys them). False = none }
  function IconsFromSpec(const ASpec: string; out ABig, ASmall: HICON): Boolean;
  { Short text for the settings window }
  function DescribeIconSpec(const ASpec: string): string;
  { Picker dialog. True = the user chose an icon (ASpec changed) }
  function PickIcon(AOwner: TComponent; var ASpec: string): Boolean;

implementation

uses
  System.Math, Winapi.ShellAPI,
  GdiPlus, Linkbar.Actions, Linkbar.TaskbarButton, Linkbar.L10n;

type
  TGlyphInfo = record
    Code: Word;
    Name: string;
  end;

const
  // Symbols of "Segoe MDL2 Assets" (Windows 10 and 11)
  GLYPHS: array[0..35] of TGlyphInfo = (
    (Code: $E80F; Name: 'Home'),       (Code: $E821; Name: 'Work'),
    (Code: $E8B7; Name: 'Folder'),     (Code: $E8A5; Name: 'Document'),
    (Code: $E943; Name: 'Code'),       (Code: $E90F; Name: 'Tools'),
    (Code: $E713; Name: 'Settings'),   (Code: $E7FC; Name: 'Games'),
    (Code: $E8D6; Name: 'Music'),      (Code: $E714; Name: 'Video'),
    (Code: $E722; Name: 'Camera'),     (Code: $E715; Name: 'Mail'),
    (Code: $E8BD; Name: 'Messages'),   (Code: $E8F2; Name: 'Chat'),
    (Code: $E774; Name: 'Internet'),   (Code: $E753; Name: 'Cloud'),
    (Code: $E896; Name: 'Downloads'),  (Code: $E72D; Name: 'Share'),
    (Code: $E787; Name: 'Calendar'),   (Code: $E81C; Name: 'History'),
    (Code: $E716; Name: 'People'),     (Code: $E77B; Name: 'Contact'),
    (Code: $E7BE; Name: 'Education'),  (Code: $E8F1; Name: 'Library'),
    (Code: $E719; Name: 'Shop'),       (Code: $E825; Name: 'Bank'),
    (Code: $E8C7; Name: 'Card'),       (Code: $E9D9; Name: 'Monitor'),
    (Code: $E7F4; Name: 'Screen'),     (Code: $E72E; Name: 'Lock'),
    (Code: $E734; Name: 'Star'),       (Code: $EB51; Name: 'Heart'),
    (Code: $E945; Name: 'Lightning'),  (Code: $EA86; Name: 'Puzzle'),
    (Code: $E707; Name: 'Place'),      (Code: $E80A; Name: 'Apps'));

  // Tile colors (TColor = $00BBGGRR)
  COLORS: array[0..9] of TColor = (
    $00D77800,  // blue
    $00BC9900,  // teal
    $00107C10,  // green
    $0000B9FF,  // yellow
    $000C63F7,  // orange
    $001C2BC4,  // red
    $008C00E3,  // pink
    $00981788,  // purple
    $007E7969,  // gray
    $00202020); // black

  GLYPH_PREFIX = 'glyph:';

{ ---------- spec ---------- }

function IsGlyphSpec(const ASpec: string): Boolean;
begin
  Result := SameText(Copy(ASpec, 1, Length(GLYPH_PREFIX)), GLYPH_PREFIX);
end;

function ParseGlyphSpec(const ASpec: string; out AGlyph: Word; out AColor: TColor): Boolean;
var parts: TArray<string>;
    v: Integer;
    s: string;
begin
  Result := False;
  AGlyph := 0;
  AColor := COLORS[0];
  if not IsGlyphSpec(ASpec) then Exit;
  parts := Copy(ASpec, Length(GLYPH_PREFIX) + 1, MaxInt).Split([':']);
  if (Length(parts) < 1) or not TryStrToInt('$' + parts[0], v) then Exit;
  AGlyph := Word(v);
  if (Length(parts) >= 2)
  then begin
    s := parts[1];
    if (s <> '') and (s[1] = '#') then Delete(s, 1, 1);
    if (Length(s) = 6) and TryStrToInt('$' + s, v)
    then AColor := TColor(RGB((v shr 16) and $FF, (v shr 8) and $FF, v and $FF));
  end;
  Result := True;
end;

function MakeGlyphSpec(AGlyph: Word; AColor: TColor): string;
var c: Cardinal;
begin
  c := ColorToRGB(AColor);
  Result := Format('%s%.4X:#%.2X%.2X%.2X', [GLYPH_PREFIX, AGlyph, GetRValue(c), GetGValue(c), GetBValue(c)]);
end;

function GlyphBitmap(AGlyph: Word; AColor: TColor; ASize: Integer): HBITMAP;
var data: TActionData;
begin
  data.Clear;
  data.Glyph := AGlyph;
  data.Color := AColor;
  Result := CreateActionIcon(data, ASize);
end;

{ PNG (or any image GDI+ reads) scaled into a square premultiplied bitmap }
function ImageFileBitmap(const AFileName: string; ASize: Integer): HBITMAP;
var
  bmi: TBitmapInfo;
  bits: Pointer;
  dst: IGPBitmap;
  img: IGPImage;
  g: IGPGraphics;
  w, h: Single;
  scale: Single;
begin
  Result := 0;
  FillChar(bmi, SizeOf(bmi), 0);
  bmi.bmiHeader.biSize := SizeOf(bmi.bmiHeader);
  bmi.bmiHeader.biWidth := ASize;
  bmi.bmiHeader.biHeight := -ASize;
  bmi.bmiHeader.biPlanes := 1;
  bmi.bmiHeader.biBitCount := 32;
  bmi.bmiHeader.biCompression := BI_RGB;
  bits := nil;
  Result := CreateDIBSection(0, bmi, DIB_RGB_COLORS, bits, 0, 0);
  if (Result = 0) or (bits = nil) then Exit;
  FillChar(bits^, ASize * ASize * 4, 0);
  try
    img := TGPBitmap.Create(AFileName);
    w := img.Width;
    h := img.Height;
    if (w <= 0) or (h <= 0) then Abort;
    scale := Min(ASize / w, ASize / h);
    dst := TGPBitmap.Create(ASize, ASize, ASize * 4, PixelFormat32bppPARGB, bits);
    g := TGPGraphics.FromImage(dst);
    g.SmoothingMode := SmoothingModeAntiAlias;
    g.DrawImage(img, (ASize - w * scale) / 2, (ASize - h * scale) / 2, w * scale, h * scale);
    g := nil;
    dst := nil;
    img := nil;
  except
    DeleteObject(Result);
    Result := 0;
  end;
end;

function BitmapToIcon(ABmp: HBITMAP): HICON;
begin
  Result := 0;
  if (ABmp = 0) then Exit;
  Result := IconFromPremultipliedBitmap(ABmp);
  DeleteObject(ABmp);
end;

function IconsFromSpec(const ASpec: string; out ABig, ASmall: HICON): Boolean;
var
  glyph: Word;
  color: TColor;
  ext, path: string;
  buf: array[0..MAX_PATH] of Char;
begin
  ABig := 0;
  ASmall := 0;
  Result := False;
  if (Trim(ASpec) = '') then Exit;

  if IsGlyphSpec(ASpec)
  then begin
    if not ParseGlyphSpec(ASpec, glyph, color) then Exit;
    ABig := BitmapToIcon(GlyphBitmap(glyph, color, GetSystemMetrics(SM_CXICON)));
    ASmall := BitmapToIcon(GlyphBitmap(glyph, color, GetSystemMetrics(SM_CXSMICON)));
  end
  else begin
    path := Trim(ASpec);
    if (ExpandEnvironmentStrings(PChar(path), buf, Length(buf)) > 0)
    then path := buf;
    ext := LowerCase(ExtractFileExt(path));
    if (ext = '.png') or (ext = '.jpg') or (ext = '.jpeg') or (ext = '.bmp') or (ext = '.gif')
    then begin
      ABig := BitmapToIcon(ImageFileBitmap(path, GetSystemMetrics(SM_CXICON)));
      ASmall := BitmapToIcon(ImageFileBitmap(path, GetSystemMetrics(SM_CXSMICON)));
    end
    else
      Exit(LoadIconsFromSpec(ASpec, ABig, ASmall)); // .ico, .exe,N, .dll,N
  end;

  Result := (ABig <> 0) or (ASmall <> 0);
  if Result
  then begin
    if (ABig = 0) then ABig := CopyIcon(ASmall);
    if (ASmall = 0) then ASmall := CopyIcon(ABig);
  end;
end;

function DescribeIconSpec(const ASpec: string): string;
var glyph: Word;
    color: TColor;
    i: Integer;
begin
  if (Trim(ASpec) = '')
  then Exit(L10NFind('Properties.TaskbarIconAutoInfo', 'automatic (icons of the bar)'));
  if ParseGlyphSpec(ASpec, glyph, color)
  then begin
    Result := L10NFind('IconPicker.Modern', 'modern icon');
    for i := Low(GLYPHS) to High(GLYPHS) do
      if (GLYPHS[i].Code = glyph)
      then Result := Result + ': ' + L10NFind('IconPicker.' + GLYPHS[i].Name, GLYPHS[i].Name);
    Exit;
  end;
  Result := ExtractFileName(ASpec);
end;

{ ---------- dialog ---------- }

function LB_PickIconDlg(hwnd: HWND; pszIconPath: PWideChar; cchIconPath: UINT;
  var piIconIndex: Integer): BOOL; stdcall; external 'shell32.dll' index 62;

type
  TFormIconPicker = class(TForm)
  private
    pbGlyphs: TPaintBox;
    pbColors: TPaintBox;
    pbPreview: TPaintBox;
    lblHint: TLabel;
    FGlyph: Integer;      // index in GLYPHS
    FColor: TColor;
    FCell, FCols, FSwatch: Integer;
    FResult: string;
    function S(const AValue: Integer): Integer;
    procedure GlyphsPaint(Sender: TObject);
    procedure GlyphsMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ColorsPaint(Sender: TObject);
    procedure ColorsMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure PreviewPaint(Sender: TObject);
    procedure OtherColorClick(Sender: TObject);
    procedure FromFileClick(Sender: TObject);
    procedure WindowsIconsClick(Sender: TObject);
    procedure OkClick(Sender: TObject);
  public
    constructor CreatePicker(AOwner: TComponent; const ASpec: string);
  end;

function TFormIconPicker.S(const AValue: Integer): Integer;
begin
  Result := MulDiv(AValue, Screen.PixelsPerInch, 96);
end;

constructor TFormIconPicker.CreatePicker(AOwner: TComponent; const ASpec: string);
var
  y, i, w: Integer;
  btn: TButton;
  glyph: Word;
  col: TColor;

  function AddButton(const ACaption: string; AX, AY, AW: Integer; AOnClick: TNotifyEvent): TButton;
  begin
    Result := TButton.Create(Self);
    Result.Parent := Self;
    Result.Caption := ACaption;
    Result.SetBounds(AX, AY, AW, S(27));
    Result.OnClick := AOnClick;
  end;

begin
  inherited CreateNew(AOwner);
  BorderStyle := bsDialog;
  Position := poScreenCenter;
  FormStyle := fsStayOnTop;
  Font.Name := Screen.MenuFont.Name;
  Caption := L10NFind('IconPicker.Title', 'Choose an icon');

  FGlyph := 0;
  FColor := COLORS[0];
  if ParseGlyphSpec(ASpec, glyph, col)
  then begin
    FColor := col;
    for i := Low(GLYPHS) to High(GLYPHS) do
      if (GLYPHS[i].Code = glyph) then FGlyph := i;
  end;

  FCell := S(44);
  FCols := 9;
  FSwatch := S(28);
  y := S(12);

  lblHint := TLabel.Create(Self);
  lblHint.Parent := Self;
  lblHint.SetBounds(S(12), y, FCols * FCell, S(16));
  lblHint.Caption := L10NFind('IconPicker.Hint', 'Modern icons: choose a symbol and a color');
  Inc(y, S(22));

  pbGlyphs := TPaintBox.Create(Self);
  pbGlyphs.Parent := Self;
  pbGlyphs.SetBounds(S(12), y, FCols * FCell, ((Length(GLYPHS) + FCols - 1) div FCols) * FCell);
  pbGlyphs.OnPaint := GlyphsPaint;
  pbGlyphs.OnMouseDown := GlyphsMouseDown;
  Inc(y, pbGlyphs.Height + S(10));

  pbColors := TPaintBox.Create(Self);
  pbColors.Parent := Self;
  pbColors.SetBounds(S(12), y, Length(COLORS) * (FSwatch + S(6)), FSwatch);
  pbColors.OnPaint := ColorsPaint;
  pbColors.OnMouseDown := ColorsMouseDown;
  AddButton(L10NFind('IconPicker.OtherColor', 'Other...'), pbColors.BoundsRect.Right + S(6), y, S(80), OtherColorClick);

  pbPreview := TPaintBox.Create(Self);
  pbPreview.Parent := Self;
  pbPreview.SetBounds(S(12) + FCols * FCell - S(64), y - S(18), S(64), S(64));
  pbPreview.OnPaint := PreviewPaint;
  Inc(y, S(56));

  w := FCols * FCell;
  AddButton(L10NFind('IconPicker.FromFile', 'From a file (.png, .ico)...'), S(12), y, S(200), FromFileClick);
  AddButton(L10NFind('IconPicker.WindowsIcons', 'Windows icons...'), S(12) + S(206), y, S(150), WindowsIconsClick);
  Inc(y, S(40));

  btn := AddButton('OK', S(12) + w - S(170), y, S(80), OkClick);
  btn.Default := True;
  btn := AddButton(L10NFind('Action.Cancel', 'Cancel'), S(12) + w - S(80), y, S(80), nil);
  btn.Cancel := True;
  btn.ModalResult := mrCancel;

  ClientWidth := w + S(24);
  ClientHeight := y + S(27) + S(12);
end;

procedure TFormIconPicker.GlyphsPaint(Sender: TObject);
var
  i: Integer;
  r: TRect;
  c: TCanvas;
begin
  c := pbGlyphs.Canvas;
  c.Brush.Color := Color;
  c.FillRect(pbGlyphs.ClientRect);
  c.Font.Name := 'Segoe MDL2 Assets';
  c.Font.Size := 16;
  c.Font.Color := Font.Color;
  for i := Low(GLYPHS) to High(GLYPHS) do
  begin
    r := Bounds((i mod FCols) * FCell, (i div FCols) * FCell, FCell, FCell);
    InflateRect(r, -S(2), -S(2));
    if (i = FGlyph)
    then begin
      c.Brush.Color := FColor;
      c.Pen.Color := FColor;
      c.RoundRect(r.Left, r.Top, r.Right, r.Bottom, S(8), S(8));
      c.Font.Color := clWhite;
    end
    else begin
      c.Brush.Color := Color;
      c.Font.Color := Font.Color;
    end;
    c.Brush.Style := bsClear;
    DrawText(c.Handle, PChar(string(Char(GLYPHS[i].Code))), 1, r,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
    c.Brush.Style := bsSolid;
  end;
end;

procedure TFormIconPicker.GlyphsMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var i: Integer;
begin
  i := (Y div FCell) * FCols + (X div FCell);
  if (i >= Low(GLYPHS)) and (i <= High(GLYPHS)) and (X div FCell < FCols)
  then begin
    FGlyph := i;
    pbGlyphs.Invalidate;
    pbPreview.Invalidate;
  end;
end;

procedure TFormIconPicker.ColorsPaint(Sender: TObject);
var i: Integer;
    r: TRect;
    c: TCanvas;
begin
  c := pbColors.Canvas;
  c.Brush.Color := Color;
  c.FillRect(pbColors.ClientRect);
  for i := Low(COLORS) to High(COLORS) do
  begin
    r := Bounds(i * (FSwatch + S(6)), 0, FSwatch, FSwatch);
    c.Brush.Color := COLORS[i];
    if (ColorToRGB(COLORS[i]) = ColorToRGB(FColor))
    then begin
      c.Pen.Color := Font.Color;
      c.Pen.Width := S(2);
    end
    else begin
      c.Pen.Color := COLORS[i];
      c.Pen.Width := 1;
    end;
    c.Ellipse(r.Left + 1, r.Top + 1, r.Right - 1, r.Bottom - 1);
  end;
  c.Pen.Width := 1;
end;

procedure TFormIconPicker.ColorsMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var i: Integer;
begin
  i := X div (FSwatch + S(6));
  if (i >= Low(COLORS)) and (i <= High(COLORS))
  then begin
    FColor := COLORS[i];
    pbColors.Invalidate;
    pbGlyphs.Invalidate;
    pbPreview.Invalidate;
  end;
end;

procedure TFormIconPicker.PreviewPaint(Sender: TObject);
var bmp: HBITMAP;
    dc: HDC;
    old: HGDIOBJ;
    bf: TBlendFunction;
    sz: Integer;
begin
  sz := pbPreview.Width;
  pbPreview.Canvas.Brush.Color := Color;
  pbPreview.Canvas.FillRect(pbPreview.ClientRect);
  bmp := GlyphBitmap(GLYPHS[FGlyph].Code, FColor, sz);
  if (bmp = 0) then Exit;
  dc := CreateCompatibleDC(pbPreview.Canvas.Handle);
  old := SelectObject(dc, bmp);
  bf.BlendOp := AC_SRC_OVER;
  bf.BlendFlags := 0;
  bf.SourceConstantAlpha := 255;
  bf.AlphaFormat := AC_SRC_ALPHA;
  Winapi.Windows.AlphaBlend(pbPreview.Canvas.Handle, 0, 0, sz, sz, dc, 0, 0, sz, sz, bf);
  SelectObject(dc, old);
  DeleteDC(dc);
  DeleteObject(bmp);
end;

procedure TFormIconPicker.OtherColorClick(Sender: TObject);
var dlg: TColorDialog;
begin
  dlg := TColorDialog.Create(Self);
  try
    dlg.Options := [cdFullOpen, cdAnyColor];
    dlg.Color := FColor;
    if dlg.Execute(Handle)
    then begin
      FColor := dlg.Color;
      pbColors.Invalidate;
      pbGlyphs.Invalidate;
      pbPreview.Invalidate;
    end;
  finally
    dlg.Free;
  end;
end;

procedure TFormIconPicker.FromFileClick(Sender: TObject);
var dlg: TOpenDialog;
begin
  dlg := TOpenDialog.Create(Self);
  try
    dlg.Filter := L10NFind('IconPicker.FileFilter', 'Images and icons') +
      ' (*.png;*.ico)|*.png;*.ico|PNG (*.png)|*.png|ICO (*.ico)|*.ico';
    dlg.Options := [ofFileMustExist, ofPathMustExist, ofEnableSizing];
    if dlg.Execute(Handle)
    then begin
      FResult := dlg.FileName;
      ModalResult := mrOk;
    end;
  finally
    dlg.Free;
  end;
end;

procedure TFormIconPicker.WindowsIconsClick(Sender: TObject);
var buf: array[0..MAX_PATH] of Char;
    idx: Integer;
begin
  FillChar(buf, SizeOf(buf), 0);
  StrPLCopy(buf, '%SystemRoot%\System32\imageres.dll', MAX_PATH);
  idx := 0;
  if LB_PickIconDlg(Handle, buf, Length(buf), idx)
  then begin
    FResult := string(buf) + ',' + IntToStr(idx);
    ModalResult := mrOk;
  end;
end;

procedure TFormIconPicker.OkClick(Sender: TObject);
begin
  FResult := MakeGlyphSpec(GLYPHS[FGlyph].Code, FColor);
  ModalResult := mrOk;
end;

function PickIcon(AOwner: TComponent; var ASpec: string): Boolean;
var f: TFormIconPicker;
begin
  f := TFormIconPicker.CreatePicker(AOwner, ASpec);
  try
    Result := (f.ShowModal = mrOk) and (f.FResult <> '');
    if Result then ASpec := f.FResult;
  finally
    f.Free;
  end;
end;

end.
