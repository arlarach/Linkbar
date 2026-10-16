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


# ---------- 1. interfaces: lo comun pasa a ILinkbarHost ----------
h = rd('Linkbar.Bar.Host.pas')
h = rep(h, '  LBToolbar, Linkbar.Consts;', '  LBToolbar, Linkbar.Consts, Linkbar.Graphics;')
h = rep(h, '    procedure BarMoveTo(const AX, AY: Integer);\n',
        '    procedure BarMoveTo(const AX, AY: Integer);\n'
        '    function BarIsDock: Boolean;\n'
        '    function BarBackgroundColor: Cardinal;\n'
        '    function BarIsLightStyle: Boolean;\n'
        '    function BarHotIndex: Integer;\n'
        '    function BarPressedIndex: Integer;\n'
        '    // The bitmap where the bar draws its items\n'
        '    function BarPanelBitmap: THBitmap;\n'
        '    // The bitmap with the look of a pressed / selected button\n'
        '    function BarButtonBitmap: THBitmap;\n'
        '    // Offset of the icon inside the button of an item\n'
        '    function BarIconOffset: TPoint;\n'
        '    function BarSeparatorStyle: TSeparatorStyle;\n'
        '    function BarSeparatorWidth: Integer;\n'
        '    function BarItemsMargin: Integer;\n'
        '    // Space kept at the end of the bar for the CPU / RAM widgets\n'
        '    function BarReservedLength(const AVertical: Boolean): Integer;\n'
        '    function BarTextLayout: TTextLayout;\n'
        '    function BarTextRect: TRect;\n'
        '    function BarUseTextColor: Boolean;\n'
        '    function BarTextColor: Cardinal;\n'
        '    function BarGlowSize: Integer;\n'
        '    // Draws the "program is open" pill and the pinned dot of an item\n'
        '    procedure BarDrawItemMarks(const ABitmap: THBitmap; const AItem: TItemBase; const ARect: TRect);\n')
wr('Linkbar.Bar.Host.pas', h)

z = rd('Linkbar.Bar.Zoom.pas')
z = z.replace(seg(z, '  // What the zoom needs from the bar window\n', '  TBarZoom = class'), '')
z = rep(z, 'FHost: IZoomHost;', 'FHost: ILinkbarHost;')
z = rep(z, 'constructor Create(const AHost: IZoomHost);', 'constructor Create(const AHost: ILinkbarHost);')
z = rep(z, 'constructor TBarZoom.Create(const AHost: IZoomHost);', 'constructor TBarZoom.Create(const AHost: ILinkbarHost);')
wr('Linkbar.Bar.Zoom.pas', z)

dk = rd('Linkbar.Bar.Dock.pas')
dk = rep(dk, '    function BarIsDock: Boolean;\n', '')
dk = rep(dk, '    function BarBackgroundColor: Cardinal;\n', '')
wr('Linkbar.Bar.Dock.pas', dk)

th = rd('Linkbar.Bar.Thumbs.pas')
th = rep(th, '    function BarHotIndex: Integer;\n', '')
wr('Linkbar.Bar.Thumbs.pas', th)

dt = rd('Linkbar.Bar.DropTarget.pas')
dt = rep(dt, '    // The bitmap where the bar draws its items\n    function BarPanelBitmap: THBitmap;\n', '')
wr('Linkbar.Bar.DropTarget.pas', dt)

# ---------- 2. Painter a partir del texto actual ----------
p = 'mUnit.pas'
s = rd(p)
o_bg = seg(s, 'procedure TLinkbarWcl.DrawBackground(const ABitmap: THBitmap;', 'procedure TLinkbarWcl.DrawCaption(')
o_cap = seg(s, 'procedure TLinkbarWcl.DrawCaption(', 'procedure TLinkbarWcl.DrawItem(ABitmap')
o_item = seg(s, 'procedure TLinkbarWcl.DrawItem(ABitmap', 'procedure TLinkbarWcl.DrawItems(')
o_items = seg(s, 'procedure TLinkbarWcl.DrawItems(', 'procedure TLinkbarWcl.RecreateMainBitmap')


