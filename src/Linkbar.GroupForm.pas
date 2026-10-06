{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   Icon groups popup (Android-like folder)             }
{*******************************************************}

unit Linkbar.GroupForm;

{$i linkbar.inc}

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes, System.Types, System.UITypes,
  System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  LBToolbar, Linkbar.Consts;

type
  { Popup window that shows the shortcuts of a group as a grid of icons }
  TFormGroup = class(TForm)
  private
    FItems: TObjectList<TItemShortcut>;
    FOwnerWnd: HWND;
    FGroupCaption: string;
    FIconSize: Integer;
    FHot: Integer;
    FCols, FRows: Integer;
    FCellW, FCellH: Integer;
    FPad: Integer;
    FHeaderHeight: Integer;
    FRadius: Integer;
    FBgColor, FTextColor, FBorderColor: TColor;
    FHotColor: Cardinal;
    function Scale(const AValue: Integer): Integer;
    function CellRect(const AIndex: Integer): TRect;
    function IndexAt(const APoint: TPoint): Integer;
    procedure DrawItemIcon(const AItem: TItemShortcut; const AX, AY: Integer);
    procedure CalcLayout;
    procedure SetHot(const AValue: Integer);
    procedure ApplyCorners;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WndProc(var Message: TMessage); override;
    procedure Paint; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure DoClose(var Action: TCloseAction); override;
  public
    constructor CreateGroup(AOwner: TComponent; AOwnerWnd: HWND;
      const AFolder, ACaption: string; AIconSize: Integer);
    destructor Destroy; override;
    procedure PopupAt(const AItemRect: TRect; const AAlign: TPanelAlign);
  end;

implementation

uses
  System.Math, GdiPlus,
  ExplorerMenu, Linkbar.Theme, Linkbar.OS, Linkbar.L10n;

{ TFormGroup }

constructor TFormGroup.CreateGroup(AOwner: TComponent; AOwnerWnd: HWND;
  const AFolder, ACaption: string; AIconSize: Integer);
var
  item: TItemShortcut;
  fileName: string;
begin
  inherited CreateNew(AOwner);

  FOwnerWnd := AOwnerWnd;
  FGroupCaption := ACaption;
  FIconSize := AIconSize;
  FHot := -1;

  BorderStyle := bsNone;
  FormStyle := fsStayOnTop;
  Position := poDesigned;
  DoubleBuffered := True;
  Font.Assign(Screen.IconFont);

  // Colors (follow Linkbar color mode)
  if (GlobalLook = ELookLight)
  then begin
    FBgColor := $00F3F3F3;
    FTextColor := clBlack;
    FBorderColor := $00D0D0D0;
    FHotColor := $14000000; // black 8%
  end
  else begin
    FBgColor := $002B2B2B;
    FTextColor := clWhite;
    FBorderColor := $00454545;
    FHotColor := $1AFFFFFF; // white 10%
  end;
  Color := FBgColor;

  // Load group content
  FItems := TObjectList<TItemShortcut>.Create(True);
  for fileName in TItemGroup.GetMemberFiles(AFolder) do
  begin
    item := TItemShortcut.Create;
    if item.LoadFromFile(fileName)
    then begin
      item.LoadIcon(FIconSize);
      FItems.Add(item);
    end
    else item.Free;
  end;

  CalcLayout;
end;

destructor TFormGroup.Destroy;
begin
  FItems.Free;
  inherited;
end;

function TFormGroup.Scale(const AValue: Integer): Integer;
begin
  Result := MulDiv(AValue, Screen.PixelsPerInch, 96);
end;

procedure TFormGroup.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := WS_POPUP;
  Params.ExStyle := (Params.ExStyle or WS_EX_TOOLWINDOW) and not WS_EX_APPWINDOW;
  Params.WindowClass.style := Params.WindowClass.style or CS_DROPSHADOW;
  Params.WndParent := FOwnerWnd;
end;

procedure TFormGroup.CalcLayout;
var
  bmp: Vcl.Graphics.TBitmap;
  textH, n: Integer;
