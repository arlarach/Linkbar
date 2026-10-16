{*******************************************************}
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
