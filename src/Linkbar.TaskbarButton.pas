{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   "Taskbar icon" mode: the bar is shown as a button   }
{   on the Windows taskbar; a click opens its content   }
{   as a popup above the taskbar (Arlarach)             }
{*******************************************************}

unit Linkbar.TaskbarButton;

{$i linkbar.inc}

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms;

type
  { Window that only exists to own a taskbar button. It stays minimized:
    when the user clicks the button, Windows asks it to restore; instead it
    fires OnClick and stays minimized. }
  TTaskbarButton = class(TForm)
  private
    FOnClick: TNotifyEvent;
    FOnCloseRequest: TNotifyEvent;
    FLastClick: Cardinal;
    FBigIcon, FSmallIcon: HICON;
    FAppId: string;
    procedure ApplyAppId;
    procedure RequestClick;
    procedure WMSysCommand(var Msg: TWMSysCommand); message WM_SYSCOMMAND;
    procedure WMActivate(var Msg: TWMActivate); message WM_ACTIVATE;
    procedure WMClose(var Msg: TWMClose); message WM_CLOSE;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WndProc(var Message: TMessage); override;
  public
    constructor CreateButton(AOwner: TComponent; const ACaption: string);
    destructor Destroy; override;
    procedure ShowButton;
    { Icon of the button (the window takes ownership of the handles) }
    procedure SetIcons(ABig, ASmall: HICON);
    { Own taskbar identity: each bar gets its own button instead of
      being grouped with the other bars }
    procedure SetAppId(const AId: string);
    procedure HideButton;
    property OnClick: TNotifyEvent read FOnClick write FOnClick;
    property OnCloseRequest: TNotifyEvent read FOnCloseRequest write FOnCloseRequest;
  end;

  { Where the taskbar is and which edge, to place the popup above it.
    ARect: a thin rectangle on the taskbar at the mouse position. }
  procedure GetTaskbarAnchor(out ARect: TRect; out AEdge: UINT);

  { HICON from a 32-bit premultiplied ARGB DIB section (e.g. CreateGroupIcon) }
  function IconFromPremultipliedBitmap(ABmp: HBITMAP): HICON;
  { "C:\path\file.dll,3" -> icons of that file (index 3); False if none }
  function LoadIconsFromSpec(const ASpec: string; out ABig, ASmall: HICON): Boolean;

implementation

uses
  Winapi.ShellAPI, Winapi.ActiveX, Winapi.PropSys;

function LB_SHGetPropertyStoreForWindow(hwnd: HWND; const riid: TGUID; out ppv): HRESULT; stdcall;
  external 'shell32.dll' name 'SHGetPropertyStoreForWindow';

const
  LB_PKEY_AppUserModel_ID: TPropertyKey = (
    fmtid: '{9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3}'; pid: 5);

const
  LM_TASKBAR_CLICK = WM_APP + 41;

{ TTaskbarButton }

constructor TTaskbarButton.CreateButton(AOwner: TComponent; const ACaption: string);
begin
  inherited CreateNew(AOwner);
  BorderStyle := bsSingle;
  BorderIcons := [biSystemMenu, biMinimize];
  Position := poDesigned;
  // Far outside the screen: it is never shown restored anyway
  SetBounds(-32000, -32000, 120, 40);
  Caption := ACaption;
  Icon.Assign(Application.Icon);
  FLastClick := 0;
end;

destructor TTaskbarButton.Destroy;
begin
  if (FBigIcon <> 0) then DestroyIcon(FBigIcon);
  if (FSmallIcon <> 0) then DestroyIcon(FSmallIcon);
  inherited;
end;

procedure TTaskbarButton.SetIcons(ABig, ASmall: HICON);
var oldBig, oldSmall: HICON;
begin
  oldBig := FBigIcon;
  oldSmall := FSmallIcon;
  FBigIcon := ABig;
  FSmallIcon := ASmall;
  HandleNeeded;
  SendMessage(Handle, WM_SETICON, ICON_BIG, LPARAM(FBigIcon));
  SendMessage(Handle, WM_SETICON, ICON_SMALL, LPARAM(FSmallIcon));
  if (oldBig <> 0) and (oldBig <> ABig) then DestroyIcon(oldBig);
  if (oldSmall <> 0) and (oldSmall <> ASmall) then DestroyIcon(oldSmall);
end;

