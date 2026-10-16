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


# campos de configuracion persistidos que son del formulario (nombre sin la F)
NAMES = ['AutoHide', 'AutoHideTransparency', 'AutoShowDelay', 'AutoShowMode', 'BackgroundColor',
         'Corner1GapWidth', 'Corner2GapWidth', 'EnableAeroGlass', 'GlowSize', 'TooltipShow', 'ModernStyle',
         'BarStyle', 'IconSize', 'IsLightStyle', 'ItemMargin', 'SeparatorWidth', 'SeparatorStyle', 'ItemOrder',
         'Layout', 'JumplistRecentMax', 'JumplistShowMode', 'LockLinkbar', 'TransparencyMode', 'Look',
         'MonitorNum', 'Align', 'SortAlphabetically', 'TextColor', 'TextLayout', 'TextOffset', 'TextWidth',
         'UseBkgndColor', 'UseTextColor', 'StayOnTop']
READ_NAMES = [n for n in NAMES if n != 'StayOnTop']

p = 'mUnit.pas'
s = rd(p)

# ---------- 1. lineas de lectura de LoadSettings ----------
load_seg = seg(s, 'procedure TLinkbarWcl.LoadSettings;', '  settings.Close;\n\n  // Set other values')
read_lines = []
new_load = []
first = True
for line in load_seg.split('\n'):
    m = re.match(r'^  F(\w+)((?:\.\w+)?)\s+:= (.*);$', line)
    if m and m.group(1) in READ_NAMES:
        read_lines.append('  %s%s := %s;' % (m.group(1), m.group(2), m.group(3).replace('settings.', 'ASettings.')))
        if first:
            new_load.append('  FConfig.Load(settings);')
            first = False
        continue
    new_load.append(line)
assert len(read_lines) == len(READ_NAMES) + 1, (len(read_lines), len(READ_NAMES))
s = s.replace(load_seg, '\n'.join(new_load))

# ---------- 2. lineas de escritura de SaveSettings ----------
INIS = ['INI_MONITORNUM', 'INI_EDGE', 'INI_AUTOHIDE', 'INI_AUTOHIDE_TRANSPARENCY', 'INI_AUTOHIDE_SHOWMODE', 'INI_ICON_SIZE',
        'INI_MARGINX', 'INI_MARGINY', 'INI_TEXT_LAYOUT', 'INI_TEXT_OFFSET', 'INI_TEXT_WIDTH', 'INI_ITEM_ORDER',
        'INI_ITEMS_ALIGN', 'INI_LOCK_BAR', 'INI_ISLIGHT', 'INI_ENABLE_AG', 'INI_AUTOSHOW_DELAY', 'INI_SORT_AB',
        'INI_USEBKGCOLOR', 'INI_BKGCOLOR', 'INI_USETXTCOLOR', 'INI_TXTCOLOR', 'INI_GLOWSIZE', 'INI_STAYONTOP',
        'INI_JUMPLIST_SHOWMODE', 'INI_JUMPLIST_RECENTMAX', 'INI_COLORMODE', 'INI_TRANSPARENCYMODE',
        'INI_CORNER1GAP_WIDTH', 'INI_CORNER2GAP_WIDTH', 'INI_SEPARATOR_WIDTH', 'INI_SEPARATOR_STYLE',
        'INI_TOOLTIP_SHOW', 'INI_MODERN_STYLE', 'INI_BAR_STYLE']
save_seg = seg(s, 'procedure TLinkbarWcl.SaveSettings;', '    // Save\n    settings.Close;')
new_save = []
first = True
removed = 0
for line in save_seg.split('\n'):
    m = re.match(r'^    settings\.Write\((INI_\w+),', line)
    if m and m.group(1) in INIS:
        removed += 1
        if first:
            new_save.append('    FConfig.Save(settings, Align, BackgroundColor);')
            first = False
        continue
    new_save.append(line)
assert removed == len(INIS), (removed, len(INIS))
s = s.replace(save_seg, '\n'.join(new_save))

# ---------- 3. unidad nueva ----------
UNIT = """{*******************************************************}
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
""" + '\n'.join(read_lines) + """
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
"""
wr('Linkbar.Bar.Config.pas', UNIT)

# ---------- 4. declaraciones de campos en el formulario ----------
s = rep(s, '    FCorner1GapWidth, FCorner2GapWidth: Integer;\n', '')
for n in NAMES:
    if n in ('Corner1GapWidth', 'Corner2GapWidth'):
        continue
    s, c = re.subn(r'^    F' + n + r': [^\n]*\n', '', s, flags=re.M)
    assert c == 1, (n, c)
s = rep(s, '    FSysWidgets: TSysWidgets;          // CPU / RAM widgets\n',
        '    FSysWidgets: TSysWidgets;          // CPU / RAM widgets\n    FConfig: TBarConfig;         // settings kept in the settings file\n')

# ---------- 5. usos ----------
for n in NAMES:
    s = re.sub(r'\bF' + n + r'\b', 'FConfig.' + n, s)

s = rep(s, 'Linkbar.Bar.Painter, Linkbar.Bar.PopupMenu;', 'Linkbar.Bar.Painter, Linkbar.Bar.PopupMenu, Linkbar.Bar.Config;')
wr(p, s)

d = rd('Linkbar.dproj')
k = '        <DCCReference Include="Linkbar.Bar.PopupMenu.pas"/>'
d = rep(d, k, k + '\n        <DCCReference Include="Linkbar.Bar.Config.pas"/>')
wr('Linkbar.dproj', d)
