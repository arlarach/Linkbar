import re
p = 'mUnit.pas'
s = open(p, 'rb').read().decode('utf-8').replace('\r\n', '\n')


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


# ---------- 1. unidad nueva ----------
UNIT = """{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   Collapse / expand of the bar: manual (">>" button), }
{   by full screen apps and by inactivity, with its     }
{   animation and the auto collapse timer               }
{*******************************************************}

unit Linkbar.Bar.Collapse;

{$i linkbar.inc}

interface

uses
  Windows, Types,
  Linkbar.Bar.Host;

const
  TIMER_COLLAPSE_ANIM = 23;
  TIMER_AUTOCOLLAPSE = 24;

type
  // What the collapse needs from the bar window
  ICollapseHost = interface(ILinkbarHost)
    ['{A3D7F1E4-5B28-4C9A-8E16-7F0B2D4C6A93}']
    // Recalculates the size of the window and redraws it
    procedure BarUpdateSize;
    procedure BarStartTimer(const AId: UINT; const AMs: Cardinal);
    procedure BarStopTimer(const AId: UINT);
    // Closes the thumbnails and the tooltip
    procedure BarDismissPopups;
    procedure BarSetAutoHideLock(const ALock: Boolean);
    // Lays out the bar again (screen edge reservation included)
    procedure BarRelayout;
    // The bar is a dock, visible and not auto hidden
    function BarCanAnimate: Boolean;
    // Length of the bar when it is collapsed
    function BarCollapsedLength(const AVertical: Boolean): Integer;
    // Shows the already rendered expanded bar cropped to ARect (animation frame)
    procedure BarShowFrame(const ARect: TRect);
    // The bar is being used (mouse over, dragging, locked...)
    function BarIsBusy: Boolean;
    // The ">>" button exists (CPU / RAM widgets on)
    function BarHasCollapseButton: Boolean;
    function BarHandleAllocated: Boolean;
  end;

  TBarCollapse = class
  private
    FHost: ICollapseHost;
    FManual: Boolean;             // True = only CPU/RAM and pinned items visible (saved)
    FByFullscreen: Boolean;       // collapsed automatically by a full screen app (not saved)
    FByIdle: Boolean;             // collapsed after some time without using the bar (not saved)
    FOnFullscreen: Boolean;       // collapse (instead of hiding) when an app is full screen
    FAnimate: Boolean;
    FAnimating: Boolean;          // frames are being shown: normal redraws are skipped
    FAnimBuild: Boolean;          // only render the expanded bitmap, do not touch the window
    FAnimRender: Boolean;         // lay out as expanded even if collapsed
    FAnimStart: Cardinal;
    FAnimFrom, FAnimTo: Integer;  // window length at the start / end of the animation
    FAnimRectExp: TRect;          // window rect when expanded (the far edge stays fixed)
    FAutoSecs: Integer;           // 0 = off
  public
    constructor Create(const AHost: ICollapseHost);
    function IsCollapsed: Boolean;
    function CanAnimate: Boolean;
    // The expanded bitmap is rendered once; each frame only moves/crops the window
    // keeping the far edge fixed. Called after ManualCollapsed already has its new value
    procedure StartAnim(const AToCollapsed: Boolean);
    procedure AnimStep;
    procedure FinishAnim;
    procedure ArmAuto;
    procedure CancelAuto;
    // Nobody used the bar for a while: collapse it (unless it is busy)
    procedure AutoTick;
    // Setters with effect on the window (the properties only store the value)
    procedure ChangeAutoSecs(const AValue: Integer);
    procedure ChangeOnFullscreen(const AValue: Boolean);
    property ManualCollapsed: Boolean read FManual write FManual;
    property CollapsedByFullscreen: Boolean read FByFullscreen write FByFullscreen;
    property CollapsedByIdle: Boolean read FByIdle write FByIdle;
    property OnFullscreen: Boolean read FOnFullscreen write FOnFullscreen;
    property AnimateEnabled: Boolean read FAnimate write FAnimate;
    property Animating: Boolean read FAnimating;
    property AnimBuild: Boolean read FAnimBuild;
    property AnimRectExp: TRect read FAnimRectExp write FAnimRectExp;
    property AutoSecs: Integer read FAutoSecs write FAutoSecs;
  end;

implementation

uses
  Math;

const
  COLLAPSE_ANIM_MS = 180;

constructor TBarCollapse.Create(const AHost: ICollapseHost);
begin
  inherited Create;
  FHost := AHost;
end;

function TBarCollapse.IsCollapsed: Boolean;
begin
  Result := (FManual or FByFullscreen or FByIdle) and not FAnimRender;
end;

function TBarCollapse.CanAnimate: Boolean;
begin
  Result := FAnimate and (not FAnimating) and FHost.BarCanAnimate;
end;

procedure TBarCollapse.StartAnim(const AToCollapsed: Boolean);
var
  vertical: Boolean;
  lenExp, lenCol: Integer;
begin
  vertical := FHost.BarIsVertical;

  FAnimBuild := True;
  FAnimRender := True;
  try
    FHost.BarRelayout;
  finally
    FAnimBuild := False;
    FAnimRender := False;
  end;

  if vertical
  then lenExp := FAnimRectExp.Height
  else lenExp := FAnimRectExp.Width;
  lenCol := Min(FHost.BarCollapsedLength(vertical), lenExp);

  if (lenCol >= lenExp)
  then begin
    FHost.BarUpdateSize;  // nothing to animate
    Exit;
  end;

  if AToCollapsed
  then begin
    FAnimFrom := lenExp;
    FAnimTo := lenCol;
  end
  else begin
    FAnimFrom := lenCol;
    FAnimTo := lenExp;
  end;

  FHost.BarDismissPopups;
  FHost.BarSetAutoHideLock(True);
  FAnimStart := GetTickCount;
  FAnimating := True;
  FHost.BarStartTimer(TIMER_COLLAPSE_ANIM, 16);
  AnimStep;
end;

procedure TBarCollapse.AnimStep;
var
  t, e: Double;
  len: Integer;
  r: TRect;
begin
  if not FAnimating
  then Exit;

  t := (GetTickCount - FAnimStart) / COLLAPSE_ANIM_MS;
  if (t > 1)
  then t := 1;
  // ease in-out
  if (t < 0.5)
  then e := 2 * t * t
  else e := 1 - Sqr(-2 * t + 2) / 2;

  len := FAnimFrom + Round((FAnimTo - FAnimFrom) * e);

  if FHost.BarIsVertical
  then r := Rect(FAnimRectExp.Left, FAnimRectExp.Bottom - len, FAnimRectExp.Right, FAnimRectExp.Bottom)
  else r := Rect(FAnimRectExp.Right - len, FAnimRectExp.Top, FAnimRectExp.Right, FAnimRectExp.Bottom);

  FHost.BarShowFrame(r);

  if (t >= 1)
  then begin
    FinishAnim;
    FHost.BarUpdateSize;  // final layout (collapsed or expanded)
  end;
end;

procedure TBarCollapse.FinishAnim;
begin
  if not FAnimating
  then Exit;
  FHost.BarStopTimer(TIMER_COLLAPSE_ANIM);
  FAnimating := False;
  FHost.BarSetAutoHideLock(False);
end;

procedure TBarCollapse.ArmAuto;
begin
  FHost.BarStopTimer(TIMER_AUTOCOLLAPSE);
  if (FAutoSecs > 0) and FHost.BarHasCollapseButton and (not IsCollapsed)
  then FHost.BarStartTimer(TIMER_AUTOCOLLAPSE, Cardinal(FAutoSecs) * 1000);
end;

procedure TBarCollapse.CancelAuto;
begin
  FHost.BarStopTimer(TIMER_AUTOCOLLAPSE);
end;

procedure TBarCollapse.AutoTick;
begin
  FHost.BarStopTimer(TIMER_AUTOCOLLAPSE);
  if (FAutoSecs <= 0) or IsCollapsed or (not FHost.BarHasCollapseButton)
  then Exit;

  if FAnimating or FHost.BarIsBusy
  then begin
    ArmAuto;  // busy: try again later
    Exit;
  end;

  FByIdle := True;
  if CanAnimate
  then StartAnim(True)
  else FHost.BarUpdateSize;
end;

procedure TBarCollapse.ChangeAutoSecs(const AValue: Integer);
begin
  FAutoSecs := Max(0, AValue);
  if (FAutoSecs = 0) and FByIdle
  then begin
    FByIdle := False;
    FHost.BarUpdateSize;
  end;
  if FHost.BarHandleAllocated
  then ArmAuto;
end;

procedure TBarCollapse.ChangeOnFullscreen(const AValue: Boolean);
begin
  FOnFullscreen := AValue;
  if (not AValue) and FByFullscreen
  then begin
    FByFullscreen := False;
    FHost.BarUpdateSize;
  end;
end;

end.
"""
open('Linkbar.Bar.Collapse.pas', 'wb').write(UNIT.replace('\n', '\r\n').encode('utf-8'))

