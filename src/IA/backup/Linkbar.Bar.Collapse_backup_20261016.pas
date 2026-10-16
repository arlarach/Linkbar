{*******************************************************}
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