procedure TTaskbarButton.SetAppId(const AId: string);
var wasVisible: Boolean;
begin
  if (AId = FAppId) then Exit;
  FAppId := AId;
  if not HandleAllocated then Exit;
  // The taskbar reads the id when the button appears
  wasVisible := IsWindowVisible(Handle);
  if wasVisible then ShowWindow(Handle, SW_HIDE);
  ApplyAppId;
  if wasVisible then ShowWindow(Handle, SW_SHOWMINNOACTIVE);
end;

procedure TTaskbarButton.ApplyAppId;
var
  store: IPropertyStore;
  pv: TPropVariant;
  bytes: Integer;
begin
  if (FAppId = '') or not HandleAllocated then Exit;
  if not Succeeded(LB_SHGetPropertyStoreForWindow(Handle, IPropertyStore, store)) then Exit;
  FillChar(pv, SizeOf(pv), 0);
  pv.vt := VT_LPWSTR;
  bytes := (Length(FAppId) + 1) * SizeOf(Char);
  pv.pwszVal := CoTaskMemAlloc(bytes);
  if (pv.pwszVal = nil) then Exit;
  Move(PChar(FAppId)^, pv.pwszVal^, bytes);
  try
    store.SetValue(LB_PKEY_AppUserModel_ID, pv);
    store.Commit;
  finally
    PropVariantClear(pv);
  end;
end;

procedure TTaskbarButton.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  // Own taskbar button, not owned by the (hidden, tool window) bar
  Params.ExStyle := (Params.ExStyle or WS_EX_APPWINDOW) and not WS_EX_TOOLWINDOW;
  Params.WndParent := 0;
end;

procedure TTaskbarButton.ShowButton;
begin
  HandleNeeded;
  ApplyAppId;
  ShowWindow(Handle, SW_SHOWMINNOACTIVE);
end;

procedure TTaskbarButton.HideButton;
begin
  if HandleAllocated
  then ShowWindow(Handle, SW_HIDE);
end;

procedure TTaskbarButton.RequestClick;
begin
  // Run the click after Windows finished with the button message
  PostMessage(Handle, LM_TASKBAR_CLICK, 0, 0);
end;

procedure TTaskbarButton.WMSysCommand(var Msg: TWMSysCommand);
begin
  case (Msg.CmdType and $FFF0) of
    SC_RESTORE, SC_MAXIMIZE:
      begin
        // Click on the taskbar button: open the popup, stay minimized
        RequestClick;
        Msg.Result := 0;
      end;
    SC_MINIMIZE, SC_MOVE, SC_SIZE:
      Msg.Result := 0;
    SC_CLOSE:
      begin
        if Assigned(FOnCloseRequest) then FOnCloseRequest(Self);
        Msg.Result := 0;
      end;
    else
      inherited;
  end;
end;

procedure TTaskbarButton.WMActivate(var Msg: TWMActivate);
begin
  inherited;
  // Restored some other way (e.g. Alt+Tab): back to minimized + popup
  if (Msg.Active <> WA_INACTIVE) and HandleAllocated and not IsIconic(Handle)
  then begin
    ShowWindow(Handle, SW_SHOWMINNOACTIVE);
    RequestClick;
  end;
end;

procedure TTaskbarButton.WMClose(var Msg: TWMClose);
begin
  // "Close window" from the taskbar: close the bar, not just this window
  if Assigned(FOnCloseRequest) then FOnCloseRequest(Self);
  Msg.Result := 0;
end;

procedure TTaskbarButton.WndProc(var Message: TMessage);
begin
  if (Message.Msg = LM_TASKBAR_CLICK)
  then begin
    // Ignore double notifications of the same click
    if (GetTickCount - FLastClick > 250)
    then begin
      FLastClick := GetTickCount;
      if Assigned(FOnClick) then FOnClick(Self);
    end;
    Message.Result := 0;
    Exit;
  end;
  inherited WndProc(Message);
end;

function IconFromPremultipliedBitmap(ABmp: HBITMAP): HICON;
var
  bm: Winapi.Windows.TBitmap;
  bmi: TBitmapInfo;
  bits, maskBits: Pointer;
  dib, mask: HBITMAP;
  w, h, i, maskSize: Integer;
  src, dst: PCardinal;
  c, a, r, g, b: Cardinal;
  ii: TIconInfo;
