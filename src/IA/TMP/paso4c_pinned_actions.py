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


# ---------- 1. Host base ----------
h = rd('Linkbar.Bar.Host.pas')
h = rep(h, '  Windows, Classes, Types,\n  Linkbar.Consts;', '  Windows, Classes, Types,\n  LBToolbar, Linkbar.Consts;')
h = rep(h, '    procedure BarCancelTooltip;\n',
        '    procedure BarCancelTooltip;\n'
        '    // Closes the thumbnails and the tooltip\n'
        '    procedure BarDismissPopups;\n'
        '    procedure BarSetAutoHideLock(const ALock: Boolean);\n'
        '    // Links folder of the current profile\n'
        '    function BarWorkDir: string;\n'
        '    function BarItems: TLBItemList;\n')
wr('Linkbar.Bar.Host.pas', h)

c = rd('Linkbar.Bar.Collapse.pas')
c = rep(c, '    // Closes the thumbnails and the tooltip\n    procedure BarDismissPopups;\n    procedure BarSetAutoHideLock(const ALock: Boolean);\n', '')
wr('Linkbar.Bar.Collapse.pas', c)
f = rd('Linkbar.Bar.Fullscreen.pas')
f = rep(f, '    // Closes the thumbnails and the tooltip\n    procedure BarDismissPopups;\n', '')
wr('Linkbar.Bar.Fullscreen.pas', f)
l = rd('Linkbar.Bar.Launcher.pas')
l = rep(l, '    function BarWorkDir: string;\n', '')
wr('Linkbar.Bar.Launcher.pas', l)

# ---------- 2. unidades nuevas ----------
PINNED = """{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   Items that stay visible when the bar is collapsed:  }
{   the list file, the flags of the items, their length }
{   and the small dot drawn on them                     }
{*******************************************************}

unit Linkbar.Bar.Pinned;

{$i linkbar.inc}

interface

uses
  Types,
  LBToolbar, Linkbar.Graphics, Linkbar.Bar.Host, Linkbar.Bar.SaveQueue;

type
  // What the pinned items need from the bar window
  IPinnedHost = interface(ILinkbarHost)
    ['{9D3E6A41-7C58-4B12-A0F9-3E5B8C2D1674}']
    // The pinned flags changed: pinned items go to the end, save and lay out again
    procedure BarPinnedChanged;
    function BarDockPad: Integer;
  end;

  TPinnedItems = class
  private
    FHost: IPinnedHost;
  public
    constructor Create(const AHost: IPinnedHost);
    // Reads the pinned flags of the items from the list file of the folder
    procedure Load(const AWorkDir: string);
    // Writes the list file of the pinned items (deletes it when there are none)
    procedure Save(const AWorkDir: string; const AQueue: TFileSaveQueue);
    procedure Toggle(const AItem: TItemBase);
    procedure PinAllActions;
    procedure UnpinAll;
    // Length taken by the pinned items when the bar is collapsed
    function CollapsedLength: Integer;
    // Small dot in the corner of the icons that stay visible when the bar is collapsed
    procedure DrawMark(const ABitmap: THBitmap; const AItem: TItemBase; const ARect: TRect);
  end;

implementation

uses
  SysUtils, Classes, Math, GdiPlus, Linkbar.Consts, Linkbar.Theme, Linkbar.Actions;

constructor TPinnedItems.Create(const AHost: IPinnedHost);
begin
  inherited Create;
  FHost := AHost;
end;

procedure TPinnedItems.Load(const AWorkDir: string);
begin
  var sl := TStringList.Create;
  try
    sl.CaseSensitive := False;
    if FileExists(AWorkDir + PINNED_FILE_NAME)
    then sl.LoadFromFile(AWorkDir + PINNED_FILE_NAME, TEncoding.UTF8);

    for var item in FHost.BarItems
    do item.Pinned := (sl.IndexOf(ExtractFileName(item.FileName)) >= 0);
  finally
    sl.Free;
  end;
end;

procedure TPinnedItems.Save(const AWorkDir: string; const AQueue: TFileSaveQueue);
begin
  var sl := TStringList.Create;
  try
    for var item in FHost.BarItems
    do if item.Pinned
       then sl.Add(ExtractFileName(item.FileName));

    if (sl.Count > 0)
    then AQueue.Save(AWorkDir + PINNED_FILE_NAME, sl.Text)
    else begin
      AQueue.Forget(AWorkDir + PINNED_FILE_NAME);
      if FileExists(AWorkDir + PINNED_FILE_NAME)
      then DeleteFile(AWorkDir + PINNED_FILE_NAME);
    end;
  finally
    sl.Free;
  end;
end;

procedure TPinnedItems.Toggle(const AItem: TItemBase);
begin
  AItem.Pinned := not AItem.Pinned;
  FHost.BarPinnedChanged;
end;

procedure TPinnedItems.PinAllActions;
begin
  for var item in FHost.BarItems
  do if (item is TItemAction)
     then item.Pinned := True;
  FHost.BarPinnedChanged;
end;

procedure TPinnedItems.UnpinAll;
begin
  for var item in FHost.BarItems
  do item.Pinned := False;
  FHost.BarPinnedChanged;
end;

function TPinnedItems.CollapsedLength: Integer;
begin
  Result := FHost.BarItems.PinnedWidth;
  if (Result > 0)
  then Inc(Result, FHost.BarDockPad);
end;

procedure TPinnedItems.DrawMark(const ABitmap: THBitmap; const AItem: TItemBase; const ARect: TRect);
var
  gp: IGPGraphics;
  brush: IGPBrush;
  d: Integer;
  color: Cardinal;
begin
  if (not AItem.Pinned) or FHost.BarIsCollapsed
  then Exit;

  d := Max(4, FHost.ScaleValue(5));
  color := SwapRedBlue(GetImmersiveColorFromName('ImmersiveSystemAccent'));
  if ((color shr 24) = 0)
  then color := color or $FF000000;

  gp := TGPGraphics.Create(ABitmap.Dc);
  brush := TGPSolidBrush.Create(color);
  GPFillRoundRect(gp, brush, Bounds(ARect.Right - d - 2, ARect.Top + 2, d, d), d div 2);
end;

end.
"""
wr('Linkbar.Bar.Pinned.pas', PINNED)

