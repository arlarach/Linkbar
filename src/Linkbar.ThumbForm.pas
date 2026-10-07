{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   Live window thumbnails (like the Windows taskbar)   }
{*******************************************************}

unit Linkbar.ThumbForm;

{$i linkbar.inc}

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes, System.Types, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls,
  Linkbar.Consts;

type
  { Popup with live DWM thumbnails of the windows of a program.
    Shown without activation; closes itself when the mouse leaves
    both the bar item (anchor) and the popup. }
  TFormThumbs = class(TForm)
  private
    FOwnerWnd: HWND;
    FWnds: TArray<HWND>;
    FThumbs: TArray<THandle>;
    FTiles: TArray<TRect>;
    FAnchor: TRect;
    FHot: Integer;
    FTimer: TTimer;
    FVertical: Boolean;
    FTitleH, FThumbW, FThumbH, FPad: Integer;
    FBgColor, FTextColor, FHotColor, FBorderColor: TColor;
    function Scale(const AValue: Integer): Integer;
    procedure CalcLayout;
    procedure RegisterThumbs;
    procedure UnregisterThumbs;
    function ThumbArea(const AIndex: Integer): TRect;
    function TileAt(const APoint: TPoint): Integer;
    procedure SetHot(const AValue: Integer);
    procedure TimerCheck(Sender: TObject);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Paint; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DoClose(var Action: TCloseAction); override;
    procedure WndProc(var Message: TMessage); override;
  public
    constructor CreateThumbs(AOwner: TComponent; AOwnerWnd: HWND;
      const AWnds: TArray<HWND>; AVertical: Boolean);
    destructor Destroy; override;
    procedure PopupAt(const AItemRect: TRect; const AAlign: TPanelAlign);
  end;

implementation

uses
  System.Math, LBToolbar;

const
  MAX_THUMBS = 6;

  LB_DWM_TNP_RECTDESTINATION      = $01;
  LB_DWM_TNP_OPACITY              = $04;
  LB_DWM_TNP_VISIBLE              = $08;
  LB_DWM_TNP_SOURCECLIENTAREAONLY = $10;

type
  TLBDwmThumbProps = record
    dwFlags: DWORD;
    rcDestination: TRect;
    rcSource: TRect;
    opacity: Byte;
    fVisible: BOOL;
    fSourceClientAreaOnly: BOOL;
  end;

function LB_DwmRegisterThumbnail(hwndDestination, hwndSource: HWND;
  out phThumbnailId: THandle): HResult; stdcall;
  external 'dwmapi.dll' name 'DwmRegisterThumbnail';
function LB_DwmUnregisterThumbnail(hThumbnailId: THandle): HResult; stdcall;
  external 'dwmapi.dll' name 'DwmUnregisterThumbnail';
function LB_DwmUpdateThumbnailProperties(hThumbnailId: THandle;
  ptnProperties: Pointer): HResult; stdcall;
  external 'dwmapi.dll' name 'DwmUpdateThumbnailProperties';
function LB_DwmQueryThumbnailSourceSize(hThumbnailId: THandle;
  out pSize: TSize): HResult; stdcall;
  external 'dwmapi.dll' name 'DwmQueryThumbnailSourceSize';

{ TFormThumbs }

constructor TFormThumbs.CreateThumbs(AOwner: TComponent; AOwnerWnd: HWND;
  const AWnds: TArray<HWND>; AVertical: Boolean);
begin
  inherited CreateNew(AOwner);
  FOwnerWnd := AOwnerWnd;
  FWnds := Copy(AWnds, 0, Min(Length(AWnds), MAX_THUMBS));
  FVertical := AVertical;
  FHot := -1;

  BorderStyle := bsNone;
  Position := poDesigned;
  DoubleBuffered := True;
  Font.Assign(Screen.IconFont);

  if (GlobalLook = ELookLight)
  then begin
    FBgColor := $00F3F3F3;
    FTextColor := clBlack;
    FHotColor := $00E0E0E0;
    FBorderColor := $00D0D0D0;
  end
  else begin
    FBgColor := $002B2B2B;
    FTextColor := clWhite;
    FHotColor := $00404040;
    FBorderColor := $00454545;
  end;
  Color := FBgColor;

  CalcLayout;

  FTimer := TTimer.Create(Self);
  FTimer.Interval := 200;
  FTimer.OnTimer := TimerCheck;
  FTimer.Enabled := False;
