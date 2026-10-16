{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   Settings of the bar that are kept in the settings   }
{   file: look, layout, behavior and positions          }
{*******************************************************}

unit Linkbar.Bar.Config;

{$i linkbar.inc}

interface

uses
  Types, Linkbar.Consts, Linkbar.Settings;

type
  TBarConfig = record
    AutoHide: Boolean;
    AutoHideTransparency: Boolean;
    AutoShowDelay: Integer;
    AutoShowMode: TAutoShowMode;
    BackgroundColor: Cardinal;
    Corner1GapWidth: Integer;
    Corner2GapWidth: Integer;
    EnableAeroGlass: Boolean;
    GlowSize: Integer;
    TooltipShow: Boolean;
    ModernStyle: Boolean;
    BarStyle: Integer;            // BAR_STYLE_NORMAL / BAR_STYLE_DOCK / BAR_STYLE_TASKBAR
    IconSize: Integer;
    IsLightStyle: Boolean;
    ItemMargin: TSize;
    SeparatorWidth: Integer;
    SeparatorStyle: TSeparatorStyle;
    ItemOrder: TItemOrder;
    Layout: TPanelLayout;
    JumplistRecentMax: Integer;
    JumplistShowMode: TJumplistShowMode;
    LockLinkbar: Boolean;
    TransparencyMode: TTransparencyMode;
    Look: TLook;
    MonitorNum: Integer;
    Align: TPanelAlign;
    SortAlphabetically: Boolean;
    TextColor: Cardinal;
    TextLayout: TTextLayout;
    TextOffset: Integer;
    TextWidth: Integer;
    UseBkgndColor: Boolean;
    UseTextColor: Boolean;
    StayOnTop: Boolean;
    // Reads the values (with their limits) from the open settings file.
    // StayOnTop is not read: it needs the window (see the bar)
    procedure Load(var ASettings: TSettingsFile);
    // Writes the values. The edge is the one the bar has right now (it changes
    // while the bar is dragged) and the background color the one in use
    procedure Save(var ASettings: TSettingsFile; const ALiveAlign: TPanelAlign;
      const AEffectiveBackground: Cardinal);
  end;

implementation

uses
  SysUtils, Vcl.Forms;

procedure TBarConfig.Load(var ASettings: TSettingsFile);
begin
  AutoHide := ASettings.Read(INI_AUTOHIDE, DEF_AUTOHIDE);
  AutoHideTransparency := ASettings.Read(INI_AUTOHIDE_TRANSPARENCY, DEF_AUTOHIDE_TRANSPARENCY);
  AutoShowDelay := ASettings.Read(INI_AUTOSHOW_DELAY, DEF_AUTOSHOW_DELAY, 0, 60000);
  AutoShowMode := ASettings.Read<TAutoShowMode>(INI_AUTOHIDE_SHOWMODE, DEF_AUTOHIDE_SHOWMODE);
  BackgroundColor := Cardinal(ASettings.Read(INI_BKGCOLOR, DEF_BKGCOLOR));
  Corner1GapWidth := ASettings.Read(INI_CORNER1GAP_WIDTH, DEF_CORNERGAP_WIDTH);
  Corner2GapWidth := ASettings.Read(INI_CORNER2GAP_WIDTH, DEF_CORNERGAP_WIDTH);
  EnableAeroGlass := ASettings.Read(INI_ENABLE_AG, DEF_ENABLE_AG);
  GlowSize := ASettings.Read(INI_GLOWSIZE, DEF_GLOWSIZE, GLOW_SIZE_MIN, GLOW_SIZE_MAX);
  TooltipShow := ASettings.Read(INI_TOOLTIP_SHOW, DEF_TOOLTIP_SHOW);
  ModernStyle := ASettings.Read(INI_MODERN_STYLE, DEF_MODERN_STYLE);
  BarStyle := ASettings.Read(INI_BAR_STYLE, DEF_BAR_STYLE, BAR_STYLE_NORMAL, BAR_STYLE_TASKBAR);
  IconSize := ASettings.Read(INI_ICON_SIZE, DEF_ICON_SIZE, ICON_SIZE_MIN, ICON_SIZE_MAX);
  IsLightStyle := ASettings.Read(INI_ISLIGHT, DEF_ISLIGHT);
  ItemMargin.cx := ASettings.Read(INI_MARGINX, DEF_MARGINX, MARGIN_MIN, MARGIN_MAX);
  ItemMargin.cy := ASettings.Read(INI_MARGINY, DEF_MARGINY, MARGIN_MIN, MARGIN_MAX);
  SeparatorWidth := ASettings.Read(INI_SEPARATOR_WIDTH, DEF_SEPARATOR_WIDTH, SEPARATOR_WIDTH_MIN, SEPARATOR_WIDTH_MAX);
  SeparatorStyle := ASettings.Read<TSeparatorStyle>(INI_SEPARATOR_STYLE, DEF_SEPARATOR_STYLE);
  ItemOrder := ASettings.Read<TItemOrder>(INI_ITEM_ORDER, DEF_ITEM_ORDER);
  Layout := ASettings.Read<TPanelLayout>(INI_ITEMS_ALIGN, DEF_ITEMS_ALIGN);
  JumplistRecentMax := ASettings.Read(INI_JUMPLIST_RECENTMAX, DEF_JUMPLIST_RECENTMAX, JUMPLIST_RECENTMAX_MIN, JUMPLIST_RECENTMAX_MAX);
  JumplistShowMode := ASettings.Read<TJumplistShowMode>(INI_JUMPLIST_SHOWMODE, DEF_JUMPLIST_SHOWMODE);
  LockLinkbar := ASettings.Read(INI_LOCK_BAR, DEF_LOCK_BAR);
  TransparencyMode := ASettings.Read<TTransparencyMode>(INI_TRANSPARENCYMODE, DEF_TRANSPARENCYMODE);
  Look := ASettings.Read<TLook>(INI_COLORMODE, DEF_COLORMODE);
  MonitorNum := ASettings.Read(INI_MONITORNUM, Screen.PrimaryMonitor.MonitorNum, 0, Screen.MonitorCount-1);
  Align := ASettings.Read<TPanelAlign>(INI_EDGE, DEF_EDGE);
  SortAlphabetically := ASettings.Read(INI_SORT_AB, DEF_SORT_AB);
  TextColor := Cardinal(ASettings.Read(INI_TXTCOLOR, DEF_TXTCOLOR) and $ffffff);
  TextLayout := ASettings.Read<TTextLayout>(INI_TEXT_LAYOUT, DEF_TEXT_LAYOUT);
  TextOffset := ASettings.Read(INI_TEXT_OFFSET, DEF_TEXT_OFFSET, TEXT_OFFSET_MIN, TEXT_OFFSET_MAX);
  TextWidth := ASettings.Read(INI_TEXT_WIDTH, DEF_TEXT_WIDTH, TEXT_WIDTH_MIN, TEXT_WIDTH_MAX);
  UseBkgndColor := ASettings.Read(INI_USEBKGCOLOR, DEF_USEBKGCOLOR);
  UseTextColor := ASettings.Read(INI_USETXTCOLOR, DEF_USETXTCOLOR);
