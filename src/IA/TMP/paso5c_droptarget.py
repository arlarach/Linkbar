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

# ---------- 1. SetDropPosition -> TBarDropTarget.Update (texto actual, sin tocar el original) ----------
orig = seg(s, 'procedure TLinkbarWcl.SetDropPosition(AValue: TPoint);', 'procedure TLinkbarWcl.DoDragEnter(const pt: TPoint);')
upd = orig.replace('procedure TLinkbarWcl.SetDropPosition(AValue: TPoint);', 'procedure TBarDropTarget.Update(const APoint: TPoint);')
upd = upd.replace('IsVertical(Align)', 'FHost.BarIsVertical')
upd = re.sub(r'\bItems\b', 'FHost.BarItems', upd)
upd = upd.replace('ItemIndexByPoint(AValue)', 'FHost.BarItemAt(APoint)')
upd = upd.replace('GetDropPart(AValue,', 'GetDropPart(APoint,')
upd = upd.replace('var bSideOnly: Boolean := FDragingItem;', 'var bSideOnly: Boolean := FHost.BarDraggingItem;')
upd = upd.replace('index <> FDragIndex', 'index <> FHost.BarDragIndex')
upd = upd.replace('FPidl := WorkDirPidl', 'FPidl := FHost.BarWorkDirPidl')
upd = upd.replace('FItemDropPosition', 'FPosition').replace('_FLastDropRect', 'FLastRect').replace('_FPart', 'FPart')
upd = upd.replace('BitBlt(BitmapPanel.Dc, r.Left, r.Top, r.Width, r.Height, BitmapDropPosition.Dc, 0, 0, SRCCOPY);',
                  'BitBlt(FHost.BarPanelBitmap.Dc, r.Left, r.Top, r.Width, r.Height, FBitmap.Dc, 0, 0, SRCCOPY);')
upd = upd.replace('BitBlt(BitmapDropPosition.Dc, 0, 0, r.Width, r.Height, BitmapPanel.Dc, r.Left, r.Top, SRCCOPY);',
                  'BitBlt(FBitmap.Dc, 0, 0, r.Width, r.Height, FHost.BarPanelBitmap.Dc, r.Left, r.Top, SRCCOPY);')
upd = rep(upd, '      DrawBackground(BitmapPanel, r);\n      ThemeDrawHover(BitmapPanel, Align, r);\n      DrawItem(BitmapPanel, FPosition, False, False, False);\n',
           '      FHost.BarPaintDropHighlight(FPosition, r);\n')
upd = upd.replace('TGpGraphics.Create(BitmapPanel.Dc)', 'TGpGraphics.Create(FHost.BarPanelBitmap.Dc)')
upd = upd.replace('  UpdateWindow;\nend;', '  FHost.BarRefresh;\nend;')
upd = upd.replace('Align', 'FHost.BarAlign') if False else upd
for bad in ['BitmapPanel', 'BitmapDropPosition', 'IsVertical(', 'Items[', ' Align']:
    assert bad not in upd.replace('FHost.BarItems[', ''), bad

