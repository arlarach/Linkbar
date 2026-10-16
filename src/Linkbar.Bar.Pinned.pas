{*******************************************************}
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
