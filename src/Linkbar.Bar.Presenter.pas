{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   Presenter of the bar: puts the bitmap of the bar    }
{   on the layered window (shown, hidden strip with or  }
{   without transparency, corner gaps)                  }
{*******************************************************}

unit Linkbar.Bar.Presenter;

{$i linkbar.inc}

interface

uses
  Types,
  Linkbar.Bar.Host, Linkbar.Bar.Collapse, Linkbar.Bar.AutoHide;

type
  TBarPresenter = class
  private
    FHost: ILinkbarHost;
    FCollapse: TBarCollapse;
    FAutoHider: TBarAutoHide;
  public
    constructor Create(const AHost: ILinkbarHost; const ACollapse: TBarCollapse; const AAutoHider: TBarAutoHide);
    // Updates the layered window with the bitmap of the bar for the given bounds
    procedure Present(const ABounds: TRect);
  end;

implementation

uses
  Winapi.Windows, GdiPlus, Linkbar.Graphics, Linkbar.Consts;

const
  bf: TBlendFunction = (BlendOp: AC_SRC_OVER; BlendFlags: 0;
      SourceConstantAlpha: $FF; AlphaFormat: AC_SRC_ALPHA);

constructor TBarPresenter.Create(const AHost: ILinkbarHost; const ACollapse: TBarCollapse; const AAutoHider: TBarAutoHide);
begin
  inherited Create;
  FHost := AHost;
  FCollapse := ACollapse;
  FAutoHider := AAutoHider;
end;

procedure TBarPresenter.Present(const ABounds: TRect);
var w, h, c1gw, c2gw, wh: Integer;
    Pt1, Pt2: TPoint;
    Sz: TSize;
    drawer: IGPGraphics;
    r: TGPRect;
    bmp: THBitmap;
    dc: HDC;
    p: Pointer;
begin
  if FCollapse.Animating  // the animation draws its own frames
  then Exit;

  w := ABounds.Width;
  h := ABounds.Height;

  // Draw
  if (FAutoHider.Hidden)
  then begin
    // Hidden

    // Check corner gaps width
    c1gw := FHost.BarCorner1Gap;
    c2gw := FHost.BarCorner2Gap;
    if (c1gw > 0) or (c2gw > 0)
    then begin
      if FHost.BarAlign in [EPanelAlignLeft, EPanelAlignRight]
      then wh := h
      else wh := w;
      if (c1gw > wh - c2gw)
      then begin
        c1gw := 0;
        c2gw := 0;
      end;
    end;

    if (FHost.BarAutoHideTransparency)
    then begin
      // and Transparency
      Pt1 := ABounds.TopLeft;
      Sz := TSize.Create(w, h);
      Pt2 := Point(0,0);

      bmp := THBitmap.Create(32);
      bmp.SetSize(w, h);
      dc := bmp.Dc;

      drawer := TGPGraphics.FromHDC(dc);
      if (c1gw > 0) or (c2gw > 0)
      then begin
        if FHost.BarAlign in [EPanelAlignLeft, EPanelAlignRight]
        then r := TGPRect.Create(0, c1gw, w, h - c1gw - c2gw)
        else r := TGPRect.Create(c1gw, 0, w - c1gw - c2gw, h);
        drawer.SetClip(r);
      end;
      drawer.Clear($01000000);

      UpdateLayeredWindow(FHost.BarHandle, 0, @Pt1, @Sz, dc, @Pt2, 0, @bf, ULW_ALPHA);
      bmp.Free;
    end
    else begin
      // and Opaque
      if (c1gw > 0) or (c2gw > 0)
      then begin
        // w/ gaps
        Pt1 := ABounds.TopLeft;
        Sz := TSize.Create(w, h);
        case FHost.BarAlign of
          EPanelAlignLeft:   Pt2 := Point(FHost.BarPanelBitmap.Width - w, 0);
          EPanelAlignTop:    Pt2 := Point(0, FHost.BarPanelBitmap.Height - h);
          EPanelAlignRight:  Pt2 := Point(0, 0);
          EPanelAlignBottom: Pt2 := Point(0, 0);
        end;

        bmp := THBitmap.Create(32);
        bmp.SetSize(w, h);
        dc := bmp.Dc;

        if FHost.BarAlign in [EPanelAlignLeft, EPanelAlignRight]
        then BitBlt(dc, 0, c1gw, w, h - c1gw - c2gw, FHost.BarPanelBitmap.Dc, Pt2.X, c1gw, SRCCOPY)
        else BitBlt(dc, c1gw, 0, w - c1gw - c2gw, h, FHost.BarPanelBitmap.Dc, c1gw, Pt2.Y, SRCCOPY);

        Pt2 := Point(0,0);
        UpdateLayeredWindow(FHost.BarHandle, 0, @Pt1, @Sz, dc, @Pt2, 0, @bf, ULW_ALPHA);
        bmp.Free;
      end
      else begin
        // w/o gaps
        Pt1 := ABounds.TopLeft;
        Sz := TSize.Create(w, h);
        case FHost.BarAlign of
          EPanelAlignLeft:   Pt2 := Point(FHost.BarPanelBitmap.Width - w, 0);
          EPanelAlignTop:    Pt2 := Point(0, FHost.BarPanelBitmap.Height - h);
          EPanelAlignRight:  Pt2 := Point(0, 0);
          EPanelAlignBottom: Pt2 := Point(0, 0);
        end;
        UpdateLayeredWindow(FHost.BarHandle, 0, @Pt1, @Sz, FHost.BarPanelBitmap.Dc, @Pt2, 0, @bf, ULW_ALPHA);
      end;
    end;
  end
  else begin
    // Not Hidden
    if (ABounds = FHost.BarBounds)
    then p := nil
    else p := @ABounds.TopLeft;
    Sz := TSize.Create(w, h);
    case FHost.BarAlign of
      EPanelAlignLeft:   Pt2 := Point(FHost.BarPanelBitmap.Width - w, 0);
      EPanelAlignTop:    Pt2 := Point(0, FHost.BarPanelBitmap.Height - h);
      EPanelAlignRight:  Pt2 := Point(0, 0);
      EPanelAlignBottom: Pt2 := Point(0, 0);
    end;

    UpdateLayeredWindow(FHost.BarHandle, 0, p, @Sz, FHost.BarPanelBitmap.Dc, @Pt2, 0, @bf, ULW_ALPHA);
  end;
end;

end.
