{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   Painter of the bar: background, captions and icons  }
{   of the items (drawn on the bitmap of the bar)       }
{*******************************************************}

unit Linkbar.Bar.Painter;

{$i linkbar.inc}

interface

uses
  Types,
  Linkbar.Graphics, Linkbar.Bar.Host, Linkbar.Bar.Dock, Linkbar.Bar.Zoom;

type
  TBarPainter = class
  private
    FHost: ILinkbarHost;
    FDock: TBarDock;
    FZoom: TBarZoom;
  public
    constructor Create(const AHost: ILinkbarHost; const ADock: TBarDock; const AZoom: TBarZoom);
    procedure DrawBackground(const ABitmap: THBitmap; const AClipRect: TRect);
    procedure DrawCaption(const ABitmap: THBitmap; const AIndex: Integer;
      const ADrawForDrag: Boolean = False);
    procedure DrawItem(ABitmap: THBitmap; AIndex: Integer; ASelected,
      APressed: Boolean; ADrawBg: Boolean = True; ADrawForDrag: Boolean = False);
    // Lays out the items and draws captions, separators and icons
    procedure DrawItems(const AWidth, AHeight: Integer);
  end;

implementation

uses
  Winapi.Windows, SysUtils, Math, Vcl.Graphics, Vcl.Forms, Vcl.Themes,
  LBToolbar, Linkbar.Consts, Linkbar.Theme;

const
  bf: TBlendFunction = (BlendOp: AC_SRC_OVER; BlendFlags: 0;
      SourceConstantAlpha: $FF; AlphaFormat: AC_SRC_ALPHA);

constructor TBarPainter.Create(const AHost: ILinkbarHost; const ADock: TBarDock; const AZoom: TBarZoom);
begin
  inherited Create;
  FHost := AHost;
  FDock := ADock;
  FZoom := AZoom;
end;

procedure TBarPainter.DrawBackground(const ABitmap: THBitmap;
  const AClipRect: TRect);
var params: TDrawBackgroundParams;
begin
  // Dock: anti-aliased rounded background painted by Linkbar itself
  if FHost.BarIsDock
  then begin
    FDock.DrawBackground(ABitmap, AClipRect);
    Exit;
  end;

  params.Bitmap := ABitmap;
  params.Align := FHost.BarAlign;
  params.ClipRect := AClipRect;
  params.IsLight := FHost.BarIsLightStyle;
  params.BgColor := FHost.BarBackgroundColor;
  ThemeDrawBackground(@params);
end;

procedure TBarPainter.DrawCaption(const ABitmap: THBitmap; const AIndex: Integer;
  const ADrawForDrag: Boolean = False);
var
  textRect: TRect;
  textColor: TColor;
  dc, dc2: HDC;
  fnt0: HGDIOBJ;
begin
  if (FHost.BarTextLayout = ETextLayoutNone) then Exit;

  const textFlags: Cardinal = TEXTALIGN[FHost.BarTextLayout] or DT_END_ELLIPSIS or DT_SINGLELINE or DT_NOPREFIX or DT_NOCLIP;

  if (StyleServices.Enabled)
  then begin
    // Aero theme. Use DrawGlassText
    if (FHost.BarUseTextColor)
    then begin
      textColor := FHost.BarTextColor;
    end
    else begin
      if (AIndex = ITEM_ALL)
      then begin
        textColor := ThemeButtonNormalTextColor;
      end
      else begin
        if (AIndex = FHost.BarPressedIndex)
        then textColor := ThemeButtonPressedTextColor
        else if (AIndex = FHost.BarHotIndex)
             then textColor := ThemeButtonSelectedTextColor
             else textColor := ThemeButtonNormalTextColor;
      end;
    end;

    dc := ABitmap.Dc;

    if (AIndex = ITEM_ALL)
    then begin
      fnt0 := SelectObject(dc, Screen.IconFont.Handle);
      for var item in FHost.BarItems
      do begin
        if (not FHost.BarItems.IsSeparator(item))
           and (not item.Rect.IsEmpty)
        then begin
          textRect := FHost.BarTextRect;
          textRect.Offset(item.Rect.TopLeft);
          DrawGlassText(dc, item.Caption, textRect, textFlags, FHost.BarGlowSize, textColor);
        end;
      end;
      SelectObject(dc, fnt0);
    end
    else begin
      const item = FHost.BarItems[AIndex];

      if (not FHost.BarItems.IsSeparator(item))
      then begin
        if ADrawForDrag
        then begin
          textRect := FHost.BarTextRect;
          fnt0 := SelectObject(dc, Screen.IconFont.Handle);
          DrawGlassText(dc, item.Caption, textRect, textFlags, FHost.BarGlowSize, textColor);
          SelectObject(dc, fnt0);
        end
        else begin
          // The shadow extends beyond the button, creating artifacts
          // Draw on separate bitmap with button size
          var bmp := THBitmap.Create(32);
          bmp.SetSize(FHost.BarButtonBitmap.Width, FHost.BarButtonBitmap.Height);
          dc2 := bmp.Dc;

          textRect := FHost.BarTextRect;
          if (AIndex = FHost.BarPressedIndex)
          then textRect.Offset(1,1);

          fnt0 := SelectObject(dc2, Screen.IconFont.Handle);
          DrawGlassText(dc2, item.Caption, textRect, textFlags, FHost.BarGlowSize, textColor);
          SelectObject(dc2, fnt0);

          Winapi.Windows.AlphaBlend(dc,
            item.Rect.Left, item.Rect.Top, bmp.Width, bmp.Height,
            dc2, 0, 0, bmp.Width, bmp.Height, bf);

          bmp.Free;
        end;
      end;
    end;
  end
  else begin
    // Classic theme
    // NOTE: DrawThemeText/DrawThemeTextEx not work in Classic theme

    Assert(not ADrawForDrag); // Classic Theme don't have Drag Image

    textColor := clBtnText;

    dc := ABitmap.Dc;
    fnt0 := SelectObject(dc, Screen.IconFont.Handle);
    SetTextColor(dc, ColorToRGB(textColor));
    SetBkColor(dc, ColorToRGB(clBtnFace));

    if (AIndex = ITEM_ALL)
    then begin
      for var item in FHost.BarItems
      do begin
        if (not FHost.BarItems.IsSeparator(item))
           and (not item.Rect.IsEmpty)
        then begin
          textRect := FHost.BarTextRect;
          textRect.Offset(item.Rect.TopLeft);
          DrawText(dc, item.Caption, -1, textRect, textFlags);
        end;
      end;
      ABitmap.Opaque;
    end
    else begin
      const item = FHost.BarItems[AIndex];
      if (not FHost.BarItems.IsSeparator(item))
      then begin
        textRect := FHost.BarTextRect;
        textRect.Offset(item.Rect.TopLeft);
        if (AIndex = FHost.BarPressedIndex)
        then textRect.Offset(1,1);
        DrawText(dc, item.Caption, -1, textRect, textFlags);
        ABitmap.OpaqueRect(item.Rect);
      end;
    end;

    SelectObject(dc, fnt0);
  end;
