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


# ---------- 1. Host: servicios comunes ----------
h = rd('Linkbar.Bar.Host.pas')
h = rep(h, 'uses\n  Types;', 'uses\n  Windows, Classes, Types,\n  Linkbar.Consts;')
h = rep(h, '    function BarIsCollapsed: Boolean;\n',
        '    function BarIsCollapsed: Boolean;\n'
        '    function BarHandle: HWND;\n'
        '    // The bar window as owner of the forms it opens\n'
        '    function BarOwner: TComponent;\n'
        '    function BarAlign: TPanelAlign;\n'
        '    function BarIconSize: Integer;\n'
        '    // Recalculates the size of the window and redraws it\n'
        '    procedure BarUpdateSize;\n'
        '    procedure BarStartTimer(const AId: UINT; const AMs: Cardinal);\n'
        '    procedure BarStopTimer(const AId: UINT);\n'
        '    procedure BarCancelTooltip;\n')
wr('Linkbar.Bar.Host.pas', h)

c = rd('Linkbar.Bar.Collapse.pas')
c = rep(c, '    // Recalculates the size of the window and redraws it\n    procedure BarUpdateSize;\n    procedure BarStartTimer(const AId: UINT; const AMs: Cardinal);\n    procedure BarStopTimer(const AId: UINT);\n', '')
wr('Linkbar.Bar.Collapse.pas', c)

f = rd('Linkbar.Bar.Fullscreen.pas')
f = rep(f, '    function BarHandle: HWND;\n', '')
f = rep(f, '    // Recalculates the size of the window and redraws it\n    procedure BarUpdateSize;\n', '')
wr('Linkbar.Bar.Fullscreen.pas', f)

# ---------- 2. unidades nuevas ----------
THUMBS = """{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   Live thumbnails of the windows of an open program,  }
{   shown when the mouse stays on its icon              }
{*******************************************************}

unit Linkbar.Bar.Thumbs;

{$i linkbar.inc}

interface

uses
  Windows, Types, Vcl.Forms,
  Linkbar.Bar.Host;

const
  TIMER_THUMBS = 19;

type
  // What the thumbnails need from the bar window
  IThumbsHost = interface(ILinkbarHost)
    ['{C84A6E19-3F52-47D0-B1A8-5D29E0F7134C}']
    function BarIsItem(const AIndex: Integer): Boolean;
    function BarItemRunning(const AIndex: Integer): Boolean;
    function BarItemTarget(const AIndex: Integer): string;
    // Rectangle of the item in the bar (client coordinates)
    function BarItemRect(const AIndex: Integer): TRect;
    function BarHotIndex: Integer;
    // Dragging, locked or auto hidden: no thumbnails
    function BarThumbsBlocked: Boolean;
  end;

  TThumbController = class
  private
    FHost: IThumbsHost;
    FForm: TForm;                 // thumbnails popup (Linkbar.ThumbForm)
    FIndex: Integer;
    procedure FormDestroyed(Sender: TObject);
  public
    constructor Create(const AHost: IThumbsHost);
    destructor Destroy; override;
    // Hot item changed: schedule the thumbnails for an open program
    procedure HotChanged;
    procedure Show(const AIndex: Integer);
    procedure Close;
    property IsOpen: Boolean read GetIsOpen;
  end;

implementation

uses
  LBToolbar, Linkbar.ThumbForm;

constructor TThumbController.Create(const AHost: IThumbsHost);
begin
  inherited Create;
  FHost := AHost;
end;

destructor TThumbController.Destroy;
begin
  // the popup belongs to the bar window: it is destroyed with it
  if Assigned(FForm)
  then FForm.OnDestroy := nil;
  FForm := nil;
  inherited;
end;

procedure TThumbController.FormDestroyed(Sender: TObject);
begin
  if (FForm = Sender)
  then FForm := nil;
end;

procedure TThumbController.HotChanged;
var hot: Integer;
begin
  FHost.BarStopTimer(TIMER_THUMBS);
  hot := FHost.BarHotIndex;

  // moved to another item: close the current preview
  if Assigned(FForm) and FHost.BarIsItem(hot) and (hot <> FIndex)
  then Close;

  if FHost.BarIsItem(hot)
     and (not Assigned(FForm))
     and FHost.BarItemRunning(hot)
     and (FHost.BarItemTarget(hot) <> '')
  then FHost.BarStartTimer(TIMER_THUMBS, 500);
end;

procedure TThumbController.Show(const AIndex: Integer);
var
  wnds: TArray<HWND>;
  r: TRect;
  form: TFormThumbs;
begin
  if (not FHost.BarIsItem(AIndex))
     or (not FHost.BarItemRunning(AIndex))
     or FHost.BarThumbsBlocked
     or Assigned(FForm)
  then Exit;

  wnds := GetProgramWindows(FHost.BarItemTarget(AIndex));
  if (Length(wnds) = 0)
  then Exit;

  FHost.BarCancelTooltip;
  r := FHost.BarItemRect(AIndex);
  MapWindowPoints(FHost.BarHandle, HWND_DESKTOP, r, 2);

  form := TFormThumbs.CreateThumbs(FHost.BarOwner, FHost.BarHandle, wnds, FHost.BarIsVertical);
  form.OnDestroy := FormDestroyed;
  FForm := form;
  FIndex := AIndex;
  form.PopupAt(r, FHost.BarAlign);
end;

procedure TThumbController.Close;
begin
  FHost.BarStopTimer(TIMER_THUMBS);
  if Assigned(FForm)
  then begin
    FForm.OnDestroy := nil;
    FForm.Close;
    FForm := nil;
  end;
end;

end.
"""
THUMBS = THUMBS.replace('    property IsOpen: Boolean read GetIsOpen;\n', '')
wr('Linkbar.Bar.Thumbs.pas', THUMBS)

