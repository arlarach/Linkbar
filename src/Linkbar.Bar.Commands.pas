{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   Commands of the context menu of the bar: new group, }
{   rename a group and remove the bar                   }
{*******************************************************}

unit Linkbar.Bar.Commands;

{$i linkbar.inc}

interface

uses
  Linkbar.Bar.Host, Linkbar.Bar.Profiles;

type
  // What the commands need from the bar window
  ICommandsHost = interface(ILinkbarHost)
    ['{F5D2B863-1C47-4A09-AE3F-6B8E0D9A2C75}']
    // The bar was removed by the user: its settings must not be saved again
    procedure BarMarkRemoved;
    procedure BarStopDirWatch;
  end;

  TBarCommands = class
  private
    FHost: ICommandsHost;
    FProfiles: TProfileManager;
  public
    constructor Create(const AHost: ICommandsHost; const AProfiles: TProfileManager);
    // New empty group in the links folder
    procedure NewGroup;
    procedure RenameGroup(const AIndex: Integer);
    // Asks for confirmation and removes the bar (and, if asked, its folder)
    procedure RemoveBar;
  end;

implementation

uses
  Winapi.Windows, SysUtils, System.UITypes, Vcl.Controls, Vcl.Dialogs,
  Linkbar.Consts, Linkbar.Shell, Linkbar.L10n;

constructor TBarCommands.Create(const AHost: ICommandsHost; const AProfiles: TProfileManager);
begin
  inherited Create;
  FHost := AHost;
  FProfiles := AProfiles;
end;

procedure TBarCommands.RenameGroup(const AIndex: Integer);
const InvalidChars: array[0..8] of Char = ('\', '/', ':', '*', '?', '"', '<', '>', '|');
var newName, oldPath, newPath: string;
    ch: Char;
begin
  oldPath := ExcludeTrailingPathDelimiter(FHost.BarItems[AIndex].FileName);
  newName := FHost.BarItems[AIndex].Caption;

  FHost.BarSetAutoHideLock(True);
  try
    if not InputQuery(L10NFind('Group.RenameTitle', 'Rename group'),
                      L10NFind('Group.RenamePrompt', 'Name:'), newName)
    then Exit;
  finally
    FHost.BarSetAutoHideLock(False);
  end;

  newName := Trim(newName);
  if (newName = '') or SameText(newName, FHost.BarItems[AIndex].Caption)
  then Exit;
  for ch in InvalidChars do
    if (Pos(ch, newName) > 0)
    then begin
      MessageDlg(L10NFind('Group.InvalidName', 'The name cannot contain: \ / : * ? " < > |'),
        mtWarning, [mbOK], 0);
      Exit;
    end;

  newPath := FHost.BarWorkDir + newName + ES_GROUP;
  if DirectoryExists(newPath) or FileExists(newPath)
  then begin
    MessageDlg(L10NFind('Group.NameExists', 'A group with this name already exists.'),
      mtWarning, [mbOK], 0);
    Exit;
  end;

  // The folder watcher updates the bar item (rename events)
  if not RenameFile(oldPath, newPath)
  then MessageDlg(SysErrorMessage(GetLastError), mtError, [mbOK], 0);
end;

{ New empty group: sub-folder "<name>.group". The folder watcher adds it to the bar.
  Drag shortcuts from the bar onto the group icon to move them inside. }
procedure TBarCommands.NewGroup;
var baseName, dirName: string;
    n: Integer;
begin
  baseName := L10NFind('Menu.GroupDefaultName', 'Group');
  dirName := FHost.BarWorkDir + baseName + ES_GROUP;
  n := 2;
  while DirectoryExists(dirName) or FileExists(dirName) do
  begin
    dirName := FHost.BarWorkDir + baseName + ' ' + IntToStr(n) + ES_GROUP;
    Inc(n);
  end;
  ForceDirectories(dirName);
end;

procedure TBarCommands.RemoveBar;
var td: TTaskDialog;
begin
  td := TTaskDialog.Create(FHost.BarOwner);
  FHost.BarSetAutoHideLock(True);
  try
    td.Caption := ' ' + APP_NAME_LINKBAR;
    td.MainIcon := tdiNone;
    td.Title := Format( L10NFind('Delete.Title', 'You remove the linkbar "%s"'), [FHost.BarPanelName] );
    td.Text := Format( L10NFind('Delete.Text', 'Working directory: %s'), [FProfiles.BaseDir] );
    td.VerificationText := L10NFind('Delete.Verification', 'Delete working directory') + Format('%*s', [24, ' ']);
    td.CommonButtons := [tcbOk, tcbCancel];
    td.DefaultButton := tcbCancel;

    if (td.Execute)
       and (td.ModalResult = mrOk)
    then begin
      FHost.BarMarkRemoved;
      DeleteFile(FHost.BarSettingsFile);
      if (tfVerificationFlagChecked in td.Flags)
      then begin
        FHost.BarStopDirWatch;
        SHDeleteOp(FHost.BarHandle, FProfiles.BaseDir, True);
      end;
      PostQuitMessage(0);
    end;
  finally
    FHost.BarSetAutoHideLock(False);
    td.Free;
  end;
end;

end.
