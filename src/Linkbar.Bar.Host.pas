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
  LBToolbar, Linkbar.Consts, Linkbar.Graphics;

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
    function BarPanelName: string;
    // Work area of the monitor of the bar
    function BarWorkArea: TRect;
    // Bounds of the bar window
    function BarBounds: TRect;
    // Moves the window keeping its size
    procedure BarMoveTo(const AX, AY: Integer);
    function BarIsDock: Boolean;
    function BarBackgroundColor: Cardinal;
    function BarIsLightStyle: Boolean;
    function BarAutoHideTransparency: Boolean;
    // Width of the corner gaps kept free when the bar is hidden
    function BarCorner1Gap: Integer;
    function BarCorner2Gap: Integer;
    function BarHotIndex: Integer;
    function BarPressedIndex: Integer;
    // The bitmap where the bar draws its items
    function BarPanelBitmap: THBitmap;
    // The bitmap with the look of a pressed / selected button
    function BarButtonBitmap: THBitmap;
    // Offset of the icon inside the button of an item
    function BarIconOffset: TPoint;
    function BarSeparatorStyle: TSeparatorStyle;
    function BarSeparatorWidth: Integer;
    function BarItemsMargin: Integer;
    // Space kept at the end of the bar for the CPU / RAM widgets
    function BarReservedLength(const AVertical: Boolean): Integer;
    function BarTextLayout: TTextLayout;
    function BarTextRect: TRect;
    function BarUseTextColor: Boolean;
    function BarTextColor: Cardinal;
    function BarGlowSize: Integer;
    // Draws the "program is open" pill and the pinned dot of an item
    procedure BarDrawItemMarks(const ABitmap: THBitmap; const AItem: TItemBase; const ARect: TRect);
  end;

implementation

end.
