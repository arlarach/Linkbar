{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2021 Asaq               }
{*******************************************************}

unit LBToolbar;

{$i linkbar.inc}

{;$define CHACE_BB_ICON}                                                        // Chache Bit Bucket icon.
                                                                                // However, if the user changes the icon of the Bit Bucket, this is incorrect.
interface

uses
  Winapi.Windows, Winapi.ShlObj,
  System.SysUtils, System.Classes, Vcl.Graphics, Generics.Collections;

type
  TItemBase = class
  public type
     TKind = (None, Shortcut, Separator);
  private
    FKind: TKind;
  protected
    FBitmap: HBITMAP;                                                           // Shortcut icon
    FBitmapZoom: HBITMAP;                                                       // Bigger icon for the magnification effect
  private
    Shield: Boolean;                                                            // Have shild overlay
    BitBucket: Boolean;                                                         // Is bitbucket
  public
    Pidl: PItemIDList;
    FileName: string;
    Caption: string;
    Rect: TRect;
    Hash: Cardinal;
    NeedLoad: Boolean;
    TargetPath: string;   // .exe the shortcut points to (lower case), '' if none
    Running: Boolean;     // a window of TargetPath is open
  public
    property Kind: TKind read FKind;
    property Bitmap: HBITMAP read FBitmap;
    property BitmapZoom: HBITMAP read FBitmapZoom;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure DoExecute(AHandle: HWND); virtual;
    procedure DoPopupMenu(AHandle: HWND; const APoint: TPoint; AShift: Boolean = False; ASubMenu: HMENU = 0); virtual;
    function LoadFromFile(const AFileName: string): Boolean; virtual;
    procedure LoadIcon(const AIconSize: Integer); virtual;
    procedure LoadZoomIcon(const AIconSize: Integer); virtual;
    procedure FreeZoomIcon;
    function GetDropPart(const APoint: TPoint; const AVertical: Boolean; const ASideOnly: Boolean = False): Integer; virtual;
  end;

  TItemShortcut = class(TItemBase)
  public var
    Size: TSize;
  public
    constructor Create; override;
    procedure DoExecute(AHandle: HWND); override;
    procedure DoPopupMenu(AHandle: HWND; const APoint: TPoint; AShift: Boolean = False; ASubMenu: HMENU = 0); override;
    function LoadFromFile(const AFileName: string): Boolean; override;
    procedure LoadIcon(const AIconSize: Integer); override;
    procedure LoadZoomIcon(const AIconSize: Integer); override;
    function GetDropPart(const APoint: TPoint; const AVertical: Boolean; const ASideOnly: Boolean = False): Integer; override;
  end;

  { Group of shortcuts (Android-like folder). A sub-folder "<name>.group"
    in the links folder. Icon = 2x2 preview of its content. }
  TItemGroup = class(TItemShortcut)
  public
    MemberTargets: TArray<string>; // .exe targets of the members (for "program is open")
    class function IsGroupFile(const AFileName: string): Boolean; static;
    class function GetMemberFiles(const AFolder: string): TArray<string>; static;
    function LoadFromFile(const AFileName: string): Boolean; override;
    procedure LoadIcon(const AIconSize: Integer); override;
    procedure LoadZoomIcon(const AIconSize: Integer); override;
  end;

  TItemSeparator = class(TItemBase)
  private const
    SEPARATOR_CAPTION: string = '|';
  public var
    Size: Integer;
  public
    class function IsSeparator(const AFileName: string): Boolean; inline;
  public
    constructor Create; override;
    procedure DoPopupMenu(AHandle: HWND; const APoint: TPoint; AShift: Boolean = False; ASubMenu: HMENU = 0); override;
  end;

  TPanelSizes = record
    Button: TSize;
    Separator: Integer;
    Margin: Integer;
    Reserved: Integer; // space kept free at the end of the bar (CPU/RAM widgets)
    ZoomRoom: Integer;    // extra thickness for the magnification effect
    ZoomBefore: Boolean;  // the extra thickness is before the items (bottom/right bars)
  end;

  TLBItemList = class(TObjectList<TItemBase>)
  private
    BitmapShield: HBITMAP;                                                        // Shield overlay icon
{$ifdef CHACE_BB_ICON}
    BitmapBitBucket: HBITMAP;                                                     // <desktop>\Recycle Bin icon
{$endif}
    FIconSize: Integer;
    FZoomIconSize: Integer;
    FLineWidth: Integer;
    procedure SetIconSize(const AValue: Integer);
    procedure SetZoomIconSize(const AValue: Integer);
    procedure QuickSort(L, R: Integer);
  public
    Lines: TList<Integer>;
    Sizes: TPanelSizes;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Draw(AHdc: HDC;  const AItem: TItemBase; AX, AY: Integer);
    procedure DrawScaled(AHdc: HDC; const AItem: TItemBase; AX, AY, ASize: Integer);
    procedure LoadIcon(const AItem: TItemBase); inline;
    procedure BitBucketUpdateIcon;
    procedure Sort;
    procedure UpdateLines(const AVertical: Boolean; const AWidth, AHeight: Integer);
    function GetLineIndex(const AItemIndex: Integer): Integer;
  public
    property IconSize: Integer read FIconSize write SetIconSize;
    property ZoomIconSize: Integer read FZoomIconSize write SetZoomIconSize; // 0 = no zoom icons
    property LineWidth: Integer read FLineWidth;
  public
    class function IsSeparator(const AItem: TItemBase): Boolean; inline;
  end;

  function StrToHash(const AStr: string): Cardinal;
  function CreateItemForFile(const AFileName: string): TItemShortcut;
  { Lower-case paths of programs that have a visible top-level window }
  procedure CollectRunningExePaths(AList: TStringList);
  { Taskbar-like top-level windows of a program (stable order) }
  function GetProgramWindows(const AExePath: string): TArray<HWND>;
  { Bring a window to the front (restores it if minimized) }
  procedure SwitchToWindow(AWnd: HWND);
  { Click on an open program: activate it, minimize it if it was already in
    front (APrevForeground), or cycle through its windows. False = no window }
  function ActivateProgram(const AExePath: string; APrevForeground: HWND): Boolean;

  { Group background color, stored as "#RRGGBB" in "<group>\color" }
  function ReadGroupColor(const AFolder: string; out AColor: TColor): Boolean;
  { clNone = back to the default color }
  procedure WriteGroupColor(const AFolder: string; const AColor: TColor);