# ---------- 2. mUnit.pas ----------
# implementaciones que se mueven
s = s.replace(seg(s, 'function TLinkbarWcl.CanAnimateCollapse: Boolean;',
                  '{ Position and alignment of a tooltip next to ARect'), '')
s = s.replace(seg(s, 'procedure TLinkbarWcl.ArmAutoCollapse;', 'procedure TLinkbarWcl.imAnimateCollapseClick'),
              'procedure TLinkbarWcl.SetAutoCollapseSecs(AValue: Integer);\nbegin\n  FCollapse.ChangeAutoSecs(AValue);\nend;\n\n'
              'function TLinkbarWcl.GetAutoCollapseSecs: Integer;\nbegin\n  Result := FCollapse.AutoSecs;\nend;\n\n'
              'function TLinkbarWcl.GetAnimateCollapse: Boolean;\nbegin\n  Result := FCollapse.AnimateEnabled;\nend;\n\n'
              'procedure TLinkbarWcl.SetAnimateCollapse(AValue: Boolean);\nbegin\n  FCollapse.AnimateEnabled := AValue;\nend;\n\n'
              'function TLinkbarWcl.GetCollapseOnFullscreen: Boolean;\nbegin\n  Result := FCollapse.OnFullscreen;\nend;\n\n')
