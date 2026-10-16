{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   Borderless popup menus: removes the frame of the    }
{   #32768 menu window (WinEventHook)                   }
{*******************************************************}

unit Linkbar.Bar.MenuHook;

{$i linkbar.inc}

interface

type
  TMenuBorderHook = class
  public
    // Reference counted: the hook is installed by the first bar and removed by the last
    class procedure Install;
    class procedure Remove;
  end;

implementation

uses
  Windows;

const
  EVENT_SYSTEM_MENUPOPUPSTART = $0006;
  WINEVENT_OUTOFCONTEXT = $0000;
  DWMWA_WINDOW_CORNER_PREFERENCE = 33;
  DWMWA_BORDER_COLOR = 34;
  DWMWCP_DONOTROUND = 1;
  DWMWA_COLOR_NONE = $FFFFFFFE;

type
  TWinEventProc = procedure(hWinEventHook: THandle; event: DWORD; hwnd: HWND;
    idObject, idChild: LongInt; idEventThread, dwmsEventTime: DWORD); stdcall;

function SetWinEventHook(eventMin, eventMax: DWORD; hmodWinEventProc: HMODULE;
  pfnWinEventProc: TWinEventProc; idProcess, idThread, dwFlags: DWORD): THandle; stdcall;
  external user32 name 'SetWinEventHook';
function UnhookWinEvent(hWinEventHook: THandle): BOOL; stdcall;
  external user32 name 'UnhookWinEvent';
function DwmSetWindowAttribute(hwnd: HWND; dwAttribute: DWORD; pvAttribute: Pointer;
  cbAttribute: DWORD): HRESULT; stdcall;
  external 'dwmapi.dll' name 'DwmSetWindowAttribute';

var
  MenuHook: THandle = 0;
  MenuHookRefs: Integer = 0;

{ Quita el marco (borde blanco) de la ventana del menú #32768 }
procedure MenuWinEvent(hWinEventHook: THandle; event: DWORD; hwnd: HWND;
  idObject, idChild: LongInt; idEventThread, dwmsEventTime: DWORD); stdcall;
var
  cls: array[0..31] of Char;
  st, exst: LONG_PTR;
  v: DWORD;
begin
  if (hwnd = 0) or (GetClassName(hwnd, cls, Length(cls)) = 0) or (cls <> '#32768')
  then Exit;

  st := GetWindowLongPtr(hwnd, GWL_STYLE);
  SetWindowLongPtr(hwnd, GWL_STYLE, st and not (WS_BORDER or WS_THICKFRAME or WS_DLGFRAME));
  exst := GetWindowLongPtr(hwnd, GWL_EXSTYLE);
  SetWindowLongPtr(hwnd, GWL_EXSTYLE,
    exst and not (WS_EX_WINDOWEDGE or WS_EX_CLIENTEDGE or WS_EX_DLGMODALFRAME or WS_EX_STATICEDGE));

  // Windows 11: sin contorno DWM y sin esquinas redondeadas (ignorado en versiones anteriores)
  v := DWMWA_COLOR_NONE;
  DwmSetWindowAttribute(hwnd, DWMWA_BORDER_COLOR, @v, SizeOf(v));
  v := DWMWCP_DONOTROUND;
  DwmSetWindowAttribute(hwnd, DWMWA_WINDOW_CORNER_PREFERENCE, @v, SizeOf(v));

  SetWindowPos(hwnd, 0, 0, 0, 0, 0,
    SWP_FRAMECHANGED or SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE);
end;

class procedure TMenuBorderHook.Install;
begin
  Inc(MenuHookRefs);
  if (MenuHook = 0)
  then MenuHook := SetWinEventHook(EVENT_SYSTEM_MENUPOPUPSTART, EVENT_SYSTEM_MENUPOPUPSTART,
    0, MenuWinEvent, GetCurrentProcessId, GetCurrentThreadId, WINEVENT_OUTOFCONTEXT);
end;

class procedure TMenuBorderHook.Remove;
begin
  Dec(MenuHookRefs);
  if (MenuHookRefs <= 0) and (MenuHook <> 0)
  then begin
    UnhookWinEvent(MenuHook);
    MenuHook := 0;
    MenuHookRefs := 0;
  end;
end;

end.