implementation

uses
  Winapi.ActiveX, Winapi.ShellAPI, Winapi.KnownFolders,
  System.Win.ComObj, System.Types, System.Math, Winapi.Dwmapi,
  Linkbar.OS, Linkbar.Consts, Linkbar.Shell, ExplorerMenu, Linkbar.Actions;

var FKnownFolderManager: IKnownFolderManager;

function CalcFNVHashFromString(const AData: string; AHash: Cardinal = 2166136261): Cardinal; inline;
var pData: PByte;
    count: Integer;
begin
  count := Length(AData) * SizeOf(Char);

  pData := PByte(PChar(AData));
  for var i := 1 to count do
  begin
    AHash := (AHash xor pData^) * 16777619;
    Inc(pData);
  end;
  Result := AHash;
end;

function StrToHash(const AStr: string): Cardinal;
begin
  Result := CalcFNVHashFromString(AnsiUpperCase(AStr));
end;

function CheckShield(const APidl: PItemIDList): Boolean;
var pExtract: IExtractIcon;
    location: array[0..MAX_PATH] of Char;
begin
  Result := False;
  if Succeeded(GetUIObjectOfPidl(0, APidl, IExtractIcon, Pointer(pExtract)))
  then begin
    var index := 0;
    var flags: UINT := 0;
    if (pExtract.GetIconLocation(GIL_CHECKSHIELD, location, MAX_PATH, index, flags) = S_OK)
    then Result := ((flags and GIL_SHIELD) > 0) and ((flags and GIL_FORCENOSHIELD) = 0);
    pExtract := nil;
  end;
end;

{ Path of the .exe a shortcut points to (lower case), '' if not an .exe shortcut }
function GetShortcutExeTarget(const APidl: PItemIDList): string;
var pLink: IShellLink;
    buf: array[0..MAX_PATH] of Char;
    fd: TWin32FindData;
begin
  Result := '';
  if Succeeded(GetUIObjectOfPidl(0, APidl, IShellLink, Pointer(pLink)))
  then begin
    FillChar(buf, SizeOf(buf), 0);
    if Succeeded(pLink.GetPath(buf, MAX_PATH, fd, 0))
       and SameText(ExtractFileExt(string(buf)), '.exe')
    then Result := AnsiLowerCase(string(buf));
    pLink := nil;
  end;
end;

function CheckBitBucket(const APidl: PItemIDList): Boolean;
var pKnownFolder: IKnownFolder;
    id: KNOWNFOLDERID;
    hr: HRESULT;
    pidl: PItemIDList;
    pLink: IShellLink;
begin
  Result := False;

  if not Assigned(FKnownFolderManager)
  then Exit;

  pidl := APidl;

  // resolve link
  if Succeeded(GetUIObjectOfPidl(0, APidl, IShellLink, Pointer(pLink)))
  then pLink.GetIDList(pidl);
  pLink := nil;

  hr := FKnownFolderManager.FindFolderFromIDList(pidl, pKnownFolder);

  if Assigned(pidl)
     and (pidl <> APidl)
  then CoTaskMemFree(pidl);

  Result := Succeeded(hr)
            and Assigned(pKnownFolder)
            and Succeeded(pKnownFolder.GetId(id))
            and (id = FOLDERID_RecycleBinFolder);
end;

procedure PreMultiply(const ABitmap: HBITMAP);
type
  TRGBAQuad = array[0..3] of Byte;
  PRGBAQuad = ^TRGBAQuad;
var bi: TBitmapInfo;
    dc: HDC;
    p: PByte;
    i, c: Integer;
    px: PRGBAQuad;
    alpha: Byte;
begin
  FillChar(bi, SizeOf(bi), 0);
  bi.bmiHeader.biSize := SizeOf(bi.bmiHeader);

  dc := CreateCompatibleDC(0);
  SelectObject(dc, ABitmap);

  // Get the BITMAPINFO structure from the bitmap
  if (GetDIBits(dc, ABitmap, 0, 0, nil, bi, DIB_RGB_COLORS) <> 0)
  then begin
    // create the pixel buffer
    p := GetMemory(bi.bmiHeader.biSizeImage);

    // We'll change the received BITMAPINFOHEADER to request the data in a
    // 32 bit RGB format (and not upside-down) so that we can iterate over
    // the pixels easily.

    // requesting a 32 bit image means that no stride/padding will be necessary,
    // although it always contains an (possibly unused) alpha channel
    bi.bmiHeader.biBitCount := 32;
    bi.bmiHeader.biCompression := BI_RGB;  // no compression -> easier to use
    // correct the bottom-up ordering of lines (abs is in cstdblib and stdlib.h)
    bi.bmiHeader.biHeight := abs(bi.bmiHeader.biHeight);

    // Call GetDIBits a second time, this time to (format and) store the actual
    // bitmap data (the "pixels") in the buffer p
    if(GetDIBits(dc, ABitmap, 0, bi.bmiHeader.biHeight, p, bi, DIB_RGB_COLORS) <> 0)
    then begin
      px := Pointer(UIntPtr(p));
      c := bi.bmiHeader.biHeight * bi.bmiHeader.biWidth;
      for i := 0 to c-1 do
      begin
        alpha := px[3];
        px[0] := MulDiv(px[0], alpha, 255);
        px[1] := MulDiv(px[1], alpha, 255);
        px[2] := MulDiv(px[2], alpha, 255);
        Inc(px);
      end;
      SetDIBits(dc, ABitmap, 0, bi.bmiHeader.biHeight, p, bi, DIB_RGB_COLORS);
    end;

    // clean up: deselect bitmap from device context, close handles, delete buffer
    FreeMemory(p);
  end;
  DeleteDC(dc);
