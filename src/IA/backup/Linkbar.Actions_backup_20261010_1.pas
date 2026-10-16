{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   Action buttons: send a keyboard shortcut or type    }
{   a text in the window that was in front (Arlarach)   }
{*******************************************************}

unit Linkbar.Actions;

{$i linkbar.inc}

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes, System.Types,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Dialogs,
  LBToolbar;

type
  TActionMode = (amKeys, amText);

  TActionData = record
    Mode: TActionMode;
    Keys: string;      // "Ctrl+Shift+V"; several combos separated by spaces
    Text: string;      // text to type (amText)
    Glyph: Word;       // "Segoe MDL2 Assets" glyph, 0 = none
    IconText: string;  // short text drawn on the icon (when Glyph = 0)
    Color: TColor;     // tile color, clNone = Windows accent color
    procedure Clear;
  end;

  { Item of the bar: file "<name>.lbaction" in the links folder }
  TItemAction = class(TItemShortcut)
  public
    Data: TActionData;
    function LoadFromFile(const AFileName: string): Boolean; override;
    procedure LoadIcon(const AIconSize: Integer); override;
    procedure LoadZoomIcon(const AIconSize: Integer); override;
    procedure DoExecute(AHandle: HWND); override;
    procedure DoPopupMenu(AHandle: HWND; const APoint: TPoint; AShift: Boolean = False; ASubMenu: HMENU = 0); override;
    function GetDropPart(const APoint: TPoint; const AVertical: Boolean; const ASideOnly: Boolean = False): Integer; override;
    function Description: string;
  end;

  function IsActionFile(const AFileName: string): Boolean;
  function LoadActionFile(const AFileName: string; out AData: TActionData): Boolean;
  function SaveActionFile(const AFileName: string; const AData: TActionData): Boolean;
  function CreateActionIcon(const AData: TActionData; const ASize: Integer): HBITMAP;
  function KeysAreValid(const AKeys: string): Boolean;
  { Bring ATarget to the front (if it is a window) and send the keys / text }
  procedure RunAction(const AData: TActionData; ATarget: HWND);
  { Dialog to create (ANew) or edit an action button }
  function EditAction(var AName: string; var AData: TActionData; const ANew: Boolean): Boolean;

implementation

uses
  System.Math, System.IniFiles, System.StrUtils, System.UITypes,
  GdiPlus, ExplorerMenu, Linkbar.Consts, Linkbar.Theme, Linkbar.L10n;

{ ---------- presets ---------- }

type
  TActionPreset = record
    Key: string;   // L10n key "Action.<Key>"
    Name: string;  // English default
    Keys: string;
    Glyph: Word;
  end;

const
  GLYPH_KEYBOARD = $E765;
  GLYPH_TEXT     = $E70F;

  PRESETS: array[0..21] of TActionPreset = (
    (Key: 'Copy';        Name: 'Copy';               Keys: 'Ctrl+C';          Glyph: $E8C8),
    (Key: 'Paste';       Name: 'Paste';              Keys: 'Ctrl+V';          Glyph: $E77F),
    (Key: 'Cut';         Name: 'Cut';                Keys: 'Ctrl+X';          Glyph: $E8C6),
    (Key: 'PastePlain';  Name: 'Paste as plain text'; Keys: 'Ctrl+Shift+V';   Glyph: $E77F),
    (Key: 'Undo';        Name: 'Undo';               Keys: 'Ctrl+Z';          Glyph: $E7A7),
    (Key: 'Redo';        Name: 'Redo';               Keys: 'Ctrl+Y';          Glyph: $E7A6),
    (Key: 'SelectAll';   Name: 'Select all';         Keys: 'Ctrl+A';          Glyph: $E8B3),
    (Key: 'Save';        Name: 'Save';               Keys: 'Ctrl+S';          Glyph: $E74E),
    (Key: 'Find';        Name: 'Find';               Keys: 'Ctrl+F';          Glyph: $E721),
    (Key: 'Print';       Name: 'Print';              Keys: 'Ctrl+P';          Glyph: $E749),
    (Key: 'CloseWindow'; Name: 'Close window';       Keys: 'Alt+F4';          Glyph: $E8BB),
    (Key: 'Screenshot';  Name: 'Screenshot';         Keys: 'Win+Shift+S';     Glyph: $E722),
    (Key: 'Clipboard';   Name: 'Clipboard history';  Keys: 'Win+V';           Glyph: $E81C),
    (Key: 'Desktop';     Name: 'Show desktop';       Keys: 'Win+D';           Glyph: $E7F4),
    (Key: 'Explorer';    Name: 'File Explorer';      Keys: 'Win+E';           Glyph: $E8B7),
    (Key: 'Emoji';       Name: 'Emoji';              Keys: 'Win+.';           Glyph: $E76E),
    (Key: 'TaskMgr';     Name: 'Task Manager';       Keys: 'Ctrl+Shift+Esc';  Glyph: $E9D9),
    (Key: 'PlayPause';   Name: 'Play / Pause';       Keys: 'PlayPause';       Glyph: $E768),
    (Key: 'NextTrack';   Name: 'Next track';         Keys: 'NextTrack';       Glyph: $E893),
    (Key: 'PrevTrack';   Name: 'Previous track';     Keys: 'PrevTrack';       Glyph: $E892),
    (Key: 'VolumeUp';    Name: 'Volume up';          Keys: 'VolumeUp';        Glyph: $E995),
    (Key: 'VolumeDown';  Name: 'Volume down';        Keys: 'VolumeDown';      Glyph: $E993)
  );