end;

procedure TBarConfig.Save(var ASettings: TSettingsFile; const ALiveAlign: TPanelAlign;
  const AEffectiveBackground: Cardinal);
begin
  ASettings.Write(INI_MONITORNUM, MonitorNum);
  ASettings.Write(INI_EDGE, Integer(ALiveAlign));
  ASettings.Write(INI_AUTOHIDE, AutoHide);
  ASettings.Write(INI_AUTOHIDE_TRANSPARENCY, AutoHideTransparency);
  ASettings.Write(INI_AUTOHIDE_SHOWMODE, Integer(AutoShowMode));
  ASettings.Write(INI_ICON_SIZE, IconSize);
  ASettings.Write(INI_MARGINX, ItemMargin.cx);
  ASettings.Write(INI_MARGINY, ItemMargin.cy);
  ASettings.Write(INI_TEXT_LAYOUT, Integer(TextLayout));
  ASettings.Write(INI_TEXT_OFFSET, TextOffset);
  ASettings.Write(INI_TEXT_WIDTH, TextWidth);
  ASettings.Write(INI_ITEM_ORDER, Integer(ItemOrder));
  ASettings.Write(INI_ITEMS_ALIGN, Integer(Layout));
  ASettings.Write(INI_LOCK_BAR, LockLinkbar);
  ASettings.Write(INI_ISLIGHT, IsLightStyle);
  ASettings.Write(INI_ENABLE_AG, EnableAeroGlass);
  ASettings.Write(INI_AUTOSHOW_DELAY, AutoShowDelay);
  ASettings.Write(INI_SORT_AB, SortAlphabetically);
  ASettings.Write(INI_USEBKGCOLOR, UseBkgndColor);
  ASettings.Write(INI_BKGCOLOR, HexDisplayPrefix + IntToHex(AEffectiveBackground, 8));
  ASettings.Write(INI_USETXTCOLOR, UseTextColor);
  ASettings.Write(INI_TXTCOLOR, HexDisplayPrefix + IntToHex(TextColor, 6));
  ASettings.Write(INI_GLOWSIZE, GlowSize);
  ASettings.Write(INI_STAYONTOP, StayOnTop);
  ASettings.Write(INI_JUMPLIST_SHOWMODE, Integer(JumplistShowMode));
  ASettings.Write(INI_JUMPLIST_RECENTMAX, JumplistRecentMax);
  ASettings.Write(INI_COLORMODE, Integer(Look));
  ASettings.Write(INI_TRANSPARENCYMODE, Integer(TransparencyMode));
  ASettings.Write(INI_CORNER1GAP_WIDTH, Corner1GapWidth);
  ASettings.Write(INI_CORNER2GAP_WIDTH, Corner2GapWidth);
  ASettings.Write(INI_SEPARATOR_WIDTH, SeparatorWidth);
  ASettings.Write(INI_SEPARATOR_STYLE, Integer(SeparatorStyle));
  ASettings.Write(INI_TOOLTIP_SHOW, TooltipShow);
  ASettings.Write(INI_MODERN_STYLE, ModernStyle);
  ASettings.Write(INI_BAR_STYLE, BarStyle);
end;

end.