end;

function LoadIconFromPidl(const APidl: PItemIDList; const AIconSize: Integer): HBITMAP;
var
  fileShellItemImage: IShellItemImageFactory;
begin
  Result := 0;
  var needUninitialize := Succeeded(CoInitializeEx(nil, COINIT_APARTMENTTHREADED or COINIT_DISABLE_OLE1DDE));
  try
    var hr := SHCreateItemFromIDList(APidl, IShellItemImageFactory, fileShellItemImage);
    if Succeeded(hr)
    then begin
      hr := fileShellItemImage.GetImage(TSize.Create(AIconSize, AIconSize),
        SIIGBF_ICONONLY or SIIGBF_BIGGERSIZEOK, Result);
      if Succeeded(hr)
      then begin
        // Bitmaps for Windows 8.1/10 require premultiply
        if IsWindows8Dot1OrAbove
        then PreMultiply(Result);
      end;
      fileShellItemImage := nil;
    end;
  finally
    if needUninitialize
    then CoUninitialize;
  end;
end;


{ TItemBase }

constructor TItemBase.Create;
begin
  FKind := TKind.None;

  FBitmap := 0;
  Shield := False;
  BitBucket := False;

  Pidl := nil;
  FileName := '';
  Caption := '';
  Rect := TRect.Empty;
  Hash := 0;
  NeedLoad := False;
end;

destructor TItemBase.Destroy;
begin
  CoTaskMemFree(Pidl);
  DeleteObject(FBitmap);
  FreeZoomIcon;
  inherited;
end;

procedure TItemBase.LoadZoomIcon(const AIconSize: Integer);
begin
end;

procedure TItemBase.FreeZoomIcon;
begin
  if (FBitmapZoom <> 0)
  then DeleteObject(FBitmapZoom);
  FBitmapZoom := 0;
end;

procedure TItemBase.DoExecute(AHandle: HWND);
begin
end;

procedure TItemBase.DoPopupMenu(AHandle: HWND; const APoint: TPoint; AShift: Boolean = False; ASubMenu: HMENU = 0);
begin
end;

function TItemBase.LoadFromFile(const AFileName: string): Boolean;
begin
  Result := False;
end;

procedure TItemBase.LoadIcon(const AIconSize: Integer);
begin
end;

function TItemBase.GetDropPart(const APoint: TPoint; const AVertical: Boolean; const ASideOnly: Boolean): Integer;
begin
  if AVertical
  then begin
    if (APoint.Y < Rect.CenterPoint.Y)
    then Result := -1
    else Result :=  1;
  end
  else begin
    if (APoint.X < Rect.CenterPoint.X)
    then Result := -1
    else Result :=  1;
  end;
end;


{ TItemShortcut }

constructor TItemShortcut.Create;
begin
  inherited;
  FKind := TKind.Shortcut;
end;

function TItemShortcut.LoadFromFile(const AFileName: string): Boolean;
begin
  CoTaskMemFree(Pidl);

  if SHParseDisplayName(PChar(AFileName), nil, Pidl, 0, PDWORD(nil)^) = S_OK
  then begin
    FileName := AFileName;
    Hash := StrToHash(ExtractFileName(FileName));

    var ppszName: PChar := nil;
    if Succeeded(SHGetNameFromIDList(Pidl, SIGDN_NORMALDISPLAY, ppszName))
    then begin
      Caption := string(ppszName);
      CoTaskMemFree(ppszName);
    end;

    Shield := CheckShield(Pidl);

    BitBucket := CheckBitBucket(Pidl);

    TargetPath := GetShortcutExeTarget(Pidl);

    Exit(True);
  end;

  Result := False;
end;

procedure TItemShortcut.LoadIcon(const AIconSize: Integer);
begin
  DeleteObject(FBitmap);
  FBitmap := 0;
{$ifdef CHACE_BB_ICON}
  if BitBucket
  then Exit;
{$endif}
  FBitmap := LoadIconFromPidl(Pidl, AIconSize);
end;

procedure TItemShortcut.LoadZoomIcon(const AIconSize: Integer);
begin
  FreeZoomIcon;
  FBitmapZoom := LoadIconFromPidl(Pidl, AIconSize);
end;

procedure TItemShortcut.DoExecute(AHandle: HWND);
begin
  OpenByDefaultVerb(AHandle, Pidl);
end;

procedure TItemShortcut.DoPopupMenu(AHandle: HWND; const APoint: TPoint; AShift: Boolean = False; ASubMenu: HMENU = 0);
begin
  ExplorerMenuPopup(AHandle, Pidl, APoint, AShift, ASubMenu);
end;


function TItemShortcut.GetDropPart(const APoint: TPoint; const AVertical: Boolean; const ASideOnly: Boolean): Integer;
var
  part0sz, part1sz: Integer;
begin
  if ASideOnly
  then begin
    Result := inherited GetDropPart(APoint, AVertical, ASideOnly);
    Exit;
  end;

  Result := 0;

  if AVertical
  then begin
    part0sz := (Rect.Height div 3) * 2;
    part1sz := (Rect.Height - part0sz) div 2;

    if (APoint.Y < (Rect.Top + part1sz))
    then Result := -1
    else if (APoint.Y >= (Rect.Top + part1sz + part0sz))
         then Result := 1
  end
  else begin
    part0sz := (Rect.Width div 3) * 2;
    part1sz := (Rect.Width - part0sz) div 2;

    if (APoint.X < (Rect.Left + part1sz))
    then Result := -1
    else if (APoint.X >= (Rect.Left + part1sz + part0sz))
         then Result := 1
  end;
