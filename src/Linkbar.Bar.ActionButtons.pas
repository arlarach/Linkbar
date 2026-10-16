{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   Action buttons of the bar: create, edit and delete  }
{   (running them depends on the mouse and stays in the }
{   bar window)                                         }
{*******************************************************}

unit Linkbar.Bar.ActionButtons;

{$i linkbar.inc}

interface

uses
  Linkbar.Actions, Linkbar.Bar.Host;

type
  // What the editor needs from the bar window
  IActionButtonsHost = interface(ILinkbarHost)
    ['{E1B47C95-0A63-4D8F-9C2E-4F7A5B3D8016}']
    // Scans the links folder again soon (reloads the icon and data of the items)
    procedure BarRescanSoon;
  end;

  TActionButtonEditor = class
  private
    FHost: IActionButtonsHost;
  public
    constructor Create(const AHost: IActionButtonsHost);
    // Asks for a new action button and saves it in the links folder
    procedure Add;
    procedure Modify(const AItem: TItemAction);
    procedure Remove(const AItem: TItemAction);
  end;

implementation

uses
  SysUtils, Linkbar.Consts, Linkbar.Shell;

constructor TActionButtonEditor.Create(const AHost: IActionButtonsHost);
begin
  inherited Create;
  FHost := AHost;
end;

procedure TActionButtonEditor.Add;
var name: string;
    data: TActionData;
    fn: string;
    n: Integer;
begin
  name := '';
  data.Clear;
  FHost.BarSetAutoHideLock(True);
  try
    if not EditAction(name, data, True)
    then Exit;
  finally
    FHost.BarSetAutoHideLock(False);
  end;
  fn := FHost.BarWorkDir + name + ES_ACTION;
  n := 2;
  while FileExists(fn) do
  begin
    fn := FHost.BarWorkDir + name + ' ' + IntToStr(n) + ES_ACTION;
    Inc(n);
  end;
  ForceDirectories(FHost.BarWorkDir);
  SaveActionFile(fn, data); // the folder watcher adds it to the bar
end;

procedure TActionButtonEditor.Modify(const AItem: TItemAction);
var name, oldFile, newFile: string;
    data: TActionData;
begin
  oldFile := AItem.FileName;
  name := AItem.Caption;
  data := AItem.Data;
  FHost.BarSetAutoHideLock(True);
  try
    if not EditAction(name, data, False)
    then Exit;
  finally
    FHost.BarSetAutoHideLock(False);
  end;
  SaveActionFile(oldFile, data);
  newFile := ExtractFilePath(oldFile) + name + ES_ACTION;
  if not SameText(newFile, oldFile) and not FileExists(newFile)
     and RenameFile(oldFile, newFile)
  then AItem.FileName := newFile;
  // reload icon/data
  AItem.NeedLoad := True;
  FHost.BarRescanSoon;
end;

procedure TActionButtonEditor.Remove(const AItem: TItemAction);
begin
  SHDeleteOp(FHost.BarHandle, AItem.FileName, True);
end;

end.
