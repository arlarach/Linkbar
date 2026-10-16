{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   Auto hide: the bar shrinks to a thin strip on the   }
{   screen edge and shows again with the mouse (or a    }
{   click / the hotkey)                                 }
{*******************************************************}

unit Linkbar.Bar.AutoHide;

{$i linkbar.inc}

interface

uses
  Windows, Types,
  Linkbar.Bar.Host;

const
  TIMER_AUTO_SHOW = 15;
  TIMER_AUTO_HIDE = 16;

type
  // What the auto hide needs from the bar window
  IAutoHideHost = interface(ILinkbarHost)
    ['{4C9E2A71-F3B8-4D05-96A2-1E7D5B0C8F34}']
    function BarAutoHideEnabled: Boolean;
    function BarAutoShowDelay: Integer;
    // No item is hot (the bar is hidden)
    procedure BarClearHot;
    // Draws the bar window in the given bounds
    procedure BarPresent(const ABounds: TRect);
    // The context menu is only available while the bar is shown
    procedure BarEnableContextMenu(const AEnabled: Boolean);
  end;

  TBarAutoHide = class
  private
    FHost: IAutoHideHost;
    FHidden: Boolean;
    FCanHide: Boolean;            // the mouse left the bar: it may hide
    FLocked: Boolean;             // a menu or dialog is open: do not hide
    FBeforeBound: TRect;          // bounds of the shown bar
    FAfterBound: TRect;           // bounds of the hidden strip
  public
    constructor Create(const AHost: IAutoHideHost);
    procedure Hide;
    procedure Show;
    procedure DelayedHide(const ADelay: Cardinal);
    procedure DelayedShow;
    property Hidden: Boolean read FHidden write FHidden;
    property CanAutoHide: Boolean read FCanHide write FCanHide;
    property Locked: Boolean read FLocked write FLocked;
    property BeforeBound: TRect read FBeforeBound write FBeforeBound;
    property AfterBound: TRect read FAfterBound write FAfterBound;
  end;

implementation

uses
  Linkbar.Consts;

// The coordinates of GetMessagePos are signed 16-bit values packed in a DWORD
function MessageCursorPos: TPoint;
var L: DWORD;
begin
  L := GetMessagePos;
  Result := TPoint.Create(SmallInt(L and $FFFF), SmallInt(L shr 16));
end;

constructor TBarAutoHide.Create(const AHost: IAutoHideHost);
begin
  inherited Create;
  FHost := AHost;
end;

procedure TBarAutoHide.Hide;
var r: TRect;
begin
  if (not FHost.BarAutoHideEnabled)
     or FLocked
     or ( WindowFromPoint(MessageCursorPos) = FHost.BarHandle )
  then Exit;

  if FCanHide and not FHidden
  then begin
    FHidden := True;
    FHost.BarClearHot;
    r := FBeforeBound;
    case FHost.BarAlign of
      EPanelAlignTop: r.Bottom := r.Top + FHost.ScaleValue(AUTOHIDE_SIZE);
      EPanelAlignLeft: r.Right := r.Left + FHost.ScaleValue(AUTOHIDE_SIZE);
      EPanelAlignRight: r.Left := r.Right - FHost.ScaleValue(AUTOHIDE_SIZE);
      EPanelAlignBottom: r.Top := r.Bottom - FHost.ScaleValue(AUTOHIDE_SIZE);
    end;
    FAfterBound := r;
    MoveWindow(FHost.BarHandle, r.Left, r.Top, r.Width, r.Height, False);
    FHost.BarPresent(FAfterBound);
    FHost.BarEnableContextMenu(False);
  end;
end;

procedure TBarAutoHide.Show;
var pt: TPoint;
begin
  pt := MessageCursorPos;
  if FHost.BarAutoHideEnabled
     and FHidden
     and ((not FCanHide) or (WindowFromPoint(pt) = FHost.BarHandle))
  then begin
    FHidden := False;
    MoveWindow(FHost.BarHandle, FBeforeBound.Left, FBeforeBound.Top,
      FBeforeBound.Width, FBeforeBound.Height, False);
    FHost.BarPresent(FBeforeBound);
    FHost.BarEnableContextMenu(True);
  end;
end;

procedure TBarAutoHide.DelayedHide(const ADelay: Cardinal);
begin
  if (not FHost.BarAutoHideEnabled)
  then Exit;

  if (ADelay = 0)
  then Hide
  else FHost.BarStartTimer(TIMER_AUTO_HIDE, ADelay);
end;

procedure TBarAutoHide.DelayedShow;
begin
  if (not FHost.BarAutoHideEnabled)
  then Exit;

  if (FHost.BarAutoShowDelay = 0)
  then Show
  else FHost.BarStartTimer(TIMER_AUTO_SHOW, FHost.BarAutoShowDelay);
end;

end.