end;

{ TItemGroup }

function CreateItemForFile(const AFileName: string): TItemShortcut;
begin
  if TItemGroup.IsGroupFile(AFileName)
  then Result := TItemGroup.Create
  else if IsActionFile(AFileName)
  then Result := TItemAction.Create
  else Result := TItemShortcut.Create;
end;

class function TItemGroup.IsGroupFile(const AFileName: string): Boolean;
begin
  Result := SameText(ExtractFileExt(ExcludeTrailingPathDelimiter(AFileName)), ES_GROUP);
end;

{ Members of a group: custom order from "<group>\list" (if the user reordered),
  then the remaining files in alphabetical order }
class function TItemGroup.GetMemberFiles(const AFolder: string): TArray<string>;
var
  sr: TSearchRec;
  found, order, res: TStringList;
  dir, ext, name: string;
  idx: Integer;
begin
  dir := IncludeTrailingPathDelimiter(AFolder);
  found := TStringList.Create;
  order := TStringList.Create;
  res := TStringList.Create;
  try
    found.CaseSensitive := False;
    for ext in ES_ARRAY do
    begin
      if (FindFirst(dir + '*' + ext, faAnyFile, sr) = 0)
      then begin
        repeat
          if ((sr.Attr and faDirectory) = 0)
          then found.Add(sr.Name);
        until (FindNext(sr) <> 0);
        FindClose(sr);
      end;
    end;
    // Sub-groups (folders "<name>.group")
    if (FindFirst(dir + '*' + ES_GROUP, faDirectory, sr) = 0)
    then begin
      repeat
        if ((sr.Attr and faDirectory) <> 0)
        then found.Add(sr.Name);
      until (FindNext(sr) <> 0);
      FindClose(sr);
    end;

    found.Sort;

    // Custom order first
    if FileExists(dir + LINKSLIST_FILE_NAME)
    then begin
      try
        order.LoadFromFile(dir + LINKSLIST_FILE_NAME, TEncoding.UTF8);
      except
        order.Clear;
      end;
      for name in order do
      begin
        idx := found.IndexOf(Trim(name));
        if (idx >= 0)
        then begin
          res.Add(dir + found[idx]);
          found.Delete(idx);
        end;
      end;
    end;

    // New/unordered files at the end, alphabetical
    for name in found do
      res.Add(dir + name);

    Result := res.ToStringArray;
  finally
    res.Free;
    order.Free;
    found.Free;
  end;
end;

function TItemGroup.LoadFromFile(const AFileName: string): Boolean;
begin
  Result := inherited LoadFromFile(AFileName);
  if Result
  then Caption := ChangeFileExt(ExtractFileName(ExcludeTrailingPathDelimiter(AFileName)), '');
end;

{ ---------- group color ---------- }

function ReadGroupColor(const AFolder: string; out AColor: TColor): Boolean;
var
  sl: TStringList;
  s: string;
  v: Integer;
  fn: string;
begin
  Result := False;
  AColor := clNone;
  fn := IncludeTrailingPathDelimiter(AFolder) + GROUPCOLOR_FILE_NAME;
  if not FileExists(fn)
  then Exit;
  sl := TStringList.Create;
  try
    try
      sl.LoadFromFile(fn);
    except
      Exit;
    end;
    if (sl.Count = 0) then Exit;
    s := Trim(sl[0]);
    if (s <> '') and (s[1] = '#') then Delete(s, 1, 1);
    if (Length(s) <> 6) or (not TryStrToInt('$' + s, v))
    then Exit;
    // #RRGGBB -> TColor ($00BBGGRR)
    AColor := TColor(RGB((v shr 16) and $FF, (v shr 8) and $FF, v and $FF));
    Result := True;
  finally
    sl.Free;
  end;
end;

procedure WriteGroupColor(const AFolder: string; const AColor: TColor);
var
  sl: TStringList;
  fn: string;
  c: Cardinal;
begin
  fn := IncludeTrailingPathDelimiter(AFolder) + GROUPCOLOR_FILE_NAME;
  if (AColor = clNone) or (AColor = clDefault)
  then begin
    System.SysUtils.DeleteFile(fn);
    Exit;
  end;
  c := ColorToRGB(AColor);
  sl := TStringList.Create;
  try
    sl.Add(Format('#%.2X%.2X%.2X', [GetRValue(c), GetGValue(c), GetBValue(c)]));
    try
      sl.SaveToFile(fn);
    except
      // read-only folder: ignore
    end;
  finally
    sl.Free;
  end;
end;

{ Group icon: rounded translucent square with up to 4 mini icons (2x2) }
function CreateGroupIcon(const AFolder: string; const AIconSize: Integer): HBITMAP;
var
  bmi: TBitmapInfo;
  bits: Pointer;
  px: PCardinal;
  x, y, i, n, pad, cell, radius: Integer;
  fx, fy, dx, dy, d, cov, baseA: Double;
  a, c: Cardinal;
  white, custom: Boolean;
  gc: TColor;
  cr, cg, cb: Cardinal;
  files: TArray<string>;
  dc, srcDc: HDC;
  old, oldSrc: HGDIOBJ;
  pidl: PItemIDList;
  ico: HBITMAP;
  bm: Winapi.Windows.TBitmap;
  bf: TBlendFunction;