s = s.replace(seg(s, 'procedure TLinkbarWcl.SetCollapseOnFullscreen(AValue: Boolean);', '{ ---------- action buttons ---------- }'),
              'procedure TLinkbarWcl.SetCollapseOnFullscreen(AValue: Boolean);\nbegin\n  FCollapse.ChangeOnFullscreen(AValue);\nend;\n\n')
s = rep(s, 'Result := (FMacCollapsed or FCollapsedByFullscreen or FCollapsedByIdle) and not FAnimRender;', 'Result := FCollapse.IsCollapsed;')

# declaraciones
s = rep(s, 'TLinkbarWcl = class(TLinkbarCustomFrom, ILinkbarHost)', 'TLinkbarWcl = class(TLinkbarCustomFrom, ILinkbarHost, ICollapseHost)')
s = rep(s, '    FMacCollapsed: Boolean;       // True = Solo CPU/RAM visibles\n', '    FCollapse: TBarCollapse;      // collapse / expand of the bar\n')
for pat in [r'    FCollapseOnFullscreen: Boolean;[^\n]*\n', r'    FCollapsedByFullscreen: Boolean;[^\n]*\n',
            r'    FCollapsedByIdle: Boolean;[^\n]*\n', r'    FAutoCollapseSecs: Integer;[^\n]*\n',
            r'    FAnimateCollapse: Boolean;\n', r'    FAnimating: Boolean;[^\n]*\n', r'    FAnimBuild: Boolean;[^\n]*\n',
            r'    FAnimRender: Boolean;[^\n]*\n', r'    FAnimStart: Cardinal;\n', r'    FAnimFrom, FAnimTo: Integer;[^\n]*\n',
            r'    FAnimRectExp: TRect;[^\n]*\n']:
    s, n = re.subn(pat, '', s)
    assert n == 1, pat