RUNNING = """{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   "Program is open" indicator: marks the items whose  }
{   program runs and draws the small pill under them    }
{*******************************************************}

unit Linkbar.Bar.Running;

{$i linkbar.inc}

interface

uses
  Types,
  GdiPlus,
  LBToolbar, Linkbar.Graphics, Linkbar.Bar.Host;

type
  TRunningIndicator = class
  private
    FHost: ILinkbarHost;
  public
    constructor Create(const AHost: ILinkbarHost);
    // Marks the items whose program is open; True when any item changed
    function Refresh(const AItems: TLBItemList): Boolean;
    // Small pill under the icon, like the taskbar
    procedure DrawMark(const ABitmap: THBitmap; const AItem: TItemBase; const ARect: TRect);
  end;

implementation

uses
  Classes, Math, Linkbar.Consts, Linkbar.Theme;

constructor TRunningIndicator.Create(const AHost: ILinkbarHost);
begin
  inherited Create;
  FHost := AHost;
end;

function TRunningIndicator.Refresh(const AItems: TLBItemList): Boolean;
var
  paths: TStringList;
  running: Boolean;
  idx: Integer;
begin
  Result := False;
  paths := TStringList.Create;
  try
    CollectRunningExePaths(paths);

    for var item in AItems do
    begin
      running := (item.TargetPath <> '') and paths.Find(item.TargetPath, idx);
      // Group: open if any of its programs is open
      if (not running) and (item is TItemGroup)
      then begin
        for var t in TItemGroup(item).MemberTargets do
          if (t <> '') and paths.Find(t, idx)
          then begin
            running := True;
            Break;
          end;
      end;
      if (running <> item.Running)
      then begin
        item.Running := running;
        Result := True;
      end;
    end;
  finally
    paths.Free;
  end;
end;

procedure TRunningIndicator.DrawMark(const ABitmap: THBitmap; const AItem: TItemBase; const ARect: TRect);
var
  gp: IGPGraphics;
  brush: IGPBrush;
  r: TRect;
  w, h: Integer;
  color: Cardinal;
begin
  if not AItem.Running
  then Exit;

  w := Max(FHost.ScaleValue(16), (FHost.BarIconSize * 2) div 3); // about 2/3 of the icon width
  h := Max(3, FHost.ScaleValue(3));
  case FHost.BarAlign of
    EPanelAlignLeft:   r := Bounds(ARect.Left + 1, ARect.Top + (ARect.Height - w) div 2, h, w);
    EPanelAlignRight:  r := Bounds(ARect.Right - h - 1, ARect.Top + (ARect.Height - w) div 2, h, w);
    else // top/bottom bar: under the icon
      r := Bounds(ARect.Left + (ARect.Width - w) div 2, ARect.Bottom - h - 1, w, h);
  end;

  color := SwapRedBlue(GetImmersiveColorFromName('ImmersiveSystemAccentLight2'));
  if ((color shr 24) = 0)
  then color := color or $FF000000;

  gp := TGPGraphics.Create(ABitmap.Dc);
  brush := TGPSolidBrush.Create(color);
  GPFillRoundRect(gp, brush, r, h div 2);
end;

end.
"""
wr('Linkbar.Bar.Running.pas', RUNNING)

