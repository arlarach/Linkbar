{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   Metrics of the items: button size, icon offset and  }
{   text rectangle for the layout of icon and caption   }
{*******************************************************}

unit Linkbar.Bar.Metrics;

{$i linkbar.inc}

interface

uses
  Types, Linkbar.Consts, Linkbar.Bar.Config;

type
  TItemMetrics = class
  public
    // Calculates the size of a button and where its icon and caption go
    class procedure Calc(const AConfig: TBarConfig; const ATextHeight: Integer;
      out AButtonSize: TSize; var AIconOffset: TPoint; var ATextRect: TRect); static;
  end;

implementation

uses
  Math;

class procedure TItemMetrics.Calc(const AConfig: TBarConfig; const ATextHeight: Integer;
  out AButtonSize: TSize; var AIconOffset: TPoint; var ATextRect: TRect);
var
  w, h: Integer;
  textHeight: Integer;
begin
  textHeight := ATextHeight;

  // Calc margin, icon offset & button size
  case AConfig.TextLayout of
  ETextLayoutLeft, ETextLayoutRight:
    begin
      // button size
      w := AConfig.ItemMargin.cx + AConfig.IconSize + AConfig.TextOffset + AConfig.TextWidth + AConfig.ItemMargin.cx;
      h := AConfig.ItemMargin.cy + Max(AConfig.IconSize, textHeight) + AConfig.ItemMargin.cy;
      // icon offset
      if (AConfig.TextLayout = ETextLayoutRight)
      then AIconOffset.X := AConfig.ItemMargin.cx
      else AIconOffset.X := AConfig.ItemMargin.cx + AConfig.TextWidth + AConfig.TextOffset;
      AIconOffset.Y := (h - AConfig.IconSize) div 2;
      // text rect
      if (AConfig.TextLayout = ETextLayoutRight)
      then ATextRect := Bounds( AConfig.ItemMargin.cx + AConfig.IconSize + AConfig.TextOffset, (h - textHeight) div 2, AConfig.TextWidth, textHeight )
      else ATextRect := Bounds( AConfig.ItemMargin.cx, (h - textHeight) div 2, AConfig.TextWidth, textHeight );
    end;
  ETextLayoutTop, ETextLayoutBottom:
    begin
      // button size
      w := AConfig.ItemMargin.cx + Max(AConfig.IconSize, AConfig.TextWidth) + AConfig.ItemMargin.cx;
      h := AConfig.ItemMargin.cy + AConfig.IconSize + AConfig.TextOffset + textHeight + AConfig.ItemMargin.cy;
      // icon offset
      AIconOffset.X := (w - AConfig.IconSize) div 2;
      if (AConfig.TextLayout = ETextLayoutBottom)
      then AIconOffset.Y := AConfig.ItemMargin.cy
      else AIconOffset.Y := AConfig.ItemMargin.cy + textHeight + AConfig.TextOffset;
      // text rect
      if (AConfig.TextLayout = ETextLayoutBottom)
      then ATextRect := Bounds( AConfig.TextOffset, AConfig.ItemMargin.cy + AConfig.IconSize + AConfig.TextOffset, w - 2*AConfig.TextOffset, textHeight )
      else ATextRect := Bounds( AConfig.TextOffset, AConfig.ItemMargin.cy, w - 2*AConfig.TextOffset, textHeight );
    end;
  else
    begin
      w := AConfig.ItemMargin.cx + AConfig.IconSize + AConfig.ItemMargin.cx;
      h := AConfig.ItemMargin.cy + AConfig.IconSize + AConfig.ItemMargin.cy;
      AIconOffset := Point(AConfig.ItemMargin.cx, AConfig.ItemMargin.cy);
    end;
  end;

  AButtonSize := TSize.Create(w, h);
end;

end.