def conv(t):
    t = t.replace('TLinkbarWcl.', 'TBarPainter.')
    t = t.replace('    FRunning.DrawMark(ABitmap, item, r);\n    FPinned.DrawMark(ABitmap, item, r);\n',
                  '    FHost.BarDrawItemMarks(ABitmap, item, r);\n')
    t = t.replace('      FRunning.DrawMark(BitmapPanel, item, item.Rect);\n      FPinned.DrawMark(BitmapPanel, item, item.Rect);\n',
                  '      FHost.BarDrawItemMarks(BitmapPanel, item, item.Rect);\n')
    t = t.replace('IsVertical(Align)', 'FHost.BarIsVertical')
    t = t.replace(', Align, ', ', FHost.BarAlign, ')
    t = t.replace('params.Align := Align;', 'params.Align := FHost.BarAlign;')
    t = t.replace('FSysWidgets.ReservedLength(FHost.BarIsVertical)', 'FHost.BarReservedLength(FHost.BarIsVertical)')
    t = t.replace(':= ButtonSize;', ':= FHost.BarButtonSize;')
    t = t.replace(':= SeparatorWidth;', ':= FHost.BarSeparatorWidth;')
    t = t.replace(':= ItemsMargin;', ':= FHost.BarItemsMargin;')
    t = re.sub(r'\bZoomRoom\b', 'FHost.ZoomExtra', t)
    t = re.sub(r'\bZoomEnabled\b', 'FZoom.Enabled', t)
    t = re.sub(r'\bIsCollapsed\b', 'FHost.BarIsCollapsed', t)
    t = re.sub(r'\bIsDock\b', 'FHost.BarIsDock', t)
    t = re.sub(r'\bIsLightStyle\b', 'FHost.BarIsLightStyle', t)
    t = re.sub(r'\bBackgroundColor\b', 'FHost.BarBackgroundColor', t)
    t = re.sub(r'\bItems\b', 'FHost.BarItems', t)
    t = re.sub(r'\bTextLayout\b', 'FHost.BarTextLayout', t)
    t = t.replace('FUseTextColor', 'FHost.BarUseTextColor').replace('FTextColor', 'FHost.BarTextColor')
    t = t.replace('FTextRect', 'FHost.BarTextRect').replace('FGlowSize', 'FHost.BarGlowSize')
    t = re.sub(r'\bPressedIndex\b', 'FHost.BarPressedIndex', t)
    t = re.sub(r'\bHotIndex\b', 'FHost.BarHotIndex', t)
    t = t.replace('BitmapButton', 'FHost.BarButtonBitmap').replace('BitmapPanel', 'FHost.BarPanelBitmap')
    t = t.replace('FIconOffset', 'FHost.BarIconOffset').replace('FSeparatorStyle', 'FHost.BarSeparatorStyle')
    t = t.replace('Windows.AlphaBlend', 'Winapi.Windows.AlphaBlend')
    return t


body = conv(o_bg) + conv(o_cap) + conv(o_item) + conv(o_items)
# no deben quedar referencias a campos o metodos del formulario
chk = re.sub(r'FHost\.Bar\w+|FHost\.ZoomExtra|FHost\.BarItems', '', body)
for bad in ['FHotIndex', 'FPressed', 'FRunning', 'FPinned', 'FSysWidgets', 'FDragIndex', 'Items.', 'Items[', 'BitmapPanel', 'BitmapButton', ' Align)', 'FIconOffset']:
    assert bad not in chk, bad

UNIT = """{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   Painter of the bar: background, captions and icons  }
{   of the items (drawn on the bitmap of the bar)       }
{*******************************************************}

unit Linkbar.Bar.Painter;

{$i linkbar.inc}

interface

uses
  Types,
  Linkbar.Graphics, Linkbar.Bar.Host, Linkbar.Bar.Dock, Linkbar.Bar.Zoom;

type
  TBarPainter = class
  private
    FHost: ILinkbarHost;
    FDock: TBarDock;
    FZoom: TBarZoom;
  public
    constructor Create(const AHost: ILinkbarHost; const ADock: TBarDock; const AZoom: TBarZoom);
    procedure DrawBackground(const ABitmap: THBitmap; const AClipRect: TRect);
    procedure DrawCaption(const ABitmap: THBitmap; const AIndex: Integer;
      const ADrawForDrag: Boolean = False);
    procedure DrawItem(ABitmap: THBitmap; AIndex: Integer; ASelected,
      APressed: Boolean; ADrawBg: Boolean = True; ADrawForDrag: Boolean = False);
    // Lays out the items and draws captions, separators and icons
    procedure DrawItems(const AWidth, AHeight: Integer);
  end;

implementation

uses
  Winapi.Windows, SysUtils, Math, Vcl.Graphics, Vcl.Forms, Vcl.Themes,
  LBToolbar, Linkbar.Consts, Linkbar.Theme;

const
  bf: TBlendFunction = (BlendOp: AC_SRC_OVER; BlendFlags: 0;
      SourceConstantAlpha: $FF; AlphaFormat: AC_SRC_ALPHA);

constructor TBarPainter.Create(const AHost: ILinkbarHost; const ADock: TBarDock; const AZoom: TBarZoom);
begin
  inherited Create;
  FHost := AHost;
  FDock := ADock;
  FZoom := AZoom;
end;

""" + body.rstrip() + "\n\nend.\n"
wr('Linkbar.Bar.Painter.pas', UNIT)

