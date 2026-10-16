{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   What the classes that serve the bar need to ask     }
{   the bar window (implemented by TLinkbarWcl)         }
{*******************************************************}

unit Linkbar.Bar.Host;

{$i linkbar.inc}

interface

uses
  Windows, Classes, Types,
  LBToolbar, Linkbar.Consts;

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
    function BarHandle: HWND;
    // The bar window as owner of the forms it opens
    function BarOwner: TComponent;
    function BarAlign: TPanelAlign;
    function BarIconSize: Integer;
    // Recalculates the size of the window and redraws it
    procedure BarUpdateSize;
    procedure BarStartTimer(const AId: UINT; const AMs: Cardinal);
    procedure BarStopTimer(const AId: UINT);
    procedure BarCancelTooltip;
    // Closes the thumbnails and the tooltip
    procedure BarDismissPopups;
    procedure BarSetAutoHideLock(const ALock: Boolean);
    // Links folder of the current profile
    function BarWorkDir: string;
    function BarItems: TLBItemList;
    function BarSettingsFile: string;
    // Work area of the monitor of the bar
    function BarWorkArea: TRect;
    // Bounds of the bar window
    function BarBounds: TRect;
    // Moves the window keeping its size
    procedure BarMoveTo(const AX, AY: Integer);
  end;

implementation

end.