end;

procedure TBarPainter.DrawItem(ABitmap: THBitmap; AIndex: integer; ASelected,
  APressed: Boolean; ADrawBg: Boolean; ADrawForDrag: Boolean);
begin
  if AIndex = ITEM_NONE then Exit;

  const item = FHost.BarItems[AIndex];
  if FHost.BarItems.IsSeparator(item) then Exit;

  var r := item.Rect;

  // Classic themes have opaque background and button
  if ADrawBg
     and StyleServices.Enabled
  then DrawBackground(ABitmap, r);

  // For darg not need draw background
  if ADrawForDrag
  then r.Location := TPoint.Zero;

  if APressed
  then ThemeDrawButton(ABitmap, r, True)
  else if ASelected
       then begin
         Winapi.Windows.AlphaBlend(ABitmap.Dc, r.Left, r.Top, r.Width, r.Height, FHost.BarButtonBitmap.Dc, 0, 0, r.Width, r.Height, bf);
       end;

  // Draw text
  DrawCaption(ABitmap, AIndex, ADrawForDrag);

  // Draw icon
  var d: Integer := IfThen(APressed, 1, 0);
  FHost.BarItems.Draw(ABitmap.Dc, item, r.Left + FHost.BarIconOffset.X + d, r.Top + FHost.BarIconOffset.Y + d);

  // "Program is open" indicator
  if not ADrawForDrag
  then begin
    FHost.BarDrawItemMarks(ABitmap, item, r);
  end;
end;

procedure TBarPainter.DrawItems(const AWidth, AHeight: integer);
begin
  FHost.BarItems.Sizes.Button := FHost.BarButtonSize;
  FHost.BarItems.Sizes.Separator := FHost.BarSeparatorWidth;
  FHost.BarItems.Sizes.Margin := FHost.BarItemsMargin;
  FHost.BarItems.Sizes.ZoomRoom := FHost.ZoomExtra;
  FHost.BarItems.Sizes.ZoomOffset := FHost.ZoomExtra div 2;
  FHost.BarItems.Sizes.Reserved := FHost.BarReservedLength(FHost.BarIsVertical);
  FHost.BarItems.Sizes.OnlyPinned := FHost.BarIsCollapsed;
  FHost.BarItems.UpdateLines(FHost.BarIsVertical, AWidth, AHeight);

  // Draw captions
  DrawCaption(FHost.BarPanelBitmap, ITEM_ALL);

  // Magnification effect (Mac-like)
  if FZoom.Enabled and (FZoom.Cursor >= 0) and (FHost.BarItems.Lines.Count = 1) and not FHost.BarIsCollapsed
  then begin
    FZoom.Draw(FHost.BarPanelBitmap);
    Exit;
  end;

  // Separator before the pinned items
  if (not FHost.BarItems.PinnedSepRect.IsEmpty)
     and (FHost.BarSeparatorStyle <> ESeparatorStyleSpace)
  then ThemeDrawSeparator(FHost.BarPanelBitmap, FHost.BarAlign, FHost.BarItems.PinnedSepRect);

  // Draw icons
  for var item in FHost.BarItems do
  begin
    if item.Rect.IsEmpty  // collapsed bar: item without position
    then Continue;
    if FHost.BarItems.IsSeparator(item)
       and (FHost.BarSeparatorStyle <> ESeparatorStyleSpace)
    then begin
      ThemeDrawSeparator(FHost.BarPanelBitmap, FHost.BarAlign, item.Rect);
    end
    else begin
      FHost.BarItems.Draw(FHost.BarPanelBitmap.Dc, item, item.Rect.Left + FHost.BarIconOffset.X, item.Rect.Top + FHost.BarIconOffset.Y);
      FHost.BarDrawItemMarks(FHost.BarPanelBitmap, item, item.Rect);
    end;
  end;
end;

end.