begin
  bmp := Vcl.Graphics.TBitmap.Create;
  try
    bmp.Canvas.Font.Assign(Font);
    textH := bmp.Canvas.TextHeight('Wg');
  finally
    bmp.Free;
  end;

  FPad := Scale(8);
  FRadius := Scale(8);
  FCellW := Max(FIconSize + Scale(24), Scale(84));
  FCellH := Scale(10) + FIconSize + Scale(6) + textH * 2 + Scale(8);
  FHeaderHeight := Scale(10) + textH + Scale(6);

  n := FItems.Count;
  if (n <= 4) then FCols := Max(n, 1)
  else if (n <= 9) then FCols := 3
  else FCols := 4;
  FRows := Max(1, (n + FCols - 1) div FCols);

  if (n = 0)
  then begin
    // Room for the "empty group" hint
    FCols := 3;
    FRows := 1;
  end;

  ClientWidth := FPad * 2 + FCols * FCellW;
  ClientHeight := FHeaderHeight + FRows * FCellH + FPad;
end;

function TFormGroup.CellRect(const AIndex: Integer): TRect;
begin
  Result := Bounds(
    FPad + (AIndex mod FCols) * FCellW,
    FHeaderHeight + (AIndex div FCols) * FCellH,
    FCellW, FCellH);
end;

function TFormGroup.IndexAt(const APoint: TPoint): Integer;
var i: Integer;
begin
  for i := 0 to FItems.Count-1 do
    if CellRect(i).Contains(APoint)
    then Exit(i);
  Result := -1;
end;

procedure TFormGroup.SetHot(const AValue: Integer);
begin
  if (AValue = FHot)
  then Exit;
  FHot := AValue;
  Invalidate;
end;

procedure TFormGroup.DrawItemIcon(const AItem: TItemShortcut; const AX, AY: Integer);
var
  dc: HDC;
  old: HGDIOBJ;
  bm: Winapi.Windows.TBitmap;
  bf: TBlendFunction;
begin
  if (AItem.Bitmap = 0)
     or (GetObject(AItem.Bitmap, SizeOf(bm), @bm) = 0)
  then Exit;

  bf.BlendOp := AC_SRC_OVER;
  bf.BlendFlags := 0;
  bf.SourceConstantAlpha := 255;
  bf.AlphaFormat := AC_SRC_ALPHA;

  dc := CreateCompatibleDC(Canvas.Handle);
  old := SelectObject(dc, AItem.Bitmap);
  Winapi.Windows.AlphaBlend(Canvas.Handle, AX, AY, FIconSize, FIconSize,
    dc, 0, 0, bm.bmWidth, Abs(bm.bmHeight), bf);
  SelectObject(dc, old);
  DeleteDC(dc);
end;

procedure TFormGroup.Paint;
var
  i: Integer;
  r, tr: TRect;
  gp: IGPGraphics;
  brush: IGPBrush;
  s: string;
begin
  // Background + border
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := FBgColor;
  Canvas.FillRect(ClientRect);
  Canvas.Pen.Color := FBorderColor;
  Canvas.Brush.Style := bsClear;
  if IsWindows11OrAbove
  then Canvas.Rectangle(ClientRect)
  else Canvas.RoundRect(0, 0, ClientWidth, ClientHeight, FRadius * 2, FRadius * 2);

  SetBkMode(Canvas.Handle, TRANSPARENT);
  Canvas.Font.Assign(Font);
  Canvas.Font.Color := FTextColor;

  // Title
  Canvas.Font.Style := [fsBold];
  r := Rect(FPad, Scale(10), ClientWidth - FPad, FHeaderHeight);
  DrawText(Canvas.Handle, PChar(FGroupCaption), -1, r,
    DT_CENTER or DT_TOP or DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX);
  Canvas.Font.Style := [];

  // Empty group hint
  if (FItems.Count = 0)
  then begin
    s := L10NFind('Group.Empty', 'Empty group. Drag shortcuts onto the group icon.');
    r := Rect(FPad * 2, FHeaderHeight, ClientWidth - FPad * 2, ClientHeight - FPad);
    DrawText(Canvas.Handle, PChar(s), -1, r,
      DT_CENTER or DT_WORDBREAK or DT_NOPREFIX);
    Exit;
  end;

  // Items
  for i := 0 to FItems.Count-1 do
  begin
    r := CellRect(i);

    if (i = FHot)
    then begin
      gp := TGPGraphics.Create(Canvas.Handle);
      brush := TGPSolidBrush.Create(FHotColor);
      tr := r;
      tr.Inflate(-Scale(2), -Scale(2));
      GPFillRoundRect(gp, brush, tr, Scale(6));
      gp := nil;
    end;

    DrawItemIcon(FItems[i], r.Left + (r.Width - FIconSize) div 2, r.Top + Scale(10));

    tr := Rect(r.Left + Scale(4), r.Top + Scale(10) + FIconSize + Scale(6),
               r.Right - Scale(4), r.Bottom - Scale(4));
    DrawText(Canvas.Handle, PChar(FItems[i].Caption), -1, tr,
      DT_CENTER or DT_WORDBREAK or DT_EDITCONTROL or DT_END_ELLIPSIS or DT_NOPREFIX);
  end;