function PresetName(const AIndex: Integer): string;
begin
  Result := L10NFind('Action.' + PRESETS[AIndex].Key, PRESETS[AIndex].Name);
end;

{ ---------- key names ---------- }

const
  KEY_NAMES: array[0..33] of string = (
    'Enter', 'Tab', 'Esc', 'Space', 'Backspace', 'Del', 'Ins', 'Home', 'End',
    'PgUp', 'PgDn', 'Left', 'Right', 'Up', 'Down', 'PrtSc', 'Pause', 'Apps',
    'CapsLock', 'NumLock', 'ScrollLock', 'Plus', 'Minus',
    'PlayPause', 'NextTrack', 'PrevTrack', 'Stop', 'VolumeUp', 'VolumeDown', 'Mute',
    'Escape', 'Delete', 'Insert', 'Return');
  KEY_CODES: array[0..33] of Word = (
    VK_RETURN, VK_TAB, VK_ESCAPE, VK_SPACE, VK_BACK, VK_DELETE, VK_INSERT, VK_HOME, VK_END,
    VK_PRIOR, VK_NEXT, VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN, VK_SNAPSHOT, VK_PAUSE, VK_APPS,
    VK_CAPITAL, VK_NUMLOCK, VK_SCROLL, VK_OEM_PLUS, VK_OEM_MINUS,
    VK_MEDIA_PLAY_PAUSE, VK_MEDIA_NEXT_TRACK, VK_MEDIA_PREV_TRACK, VK_MEDIA_STOP,
    VK_VOLUME_UP, VK_VOLUME_DOWN, VK_VOLUME_MUTE,
    VK_ESCAPE, VK_DELETE, VK_INSERT, VK_RETURN);

function KeyNameToVK(const AName: string): Word;
var i, n: Integer;
    c: Char;
begin
  Result := 0;
  if (AName = '') then Exit;
  for i := Low(KEY_NAMES) to High(KEY_NAMES) do
    if SameText(AName, KEY_NAMES[i])
    then Exit(KEY_CODES[i]);
  // F1..F24
  if (Length(AName) >= 2) and CharInSet(UpCase(AName[1]), ['F'])
     and TryStrToInt(Copy(AName, 2, 2), n) and (n >= 1) and (n <= 24)
  then Exit(VK_F1 + n - 1);
  // VK<number>
  if StartsText('VK', AName) and TryStrToInt(Copy(AName, 3, 5), n) and (n > 0) and (n < 255)
  then Exit(n);
  if (Length(AName) = 1)
  then begin
    c := UpCase(AName[1]);
    if CharInSet(c, ['A'..'Z', '0'..'9'])
    then Exit(Ord(c));
    n := VkKeyScan(c);
    if (n <> -1)
    then Exit(n and $FF);
  end;
end;

function VKToKeyName(const AVK: Word): string;
var i: Integer;
    ch: Cardinal;
begin
  case AVK of
    Ord('A')..Ord('Z'), Ord('0')..Ord('9'): Exit(Char(AVK));
    VK_F1..VK_F24: Exit('F' + IntToStr(AVK - VK_F1 + 1));
  end;
  for i := Low(KEY_NAMES) to High(KEY_NAMES) do
    if (KEY_CODES[i] = AVK)
    then Exit(KEY_NAMES[i]);
  ch := MapVirtualKey(AVK, 2 {MAPVK_VK_TO_CHAR}) and $FFFF;
  if (ch > 32) and (ch <> Ord('+'))
  then Exit(Char(ch));
  Result := 'VK' + IntToStr(AVK);
end;

type
  TKeyCombo = record
    Ctrl, Shift, Alt, Win: Boolean;
    VK: Word;
  end;

function ParseCombo(const AText: string; out ACombo: TKeyCombo): Boolean;
var parts: TArray<string>;
    s: string;
    i: Integer;