UNIT = """{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   Drop target of the bar: the indicator that shows    }
{   where an icon or a file will be dropped             }
{*******************************************************}

unit Linkbar.Bar.DropTarget;

{$i linkbar.inc}

interface

uses
  Winapi.Windows, Winapi.ShlObj, Types,
  Linkbar.Graphics, Linkbar.Bar.Host;

type
  // What the drop indicator needs from the bar window
  IDropTargetHost = interface(ILinkbarHost)
    ['{D2A85F16-6E3B-49C7-A1D4-8B0E5C7F3926}']
    // Index of the item under the point (ITEM_NONE when there is none)
    function BarItemAt(const APt: TPoint): Integer;
    // An item of the bar is being dragged inside the bar
    function BarDraggingItem: Boolean;
    function BarDragIndex: Integer;
    // The bitmap where the bar draws its items
    function BarPanelBitmap: THBitmap;
    function BarWorkDirPidl: PItemIDList;
    // Draws the hover look (background, hover and item) of the item that receives the drop
    procedure BarPaintDropHighlight(const AIndex: Integer; const ARect: TRect);
    procedure BarRefresh;
  end;

  TBarDropTarget = class
  private
    FHost: IDropTargetHost;
    FBitmap: THBitmap;            // what was under the indicator (to restore it)
    FPosition: Integer;           // item (or gap) that receives the drop
    FPart: Integer;               // -1 before the item, 0 on it, 1 after it
    FLastRect: TRect;
    FPidl: PItemIDList;           // target of the shell drop
    function IndicatorRect(const AIndex, APart: Integer): TRect;
  public
    constructor Create(const AHost: IDropTargetHost);
    destructor Destroy; override;
    procedure SetSize(const AWidth, AHeight: Integer);
    // Moves the indicator to the item (or gap) under the point; (-1, -1) clears it
    procedure Update(const APoint: TPoint);
    // Image of an icon dragged out of a group (nil when it cannot be created)
    class function CreateExternalImage(const AIcon: HBITMAP; const ASize: Integer): THBitmap; static;
    property Position: Integer read FPosition write FPosition;
    property Part: Integer read FPart;
    property Pidl: PItemIDList read FPidl;
  end;

implementation

uses
  GdiPlus, LBToolbar, Linkbar.Consts;

constructor TBarDropTarget.Create(const AHost: IDropTargetHost);
begin
  inherited Create;
  FHost := AHost;
  FBitmap := THBitmap.Create(32);
  FPosition := ITEM_NONE;
end;

destructor TBarDropTarget.Destroy;
begin
  FBitmap.Free;
  inherited;
end;

procedure TBarDropTarget.SetSize(const AWidth, AHeight: Integer);
begin
  FBitmap.SetSize(AWidth, AHeight);
end;

function TBarDropTarget.IndicatorRect(const AIndex, APart: Integer): TRect;
var r: TRect;
begin
  r := FHost.BarItems[AIndex].Rect;

  case APart of
    -1: begin
      if FHost.BarIsVertical
      then begin
        r.Top := r.Top - DROP_INDICATOR_SIZE div 2;
        r.Left := r.Left + r.Width div DROP_INDICATOR_PADDING_DIV;
        r.Right := r.Right - r.Width div DROP_INDICATOR_PADDING_DIV;
        r.Height := DROP_INDICATOR_SIZE;
      end
      else begin
        r.Left := r.Left - DROP_INDICATOR_SIZE div 2;
        r.Top := r.Top + r.Height div DROP_INDICATOR_PADDING_DIV;
        r.Bottom := r.Bottom - r.Height div DROP_INDICATOR_PADDING_DIV;
        r.Width := DROP_INDICATOR_SIZE;
      end;
    end;
    1: begin
      if FHost.BarIsVertical
      then begin
        r.Top := r.Bottom - DROP_INDICATOR_SIZE div 2;
        r.Left := r.Left + r.Width div DROP_INDICATOR_PADDING_DIV;
        r.Right := r.Right - r.Width div DROP_INDICATOR_PADDING_DIV;
        r.Height := DROP_INDICATOR_SIZE;
      end
      else begin
        r.Left := r.Right - DROP_INDICATOR_SIZE div 2;
        r.Top := r.Top + r.Height div DROP_INDICATOR_PADDING_DIV;
        r.Bottom := r.Bottom - r.Height div DROP_INDICATOR_PADDING_DIV;
        r.Width := DROP_INDICATOR_SIZE;
      end;
    end;
  end;

  Result := r;
end;

@@UPDATE@@

class function TBarDropTarget.CreateExternalImage(const AIcon: HBITMAP; const ASize: Integer): THBitmap;
var
  srcDc: HDC;
  old: HGDIOBJ;
  bm: Winapi.Windows.TBitmap;
  blend: TBlendFunction;
begin
  Result := nil;
  if (AIcon = 0) or (ASize <= 0) or (GetObject(AIcon, SizeOf(bm), @bm) = 0)
  then Exit;

  Result := THBitmap.Create(32);
  Result.SetSize(ASize, ASize);
  blend.BlendOp := AC_SRC_OVER;
  blend.BlendFlags := 0;
  blend.SourceConstantAlpha := 255;
  blend.AlphaFormat := AC_SRC_ALPHA;
  srcDc := CreateCompatibleDC(0);
  old := SelectObject(srcDc, AIcon);
  Winapi.Windows.AlphaBlend(Result.Dc, 0, 0, ASize, ASize,
    srcDc, 0, 0, bm.bmWidth, Abs(bm.bmHeight), blend);
  SelectObject(srcDc, old);
  DeleteDC(srcDc);
end;

end.
"""
# el cuerpo de Update: sin la funcion anidada GetItemDropRect (ahora es IndicatorRect)
a = upd.index('var\n  r: TRect;\n  index: Integer;')
upd_body = upd[:upd.index('\n\n  function GetItemDropRect')] + '\n\n' + upd[a:]
upd_body = upd_body.replace('GetItemDropRect(FPosition, part)', 'IndicatorRect(FPosition, part)')
assert 'GetItemDropRect' not in upd_body.replace('IndicatorRect', '')
UNIT = UNIT.replace('@@UPDATE@@', upd_body.rstrip())
wr('Linkbar.Bar.DropTarget.pas', UNIT)