EDITOR = """{*******************************************************}
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
"""
wr('Linkbar.Bar.ActionButtons.pas', EDITOR)

# ---------- 3. mUnit.pas ----------
p = 'mUnit.pas'
s = rd(p)

# SaveLinks: la parte de fijados pasa a la clase
s = s.replace(seg(s, '      // Items that stay visible when the bar is collapsed',
                  '    finally\n      sl.Free;\n    end;\n  end;\nend;\n\nprocedure TLinkbarWcl.LoadPinned;'),
              '      // Items that stay visible when the bar is collapsed\n      FPinned.Save(WorkDir, FSaveQueue);\n')
# LoadPinned y PinnedLength delegan
s = s.replace(seg(s, 'procedure TLinkbarWcl.LoadPinned;', 'procedure TLinkbarWcl.SaveSettings;'),
              'procedure TLinkbarWcl.LoadPinned;\nbegin\n  FPinned.Load(WorkDir);\nend;\n\n'
              '{ Length taken by the pinned items when the bar is collapsed }\n'
              'function TLinkbarWcl.PinnedLength(const AVertical: Boolean): Integer;\nbegin\n  Result := FPinned.CollapsedLength;\nend;\n\n')

# DrawPinnedMark se mueve
a = s.index('{ Small dot in the corner of the icons that stay visible when the bar is collapsed }')
b = s.index('end;\n', s.index('GPFillRoundRect(gp, brush, Bounds(ARect.Right - d - 2', a)) + len('end;\n')
s = s[:a] + s[b:].lstrip('\n')