end;

destructor TFormThumbs.Destroy;
begin
  UnregisterThumbs;
  inherited;
end;

function TFormThumbs.Scale(const AValue: Integer): Integer;
begin
  Result := MulDiv(AValue, Screen.PixelsPerInch, 96);
end;

procedure TFormThumbs.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := WS_POPUP;
  Params.ExStyle := (Params.ExStyle or WS_EX_TOOLWINDOW or WS_EX_TOPMOST or WS_EX_NOACTIVATE)
    and not WS_EX_APPWINDOW;
  Params.WindowClass.style := Params.WindowClass.style or CS_DROPSHADOW;
  Params.WndParent := FOwnerWnd;
end;

procedure TFormThumbs.CalcLayout;
var
  i, tileW, tileH: Integer;
begin
  FPad := Scale(8);
  FTitleH := Scale(22);
  FThumbW := Scale(200);
  FThumbH := Scale(120);
  tileW := FThumbW + Scale(12);
  tileH := FTitleH + FThumbH + Scale(12);

  SetLength(FTiles, Length(FWnds));
  for i := 0 to High(FWnds) do
  begin
    if FVertical
    then FTiles[i] := Bounds(FPad, FPad + i * (tileH + FPad), tileW, tileH)
    else FTiles[i] := Bounds(FPad + i * (tileW + FPad), FPad, tileW, tileH);
  end;

  if FVertical
  then begin
    ClientWidth := tileW + FPad * 2;
    ClientHeight := Length(FWnds) * (tileH + FPad) + FPad;
  end
  else begin
    ClientWidth := Length(FWnds) * (tileW + FPad) + FPad;
    ClientHeight := tileH + FPad * 2;
  end;
end;

{ Area of the tile reserved for the thumbnail }
function TFormThumbs.ThumbArea(const AIndex: Integer): TRect;
var r: TRect;
begin
  r := FTiles[AIndex];
  Result := Rect(r.Left + Scale(6), r.Top + FTitleH + Scale(4), r.Right - Scale(6), r.Bottom - Scale(6));
end;

procedure TFormThumbs.RegisterThumbs;
var
  i: Integer;
  props: TLBDwmThumbProps;
  src: TSize;
  area, dst: TRect;
  k: Double;
  w, h: Integer;
begin
  SetLength(FThumbs, Length(FWnds));
  for i := 0 to High(FWnds) do
  begin
    FThumbs[i] := 0;
    if Failed(LB_DwmRegisterThumbnail(Handle, FWnds[i], FThumbs[i]))
    then begin
      FThumbs[i] := 0;
      Continue;
    end;

    // Fit the source window into the area, keeping the aspect ratio
    area := ThumbArea(i);
    dst := area;
    if Succeeded(LB_DwmQueryThumbnailSourceSize(FThumbs[i], src))
       and (src.cx > 0) and (src.cy > 0)
    then begin
      k := Min(area.Width / src.cx, area.Height / src.cy);
      if (k > 1) then k := 1;
      w := Round(src.cx * k);
      h := Round(src.cy * k);
      dst := Bounds(area.Left + (area.Width - w) div 2, area.Top + (area.Height - h) div 2, w, h);
    end;

    FillChar(props, SizeOf(props), 0);
    props.dwFlags := LB_DWM_TNP_RECTDESTINATION or LB_DWM_TNP_VISIBLE
      or LB_DWM_TNP_OPACITY or LB_DWM_TNP_SOURCECLIENTAREAONLY;
    props.rcDestination := dst;
    props.opacity := 255;
    props.fVisible := True;
    props.fSourceClientAreaOnly := False;
    LB_DwmUpdateThumbnailProperties(FThumbs[i], @props);
  end;
end;

procedure TFormThumbs.UnregisterThumbs;
var i: Integer;
begin
  for i := 0 to High(FThumbs) do
    if (FThumbs[i] <> 0)
    then LB_DwmUnregisterThumbnail(FThumbs[i]);
  SetLength(FThumbs, 0);