for d in ['    function CanAnimateCollapse: Boolean;\n', '    procedure StartCollapseAnim(const AToCollapsed: Boolean);\n',
          '    procedure CollapseAnimStep;\n', '    procedure FinishCollapseAnim;\n', '    procedure ArmAutoCollapse;\n',
          '    procedure AutoCollapseTick;\n']:
    s = rep(s, d, '')
s = rep(s, '    procedure SetAutoCollapseSecs(AValue: Integer);\n',
        '    procedure SetAutoCollapseSecs(AValue: Integer);\n    function GetAutoCollapseSecs: Integer;\n'
        '    function GetAnimateCollapse: Boolean;\n    procedure SetAnimateCollapse(AValue: Boolean);\n'
        '    function GetCollapseOnFullscreen: Boolean;\n')
s = rep(s, 'property CollapseOnFullscreen: Boolean read FCollapseOnFullscreen write SetCollapseOnFullscreen;',
        'property CollapseOnFullscreen: Boolean read GetCollapseOnFullscreen write SetCollapseOnFullscreen;')
s = rep(s, 'property AnimateCollapse: Boolean read FAnimateCollapse write FAnimateCollapse;',
        'property AnimateCollapse: Boolean read GetAnimateCollapse write SetAnimateCollapse;')
s = rep(s, 'property AutoCollapseSecs: Integer read FAutoCollapseSecs write SetAutoCollapseSecs;',
        'property AutoCollapseSecs: Integer read GetAutoCollapseSecs write SetAutoCollapseSecs;')
s = rep(s, '    function BarIsCollapsed: Boolean;\n',
        '    function BarIsCollapsed: Boolean;\n'
        '    // ICollapseHost\n'
        '    procedure BarUpdateSize;\n'
        '    procedure BarStartTimer(const AId: UINT; const AMs: Cardinal);\n'
        '    procedure BarStopTimer(const AId: UINT);\n'
        '    procedure BarDismissPopups;\n'
        '    procedure BarSetAutoHideLock(const ALock: Boolean);\n'
        '    procedure BarRelayout;\n'
        '    function BarCanAnimate: Boolean;\n'
        '    function BarCollapsedLength(const AVertical: Boolean): Integer;\n'
        '    procedure BarShowFrame(const ARect: TRect);\n'
        '    function BarIsBusy: Boolean;\n'
        '    function BarHasCollapseButton: Boolean;\n'
        '    function BarHandleAllocated: Boolean;\n')

# constantes que pasan a la unidad
s = rep(s, '  TIMER_COLLAPSE_ANIM = 23;\n  TIMER_AUTOCOLLAPSE = 24;\n  COLLAPSE_ANIM_MS = 180;\n', '')