begin
  Result := 0;
  if (AIconSize <= 0)
  then Exit;

  FillChar(bmi, SizeOf(bmi), 0);
  bmi.bmiHeader.biSize := SizeOf(bmi.bmiHeader);
  bmi.bmiHeader.biWidth := AIconSize;
  bmi.bmiHeader.biHeight := -AIconSize; // top-down
  bmi.bmiHeader.biPlanes := 1;
  bmi.bmiHeader.biBitCount := 32;
  bmi.bmiHeader.biCompression := BI_RGB;
  bits := nil;
  Result := CreateDIBSection(0, bmi, DIB_RGB_COLORS, bits, 0, 0);
  if (Result = 0) or (bits = nil)
  then Exit;

  // Background (premultiplied ARGB)
  white := (GlobalLook <> ELookLight);
  if white
  then baseA := 0.22
  else baseA := 0.12;
  radius := AIconSize div 4;
  if (radius < 2) then radius := 2;

  // Custom group color: almost opaque tile of that color
  custom := ReadGroupColor(AFolder, gc);
  cr := 0; cg := 0; cb := 0;
  if custom
  then begin
    baseA := 0.90;
    cr := GetRValue(Cardinal(gc));
    cg := GetGValue(Cardinal(gc));
    cb := GetBValue(Cardinal(gc));
  end;

  px := bits;
  for y := 0 to AIconSize-1 do
    for x := 0 to AIconSize-1 do
    begin
      fx := x + 0.5;
      fy := y + 0.5;
      dx := 0;
      if (fx < radius) then dx := radius - fx
      else if (fx > AIconSize - radius) then dx := fx - (AIconSize - radius);
      dy := 0;
      if (fy < radius) then dy := radius - fy
      else if (fy > AIconSize - radius) then dy := fy - (AIconSize - radius);
      d := Sqrt(dx*dx + dy*dy);
      cov := radius - d + 0.5;
      if (cov < 0) then cov := 0;
      if (cov > 1) then cov := 1;
      a := Cardinal(Round(255 * baseA * cov));
      if custom
      then px^ := (a shl 24) or (((cr * a) div 255) shl 16) or (((cg * a) div 255) shl 8) or ((cb * a) div 255)
      else begin
        if white
        then c := a
        else c := 0;
        px^ := (a shl 24) or (c shl 16) or (c shl 8) or c;
      end;
      Inc(px);
    end;

  // Mini icons
  files := TItemGroup.GetMemberFiles(AFolder);
  n := Length(files);
  if (n > 4) then n := 4;
  if (n = 0)
  then Exit;

  pad := AIconSize div 10;
  if (pad < 1) then pad := 1;
  cell := (AIconSize - pad*3) div 2;
  if (cell < 4)
  then Exit;

  bf.BlendOp := AC_SRC_OVER;
  bf.BlendFlags := 0;
  bf.SourceConstantAlpha := 255;
  bf.AlphaFormat := AC_SRC_ALPHA;

  dc := CreateCompatibleDC(0);
  srcDc := CreateCompatibleDC(0);
  old := SelectObject(dc, Result);
  try
    for i := 0 to n-1 do
    begin
      pidl := nil;
      if (SHParseDisplayName(PChar(files[i]), nil, pidl, 0, PDWORD(nil)^) = S_OK)
      then try
        ico := LoadIconFromPidl(pidl, cell);
        if (ico <> 0)
        then try
          if (GetObject(ico, SizeOf(bm), @bm) <> 0)
          then begin
            x := pad + (i mod 2) * (cell + pad);
            y := pad + (i div 2) * (cell + pad);
            oldSrc := SelectObject(srcDc, ico);
            Winapi.Windows.AlphaBlend(dc, x, y, cell, cell, srcDc, 0, 0, bm.bmWidth, Abs(bm.bmHeight), bf);
            SelectObject(srcDc, oldSrc);
          end;
        finally
          DeleteObject(ico);
        end;
      finally
        CoTaskMemFree(pidl);
      end;
    end;
  finally
    SelectObject(dc, old);
    DeleteDC(srcDc);
    DeleteDC(dc);
  end;
end;

procedure TItemGroup.LoadZoomIcon(const AIconSize: Integer);
begin
  FreeZoomIcon;
  FBitmapZoom := CreateGroupIcon(FileName, AIconSize);
end;

procedure TItemGroup.LoadIcon(const AIconSize: Integer);
var
  files: TArray<string>;
  i: Integer;
  pidl: PItemIDList;
begin
  DeleteObject(FBitmap);
  FBitmap := CreateGroupIcon(FileName, AIconSize);

  // Cache member targets (used by the "program is open" indicator)
  files := GetMemberFiles(FileName);
  SetLength(MemberTargets, Length(files));
  for i := 0 to High(files) do
  begin
    MemberTargets[i] := '';
    pidl := nil;
    if (SHParseDisplayName(PChar(files[i]), nil, pidl, 0, PDWORD(nil)^) = S_OK)
    then try
      MemberTargets[i] := GetShortcutExeTarget(pidl);
    finally
      CoTaskMemFree(pidl);
    end;
  end;
end;

{ ---------- running programs ---------- }

const
  LB_PROCESS_QUERY_LIMITED_INFORMATION = $1000;

function LB_QueryFullProcessImageName(hProcess: THandle; dwFlags: DWORD;
  lpExeName: PWideChar; var lpdwSize: DWORD): BOOL; stdcall;
  external kernel32 name 'QueryFullProcessImageNameW';

procedure LB_SwitchToThisWindow(hWnd: HWND; fAltTab: BOOL); stdcall;
  external user32 name 'SwitchToThisWindow';

{ Window that would appear on the taskbar }
function IsTaskWindow(wnd: HWND): Boolean;
const LB_DWMWA_CLOAKED = 14;
var cloaked: DWORD;
begin
  Result := IsWindowVisible(wnd)
    and (GetWindow(wnd, GW_OWNER) = 0)
    and ((GetWindowLongPtr(wnd, GWL_EXSTYLE) and WS_EX_TOOLWINDOW) = 0);
  if Result and IsWindows8OrAbove
  then begin
    // hidden UWP windows / other virtual desktops
    cloaked := 0;
    if Succeeded(DwmGetWindowAttribute(wnd, LB_DWMWA_CLOAKED, @cloaked, SizeOf(cloaked)))
       and (cloaked <> 0)
    then Result := False;
  end;
