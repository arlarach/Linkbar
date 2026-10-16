{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   Dock style: free space at both ends, window bounds  }
{   along the screen edge, rounded background and the   }
{   Ctrl + drag that slides the dock along the edge     }
{*******************************************************}

unit Linkbar.Bar.Dock;

{$i linkbar.inc}

interface

uses
  Types,
  Linkbar.Graphics, Linkbar.Bar.Host, Linkbar.Bar.Collapse, Linkbar.Bar.Zoom;

type
  // What the dock needs from the bar window
  IDockHost = interface(ICollapseHost)
    ['{B6E41D07-92AC-4F35-8D1B-3A5C7E0F9248}']
    // Length of the expanded bar along its edge
    function BarExpandedLength(const AVertical: Boolean): Integer;
    function BarOpaque: Boolean;
  end;

  TBarDock = class
  private
    FHost: IDockHost;
    FZoom: TBarZoom;
    FPos: Integer;                // position along the edge 0..1000
    FSliding: Boolean;            // Ctrl+drag in progress
    FSlideMoved: Boolean;
    FSlideStartCursor: TPoint;
    FSlideStartPos: TPoint;
    procedure Slide(const ACursor: TPoint);
  public
    constructor Create(const AHost: IDockHost; const AZoom: TBarZoom);
    // Free space at both ends so magnified end icons are not cut
    function Pad: Integer;
    // Dock bounds: only as long as its content, centered, slightly away from the edge
    procedure CalcBounds(var AX, AY, AWidth, AHeight: Integer);
    // Rounded rectangle with anti-aliased edges and a thin border, written directly
    // as premultiplied pixels (correct alpha)
    procedure DrawBackground(const ABitmap: THBitmap; const AClipRect: TRect);
    // Start of the Ctrl + drag
    procedure BeginSlide;
    // Mouse move while sliding
    procedure Drag;
    // Remember the position as a fraction of the free space (survives resolution changes)
    procedure SavePos;
    // Center the dock again
    procedure ResetPos;
    property Pos: Integer read FPos write FPos;
    property Sliding: Boolean read FSliding write FSliding;
    property SlideMoved: Boolean read FSlideMoved;
  end;

implementation

uses
  Windows, SysUtils, Math, Vcl.Controls, Vcl.Forms,
  Linkbar.Consts, Linkbar.Settings;

constructor TBarDock.Create(const AHost: IDockHost; const AZoom: TBarZoom);
begin
  inherited Create;
  FHost := AHost;
  FZoom := AZoom;
  FPos := DEF_DOCK_POS;
end;

function TBarDock.Pad: Integer;
begin
  if not FHost.BarIsDock
  then Exit(0);
  if FZoom.Enabled
  then begin
    var bs := FHost.BarButtonSize;
    Result := MulDiv(Max(bs.cx, bs.cy), FZoom.Percent - 100, 100);
  end
  else Result := FHost.ScaleValue(4);
end;

procedure TBarDock.CalcBounds(var AX, AY, AWidth, AHeight: Integer);
var
  wa: TRect;
  len, len_exp, gap: Integer;
  vertical, collapsed: Boolean;
  align: TPanelAlign;
begin
  wa := FHost.BarWorkArea;
  gap := FHost.ScaleValue(6);
  vertical := FHost.BarIsVertical;
  align := FHost.BarAlign;
  collapsed := FHost.BarIsCollapsed;

  len_exp := FHost.BarExpandedLength(vertical);
  if collapsed then
    len := FHost.BarCollapsedLength(vertical)
  else
    len := len_exp;

  if vertical
  then begin
    len_exp := Min(len_exp, wa.Height);
    len := Min(len, wa.Height);
    AHeight := len;
    AY := wa.Top + MulDiv(wa.Height - len_exp, FPos, 1000);
    if collapsed then
      AY := AY + (len_exp - len);

    if (align = EPanelAlignLeft)
    then AX := wa.Left + gap
    else AX := wa.Right - AWidth - gap;
  end
  else begin
    len_exp := Min(len_exp, wa.Width);
    len := Min(len, wa.Width);
    AWidth := len;
    AX := wa.Left + MulDiv(wa.Width - len_exp, FPos, 1000);
    if collapsed then
      AX := AX + (len_exp - len);

    if (align = EPanelAlignTop)
    then AY := wa.Top + gap
    else AY := wa.Bottom - AHeight - gap;
  end;
end;

{ Dock background: rounded rectangle with anti-aliased edges and a thin
  border, written directly as premultiplied pixels (correct alpha) }
procedure TBarDock.DrawBackground(const ABitmap: THBitmap; const AClipRect: TRect);

  // 0..1 coverage of pixel center (fx, fy) by a rounded rect
  function Coverage(fx, fy: Double; const R: TRect; Radius: Double): Double;
  var dx, dy: Double;
  begin
    if (fx < R.Left) or (fx > R.Right) or (fy < R.Top) or (fy > R.Bottom)
    then begin
      // outside the box: soft edge of half a pixel
      dx := Max(Max(R.Left - fx, fx - R.Right), 0);
      dy := Max(Max(R.Top - fy, fy - R.Bottom), 0);
      Exit(EnsureRange(0.5 - Sqrt(dx*dx + dy*dy), 0, 1));
    end;
    dx := 0;
    if (fx < R.Left + Radius) then dx := R.Left + Radius - fx
    else if (fx > R.Right - Radius) then dx := fx - (R.Right - Radius);
    dy := 0;
    if (fy < R.Top + Radius) then dy := R.Top + Radius - fy
    else if (fy > R.Bottom - Radius) then dy := fy - (R.Bottom - Radius);
    if (dx = 0) or (dy = 0)
    then begin
      // straight edges: distance to the nearest side
      Result := EnsureRange(Min(Min(fx - R.Left, R.Right - fx), Min(fy - R.Top, R.Bottom - fy)) + 0.5, 0, 1);
    end
    else Result := EnsureRange(Radius - Sqrt(dx*dx + dy*dy) + 0.5, 0, 1);
  end;