end;

procedure TFormGroup.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  SetHot(IndexAt(Point(X, Y)));
end;

procedure TFormGroup.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  i: Integer;
  pt: TPoint;
begin
  inherited;
  i := IndexAt(Point(X, Y));
  if (i < 0)
  then Exit;

  if (Button = mbLeft)
  then begin
    try
      OpenByDefaultVerb(FOwnerWnd, FItems[i].Pidl);
    finally
      Close;
    end;
  end
  else if (Button = mbRight)
  then begin
    pt := ClientToScreen(Point(X, Y));
    ExplorerMenuPopup(Handle, FItems[i].Pidl, pt, ssShift in Shift, 0);
  end;
end;

procedure TFormGroup.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_ESCAPE)
  then Close;
end;

procedure TFormGroup.DoClose(var Action: TCloseAction);
begin
  inherited;
  Action := caFree;
end;

procedure TFormGroup.WndProc(var Message: TMessage);
begin
  case Message.Msg of
    WM_ACTIVATE:
      // Close when user clicks outside
      if (LoWord(Message.WParam) = WA_INACTIVE)
      then PostMessage(Handle, WM_CLOSE, 0, 0);
    CM_MOUSELEAVE:
      SetHot(-1);
  end;
  inherited WndProc(Message);
end;

procedure TFormGroup.ApplyCorners;
var rgn: HRGN;
begin
  if IsWindows11OrAbove
  then ThemeSetRoundCorners11(Handle, False)
  else begin
    rgn := CreateRoundRectRgn(0, 0, Width + 1, Height + 1, FRadius * 2, FRadius * 2);
    SetWindowRgn(Handle, rgn, True); // the system owns rgn now
  end;
end;

procedure TFormGroup.PopupAt(const AItemRect: TRect; const AAlign: TPanelAlign);
var
  wa: TRect;
  L, T, gap: Integer;
begin
  gap := Scale(6);
  wa := Screen.MonitorFromRect(AItemRect, mdNearest).WorkareaRect;

  case AAlign of
    EPanelAlignTop:
      begin
        L := AItemRect.CenterPoint.X - Width div 2;
        T := AItemRect.Bottom + gap;
      end;
    EPanelAlignBottom:
      begin
        L := AItemRect.CenterPoint.X - Width div 2;
        T := AItemRect.Top - Height - gap;
      end;
    EPanelAlignLeft:
      begin
        L := AItemRect.Right + gap;
        T := AItemRect.CenterPoint.Y - Height div 2;
      end;
    else // EPanelAlignRight
      begin
        L := AItemRect.Left - Width - gap;
        T := AItemRect.CenterPoint.Y - Height div 2;
      end;
  end;

  L := Max(wa.Left, Min(L, wa.Right - Width));
  T := Max(wa.Top, Min(T, wa.Bottom - Height));

  SetBounds(L, T, Width, Height);
  ApplyCorners;
  Show;
  SetForegroundWindow(Handle);
end;

end.
