{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   Links of the bar: builds the list of items from the }
{   links folder and follows the changes of the folder  }
{*******************************************************}

unit Linkbar.Bar.LinkList;

{$i linkbar.inc}

interface

uses
  Cromis.DirectoryWatch, LBToolbar,
  Linkbar.Bar.Host, Linkbar.Bar.Pinned, Linkbar.Bar.Zoom;

type
  // What the link list needs from the bar window
  ILinkListHost = interface(ILinkbarHost)
    ['{8B3D5F20-6A91-4E47-B2C8-0D4F7A1E9563}']
    // The list of items, created when it does not exist yet
    function BarEnsureItems: TLBItemList;
    function BarSortAlphabetically: Boolean;
    // Item (or gap) that receives a drop; ITEM_NONE when there is none
    function BarDropPosition: Integer;
    // Removes an item (and forgets it as hot / pressed)
    procedure BarDeleteItem(const AIndex: Integer);
    // The folder timer waits a moment so a burst of changes is processed once
    procedure BarRescanTimer(const AEnabled: Boolean);
    procedure BarClearDropPosition;
    // The items changed: lay the bar out again
    procedure BarLinksChanged;
  end;

  TLinkList = class
  private
    FHost: ILinkListHost;
    FPinned: TPinnedItems;
    FZoom: TBarZoom;
    FLastModifiedHash: Cardinal;
    FRenamedOldHash: Cardinal;
  public
    constructor Create(const AHost: ILinkListHost; const APinned: TPinnedItems; const AZoom: TBarZoom);
    // Builds the items from the links folder, in the order of the list file
    procedure Load(const AFileName: string);
    // A file of the links folder was added, removed, modified or renamed
    procedure FolderChanged(const AAction: TWatchAction; const AFileName: string);
    // Timer: loads the items that changed and lays the bar out
    procedure RescanTick;
  end;

implementation

uses
  SysUtils, Classes, StrUtils, System.IOUtils, Linkbar.Consts; // TEMP-LOG (System.IOUtils)

// TEMP-LOG: diagnostico del renombrado desde la carpeta (se retira despues)
procedure TempLog(const AText: string);
begin
  try
    TFile.AppendAllText('E:\Linkbar\src\IA\TMP\dirwatch.log',
      FormatDateTime('hh:nn:ss.zzz', Now) + ' ' + AText + sLineBreak, TEncoding.UTF8);
  except
  end;
end;

constructor TLinkList.Create(const AHost: ILinkListHost; const APinned: TPinnedItems; const AZoom: TBarZoom);
begin
  inherited Create;
  FHost := AHost;
  FPinned := APinned;
  FZoom := AZoom;
end;

procedure TLinkList.Load(const AFileName: string);
var list: TStringList;
    templist: TStringList;
    sr: TSearchRec;
    i, j : integer;
    ext: string;
    items: TLBItemList;
    workDir: string;
begin
  items := FHost.BarEnsureItems;
  workDir := FHost.BarWorkDir;
  items.Clear;

  // Load last ordered items list
  list := TStringList.Create;
  if FileExists(AFileName)
  then list.LoadFromFile(AFileName, TEncoding.UTF8);

  templist := TStringList.Create;
  templist.CaseSensitive := False;
  templist.Sorted := False;

  // Find supperted files (and groups) in working directory
  for ext in ES_ITEMS_ARRAY do
  begin
    if ( FindFirst( workDir + '*' + ext, faAnyFile, sr) = 0 )
    then repeat
      templist.Add(sr.Name);
    until (FindNext(sr) <> 0);
    FindClose(sr);
  end;

  templist.Sort;

  // Ordering founded items
  i := 0;
  while i < list.Count do
  begin
    if TItemSeparator.IsSeparator(list[i])
    then begin
      Inc(i);
    end
    else if templist.Find(list[i], j)
    then begin
      templist.Delete(j);
      Inc(i);
    end
    else list.Delete(i);
  end;

  // New item move to end
  if (templist.Count > 0)
  then list.AddStrings(templist);
  templist.Free;

  // Create linkbar items
  items.Capacity := list.Count;
  for var fileName in list do
  begin
    if TItemSeparator.IsSeparator(fileName)
    then begin
      items.Add(TItemSeparator.Create);
    end
    else begin
      var item := CreateItemForFile(fileName);
      if item.LoadFromFile(workDir + fileName)
      then items.Add(item)
      else item.Free;
    end;
  end;
  list.Free;

  FPinned.Load(workDir);

  if FHost.BarSortAlphabetically
  then items.Sort;
  items.PinnedToEnd;

  items.IconSize := FHost.BarIconSize;
  items.ZoomIconSize := FZoom.IconSizeValue;