end;

function EnumTaskWindowsProc(wnd: HWND; lParam: LPARAM): BOOL; stdcall;
begin
  Result := True;
  if IsTaskWindow(wnd)
  then TList<HWND>(Pointer(lParam)).Add(wnd);
end;

function GetTaskWindows: TArray<HWND>;
var list: TList<HWND>;
begin
  list := TList<HWND>.Create;
  try
    EnumWindows(@EnumTaskWindowsProc, LPARAM(Pointer(list)));
    Result := list.ToArray;
  finally
    list.Free;
  end;
end;

function GetProcessExePath(APid: DWORD): string;
var
  h: THandle;
  buf: array[0..MAX_PATH] of Char;
  size: DWORD;
begin
  Result := '';
  h := OpenProcess(LB_PROCESS_QUERY_LIMITED_INFORMATION, False, APid);
  if (h <> 0)
  then try
    size := MAX_PATH;
    if LB_QueryFullProcessImageName(h, 0, buf, size)
    then Result := AnsiLowerCase(Copy(string(buf), 1, size));
  finally
    CloseHandle(h);
  end;
end;

{ Calls AProc for every task window with the exe path of its process }
type
  TWindowExeProc = reference to procedure(AWnd: HWND; const AExePath: string);

procedure ForEachTaskWindow(const AProc: TWindowExeProc);
var
  cache: TDictionary<DWORD, string>;
  wnd: HWND;
  pid: DWORD;
  path: string;
begin
  cache := TDictionary<DWORD, string>.Create;
  try
    for wnd in GetTaskWindows do
    begin
      pid := 0;
      GetWindowThreadProcessId(wnd, pid);
      if (pid = 0) then Continue;
      if not cache.TryGetValue(pid, path)
      then begin
        path := GetProcessExePath(pid);
        cache.Add(pid, path);
      end;
      if (path <> '')
      then AProc(wnd, path);
    end;
  finally
    cache.Free;
  end;
end;

procedure CollectRunningExePaths(AList: TStringList);
var list: TStringList;
begin
  AList.Clear;
  AList.Sorted := True;
  AList.Duplicates := dupIgnore;
  AList.CaseSensitive := False;
  list := AList;
  ForEachTaskWindow(
    procedure(AWnd: HWND; const AExePath: string)
    begin
      list.Add(AExePath);
    end);
end;

function GetProgramWindows(const AExePath: string): TArray<HWND>;
var list: TList<HWND>;
begin
  list := TList<HWND>.Create;
  try
    ForEachTaskWindow(
      procedure(AWnd: HWND; const APath: string)
      begin
        if SameText(APath, AExePath)
        then list.Add(AWnd);
      end);
    list.Sort; // stable order by handle, so repeated clicks cycle
    Result := list.ToArray;
  finally
    list.Free;
  end;
end;

procedure SwitchToWindow(AWnd: HWND);
begin
  if IsIconic(AWnd)
  then ShowWindow(AWnd, SW_RESTORE);
  LB_SwitchToThisWindow(AWnd, True);
  SetForegroundWindow(AWnd);
end;

function ActivateProgram(const AExePath: string; APrevForeground: HWND): Boolean;
var
  wnds: TArray<HWND>;
  i, idx: Integer;
begin
  Result := False;
  if (AExePath = '')
  then Exit;
  wnds := GetProgramWindows(AExePath);
  if (Length(wnds) = 0)
  then Exit;
  Result := True;

  idx := -1;
  for i := 0 to High(wnds) do
    if (wnds[i] = APrevForeground)
    then idx := i;

  if (idx < 0)
  then SwitchToWindow(wnds[0])                         // not in front: activate
  else if (Length(wnds) = 1)
  then ShowWindow(wnds[0], SW_MINIMIZE)                // already in front: minimize
  else SwitchToWindow(wnds[(idx + 1) mod Length(wnds)]); // several: next one
end;

{ TItemSeparator }

constructor TItemSeparator.Create;
begin
  inherited;
  FKind := TKind.Separator;
  Caption := SEPARATOR_CAPTION;
  FileName := SEPARATOR_CAPTION;
end;

procedure TItemSeparator.DoPopupMenu(AHandle: HWND; const APoint: TPoint; AShift: Boolean = False; ASubMenu: HMENU = 0);
begin
  var menu := CreatePopupMenu;
  try
    var Flags: UINT := MF_BYCOMMAND or MF_STRING;
    AppendMenu(menu, Flags, 1, 'Delete');

    var command := TrackPopupMenuEx(menu, TPM_RETURNCMD or TPM_RIGHTBUTTON or TPM_NONOTIFY, APoint.X, APoint.Y, AHandle, nil);

    if (command)
    then PostMessage(AHandle, LM_CM_DELETE, 0, 0);
  finally
    DestroyMenu(menu);
  end;
end;

class function TItemSeparator.IsSeparator(const AFileName: string): Boolean;
begin
  Result := SameText(AFileName, TItemSeparator.SEPARATOR_CAPTION);
end;

////////////////////////////////////////////////////////////////////////////////
// TLBItemList
////////////////////////////////////////////////////////////////////////////////

class function TLBItemList.IsSeparator(const AItem: TItemBase): Boolean;
begin
  Result := (AItem.Kind = TItemBase.TKind.Separator);
end;

constructor TLBItemList.Create;
begin
  inherited Create(True);
  BitmapShield := 0;
{$ifdef CHACE_BB_ICON}
  BitmapBitBucket := 0;
{$endif}
  CoCreateInstance(CLSID_KnownFolderManager, nil, CLSCTX_ALL, IKnownFolderManager, FKnownFolderManager);
  Lines := TList<Integer>.Create;
  Lines.Capacity := 16;
end;

