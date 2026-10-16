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


# ---------- 1. unidad nueva ----------
UNIT = """{*******************************************************}
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
    function BarWorkDir: string;
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
  LBToolbar, Linkbar.Consts, Linkbar.GroupForm, Linkbar.IconPicker, Linkbar.Shell;

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
"""
wr('Linkbar.Bar.Launcher.pas', UNIT)

# ---------- 2. mUnit.pas ----------
p = 'mUnit.pas'
s = rd(p)

NEW_IMPL = """{ Show the bar or only its taskbar button, depending on the style }
procedure TLinkbarWcl.ApplyTaskbarMode;
begin
  FLauncher.Apply(IsTaskbarIcon);
end;

procedure TLinkbarWcl.UpdateTaskbarIcon;
begin
  if Assigned(FLauncher)
  then FLauncher.UpdateIcon;
end;

procedure TLinkbarWcl.SetTaskbarIcon(const AValue: string);
begin
  FLauncher.ChangeIcon(AValue);
end;

function TLinkbarWcl.GetTaskbarIcon: string;
begin
  Result := FLauncher.IconSpec;
end;

function TLinkbarWcl.BarPanelName: string;
begin
  Result := PanelName;
end;

function TLinkbarWcl.BarSettingsFile: string;
begin
  Result := FSettingsFileName;
end;

function TLinkbarWcl.BarWorkDir: string;
begin
  Result := WorkDir;
end;

procedure TLinkbarWcl.BarHideForLauncher;
begin
  CloseThumbs;
  ToolTip.Cancel;
  ShowWindow(Handle, SW_HIDE);
end;

procedure TLinkbarWcl.BarRestoreFromLauncher;
begin
  if not IsWindowVisible(Handle) and not FFullscreen.HiddenByFullscreen
  then begin
    ShowWindow(Handle, SW_SHOWNA);
    oAppBar.AppBarPosChanged;
  end;
end;

function TLinkbarWcl.BarActionTarget: HWND;
begin
  Result := GetForegroundWindow;
  if TFullscreenWatcher.IsOurWindow(Result) or TFullscreenWatcher.IsShellUiWindow(Result)
  then Result := FFullscreen.LastForeignWnd;
  if TFullscreenWatcher.IsOurWindow(Result)
  then Result := 0;
end;

function TLinkbarWcl.BarSysStatsEnabled: Boolean;
begin
  Result := FSysWidgets.Enabled;
end;

procedure TLinkbarWcl.BarSysStats(out ACpu, ARam: Integer);
begin
  // the widgets timer keeps sampling while the bar is hidden
  ACpu := FSysWidgets.CpuLoad;
  ARam := FSysWidgets.RamLoad;
end;

{ Extra items in the popup menu: settings and back to a normal bar }
procedure TLinkbarWcl.BarFillLauncherMenu(AMenu: TPopupMenu);
var mi: TMenuItem;
begin
  mi := TMenuItem.Create(AMenu);
  mi.Caption := L10NFind('Menu.ShowAsBar', 'Show as a bar');
  mi.OnClick := LauncherShowAsBar;
  AMenu.Items.Add(mi);
  mi := TMenuItem.Create(AMenu);
  mi.Caption := imProperties.Caption;
  mi.OnClick := imPropertiesClick;
  AMenu.Items.Add(mi);
end;

procedure TLinkbarWcl.BarCloseRequested(Sender: TObject);
begin
  imCloseClick(Sender);
end;

procedure TLinkbarWcl.BarActivate(const AWnd: HWND);
begin
  SetForegroundWindowInternal(AWnd);
end;

"""
s = s.replace(seg(s, '{ Show the bar or only its taskbar button, depending on the style }',
                  'procedure TLinkbarWcl.LauncherShowAsBar(Sender: TObject);'), NEW_IMPL)

s = rep(s, 'IFullscreenHost, IThumbsHost)', 'IFullscreenHost, IThumbsHost, ILauncherHost)')
for pat in [r'    FTaskbarButton: TForm;[^\n]*\n', r'    FLauncherOpen: Boolean;[^\n]*\n',
            r'    FLauncherClosedAt: Cardinal;[^\n]*\n']:
    s, n = re.subn(pat, '', s)
    assert n == 1, pat
s = rep(s, '    FTaskbarIcon: string;        // icon of the taskbar button: \'\' = automatic, "file,index"\n',
        '    FLauncher: TLauncherMode;    // "taskbar icon" mode\n')
for d in ['    procedure TaskbarButtonClick(Sender: TObject);\n', '    procedure TaskbarButtonClose(Sender: TObject);\n',
          '    procedure LauncherPopupDestroy(Sender: TObject);\n', '    procedure LauncherRootMenu(AMenu: TPopupMenu);\n',
          '    procedure LauncherSysStats(out ACpu, ARam: Integer);\n', '    procedure LauncherChanged(Sender: TObject);\n']:
    s = rep(s, d, '')
s = rep(s, '    procedure SetTaskbarIcon(const AValue: string);\n', '    procedure SetTaskbarIcon(const AValue: string);\n    function GetTaskbarIcon: string;\n')
s = rep(s, 'property TaskbarIcon: string read FTaskbarIcon write SetTaskbarIcon;', 'property TaskbarIcon: string read GetTaskbarIcon write SetTaskbarIcon;')
s = rep(s, '    function BarThumbsBlocked: Boolean;\n',
        '    function BarThumbsBlocked: Boolean;\n'
        '    // ILauncherHost\n'
        '    function BarPanelName: string;\n'
        '    function BarSettingsFile: string;\n'
        '    function BarWorkDir: string;\n'
        '    procedure BarHideForLauncher;\n'
        '    procedure BarRestoreFromLauncher;\n'
        '    function BarActionTarget: HWND;\n'
        '    function BarSysStatsEnabled: Boolean;\n'
        '    procedure BarSysStats(out ACpu, ARam: Integer);\n'
        '    procedure BarFillLauncherMenu(AMenu: TPopupMenu);\n'
        '    procedure BarCloseRequested(Sender: TObject);\n'
        '    procedure BarActivate(const AWnd: HWND);\n')
s = re.sub(r'\bFTaskbarIcon\b', 'FLauncher.IconSpec', s)

s = rep(s, '  FThumbs := TThumbController.Create(Self);\n', '  FThumbs := TThumbController.Create(Self);\n  FLauncher := TLauncherMode.Create(Self);\n')
s = rep(s, '  FreeAndNil(FRunning);\n', '  FreeAndNil(FLauncher);\n  FreeAndNil(FRunning);\n')
s = rep(s, 'Linkbar.Bar.Thumbs, Linkbar.Bar.Running;', 'Linkbar.Bar.Thumbs, Linkbar.Bar.Running, Linkbar.Bar.Launcher;')
wr(p, s)

d = rd('Linkbar.dproj')
k = '        <DCCReference Include="Linkbar.Bar.Running.pas"/>'
d = rep(d, k, k + '\n        <DCCReference Include="Linkbar.Bar.Launcher.pas"/>')
wr('Linkbar.dproj', d)