end;

procedure TLinkList.FolderChanged(const AAction: TWatchAction; const AFileName: string);

  function FindItemByHash(AHash: Cardinal): Integer;
  begin
    for var i := 0 to FHost.BarItems.Count-1
    do if FHost.BarItems[i].Hash = AHash
       then Exit(i);
    Result := ITEM_NONE;
  end;

var ext: string;
    hash: Cardinal;
    index: integer;
begin
  TempLog('event ' + IntToStr(Ord(AAction)) + ' "' + AFileName + '" hash=' + IntToHex(StrToHash(AFileName), 8)); // TEMP-LOG
  // Skip unsupported files
  ext := ExtractFileExt(AFileName);
  if not MatchText(ext, ES_ITEMS_ARRAY) then Exit;

  FHost.BarRescanTimer(False);

  case AAction of
  waAdded:
  begin
    var item := CreateItemForFile(AFileName);
    item.Hash := StrToHash(AFileName);
    item.FileName := FHost.BarWorkDir + AFileName;
    item.NeedLoad := True;
    if (FHost.BarDropPosition = ITEM_NONE)
    then FHost.BarItems.Add(item)
    else FHost.BarItems.Insert(FHost.BarDropPosition, item);
  end;
  waRemoved:
  begin
    index := FindItemByHash(StrToHash(AFileName));
    TempLog('  removed: found=' + IntToStr(index)); // TEMP-LOG
    if (index <> ITEM_NONE)
    then FHost.BarDeleteItem(index);
  end;
  waModified:
  begin
    hash := StrToHash(AFileName);
    if (FLastModifiedHash <> hash)
    then begin
      FLastModifiedHash := hash;
      index := FindItemByHash(hash);
      if (index <> ITEM_NONE)
      then FHost.BarItems[index].NeedLoad := True;
    end;
  end;
  waRenamedOld:
  begin
    FRenamedOldHash := StrToHash(AFileName);
  end;
  waRenamedNew:
  begin
    index := FindItemByHash(FRenamedOldHash);
    TempLog('  renamedNew: oldHash=' + IntToHex(FRenamedOldHash, 8) + ' found=' + IntToStr(index)); // TEMP-LOG
    if (index <> ITEM_NONE)
    then begin
      var item := FHost.BarItems[index];
      item.FileName := FHost.BarWorkDir + AFileName;
      item.NeedLoad := True;
      FRenamedOldHash := 0;
    end;
  end;
  end;

  FHost.BarRescanTimer(True);
end;

procedure TLinkList.RescanTick;
begin
  FHost.BarRescanTimer(False);
  TempLog('tick'); // TEMP-LOG

  for var i := FHost.BarItems.Count-1 downto 0 do
  begin
    const item = FHost.BarItems[i];
    if item.NeedLoad
    then begin
      TempLog('  reload ' + item.FileName + ' (caption was ' + item.Caption + ')'); // TEMP-LOG
      if item.LoadFromFile(item.FileName)
      then FHost.BarItems.LoadIcon(item)
      else FHost.BarDeleteItem(i);
    end
  end;

  if FHost.BarSortAlphabetically
  then FHost.BarItems.Sort;
  FHost.BarItems.PinnedToEnd;

  FLastModifiedHash := 0;
  FRenamedOldHash := 0;

  FHost.BarClearDropPosition;
  // Lays the bar out again (and, in taskbar icon mode, refreshes the automatic icon)
  FHost.BarLinksChanged;
end;

end.
