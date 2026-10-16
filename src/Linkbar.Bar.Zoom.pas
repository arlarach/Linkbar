{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   Magnification (dock zoom): the icons near the mouse }
{   grow and the row spreads out around it              }
{*******************************************************}

unit Linkbar.Bar.Zoom;

{$i linkbar.inc}

interface

uses
  Types,
  LBToolbar, Linkbar.Consts, Linkbar.Graphics, Linkbar.Bar.Host;

type
  TBarZoom = class
  private
    FHost: ILinkbarHost;
    FPercent: Integer;            // magnification 100..200 (100 = off)
    FCursor: Integer;             // mouse position along the bar, -1 = none
  public
    constructor Create(const AHost: ILinkbarHost);
    function Enabled: Boolean;
    // Extra thickness so magnified icons fit in the bar
    function Room: Integer;
    // Size of a fully magnified icon (0 when the zoom is off)
    function IconSizeValue: Integer;
    // Sets the percentage; True when it changed (the caller lays the bar out again)
    function ChangePercent(const AValue: Integer): Boolean;
    // Draws the items magnified around the mouse
    procedure Draw(const ABitmap: THBitmap);
    property Percent: Integer read FPercent write FPercent;
    property Cursor: Integer read FCursor write FCursor;
  end;

implementation

uses
  Windows, SysUtils, Math, Linkbar.Theme;

constructor TBarZoom.Create(const AHost: ILinkbarHost);
begin
  inherited Create;
  FHost := AHost;
  FCursor := -1;
end;

function TBarZoom.Enabled: Boolean;
begin
  Result := (FPercent > 100);
end;

function TBarZoom.Room: Integer;
begin
  if Enabled
  then Result := MulDiv(FHost.BarIconSize, FPercent - 100, 100)
  else Result := 0;
end;

function TBarZoom.IconSizeValue: Integer;
begin
  if Enabled
  then Result := MulDiv(FHost.BarIconSize, FPercent, 100)
  else Result := 0;
end;

function TBarZoom.ChangePercent(const AValue: Integer): Boolean;
begin
  var value := EnsureRange(AValue, ZOOM_MIN, ZOOM_MAX);
  Result := (value <> FPercent);
  if not Result
  then Exit;
  FPercent := value;
  FCursor := -1;
  FHost.BarItems.ZoomIconSize := IconSizeValue;
end;

{ Icons near the mouse grow (cosine falloff over ~2.5 slots), the row spreads
  out around the mouse so the icon under it stays under it }
procedure TBarZoom.Draw(const ABitmap: THBitmap);
const
  RANGE = 2.5; // slots affected on each side
var
  vertical: Boolean;
  list: TLBItemList;
  bs: TSize;
  io: TPoint;
  isz: Integer;
  z, d, f, shift, t, vis, cursor: Double;
  n, i, k, slot, size, x, y: Integer;
  scales, lens, starts: array of Double;
  base, vr: TRect;
  item: TItemBase;
  baseStart, baseLen: Double;
  gap, sepIdx: Integer;
  sr: TRect;