begin
  Result := 0;
  if (ABmp = 0) or (GetObject(ABmp, SizeOf(bm), @bm) = 0) then Exit;
  if (bm.bmBitsPixel <> 32) or (bm.bmBits = nil) then Exit;
  w := bm.bmWidth;
  h := Abs(bm.bmHeight);

  FillChar(bmi, SizeOf(bmi), 0);
  bmi.bmiHeader.biSize := SizeOf(bmi.bmiHeader);
  bmi.bmiHeader.biWidth := w;
  bmi.bmiHeader.biHeight := bm.bmHeight; // same row order as the source
  bmi.bmiHeader.biPlanes := 1;
  bmi.bmiHeader.biBitCount := 32;
  bmi.bmiHeader.biCompression := BI_RGB;
  bits := nil;
  dib := CreateDIBSection(0, bmi, DIB_RGB_COLORS, bits, 0, 0);
  if (dib = 0) or (bits = nil) then Exit;
  try
    // Icons want straight (not premultiplied) alpha
    src := bm.bmBits;
    dst := bits;
    for i := 0 to w * h - 1 do
    begin
      c := src^;
      a := c shr 24;
      if (a = 0)
      then dst^ := 0
      else begin
        r := ((c shr 16) and $FF) * 255 div a;
        g := ((c shr 8) and $FF) * 255 div a;
        b := (c and $FF) * 255 div a;
        if (r > 255) then r := 255;
        if (g > 255) then g := 255;
        if (b > 255) then b := 255;
        dst^ := (a shl 24) or (r shl 16) or (g shl 8) or b;
      end;
      Inc(src);
      Inc(dst);
    end;

    maskSize := ((w + 15) div 16) * 2 * h;
    GetMem(maskBits, maskSize);
    try
      FillChar(maskBits^, maskSize, 0);
      mask := CreateBitmap(w, h, 1, 1, maskBits);
    finally
      FreeMem(maskBits);
    end;
    try
      ii.fIcon := True;
      ii.xHotspot := 0;
      ii.yHotspot := 0;
      ii.hbmMask := mask;
      ii.hbmColor := dib;
      Result := CreateIconIndirect(ii);
    finally
      DeleteObject(mask);
    end;
  finally
    DeleteObject(dib);
  end;
end;

function LoadIconsFromSpec(const ASpec: string; out ABig, ASmall: HICON): Boolean;
var
  p, idx: Integer;
  path: string;
  buf: array[0..MAX_PATH] of Char;
begin
  ABig := 0;
  ASmall := 0;
  Result := False;
  if (Trim(ASpec) = '') then Exit;
  p := LastDelimiter(',', ASpec);
  if (p > 0) and TryStrToInt(Trim(Copy(ASpec, p + 1, MaxInt)), idx)
  then path := Trim(Copy(ASpec, 1, p - 1))
  else begin
    path := Trim(ASpec);
    idx := 0;
  end;
  if (ExpandEnvironmentStrings(PChar(path), buf, Length(buf)) > 0)
  then path := buf;
  if (ExtractIconEx(PChar(path), idx, ABig, ASmall, 1) = 0) then Exit;
  Result := (ABig <> 0) or (ASmall <> 0);
  if (ABig = 0) then ABig := CopyIcon(ASmall);
  if (ASmall = 0) then ASmall := CopyIcon(ABig);
end;

procedure GetTaskbarAnchor(out ARect: TRect; out AEdge: UINT);
var
  abd: TAppBarData;
  pt: TPoint;
begin
  GetCursorPos(pt);
  FillChar(abd, SizeOf(abd), 0);
  abd.cbSize := SizeOf(abd);
  if (SHAppBarMessage(ABM_GETTASKBARPOS, abd) <> 0) and PtInRect(abd.rc, pt)
  then begin
    AEdge := abd.uEdge;
    case AEdge of
      ABE_LEFT, ABE_RIGHT:
        ARect := Rect(abd.rc.Left, pt.Y - 1, abd.rc.Right, pt.Y + 1);
      else
        ARect := Rect(pt.X - 1, abd.rc.Top, pt.X + 1, abd.rc.Bottom);
    end;
  end
  else begin
    // Taskbar on another monitor or unknown: open above the mouse
    AEdge := ABE_BOTTOM;
    ARect := Rect(pt.X - 1, pt.Y - 1, pt.X + 1, pt.Y + 1);
  end;
end;

end.
