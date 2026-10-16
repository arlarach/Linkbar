import re
p = 'mUnit.pas'
s = open(p, 'rb').read().decode('utf-8').replace('\r\n', '\n')


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


# ---------- 1. segmentos que se mueven ----------
m_len = seg(s, '{ Space kept at the end of the bar }', 'function TLinkbarWcl.SysWidgetRect')
m_rect = seg(s, 'function TLinkbarWcl.SysWidgetRect', 'procedure TLinkbarWcl.SampleSysStats;')
m_samp = seg(s, 'procedure TLinkbarWcl.SampleSysStats;', 'procedure TLinkbarWcl.DrawSysWidgets')
m_draw = seg(s, 'procedure TLinkbarWcl.DrawSysWidgets', '{ Timer: sample and redraw only the widget area }')
m_const = seg(s, 'const\n  SYSWIDGET_COUNT = 2; // CPU, RAM', 'procedure TLinkbarWcl.SetShowSysWidgets')


def common(t):
    t = t.replace('TLinkbarWcl.SysWidgetLength', 'TSysWidgets.ReservedLength')
    t = t.replace('TLinkbarWcl.SysWidgetRect', 'TSysWidgets.WidgetRect')
    t = t.replace('TLinkbarWcl.SampleSysStats', 'TSysWidgets.Sample')
    t = t.replace('TLinkbarWcl.DrawSysWidgets', 'TSysWidgets.Draw')
    t = t.replace('SysWidgetLength(', 'ReservedLength(')
    t = t.replace('SysWidgetRect(', 'WidgetRect(')
    t = t.replace('FShowSysWidgets', 'FEnabled')
    t = t.replace('IsVertical(Align)', 'FHost.BarIsVertical')
    t = t.replace('ScaleDimension(', 'FHost.ScaleValue(')
    t = t.replace('FBtnCollapseRect', 'FCollapseRect').replace('FBtnCollapseHot', 'FCollapseHot')
    t = re.sub(r'\bIsCollapsed\b', 'FHost.BarIsCollapsed', t)
    t = re.sub(r'\bZoomRoom\b', 'FHost.ZoomExtra', t)
    return t


m_len = common(m_len).replace('ButtonSize.', 'FHost.BarButtonSize.')
m_rect = common(m_rect)
m_samp = common(m_samp)
m_draw = common(m_draw).replace('ButtonSize.', 'bs.')
m_draw = rep(m_draw, '  s: string;\nbegin\n  if not FEnabled', '  s: string;\n  bs: TSize;\nbegin\n  bs := FHost.BarButtonSize;\n  if not FEnabled')
m_const = m_const.replace('procedure TLinkbarWcl.SetShowSysWidgets', '')

HEADER = """{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   CPU / RAM widgets at the end of the bar: sampling   }
{   of the system load, layout and drawing, and the     }
{   rectangle of the ">>" / "<<" collapse button        }
{*******************************************************}

unit Linkbar.Bar.SysWidgets;

{$i linkbar.inc}

interface

uses
  Windows, Types,
  Linkbar.Graphics, Linkbar.Bar.Host;

type
  TSysWidgets = class
  private
    FHost: ILinkbarHost;
    FEnabled: Boolean;
    FCpuLoad, FRamLoad: Integer;       // 0..100
    FPrevIdle, FPrevKernel, FPrevUser: UInt64;
    FCollapseRect: TRect;              // interactive area of the ">>" / "<<" button
    FCollapseHot: Boolean;             // the mouse is over the button
  public
    constructor Create(const AHost: ILinkbarHost);
    // Reads the current CPU and RAM load
    procedure Sample;
    // Space kept at the end of the bar (0 when the widgets are off)
    function ReservedLength(const AVertical: Boolean): Integer;
    // Area of the widgets inside a bar of the given size
    function WidgetRect(const AWidth, AHeight: Integer): TRect;
    procedure Draw(const ABitmap: THBitmap; const AWidth, AHeight: Integer);
    property Enabled: Boolean read FEnabled write FEnabled;
    property CpuLoad: Integer read FCpuLoad;
    property RamLoad: Integer read FRamLoad;
    property CollapseRect: TRect read FCollapseRect;
    property CollapseHot: Boolean read FCollapseHot write FCollapseHot;
  end;

implementation

uses
  SysUtils, Math, Graphics, Forms, Themes, GdiPlus, Linkbar.Consts, Linkbar.Theme;

"""

unit_txt = (HEADER + m_const.rstrip() + "\n\n"
            + "constructor TSysWidgets.Create(const AHost: ILinkbarHost);\nbegin\n  inherited Create;\n  FHost := AHost;\nend;\n\n"
            + m_len + m_rect + m_samp + m_draw.rstrip() + "\n\nend.\n")
open('Linkbar.Bar.SysWidgets.pas', 'wb').write(unit_txt.replace('\n', '\r\n').encode('utf-8'))

HOST = """{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   What the classes that serve the bar need to ask     }
{   the bar window (implemented by TLinkbarWcl)         }
{*******************************************************}

unit Linkbar.Bar.Host;

{$i linkbar.inc}

interface

uses
  Types;

type
  ILinkbarHost = interface
    ['{6B1F3C52-8D0A-4E6B-9A57-2C4F1D7E8B31}']
    // Scales a value from 96 dpi to the dpi of the bar
    function ScaleValue(const X: Integer): Integer;
    function BarButtonSize: TSize;
    // Extra thickness reserved for the zoom of the items
    function ZoomExtra: Integer;
    function BarIsVertical: Boolean;
    function BarIsCollapsed: Boolean;
  end;

implementation

end.
"""
open('Linkbar.Bar.Host.pas', 'wb').write(HOST.replace('\n', '\r\n').encode('utf-8'))