# implementacion del host
HOST_IMPL = """procedure TLinkbarWcl.BarUpdateSize;
begin
  UpdateWindowSize;
end;

procedure TLinkbarWcl.BarStartTimer(const AId: UINT; const AMs: Cardinal);
begin
  SetTimer(Handle, AId, AMs, nil);
end;

procedure TLinkbarWcl.BarStopTimer(const AId: UINT);
begin
  KillTimer(Handle, AId);
end;

procedure TLinkbarWcl.BarDismissPopups;
begin
  CloseThumbs;
  ToolTip.Cancel;
end;

procedure TLinkbarWcl.BarSetAutoHideLock(const ALock: Boolean);
begin
  FLockAutoHide := ALock;
end;

procedure TLinkbarWcl.BarRelayout;
begin
  oAppBar.AppBarPosChanged;
end;

function TLinkbarWcl.BarCanAnimate: Boolean;
begin
  Result := IsDock and Assigned(oAppBar) and (not FAutoHiden) and IsWindowVisible(Handle);
end;

function TLinkbarWcl.BarCollapsedLength(const AVertical: Boolean): Integer;
begin
  Result := ItemsMargin + PinnedLength(AVertical) + FSysWidgets.ReservedLength(AVertical);
end;

procedure TLinkbarWcl.BarShowFrame(const ARect: TRect);
var
  pt1, pt2: TPoint;
  sz: TSize;
begin
  if IsVertical(Align)
  then pt2 := Point(0, BitmapPanel.Height - ARect.Height)
  else pt2 := Point(BitmapPanel.Width - ARect.Width, 0);
  pt1 := ARect.TopLeft;
  sz := TSize.Create(ARect.Width, ARect.Height);
  UpdateLayeredWindow(Handle, 0, @pt1, @sz, BitmapPanel.Dc, @pt2, 0, @bf, ULW_ALPHA);
end;

function TLinkbarWcl.BarIsBusy: Boolean;
var
  pt: TPoint;
begin
  GetCursorPos(pt);
  Result := FAutoHiden or FHiddenByFullscreen
         or FLockAutoHide or FLockHotIndex or FMouseLeftDown or FDockSliding
         or PtInRect(BoundsRect, pt);
end;

function TLinkbarWcl.BarHasCollapseButton: Boolean;
begin
  Result := FSysWidgets.Enabled;
end;

function TLinkbarWcl.BarHandleAllocated: Boolean;
begin
  Result := HandleAllocated;
end;

"""
s = rep(s, 'function TLinkbarWcl.GetShowSysWidgets: Boolean;', HOST_IMPL + 'function TLinkbarWcl.GetShowSysWidgets: Boolean;')

# usos
s = rep(s, 'KillTimer(Handle, TIMER_AUTOCOLLAPSE);', 'FCollapse.CancelAuto;', 0)
s = rep(s, 'FinishCollapseAnim', 'FCollapse.FinishAnim', 0)
s = rep(s, 'CanAnimateCollapse', 'FCollapse.CanAnimate', 0)
s = rep(s, 'StartCollapseAnim(', 'FCollapse.StartAnim(', 0)
s = rep(s, 'ArmAutoCollapse', 'FCollapse.ArmAuto', 0)
s = rep(s, '              AutoCollapseTick;\n', '              if Assigned(FCollapse)\n              then FCollapse.AutoTick;\n')
s = rep(s, '              CollapseAnimStep;\n', '              if Assigned(FCollapse)\n              then FCollapse.AnimStep;\n')
for old, new in [('FAnimating', 'FCollapse.Animating'), ('FAnimBuild', 'FCollapse.AnimBuild'),
                 ('FAnimRectExp', 'FCollapse.AnimRectExp'), ('FMacCollapsed', 'FCollapse.ManualCollapsed'),
                 ('FCollapsedByFullscreen', 'FCollapse.CollapsedByFullscreen'),
                 ('FCollapsedByIdle', 'FCollapse.CollapsedByIdle'), ('FAutoCollapseSecs', 'FCollapse.AutoSecs'),
                 ('FAnimateCollapse', 'FCollapse.AnimateEnabled'), ('FCollapseOnFullscreen', 'FCollapse.OnFullscreen')]:
    s = re.sub(r'\b' + old + r'\b', new, s)

# crear / liberar
s = rep(s, '  FSysWidgets := TSysWidgets.Create(Self);\n', '  FSysWidgets := TSysWidgets.Create(Self);\n  FCollapse := TBarCollapse.Create(Self);\n')
s = rep(s, '  FreeAndNil(FSysWidgets);\n', '  FreeAndNil(FCollapse);\n  FreeAndNil(FSysWidgets);\n')
s = rep(s, '  Linkbar.Bar.SysWidgets;', '  Linkbar.Bar.SysWidgets, Linkbar.Bar.Collapse;')
open(p, 'wb').write(s.replace('\n', '\r\n').encode('utf-8'))

d = 'Linkbar.dproj'
t = open(d, 'rb').read().decode('utf-8')
k = '        <DCCReference Include="Linkbar.Bar.SysWidgets.pas"/>'
nl = '\r\n' if '\r\n' in t else '\n'
t = t.replace(k, k + nl + '        <DCCReference Include="Linkbar.Bar.Collapse.pas"/>', 1)
open(d, 'wb').write(t.encode('utf-8'))
