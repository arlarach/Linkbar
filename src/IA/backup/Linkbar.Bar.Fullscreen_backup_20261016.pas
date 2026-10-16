{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   Window in front and full screen detection: hides    }
{   or collapses the bar while a full screen app runs   }
{   and remembers the last window that is not ours      }
{*******************************************************}

unit Linkbar.Bar.Fullscreen;

{$i linkbar.inc}

interface

uses
  Windows,
  Linkbar.Bar.Host, Linkbar.Bar.Collapse;

type
  // What the watcher needs from the bar window
  IFullscreenHost = interface(ILinkbarHost)
    ['{5E92C0B7-14D3-4A68-B3F5-9D1E7A2C4086}']
    function BarHandle: HWND;
    function BarIsTaskbarIcon: Boolean;
    // Closes the thumbnails and the tooltip
    procedure BarDismissPopups;
    // Recalculates the size of the window and redraws it
    procedure BarUpdateSize;
  end;

  TFullscreenWatcher = class
  private
    FHost: IFullscreenHost;
    FCollapse: TBarCollapse;
    FHide: Boolean;               // hide the bar when an app is full screen
    FHidden: Boolean;             // hidden by a full screen app (not saved)
    FLastForeign: HWND;           // last window in front that is not ours (action buttons)
  public
    constructor Create(const AHost: IFullscreenHost; const ACollapse: TBarCollapse);
    // The window belongs to this process (or does not exist)
    class function IsOurWindow(const AWnd: HWND): Boolean; static;
    // Taskbar, Start menu...: not a window to send the keys of an action button to
    class function IsShellUiWindow(const AWnd: HWND): Boolean; static;
    // Timer: remember the window in front and hide / collapse when it is full screen
    procedure Check;
    // Setter with effect on the window (the property only stores the value)
    procedure ChangeHide(const AValue: Boolean);
    property HideOnFullscreen: Boolean read FHide write FHide;
    property HiddenByFullscreen: Boolean read FHidden;
    property LastForeignWnd: HWND read FLastForeign write FLastForeign;
  end;

implementation

uses
  SysUtils, Types, StrUtils, Forms;

function LB_SHQueryUserNotificationState(out pquns: Integer): HRESULT; stdcall;
  external 'shell32.dll' name 'SHQueryUserNotificationState';

constructor TFullscreenWatcher.Create(const AHost: IFullscreenHost; const ACollapse: TBarCollapse);
begin
  inherited Create;
  FHost := AHost;
  FCollapse := ACollapse;
end;

class function TFullscreenWatcher.IsShellUiWindow(const AWnd: HWND): Boolean;
var cls: array[0..63] of Char;
begin
  cls[0] := #0;
  GetClassName(AWnd, cls, Length(cls));
  Result := MatchText(PChar(@cls[0]), ['Shell_TrayWnd', 'Shell_SecondaryTrayWnd',
    'NotifyIconOverflowWindow', 'TopLevelWindowForOverflowXamlIsland',
    'Windows.UI.Core.CoreWindow', 'XamlExplorerHostIslandWindow', 'TaskListThumbnailWnd']);
end;

class function TFullscreenWatcher.IsOurWindow(const AWnd: HWND): Boolean;
var pid: DWORD;
begin
  Result := True;
  if (AWnd = 0) or not IsWindow(AWnd) then Exit;
  pid := 0;
  GetWindowThreadProcessId(AWnd, @pid);
  Result := (pid = GetCurrentProcessId);
end;

procedure TFullscreenWatcher.Check;
const
  QUNS_RUNNING_D3D_FULL_SCREEN = 3;
  QUNS_PRESENTATION_MODE = 4;
var
  fg: HWND;
  r: TRect;
  mon: Vcl.Forms.TMonitor;
  mr: TRect;
  cls: array[0..63] of Char;
  state: Integer;
  full: Boolean;
begin
  fg := GetForegroundWindow;
  if not IsOurWindow(fg) and not IsShellUiWindow(fg)
  then FLastForeign := fg;

  full := False;
  if (FHide or FCollapse.OnFullscreen) and (fg <> 0) and not IsOurWindow(fg) and not FHost.BarIsTaskbarIcon
  then begin
    // Windows own detection (games, presentations)
    state := 0;
    if Succeeded(LB_SHQueryUserNotificationState(state))
       and ((state = QUNS_RUNNING_D3D_FULL_SCREEN) or (state = QUNS_PRESENTATION_MODE))
    then full := True
    else begin
      // A window that covers our whole monitor (video, browser F11, borderless games)
      cls[0] := #0;
      GetClassName(fg, cls, Length(cls));
      // desktop, taskbar, Start menu, task view: not "full screen apps"
      if not MatchText(PChar(@cls[0]), ['Progman', 'WorkerW', 'Shell_TrayWnd',
               'MultitaskingViewFrame', 'XamlExplorerHostIslandWindow',
               'Windows.UI.Core.CoreWindow', 'ForegroundStaging'])
         and not IsZoomed(fg)
         and GetWindowRect(fg, r)
      then begin
        // only when it is on the same monitor as the bar
        mon := Screen.MonitorFromWindow(fg, mdNearest);
        if Assigned(mon) and (mon = Screen.MonitorFromWindow(FHost.BarHandle, mdNearest))
        then begin
          mr := mon.BoundsRect;
          full := (r.Left <= mr.Left) and (r.Top <= mr.Top)
              and (r.Right >= mr.Right) and (r.Bottom >= mr.Bottom);
        end;
      end;
    end;
  end;

  // "Hide" prevails over "collapse" when both are enabled
  const hideIt = full and FHide;
  const collapseIt = full and FCollapse.OnFullscreen and not FHide;

  if (hideIt <> FHidden)
  then begin
    FHidden := hideIt;
    if hideIt
    then begin
      FHost.BarDismissPopups;
      ShowWindow(FHost.BarHandle, SW_HIDE);
    end
    else ShowWindow(FHost.BarHandle, SW_SHOWNA);
  end;

  if (collapseIt <> FCollapse.CollapsedByFullscreen)
  then begin
    FCollapse.CollapsedByFullscreen := collapseIt;
    if collapseIt
    then FHost.BarDismissPopups;
    FHost.BarUpdateSize;
  end;
end;

procedure TFullscreenWatcher.ChangeHide(const AValue: Boolean);
begin
  FHide := AValue;
  if not AValue and FHidden
  then begin
    FHidden := False;
    ShowWindow(FHost.BarHandle, SW_SHOWNA);
  end;
end;

end.