end;

function TFormThumbs.TileAt(const APoint: TPoint): Integer;
var i: Integer;
begin
  for i := 0 to High(FTiles) do
    if FTiles[i].Contains(APoint)
    then Exit(i);
  Result := -1;
end;

procedure TFormThumbs.SetHot(const AValue: Integer);
begin
  if (AValue = FHot) then Exit;
  FHot := AValue;
  Invalidate;
end;

procedure TFormThumbs.Paint;
var
  i: Integer;
  r: TRect;
  title: array[0..255] of Char;
  s: string;
begin
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := FBgColor;
  Canvas.FillRect(ClientRect);
  Canvas.Pen.Color := FBorderColor;
  Canvas.Brush.Style := bsClear;
  Canvas.Rectangle(ClientRect);

  SetBkMode(Canvas.Handle, TRANSPARENT);
  Canvas.Font.Assign(Font);
  Canvas.Font.Color := FTextColor;

  for i := 0 to High(FTiles) do
  begin
    if (i = FHot)
    then begin
      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := FHotColor;
      Canvas.Pen.Style := psClear;
      Canvas.RoundRect(FTiles[i].Left, FTiles[i].Top, FTiles[i].Right, FTiles[i].Bottom, Scale(8), Scale(8));
      Canvas.Pen.Style := psSolid;
      Canvas.Brush.Style := bsClear;
    end;

    title[0] := #0;
    GetWindowText(FWnds[i], title, Length(title));
    s := string(title);
    r := Rect(FTiles[i].Left + Scale(6), FTiles[i].Top + Scale(4), FTiles[i].Right - Scale(6), FTiles[i].Top + FTitleH);
    DrawText(Canvas.Handle, PChar(s), -1, r,
      DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX);
  end;
end;

procedure TFormThumbs.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  SetHot(TileAt(Point(X, Y)));
end;

procedure TFormThumbs.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var i: Integer;
begin
  inherited;
  i := TileAt(Point(X, Y));
  if (i < 0) then Exit;

  case Button of
    mbLeft:   SwitchToWindow(FWnds[i]);                 // bring to front
    mbMiddle: PostMessage(FWnds[i], WM_CLOSE, 0, 0);    // close that window
  end;
  Close;
end;

procedure TFormThumbs.DoClose(var Action: TCloseAction);
begin
  inherited;
  FTimer.Enabled := False;
  if HandleAllocated
  then ShowWindow(Handle, SW_HIDE);
  Action := caFree;
end;

procedure TFormThumbs.WndProc(var Message: TMessage);
begin
  case Message.Msg of
    WM_MOUSEACTIVATE:
      begin
        // never take focus away from the user's window
        Message.Result := MA_NOACTIVATE;
        Exit;
      end;
    CM_MOUSELEAVE:
      SetHot(-1);
  end;
  inherited WndProc(Message);
end;

{ Close when the mouse is neither on the bar item nor on the popup
  (the gap between them counts as inside) }
procedure TFormThumbs.TimerCheck(Sender: TObject);
var
  pt: TPoint;
  zone: TRect;
begin
  GetCursorPos(pt);
  zone := TRect.Union(FAnchor, BoundsRect);
  if not zone.Contains(pt)
  then Close;
end;

procedure TFormThumbs.PopupAt(const AItemRect: TRect; const AAlign: TPanelAlign);
var
  wa: TRect;
  L, T, gap: Integer;
begin
  FAnchor := AItemRect;
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
    else
      begin
        L := AItemRect.Left - Width - gap;
        T := AItemRect.CenterPoint.Y - Height div 2;
      end;
  end;
  L := Max(wa.Left, Min(L, wa.Right - Width));
  T := Max(wa.Top, Min(T, wa.Bottom - Height));

  // Create the window, attach the live thumbnails, show without activation
  SetBounds(L, T, Width, Height);
  HandleNeeded;
  RegisterThumbs;
  SetWindowPos(Handle, HWND_TOPMOST, L, T, Width, Height, SWP_SHOWWINDOW or SWP_NOACTIVATE);
  FTimer.Enabled := True;
end;

end.
