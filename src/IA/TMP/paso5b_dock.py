import re


def rd(path):
    return open(path, 'rb').read().decode('utf-8').replace('\r\n', '\n')


def wr(path, text):
    open(path, 'wb').write(text.replace('\n', '\r\n').encode('utf-8'))


def seg(s, start, end):
    a = s.index(start)
    b = s.index(end)
    assert a < b
    return s[a:b]


def rep(s, old, new, count=1):
    assert s.count(old) >= 1, old
    if count:
        assert s.count(old) == count, (old, s.count(old))
    return s.replace(old, new)


# ---------- 1. Host base ----------
h = rd('Linkbar.Bar.Host.pas')
h = rep(h, '    function BarItems: TLBItemList;\n',
        '    function BarItems: TLBItemList;\n'
        '    function BarSettingsFile: string;\n'
        '    // Work area of the monitor of the bar\n'
        '    function BarWorkArea: TRect;\n'
        '    // Bounds of the bar window\n'
        '    function BarBounds: TRect;\n'
        '    // Moves the window keeping its size\n'
        '    procedure BarMoveTo(const AX, AY: Integer);\n')
wr('Linkbar.Bar.Host.pas', h)
l = rd('Linkbar.Bar.Launcher.pas')
l = rep(l, '    function BarSettingsFile: string;\n', '')
wr('Linkbar.Bar.Launcher.pas', l)

p = 'mUnit.pas'
s = rd(p)

# ---------- 2. DrawBackground a partir del texto actual (sin tocar el original) ----------
orig_draw = seg(s, '{ Dock background: rounded rectangle with anti-aliased edges and a thin', '{ Move the dock along its edge')
draw = orig_draw.replace('procedure TLinkbarWcl.DrawDockBackground(', 'procedure TBarDock.DrawBackground(')
draw = rep(draw, '  color := BackgroundColor;', '  color := FHost.BarBackgroundColor;')
draw = rep(draw, '  if (FTransparencyMode = tmOpaque) then a := 255;', '  if FHost.BarOpaque then a := 255;')
draw = draw.replace('ScaleDimension(', 'FHost.ScaleValue(')
assert 'FTransparencyMode' not in draw and 'BackgroundColor;' in draw

UNIT = """{*******************************************************}
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
    function BarIsDock: Boolean;
    // Length of the expanded bar along its edge
    function BarExpandedLength(const AVertical: Boolean): Integer;
    function BarBackgroundColor: Cardinal;
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

""" + draw.rstrip() + """

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
"""
wr('Linkbar.Bar.Dock.pas', UNIT)

# ---------- 3. mUnit.pas ----------
# quitar implementaciones que se mueven (usando el texto original, no el transformado)
s = s.replace(orig_draw, '')
s = s.replace(seg(s, '{ Dock bounds: only as long as its content', '{ Rounded corners for the dock'), '')
s = s.replace(seg(s, '{ Move the dock along its edge following the mouse (Ctrl+drag) }', 'procedure TLinkbarWcl.SetBarStyle'), '')
s = s.replace(seg(s, '{ Dock: free space at both ends so magnified end icons are not cut }', 'function TLinkbarWcl.ItemsMargin: Integer;'),
              '{ Dock: free space at both ends so magnified end icons are not cut }\n'
              'function TLinkbarWcl.DockPad: Integer;\nbegin\n  if Assigned(FDock)\n  then Result := FDock.Pad\n  else Result := 0;\nend;\n\n')

# implementacion del host del dock
HOST = """function TLinkbarWcl.BarIsDock: Boolean;
begin
  Result := IsDock;
end;

function TLinkbarWcl.BarExpandedLength(const AVertical: Boolean): Integer;
begin
  Result := Items.LineWidth + 2 * ItemsMargin + FSysWidgets.ReservedLength(AVertical);
end;

function TLinkbarWcl.BarBackgroundColor: Cardinal;
begin
  Result := BackgroundColor;
end;

function TLinkbarWcl.BarOpaque: Boolean;
begin
  Result := (FTransparencyMode = tmOpaque);
end;

function TLinkbarWcl.BarWorkArea: TRect;
begin
  Result := Screen.Monitors[EnsureRange(FMonitorNum, 0, Screen.MonitorCount - 1)].WorkareaRect;
end;

function TLinkbarWcl.BarBounds: TRect;
begin
  Result := BoundsRect;
end;

procedure TLinkbarWcl.BarMoveTo(const AX, AY: Integer);
begin
  SetWindowPos(Handle, 0, AX, AY, 0, 0, SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE);
  FBeforeAutoHideBound := Bounds(AX, AY, Width, Height);
end;

"""
s = rep(s, 'procedure TLinkbarWcl.SetBarStyle(AValue: Integer);', HOST + 'procedure TLinkbarWcl.SetBarStyle(AValue: Integer);')