# ---------- 2. mUnit.pas ----------
s = s.replace(seg(s, '{ Space kept at the end of the bar }', '{ Timer: sample and redraw only the widget area }'), '')
s = s.replace(seg(s, 'const\n  SYSWIDGET_COUNT = 2; // CPU, RAM', 'procedure TLinkbarWcl.SetShowSysWidgets'), '')

s = rep(s, 'TLinkbarWcl = class(TLinkbarCustomFrom)', 'TLinkbarWcl = class(TLinkbarCustomFrom, ILinkbarHost)')
s = rep(s, '    FCpuLoad, FRamLoad: Integer;       // 0..100\n    FPrevIdle, FPrevKernel, FPrevUser: UInt64;\n', '    FSysWidgets: TSysWidgets;          // CPU / RAM widgets\n')
s = rep(s, '    FBtnCollapseRect: TRect;      // Área interactiva del botón ">>" / "<<"\n    FBtnCollapseHot: Boolean;     // Para saber si el mouse está sobre el botón\n', '')
s = rep(s, '    FShowSysWidgets: Boolean;\n', '')
s = rep(s, '    function SysWidgetLength(const AVertical: Boolean): Integer;\n    function SysWidgetRect(const AWidth, AHeight: Integer): TRect;\n    procedure SampleSysStats;\n    procedure DrawSysWidgets(const ABitmap: THBitmap; const AWidth, AHeight: Integer);\n', '')
s = rep(s, '    procedure SetShowSysWidgets(AValue: Boolean);\n', '    procedure SetShowSysWidgets(AValue: Boolean);\n    function GetShowSysWidgets: Boolean;\n')
s = rep(s, 'property ShowSysWidgets: Boolean read FShowSysWidgets write SetShowSysWidgets;', 'property ShowSysWidgets: Boolean read GetShowSysWidgets write SetShowSysWidgets;')
s = rep(s, '    function ScaleDimension(const X: Integer): Integer; inline;\n',
        '    function ScaleDimension(const X: Integer): Integer; inline;\n'
        '    // ILinkbarHost\n'
        '    function ScaleValue(const X: Integer): Integer;\n'
        '    function BarButtonSize: TSize;\n'
        '    function ZoomExtra: Integer;\n'
        '    function BarIsVertical: Boolean;\n'
        '    function BarIsCollapsed: Boolean;\n')
s = rep(s, 'procedure TLinkbarWcl.DoAutoHide;',
        'function TLinkbarWcl.ScaleValue(const X: Integer): Integer;\nbegin\n  Result := ScaleDimension(X);\nend;\n\n'
        'function TLinkbarWcl.BarButtonSize: TSize;\nbegin\n  Result := FButtonSize;\nend;\n\n'
        'function TLinkbarWcl.ZoomExtra: Integer;\nbegin\n  Result := ZoomRoom;\nend;\n\n'
        'function TLinkbarWcl.BarIsVertical: Boolean;\nbegin\n  Result := IsVertical(Align);\nend;\n\n'
        'function TLinkbarWcl.BarIsCollapsed: Boolean;\nbegin\n  Result := IsCollapsed;\nend;\n\n'
        'function TLinkbarWcl.GetShowSysWidgets: Boolean;\nbegin\n  Result := FSysWidgets.Enabled;\nend;\n\n'
        'procedure TLinkbarWcl.DoAutoHide;')

s = s.replace('SysWidgetLength(', 'FSysWidgets.ReservedLength(')
s = s.replace('SysWidgetRect(', 'FSysWidgets.WidgetRect(')
s = rep(s, 'SampleSysStats;', 'FSysWidgets.Sample;', 0)
s = s.replace('DrawSysWidgets(', 'FSysWidgets.Draw(')
s = re.sub(r'\bFBtnCollapseRect\b', 'FSysWidgets.CollapseRect', s)
s = re.sub(r'\bFBtnCollapseHot\b', 'FSysWidgets.CollapseHot', s)
s = re.sub(r'\bFShowSysWidgets\b', 'FSysWidgets.Enabled', s)
s = re.sub(r'\bFCpuLoad\b', 'FSysWidgets.CpuLoad', s)
s = re.sub(r'\bFRamLoad\b', 'FSysWidgets.RamLoad', s)

s = rep(s, '  FSaveQueue.OnFailed := ShowSaveFailed;\n', '  FSaveQueue.OnFailed := ShowSaveFailed;\n  FSysWidgets := TSysWidgets.Create(Self);\n')
s = rep(s, '  FreeAndNil(FSaveQueue);\n', '  FreeAndNil(FSaveQueue);\n  FreeAndNil(FSysWidgets);\n')
s = rep(s, 'Linkbar.Graphics, Linkbar.Bar.SaveQueue, Linkbar.Bar.Profiles;', 'Linkbar.Graphics, Linkbar.Bar.Host, Linkbar.Bar.SaveQueue, Linkbar.Bar.Profiles,\n  Linkbar.Bar.SysWidgets;')
open(p, 'wb').write(s.replace('\n', '\r\n').encode('utf-8'))

d = 'Linkbar.dproj'
t = open(d, 'rb').read().decode('utf-8')
k = '        <DCCReference Include="Linkbar.Bar.Profiles.pas"/>'
nl = '\r\n' if '\r\n' in t else '\n'
t = t.replace(k, k + nl + '        <DCCReference Include="Linkbar.Bar.Host.pas"/>' + nl + '        <DCCReference Include="Linkbar.Bar.SysWidgets.pas"/>', 1)
open(d, 'wb').write(t.encode('utf-8'))