# ---------- 2. mUnit.pas ----------
s = s.replace(orig, 'procedure TLinkbarWcl.SetDropPosition(AValue: TPoint);\nbegin\n  if Assigned(FDropTarget)\n  then FDropTarget.Update(AValue);\nend;\n\n'
              'function TLinkbarWcl.BarItemAt(const APt: TPoint): Integer;\nbegin\n  Result := ItemIndexByPoint(APt);\nend;\n\n'
              'function TLinkbarWcl.BarDraggingItem: Boolean;\nbegin\n  Result := FDragingItem;\nend;\n\n'
              'function TLinkbarWcl.BarDragIndex: Integer;\nbegin\n  Result := FDragIndex;\nend;\n\n'
              'function TLinkbarWcl.BarPanelBitmap: THBitmap;\nbegin\n  Result := BitmapPanel;\nend;\n\n'
              'function TLinkbarWcl.BarWorkDirPidl: PItemIDList;\nbegin\n  Result := WorkDirPidl;\nend;\n\n'
              'procedure TLinkbarWcl.BarPaintDropHighlight(const AIndex: Integer; const ARect: TRect);\nbegin\n'
              '  DrawBackground(BitmapPanel, ARect);\n  ThemeDrawHover(BitmapPanel, Align, ARect);\n  DrawItem(BitmapPanel, AIndex, False, False, False);\nend;\n\n'
              'procedure TLinkbarWcl.BarRefresh;\nbegin\n  UpdateWindow;\nend;\n\n')
s = rep(s, 'var _FLastDropRect: TRect;\n    _FPart: Integer;\n\n', '')

# imagen externa
a = s.index('    ABitmap := THBitmap.Create(32);\n    ABitmap.SetSize(FExtDragIconSize, FExtDragIconSize);')
b = s.index('    DeleteDC(srcDc);\n', a) + len('    DeleteDC(srcDc);\n')
s = s[:a] + '    ABitmap := TBarDropTarget.CreateExternalImage(FExtDragIcon, FExtDragIconSize);\n' + s[b:]
s = rep(s, 'var ItemRect: TRect;\n    srcDc: HDC;\n    old: HGDIOBJ;\n    bm: Winapi.Windows.TBitmap;\n    blend: TBlendFunction;\nbegin\n  if (not StyleServices.Enabled)',
        'var ItemRect: TRect;\n    bm: Winapi.Windows.TBitmap;\nbegin\n  if (not StyleServices.Enabled)')

# declaraciones
s = rep(s, 'IZoomHost, IDockHost)', 'IZoomHost, IDockHost, IDropTargetHost)')
s = rep(s, '    BitmapDropPosition: THBitmap;\n', '    FDropTarget: TBarDropTarget;  // drop indicator\n')
s = rep(s, '    FItemDropPosition: Integer;\n    FPidl: PItemIDList;\n', '')
s = rep(s, '  BitmapDropPosition.SetSize(AWidth, AHeight);', '  FDropTarget.SetSize(AWidth, AHeight);')
s = rep(s, '  if Assigned(BitmapDropPosition) then BitmapDropPosition.Free;\n', '')
s = rep(s, '  BitmapDropPosition := THBitmap.Create(32);\n', '')
s = rep(s, '    procedure BarPinnedChanged;\n',
        '    procedure BarPinnedChanged;\n'
        '    // IDropTargetHost\n'
        '    function BarItemAt(const APt: TPoint): Integer;\n'
        '    function BarDraggingItem: Boolean;\n'
        '    function BarDragIndex: Integer;\n'
        '    function BarPanelBitmap: THBitmap;\n'
        '    function BarWorkDirPidl: PItemIDList;\n'
        '    procedure BarPaintDropHighlight(const AIndex: Integer; const ARect: TRect);\n'
        '    procedure BarRefresh;\n')
s = re.sub(r'\bFItemDropPosition\b', 'FDropTarget.Position', s)
s = re.sub(r'\b_FPart\b', 'FDropTarget.Part', s)
s = re.sub(r'\bFPidl\b', 'FDropTarget.Pidl', s)

s = rep(s, '  FDock := TBarDock.Create(Self, FZoom);\n', '  FDock := TBarDock.Create(Self, FZoom);\n  FDropTarget := TBarDropTarget.Create(Self);\n')
s = rep(s, '  FreeAndNil(FDock);\n', '  FreeAndNil(FDropTarget);\n  FreeAndNil(FDock);\n')
s = rep(s, 'Linkbar.Bar.Zoom, Linkbar.Bar.Dock;', 'Linkbar.Bar.Zoom, Linkbar.Bar.Dock, Linkbar.Bar.DropTarget;')
wr(p, s)

d = rd('Linkbar.dproj')
k = '        <DCCReference Include="Linkbar.Bar.Dock.pas"/>'
d = rep(d, k, k + '\n        <DCCReference Include="Linkbar.Bar.DropTarget.pas"/>')
wr('Linkbar.dproj', d)