# ratón
s = rep(s, '    FDockSliding := True;\n    FSlideMoved := False;\n    GetCursorPos(FSlideStartCursor);\n    FSlideStartPos := BoundsRect.TopLeft;\n',
        '    FDock.BeginSlide;\n')
a = s.index('  if FDockSliding\n  then begin\n    var p: TPoint;')
b = s.index('    Exit;\n  end;\n', a) + len('    Exit;\n  end;\n')
s = s[:a] + '  if FDock.Sliding\n  then begin\n    FDock.Drag;\n    Exit;\n  end;\n' + s[b:]
s = rep(s, '    if FSlideMoved\n    then SaveDockPos\n', '    if FDock.SlideMoved\n    then FDock.SavePos\n')
s = rep(s, '      FDockPos := DEF_DOCK_POS;\n      TSettingsFile.Write(FSettingsFileName, INI_DOCK_POS, FDockPos);\n', '      FDock.ResetPos;\n')

# declaraciones
s = rep(s, 'IActionButtonsHost, IZoomHost)', 'IActionButtonsHost, IZoomHost, IDockHost)')
s = rep(s, '    FDockPos: Integer;           // dock position along the edge 0..1000\n    FDockSliding: Boolean;       // Ctrl+drag in progress\n    FSlideMoved: Boolean;\n    FSlideStartCursor: TPoint;\n    FSlideStartPos: TPoint;\n',
        '    FDock: TBarDock;             // dock style\n')
for d in ['    procedure DockBounds(var AX, AY, AWidth, AHeight: Integer);\n', '    procedure SlideDock(const ACursor: TPoint);\n',
          '    procedure DrawDockBackground(const ABitmap: THBitmap; const AClipRect: TRect);\n', '    procedure SaveDockPos;\n']:
    s = rep(s, d, '')
s = rep(s, '    procedure BarPinnedChanged;\n',
        '    procedure BarPinnedChanged;\n'
        '    // IDockHost\n'
        '    function BarIsDock: Boolean;\n'
        '    function BarExpandedLength(const AVertical: Boolean): Integer;\n'
        '    function BarBackgroundColor: Cardinal;\n'
        '    function BarOpaque: Boolean;\n'
        '    function BarWorkArea: TRect;\n'
        '    function BarBounds: TRect;\n'
        '    procedure BarMoveTo(const AX, AY: Integer);\n')
s = rep(s, 'DockBounds(x, y, w, h)', 'FDock.CalcBounds(x, y, w, h)')
s = rep(s, 'DrawDockBackground(ABitmap, AClipRect)', 'FDock.DrawBackground(ABitmap, AClipRect)')
s = re.sub(r'\bFDockPos\b', 'FDock.Pos', s)
s = re.sub(r'\bFDockSliding\b', 'FDock.Sliding', s)

s = rep(s, '  FZoom := TBarZoom.Create(Self);\n', '  FZoom := TBarZoom.Create(Self);\n  FDock := TBarDock.Create(Self, FZoom);\n')
s = rep(s, '  FreeAndNil(FZoom);\n', '  FreeAndNil(FDock);\n  FreeAndNil(FZoom);\n')
s = rep(s, 'Linkbar.Bar.ActionButtons, Linkbar.Bar.Zoom;', 'Linkbar.Bar.ActionButtons, Linkbar.Bar.Zoom, Linkbar.Bar.Dock;')
wr(p, s)

d = rd('Linkbar.dproj')
k = '        <DCCReference Include="Linkbar.Bar.Zoom.pas"/>'
d = rep(d, k, k + '\n        <DCCReference Include="Linkbar.Bar.Dock.pas"/>')
wr('Linkbar.dproj', d)
