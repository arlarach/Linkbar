{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   "Program is open" indicator: marks the items whose  }
{   program runs and draws the small pill under them    }
{*******************************************************}

unit Linkbar.Bar.Running;

{$i linkbar.inc}

interface

uses
  Types,
  GdiPlus,
  LBToolbar, Linkbar.Graphics, Linkbar.Bar.Host;

type
  TRunningIndicator = class
  private
    FHost: ILinkbarHost;
  public
    constructor Create(const AHost: ILinkbarHost);
    // Marks the items whose program is open; True when any item changed
    function Refresh(const AItems: TLBItemList): Boolean;
    // Small pill under the icon, like the taskbar
    procedure DrawMark(const ABitmap: THBitmap; const AItem: TItemBase; const ARect: TRect);
  end;

implementation

uses
  Classes, Math, Linkbar.Consts, Linkbar.Theme;

constructor TRunningIndicator.Create(const AHost: ILinkbarHost);
begin
  inherited Create;
  FHost := AHost;
end;

function TRunningIndicator.Refresh(const AItems: TLBItemList): Boolean;
var
  paths: TStringList;
  running: Boolean;
  idx: Integer;
begin
  Result := False;
  paths := TStringList.Create;
  try
    CollectRunningExePaths(paths);

    for var item in AItems do
    begin
      running := (item.TargetPath <> '') and paths.Find(item.TargetPath, idx);
      // Group: open if any of its programs is open
      if (not running) and (item is TItemGroup)
      then begin
        for var t in TItemGroup(item).MemberTargets do
          if (t <> '') and paths.Find(t, idx)
          then begin
            running := True;
            Break;
          end;
      end;
      if (running <> item.Running)
      then begin
        item.Running := running;
        Result := True;
      end;
    end;
  finally
    paths.Free;
  end;
end;

procedure TRunningIndicator.DrawMark(const ABitmap: THBitmap; const AItem: TItemBase; const ARect: TRect);
var
  gp: IGPGraphics;
  brush: IGPBrush;
  r: TRect;
  w, h: Integer;
  color: Cardinal;
begin
  if not AItem.Running
  then Exit;

  w := Max(FHost.ScaleValue(16), (FHost.BarIconSize * 2) div 3); // about 2/3 of the icon width
  h := Max(3, FHost.ScaleValue(3));
  case FHost.BarAlign of
    EPanelAlignLeft:   r := Bounds(ARect.Left + 1, ARect.Top + (ARect.Height - w) div 2, h, w);
    EPanelAlignRight:  r := Bounds(ARect.Right - h - 1, ARect.Top + (ARect.Height - w) div 2, h, w);
    else // top/bottom bar: under the icon
      r := Bounds(ARect.Left + (ARect.Width - w) div 2, ARect.Bottom - h - 1, w, h);
  end;

  color := SwapRedBlue(GetImmersiveColorFromName('ImmersiveSystemAccentLight2'));
  if ((color shr 24) = 0)
  then color := color or $FF000000;

  gp := TGPGraphics.Create(ABitmap.Dc);
  brush := TGPSolidBrush.Create(color);
  GPFillRoundRect(gp, brush, r, h div 2);
end;

end.