destructor TLBItemList.Destroy;
begin
  DeleteObject(BitmapShield);
{$ifdef CHACE_BB_ICON}
  DeleteObject(BitmapBitBucket);
{$endif}
  FKnownFolderManager := nil;
  Lines.Free;
  inherited;
end;

procedure TLBItemList.UpdateLines(const AVertical: Boolean; const AWidth, AHeight: Integer);
var
  count, x, y, margin: Integer;
  offset: TPoint;
  r: TRect;
  availW, availH: Integer;
begin
  // Area available for items (end of the bar may be reserved for widgets)
  availW := AWidth;
  availH := AHeight;
  if AVertical
  then availH := AHeight - Sizes.Reserved
  else availW := AWidth - Sizes.Reserved;

  // Set item width and height
  for var item in Self
  do begin
    item.Rect := TRect.Empty;
    if IsSeparator(item)
    then begin
      if (AVertical)
      then item.Rect.BottomRight := TPoint.Create(Sizes.Button.cx, Sizes.Separator)
      else item.Rect.BottomRight := TPoint.Create(Sizes.Separator, Sizes.Button.cy);
    end
    else item.Rect.BottomRight := TPoint.Create(Sizes.Button.cx, Sizes.Button.cy);
  end;

  margin := Sizes.Margin;

  if (AVertical)
  then begin
    x := 0;
    if Sizes.ZoomBefore then x := Sizes.ZoomRoom;
    y := margin;
  end else
  begin
    x := margin;
    y := 0;
    if Sizes.ZoomBefore then y := Sizes.ZoomRoom;
  end;

  count := 0;
  Lines.Clear;

  for var i := 0 to Self.Count-1
  do begin
    Inc(count);

    r := Self[i].Rect;

    // Calc item bounds
    r.Offset(x, y);  // because TopLeft = (0, 0)

    // Calc next item position
    if (AVertical)
    then begin
      Inc(y, r.Height);
      if (i < (Self.Count - 1))
         and ((y + Self[i+1].Rect.Height) > availH)
      then begin
        y := margin;
        Inc(x, r.Width);

        Lines.Add(count);
        count := 0;
      end;
    end
    else begin
      Inc(x, r.Width);
      if (i < (Self.Count - 1))
         and ((x + Self[i+1].Rect.Width) > availW)
      then begin
        x := margin;
        Inc(y, r.Height);

        Lines.Add(count);
        count := 0;
      end
    end;

    Self[i].Rect := r;
  end;

  if (count > 0)
  then Lines.Add(count);

  if (Lines.Count = 0)
  then Lines.Add(0);

  // Calc first line width
  if (Lines[0] = 0)
  then
    FLineWidth := 0
  else begin
    if (AVertical)
    then FLineWidth := Self[Lines[0]-1].Rect.Bottom - Self[0].Rect.Top
    else FLineWidth := Self[Lines[0]-1].Rect.Right - Self[0].Rect.Left;
  end;

  // Align items
  if (GlobalLayout = EPanelLayoutCenter)
     and (Lines.Count = 1)
  then begin
    offset := TPoint.Zero;
    if (AVertical)
    then offset.Y := ((availH - FLineWidth) div 2) - margin
    else offset.X := ((availW - FLineWidth) div 2) - margin;

    for var item in Self
    do item.Rect.Offset(offset);
  end
end;

function TLBItemList.GetLineIndex(const AItemIndex: Integer): Integer;
var temp: Integer;
begin
  temp := 0;
  for var i := 0 to Lines.Count-1
  do begin
    Inc(temp, Lines[i]);
    if AItemIndex < temp
    then Exit(i);
  end;
  Result := 0;
end;

// Creates a shield icon in the bottom/right corner
function GetShieldOverlay(AHdc: HDC; const APath: PChar; AIndex, AIconSize: Integer): HBITMAP; inline;
var bi: TBitmapInfo;
    rc: TRect;
    bits: Pointer;
    bmp: HBITMAP;
    bmp0: HGDIOBJ;
    ico: HICON;
begin
  FillChar(bi, SizeOf(bi), 0);
  bi.bmiHeader.biSize := sizeof(BITMAPINFOHEADER);
  bi.bmiHeader.biWidth := AIconSize;
  bi.bmiHeader.biHeight := AIconSize;
  bi.bmiHeader.biPlanes := 1;
  bi.bmiHeader.biBitCount := 32;
  rc := TRect.Create(0, 0, AIconSize, AIconSize);

  bmp := CreateDIBSection(AHdc, &bi, DIB_RGB_COLORS, bits, 0, 0);
  bmp0 := SelectObject(AHdc, bmp);
  FillRect(AHdc, rc, GetStockObject(BLACK_BRUSH));
  ico := ShExtractIcon(APath, AIndex, AIconSize div 2);
  if (ico > 0)
  then begin
    DrawIconEx(AHdc, rc.CenterPoint.X, rc.CenterPoint.Y, ico, AIconSize div 2, AIconSize div 2, 0, 0, DI_NORMAL);
    DestroyIcon(ico);
  end;
  SelectObject(AHdc, bmp0);
  Result := bmp;
end;

procedure TLBItemList.BitBucketUpdateIcon;
begin
{$ifdef CHACE_BB_ICON}
  DeleteObject(BitmapBitBucket); // free old
  BitmapBitBucket := 0;

  var pidl: PItemIDList := nil;
  if Failed(SHGetKnownFolderIDList(FOLDERID_RecycleBinFolder, 0, 0, pidl))
     or (pidl = nil)
  then Exit;

  BitmapBitBucket := LoadIconFromPidl(pidl, FIconSize);
  CoTaskMemFree(pidl);
{$else}
  for var item in Self do
  begin
    if item.BitBucket
    then LoadIcon(item);
  end;
{$endif}
end;

