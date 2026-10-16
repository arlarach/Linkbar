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


p = 'mUnit.pas'
s = rd(p)

# ---------- 1. unidad nueva: el dibujo ampliado sale del texto actual ----------
draw = seg(s, '{ Icons near the mouse grow (cosine falloff over ~2.5 slots)', '{ ---------- CPU / RAM widgets ---------- }')
draw = draw.replace('procedure TLinkbarWcl.DrawItemsZoomed;', 'procedure TBarZoom.Draw(const ABitmap: THBitmap);')
draw = draw.replace('  vertical: Boolean;\n  z, d, f', '  vertical: Boolean;\n  list: TLBItemList;\n  bs: TSize;\n  io: TPoint;\n  isz: Integer;\n  z, d, f')
draw = rep(draw, 'begin\n  vertical := IsVertical(Align);\n  z := FZoomPercent / 100;\n  n := Items.Count;',
           'begin\n  vertical := FHost.BarIsVertical;\n  list := FHost.BarItems;\n  bs := FHost.BarButtonSize;\n  io := FHost.BarIconOffset;\n  isz := FHost.BarIconSize;\n  z := FPercent / 100;\n  n := list.Count;')
draw = draw.replace('ButtonSize.', 'bs.')
draw = draw.replace('cursor := FZoomCursor;', 'cursor := FCursor;')
draw = re.sub(r'\bItems\b', 'list', draw)
draw = draw.replace('FSeparatorStyle', 'FHost.BarSeparatorStyle')
draw = draw.replace('ThemeDrawSeparator(BitmapPanel, Align, ', 'ThemeDrawSeparator(ABitmap, FHost.BarAlign, ')
draw = draw.replace('BitmapPanel', 'ABitmap')
draw = draw.replace('FIconOffset.', 'io.')
draw = re.sub(r'\bIconSize\b', 'isz', draw)
draw = draw.replace('    FRunning.DrawMark(ABitmap, item, vr);\n    FPinned.DrawMark(ABitmap, item, vr);\n', '    FHost.BarDrawItemMarks(ABitmap, item, vr);\n')
assert 'Align,' not in draw.replace('FHost.BarAlign,', '')

UNIT = """{*******************************************************}
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
  // What the zoom needs from the bar window
  IZoomHost = interface(ILinkbarHost)
    ['{7A5C2E83-1D94-4F60-B8E2-0C3D6F9A4157}']
    // Offset of the icon inside the button of an item
    function BarIconOffset: TPoint;
    function BarSeparatorStyle: TSeparatorStyle;
    // Draws the "program is open" pill and the pinned dot of an item
    procedure BarDrawItemMarks(const ABitmap: THBitmap; const AItem: TItemBase; const ARect: TRect);
  end;

  TBarZoom = class
  private
    FHost: IZoomHost;
    FPercent: Integer;            // magnification 100..200 (100 = off)
    FCursor: Integer;             // mouse position along the bar, -1 = none
  public
    constructor Create(const AHost: IZoomHost);
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
  SysUtils, Math, Linkbar.Theme;

constructor TBarZoom.Create(const AHost: IZoomHost);
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

""" + draw.rstrip() + "\n\nend.\n"
wr('Linkbar.Bar.Zoom.pas', UNIT)

# ---------- 2. mUnit.pas ----------
s = s.replace(draw, '')
s = s.replace(seg(s, 'function TLinkbarWcl.ZoomEnabled: Boolean;', '{ Dock: free space at both ends'),
              'function TLinkbarWcl.ZoomEnabled: Boolean;\nbegin\n  Result := Assigned(FZoom) and FZoom.Enabled;\nend;\n\n'
              '{ Extra thickness so magnified icons fit in the bar }\n'
              'function TLinkbarWcl.ZoomRoom: Integer;\nbegin\n  if Assigned(FZoom)\n  then Result := FZoom.Room\n  else Result := 0;\nend;\n\n'
              'function TLinkbarWcl.ZoomIconSizeValue: Integer;\nbegin\n  if Assigned(FZoom)\n  then Result := FZoom.IconSizeValue\n  else Result := 0;\nend;\n\n')
