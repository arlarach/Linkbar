{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   Icon of the bar in the notification area (tray):    }
{   a way to bring the bar back in front                }
{*******************************************************}

unit Linkbar.Bar.TrayIcon;

{$i linkbar.inc}

interface

uses
  Windows, Messages, ShellApi;

type
  TBarTrayIcon = class
  private
    FWnd: HWND;
    FCallbackMsg: UINT;
    FTaskbarCreated: UINT;
    FAdded: Boolean;
    FTip: string;
    FIcon: HICON;
    procedure Fill(var AData: TNotifyIconData);
  public
    constructor Create(const AWnd: HWND; const ACallbackMsg: UINT);
    destructor Destroy; override;
    // Adds the icon (or refreshes it when it already exists)
    procedure Show(const ATip: string; const AIcon: HICON);
    procedure Hide;
    // Message registered by Explorer when it restarts: the icons must be added again
    property TaskbarCreatedMsg: UINT read FTaskbarCreated;
    property Visible: Boolean read FAdded;
  end;

implementation

uses
  SysUtils;

constructor TBarTrayIcon.Create(const AWnd: HWND; const ACallbackMsg: UINT);
begin
  inherited Create;
  FWnd := AWnd;
  FCallbackMsg := ACallbackMsg;
  FTaskbarCreated := RegisterWindowMessage('TaskbarCreated');
end;

destructor TBarTrayIcon.Destroy;
begin
  Hide;
  inherited;
end;

procedure TBarTrayIcon.Fill(var AData: TNotifyIconData);
begin
  FillChar(AData, SizeOf(AData), 0);
  AData.cbSize := SizeOf(AData);
  AData.Wnd := FWnd;
  AData.uID := 1;
  AData.uFlags := NIF_MESSAGE or NIF_ICON or NIF_TIP;
  AData.uCallbackMessage := FCallbackMsg;
  AData.hIcon := FIcon;
  StrPLCopy(AData.szTip, FTip, Length(AData.szTip) - 1);
end;

procedure TBarTrayIcon.Show(const ATip: string; const AIcon: HICON);
var data: TNotifyIconData;
begin
  FTip := ATip;
  FIcon := AIcon;
  Fill(data);
  // NIM_ADD fails when the icon already exists: then it is refreshed
  if not Shell_NotifyIcon(NIM_ADD, @data)
  then Shell_NotifyIcon(NIM_MODIFY, @data);
  FAdded := True;
end;

procedure TBarTrayIcon.Hide;
var data: TNotifyIconData;
begin
  if not FAdded
  then Exit;
  Fill(data);
  Shell_NotifyIcon(NIM_DELETE, @data);
  FAdded := False;
end;

end.