# ---------- 3. mUnit.pas ----------
WRAP = """procedure TLinkbarWcl.DrawBackground(const ABitmap: THBitmap;
  const AClipRect: TRect);
begin
  if Assigned(FPainter)
  then FPainter.DrawBackground(ABitmap, AClipRect);
end;

procedure TLinkbarWcl.DrawCaption(const ABitmap: THBitmap; const AIndex: Integer;
  const ADrawForDrag: Boolean = False);
begin
  if Assigned(FPainter)
  then FPainter.DrawCaption(ABitmap, AIndex, ADrawForDrag);
end;

procedure TLinkbarWcl.DrawItem(ABitmap: THBitmap; AIndex: integer; ASelected,
  APressed: Boolean; ADrawBg: Boolean; ADrawForDrag: Boolean);
begin
  if Assigned(FPainter)
  then FPainter.DrawItem(ABitmap, AIndex, ASelected, APressed, ADrawBg, ADrawForDrag);
end;

procedure TLinkbarWcl.DrawItems(const AWidth, AHeight: integer);
begin
  if Assigned(FPainter)
  then FPainter.DrawItems(AWidth, AHeight);
end;

function TLinkbarWcl.BarButtonBitmap: THBitmap;
begin
  Result := BitmapButton;
end;

function TLinkbarWcl.BarIsLightStyle: Boolean;
begin
  Result := FIsLightStyle;
end;

function TLinkbarWcl.BarPressedIndex: Integer;
begin
  Result := FPressedIndex;
end;

function TLinkbarWcl.BarSeparatorWidth: Integer;
begin
  Result := FSeparatorWidth;
end;

function TLinkbarWcl.BarItemsMargin: Integer;
begin
  Result := ItemsMargin;
end;

function TLinkbarWcl.BarReservedLength(const AVertical: Boolean): Integer;
begin
  Result := FSysWidgets.ReservedLength(AVertical);
end;

function TLinkbarWcl.BarTextLayout: TTextLayout;
begin
  Result := FTextLayout;
end;

function TLinkbarWcl.BarTextRect: TRect;
begin
  Result := FTextRect;
end;

function TLinkbarWcl.BarUseTextColor: Boolean;
begin
  Result := FUseTextColor;
end;

function TLinkbarWcl.BarTextColor: Cardinal;
begin
  Result := FTextColor;
end;

function TLinkbarWcl.BarGlowSize: Integer;
begin
  Result := FGlowSize;
end;

"""
s = s.replace(o_bg + o_cap + o_item + o_items, WRAP)

s = rep(s, 'IActionButtonsHost, IZoomHost, IDockHost, IDropTargetHost)', 'IActionButtonsHost, IDockHost, IDropTargetHost)')
s = rep(s, '    FDropTarget: TBarDropTarget;  // drop indicator\n', '    FDropTarget: TBarDropTarget;  // drop indicator\n    FPainter: TBarPainter;        // background, captions and icons\n')
s = rep(s, '    procedure BarPinnedChanged;\n',
        '    procedure BarPinnedChanged;\n'
        '    // IPainterHost (common bar services)\n'
        '    function BarButtonBitmap: THBitmap;\n'
        '    function BarIsLightStyle: Boolean;\n'
        '    function BarPressedIndex: Integer;\n'
        '    function BarSeparatorWidth: Integer;\n'
        '    function BarItemsMargin: Integer;\n'
        '    function BarReservedLength(const AVertical: Boolean): Integer;\n'
        '    function BarTextLayout: TTextLayout;\n'
        '    function BarTextRect: TRect;\n'
        '    function BarUseTextColor: Boolean;\n'
        '    function BarTextColor: Cardinal;\n'
        '    function BarGlowSize: Integer;\n')
s = rep(s, '  FDropTarget := TBarDropTarget.Create(Self);\n', '  FDropTarget := TBarDropTarget.Create(Self);\n  FPainter := TBarPainter.Create(Self, FDock, FZoom);\n')
s = rep(s, '  FreeAndNil(FDropTarget);\n', '  FreeAndNil(FPainter);\n  FreeAndNil(FDropTarget);\n')
s = rep(s, 'Linkbar.Bar.Dock, Linkbar.Bar.DropTarget;', 'Linkbar.Bar.Dock, Linkbar.Bar.DropTarget, Linkbar.Bar.Painter;')
wr(p, s)

d = rd('Linkbar.dproj')
k = '        <DCCReference Include="Linkbar.Bar.DropTarget.pas"/>'
d = rep(d, k, k + '\n        <DCCReference Include="Linkbar.Bar.Painter.pas"/>')
wr('Linkbar.dproj', d)
