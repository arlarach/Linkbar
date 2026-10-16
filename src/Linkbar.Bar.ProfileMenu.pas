{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   Profiles menu: the submenu of profiles and the      }
{   commands to switch, create, rename and delete them  }
{*******************************************************}

unit Linkbar.Bar.ProfileMenu;

{$i linkbar.inc}

interface

uses
  Classes, Vcl.Menus,
  Linkbar.Bar.Host, Linkbar.Bar.Profiles;

type
  // What the profiles menu needs from the bar window
  IProfileHost = interface(ILinkbarHost)
    ['{A07F3C94-2B6E-4D18-8E5A-9C1D4B7F0E62}']
    procedure BarSaveLinks;
    // Changes the links folder of the bar (and its folder watcher)
    procedure BarSetWorkDir(const ADir: string);
    // Loads the items of the current links folder
    procedure BarReloadLinks;
  end;

  TProfileMenu = class
  private
    FHost: IProfileHost;
    FProfiles: TProfileManager;
    procedure ItemClick(Sender: TObject);
    procedure NewClick(Sender: TObject);
    procedure RenameClick(Sender: TObject);
    procedure DeleteClick(Sender: TObject);
  public
    constructor Create(const AHost: IProfileHost; const AProfiles: TProfileManager);
    procedure Switch(const AName: string);
    // Next (1) or previous (-1) profile
    procedure Cycle(const ADelta: Integer);
    // Fills the submenu with the profiles and the commands
    procedure Build(const AMenu: TMenuItem; const AOwner: TComponent);
  end;

implementation

uses
  Winapi.Windows, SysUtils, Vcl.Dialogs,
  Linkbar.Consts, Linkbar.Settings, Linkbar.Shell, Linkbar.L10n;

constructor TProfileMenu.Create(const AHost: IProfileHost; const AProfiles: TProfileManager);
begin
  inherited Create;
  FHost := AHost;
  FProfiles := AProfiles;
end;

procedure TProfileMenu.Switch(const AName: string);
var dir: string;
    settings: TSettingsFile;
begin
  if SameText(AName, FProfiles.Current) then Exit;
  dir := FProfiles.ProfileDir(AName);
  if not (DirectoryExists(dir) or ForceDirectories(dir)) then Exit;
  FHost.BarDismissPopups;
  FHost.BarSaveLinks;
  FProfiles.Current := AName;
  settings.Open(FHost.BarSettingsFile);
  settings.Write(INI_PROFILE, FProfiles.Current);
  settings.Close;
  FHost.BarSetWorkDir(dir);
  FHost.BarReloadLinks;
end;

procedure TProfileMenu.Cycle(const ADelta: Integer);
begin
  Switch(FProfiles.Neighbour(ADelta));
end;

procedure TProfileMenu.Build(const AMenu: TMenuItem; const AOwner: TComponent);

  function Add(const ACaption, AHint: string; AOnClick: TNotifyEvent; AChecked: Boolean = False): TMenuItem;
  begin
    Result := TMenuItem.Create(AOwner);
    Result.Caption := ACaption;
    Result.Hint := AHint;
    Result.Checked := AChecked;
    Result.OnClick := AOnClick;
    AMenu.Add(Result);
  end;

var name, mainName: string;
begin
  AMenu.Clear;
  mainName := L10NFind('Profile.Main', 'Main');
  if (FProfiles.Current = '')
  then AMenu.Caption := L10NFind('Menu.Profile', 'Profile') + ': ' + mainName
  else AMenu.Caption := L10NFind('Menu.Profile', 'Profile') + ': ' + FProfiles.Current;

  Add(mainName, '', ItemClick, FProfiles.Current = '');
  for name in FProfiles.Names do
    Add(name, name, ItemClick, SameText(name, FProfiles.Current));
  Add('-', '', nil);
  Add(L10NFind('Profile.New', 'New profile...'), '', NewClick);
  if (FProfiles.Current <> '')
  then begin
    Add(L10NFind('Profile.Rename', 'Rename this profile...'), '', RenameClick);
    Add(L10NFind('Profile.Delete', 'Delete this profile'), '', DeleteClick);
  end;
end;

procedure TProfileMenu.ItemClick(Sender: TObject);
begin
  Switch(TMenuItem(Sender).Hint);
end;

procedure TProfileMenu.NewClick(Sender: TObject);
var name: string;
begin
  name := '';
  FHost.BarSetAutoHideLock(True);
  try
    if not InputQuery(L10NFind('Profile.NewTitle', 'New profile'),
                      L10NFind('Profile.NamePrompt', 'Profile name (for example Work):'), name)
    then Exit;
  finally
    FHost.BarSetAutoHideLock(False);
  end;
  name := Trim(name);
  if not TProfileManager.IsValidName(name)
  then Exit;
  if DirectoryExists(FProfiles.ProfileDir(name))
  then begin
    Switch(name);
    Exit;
  end;
  if ForceDirectories(FProfiles.ProfileDir(name))
  then Switch(name);
end;

procedure TProfileMenu.RenameClick(Sender: TObject);
var name, oldName: string;
    settings: TSettingsFile;
begin
  if (FProfiles.Current = '') then Exit;
  oldName := FProfiles.Current;
  name := oldName;
  FHost.BarSetAutoHideLock(True);
  try
    if not InputQuery(L10NFind('Profile.RenameTitle', 'Rename profile'),
                      L10NFind('Profile.NamePrompt', 'Profile name (for example Work):'), name)
    then Exit;
  finally
    FHost.BarSetAutoHideLock(False);
  end;
  name := Trim(name);
  if not TProfileManager.IsValidName(name) or SameText(name, oldName)
     or DirectoryExists(FProfiles.ProfileDir(name))
  then Exit;
  // stop watching the folder before renaming it
  FHost.BarSaveLinks;
  FHost.BarSetWorkDir(FProfiles.BaseDir);
  if RenameFile(ExcludeTrailingPathDelimiter(FProfiles.ProfileDir(oldName)),
                ExcludeTrailingPathDelimiter(FProfiles.ProfileDir(name)))
  then FProfiles.Current := name;
  FHost.BarSetWorkDir(FProfiles.ProfileDir(FProfiles.Current));
  settings.Open(FHost.BarSettingsFile);
  settings.Write(INI_PROFILE, FProfiles.Current);
  settings.Close;
  FHost.BarReloadLinks;
end;

procedure TProfileMenu.DeleteClick(Sender: TObject);
var name: string;
begin
  if (FProfiles.Current = '') then Exit;
  name := FProfiles.Current;
  FHost.BarSetAutoHideLock(True);
  try
    if (MessageBox(FHost.BarHandle,
          PChar(Format(L10NFind('Profile.DeleteConfirm',
            'Delete the profile "%s"? Its icons go to the Recycle Bin.'), [name])),
          PChar(APP_NAME_LINKBAR), MB_ICONQUESTION or MB_YESNO) <> IDYES)
    then Exit;
  finally
    FHost.BarSetAutoHideLock(False);
  end;
  Switch('');
  SHDeleteOp(FHost.BarHandle, ExcludeTrailingPathDelimiter(FProfiles.ProfileDir(name)), True);
end;

end.