begin
  Result := False;
  FillChar(ACombo, SizeOf(ACombo), 0);
  s := Trim(AText);
  if (s = '') then Exit;
  // "Ctrl++" -> the key is "+"
  if (Length(s) > 1) and EndsStr('++', s)
  then s := Copy(s, 1, Length(s) - 2) + '+Plus';
  parts := s.Split(['+']);
  for i := 0 to High(parts) do
  begin
    s := Trim(parts[i]);
    if SameText(s, 'Ctrl') or SameText(s, 'Control') then ACombo.Ctrl := True
    else if SameText(s, 'Shift') then ACombo.Shift := True
    else if SameText(s, 'Alt') then ACombo.Alt := True
    else if SameText(s, 'Win') or SameText(s, 'Windows') then ACombo.Win := True
    else begin
      if (i <> High(parts)) or (ACombo.VK <> 0) then Exit;
      ACombo.VK := KeyNameToVK(s);
      if (ACombo.VK = 0) then Exit;
    end;
  end;
  Result := (ACombo.VK <> 0);
end;

function ParseKeys(const AKeys: string; out ACombos: TArray<TKeyCombo>): Boolean;
var c: TKeyCombo;
    s: string;
begin
  ACombos := nil;
  for s in AKeys.Split([' ', #9], TStringSplitOptions.ExcludeEmpty) do
  begin
    if not ParseCombo(s, c)
    then Exit(False);
    ACombos := ACombos + [c];
  end;
  Result := Length(ACombos) > 0;
end;

function KeysAreValid(const AKeys: string): Boolean;
var c: TArray<TKeyCombo>;
begin
  Result := ParseKeys(AKeys, c);
end;

{ ---------- sending input ---------- }

function IsExtendedKey(const AVK: Word): Boolean;
begin
  case AVK of
    VK_INSERT, VK_DELETE, VK_HOME, VK_END, VK_PRIOR, VK_NEXT,
    VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN, VK_LWIN, VK_RWIN, VK_APPS,
    VK_DIVIDE, VK_NUMLOCK, VK_SNAPSHOT, VK_RCONTROL, VK_RMENU,
    VK_MEDIA_PLAY_PAUSE, VK_MEDIA_NEXT_TRACK, VK_MEDIA_PREV_TRACK, VK_MEDIA_STOP,
    VK_VOLUME_UP, VK_VOLUME_DOWN, VK_VOLUME_MUTE: Result := True;
    else Result := False;
  end;
end;

procedure AddKey(var AInputs: TArray<TInput>; const AVK: Word; const AUp: Boolean);
var inp: TInput;
begin
  FillChar(inp, SizeOf(inp), 0);
  inp.Itype := INPUT_KEYBOARD;
  inp.ki.wVk := AVK;
  inp.ki.wScan := MapVirtualKey(AVK, 0);
  if IsExtendedKey(AVK) then inp.ki.dwFlags := KEYEVENTF_EXTENDEDKEY;
  if AUp then inp.ki.dwFlags := inp.ki.dwFlags or KEYEVENTF_KEYUP;
  AInputs := AInputs + [inp];
end;

procedure AddChar(var AInputs: TArray<TInput>; const ACh: Char);
var inp: TInput;
begin
  FillChar(inp, SizeOf(inp), 0);
  inp.Itype := INPUT_KEYBOARD;
  inp.ki.wScan := Ord(ACh);
  inp.ki.dwFlags := KEYEVENTF_UNICODE;
  AInputs := AInputs + [inp];
  inp.ki.dwFlags := KEYEVENTF_UNICODE or KEYEVENTF_KEYUP;
  AInputs := AInputs + [inp];
end;

procedure SendInputs(const AInputs: TArray<TInput>);
var a: TArray<TInput>;
begin
  a := Copy(AInputs);
  if (Length(a) > 0)
  then SendInput(Length(a), a[0], SizeOf(TInput));
end;

procedure SendCombos(const ACombos: TArray<TKeyCombo>);
var inputs: TArray<TInput>;
    c: TKeyCombo;
begin
  for c in ACombos do
  begin
    inputs := nil;
    if c.Win   then AddKey(inputs, VK_LWIN, False);
    if c.Ctrl  then AddKey(inputs, VK_CONTROL, False);
    if c.Alt   then AddKey(inputs, VK_MENU, False);
    if c.Shift then AddKey(inputs, VK_SHIFT, False);
    AddKey(inputs, c.VK, False);
    AddKey(inputs, c.VK, True);
    if c.Shift then AddKey(inputs, VK_SHIFT, True);
    if c.Alt   then AddKey(inputs, VK_MENU, True);
    if c.Ctrl  then AddKey(inputs, VK_CONTROL, True);
    if c.Win   then AddKey(inputs, VK_LWIN, True);
    SendInputs(inputs);
    if (Length(ACombos) > 1) then Sleep(40);
  end;
end;

procedure TypeText(const AText: string);
var inputs: TArray<TInput>;
    i: Integer;
    ch: Char;
begin
  inputs := nil;
  for i := 1 to Length(AText) do
  begin
    ch := AText[i];
    case ch of
      #13: begin AddKey(inputs, VK_RETURN, False); AddKey(inputs, VK_RETURN, True); end;
      #10: if (i = 1) or (AText[i-1] <> #13)
           then begin AddKey(inputs, VK_RETURN, False); AddKey(inputs, VK_RETURN, True); end;
      #9:  begin AddKey(inputs, VK_TAB, False); AddKey(inputs, VK_TAB, True); end;
      else AddChar(inputs, ch);
    end;
  end;
  SendInputs(inputs);
end;

procedure RunAction(const AData: TActionData; ATarget: HWND);
var t: Cardinal;
    combos: TArray<TKeyCombo>;
begin
  // Give the focus back to the window that was in front before the click
  if (ATarget <> 0) and IsWindow(ATarget) and (GetForegroundWindow <> ATarget)
  then begin
    SetForegroundWindow(ATarget);
    t := GetTickCount;
    while (GetForegroundWindow <> ATarget) and (GetTickCount - t < 400) do
      Sleep(10);
    Sleep(30);
  end;

  case AData.Mode of
    amKeys:
      if ParseKeys(AData.Keys, combos)
      then SendCombos(combos);
    amText:
      if (AData.Text <> '')
      then TypeText(AData.Text);
  end;
end;

{ ---------- file ---------- }

const
  SEC = 'Action';

procedure TActionData.Clear;
begin
  Mode := amKeys;
  Keys := '';
  Text := '';
  Glyph := 0;
  IconText := '';
  Color := clNone;
end;

function IsActionFile(const AFileName: string): Boolean;
begin
  Result := SameText(ExtractFileExt(AFileName), ES_ACTION);
end;

function EscapeText(const S: string): string;
begin
  Result := S.Replace('\', '\\').Replace(#13#10, '\n').Replace(#10, '\n').Replace(#13, '\n').Replace(#9, '\t');
end;

function UnescapeText(const S: string): string;
var i: Integer;
begin
  Result := '';
  i := 1;
  while (i <= Length(S)) do
  begin
    if (S[i] = '\') and (i < Length(S))
    then begin
      case S[i+1] of
        'n': Result := Result + #13#10;
        't': Result := Result + #9;
        else Result := Result + S[i+1];
      end;
      Inc(i, 2);
    end
    else begin
      Result := Result + S[i];
      Inc(i);
    end;
  end;
end;

function LoadActionFile(const AFileName: string; out AData: TActionData): Boolean;
var ini: TMemIniFile;
    s: string;
    v: Integer;
begin
  AData.Clear;
  Result := False;
  if not FileExists(AFileName) then Exit;
  try
    ini := TMemIniFile.Create(AFileName, TEncoding.UTF8);
    try
      if SameText(ini.ReadString(SEC, 'Mode', 'keys'), 'text')
      then AData.Mode := amText;
      AData.Keys := Trim(ini.ReadString(SEC, 'Keys', ''));
      AData.Text := UnescapeText(ini.ReadString(SEC, 'Text', ''));
      s := Trim(ini.ReadString(SEC, 'Glyph', ''));
      if (s <> '') and TryStrToInt('$' + s, v) then AData.Glyph := Word(v);
      AData.IconText := Copy(Trim(ini.ReadString(SEC, 'IconText', '')), 1, 3);
      s := Trim(ini.ReadString(SEC, 'Color', ''));
      if (s <> '') and (s[1] = '#') then Delete(s, 1, 1);
      if (Length(s) = 6) and TryStrToInt('$' + s, v)
      then AData.Color := TColor(RGB((v shr 16) and $FF, (v shr 8) and $FF, v and $FF));
      Result := True;
    finally
      ini.Free;
    end;
  except
    Result := False;
  end;
end;

function SaveActionFile(const AFileName: string; const AData: TActionData): Boolean;
var sl: TStringList;
    c: Cardinal;
begin
  sl := TStringList.Create;
  try
    sl.Add('[' + SEC + ']');
    if (AData.Mode = amText)
    then sl.Add('Mode=text')
    else sl.Add('Mode=keys');
    sl.Add('Keys=' + AData.Keys);
    sl.Add('Text=' + EscapeText(AData.Text));
    if (AData.Glyph <> 0)
    then sl.Add('Glyph=' + IntToHex(AData.Glyph, 4))
    else sl.Add('Glyph=');
    sl.Add('IconText=' + AData.IconText);
    if (AData.Color = clNone)
    then sl.Add('Color=')
    else begin
      c := ColorToRGB(AData.Color);
      sl.Add(Format('Color=#%.2X%.2X%.2X', [GetRValue(c), GetGValue(c), GetBValue(c)]));
    end;
    try
      sl.SaveToFile(AFileName, TEncoding.UTF8);
      Result := True;
    except
      Result := False;
    end;
  finally
    sl.Free;
  end;
end;

{ ---------- icon ---------- }

function CreateActionIcon(const AData: TActionData; const ASize: Integer): HBITMAP;
var
  bmi: TBitmapInfo;
  bits: Pointer;
  bmp: IGPBitmap;
  g: IGPGraphics;
  brush: IGPBrush;
  font: IGPFont;
  fmt: IGPStringFormat;
  argb, c: Cardinal;
  r, gg, b, lum, pad: Integer;
  s, family: string;
  em: Single;
  style: TGPFontStyle;
begin
  Result := 0;
  if (ASize <= 0) then Exit;

  FillChar(bmi, SizeOf(bmi), 0);
  bmi.bmiHeader.biSize := SizeOf(bmi.bmiHeader);
  bmi.bmiHeader.biWidth := ASize;
  bmi.bmiHeader.biHeight := -ASize; // top-down
  bmi.bmiHeader.biPlanes := 1;
  bmi.bmiHeader.biBitCount := 32;
  bmi.bmiHeader.biCompression := BI_RGB;
  bits := nil;
  Result := CreateDIBSection(0, bmi, DIB_RGB_COLORS, bits, 0, 0);
  if (Result = 0) or (bits = nil) then Exit;
  FillChar(bits^, ASize * ASize * 4, 0);

  // Tile color
  if (AData.Color = clNone)
  then argb := SwapRedBlue(GetImmersiveColorFromName('ImmersiveSystemAccent')) or $FF000000
  else begin
    c := ColorToRGB(AData.Color);
    argb := $FF000000 or (GetRValue(c) shl 16) or (GetGValue(c) shl 8) or GetBValue(c);
  end;
  r := (argb shr 16) and $FF;
  gg := (argb shr 8) and $FF;
  b := argb and $FF;
  lum := (r * 299 + gg * 587 + b * 114) div 1000;

  try
    bmp := TGPBitmap.Create(ASize, ASize, ASize * 4, PixelFormat32bppPARGB, bits);
    g := TGPGraphics.FromImage(bmp);
    g.SmoothingMode := SmoothingModeAntiAlias;
    g.TextRenderingHint := TextRenderingHintAntiAlias;

    pad := Max(1, ASize div 16);
    brush := TGPSolidBrush.Create(argb);
    GPFillRoundRect(g, brush, Rect(pad, pad, ASize - pad, ASize - pad), ASize div 4);

    // Glyph or short text
    if (AData.IconText <> '')
    then begin
      s := AData.IconText;
      family := 'Segoe UI';
      style := [FontStyleBold];
      if (Length(s) >= 3) then em := ASize * 0.30
      else if (Length(s) = 2) then em := ASize * 0.38
      else em := ASize * 0.48;
    end
    else begin
      if (AData.Glyph <> 0) then s := Char(AData.Glyph)
      else if (AData.Mode = amText) then s := Char(GLYPH_TEXT)
      else s := Char(GLYPH_KEYBOARD);
      family := 'Segoe MDL2 Assets';
      style := FontStyleRegular;
      em := ASize * 0.46;
    end;

    font := TGPFont.Create(family, em, style, UnitPixel);
    fmt := TGPStringFormat.Create;
    fmt.Alignment := StringAlignmentCenter;
    fmt.LineAlignment := StringAlignmentCenter;
    if (lum >= 160)
    then brush := TGPSolidBrush.Create($FF000000)
    else brush := TGPSolidBrush.Create($FFFFFFFF);
    g.DrawString(s, font, TGPRectF.Create(0, 0, ASize, ASize + ASize / 32), fmt, brush);
  except
    // GDI+ failure: keep the plain tile
  end;
  g := nil;
  bmp := nil;
end;

{ ---------- TItemAction ---------- }

function TItemAction.LoadFromFile(const AFileName: string): Boolean;
begin
  Result := inherited LoadFromFile(AFileName);
  if Result
  then begin
    Caption := ChangeFileExt(ExtractFileName(AFileName), '');
    TargetPath := '';
    LoadActionFile(AFileName, Data);
  end;
end;

procedure TItemAction.LoadIcon(const AIconSize: Integer);
begin
  DeleteObject(FBitmap);
  FBitmap := CreateActionIcon(Data, AIconSize);
end;

procedure TItemAction.LoadZoomIcon(const AIconSize: Integer);
begin
  FreeZoomIcon;
  FBitmapZoom := CreateActionIcon(Data, AIconSize);
end;

procedure TItemAction.DoExecute(AHandle: HWND);
begin
  RunAction(Data, 0);
end;

{ Right click: only the Linkbar menu (it has "Edit" and "Delete" for actions) }
procedure TItemAction.DoPopupMenu(AHandle: HWND; const APoint: TPoint; AShift: Boolean; ASubMenu: HMENU);
var cmd: LongBool;
begin
  if (ASubMenu = 0) then Exit;
  try
    cmd := TrackPopupMenuEx(ASubMenu, TPM_RETURNCMD or TPM_RIGHTBUTTON or TPM_NONOTIFY,
      APoint.X, APoint.Y, AHandle, nil);
    if cmd
    then PostMessage(AHandle, LM_CM_ITEMS, 0, LPARAM(LongInt(cmd)));
  finally
    DestroyMenu(ASubMenu);
  end;
end;

{ Files can only be dropped beside an action, not onto it }
function TItemAction.GetDropPart(const APoint: TPoint; const AVertical: Boolean; const ASideOnly: Boolean): Integer;
begin
  Result := inherited GetDropPart(APoint, AVertical, True);
end;

function TItemAction.Description: string;
begin
  if (Data.Mode = amText)
  then Result := Caption + '  (' + L10NFind('Action.TypesText', 'types a text') + ')'
  else Result := Caption + '  (' + Data.Keys + ')';
end;

{ ---------- editor dialog ---------- }

type
  TFormActionEdit = class(TForm)
  private
    edtName: TEdit;
    cbbPreset: TComboBox;
    rbKeys, rbText: TRadioButton;
    edtKeys: TEdit;
    chbWin: TCheckBox;
    mmoText: TMemo;
    edtIconText: TEdit;
    btnColor, btnColorDefault: TButton;
    pbPreview: TPaintBox;
    btnOk, btnCancel: TButton;
    FData: TActionData;
    FUpdating: Boolean;
    function S(const AValue: Integer): Integer;
    function AddLabel(const ACaption: string; const ATop: Integer): TLabel;
    procedure PresetChange(Sender: TObject);
    procedure ModeClick(Sender: TObject);
    procedure KeysKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure KeysKeyPress(Sender: TObject; var Key: Char);
    procedure AnyChange(Sender: TObject);
    procedure ColorClick(Sender: TObject);
    procedure ColorDefaultClick(Sender: TObject);
    procedure PreviewPaint(Sender: TObject);
    procedure OkClick(Sender: TObject);
    procedure UpdateEnabled;
    procedure ReadControls;
  public
    constructor CreateEditor(const AName: string; const AData: TActionData; const ANew: Boolean);
  end;

function TFormActionEdit.S(const AValue: Integer): Integer;
begin
  Result := MulDiv(AValue, Screen.PixelsPerInch, 96);
end;

function TFormActionEdit.AddLabel(const ACaption: string; const ATop: Integer): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent := Self;
  Result.Caption := ACaption;
  Result.Left := S(12);
  Result.Top := ATop + S(3);
end;

constructor TFormActionEdit.CreateEditor(const AName: string; const AData: TActionData; const ANew: Boolean);
const
  LW = 130; // label column
  CW = 250; // control column
var
  y, i, x2: Integer;
  keys: string;
begin
  inherited CreateNew(nil);
  FData := AData;
  FUpdating := True;

  BorderStyle := bsDialog;
  Position := poScreenCenter;
  FormStyle := fsStayOnTop;
  Font.Name := Screen.MenuFont.Name;
  if ANew
  then Caption := L10NFind('Action.NewTitle', 'New action button')
  else Caption := L10NFind('Action.EditTitle', 'Edit action button');

  x2 := S(12 + LW);
  y := S(12);

  // Name
  AddLabel(L10NFind('Action.Name', 'Name:'), y);
  edtName := TEdit.Create(Self);
  edtName.Parent := Self;
  edtName.SetBounds(x2, y, S(CW), S(23));
  edtName.Text := AName;
  edtName.OnChange := AnyChange;
  Inc(y, S(32));

  // Preset
  AddLabel(L10NFind('Action.Preset', 'Quick action:'), y);
  cbbPreset := TComboBox.Create(Self);
  cbbPreset.Parent := Self;
  cbbPreset.Style := csDropDownList;
  cbbPreset.SetBounds(x2, y, S(CW), S(23));
  cbbPreset.DropDownCount := 24;
  cbbPreset.Items.Add(L10NFind('Action.Custom', '(custom)'));
  for i := Low(PRESETS) to High(PRESETS) do
    cbbPreset.Items.Add(PresetName(i) + '   ' + PRESETS[i].Keys);
  cbbPreset.ItemIndex := 0;
  for i := Low(PRESETS) to High(PRESETS) do
    if (AData.Mode = amKeys) and SameText(AData.Keys, PRESETS[i].Keys)
    then cbbPreset.ItemIndex := i + 1;
  cbbPreset.OnChange := PresetChange;
  Inc(y, S(36));

  // Mode: shortcut
  rbKeys := TRadioButton.Create(Self);
  rbKeys.Parent := Self;
  rbKeys.SetBounds(S(12), y, S(LW + CW), S(19));
  rbKeys.Caption := L10NFind('Action.ModeKeys', 'Send a keyboard shortcut');
  rbKeys.OnClick := ModeClick;
  Inc(y, S(24));

  AddLabel(L10NFind('Action.Keys', 'Keys (press them):'), y);
  edtKeys := TEdit.Create(Self);
  edtKeys.Parent := Self;
  edtKeys.SetBounds(x2, y, S(CW), S(23));
  edtKeys.OnKeyDown := KeysKeyDown;
  edtKeys.OnKeyPress := KeysKeyPress;
  edtKeys.OnChange := AnyChange;
  Inc(y, S(28));

  chbWin := TCheckBox.Create(Self);
  chbWin.Parent := Self;
  chbWin.SetBounds(x2, y, S(CW), S(19));
  chbWin.Caption := L10NFind('Action.WithWin', 'With the Windows key');
  chbWin.OnClick := AnyChange;
  Inc(y, S(30));

  // Mode: text
  rbText := TRadioButton.Create(Self);
  rbText.Parent := Self;
  rbText.SetBounds(S(12), y, S(LW + CW), S(19));
  rbText.Caption := L10NFind('Action.ModeText', 'Type a text');
  rbText.OnClick := ModeClick;
  Inc(y, S(24));

  mmoText := TMemo.Create(Self);
  mmoText.Parent := Self;
  mmoText.SetBounds(x2, y, S(CW), S(60));
  mmoText.ScrollBars := ssVertical;
  mmoText.WantReturns := True;
  mmoText.Text := AData.Text;
  mmoText.OnChange := AnyChange;
  Inc(y, S(72));

  // Icon
  AddLabel(L10NFind('Action.IconText', 'Icon text (optional):'), y);
  edtIconText := TEdit.Create(Self);
  edtIconText.Parent := Self;
  edtIconText.SetBounds(x2, y, S(60), S(23));
  edtIconText.MaxLength := 3;
  edtIconText.Text := AData.IconText;
  edtIconText.OnChange := AnyChange;

  pbPreview := TPaintBox.Create(Self);
  pbPreview.Parent := Self;
  pbPreview.SetBounds(x2 + S(CW) - S(48), y, S(48), S(48));
  pbPreview.OnPaint := PreviewPaint;
  Inc(y, S(28));

  btnColor := TButton.Create(Self);
  btnColor.Parent := Self;
  btnColor.SetBounds(x2, y, S(90), S(25));
  btnColor.Caption := L10NFind('Action.Color', 'Color...');
  btnColor.OnClick := ColorClick;
  btnColorDefault := TButton.Create(Self);
  btnColorDefault.Parent := Self;
  btnColorDefault.SetBounds(x2 + S(94), y, S(90), S(25));
  btnColorDefault.Caption := L10NFind('Group.ColorDefault', 'Default');
  btnColorDefault.OnClick := ColorDefaultClick;
  Inc(y, S(44));

  // Buttons
  btnOk := TButton.Create(Self);
  btnOk.Parent := Self;
  btnOk.Caption := 'OK';
  btnOk.Default := True;
  btnOk.SetBounds(x2 + S(CW) - S(170), y, S(80), S(25));
  btnOk.OnClick := OkClick;
  btnCancel := TButton.Create(Self);
  btnCancel.Parent := Self;
  btnCancel.Caption := L10NFind('Action.Cancel', 'Cancel');
  btnCancel.Cancel := True;
  btnCancel.ModalResult := mrCancel;
  btnCancel.SetBounds(x2 + S(CW) - S(80), y, S(80), S(25));

  ClientWidth := x2 + S(CW) + S(12);
  ClientHeight := y + S(25) + S(12);

  // Values
  keys := AData.Keys;
  if StartsText('Win+', keys)
  then begin
    chbWin.Checked := True;
    Delete(keys, 1, 4);
  end;
  edtKeys.Text := keys;
  rbKeys.Checked := (AData.Mode = amKeys);
  rbText.Checked := (AData.Mode = amText);

  FUpdating := False;
  UpdateEnabled;
  ActiveControl := edtName;
end;

procedure TFormActionEdit.UpdateEnabled;
begin
  edtKeys.Enabled := rbKeys.Checked;
  chbWin.Enabled := rbKeys.Checked;
  mmoText.Enabled := rbText.Checked;
end;

procedure TFormActionEdit.ReadControls;
begin
  if rbText.Checked
  then FData.Mode := amText
  else FData.Mode := amKeys;
  FData.Keys := Trim(edtKeys.Text);
  if chbWin.Checked and (FData.Keys <> '')
  then FData.Keys := 'Win+' + FData.Keys;
  FData.Text := mmoText.Text;
  FData.IconText := Trim(edtIconText.Text);
end;

procedure TFormActionEdit.PresetChange(Sender: TObject);
var i: Integer;
    keys: string;
begin
  i := cbbPreset.ItemIndex - 1;
  if (i < 0) then Exit;
  FUpdating := True;
  try
    keys := PRESETS[i].Keys;
    chbWin.Checked := StartsText('Win+', keys);
    if chbWin.Checked then Delete(keys, 1, 4);
    edtKeys.Text := keys;
    rbKeys.Checked := True;
    FData.Glyph := PRESETS[i].Glyph;
    edtIconText.Text := '';
    if (Trim(edtName.Text) = '') or (edtName.Tag = 1)
    then begin
      edtName.Text := PresetName(i);
      edtName.Tag := 1; // name set by the preset: follow the next preset too
    end;
  finally
    FUpdating := False;
  end;
  UpdateEnabled;
  pbPreview.Invalidate;
end;

procedure TFormActionEdit.ModeClick(Sender: TObject);
begin
  UpdateEnabled;
  AnyChange(Sender);
end;

procedure TFormActionEdit.KeysKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var s: string;
begin
  case Key of
    VK_SHIFT, VK_CONTROL, VK_MENU, VK_LWIN, VK_RWIN:
      begin
        Key := 0;
        Exit;
      end;
    VK_TAB:
      if (Shift = []) or (Shift = [ssShift]) then Exit; // move to the next control
    VK_BACK:
      if (Shift = [])
      then begin
        edtKeys.Text := '';
        Key := 0;
        Exit;
      end;
  end;
  s := '';
  if (ssCtrl in Shift) then s := s + 'Ctrl+';
  if (ssAlt in Shift) then s := s + 'Alt+';
  if (ssShift in Shift) then s := s + 'Shift+';
  edtKeys.Text := s + VKToKeyName(Key);
  edtKeys.SelStart := Length(edtKeys.Text);
  Key := 0;
end;

procedure TFormActionEdit.KeysKeyPress(Sender: TObject; var Key: Char);
begin
  Key := #0;
end;

procedure TFormActionEdit.AnyChange(Sender: TObject);
begin
  if FUpdating then Exit;
  if (Sender = edtName) then edtName.Tag := 0;
  // keys typed by hand: no longer the preset (keep its glyph only if the keys are the same)
  if (Sender = edtKeys) or (Sender = chbWin)
  then begin
    ReadControls;
    var match := 0;
    for var i := Low(PRESETS) to High(PRESETS) do
      if SameText(FData.Keys, PRESETS[i].Keys) then match := i + 1;
    FUpdating := True;
    cbbPreset.ItemIndex := match;
    FUpdating := False;
    if (match > 0)
    then FData.Glyph := PRESETS[match - 1].Glyph
    else FData.Glyph := 0;
  end;
  if (Sender = rbText) and rbText.Checked
  then FData.Glyph := 0;
  pbPreview.Invalidate;
end;

procedure TFormActionEdit.ColorClick(Sender: TObject);
var dlg: TColorDialog;
begin
  dlg := TColorDialog.Create(Self);
  try
    dlg.Options := [cdFullOpen, cdAnyColor];
    if (FData.Color <> clNone) then dlg.Color := FData.Color;
    if dlg.Execute(Handle)
    then begin
      FData.Color := dlg.Color;
      pbPreview.Invalidate;
    end;
  finally
    dlg.Free;
  end;
end;

procedure TFormActionEdit.ColorDefaultClick(Sender: TObject);
begin
  FData.Color := clNone;
  pbPreview.Invalidate;
end;

procedure TFormActionEdit.PreviewPaint(Sender: TObject);
var bmp: HBITMAP;
    dc: HDC;
    old: HGDIOBJ;
    bf: TBlendFunction;
    sz: Integer;
begin
  ReadControls;
  sz := pbPreview.Width;
  pbPreview.Canvas.Brush.Color := Color;
  pbPreview.Canvas.FillRect(pbPreview.ClientRect);
  bmp := CreateActionIcon(FData, sz);
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

procedure TFormActionEdit.OkClick(Sender: TObject);
const InvalidChars = '\/:*?"<>|';
var ch: Char;
    name: string;
begin
  ReadControls;
  name := Trim(edtName.Text);
  if (name = '')
  then begin
    edtName.SetFocus;
    Exit;
  end;
  for ch in InvalidChars do
    if (Pos(ch, name) > 0)
    then begin
      MessageDlg(L10NFind('Group.InvalidName', 'The name can not contain: \ / : * ? " < > |'), mtWarning, [mbOK], 0);
      edtName.SetFocus;
      Exit;
    end;
  if (FData.Mode = amKeys) and not KeysAreValid(FData.Keys)
  then begin
    MessageDlg(L10NFind('Action.InvalidKeys', 'Click the "Keys" box and press the shortcut (for example Ctrl+C).'),
      mtWarning, [mbOK], 0);
    edtKeys.SetFocus;
    Exit;
  end;
  if (FData.Mode = amText) and (FData.Text = '')
  then begin
    mmoText.SetFocus;
    Exit;
  end;
  ModalResult := mrOk;
end;

function EditAction(var AName: string; var AData: TActionData; const ANew: Boolean): Boolean;
var f: TFormActionEdit;
begin
  f := TFormActionEdit.CreateEditor(AName, AData, ANew);
  try
    Result := (f.ShowModal = mrOk);
    if Result
    then begin
      f.ReadControls;
      AName := Trim(f.edtName.Text);
      AData := f.FData;
    end;
  finally
    f.Free;
  end;
end;

end.
