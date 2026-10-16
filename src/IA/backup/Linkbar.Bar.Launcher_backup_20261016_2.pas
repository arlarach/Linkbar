{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   "Taskbar icon" mode: the bar is shown as a button   }
{   on the Windows taskbar that opens its content as a  }
{   popup                                               }
{*******************************************************}

unit Linkbar.Bar.Launcher;

{$i linkbar.inc}

interface

uses
  Windows, Classes, Menus,
  Linkbar.Bar.Host, Linkbar.TaskbarButton;

type
  // What the launcher mode needs from the bar window
  ILauncherHost = interface(ILinkbarHost)
    ['{2F8B5D63-A1C4-4E97-8D30-6B7E9C1A5F42}']
    function BarPanelName: string;
    function BarSettingsFile: string;
    // Closes the popups and hides the bar window (only the taskbar button stays)
    procedure BarHideForLauncher;
    // Shows the bar window again
    procedure BarRestoreFromLauncher;
    // Window that receives the keys of the action buttons of the popup
    function BarActionTarget: HWND;
    function BarSysStatsEnabled: Boolean;
    procedure BarSysStats(out ACpu, ARam: Integer);
    // Extra items of the popup menu (settings, back to a normal bar)
    procedure BarFillLauncherMenu(AMenu: TPopupMenu);
    // The user closed the taskbar button
    procedure BarCloseRequested(Sender: TObject);
    // Gives the focus to a window of this process
    procedure BarActivate(const AWnd: HWND);
  end;

  TLauncherMode = class
  private
    FHost: ILauncherHost;
    FButton: TTaskbarButton;
    FOpen: Boolean;               // its popup is open
    FClosedAt: Cardinal;          // when the popup closed (a click on the button closes it)
    FIcon: string;                // icon of the taskbar button: '' = automatic, "file,index"
    procedure ButtonClick(Sender: TObject);
    procedure ButtonClose(Sender: TObject);
    procedure PopupDestroyed(Sender: TObject);
    procedure RootMenu(AMenu: TPopupMenu);
    procedure GroupChanged(Sender: TObject);
    procedure SysStats(out ACpu, ARam: Integer);
  public
    constructor Create(const AHost: ILauncherHost);
    // Show the bar or only its taskbar button, depending on the style
    procedure Apply(const AActive: Boolean);
    // Icon of the taskbar button: the chosen one, or a 2x2 preview of the bar's
    // icons on a tile of the bar's color (so every bar looks different)
    procedure UpdateIcon;
    // Setter with effect on the button (the property only stores the value)
    procedure ChangeIcon(const AValue: string);
    property IconSpec: string read FIcon write FIcon;
  end;

implementation

uses
  SysUtils, Math, Types, Vcl.Forms,
  Winapi.ShellAPI,
  LBToolbar, Linkbar.Consts, Linkbar.GroupForm, Linkbar.IconPicker;

constructor TLauncherMode.Create(const AHost: ILauncherHost);
begin
  inherited Create;
  FHost := AHost;
end;

procedure TLauncherMode.Apply(const AActive: Boolean);
begin
  if AActive
  then begin
    if not Assigned(FButton)
    then begin
      FButton := TTaskbarButton.CreateButton(FHost.BarOwner, FHost.BarPanelName);
      FButton.OnClick := ButtonClick;
      FButton.OnCloseRequest := ButtonClose;
      // Each bar is its own taskbar app: not grouped with the other bars
      FButton.SetAppId('Arlarach.Linkbar.' + IntToHex(StrToHash(AnsiLowerCase(FHost.BarSettingsFile)), 8));
    end;
    UpdateIcon;
    FHost.BarHideForLauncher;
    FButton.ShowButton;
  end
  else begin
    if Assigned(FButton)
    then begin
      FButton.HideButton;
      FreeAndNil(FButton);
    end;
    FHost.BarRestoreFromLauncher;
  end;
end;

{ Click on the taskbar button: the bar's content as a popup above the taskbar }
procedure TLauncherMode.ButtonClick(Sender: TObject);
var r: TRect;
    edge: UINT;
    al: TPanelAlign;
begin
  // The popup closes when the button is pressed: that click only closes it
  if FOpen or (GetTickCount - FClosedAt < 400)
  then Exit;

  GetTaskbarAnchor(r, edge);
  case edge of
    ABE_TOP:   al := EPanelAlignTop;
    ABE_LEFT:  al := EPanelAlignLeft;
    ABE_RIGHT: al := EPanelAlignRight;
    else       al := EPanelAlignBottom;
  end;

  var form := TFormGroup.CreateGroup(FHost.BarOwner, FHost.BarHandle,
    ExcludeTrailingPathDelimiter(FHost.BarWorkDir), FHost.BarPanelName,
    EnsureRange(FHost.BarIconSize, 32, 64));
  form.RootLocked := True;
  // Action buttons of the popup send their keys to the window that was in front
  form.ActionTarget := FHost.BarActionTarget;
  form.OnRootMenu := RootMenu;
  form.OnDestroy := PopupDestroyed;
  form.OnGroupChanged := GroupChanged;
  // The bar is hidden: its CPU/RAM widgets go to the popup
  if FHost.BarSysStatsEnabled
  then form.EnableSysStats(SysStats);
  FOpen := True;
  form.PopupAt(r, al);
  // The popup closes when it loses the focus, so it must get it
  if (GetForegroundWindow <> form.Handle)
  then FHost.BarActivate(form.Handle);
end;

procedure TLauncherMode.PopupDestroyed(Sender: TObject);
begin
  FOpen := False;
  FClosedAt := GetTickCount;
end;

procedure TLauncherMode.ButtonClose(Sender: TObject);
begin
  FHost.BarCloseRequested(Sender);
end;

procedure TLauncherMode.RootMenu(AMenu: TPopupMenu);
begin
  FHost.BarFillLauncherMenu(AMenu);
end;

{ Something changed in the popup (color, sub-groups): refresh the button icon }
procedure TLauncherMode.GroupChanged(Sender: TObject);
begin
  UpdateIcon;
end;

procedure TLauncherMode.SysStats(out ACpu, ARam: Integer);
begin
  FHost.BarSysStats(ACpu, ARam);
end;

procedure TLauncherMode.UpdateIcon;
var
  big, small: HICON;
  bmp: HBITMAP;
begin
  if not Assigned(FButton) then Exit;
  if not IconsFromSpec(FIcon, big, small)
  then begin
    bmp := CreateGroupIcon(ExcludeTrailingPathDelimiter(FHost.BarWorkDir), GetSystemMetrics(SM_CXICON));
    big := IconFromPremultipliedBitmap(bmp);
    DeleteObject(bmp);
    bmp := CreateGroupIcon(ExcludeTrailingPathDelimiter(FHost.BarWorkDir), GetSystemMetrics(SM_CXSMICON));
    small := IconFromPremultipliedBitmap(bmp);
    DeleteObject(bmp);
  end;
  if (big = 0) and (small = 0) then Exit; // keep the current one
  FButton.SetIcons(big, small);
end;

procedure TLauncherMode.ChangeIcon(const AValue: string);
begin
  if (Trim(AValue) = FIcon) then Exit;
  FIcon := Trim(AValue);
  UpdateIcon;
end;

end.