# ---------- 3. mUnit.pas ----------
p = 'mUnit.pas'
s = rd(p)

# implementaciones: UpdateRunningState + DrawRunningMark + miniaturas
NEW_RUNNING = """procedure TLinkbarWcl.UpdateRunningState;
begin
  if (not Assigned(FRunning)) or FAutoHiden or IsDragDrop or FMouseDragLinkbar or FMouseLeftDown
  then Exit;

  if FRunning.Refresh(Items)
     and (BitmapPanel.Width > 0) and (BitmapPanel.Height > 0)
  then begin
    var hot := FHotIndex;
    RecreateMainBitmap(BitmapPanel.Width, BitmapPanel.Height);
    if IsItemIndex(hot) and not ZoomEnabled
    then begin
      // refresh hover snapshot and highlight
      const r = Items[hot].Rect;
      BitBlt(BitmapSelected.Dc, 0, 0, r.Width, r.Height, BitmapPanel.Dc, r.Left, r.Top, SRCCOPY);
      DrawItem(BitmapPanel, hot, True, False);
    end;
    UpdateWindow;
  end;
end;

{ ---------- Live thumbnails ---------- }

procedure TLinkbarWcl.ThumbsHotChanged;
begin
  if Assigned(FThumbs)
  then FThumbs.HotChanged;
end;

procedure TLinkbarWcl.ShowThumbs(const AIndex: Integer);
begin
  if Assigned(FThumbs)
  then FThumbs.Show(AIndex);
end;

procedure TLinkbarWcl.CloseThumbs;
begin
  if Assigned(FThumbs)
  then FThumbs.Close;
end;

function TLinkbarWcl.BarIsItem(const AIndex: Integer): Boolean;
begin
  Result := IsItemIndex(AIndex);
end;

function TLinkbarWcl.BarItemRunning(const AIndex: Integer): Boolean;
begin
  Result := Items[AIndex].Running;
end;

function TLinkbarWcl.BarItemTarget(const AIndex: Integer): string;
begin
  Result := Items[AIndex].TargetPath;
end;

function TLinkbarWcl.BarItemRect(const AIndex: Integer): TRect;
begin
  Result := Items[AIndex].Rect;
end;

function TLinkbarWcl.BarHotIndex: Integer;
begin
  Result := FHotIndex;
end;

function TLinkbarWcl.BarThumbsBlocked: Boolean;
begin
  Result := FMouseLeftDown or IsDragDrop or FLockHotIndex or FAutoHiden;
end;

function TLinkbarWcl.BarOwner: TComponent;
begin
  Result := Self;
end;

function TLinkbarWcl.BarAlign: TPanelAlign;
begin
  Result := Align;
end;

function TLinkbarWcl.BarIconSize: Integer;
begin
  Result := FIconSize;
end;

procedure TLinkbarWcl.BarCancelTooltip;
begin
  ToolTip.Cancel;
end;

"""
s = s.replace(seg(s, 'procedure TLinkbarWcl.UpdateRunningState;', '{ ---------- Dock mode and magnification ---------- }'), NEW_RUNNING)

