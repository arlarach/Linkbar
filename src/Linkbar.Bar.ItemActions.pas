{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   What happens when an item is activated: run, open   }
{   a group, run an action button, run as administrator }
{   and rename                                          }
{*******************************************************}

unit Linkbar.Bar.ItemActions;

{$i linkbar.inc}

interface

uses
  Winapi.Windows,
  Linkbar.Bar.Host, Linkbar.Bar.Fullscreen;

type
  // What the item actions need from the bar window
  IItemActionsHost = interface(ILinkbarHost)
    ['{3E7A9C15-D824-4F6B-A0E1-5B2C8D4F7963}']
    // Window that was in front before the mouse was pressed on the bar
    function BarForegroundAtMouseDown: HWND;
    // Opens a group as a popup grid of icons
    procedure BarShowGroup(const AIndex: Integer);
    procedure BarRenameGroup(const AIndex: Integer);
  end;

  TItemActivator = class
  private
    FHost: IItemActionsHost;
    FFullscreen: TFullscreenWatcher;
    function IsItem(const AIndex: Integer): Boolean;
  public
    constructor Create(const AHost: IItemActionsHost; const AFullscreen: TFullscreenWatcher);
    // Runs the item: action button, group, program in the front or a new instance
    procedure Execute(const AIndex: Integer);
    // Click on an item (Ctrl+Shift runs it as administrator)
    procedure Click(const AIndex: Integer);
    procedure Rename(const AIndex: Integer);
    // Runs an action button sending its keys to the window that was in front
    procedure RunAction(const AIndex: Integer);
  end;

implementation

uses
  Winapi.ShellAPI, LBToolbar, Linkbar.Actions, RenameDialog;

constructor TItemActivator.Create(const AHost: IItemActionsHost; const AFullscreen: TFullscreenWatcher);
begin
  inherited Create;
  FHost := AHost;
  FFullscreen := AFullscreen;
end;

function TItemActivator.IsItem(const AIndex: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex < FHost.BarItems.Count);
end;

procedure TItemActivator.Execute(const AIndex: Integer);
begin
  if not IsItem(AIndex)
  then Exit;

  if (FHost.BarItems[AIndex] is TItemAction)
  then RunAction(AIndex)
  else if (FHost.BarItems[AIndex] is TItemGroup)
  then FHost.BarShowGroup(AIndex)
  // Open program: bring it to the front / minimize / next window (like the taskbar)
  else if FHost.BarItems[AIndex].Running
          and ActivateProgram(FHost.BarItems[AIndex].TargetPath, FHost.BarForegroundAtMouseDown)
  then Exit
  else FHost.BarItems[AIndex].DoExecute(FHost.BarHandle);
end;

procedure TItemActivator.Click(const AIndex: Integer);
begin

  // Ctrl+Shift+click: run as administrator
  if IsItem(AIndex)
     and (GetKeyState(VK_CONTROL) < 0)
     and (GetKeyState(VK_SHIFT) < 0)
     and (not FHost.BarItems.IsSeparator(FHost.BarItems[AIndex]))
     and (not (FHost.BarItems[AIndex] is TItemGroup))
     and (not (FHost.BarItems[AIndex] is TItemAction))
  then begin
    ShellExecute(FHost.BarHandle, 'runas', PChar(FHost.BarItems[AIndex].FileName), nil, nil, SW_SHOWNORMAL);
    Exit;
  end;

  Execute(AIndex);
end;

procedure TItemActivator.Rename(const AIndex: Integer);
var dlg: TRenamingWCl;
begin
  if not IsItem(AIndex)
  then Exit;

  // Groups: ask only the name, keep the ".group" suffix
  if (FHost.BarItems[AIndex] is TItemGroup)
  then begin
    FHost.BarRenameGroup(AIndex);
    Exit;
  end;

  FHost.BarSetAutoHideLock(True);
  dlg := TRenamingWCl.Create(FHost.BarOwner);
  dlg.Pidl := FHost.BarItems[AIndex].Pidl;
  dlg.ShowModal;
  dlg.Free;
  FHost.BarSetAutoHideLock(False);
end;

procedure TItemActivator.RunAction(const AIndex: Integer);
var target: HWND;
begin
  target := FHost.BarForegroundAtMouseDown;
  if TFullscreenWatcher.IsOurWindow(target)
  then target := FFullscreen.LastForeignWnd;
  if TFullscreenWatcher.IsOurWindow(target)
  then target := 0;
  ReleaseCapture;
  Linkbar.Actions.RunAction(TItemAction(FHost.BarItems[AIndex]).Data, target);
end;

end.
