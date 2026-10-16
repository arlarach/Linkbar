{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   Keyboard of the bar: arrows and Tab move the hot    }
{   item, Enter runs it, F2 renames, Delete removes     }
{*******************************************************}

unit Linkbar.Bar.Keyboard;

{$i linkbar.inc}

interface

uses
  Linkbar.Consts, Linkbar.Bar.Host, Linkbar.Bar.AutoHide, Linkbar.Bar.ItemActions;

type
  // What the keyboard needs from the bar window
  IKeyboardHost = interface(ILinkbarHost)
    ['{9C14E8B2-7F35-4A60-B1D9-2E6A0C5F8473}']
    procedure BarSetHotIndex(const AIndex: Integer);
    function BarItemOrder: TItemOrder;
    // The items are laid out in several lines and the bar is vertical
    function BarMultiLineVertical: Boolean;
    function BarAutoHideEnabled: Boolean;
  end;

  TBarKeyboard = class
  private
    FHost: IKeyboardHost;
    FAutoHider: TBarAutoHide;
    FActions: TItemActivator;
    function IsItem(const AIndex: Integer): Boolean;
  public
    constructor Create(const AHost: IKeyboardHost; const AAutoHider: TBarAutoHide; const AActions: TItemActivator);
    // Key pressed on the bar; Key is set to 0 when the bar is hidden
    procedure KeyDown(var Key: Word);
  end;

implementation

uses
  Winapi.Windows, Math, Linkbar.Shell;

constructor TBarKeyboard.Create(const AHost: IKeyboardHost; const AAutoHider: TBarAutoHide; const AActions: TItemActivator);
begin
  inherited Create;
  FHost := AHost;
  FAutoHider := AAutoHider;
  FActions := AActions;
end;

function TBarKeyboard.IsItem(const AIndex: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex < FHost.BarItems.Count);
end;

procedure TBarKeyboard.KeyDown(var Key: Word);
begin
  if FHost.BarAutoHideEnabled
     and FAutoHider.Hidden
  then begin
    Key := 0;
    Exit;
  end;

  if (FHost.BarItems.Count = 0) then Exit;

  case Key of
    VK_SPACE, VK_RETURN: // Run
      begin
        if IsItem(FHost.BarHotIndex)
        then begin
          FHost.BarCancelTooltip;
          FActions.Execute(FHost.BarHotIndex);
        end;
        Exit;
      end;
    VK_ESCAPE: // Deselect
      begin
        if (FHost.BarHotIndex = ITEM_NONE)
        then begin
          FAutoHider.CanAutoHide := True;
          FAutoHider.Hide;
        end
        else FHost.BarSetHotIndex(ITEM_NONE);
        Exit;
      end;
    VK_F2: // Rename
      begin
        if IsItem(FHost.BarHotIndex)
        then begin
          FHost.BarCancelTooltip;
          FActions.Rename(FHost.BarHotIndex);
        end;
        Exit;
      end;
    VK_DELETE:
      begin
        if IsItem(FHost.BarHotIndex)
        then begin
          FHost.BarCancelTooltip;
          SHDeleteOp(FHost.BarHandle, FHost.BarItems[FHost.BarHotIndex].FileName, GetKeyState(VK_SHIFT) >= 0);
        end;
        Exit;
      end;
    VK_TAB:
      begin
        FHost.BarSetHotIndex(FHost.BarHotIndex + 1);
        Exit;
      end;
    // Arrows
    VK_LEFT, VK_RIGHT, VK_DOWN, VK_UP:
      begin
        // No hot item:
        // Left/Up - last
        // Right/Down - first
        if (FHost.BarHotIndex = ITEM_NONE)
        then begin
          if (Key in [VK_LEFT, VK_UP])
          then FHost.BarSetHotIndex(FHost.BarItems.Count-1)
          else FHost.BarSetHotIndex(0);
          Exit;
        end;

        // One-line panel:
        // Left/Up - prev
        // Right/Down - next
        if (FHost.BarItems.Lines.Count = 1)
        then begin
          if (Key in [VK_LEFT, VK_UP])
          then FHost.BarSetHotIndex(Max(FHost.BarHotIndex - 1, 0))
          else FHost.BarSetHotIndex(Min(FHost.BarHotIndex + 1, FHost.BarItems.Count-1));
          Exit;
        end;

        // Multi-line panel:
        case Key of
          VK_LEFT:
            begin
              if (FHost.BarItemOrder = EItemOrderLeftToRight)
              then FHost.BarSetHotIndex(Max(FHost.BarHotIndex - 1, 0))
              else begin
                if (FHost.BarMultiLineVertical)
                then begin
                  const prevLineIndex: Integer = Max(0, FHost.BarItems.GetLineIndex(FHost.BarHotIndex) - 1);
                  FHost.BarSetHotIndex(Max(FHost.BarHotIndex - FHost.BarItems.Lines[prevLineIndex], 0));
                end
                else
                  FHost.BarSetHotIndex(Max(FHost.BarHotIndex - FHost.BarItems.Lines.Count, 0));
              end;
            end;
          VK_RIGHT:
            begin
              if (FHost.BarItemOrder = EItemOrderLeftToRight)
              then FHost.BarSetHotIndex(Min(FHost.BarHotIndex + 1, FHost.BarItems.Count-1))
              else begin
                if (FHost.BarMultiLineVertical)
                then begin
                  const nextLineIndex: Integer = Min(FHost.BarItems.Lines.Count-1, FHost.BarItems.GetLineIndex(FHost.BarHotIndex) + 1);
                  FHost.BarSetHotIndex(Min(FHost.BarHotIndex + FHost.BarItems.Lines[nextLineIndex], FHost.BarItems.Count-1));
                end
                else
                  FHost.BarSetHotIndex(Min(FHost.BarHotIndex + FHost.BarItems.Lines.Count, FHost.BarItems.Count-1))
              end;
            end;
          VK_UP:
            begin
              if (FHost.BarItemOrder = EItemOrderUpToDown)
              then FHost.BarSetHotIndex(Max(FHost.BarHotIndex - 1, 0))
              else begin
                if (FHost.BarMultiLineVertical)
                then
                  FHost.BarSetHotIndex(Max(FHost.BarHotIndex - FHost.BarItems.Lines.Count, 0))
                else begin
                  const prevLineIndex: Integer = Max(0, FHost.BarItems.GetLineIndex(FHost.BarHotIndex) - 1);
                  FHost.BarSetHotIndex(Max(FHost.BarHotIndex - FHost.BarItems.Lines[prevLineIndex], 0));
                end;
              end;
            end;
          VK_DOWN:
            begin
              if (FHost.BarItemOrder = EItemOrderUpToDown)
              then FHost.BarSetHotIndex(Min(FHost.BarHotIndex + 1, FHost.BarItems.Count-1))
              else begin
                if (FHost.BarMultiLineVertical)
                then
                  FHost.BarSetHotIndex(Min(FHost.BarHotIndex + FHost.BarItems.Lines.Count, FHost.BarItems.Count-1))
                else begin
                  const nextLineIndex: Integer = Min(FHost.BarItems.Lines.Count-1, FHost.BarItems.GetLineIndex(FHost.BarHotIndex) + 1);
                  FHost.BarSetHotIndex(Min(FHost.BarHotIndex + FHost.BarItems.Lines[nextLineIndex], FHost.BarItems.Count-1));
                end;
              end;
            end;
        end;
      end;
  else
    Exit;
  end;
end;

end.