s = s.replace(seg(s, 'procedure TLinkbarWcl.SetZoomPercent(AValue: Integer);', 'procedure TLinkbarWcl.RedrawZoom;'),
              'procedure TLinkbarWcl.SetZoomPercent(AValue: Integer);\nbegin\n  if not FZoom.ChangePercent(AValue)\n  then Exit;\n'
              '  // the bar thickness changes\n  if Assigned(oAppBar)\n  then oAppBar.AppBarPosChanged\n  else UpdateWindowSize;\nend;\n\n'
              'function TLinkbarWcl.GetZoomPercent: Integer;\nbegin\n  Result := FZoom.Percent;\nend;\n\n'
              'function TLinkbarWcl.BarIconOffset: TPoint;\nbegin\n  Result := FIconOffset;\nend;\n\n'
              'function TLinkbarWcl.BarSeparatorStyle: TSeparatorStyle;\nbegin\n  Result := FSeparatorStyle;\nend;\n\n'
              'procedure TLinkbarWcl.BarDrawItemMarks(const ABitmap: THBitmap; const AItem: TItemBase; const ARect: TRect);\nbegin\n'
              '  FRunning.DrawMark(ABitmap, AItem, ARect);\n  FPinned.DrawMark(ABitmap, AItem, ARect);\nend;\n\n')

s = rep(s, 'IPinnedHost, IActionButtonsHost)', 'IPinnedHost, IActionButtonsHost, IZoomHost)')
s = rep(s, '    FZoomPercent: Integer;       // magnification 100..200 (100 = off)\n    FZoomCursor: Integer;        // mouse position along the bar, -1 = none\n',
        '    FZoom: TBarZoom;             // magnification of the dock\n')
s = rep(s, '    procedure DrawItemsZoomed;\n', '')
s = rep(s, '    procedure SetZoomPercent(AValue: Integer);\n', '    procedure SetZoomPercent(AValue: Integer);\n    function GetZoomPercent: Integer;\n')
s = rep(s, 'property ZoomPercent: Integer read FZoomPercent write SetZoomPercent;', 'property ZoomPercent: Integer read GetZoomPercent write SetZoomPercent;')
s = rep(s, '    procedure BarPinnedChanged;\n',
        '    procedure BarPinnedChanged;\n'
        '    // IZoomHost\n'
        '    function BarIconOffset: TPoint;\n'
        '    function BarSeparatorStyle: TSeparatorStyle;\n'
        '    procedure BarDrawItemMarks(const ABitmap: THBitmap; const AItem: TItemBase; const ARect: TRect);\n')
s = rep(s, '    DrawItemsZoomed;\n', '    FZoom.Draw(BitmapPanel);\n')
s = re.sub(r'\bFZoomPercent\b', 'FZoom.Percent', s)
s = re.sub(r'\bFZoomCursor\b', 'FZoom.Cursor', s)
s = rep(s, '  FPinned := TPinnedItems.Create(Self);\n', '  FPinned := TPinnedItems.Create(Self);\n  FZoom := TBarZoom.Create(Self);\n')
s = rep(s, '  FreeAndNil(FPinned);\n', '  FreeAndNil(FZoom);\n  FreeAndNil(FPinned);\n')
s = rep(s, 'Linkbar.Bar.Pinned, Linkbar.Bar.ActionButtons;', 'Linkbar.Bar.Pinned, Linkbar.Bar.ActionButtons, Linkbar.Bar.Zoom;')
wr(p, s)

d = rd('Linkbar.dproj')
k = '        <DCCReference Include="Linkbar.Bar.ActionButtons.pas"/>'
d = rep(d, k, k + '\n        <DCCReference Include="Linkbar.Bar.Zoom.pas"/>')
wr('Linkbar.dproj', d)