begin
  vertical := FHost.BarIsVertical;
  list := FHost.BarItems;
  bs := FHost.BarButtonSize;
  io := FHost.BarIconOffset;
  isz := FHost.BarIconSize;
  z := FPercent / 100;
  n := list.Count;
  if (n = 0) then Exit;
  if vertical then slot := bs.cy else slot := bs.cx;
  if (slot <= 0) then Exit;
  cursor := FCursor;

  SetLength(scales, n);
  SetLength(lens, n);
  SetLength(starts, n);

  // scale and enlarged length of every item
  for i := 0 to n-1 do
  begin
    base := list[i].Rect;
    if vertical
    then begin baseStart := base.Top;  baseLen := base.Height; end
    else begin baseStart := base.Left; baseLen := base.Width;  end;

    if list.IsSeparator(list[i])
    then scales[i] := 1
    else begin
      d := Abs(cursor - (baseStart + baseLen / 2)) / slot;
      if (d < RANGE)
      then f := (1 + Cos(Pi * d / RANGE)) / 2
      else f := 0;
      scales[i] := 1 + (z - 1) * f;
    end;
    lens[i] := baseLen * scales[i];
  end;

  // positions: keep the point under the mouse fixed
  if vertical then vis := list[0].Rect.Top else vis := list[0].Rect.Left;
  // gap before the pinned items (see TLBItemList.PinnedSepRect)
  gap := 0;
  sepIdx := -1;
  if not list.PinnedSepRect.IsEmpty
  then begin
    if vertical then gap := list.PinnedSepRect.Height else gap := list.PinnedSepRect.Width;
  end;
  for i := 0 to n-1 do
  begin
    if (gap > 0) and (i > 0) and list[i].Pinned and not list[i-1].Pinned
    then begin
      sepIdx := i;
      vis := vis + gap;
    end;
    starts[i] := vis;
    vis := vis + lens[i];
  end;

  k := -1;
  for i := 0 to n-1 do
  begin
    base := list[i].Rect;
    if vertical
    then begin baseStart := base.Top;  baseLen := base.Height; end
    else begin baseStart := base.Left; baseLen := base.Width;  end;
    if (cursor >= baseStart) and (cursor < baseStart + baseLen)
    then begin
      k := i;
      Break;
    end;
  end;

  if (k >= 0)
  then begin
    base := list[k].Rect;
    if vertical
    then begin baseStart := base.Top;  baseLen := base.Height; end
    else begin baseStart := base.Left; baseLen := base.Width;  end;
    t := (cursor - baseStart) / baseLen;
    shift := cursor - (starts[k] + t * lens[k]);
  end
  else begin
    // mouse before the first item: grow to the right; after the last: to the left
    if vertical
    then begin
      if (cursor < list[0].Rect.Top) then shift := 0
      else shift := list[n-1].Rect.Bottom - (starts[n-1] + lens[n-1]);
    end
    else begin
      if (cursor < list[0].Rect.Left) then shift := 0
      else shift := list[n-1].Rect.Right - (starts[n-1] + lens[n-1]);
    end;
  end;

  // draw
  if (sepIdx >= 0) and (FHost.BarSeparatorStyle <> ESeparatorStyleSpace)
  then begin
    sr := list.PinnedSepRect;
    if vertical
    then sr := Rect(sr.Left, Round(starts[sepIdx] - gap + shift), sr.Right, Round(starts[sepIdx] + shift))
    else sr := Rect(Round(starts[sepIdx] - gap + shift), sr.Top, Round(starts[sepIdx] + shift), sr.Bottom);
    ThemeDrawSeparator(ABitmap, FHost.BarAlign, sr);
  end;

  for i := 0 to n-1 do
  begin
    item := list[i];
    base := item.Rect;
    if vertical
    then vr := Rect(base.Left, Round(starts[i] + shift), base.Right, Round(starts[i] + shift + lens[i]))
    else vr := Rect(Round(starts[i] + shift), base.Top, Round(starts[i] + shift + lens[i]), base.Bottom);

    if list.IsSeparator(item)
    then begin
      if (FHost.BarSeparatorStyle <> ESeparatorStyleSpace)
      then ThemeDrawSeparator(ABitmap, FHost.BarAlign, vr);
      Continue;
    end;

    size := Round(isz * scales[i]);
    if vertical
    then begin
      y := vr.Top + (vr.Height - size) div 2;
      x := base.Left + io.X + (isz - size) div 2;   // grows to both sides
    end
    else begin
      x := vr.Left + (vr.Width - size) div 2;
      y := base.Top + io.Y + (isz - size) div 2;    // grows to both sides
    end;

    list.DrawScaled(ABitmap.Dc, item, x, y, size);
    FHost.BarDrawItemMarks(ABitmap, item, vr);
  end;
end;

end.