var
  color, a, ba, br, bg, bb, cr, cg, cb: Cardinal;
  outer, inner, clip: TRect;
  radius, covO, covI, fa, fb: Double;
  x, y: Integer;
  row: PByte;
  px: PCardinal;
  oa, orr, og, ob: Double;
begin
  if (ABitmap.Bits = nil)
  then Exit;

  // fill color (ARGB); opaque mode = fully opaque
  color := FHost.BarBackgroundColor;
  a := color shr 24;
  if FHost.BarOpaque then a := 255;
  if (a < 8) then a := 8; // keep it clickable
  cr := (color shr 16) and $FF;
  cg := (color shr 8) and $FF;
  cb := color and $FF;

  // thin border: light on dark, dark on light
  if (GlobalLook = ELookLight)
  then begin ba := 50; br := 0; bg := 0; bb := 0; end
  else begin ba := 60; br := 255; bg := 255; bb := 255; end;

  outer := Rect(0, 0, ABitmap.Width, ABitmap.Height);
  inner := Rect(1, 1, ABitmap.Width - 1, ABitmap.Height - 1);
  radius := Min(FHost.ScaleValue(14), Min(ABitmap.Width, ABitmap.Height) div 2);

  clip := AClipRect;
  if not clip.IntersectsWith(outer) then Exit;
  clip.Intersect(outer);

  for y := clip.Top to clip.Bottom - 1 do
  begin
    row := PByte(ABitmap.Bits) + y * ABitmap.Pitch;
    for x := clip.Left to clip.Right - 1 do
    begin
      px := PCardinal(row + x * 4);
      covO := Coverage(x + 0.5, y + 0.5, outer, radius);
      covI := Coverage(x + 0.5, y + 0.5, inner, Max(radius - 1, 0));
      fa := (a / 255) * covI;          // fill alpha
      fb := (ba / 255) * Max(covO - covI, 0); // border alpha
      // composite border over fill (premultiplied)
      oa := fb + fa * (1 - fb);
      orr := br * fb + cr * fa * (1 - fb);
      og := bg * fb + cg * fa * (1 - fb);
      ob := bb * fb + cb * fa * (1 - fb);
      px^ := (Cardinal(Round(oa * 255)) shl 24)
          or (Cardinal(Round(orr)) shl 16)
          or (Cardinal(Round(og)) shl 8)
          or  Cardinal(Round(ob));
    end;
  end;
end;

procedure TBarDock.BeginSlide;
begin
  FSliding := True;
  FSlideMoved := False;
  GetCursorPos(FSlideStartCursor);
  FSlideStartPos := FHost.BarBounds.TopLeft;
end;

{ Move the dock along its edge following the mouse (Ctrl+drag) }
procedure TBarDock.Slide(const ACursor: TPoint);
var
  wa, b: TRect;
  l, t: Integer;
begin
  wa := FHost.BarWorkArea;
  b := FHost.BarBounds;
  l := FSlideStartPos.X;
  t := FSlideStartPos.Y;
  if FHost.BarIsVertical
  then t := EnsureRange(t + ACursor.Y - FSlideStartCursor.Y, wa.Top, Max(wa.Top, wa.Bottom - b.Height))
  else l := EnsureRange(l + ACursor.X - FSlideStartCursor.X, wa.Left, Max(wa.Left, wa.Right - b.Width));
  FHost.BarMoveTo(l, t);
end;

procedure TBarDock.Drag;
var p: TPoint;
begin
  GetCursorPos(p);
  if (not FSlideMoved)
     and (Abs(p.X - FSlideStartCursor.X) + Abs(p.Y - FSlideStartCursor.Y) > PANEL_DRAG_THRESHOLD)
  then begin
    FSlideMoved := True;
    if FHost.BarIsVertical
    then Screen.Cursor := crSizeNS
    else Screen.Cursor := crSizeWE;
  end;
  if FSlideMoved
  then Slide(p);
end;

procedure TBarDock.SavePos;
var
  wa, b: TRect;
  range, pos, len_exp: Integer;
  vertical, collapsed: Boolean;
begin
  vertical := FHost.BarIsVertical;
  collapsed := FHost.BarIsCollapsed;
  len_exp := FHost.BarExpandedLength(vertical);
  wa := FHost.BarWorkArea;
  b := FHost.BarBounds;

  if vertical
  then begin
    len_exp := Min(len_exp, wa.Height);
    range := wa.Height - len_exp;
    pos := b.Top - wa.Top;
    if collapsed then pos := pos - (len_exp - b.Height);
  end
  else begin
    len_exp := Min(len_exp, wa.Width);
    range := wa.Width - len_exp;
    pos := b.Left - wa.Left;
    if collapsed then pos := pos - (len_exp - b.Width);
  end;

  if (range > 0)
  then FPos := EnsureRange(MulDiv(pos, 1000, range), 0, 1000)
  else FPos := DEF_DOCK_POS;
  TSettingsFile.Write(FHost.BarSettingsFile, INI_DOCK_POS, FPos);
end;

procedure TBarDock.ResetPos;
begin
  FPos := DEF_DOCK_POS;
  TSettingsFile.Write(FHost.BarSettingsFile, INI_DOCK_POS, FPos);
end;

end.