procedure TLBItemList.SetIconSize(const AValue: Integer);
begin
  if (FIconSize = AValue)
  then Exit;

  FIconSize := AValue;

  { Add shield overlay icon }
  var sii: TSHStockIconInfo := Default(TSHStockIconInfo);
  sii.cbSize := SizeOf(sii);
  var dc := CreateCompatibleDC(0);
  SHGetStockIconInfo(SIID_SHIELD, SHGSI_ICONLOCATION, sii);
  DeleteObject(BitmapShield); // free old
  BitmapShield := GetShieldOverlay(dc, sii.szPath, sii.iIcon, FIconSize);
  DeleteDC(dc);

{$ifdef CHACE_BB_ICON}
  { Get bitbucket icon }
  BitBucketUpdateIcon;
{$endif}

  { Update item icons }
  for var item in Self do LoadIcon(item);
end;

procedure TLBItemList.LoadIcon(const AItem: TItemBase);
begin
  AItem.LoadIcon(FIconSize);
  if (FZoomIconSize > FIconSize)
  then AItem.LoadZoomIcon(FZoomIconSize)
  else AItem.FreeZoomIcon;
end;

procedure TLBItemList.SetZoomIconSize(const AValue: Integer);
begin
  if (FZoomIconSize = AValue)
  then Exit;
  FZoomIconSize := AValue;
  for var item in Self do
  begin
    if (FZoomIconSize > FIconSize)
    then item.LoadZoomIcon(FZoomIconSize)
    else item.FreeZoomIcon;
  end;
end;

{ Draw the icon at any size (magnification). Uses the big icon when enlarged }
procedure TLBItemList.DrawScaled(AHdc: HDC; const AItem: TItemBase; AX, AY, ASize: Integer);
const bf: TBlendFunction = (BlendOp: AC_SRC_OVER; BlendFlags: 0; SourceConstantAlpha: 255; AlphaFormat: AC_SRC_ALPHA);
var
  src: HBITMAP;
  bm: Winapi.Windows.TBitmap;
  dc: HDC;
  bmp0: HGDIOBJ;
begin
  if (ASize <= FIconSize) or (AItem.FBitmapZoom = 0)
  then src := AItem.FBitmap
  else src := AItem.FBitmapZoom;
  if (src = 0) or (GetObject(src, SizeOf(bm), @bm) = 0)
  then Exit;

  dc := CreateCompatibleDC(AHdc);
  bmp0 := SelectObject(dc, src);
  Winapi.Windows.AlphaBlend(AHdc, AX, AY, ASize, ASize, dc, 0, 0, bm.bmWidth, Abs(bm.bmHeight), bf);
  SelectObject(dc, bmp0);

  if AItem.Shield and (BitmapShield <> 0)
  then begin
    bmp0 := SelectObject(dc, BitmapShield);
    Winapi.Windows.AlphaBlend(AHdc, AX, AY, ASize, ASize, dc, 0, 0, FIconSize, FIconSize, bf);
    SelectObject(dc, bmp0);
  end;
  DeleteDC(dc);
end;

procedure TLBItemList.Draw(AHdc: HDC; const AItem: TItemBase; AX, AY: Integer);
const bf: TBlendFunction = (BlendOp: AC_SRC_OVER; BlendFlags: 0; SourceConstantAlpha: 255; AlphaFormat: AC_SRC_ALPHA);
var
  bmp0: HGDIOBJ;
begin
  var dc := CreateCompatibleDC(AHdc);

{$ifdef CHACE_BB_ICON}
  if AItem.BitBucket
  then bmp0 := SelectObject(dc, BitmapBitBucket) else
{$endif}
  bmp0 := SelectObject(dc, AItem.Bitmap);

  // Draw icon
  Winapi.Windows.AlphaBlend(AHdc, AX, AY, FIconSize, FIconSize, dc, 0, 0, FIconSize, FIconSize, bf);
  SelectObject(dc, bmp0);

  // Draw shield
  if (AItem.Shield)
  then begin
    bmp0 := SelectObject(dc, BitmapShield);
    Winapi.Windows.AlphaBlend(AHdc, AX, AY, FIconSize, FIconSize, dc, 0, 0, FIconSize, FIconSize, bf);
    SelectObject(dc, bmp0);
  end;

  DeleteDC(dc);
end;

function StrCmpLogicalW(psz1, psz2: PWideChar): Integer; stdcall; external 'shlwapi.dll';

function SortCompareLogical(const List: TLBItemList; Index1, Index2: Integer): Integer; inline;
begin
  Result := StrCmpLogicalW(PChar(List[Index1].Caption), PChar(List[Index2].Caption));
end;

procedure TLBItemList.QuickSort(L, R: Integer);
var
  I, J, P: Integer;
begin
  repeat
    I := L;
    J := R;
    P := (L + R) shr 1;
    repeat
      while SortCompareLogical(Self, I, P) < 0 do Inc(I);
      while SortCompareLogical(Self, J, P) > 0 do Dec(J);
      if (I <= J)
      then begin
        if (I <> J)
        then Self.Exchange(I, J);
        if (P = I)
        then P := J
        else if (P = J)
             then P := I;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if (L < J)
    then QuickSort(L, J);
    L := I;
  until I >= R;
end;

procedure TLBItemList.Sort;
var
  separators: Tlist<Integer>;
begin
  // Collect separated groups
  // 2 virtual first and last seperators
  separators := Tlist<Integer>.Create;
  separators.Capacity := Self.Count + 2;
  separators.Add(-1);

  for var i := 0 to Self.Count-1
  do begin
    if IsSeparator(Self[i])
    then separators.Add(i);
  end;

  separators.Add(Self.Count);

  // Sort groups
  for var i := 0 to separators.Count-2
  do begin
    const l = separators[i] + 1;
    const r = separators[i+1] - 1;
    if (r - l) >= 2
    then QuickSort(l, r);
  end;

  separators.Free;
end;

end.