# declaraciones
s = rep(s, 'TLinkbarWcl = class(TLinkbarCustomFrom, ILinkbarHost, ICollapseHost, IFullscreenHost)',
        'TLinkbarWcl = class(TLinkbarCustomFrom, ILinkbarHost, ICollapseHost, IFullscreenHost, IThumbsHost)')
s = rep(s, '    FThumbForm: TForm;          // live thumbnails popup (Linkbar.ThumbForm)\n    FThumbIndex: Integer;\n',
        '    FThumbs: TThumbController;  // live thumbnails\n    FRunning: TRunningIndicator;  // "program is open" indicator\n')
s = rep(s, '    procedure OnThumbsDestroy(Sender: TObject);\n', '')
s = rep(s, '    procedure DrawRunningMark(const ABitmap: THBitmap; const AItem: TItemBase; const ARect: TRect);\n', '')
s = rep(s, '    function BarIsCollapsed: Boolean;\n',
        '    function BarIsCollapsed: Boolean;\n'
        '    function BarOwner: TComponent;\n'
        '    function BarAlign: TPanelAlign;\n'
        '    function BarIconSize: Integer;\n'
        '    procedure BarCancelTooltip;\n')
s = rep(s, '    function BarIsTaskbarIcon: Boolean;\n',
        '    function BarIsTaskbarIcon: Boolean;\n'
        '    // IThumbsHost\n'
        '    function BarIsItem(const AIndex: Integer): Boolean;\n'
        '    function BarItemRunning(const AIndex: Integer): Boolean;\n'
        '    function BarItemTarget(const AIndex: Integer): string;\n'
        '    function BarItemRect(const AIndex: Integer): TRect;\n'
        '    function BarHotIndex: Integer;\n'
        '    function BarThumbsBlocked: Boolean;\n')
s = rep(s, '  TIMER_THUMBS = 19;\n', '')
s = rep(s, 'DrawRunningMark(', 'FRunning.DrawMark(', 0)

# crear / liberar / uses
s = rep(s, '  FFullscreen := TFullscreenWatcher.Create(Self, FCollapse);\n',
        '  FFullscreen := TFullscreenWatcher.Create(Self, FCollapse);\n  FThumbs := TThumbController.Create(Self);\n  FRunning := TRunningIndicator.Create(Self);\n')
s = rep(s, '  FreeAndNil(FFullscreen);\n', '  FreeAndNil(FRunning);\n  FreeAndNil(FThumbs);\n  FreeAndNil(FFullscreen);\n')
s = rep(s, 'Linkbar.Bar.Collapse, Linkbar.Bar.Fullscreen;', 'Linkbar.Bar.Collapse, Linkbar.Bar.Fullscreen,\n  Linkbar.Bar.Thumbs, Linkbar.Bar.Running;')

# implementaciones de las nuevas consultas ya incluidas arriba en NEW_RUNNING (junto a las miniaturas)
wr(p, s)

d = rd('Linkbar.dproj')
k = '        <DCCReference Include="Linkbar.Bar.Fullscreen.pas"/>'
d = rep(d, k, k + '\n        <DCCReference Include="Linkbar.Bar.Thumbs.pas"/>\n        <DCCReference Include="Linkbar.Bar.Running.pas"/>')
open('Linkbar.dproj', 'wb').write(d.replace('\n', '\r\n').encode('utf-8'))
