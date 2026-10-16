{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   Drop target of the bar: the indicator that shows    }
{   where an icon or a file will be dropped             }
{*******************************************************}

unit Linkbar.Bar.DropTarget;

{$i linkbar.inc}

interface

uses
  Winapi.Windows, Winapi.ShlObj, Types,
  Linkbar.Graphics, Linkbar.Bar.Host;

type
  // What the drop indicator needs from the bar window
  IDropTargetHost = interface(ILinkbarHost)
    ['{D2A85F16-6E3B-49C7-A1D4-8B0E5C7F3926}']
    // Index of the item under the point (ITEM_NONE when there is none)
    function BarItemAt(const APt: TPoint): Integer;
    // An item of the bar is being dragged inside the bar
    function BarDraggingItem: Boolean;
    function BarDragIndex: Integer;
    function BarWorkDirPidl: PItemIDList;
    // Draws the hover look (background, hover and item) of the item that receives the drop
    procedure BarPaintDropHighlight(const AIndex: Integer; const ARect: TRect);
    procedure BarRefresh;
  end;

  TBarDropTarget = class
  private
    FHost: IDropTargetHost;
    FBitmap: THBitmap;            // what was under the indicator (to restore it)
    FPosition: Integer;           // item (or gap) that receives the drop
    FPart: Integer;               // -1 before the item, 0 on it, 1 after it
    FLastRect: TRect;
    FPidl: PItemIDList;           // target of the shell drop
    function IndicatorRect(const AIndex, APart: Integer): TRect;
  public
    constructor Create(const AHost: IDropTargetHost);
    destructor Destroy; override;
    procedure SetSize(const AWidth, AHeight: Integer);
    // Moves the indicator to the item (or gap) under the point; (-1, -1) clears it
    procedure Update(const APoint: TPoint);
    // Image of an icon dragged out of a group (nil when it cannot be created)
    class function CreateExternalImage(const AIcon: HBITMAP; const ASize: Integer): THBitmap; static;
    property Position: Integer read FPosition write FPosition;
    property Part: Integer read FPart;
    property Pidl: PItemIDList read FPidl;
  end;

implementation

uses
  GdiPlus, LBToolbar, Linkbar.Consts;

constructor TBarDropTarget.Create(const AHost: IDropTargetHost);
begin
  inherited Create;
  FHost := AHost;
  FBitmap := THBitmap.Create(32);
  FPosition := ITEM_NONE;
end;

destructor TBarDropTarget.Destroy;
begin
  FBitmap.Free;
  inherited;
end;

procedure TBarDropTarget.SetSize(const AWidth, AHeight: Integer);
begin
  FBitmap.SetSize(AWidth, AHeight);
end;

function TBarDropTarget.IndicatorRect(const AIndex, APart: Integer): TRect;
var r: TRect;
begin
  r := FHost.BarItems[AIndex].Rect;

  case APart of
    -1: begin
      if FHost.BarIsVertical
      then begin
        r.Top := r.Top - DROP_INDICATOR_SIZE div 2;
        r.Left := r.Left + r.Width div DROP_INDICATOR_PADDING_DIV;
        r.Right := r.Right - r.Width div DROP_INDICATOR_PADDING_DIV;
        r.Height := DROP_INDICATOR_SIZE;
      end
      else begin
        r.Left := r.Left - DROP_INDICATOR_SIZE div 2;
        r.Top := r.Top + r.Height div DROP_INDICATOR_PADDING_DIV;
        r.Bottom := r.Bottom - r.Height div DROP_INDICATOR_PADDING_DIV;
        r.Width := DROP_INDICATOR_SIZE;
      end;
    end;
    1: begin
      if FHost.BarIsVertical
      then begin
        r.Top := r.Bottom - DROP_INDICATOR_SIZE div 2;
        r.Left := r.Left + r.Width div DROP_INDICATOR_PADDING_DIV;
        r.Right := r.Right - r.Width div DROP_INDICATOR_PADDING_DIV;
        r.Height := DROP_INDICATOR_SIZE;
      end
      else begin
        r.Left := r.Right - DROP_INDICATOR_SIZE div 2;
        r.Top := r.Top + r.Height div DROP_INDICATOR_PADDING_DIV;
        r.Bottom := r.Bottom - r.Height div DROP_INDICATOR_PADDING_DIV;
        r.Width := DROP_INDICATOR_SIZE;
      end;
    end;
  end;

  Result := r;