# acciones y fijados
NEW_ACTIONS = """procedure TLinkbarWcl.imNewActionClick(Sender: TObject);
begin
  FActionEditor.Add;
end;

procedure TLinkbarWcl.imEditActionClick(Sender: TObject);
begin
  if IsItemIndex(FItemPopup) and (Items[FItemPopup] is TItemAction)
  then FActionEditor.Modify(TItemAction(Items[FItemPopup]));
end;

procedure TLinkbarWcl.imDeleteActionClick(Sender: TObject);
begin
  if IsItemIndex(FItemPopup) and (Items[FItemPopup] is TItemAction)
  then FActionEditor.Remove(TItemAction(Items[FItemPopup]));
end;

procedure TLinkbarWcl.imPinnedClick(Sender: TObject);
begin
  if IsItemIndex(FItemPopup)
  then FPinned.Toggle(Items[FItemPopup]);
end;

{ After changing the pinned flags: pinned items go to the end, save and re-layout }
procedure TLinkbarWcl.ApplyPinned;
begin
  Items.PinnedToEnd;
  SaveLinks;
  UpdateWindowSize;
end;

procedure TLinkbarWcl.imPinAllActionsClick(Sender: TObject);
begin
  FPinned.PinAllActions;
end;

procedure TLinkbarWcl.imUnpinAllClick(Sender: TObject);
begin
  FPinned.UnpinAll;
end;

procedure TLinkbarWcl.BarPinnedChanged;
begin
  ApplyPinned;
end;

function TLinkbarWcl.BarDockPad: Integer;
begin
  Result := DockPad;
end;

procedure TLinkbarWcl.BarRescanSoon;
begin
  tmrUpdate.Enabled := False;
  tmrUpdate.Enabled := True;
end;

function TLinkbarWcl.BarItems: TLBItemList;
begin
  Result := Items;
end;

"""
s = s.replace(seg(s, 'procedure TLinkbarWcl.imNewActionClick(Sender: TObject);', '{ ---------- profiles ---------- }'), NEW_ACTIONS)

s = rep(s, 'IThumbsHost, ILauncherHost)', 'IThumbsHost, ILauncherHost, IPinnedHost, IActionButtonsHost)')
s = rep(s, '    procedure DrawPinnedMark(const ABitmap: THBitmap; const AItem: TItemBase; const ARect: TRect);\n', '')
s = rep(s, '    FLauncher: TLauncherMode;    // "taskbar icon" mode\n',
        '    FLauncher: TLauncherMode;    // "taskbar icon" mode\n'
        '    FPinned: TPinnedItems;       // items kept visible when collapsed\n'
        '    FActionEditor: TActionButtonEditor;  // new / edit / delete action buttons\n')
s = rep(s, '    procedure BarActivate(const AWnd: HWND);\n',
        '    procedure BarActivate(const AWnd: HWND);\n'
        '    // IPinnedHost / IActionButtonsHost / common services\n'
        '    procedure BarPinnedChanged;\n'
        '    function BarDockPad: Integer;\n'
        '    procedure BarRescanSoon;\n'
        '    function BarItems: TLBItemList;\n')
s = rep(s, 'DrawPinnedMark(', 'FPinned.DrawMark(', 0)

s = rep(s, '  FLauncher := TLauncherMode.Create(Self);\n',
        '  FLauncher := TLauncherMode.Create(Self);\n  FPinned := TPinnedItems.Create(Self);\n  FActionEditor := TActionButtonEditor.Create(Self);\n')
s = rep(s, '  FreeAndNil(FLauncher);\n', '  FreeAndNil(FActionEditor);\n  FreeAndNil(FPinned);\n  FreeAndNil(FLauncher);\n')
s = rep(s, 'Linkbar.Bar.Running, Linkbar.Bar.Launcher;', 'Linkbar.Bar.Running, Linkbar.Bar.Launcher,\n  Linkbar.Bar.Pinned, Linkbar.Bar.ActionButtons;')
wr(p, s)

d = rd('Linkbar.dproj')
k = '        <DCCReference Include="Linkbar.Bar.Launcher.pas"/>'
d = rep(d, k, k + '\n        <DCCReference Include="Linkbar.Bar.Pinned.pas"/>\n        <DCCReference Include="Linkbar.Bar.ActionButtons.pas"/>')
wr('Linkbar.dproj', d)