end;

procedure TBarDropTarget.Update(const APoint: TPoint);

var
  r: TRect;
  index: Integer;
  part: Integer;
begin
  index := FHost.BarItemAt(APoint);

  if (index = ITEM_NONE)
  then part := -1
  else begin
    var bSideOnly: Boolean := FHost.BarDraggingItem;
    if bSideOnly and (FHost.BarItems[index] is TItemGroup) then
      bSideOnly := False;
      
    part := FHost.BarItems[index].GetDropPart(APoint, FHost.BarIsVertical, bSideOnly);

    if (part = 1) and (index <> FHost.BarDragIndex)
    then begin
      index := index + 1;
      part := -1;
    end;

    if index > (FHost.BarItems.Count-1)
    then index := ITEM_NONE;
  end;

  if (index = ITEM_NONE) or (part <> 0)
  then FPidl := FHost.BarWorkDirPidl
  else FPidl := FHost.BarItems[index].Pidl;

  if (index = FPosition) and (part = FPart) then Exit;
  FPart := part;

  if (FPosition <> ITEM_NONE) then
  begin
    r := FLastRect;
    BitBlt(FHost.BarPanelBitmap.Dc, r.Left, r.Top, r.Width, r.Height, FBitmap.Dc, 0, 0, SRCCOPY);
  end;

  FPosition := index;

  if (FPosition <> ITEM_NONE) then
  begin
    r := IndicatorRect(FPosition, part);
    FLastRect := r;

    BitBlt(FBitmap.Dc, 0, 0, r.Width, r.Height, FHost.BarPanelBitmap.Dc, r.Left, r.Top, SRCCOPY);

    if (part = 0)
    then begin
      FHost.BarPaintDropHighlight(FPosition, r);
    end
    else begin
      var gpDrawer: IGPGraphics := TGpGraphics.Create(FHost.BarPanelBitmap.Dc);
      var gpBrush: IGPSolidBrush := TGPSolidBrush.Create(TGPColor.Create($ff000000));
      gpDrawer.FillRectangle(gpBrush, TGPRect.Create(r));
      gpBrush.Color := TGPColor.Create($ffffffff);
      r.Inflate(-1,-1,-1,-1);
      gpDrawer.FillRectangle(gpBrush, TGPRect.Create(r));
    end;
  end;

  FHost.BarRefresh;
end;

class function TBarDropTarget.CreateExternalImage(const AIcon: HBITMAP; const ASize: Integer): THBitmap;
var
  srcDc: HDC;
  old: HGDIOBJ;
  bm: Winapi.Windows.TBitmap;
  blend: TBlendFunction;
begin
  Result := nil;
  if (AIcon = 0) or (ASize <= 0) or (GetObject(AIcon, SizeOf(bm), @bm) = 0)
  then Exit;

  Result := THBitmap.Create(32);
  Result.SetSize(ASize, ASize);
  blend.BlendOp := AC_SRC_OVER;
  blend.BlendFlags := 0;
  blend.SourceConstantAlpha := 255;
  blend.AlphaFormat := AC_SRC_ALPHA;
  srcDc := CreateCompatibleDC(0);
  old := SelectObject(srcDc, AIcon);
  Winapi.Windows.AlphaBlend(Result.Dc, 0, 0, ASize, ASize,
    srcDc, 0, 0, bm.bmWidth, Abs(bm.bmHeight), blend);
  SelectObject(srcDc, old);
  DeleteDC(srcDc);
end;

end.
