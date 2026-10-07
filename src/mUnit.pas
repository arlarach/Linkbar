{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2021 Asaq               }
{*******************************************************}

unit mUnit;

{$i linkbar.inc}

interface

uses
  GdiPlus,
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  System.UITypes, Menus, Vcl.ExtCtrls, Winapi.ShlObj,
  DDForms, Cromis.DirectoryWatch,
  AccessBar, LBToolbar, Linkbar.Consts, Linkbar.Hint, Linkbar.Taskbar, HotKey,
  Linkbar.Graphics;

type
  TLinkbarWcl = class(TLinkbarCustomFrom)
    pMenu: TPopupMenu;
    imClose: TMenuItem;
    imProperties: TMenuItem;
    imNewLinkbar: TMenuItem;
    imRemoveBar: TMenuItem;
    N1: TMenuItem;
    N2: TMenuItem;
    imNewShortcut: TMenuItem;
    tmrUpdate: TTimer;
    imCloseAll: TMenuItem;
    imOpenWorkdir: TMenuItem;
    imLockBar: TMenuItem;
    N3: TMenuItem;
    imSortAlphabet: TMenuItem;
    imNewSeparator: TMenuItem;
    imNewGroup: TMenuItem;
    imNew: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormMouseLeave(Sender: TObject);
    procedure FormMouseEnter(Sender: TObject);
    procedure imPropertiesClick(Sender: TObject);
    procedure imRemoveBarClick(Sender: TObject);
    procedure imCloseClick(Sender: TObject);
    procedure imNewLinkbarClick(Sender: TObject);
    procedure imNewShortcutClick(Sender: TObject);
    procedure tmrUpdateTimer(Sender: TObject);
    procedure imCloseAllClick(Sender: TObject);
    procedure imOpenWorkdirClick(Sender: TObject);
    procedure imLockBarClick(Sender: TObject);
    procedure FormContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure imSortAlphabetClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormResize(Sender: TObject);
    procedure imNewSeparatorClick(Sender: TObject);
    procedure imNewGroupClick(Sender: TObject);
  private
    BitmapSelected: THBitmap;
    BitmapDropPosition: THBitmap;
    BitmapButton: THBitmap;
    BitmapPanel: THBitmap;
    Items: TLBItemList;
    oAppBar : TAccessBar;
    ToolTip: TTooltip32;
    FCreated: Boolean;
    FHotIndex: Integer;
    FPressedIndex: Integer;
    FMousePosDown: TPoint;
    FMousePosUp: TPoint;
    FMouseLeftDown: Boolean;
    FMouseDragLinkbar: Boolean;
    FMouseDragItem: Boolean;
    FBeforeDragBounds: TRect;
    FDragingItem: Boolean;
    FAutoHide: Boolean;
    FAutoHideTransparency: Boolean;
    FAutoShowMode: TAutoShowMode;
    FButtonSize: TSize;
    FEnableAeroGlass: Boolean;
    FGripSize: Integer;
    FTooltipShow: Boolean;
    FModernStyle: Boolean;
    FExtDragIcon: HBITMAP;
    FShowSysWidgets: Boolean;
    FBarStyle: Integer;          // BAR_STYLE_NORMAL / BAR_STYLE_DOCK
    FZoomPercent: Integer;       // magnification 100..200 (100 = off)
    FZoomCursor: Integer;        // mouse position along the bar, -1 = none
    FDockPos: Integer;           // dock position along the edge 0..1000
    FDockSliding: Boolean;       // Ctrl+drag in progress
    FSlideMoved: Boolean;
    FSlideStartCursor: TPoint;
    FSlideStartPos: TPoint;
    FThumbForm: TForm;          // live thumbnails popup (Linkbar.ThumbForm)
    FThumbIndex: Integer;
    FForegroundAtMouseDown: HWND;
    FLastForeignWnd: HWND;       // last window in front that is not ours (action buttons)
    FHideOnFullscreen: Boolean;
    FHiddenByFullscreen: Boolean;
    FLinksBaseDir: string;       // links folder of the main profile
    FProfile: string;            // current profile ('' = main)
    imNewAction, imEditAction, imDeleteAction, imActionLine, imProfiles: TMenuItem;
    FCpuLoad, FRamLoad: Integer;       // 0..100
    FPrevIdle, FPrevKernel, FPrevUser: UInt64;
    FExtDragIconSize: Integer;
    FHotkeyInfo: THotkeyInfo;
    FItemMargin: TSize;
    FIconSize: Integer;
    FIsLightStyle: Boolean;
    FItemOrder: TItemOrder;
    FJumplistShowMode: TJumplistShowMode;
    FJumplistRecentMax: Integer;
    FTransparencyMode: TTransparencyMode;
    FLook: TLook;
    FLockLinkbar: Boolean;
    FLockHotIndex: Boolean;
    FCorner1GapWidth, FCorner2GapWidth: Integer;
    FSortAlphabetically: Boolean;
    FStayOnTop: Boolean;
    FBackgroundColor: Cardinal;
    FSysBackgroundColor: Cardinal;
    FTextColor: Cardinal;
    FUseBkgndColor: Boolean;
    FUseTextColor: Boolean;
    FGlowSize: Integer;
    FLayout: TPanelLayout;
    FAlign: TPanelAlign;
    FTextWidth: Integer;
    FTextOffset: Integer;
    FTextLayout: TTextLayout;
    FIconOffset: TPoint;
    FTextRect: TRect;
    FPrevForegroundWnd: HWND;
    FSeparatorWidth: Integer;
    FSeparatorStyle: TSeparatorStyle;
    procedure UpdateWindowSize;
    procedure SetLayout(AValue: TPanelLayout);
    procedure SetAlign(AValue: TPanelAlign);
    procedure SetAutoHide(AValue: Boolean);
    procedure SetEnableAeroGlass(AValue: Boolean);
    procedure SetItemOrder(AValue: TItemOrder);
    procedure SetPressedIndex(AValue: integer);
    procedure SetHotIndex(AValue: integer);
    procedure SetHotkeyInfo(AValue: THotkeyInfo);
    procedure SetButtonSize(AValue: TSize);
    procedure SetIconSize(AValue: integer);
    procedure SetIsLightStyle(AValue: Boolean);
    procedure SetItemMargin(AValue: TSize);
    procedure SetTextLayout(AValue: TTextLayout);
    procedure SetTextOffset(AValue: Integer);
    procedure SetTextWidth(AValue: Integer);
    procedure SetSortAlphabetically(AValue: Boolean);
    procedure SetStayOnTop(AValue: Boolean);
    procedure SetTransparencyMode(AValue: TTransparencyMode);
    procedure SetLook(AValue: TLook);
    procedure SetModernStyle(AValue: Boolean);
    procedure SetShowSysWidgets(AValue: Boolean);
    procedure SetBarStyle(AValue: Integer);
    procedure SetZoomPercent(AValue: Integer);
    function IsDock: Boolean;
    function ZoomEnabled: Boolean;
    function ZoomRoom: Integer;
    function ZoomBefore: Boolean;
    function ZoomIconSizeValue: Integer;
    function DockPad: Integer;
    function ItemsMargin: Integer;
    procedure DockBounds(var AX, AY, AWidth, AHeight: Integer);
    procedure ApplyDockRegion(const AWidth, AHeight: Integer);
    procedure DrawItemsZoomed;
    procedure RedrawZoom;
    procedure SlideDock(const ACursor: TPoint);
    procedure DrawDockBackground(const ABitmap: THBitmap; const AClipRect: TRect);
    procedure SaveDockPos;
    function SysWidgetLength(const AVertical: Boolean): Integer;
    function SysWidgetRect(const AWidth, AHeight: Integer): TRect;
    procedure SampleSysStats;
    procedure DrawSysWidgets(const ABitmap: THBitmap; const AWidth, AHeight: Integer);
    procedure RefreshSysWidgets;
    procedure UpdateRunningState;
    procedure ThumbsHotChanged;
    procedure ShowThumbs(const AIndex: Integer);
    procedure CloseThumbs;
    procedure OnThumbsDestroy(Sender: TObject);
    procedure DrawRunningMark(const ABitmap: THBitmap; const AItem: TItemBase; const ARect: TRect);
    procedure SetUseBkgndColor(AValue: Boolean);
    function GetAlign: TPanelAlign;
    procedure DrawBackground(const ABitmap: THBitmap; const AClipRect: TRect);
    procedure DrawCaption(const ABitmap: THBitmap; const AIndex: Integer;
      const ADrawForDrag: Boolean = False);
    procedure DrawItem(ABitmap: THBitmap; AIndex: integer; ASelected,
      APressed: Boolean; ADrawBg: Boolean = True; ADrawForDrag: Boolean = False);
    procedure DrawItems(const AWidth, AHeight: integer);
    procedure RecreateMainBitmap(const AWidth, AHeight: integer);
    procedure RecreateButtonBitmap(const AWidth, AHeight: integer);
    procedure UpdateWindow; overload;
    procedure UpdateWindow(const ABounds: TRect); overload;
    procedure UpdateBlur;
    procedure UpdateBackgroundColor;
    function GetBackgroundColor: Cardinal;
    function ItemIndexByPoint(const APt: TPoint;
      const ALastIndex: integer = ITEM_NONE): Integer;
    function CheckItem(AIndex: Integer): Boolean;
    procedure DeleteItem(const AIndex: Integer);
    function ScaleDimension(const X: Integer): Integer; inline;
  private
    procedure L10n;
    procedure LoadSettings;
    procedure SaveLinks;
  private
    BitBucketNotify: Cardinal;
    procedure UpdateBitBuckets;
  private
    FRemoved: boolean;
    FDragAlign: TPanelAlign;
    FMonitorNum: Integer;
    FDragMonitorNum: Integer;
    FItemPopup: Integer;
    FDragIndex: Integer;
    MonitorsWorkareaWoTaskbar: TDynRectArray;
    procedure DoClickItem(X, Y: Integer);
    procedure DoExecuteItem(const AIndex: Integer);
    procedure ShowGroup(const AIndex: Integer);
    procedure DragExternalFile(const AFileName: string; AIcon: HBITMAP; AIconSize: Integer);
    procedure GroupChanged(Sender: TObject);
    procedure CheckForeground;
    procedure SetHideOnFullscreen(AValue: Boolean);
    function IsOurWindow(const AWnd: HWND): Boolean;
    procedure RunActionItem(const AIndex: Integer);
    procedure imNewActionClick(Sender: TObject);
    procedure imEditActionClick(Sender: TObject);
    procedure imDeleteActionClick(Sender: TObject);
    function ProfilesDir: string;
    function ProfileDir(const AName: string): string;
    function GetProfileNames: TArray<string>;
    procedure ReloadLinks;
    procedure SwitchProfile(const AName: string);
    procedure CycleProfile(const ADelta: Integer);
    procedure BuildProfilesMenu;
    procedure ProfileItemClick(Sender: TObject);
    procedure ProfileNewClick(Sender: TObject);
    procedure ProfileRenameClick(Sender: TObject);
    procedure ProfileDeleteClick(Sender: TObject);
    procedure RenameGroup(const AIndex: Integer);
    procedure DoRenameItem(const AIndex: Integer);
    procedure DoDelete(const AIndex: Integer);
    procedure DoPopupMenuItemExecute(const ACmd: Integer);
    procedure DoDragLinkbar(const X, Y: Integer);
    procedure DoPopupMenu(APt: TPoint; AShift: Boolean);
    procedure DoPopupJumplist(APt: TPoint; AShift: Boolean);
    procedure DoDragItem(X, Y: Integer);
    procedure GetOrCreateFilesList(const AFileName: string);
    procedure QuerySizingEvent(Sender: TObject; AVertical: Boolean;
      var AWidth, AHeight: Integer);
    procedure QuerySizedEvent(Sender: TObject; const AX, AY, AWidth, AHeight: Integer);
    procedure QueryHideEvent(Sender: TObject; AEnabled: boolean);
    function IsItemIndex(const AIndex: Integer): Boolean;
    procedure CreateBitmaps;
  protected
    // Drag&Drop functions
    FItemDropPosition: Integer;
    FPidl: PItemIDList;
    procedure SetDropPosition(AValue: TPoint);
    procedure DoDragEnter(const pt: TPoint); override;
    procedure DoDragOver(const pt: TPoint; var ppidl: PItemIDList); override;
    procedure DoDragLeave; override;
    procedure DoDrop(const pt: TPoint); override;
    procedure QueryDragImage(out ABitmap: THBitmap; out AOffset: TPoint); override;
  protected
    // Dir watch
    procedure DirWatchChange(const Sender: TObject; const AAction: TWatchAction;
      const AFileName: string); override;
    procedure DirWatchError(const Sender: TObject; const ErrorCode: Integer;
      const ErrorMessage: string); override;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    procedure WndProc(var Msg: TMessage); override;
    procedure WmHotKey(var Msg: TMessage); message WM_HOTKEY;
    procedure CMDialogKey(var Msg: TCMDialogKey); message CM_DIALOGKEY;
  protected
    FAutoHiden: Boolean;
    FCanAutoHide: Boolean;
    FLockAutoHide: Boolean;
    FBeforeAutoHideBound: TRect;
    FAfterAutoHideBound: TRect;
    FAutoShowDelay: Integer;
    procedure DoAutoHide;
    procedure DoAutoShow;
    procedure DoDelayedAutoShow;
    procedure DoDelayedAutoHide(const ADelay: Cardinal);
    procedure OnFormJumplistDestroy(Sender: TObject);
  public
    procedure SaveSettings;
    procedure UpdateItemSizes;
    property AutoHide: Boolean read FAutoHide write SetAutoHide;
    property AutoHideTransparency: Boolean read FAutoHideTransparency write FAutoHideTransparency;
    property AutoShowDelay: Integer read FAutoShowDelay write FAutoShowDelay;
    property AutoShowMode: TAutoShowMode read FAutoShowMode write FAutoShowMode;
    property BackgroundColor: Cardinal read GetBackgroundColor write FBackgroundColor;
    property ButtonSize: TSize read FButtonSize write SetButtonSize;
    property EnableAeroGlass: Boolean read FEnableAeroGlass write SetEnableAeroGlass;
    property GlowSize: Integer read FGlowSize write FGlowSize;
    property TooltipShow: Boolean read FTooltipShow write FTooltipShow;
    property ModernStyle: Boolean read FModernStyle write SetModernStyle;
    property ShowSysWidgets: Boolean read FShowSysWidgets write SetShowSysWidgets;
    property HideOnFullscreen: Boolean read FHideOnFullscreen write SetHideOnFullscreen;
    property BarStyle: Integer read FBarStyle write SetBarStyle;
    procedure ApplyWindowAccent;
    property ZoomPercent: Integer read FZoomPercent write SetZoomPercent;
    property HotIndex: Integer read FHotIndex write SetHotIndex;
    property HotkeyInfo: THotkeyInfo read FHotkeyInfo write SetHotkeyInfo;
    property IconSize: Integer read FIconSize write SetIconSize;
    property IsLightStyle: Boolean read FIsLightStyle write SetIsLightStyle;
    property ItemMargin: TSize read FItemMargin write SetItemMargin;
    property ItemOrder: TItemOrder read FItemOrder write SetItemOrder;
    property JumplistShowMode: TJumplistShowMode read FJumplistShowMode write FJumplistShowMode;
    property JumplistRecentMax: Integer read FJumplistRecentMax write FJumplistRecentMax;
    property TransparencyMode: TTransparencyMode read FTransparencyMode write SetTransparencyMode;
    property Look: TLook read FLook  write SetLook;
    property PressedIndex: Integer read FPressedIndex write SetPressedIndex;
    property Layout: TPanelLayout read FLayout write SetLayout;
    property Align: TPanelAlign read GetAlign  write SetAlign;
    property SortAlphabetically: Boolean read FSortAlphabetically write SetSortAlphabetically;
    property StayOnTop: Boolean read FStayOnTop write SetStayOnTop default True;
    property TextLayout: TTextLayout read FTextLayout write SetTextLayout;
    property TextOffset: Integer read FTextOffset write SetTextOffset;
    property TextWidth: Integer read FTextWidth write SetTextWidth;
    property TextColor: Cardinal read FTextColor write FTextColor;
    property UseBkgndColor: Boolean read FUseBkgndColor write SetUseBkgndColor;
    property UseTextColor: Boolean read FUseTextColor write FUseTextColor;
    property SeparatorWidth: Integer read FSeparatorWidth write FSeparatorWidth default DEF_SEPARATOR_WIDTH;
    property SeparatorStyle: TSeparatorStyle read FSeparatorStyle write FSeparatorStyle default DEF_SEPARATOR_STYLE;
    //
    property Corner1GapWidth: Integer read FCorner1GapWidth write FCorner1GapWidth;
    property Corner2GapWidth: Integer read FCorner2GapWidth write FCorner2GapWidth;
  public class
    procedure CloseAll;
  end;

var
  LinkbarWcl: TLinkbarWcl;
  FSettingsFileName: string;

implementation

{$R *.dfm}

uses
  Types, Math, Dialogs, StrUtils, Themes, System.Generics.Collections,
  Winapi.ShellAPI,
  ExplorerMenu, Linkbar.Shell, Linkbar.Theme,
  Linkbar.OS, Linkbar.L10n, JumpLists.Form, JumpLists.Api_2, RenameDialog,
  Linkbar.SettingsForm, Linkbar.Settings, Linkbar.GroupForm, Linkbar.ThumbForm,
  Linkbar.Actions;

const
  bf: TBlendFunction = (BlendOp: AC_SRC_OVER; BlendFlags: 0;
      SourceConstantAlpha: $FF; AlphaFormat: AC_SRC_ALPHA);

  LM_SHELLNOTIFY = WM_USER + 88;
  TIMER_AUTO_SHOW = 15;
  TIMER_AUTO_HIDE = 16;
  TIMER_SYS_WIDGETS = 17;
  TIMER_RUNNING = 18;
  TIMER_THUMBS = 19;
  TIMER_FOREGROUND = 20;

function EnumWindowProcStopDirWatch(wnd: HWND; lParam: LPARAM): BOOL; stdcall;
var
  className: array[0..MAX_PATH-1] of Char;
begin
  Result := True;
  if (GetClassName(wnd, className, Length(className)) > 0)
     and SameText(string(className), TLinkbarWcl.ClassName)
  then PostMessage(wnd, LM_STOPDIRWATCH, 0, 0);
end;

function EnumWindowProcClose(wnd: HWND; lParam: LPARAM): BOOL; stdcall;
var
  className: array[0..MAX_PATH-1] of Char;
begin
  Result := True;
  if (GetClassName(wnd, className, Length(className)) > 0)
     and SameText(string(className), TLinkbarWcl.ClassName)
  then PostMessage(wnd, WM_CLOSE, 0, 0);
end;

class procedure TLinkbarWcl.CloseAll;
begin
  if MessageDlg(L10NFind('Message.CloseAll', 'Close all linkbars?'),
        mtConfirmation, [mbOK, mbCancel], 0, mbCancel) = mrOk
  then begin
    EnumWindows(@EnumWindowProcStopDirWatch, 0);
    EnumWindows(@EnumWindowProcClose, 0);
  end;
end;

function FindinSL(sl: TStringList; s: string; var index: integer): boolean;
var i: integer;
begin
  index := -1;
  for i := 0 to sl.Count-1 do
  begin
    if CompareText(sl[i], s) = 0
    then begin
      index := i;
      Break;
    end;
  end;
  Result := (index >= 0);
end;

procedure TLinkbarWcl.GetOrCreateFilesList(const AFileName: string);
var list: TStringList;
    templist: TStringList;
    sr: TSearchRec;
    i, j : integer;
    ext: string;
begin
  if not Assigned(Items)
  then Items := TLBItemList.Create;
  Items.Clear;

  // Load last ordered items list
  list := TStringList.Create;
  if FileExists(AFileName)
  then list.LoadFromFile(AFileName, TEncoding.UTF8);

  templist := TStringList.Create;
  templist.CaseSensitive := False;
  templist.Sorted := False;

  // Find supperted files (and groups) in working directory
  for ext in ES_ITEMS_ARRAY do
  begin
    if ( FindFirst( WorkDir + '*' + ext, faAnyFile, sr) = 0 )
    then repeat
      templist.Add(sr.Name);
    until (FindNext(sr) <> 0);
    FindClose(sr);
  end;

  templist.Sort;

  // Ordering founded items
  i := 0;
  while i < list.Count do
  begin
    if TItemSeparator.IsSeparator(list[i])
    then begin
      Inc(i);
    end
    else if templist.Find(list[i], j)
    then begin
      templist.Delete(j);
      Inc(i);
    end
    else list.Delete(i);
  end;

  // New item move to end
  if (templist.Count > 0)
  then list.AddStrings(templist);
  templist.Free;

  // Create linkbar items
  Items.Capacity := list.Count;
  for var fileName in list do
  begin
    if TItemSeparator.IsSeparator(fileName)
    then begin
      Items.Add(TItemSeparator.Create);
    end
    else begin
      var item := CreateItemForFile(fileName);
      if item.LoadFromFile(WorkDir + fileName)
      then Items.Add(item)
      else item.Free;
    end;
  end;
  list.Free;

  if FSortAlphabetically
  then Items.Sort;

  Items.IconSize := IconSize;
  Items.ZoomIconSize := ZoomIconSizeValue;
end;

function TLinkbarWcl.GetAlign: TPanelAlign;
begin
  if (FMouseDragLinkbar)
  then Result := FDragAlign
  else Result := FAlign;
end;

function TLinkbarWcl.CheckItem(AIndex: Integer): Boolean;
var fn: string;
begin
  fn := Items[AIndex].FileName;
  Result := FileExists(fn);
  if not Result
  then begin
    if MessageDlg( L10NFind('Message.FileNotFound', 'File does not exists')
        + #13 + fn + #13 +
        L10NFind('Message.DeleteShortcut', 'Delete shortcut?'),
        mtConfirmation, [mbOK, mbCancel], 0, mbCancel) = mrOk
    then begin
      DeleteItem(AIndex);
      UpdateWindowSize;
    end;
  end;
end;

procedure TLinkbarWcl.DeleteItem(const AIndex: Integer);
begin
  Items.Delete(AIndex);
  // Clear FHotIndex/FPressedIndex if Hot/Pressed item deleted
  if (FHotIndex = AIndex)
  then FHotIndex := ITEM_NONE;
  if (FPressedIndex = AIndex)
  then FPressedIndex := ITEM_NONE;
end;

procedure TLinkbarWcl.DrawBackground(const ABitmap: THBitmap;
  const AClipRect: TRect);
var params: TDrawBackgroundParams;
begin
  // Dock: anti-aliased rounded background painted by Linkbar itself
  if IsDock
  then begin
    DrawDockBackground(ABitmap, AClipRect);
    Exit;
  end;

  params.Bitmap := ABitmap;
  params.Align := Align;
  params.ClipRect := AClipRect;
  params.IsLight := IsLightStyle;
  params.BgColor := BackgroundColor;
  ThemeDrawBackground(@params);
end;

procedure TLinkbarWcl.DrawCaption(const ABitmap: THBitmap; const AIndex: Integer;
  const ADrawForDrag: Boolean = False);
var
  textRect: TRect;
  textColor: TColor;
  dc, dc2: HDC;
  fnt0: HGDIOBJ;
begin
  if (TextLayout = ETextLayoutNone) then Exit;

  const textFlags: Cardinal = TEXTALIGN[TextLayout] or DT_END_ELLIPSIS or DT_SINGLELINE or DT_NOPREFIX or DT_NOCLIP;

  if (StyleServices.Enabled)
  then begin
    // Aero theme. Use DrawGlassText
    if (FUseTextColor)
    then begin
      textColor := FTextColor;
    end
    else begin
      if (AIndex = ITEM_ALL)
      then begin
        textColor := ThemeButtonNormalTextColor;
      end
      else begin
        if (AIndex = PressedIndex)
        then textColor := ThemeButtonPressedTextColor
        else if (AIndex = HotIndex)
             then textColor := ThemeButtonSelectedTextColor
             else textColor := ThemeButtonNormalTextColor;
      end;
    end;

    dc := ABitmap.Dc;

    if (AIndex = ITEM_ALL)
    then begin
      fnt0 := SelectObject(dc, Screen.IconFont.Handle);
      for var item in Items
      do begin
        if (not Items.IsSeparator(item))
        then begin
          textRect := FTextRect;
          textRect.Offset(item.Rect.TopLeft);
          DrawGlassText(dc, item.Caption, textRect, textFlags, FGlowSize, textColor);
        end;
      end;
      SelectObject(dc, fnt0);
    end
    else begin
      const item = Items[AIndex];

      if (not Items.IsSeparator(item))
      then begin
        if ADrawForDrag
        then begin
          textRect := FTextRect;
          fnt0 := SelectObject(dc, Screen.IconFont.Handle);
          DrawGlassText(dc, item.Caption, textRect, textFlags, FGlowSize, textColor);
          SelectObject(dc, fnt0);
        end
        else begin
          // The shadow extends beyond the button, creating artifacts
          // Draw on separate bitmap with button size
          var bmp := THBitmap.Create(32);
          bmp.SetSize(BitmapButton.Width, BitmapButton.Height);
          dc2 := bmp.Dc;

          textRect := FTextRect;
          if (AIndex = PressedIndex)
          then textRect.Offset(1,1);

          fnt0 := SelectObject(dc2, Screen.IconFont.Handle);
          DrawGlassText(dc2, item.Caption, textRect, textFlags, FGlowSize, textColor);
          SelectObject(dc2, fnt0);

          Windows.AlphaBlend(dc,
            item.Rect.Left, item.Rect.Top, bmp.Width, bmp.Height,
            dc2, 0, 0, bmp.Width, bmp.Height, bf);

          bmp.Free;
        end;
      end;
    end;
  end
  else begin
    // Classic theme
    // NOTE: DrawThemeText/DrawThemeTextEx not work in Classic theme

    Assert(not ADrawForDrag); // Classic Theme don't have Drag Image

    textColor := clBtnText;

    dc := ABitmap.Dc;
    fnt0 := SelectObject(dc, Screen.IconFont.Handle);
    SetTextColor(dc, ColorToRGB(textColor));
    SetBkColor(dc, ColorToRGB(clBtnFace));

    if (AIndex = ITEM_ALL)
    then begin
      for var item in Items
      do begin
        if (not Items.IsSeparator(item))
        then begin
          textRect := FTextRect;
          textRect.Offset(item.Rect.TopLeft);
          DrawText(dc, item.Caption, -1, textRect, textFlags);
        end;
      end;
      ABitmap.Opaque;
    end
    else begin
      const item = Items[AIndex];
      if (not Items.IsSeparator(item))
      then begin
        textRect := FTextRect;
        textRect.Offset(item.Rect.TopLeft);
        if (AIndex = PressedIndex)
        then textRect.Offset(1,1);
        DrawText(dc, item.Caption, -1, textRect, textFlags);
        ABitmap.OpaqueRect(item.Rect);
      end;
    end;

    SelectObject(dc, fnt0);
  end;
end;

procedure TLinkbarWcl.DrawItem(ABitmap: THBitmap; AIndex: integer; ASelected,
  APressed: Boolean; ADrawBg: Boolean; ADrawForDrag: Boolean);
begin
  if AIndex = ITEM_NONE then Exit;

  const item = Items[AIndex];
  if Items.IsSeparator(item) then Exit;

  var r := item.Rect;

  // Classic themes have opaque background and button
  if ADrawBg
     and StyleServices.Enabled
  then DrawBackground(ABitmap, r);

  // For darg not need draw background
  if ADrawForDrag
  then r.Location := TPoint.Zero;

  if APressed
  then ThemeDrawButton(ABitmap, r, True)
  else if ASelected
       then begin
         Windows.AlphaBlend(ABitmap.Dc, r.Left, r.Top, r.Width, r.Height, BitmapButton.Dc, 0, 0, r.Width, r.Height, bf);
       end;

  // Draw text
  DrawCaption(ABitmap, AIndex, ADrawForDrag);

  // Draw icon
  var d: Integer := IfThen(APressed, 1, 0);
  Items.Draw(ABitmap.Dc, item, r.Left + FIconOffset.X + d, r.Top + FIconOffset.Y + d);

  // "Program is open" indicator
  if not ADrawForDrag
  then DrawRunningMark(ABitmap, item, r);
end;

procedure TLinkbarWcl.DrawItems(const AWidth, AHeight: integer);
begin
  Items.Sizes.Button := ButtonSize;
  Items.Sizes.Separator := SeparatorWidth;
  Items.Sizes.Margin := ItemsMargin;
  Items.Sizes.ZoomRoom := ZoomRoom;
  Items.Sizes.ZoomBefore := ZoomBefore;
  Items.Sizes.Reserved := SysWidgetLength(IsVertical(Align));
  Items.UpdateLines(IsVertical(Align), AWidth, AHeight);

  // Draw captions
  DrawCaption(BitmapPanel, ITEM_ALL);

  // Magnification effect (Mac-like)
  if ZoomEnabled and (FZoomCursor >= 0) and (Items.Lines.Count = 1)
  then begin
    DrawItemsZoomed;
    Exit;
  end;

  // Draw icons
  for var item in Items do
  begin
    if Items.IsSeparator(item)
       and (FSeparatorStyle <> ESeparatorStyleSpace)
    then begin
      ThemeDrawSeparator(BitmapPanel, Align, item.Rect);
    end
    else begin
      Items.Draw(BitmapPanel.Dc, item, item.Rect.Left + FIconOffset.X, item.Rect.Top + FIconOffset.Y);
      DrawRunningMark(BitmapPanel, item, item.Rect);
    end;
  end;
end;

procedure TLinkbarWcl.RecreateMainBitmap(const AWidth, AHeight: integer);
begin
  BitmapPanel.SetSize(AWidth, AHeight);
  BitmapPanel.Clear;
  // Draw background
  DrawBackground(BitmapPanel, Rect(0, 0, AWidth, AHeight));
  // Draw items
  DrawItems(AWidth, AHeight);
  // CPU/RAM widgets
  DrawSysWidgets(BitmapPanel, AWidth, AHeight);
end;

procedure TLinkbarWcl.RecreateButtonBitmap(const AWidth, AHeight: integer);
begin
  // Create clear bitmap
  BitmapButton.SetSize(AWidth, AHeight);
  BitmapButton.Clear;
  ThemeDrawButton(BitmapButton, BitmapButton.Bound, False);
  // Buffer for selections
  BitmapSelected.SetSize(AWidth, AHeight);
  // Buffer for drop
  BitmapDropPosition.SetSize(AWidth, AHeight);
end;

procedure TLinkbarWcl.UpdateWindow;
begin
  UpdateWindow(BoundsRect);
end;

procedure TLinkbarWcl.UpdateWindow(const ABounds: TRect);
var w, h, c1gw, c2gw, wh: Integer;
    Pt1, Pt2: TPoint;
    Sz: TSize;
    drawer: IGPGraphics;
    r: TGPRect;
    bmp: THBitmap;
    dc: HDC;
    p: Pointer;
begin
  w := ABounds.Width;
  h := ABounds.Height;

  // Draw
  if (FAutoHiden)
  then begin
    // Hidden

    // Check corner gaps width
    c1gw := FCorner1GapWidth;
    c2gw := FCorner2GapWidth;
    if (c1gw > 0) or (c2gw > 0)
    then begin
      if Align in [EPanelAlignLeft, EPanelAlignRight]
      then wh := h
      else wh := w;
      if (c1gw > wh - c2gw)
      then begin
        c1gw := 0;
        c2gw := 0;
      end;
    end;

    if (FAutoHideTransparency)
    then begin
      // and Transparency
      Pt1 := ABounds.TopLeft;
      Sz := TSize.Create(w, h);
      Pt2 := Point(0,0);

      bmp := THBitmap.Create(32);
      bmp.SetSize(w, h);
      dc := bmp.Dc;

      drawer := TGPGraphics.FromHDC(dc);
      if (c1gw > 0) or (c2gw > 0)
      then begin
        if Align in [EPanelAlignLeft, EPanelAlignRight]
        then r := TGPRect.Create(0, c1gw, w, h - c1gw - c2gw)
        else r := TGPRect.Create(c1gw, 0, w - c1gw - c2gw, h);
        drawer.SetClip(r);
      end;
      drawer.Clear($01000000);

      UpdateLayeredWindow(Handle, 0, @Pt1, @Sz, dc, @Pt2, 0, @bf, ULW_ALPHA);
      bmp.Free;
    end
    else begin
      // and Opaque
      if (c1gw > 0) or (c2gw > 0)
      then begin
        // w/ gaps
        Pt1 := ABounds.TopLeft;
        Sz := TSize.Create(w, h);
        case Align of
          EPanelAlignLeft:   Pt2 := Point(BitmapPanel.Width - w, 0);
          EPanelAlignTop:    Pt2 := Point(0, BitmapPanel.Height - h);
          EPanelAlignRight:  Pt2 := Point(0, 0);
          EPanelAlignBottom: Pt2 := Point(0, 0);
        end;

        bmp := THBitmap.Create(32);
        bmp.SetSize(w, h);
        dc := bmp.Dc;

        if Align in [EPanelAlignLeft, EPanelAlignRight]
        then BitBlt(dc, 0, c1gw, w, h - c1gw - c2gw, BitmapPanel.Dc, Pt2.X, c1gw, SRCCOPY)
        else BitBlt(dc, c1gw, 0, w - c1gw - c2gw, h, BitmapPanel.Dc, c1gw, Pt2.Y, SRCCOPY);

        Pt2 := Point(0,0);
        UpdateLayeredWindow(Handle, 0, @Pt1, @Sz, dc, @Pt2, 0, @bf, ULW_ALPHA);
        bmp.Free;
      end
      else begin
        // w/o gaps
        Pt1 := ABounds.TopLeft;
        Sz := TSize.Create(w, h);
        case Align of
          EPanelAlignLeft:   Pt2 := Point(BitmapPanel.Width - w, 0);
          EPanelAlignTop:    Pt2 := Point(0, BitmapPanel.Height - h);
          EPanelAlignRight:  Pt2 := Point(0, 0);
          EPanelAlignBottom: Pt2 := Point(0, 0);
        end;
        UpdateLayeredWindow(Handle, 0, @Pt1, @Sz, BitmapPanel.Dc, @Pt2, 0, @bf, ULW_ALPHA);
      end;
    end;
  end
  else begin
    // Not Hidden
    if (ABounds = BoundsRect)
    then p := nil
    else p := @ABounds.TopLeft;
    Sz := TSize.Create(w, h);
    case Align of
      EPanelAlignLeft:   Pt2 := Point(BitmapPanel.Width - w, 0);
      EPanelAlignTop:    Pt2 := Point(0, BitmapPanel.Height - h);
      EPanelAlignRight:  Pt2 := Point(0, 0);
      EPanelAlignBottom: Pt2 := Point(0, 0);
    end;

    UpdateLayeredWindow(Handle, 0, p, @Sz, BitmapPanel.Dc, @Pt2, 0, @bf, ULW_ALPHA);
  end;
end;

procedure TLinkbarWcl.UpdateBlur;
var blurEnabled: Boolean;
begin
  if IsWindows10
  then begin
    ApplyWindowAccent;
  end
  else begin
    blurEnabled := not (FAutoHiden and FAutoHideTransparency);
    if (IsWindows8And8Dot1 and not FEnableAeroGlass)
    then blurEnabled := False;
    ThemeUpdateBlur(Handle, blurEnabled);
  end;
end;

{ Load settings from file }
procedure TLinkbarWcl.LoadSettings;
var settings: TSettingsFile;
    hki: THotkeyInfo;
begin
  settings.Open(FSettingsFileName);
  // Read
  WorkDir               := settings.Read(INI_DIR_LINKS, DEF_DIR_LINKS);
  FLinksBaseDir         := WorkDir;  // expanded by SetWorkDir
  FProfile              := Trim(settings.Read(INI_PROFILE, ''));
  if (FProfile <> '')
  then begin
    if DirectoryExists(ProfileDir(FProfile))
    then WorkDir := ProfileDir(FProfile)
    else FProfile := '';
  end;
  FHideOnFullscreen     := settings.Read(INI_HIDE_FULLSCREEN, DEF_HIDE_FULLSCREEN);
  FAutoHide             := settings.Read(INI_AUTOHIDE, DEF_AUTOHIDE);
  FAutoHideTransparency := settings.Read(INI_AUTOHIDE_TRANSPARENCY, DEF_AUTOHIDE_TRANSPARENCY);
  FAutoShowDelay        := settings.Read(INI_AUTOSHOW_DELAY, DEF_AUTOSHOW_DELAY, 0, 60000);
  FAutoShowMode         := settings.Read<TAutoShowMode>(INI_AUTOHIDE_SHOWMODE, DEF_AUTOHIDE_SHOWMODE);
  FBackgroundColor      := Cardinal(settings.Read(INI_BKGCOLOR, DEF_BKGCOLOR));
  FCorner1GapWidth      := settings.Read(INI_CORNER1GAP_WIDTH, DEF_CORNERGAP_WIDTH);
  FCorner2GapWidth      := settings.Read(INI_CORNER2GAP_WIDTH, DEF_CORNERGAP_WIDTH);
  FEnableAeroGlass      := settings.Read(INI_ENABLE_AG, DEF_ENABLE_AG);
  FGlowSize             := settings.Read(INI_GLOWSIZE, DEF_GLOWSIZE, GLOW_SIZE_MIN, GLOW_SIZE_MAX);
  FTooltipShow          := settings.Read(INI_TOOLTIP_SHOW, DEF_TOOLTIP_SHOW);
  FModernStyle          := settings.Read(INI_MODERN_STYLE, DEF_MODERN_STYLE);
  FShowSysWidgets       := settings.Read(INI_SYS_WIDGETS, DEF_SYS_WIDGETS);
  FBarStyle            := settings.Read(INI_BAR_STYLE, DEF_BAR_STYLE, BAR_STYLE_NORMAL, BAR_STYLE_DOCK);
  FZoomPercent          := settings.Read(INI_ZOOM, DEF_ZOOM, ZOOM_MIN, ZOOM_MAX);
  FZoomCursor           := -1;
  FDockPos             := settings.Read(INI_DOCK_POS, DEF_DOCK_POS, 0, 1000);
  hki                   := settings.Read(INI_AUTOHIDE_HOTKEY, DEF_AUTOHIDE_HOTKEY);
  FIconSize             := settings.Read(INI_ICON_SIZE, DEF_ICON_SIZE, ICON_SIZE_MIN, ICON_SIZE_MAX);
  FIsLightStyle         := settings.Read(INI_ISLIGHT, DEF_ISLIGHT);
  FItemMargin.cx        := settings.Read(INI_MARGINX, DEF_MARGINX, MARGIN_MIN, MARGIN_MAX);
  FItemMargin.cy        := settings.Read(INI_MARGINY, DEF_MARGINY, MARGIN_MIN, MARGIN_MAX);
  FSeparatorWidth       := settings.Read(INI_SEPARATOR_WIDTH, DEF_SEPARATOR_WIDTH, SEPARATOR_WIDTH_MIN, SEPARATOR_WIDTH_MAX);
  FSeparatorStyle       := settings.Read<TSeparatorStyle>(INI_SEPARATOR_STYLE, DEF_SEPARATOR_STYLE);
  FItemOrder            := settings.Read<TItemOrder>(INI_ITEM_ORDER, DEF_ITEM_ORDER);
  FLayout               := settings.Read<TPanelLayout>(INI_ITEMS_ALIGN, DEF_ITEMS_ALIGN);
  FJumplistRecentMax    := settings.Read(INI_JUMPLIST_RECENTMAX, DEF_JUMPLIST_RECENTMAX, JUMPLIST_RECENTMAX_MIN, JUMPLIST_RECENTMAX_MAX);
  FJumplistShowMode     := settings.Read<TJumplistShowMode>(INI_JUMPLIST_SHOWMODE, DEF_JUMPLIST_SHOWMODE);
  FLockLinkbar          := settings.Read(INI_LOCK_BAR, DEF_LOCK_BAR);
  FTransparencyMode     := settings.Read<TTransparencyMode>(INI_TRANSPARENCYMODE, DEF_TRANSPARENCYMODE);
  FLook                 := settings.Read<TLook>(INI_COLORMODE, DEF_COLORMODE);
  FMonitorNum           := settings.Read(INI_MONITORNUM, Screen.PrimaryMonitor.MonitorNum, 0, Screen.MonitorCount-1);
  FAlign                := settings.Read<TPanelAlign>(INI_EDGE, DEF_EDGE);
  FSortAlphabetically   := settings.Read(INI_SORT_AB, DEF_SORT_AB);
  FTextColor            := Cardinal(settings.Read(INI_TXTCOLOR, DEF_TXTCOLOR) and $ffffff);
  FTextLayout           := settings.Read<TTextLayout>(INI_TEXT_LAYOUT, DEF_TEXT_LAYOUT);
  FTextOffset           := settings.Read(INI_TEXT_OFFSET, DEF_TEXT_OFFSET, TEXT_OFFSET_MIN, TEXT_OFFSET_MAX);
  FTextWidth            := settings.Read(INI_TEXT_WIDTH, DEF_TEXT_WIDTH, TEXT_WIDTH_MIN, TEXT_WIDTH_MAX);
  FUseBkgndColor        := settings.Read(INI_USEBKGCOLOR, DEF_USEBKGCOLOR);
  FUseTextColor         := settings.Read(INI_USETXTCOLOR, DEF_USETXTCOLOR);
  FStayOnTop := (FormStyle = fsStayOnTop);
  StayOnTop             := settings.Read(INI_STAYONTOP, DEF_STAYONTOP);
  //
  settings.Close;

  // Set other values
  FGripSize := GRIP_SIZE;
  FHotIndex := ITEM_NONE;
  FPressedIndex := ITEM_NONE;
  FItemDropPosition := ITEM_NONE;
  FItemPopup := ITEM_NONE;
  FDragIndex := ITEM_NONE;
  FMouseLeftDown := False;
  FMouseDragLinkbar := False;
  FMouseDragItem := False;
  FDragingItem := False;

  GlobalLayout := FLayout;
  GlobalLook := FLook;
  GlobalAeroGlassEnabled := FEnableAeroGlass;
  GlobalModernStyle := FModernStyle;

  // CPU/RAM widgets
  if FShowSysWidgets
  then begin
    SampleSysStats;
    SetTimer(Handle, TIMER_SYS_WIDGETS, 1000, nil);
  end;

  // "Program is open" indicator
  SetTimer(Handle, TIMER_RUNNING, 2000, nil);

  // Window in front: action buttons target + hide on full screen
  SetTimer(Handle, TIMER_FOREGROUND, 500, nil);

  // Register Hotkey
  HotkeyInfo := hki;
end;

procedure TLinkbarWcl.SaveLinks;
begin
  if DirectoryExists(WorkDir)
     or ForceDirectories(WorkDir)
  then begin
    var sl := TStringList.Create;
    try
      for var item in Items
      do sl.Add(ExtractFileName(item.FileName));

      sl.SaveToFile(WorkDir + LINKSLIST_FILE_NAME, TEncoding.UTF8);
    finally
      sl.Free;
    end;
  end;
end;

procedure TLinkbarWcl.SaveSettings;
var path: string;
    settings: TSettingsFile;
begin
  path := ExtractFilePath(FSettingsFileName);
  if DirectoryExists(path)
     or ForceDirectories(path)
  then begin
    settings.Open(FSettingsFileName);
    // Write
    settings.Write(INI_MONITORNUM, FMonitorNum);
    settings.Write(INI_HIDE_FULLSCREEN, FHideOnFullscreen);
    settings.Write(INI_PROFILE, FProfile);
    settings.Write(INI_EDGE, Integer(Align));
    settings.Write(INI_AUTOHIDE, AutoHide);
    settings.Write(INI_AUTOHIDE_TRANSPARENCY, FAutoHideTransparency);
    settings.Write(INI_AUTOHIDE_SHOWMODE, Integer(AutoShowMode));
    settings.Write(INI_AUTOHIDE_HOTKEY, string(HotkeyInfo));
    settings.Write(INI_ICON_SIZE, IconSize);
    settings.Write(INI_MARGINX, ItemMargin.cx);
    settings.Write(INI_MARGINY, ItemMargin.cy);
    settings.Write(INI_TEXT_LAYOUT, Integer(TextLayout));
    settings.Write(INI_TEXT_OFFSET, TextOffset);
    settings.Write(INI_TEXT_WIDTH, TextWidth);
    settings.Write(INI_ITEM_ORDER, Integer(ItemOrder));
    settings.Write(INI_ITEMS_ALIGN, Integer(Layout));
    settings.Write(INI_LOCK_BAR, FLockLinkbar);
    settings.Write(INI_ISLIGHT, FIsLightStyle);
    settings.Write(INI_ENABLE_AG, FEnableAeroGlass);
    settings.Write(INI_AUTOSHOW_DELAY, FAutoShowDelay);
    settings.Write(INI_SORT_AB, FSortAlphabetically);
    settings.Write(INI_USEBKGCOLOR, FUseBkgndColor);
    settings.Write(INI_BKGCOLOR, HexDisplayPrefix + IntToHex(BackgroundColor, 8));
    settings.Write(INI_USETXTCOLOR, FUseTextColor);
    settings.Write(INI_TXTCOLOR, HexDisplayPrefix + IntToHex(FTextColor, 6));
    settings.Write(INI_GLOWSIZE, FGlowSize);
    settings.Write(INI_STAYONTOP, FStayOnTop);
    settings.Write(INI_JUMPLIST_SHOWMODE, Integer(JumplistShowMode));
    settings.Write(INI_JUMPLIST_RECENTMAX, JumplistRecentMax);
    settings.Write(INI_COLORMODE, Integer(FLook));
    settings.Write(INI_TRANSPARENCYMODE, Integer(FTransparencyMode));
    settings.Write(INI_CORNER1GAP_WIDTH, FCorner1GapWidth);
    settings.Write(INI_CORNER2GAP_WIDTH, FCorner2GapWidth);
    settings.Write(INI_SEPARATOR_WIDTH, FSeparatorWidth);
    settings.Write(INI_SEPARATOR_STYLE, Integer(FSeparatorStyle));
    settings.Write(INI_TOOLTIP_SHOW, FTooltipShow);
    settings.Write(INI_MODERN_STYLE, FModernStyle);
    settings.Write(INI_SYS_WIDGETS, FShowSysWidgets);
    settings.Write(INI_BAR_STYLE, FBarStyle);
    settings.Write(INI_ZOOM, FZoomPercent);
    settings.Write(INI_DOCK_POS, FDockPos);
    // Save
    settings.Close;
  end;
end;

procedure TLinkbarWcl.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := WS_POPUP;
  Params.ExStyle := (Params.ExStyle or WS_EX_TOOLWINDOW) and not WS_EX_APPWINDOW;
end;

procedure TLinkbarWcl.CreateWnd;
begin
  inherited CreateWnd;
  // Set layered window style
  if SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE) or WS_EX_LAYERED) = 0
  then MessageBox(Handle, PChar(SysErrorMessage(GetLastError)), 'Error', MB_ICONWARNING or MB_OK);
end;

procedure TLinkbarWcl.FormCreate(Sender: TObject);
begin
  FCreated := False;
  CreateBitmaps;

  Self.DesktopFont := True;

  L10n;

  // New > Action button
  imNewAction := TMenuItem.Create(pMenu);
  imNewAction.Caption := L10NFind('Menu.Action', 'Action button');
  imNewAction.OnClick := imNewActionClick;
  imNew.Insert(imNew.IndexOf(imNewGroup) + 1, imNewAction);
  // Edit / delete an action button (only shown for action buttons)
  imEditAction := TMenuItem.Create(pMenu);
  imEditAction.Caption := L10NFind('Menu.EditAction', 'Edit action...');
  imEditAction.OnClick := imEditActionClick;
  pMenu.Items.Insert(0, imEditAction);
  imDeleteAction := TMenuItem.Create(pMenu);
  imDeleteAction.Caption := L10NFind('Menu.DeleteAction', 'Delete action');
  imDeleteAction.OnClick := imDeleteActionClick;
  pMenu.Items.Insert(1, imDeleteAction);
  imActionLine := TMenuItem.Create(pMenu);
  imActionLine.Caption := '-';
  pMenu.Items.Insert(2, imActionLine);
  // Profiles (sub-menu filled when the menu opens)
  imProfiles := TMenuItem.Create(pMenu);
  imProfiles.Caption := L10NFind('Menu.Profile', 'Profile');
  pMenu.Items.Insert(pMenu.Items.IndexOf(imNew) + 1, imProfiles);

  pMenu.Items.RethinkHotkeys;
  imNew.RethinkHotkeys;

  ToolTip := TTooltip32.Create(Handle);

  Color := 0;
  FrmProperties := nil;
  FLockAutoHide := False;
  FCanAutoHide := True;

  LoadSettings;

  UpdateBackgroundColor;

  if IsWindows10
  then ThemeSetWindowAttribute10(Handle, FTransparencyMode, BackgroundColor)
  else ThemeSetWindowAttribute78(Handle);
  // Dock: its own anti-aliased background, no DWM accent (that one has jagged corners)
  if IsWindows10 and IsDock
  then ThemeSetWindowAccentPolicy10(Handle, tmDisabled, 0);

  ThemeInitData(Handle, FIsLightStyle);

  GetOrCreateFilesList(WorkDir + LINKSLIST_FILE_NAME);

  UpdateItemSizes;

  oAppBar := TAccessBar.Create2(self, FAlign, FALSE);
  oAppBar.StayOnTop := StayOnTop;
  oAppBar.MonitorNum := FMonitorNum;
  oAppBar.QuerySizing := QuerySizingEvent;
  oAppBar.QuerySized := QuerySizedEvent;
  oAppBar.QueryAutoHide := QueryHideEvent;

  // Dock mode: floating bar, no autohide
  oAppBar.Floating := IsDock;
  if IsDock then FAutoHide := False;

  if not AutoHide then oAppBar.Loaded
  else AutoHide := TRUE;

  BitBucketNotify := RegisterBitBucketNotify(Handle, LM_SHELLNOTIFY);

  FCreated := True;
  UpdateBlur;

  CreateLinkbarTasksJumplist;

  DoDelayedAutoHide(1000);
end;

procedure TLinkbarWcl.L10n;
begin
  L10nControl(imNew,          'Menu.New');
  L10nControl(imNewShortcut,  'Menu.Shortcut');
  L10nControl(imNewSeparator, 'Menu.Separator');
  L10nControl(imNewGroup,     'Menu.Group');
  L10nControl(imNewLinkbar,   'Menu.Linkbar');
  L10nControl(imOpenWorkdir,  'Menu.Open');
  L10nControl(imRemoveBar,    'Menu.Delete');
  L10nControl(imLockBar,      'Menu.Lock');
  L10nControl(imSortAlphabet, 'Menu.Sort');
  L10nControl(imProperties,   'Menu.Properties');
  L10nControl(imClose,        'Menu.Close');
  L10nControl(imCloseAll,     'Menu.CloseAll');
end;

procedure TLinkbarWcl.FormDestroy(Sender: TObject);
begin
  UnregisterBitBucketNotify(BitBucketNotify);
  UnregisterHotkeyNotify(Handle);

  if Assigned(FrmProperties)
  then FrmProperties.Free;

  oAppBar.Free;
  StopDirWatch;

  if (not FRemoved)
  then SaveLinks;

  ThemeCloseData;

  if Assigned(ToolTip) then ToolTip.Free;
  if Assigned(BitmapPanel) then BitmapPanel.Free;
  if Assigned(BitmapButton) then BitmapButton.Free;
  if Assigned(BitmapSelected) then BitmapSelected.Free;
  if Assigned(BitmapDropPosition) then BitmapDropPosition.Free;
  if Assigned(Items) then Items.Free;
end;

procedure TLinkbarWcl.CreateBitmaps;
begin
  BitmapSelected := THBitmap.Create(32);
  BitmapDropPosition := THBitmap.Create(32);
  BitmapButton := THBitmap.Create(32);
  BitmapPanel := THBitmap.Create(32);
end;

function TLinkbarWcl.IsItemIndex(const AIndex: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex < Items.Count);
end;

procedure TLinkbarWcl.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if AutoHide
     and FAutoHiden
  then begin
    Key := 0;
    Exit;
  end;

  if (Items.Count = 0) then Exit;

  case Key of
    VK_SPACE, VK_RETURN: // Run
      begin
        if IsItemIndex(HotIndex)
        then begin
          ToolTip.Cancel;
          DoExecuteItem(HotIndex);
        end;
        Exit;
      end;
    VK_ESCAPE: // Deselect
      begin
        if (HotIndex = ITEM_NONE)
        then begin
          FCanAutoHide := True;
          DoAutoHide;
        end
        else HotIndex := ITEM_NONE;
        Exit;
      end;
    VK_F2: // Rename
      begin
        if IsItemIndex(HotIndex)
        then begin
          ToolTip.Cancel;
          DoRenameItem(HotIndex);
        end;
        Exit;
      end;
    VK_DELETE:
      begin
        if IsItemIndex(HotIndex)
        then begin
          ToolTip.Cancel;
          SHDeleteOp(Handle, Items[HotIndex].FileName, GetKeyState(VK_SHIFT) >= 0);
        end;
        Exit;
      end;
    VK_TAB:
      begin
        HotIndex := HotIndex + 1;
        Exit;
      end;
    // Arrows
    VK_LEFT, VK_RIGHT, VK_DOWN, VK_UP:
      begin
        // No hot item:
        // Left/Up - last
        // Right/Down - first
        if (HotIndex = ITEM_NONE)
        then begin
          if (Key in [VK_LEFT, VK_UP])
          then HotIndex := Items.Count-1
          else HotIndex := 0;
          Exit;
        end;

        // One-line panel:
        // Left/Up - prev
        // Right/Down - next
        if (Items.Lines.Count = 1)
        then begin
          if (Key in [VK_LEFT, VK_UP])
          then HotIndex := Max(HotIndex - 1, 0)
          else HotIndex := Min(HotIndex + 1, Items.Count-1);
          Exit;
        end;

        // Multi-line panel:
        case Key of
          VK_LEFT:
            begin
              if (ItemOrder = EItemOrderLeftToRight)
              then HotIndex := Max(HotIndex - 1, 0)
              else begin
                if (oAppBar.Vertical)
                then begin
                  const prevLineIndex: Integer = Max(0, Items.GetLineIndex(HotIndex) - 1);
                  HotIndex := Max(HotIndex - Items.Lines[prevLineIndex], 0);
                end
                else
                  HotIndex := Max(HotIndex - Items.Lines.Count, 0);
              end;
            end;
          VK_RIGHT:
            begin
              if (ItemOrder = EItemOrderLeftToRight)
              then HotIndex := Min(HotIndex + 1, Items.Count-1)
              else begin
                if (oAppBar.Vertical)
                then begin
                  const nextLineIndex: Integer = Min(Items.Lines.Count-1, Items.GetLineIndex(HotIndex) + 1);
                  HotIndex := Min(HotIndex + Items.Lines[nextLineIndex], Items.Count-1);
                end
                else
                  HotIndex := Min(HotIndex + Items.Lines.Count, Items.Count-1)
              end;
            end;
          VK_UP:
            begin
              if (ItemOrder = EItemOrderUpToDown)
              then HotIndex := Max(HotIndex - 1, 0)
              else begin
                if (oAppBar.Vertical)
                then
                  HotIndex := Max(HotIndex - Items.Lines.Count, 0)
                else begin
                  const prevLineIndex: Integer = Max(0, Items.GetLineIndex(HotIndex) - 1);
                  HotIndex := Max(HotIndex - Items.Lines[prevLineIndex], 0);
                end;
              end;
            end;
          VK_DOWN:
            begin
              if (ItemOrder = EItemOrderUpToDown)
              then HotIndex := Min(HotIndex + 1, Items.Count-1)
              else begin
                if (oAppBar.Vertical)
                then
                  HotIndex := Min(HotIndex + Items.Lines.Count, Items.Count-1)
                else begin
                  const nextLineIndex: Integer = Min(Items.Lines.Count-1, Items.GetLineIndex(HotIndex) + 1);
                  HotIndex := Min(HotIndex + Items.Lines[nextLineIndex], Items.Count-1);
                end;
              end;
            end;
        end;
      end;
  else
    Exit;
  end;
end;

procedure TLinkbarWcl.CMDialogKey(var Msg: TCMDialogKey);
begin
  // If you do not return 0 then VK_TAB will not pass into FormKeyDown
  if (Msg.CharCode = VK_TAB)
  then Msg.Result := 0
  else inherited;
end;

function TLinkbarWcl.ItemIndexByPoint(const APt: TPoint; const ALastIndex: integer = ITEM_NONE): Integer;
var
  i: Integer;
begin
  if (APt.X < 0) or (APt.Y < 0)
  then Exit(ITEM_NONE);

  if (ALastIndex <> ITEM_NONE)
     and InRange(ALastIndex+1, 0, Items.Count)
     and PtInRect(Items[ALastIndex].Rect, APt)
  then Exit(ALastIndex);

  for i := 0 to Items.Count-1 do
  begin
    if PtInRect(Items[i].Rect, APt)
    then Exit(i);
  end;

  Result := ITEM_NONE;
end;

procedure TLinkbarWcl.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if AutoHide and FAutoHiden
  then Exit;

  FMousePosDown := Point(X, Y);
  // window that was in front before clicking the bar (for minimize on click)
  if (GetForegroundWindow <> Handle)
  then FForegroundAtMouseDown := GetForegroundWindow;
  CloseThumbs;

  // Dock: Ctrl + drag slides it along the same screen edge
  if IsDock and (Button = mbLeft)
     and (ssCtrl in Shift) and not (ssShift in Shift)
  then begin
    FDockSliding := True;
    FSlideMoved := False;
    GetCursorPos(FSlideStartCursor);
    FSlideStartPos := BoundsRect.TopLeft;
    SetCapture(Handle);
    ToolTip.Cancel;
    Exit;
  end;

  case Button of
    mbLeft:
      begin
        FMouseLeftDown := True;
        FLockHotIndex := False;
        PressedIndex := ItemIndexByPoint( Point(X, Y) );
      end
    else Exit;
  end;
end;

var
  prevX: Integer = -MaxInt;
  prevY: Integer = -MaxInt;

procedure TLinkbarWcl.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if FDockSliding
  then begin
    var p: TPoint;
    GetCursorPos(p);
    if (not FSlideMoved)
       and (Abs(p.X - FSlideStartCursor.X) + Abs(p.Y - FSlideStartCursor.Y) > PANEL_DRAG_THRESHOLD)
    then begin
      FSlideMoved := True;
      if IsVertical(Align)
      then Screen.Cursor := crSizeNS
      else Screen.Cursor := crSizeWE;
    end;
    if FSlideMoved
    then SlideDock(p);
    Exit;
  end;

  if (X = prevX) and (Y = prevY)
  then Exit;
  prevX := X; prevY := Y;

  if FAutoHiden then Exit;

  if Self.IsDragDrop then Exit;
  if FItemDropPosition <> ITEM_NONE then Exit;

  if not FMouseLeftDown then
  begin
    HotIndex := ItemIndexByPoint( Point(X, Y), HotIndex );

    // Magnification follows the mouse
    if ZoomEnabled and (not FMouseDragLinkbar)
    then begin
      if IsVertical(Align)
      then FZoomCursor := Y
      else FZoomCursor := X;
      RedrawZoom;
    end;
  end;

  if FMouseLeftDown
  then begin
    if FMouseDragLinkbar
    then DoDragLinkbar(X, Y)
    else if FMouseDragItem
    then begin
      if not FDragingItem
      then begin
        FDragingItem := True;
        DoDragItem(FMousePosDown.X, FMousePosDown.Y);
      end;
    end
    else if (not FLockLinkbar)
    then begin
      if (FPressedIndex = ITEM_NONE)
      then begin
        if ( TPoint.Create(X,Y).Distance(FMousePosDown) > PANEL_DRAG_THRESHOLD )
        then begin
          FMouseDragLinkbar := True;
          FMouseDragItem := False;
          GetUserWorkArea(MonitorsWorkareaWoTaskbar);
          FBeforeDragBounds := BoundsRect;
          FDragMonitorNum := FMonitorNum;
        end;
      end
      else begin
        // If cursor leave item rect then start DragItem
        // This is done by MS for TaskBand items
        if ( not PtInRect(Items[FPressedIndex].Rect, TPoint.Create(X, Y)) )
        then begin
          FMouseDragItem := True;
          FMouseDragLinkbar := False;
        end;
      end;
    end;
  end;
end;

procedure TLinkbarWcl.FormMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if FAutoHiden
  then begin
    if ( (AutoShowMode = EAutoShowModeMouseClickLeft) and (Button =  mbLeft) )
       or
       ( (AutoShowMode = EAutoShowModeMouseClickRight) and (Button = mbRight) )
    then begin
      if PtInRect(Rect(0,0,Width,Height), Point(X, Y))
      then begin
        FCanAutoHide := False;
        DoAutoShow;
      end;
    end;
    Exit;
  end;

  // End of Ctrl+drag of the dock
  if FDockSliding and (Button = mbLeft)
  then begin
    FDockSliding := False;
    ReleaseCapture;
    Screen.Cursor := crDefault;
    if FSlideMoved
    then SaveDockPos
    else if (ItemIndexByPoint(Point(X, Y)) = ITEM_NONE)
    then begin
      // Ctrl+click on an empty area: center the dock again
      FDockPos := DEF_DOCK_POS;
      TSettingsFile.Write(FSettingsFileName, INI_DOCK_POS, FDockPos);
      oAppBar.AppBarPosChanged;
    end
    else DoClickItem(X, Y);
    Exit;
  end;

  FCanAutoHide := False;
  FMousePosUp := Point(X, Y);
  case Button of
    mbLeft:
      begin
        FMouseLeftDown := False;
        // drag linkbar end
        if FMouseDragLinkbar then
        begin
          FMouseDragLinkbar := False;
          FMonitorNum := FDragMonitorNum;
          Align := FDragAlign;
          TSettingsFile.Write(FSettingsFileName, INI_MONITORNUM, FMonitorNum);
          TSettingsFile.Write(FSettingsFileName, INI_EDGE, Integer(FAlign));
        end
        else if FMouseDragItem
        then begin // drag item end
          FMouseDragItem := False;
          FDragingItem := False;
          FDragIndex := ITEM_NONE;
        end
        else if (PressedIndex = ITEM_NONE)
             and FShowSysWidgets
             and PtInRect(SysWidgetRect(Width, Height), Point(X, Y))
             and PtInRect(SysWidgetRect(Width, Height), FMousePosDown)
        then begin // click on CPU/RAM widgets: open Task Manager
          ShellExecute(0, 'open', 'taskmgr.exe', nil, nil, SW_SHOWNORMAL);
        end
        else if (PressedIndex <> ITEM_NONE)
        then begin // click
          // If during the execute shortcut will be a modal window with the error
          // should be reset PressedIndex before
          PressedIndex := ITEM_NONE;
          DoClickItem(X, Y);
        end;
        PressedIndex := ITEM_NONE;
      end;
    mbMiddle:
      begin
        // Middle click: open a new window/instance of the program
        var idx := ItemIndexByPoint( Point(X, Y) );
        if IsItemIndex(idx)
           and (not Items.IsSeparator(Items[idx]))
        then begin
          if (Items[idx] is TItemGroup)
          then ShowGroup(idx)
          else if (Items[idx] is TItemAction)
          then RunActionItem(idx)
          else Items[idx].DoExecute(Handle);
        end;
      end
    else Exit;
  end;
end;

procedure TLinkbarWcl.DoDragItem(X, Y: Integer);
var
  FileName: string;
begin
  FDragIndex := ItemIndexByPoint( Point(X, Y) );
  if (FDragIndex <> ITEM_NONE)
  then begin
    HotIndex := ITEM_NONE;

    const item = Items[FDragIndex];
    if Items.IsSeparator(item)
    then FileName := Application.ExeName
    else FileName := item.FileName;

    DragFile(FileName);
    FormMouseUp(Self, mbLeft, [], -1, -1);
  end;
end;

procedure TLinkbarWcl.DoExecuteItem(const AIndex: Integer);
begin
  if not IsItemIndex(AIndex)
  then Exit;

  if (Items[AIndex] is TItemAction)
  then RunActionItem(AIndex)
  else if (Items[AIndex] is TItemGroup)
  then ShowGroup(AIndex)
  // Open program: bring it to the front / minimize / next window (like the taskbar)
  else if Items[AIndex].Running
          and ActivateProgram(Items[AIndex].TargetPath, FForegroundAtMouseDown)
  then Exit
  else Items[AIndex].DoExecute(Handle);
end;

{ Show group content as a popup grid of icons }
procedure TLinkbarWcl.ShowGroup(const AIndex: Integer);
begin
  const item = Items[AIndex];
  var itemRect := item.Rect;
  MapWindowPoints(Handle, HWND_DESKTOP, itemRect, 2);

  var form := TFormGroup.CreateGroup(Self, Handle, item.FileName, item.Caption,
    EnsureRange(IconSize, 32, 64));
  ToolTip.Cancel;
  form.OnDestroy := OnFormJumplistDestroy;
  form.OnDragOut := DragExternalFile;
  form.OnGroupChanged := GroupChanged;
  FLockHotIndex := True;
  FLockAutoHide := True;
  form.PopupAt(itemRect, Align);
end;

procedure TLinkbarWcl.DoClickItem(X, Y: Integer);
var iIndex: Integer;
begin
  iIndex := ItemIndexByPoint( Point(X, Y) );

  // Ctrl+Shift+click: run as administrator
  if IsItemIndex(iIndex)
     and (GetKeyState(VK_CONTROL) < 0)
     and (GetKeyState(VK_SHIFT) < 0)
     and (not Items.IsSeparator(Items[iIndex]))
     and (not (Items[iIndex] is TItemGroup))
     and (not (Items[iIndex] is TItemAction))
  then begin
    ShellExecute(Handle, 'runas', PChar(Items[iIndex].FileName), nil, nil, SW_SHOWNORMAL);
    Exit;
  end;

  DoExecuteItem(iIndex);
end;

procedure TLinkbarWcl.DoRenameItem(const AIndex: Integer);
var dlg: TRenamingWCl;
begin
  if not IsItemIndex(AIndex)
  then Exit;

  // Groups: ask only the name, keep the ".group" suffix
  if (Items[AIndex] is TItemGroup)
  then begin
    RenameGroup(AIndex);
    Exit;
  end;

  FLockAutoHide := True;
  dlg := TRenamingWCl.Create(Self);
  dlg.Pidl := Items[AIndex].Pidl;
  dlg.ShowModal;
  dlg.Free;
  FLockAutoHide := False;
end;

{ Drag a file that is not a bar item (an icon dragged out of a group window).
  Dropping it on the bar moves it into the links folder. }
procedure TLinkbarWcl.DragExternalFile(const AFileName: string; AIcon: HBITMAP; AIconSize: Integer);
begin
  FDragIndex := ITEM_NONE;
  FDragingItem := False;
  FExtDragIcon := AIcon;
  FExtDragIconSize := AIconSize;
  try
    DragFile(AFileName);
  finally
    FExtDragIcon := 0;
    FExtDragIconSize := 0;
  end;
end;

{ ---------- window in front / full screen ---------- }

function LB_SHQueryUserNotificationState(out pquns: Integer): HRESULT; stdcall;
  external 'shell32.dll' name 'SHQueryUserNotificationState';

function TLinkbarWcl.IsOurWindow(const AWnd: HWND): Boolean;
var pid: DWORD;
begin
  Result := True;
  if (AWnd = 0) or not IsWindow(AWnd) then Exit;
  pid := 0;
  GetWindowThreadProcessId(AWnd, @pid);
  Result := (pid = GetCurrentProcessId);
end;

procedure TLinkbarWcl.CheckForeground;
const
  QUNS_RUNNING_D3D_FULL_SCREEN = 3;
  QUNS_PRESENTATION_MODE = 4;
var
  fg: HWND;
  r: TRect;
  mon: Vcl.Forms.TMonitor;
  mr: TRect;
  cls: array[0..63] of Char;
  state: Integer;
  full: Boolean;
begin
  fg := GetForegroundWindow;
  if not IsOurWindow(fg)
  then FLastForeignWnd := fg;

  full := False;
  if FHideOnFullscreen and (fg <> 0) and not IsOurWindow(fg)
  then begin
    // Windows own detection (games, presentations)
    state := 0;
    if Succeeded(LB_SHQueryUserNotificationState(state))
       and ((state = QUNS_RUNNING_D3D_FULL_SCREEN) or (state = QUNS_PRESENTATION_MODE))
    then full := True
    else begin
      // A window that covers our whole monitor (video, browser F11, borderless games)
      cls[0] := #0;
      GetClassName(fg, cls, Length(cls));
      // desktop, taskbar, Start menu, task view: not "full screen apps"
      if not MatchText(PChar(@cls[0]), ['Progman', 'WorkerW', 'Shell_TrayWnd',
               'MultitaskingViewFrame', 'XamlExplorerHostIslandWindow',
               'Windows.UI.Core.CoreWindow', 'ForegroundStaging'])
         and not IsZoomed(fg)
         and GetWindowRect(fg, r)
      then begin
        // only when it is on the same monitor as the bar
        mon := Screen.MonitorFromWindow(fg, mdNearest);
        if Assigned(mon) and (mon = Screen.MonitorFromWindow(Handle, mdNearest))
        then begin
          mr := mon.BoundsRect;
          full := (r.Left <= mr.Left) and (r.Top <= mr.Top)
              and (r.Right >= mr.Right) and (r.Bottom >= mr.Bottom);
        end;
      end;
    end;
  end;

  if (full <> FHiddenByFullscreen)
  then begin
    FHiddenByFullscreen := full;
    if full
    then begin
      CloseThumbs;
      ToolTip.Cancel;
      ShowWindow(Handle, SW_HIDE);
    end
    else ShowWindow(Handle, SW_SHOWNA);
  end;
end;

procedure TLinkbarWcl.SetHideOnFullscreen(AValue: Boolean);
begin
  FHideOnFullscreen := AValue;
  if not AValue and FHiddenByFullscreen
  then begin
    FHiddenByFullscreen := False;
    ShowWindow(Handle, SW_SHOWNA);
  end;
end;

{ ---------- action buttons ---------- }

procedure TLinkbarWcl.RunActionItem(const AIndex: Integer);
var target: HWND;
begin
  target := FForegroundAtMouseDown;
  if IsOurWindow(target)
  then target := FLastForeignWnd;
  if IsOurWindow(target)
  then target := 0;
  ReleaseCapture;
  RunAction(TItemAction(Items[AIndex]).Data, target);
end;

procedure TLinkbarWcl.imNewActionClick(Sender: TObject);
var name: string;
    data: TActionData;
    fn: string;
    n: Integer;
begin
  name := '';
  data.Clear;
  FLockAutoHide := True;
  try
    if not EditAction(name, data, True)
    then Exit;
  finally
    FLockAutoHide := False;
  end;
  fn := WorkDir + name + ES_ACTION;
  n := 2;
  while FileExists(fn) do
  begin
    fn := WorkDir + name + ' ' + IntToStr(n) + ES_ACTION;
    Inc(n);
  end;
  ForceDirectories(WorkDir);
  SaveActionFile(fn, data); // the folder watcher adds it to the bar
end;

procedure TLinkbarWcl.imEditActionClick(Sender: TObject);
var item: TItemAction;
    name, oldFile, newFile: string;
    data: TActionData;
begin
  if not (IsItemIndex(FItemPopup) and (Items[FItemPopup] is TItemAction))
  then Exit;
  item := TItemAction(Items[FItemPopup]);
  oldFile := item.FileName;
  name := item.Caption;
  data := item.Data;
  FLockAutoHide := True;
  try
    if not EditAction(name, data, False)
    then Exit;
  finally
    FLockAutoHide := False;
  end;
  SaveActionFile(oldFile, data);
  newFile := ExtractFilePath(oldFile) + name + ES_ACTION;
  if not SameText(newFile, oldFile) and not FileExists(newFile)
     and RenameFile(oldFile, newFile)
  then item.FileName := newFile;
  // reload icon/data
  item.NeedLoad := True;
  tmrUpdate.Enabled := False;
  tmrUpdate.Enabled := True;
end;

procedure TLinkbarWcl.imDeleteActionClick(Sender: TObject);
begin
  if IsItemIndex(FItemPopup) and (Items[FItemPopup] is TItemAction)
  then SHDeleteOp(Handle, Items[FItemPopup].FileName, True);
end;

{ ---------- profiles ---------- }

function TLinkbarWcl.ProfilesDir: string;
begin
  Result := IncludeTrailingPathDelimiter(FLinksBaseDir) + PROFILES_DIR_NAME + '\';
end;

function TLinkbarWcl.ProfileDir(const AName: string): string;
begin
  if (AName = '')
  then Result := IncludeTrailingPathDelimiter(FLinksBaseDir)
  else Result := ProfilesDir + AName + '\';
end;

function TLinkbarWcl.GetProfileNames: TArray<string>;
var sr: TSearchRec;
    sl: TStringList;
begin
  sl := TStringList.Create;
  try
    if (FindFirst(ProfilesDir + '*', faDirectory, sr) = 0)
    then begin
      repeat
        if ((sr.Attr and faDirectory) <> 0) and (sr.Name <> '.') and (sr.Name <> '..')
        then sl.Add(sr.Name);
      until (FindNext(sr) <> 0);
      FindClose(sr);
    end;
    sl.Sort;
    Result := sl.ToStringArray;
  finally
    sl.Free;
  end;
end;

procedure TLinkbarWcl.ReloadLinks;
begin
  FHotIndex := ITEM_NONE;
  FPressedIndex := ITEM_NONE;
  FItemPopup := ITEM_NONE;
  GetOrCreateFilesList(WorkDir + LINKSLIST_FILE_NAME);
  for var item in Items do
    Items.LoadIcon(item);
  UpdateRunningState;
  oAppBar.AppBarPosChanged;
end;

procedure TLinkbarWcl.SwitchProfile(const AName: string);
var dir: string;
    settings: TSettingsFile;
begin
  if SameText(AName, FProfile) then Exit;
  dir := ProfileDir(AName);
  if not (DirectoryExists(dir) or ForceDirectories(dir)) then Exit;
  CloseThumbs;
  ToolTip.Cancel;
  SaveLinks;
  FProfile := AName;
  settings.Open(FSettingsFileName);
  settings.Write(INI_PROFILE, FProfile);
  settings.Close;
  WorkDir := dir;
  ReloadLinks;
end;

procedure TLinkbarWcl.CycleProfile(const ADelta: Integer);
var names: TArray<string>;
    i, cur: Integer;
begin
  names := [''] + GetProfileNames;
  if (Length(names) < 2) then Exit;
  cur := 0;
  for i := 0 to High(names) do
    if SameText(names[i], FProfile) then cur := i;
  cur := (cur + ADelta + Length(names)) mod Length(names);
  SwitchProfile(names[cur]);
end;

procedure TLinkbarWcl.BuildProfilesMenu;

  function Add(const ACaption, AHint: string; AOnClick: TNotifyEvent; AChecked: Boolean = False): TMenuItem;
  begin
    Result := TMenuItem.Create(pMenu);
    Result.Caption := ACaption;
    Result.Hint := AHint;
    Result.Checked := AChecked;
    Result.OnClick := AOnClick;
    imProfiles.Add(Result);
  end;

var name, mainName: string;
begin
  imProfiles.Clear;
  mainName := L10NFind('Profile.Main', 'Main');
  if (FProfile = '')
  then imProfiles.Caption := L10NFind('Menu.Profile', 'Profile') + ': ' + mainName
  else imProfiles.Caption := L10NFind('Menu.Profile', 'Profile') + ': ' + FProfile;

  Add(mainName, '', ProfileItemClick, FProfile = '');
  for name in GetProfileNames do
    Add(name, name, ProfileItemClick, SameText(name, FProfile));
  Add('-', '', nil);
  Add(L10NFind('Profile.New', 'New profile...'), '', ProfileNewClick);
  if (FProfile <> '')
  then begin
    Add(L10NFind('Profile.Rename', 'Rename this profile...'), '', ProfileRenameClick);
    Add(L10NFind('Profile.Delete', 'Delete this profile'), '', ProfileDeleteClick);
  end;
end;

procedure TLinkbarWcl.ProfileItemClick(Sender: TObject);
begin
  SwitchProfile(TMenuItem(Sender).Hint);
end;

function ValidProfileName(const AName: string): Boolean;
const InvalidChars = '\/:*?"<>|';
var ch: Char;
begin
  Result := (AName <> '') and (AName <> '.') and (AName <> '..');
  if Result then
    for ch in InvalidChars do
      if (Pos(ch, AName) > 0) then Exit(False);
end;

procedure TLinkbarWcl.ProfileNewClick(Sender: TObject);
var name: string;
begin
  name := '';
  FLockAutoHide := True;
  try
    if not InputQuery(L10NFind('Profile.NewTitle', 'New profile'),
                      L10NFind('Profile.NamePrompt', 'Profile name (for example Work):'), name)
    then Exit;
  finally
    FLockAutoHide := False;
  end;
  name := Trim(name);
  if not ValidProfileName(name)
  then Exit;
  if DirectoryExists(ProfileDir(name))
  then begin
    SwitchProfile(name);
    Exit;
  end;
  if ForceDirectories(ProfileDir(name))
  then SwitchProfile(name);
end;

procedure TLinkbarWcl.ProfileRenameClick(Sender: TObject);
var name, oldName: string;
    settings: TSettingsFile;
begin
  if (FProfile = '') then Exit;
  oldName := FProfile;
  name := oldName;
  FLockAutoHide := True;
  try
    if not InputQuery(L10NFind('Profile.RenameTitle', 'Rename profile'),
                      L10NFind('Profile.NamePrompt', 'Profile name (for example Work):'), name)
    then Exit;
  finally
    FLockAutoHide := False;
  end;
  name := Trim(name);
  if not ValidProfileName(name) or SameText(name, oldName)
     or DirectoryExists(ProfileDir(name))
  then Exit;
  // stop watching the folder before renaming it
  SaveLinks;
  WorkDir := FLinksBaseDir;
  if RenameFile(ExcludeTrailingPathDelimiter(ProfileDir(oldName)),
                ExcludeTrailingPathDelimiter(ProfileDir(name)))
  then FProfile := name;
  WorkDir := ProfileDir(FProfile);
  settings.Open(FSettingsFileName);
  settings.Write(INI_PROFILE, FProfile);
  settings.Close;
  ReloadLinks;
end;

procedure TLinkbarWcl.ProfileDeleteClick(Sender: TObject);
var name: string;
begin
  if (FProfile = '') then Exit;
  name := FProfile;
  FLockAutoHide := True;
  try
    if (MessageBox(Handle,
          PChar(Format(L10NFind('Profile.DeleteConfirm',
            'Delete the profile "%s"? Its icons go to the Recycle Bin.'), [name])),
          PChar(APP_NAME_LINKBAR), MB_ICONQUESTION or MB_YESNO) <> IDYES)
    then Exit;
  finally
    FLockAutoHide := False;
  end;
  SwitchProfile('');
  SHDeleteOp(Handle, ExcludeTrailingPathDelimiter(ProfileDir(name)), True);
end;

{ Content or color of an open group changed: reload its icon on the bar }
procedure TLinkbarWcl.GroupChanged(Sender: TObject);
var root: string;
begin
  if not (Sender is TFormGroup) then Exit;
  root := ExcludeTrailingPathDelimiter(TFormGroup(Sender).RootFolder);
  for var i := 0 to Items.Count-1 do
    if (Items[i] is TItemGroup)
       and SameText(ExcludeTrailingPathDelimiter(Items[i].FileName), root)
    then begin
      Items[i].NeedLoad := True;
      tmrUpdate.Enabled := False;
      tmrUpdate.Enabled := True;
      Break;
    end;
end;

procedure TLinkbarWcl.RenameGroup(const AIndex: Integer);
const InvalidChars: array[0..8] of Char = ('\', '/', ':', '*', '?', '"', '<', '>', '|');
var newName, oldPath, newPath: string;
    ch: Char;
begin
  oldPath := ExcludeTrailingPathDelimiter(Items[AIndex].FileName);
  newName := Items[AIndex].Caption;

  FLockAutoHide := True;
  try
    if not InputQuery(L10NFind('Group.RenameTitle', 'Rename group'),
                      L10NFind('Group.RenamePrompt', 'Name:'), newName)
    then Exit;
  finally
    FLockAutoHide := False;
  end;

  newName := Trim(newName);
  if (newName = '') or SameText(newName, Items[AIndex].Caption)
  then Exit;
  for ch in InvalidChars do
    if (Pos(ch, newName) > 0)
    then begin
      MessageDlg(L10NFind('Group.InvalidName', 'The name cannot contain: \ / : * ? " < > |'),
        mtWarning, [mbOK], 0);
      Exit;
    end;

  newPath := WorkDir + newName + ES_GROUP;
  if DirectoryExists(newPath) or FileExists(newPath)
  then begin
    MessageDlg(L10NFind('Group.NameExists', 'A group with this name already exists.'),
      mtWarning, [mbOK], 0);
    Exit;
  end;

  // The folder watcher updates the bar item (rename events)
  if not RenameFile(oldPath, newPath)
  then MessageDlg(SysErrorMessage(GetLastError), mtError, [mbOK], 0);
end;

procedure TLinkbarWcl.DoDelete(const AIndex: Integer);
begin
  if not IsItemIndex(AIndex)
  then Exit;

  Items.Delete(AIndex);
  UpdateWindowSize;
end;

procedure TLinkbarWcl.DoDragLinkbar(const X, Y: Integer);
var Pt: TPoint;
   mon: TMonitor;
   k: Double;
   e: TPanelAlign;
   r: TRect;
   w, h: Integer;
begin
  Pt := Point(X,Y);
  MapWindowPoints(Handle, HWND_DESKTOP, Pt, 1);
  mon := Screen.MonitorFromPoint(Pt);
  // translate to monitor coordinates
  Pt.Offset(-mon.Left, -mon.Top);
  // calc edge
  k := mon.Width/mon.Height;
  if Pt.X < Pt.Y*k then
  begin // left/bottom
    if Pt.X < (mon.Height-Pt.Y)*k
    then e := EPanelAlignLeft
    else e := EPanelAlignBottom;
  end else
  begin // top/right
    if (mon.Width-Pt.X) < Pt.Y*k
    then e := EPanelAlignRight
    else e := EPanelAlignTop;
  end;

  if (e = FDragAlign)
     and (mon.MonitorNum = FDragMonitorNum)
  then Exit;

  FDragAlign := e;
  FDragMonitorNum := mon.MonitorNum;

  if (FDragAlign = FAlign)
     and (FDragMonitorNum = FMonitorNum)
  then begin // it's position before drag
    r := FBeforeDragBounds;
  end
  else begin
    if AutoHide
    then
      r := mon.BoundsRect
    else begin
      r := mon.WorkareaRect;

      if IsHorizontal(FDragAlign)
      then begin
        r.Left := MonitorsWorkareaWoTaskbar[FDragMonitorNum].Left;
        r.Right := MonitorsWorkareaWoTaskbar[FDragMonitorNum].Right;
      end;

      // Correct new rect
      if (FDragMonitorNum = FMonitorNum)
         and IsVertical(FDragAlign)
      then begin
        case FAlign of
          EPanelAlignTop: r.Top := r.Top - FBeforeDragBounds.Height;
          EPanelAlignBottom: r.Bottom := r.Bottom + FBeforeDragBounds.Height;
        end;
      end;
    end;

    w := r.Width;
    h := r.Height;

    QuerySizingEvent(nil, IsVertical(e), w, h);
    case FDragAlign of
      EPanelAlignRight: r.Left := r.Right - w;
      EPanelAlignBottom: r.Top := r.Bottom - h;
    end;
    r.Width := w;
    r.Height := h;
  end;
  QuerySizedEvent(nil, r.Left, r.Top, r.Width, r.Height);
end;

// Macros from windowsx.h:
// Important  Do not use the LOWORD or HIWORD macros to extract the x- and y-
// coordinates of the cursor position because these macros return incorrect results
// on systems with multiple monitors. Systems with multiple monitors can have
// negative x- and y- coordinates, and LOWORD and HIWORD treat the coordinates
// as unsigned quantities.
function MakePoint(const L: DWORD): TPoint; inline;
Begin
  Result := TPoint.Create(SmallInt(L and $FFFF), SmallInt(L shr 16));
End;

procedure TLinkbarWcl.DoPopupMenu(APt: TPoint; AShift: Boolean);
var
  FPopupMenu: HMENU;
  Flags: Integer;
  mii: TMenuItemInfo;
  mi: TMenuInfo;
  iconsize: Integer;
  icon: HICON;
  bmp: HBITMAP;
  caption: string;
begin
  FPopupMenu := CreatePopupMenu;
  if (FPopupMenu = 0)
  then Exit;

  BuildProfilesMenu;
  var isAction := IsItemIndex(FItemPopup) and (Items[FItemPopup] is TItemAction);

  //for i := 0 to pMenu.Items.Count-1 do
  for var item: TMenuItem in pMenu.Items
  do begin
    if (AShift)
    then begin
      if item.Tag = 20 // Hide in extended menu
      then Continue;
    end
    else begin
      if item.Tag = 10 // Hide in regular menu
      then Continue;
    end;

    // "Edit/Delete action" only for action buttons
    if ((item = imEditAction) or (item = imDeleteAction) or (item = imActionLine))
       and not isAction
    then Continue;

    Flags := MF_BYCOMMAND;

    if (item.IsLine)
    then Flags := Flags or MF_SEPARATOR
    else Flags := Flags or MF_STRING;

    if (item = imLockBar)
       and (FLockLinkbar)
    then Flags := Flags or MF_CHECKED;

    if (item = imSortAlphabet)
       and (FSortAlphabetically)
    then Flags := Flags or MF_CHECKED;

    if (item.Count = 0)
    then begin
      caption := item.Caption;
      //if (item = imClose)
      //then caption := caption + #9 + 'Alt+F4';
      AppendMenu(FPopupMenu, Flags, item.Command, PChar(caption));
    end
    else begin
      var subMenu := CreatePopupMenu;

      for var subItem: TMenuItem in item
      do begin
        Flags := MF_BYCOMMAND;
        if (subItem.IsLine)
        then Flags := Flags or MF_SEPARATOR
        else Flags := Flags or MF_STRING;
        if subItem.Checked
        then Flags := Flags or MF_CHECKED;
        AppendMenu(subMenu, Flags, subItem.Command, PChar(subItem.Caption));
      end;

      Flags := MF_POPUP or MF_STRING;
      AppendMenu(FPopupMenu, Flags, subMenu, PChar(item.Caption));
    end;
  end;

  // Set icon&default for "Close" or "Close All" menu item
  mii := Default(TMenuItemInfo);
  mii.cbSize := SizeOf(mii);
  mii.fMask := MIIM_BITMAP or MIIM_STATE;
  mii.fState := MFS_DEFAULT;
  mii.hbmpItem := HBMMENU_POPUP_CLOSE;
  if (AShift)
  then SetMenuItemInfo(FPopupMenu, imCloseAll.Command, False, mii)
  else SetMenuItemInfo(FPopupMenu, imClose.Command, False, mii);

  // Set icon for "New shortcut" menu item
  bmp := 0;
  iconsize := GetSystemMetrics(SM_CXSMICON);
  icon := LoadImage(GetModuleHandle('shell32.dll'), MakeIntResource(16769), IMAGE_ICON, iconsize, iconsize, LR_DEFAULTCOLOR);
  if (icon <> 0)
  then begin
    bmp := BitmapFromIcon(icon, iconsize);
    DestroyIcon(icon);
    mii := Default(TMenuItemInfo);
    mii.cbSize := SizeOf(mii);
    mii.fMask := MIIM_BITMAP;
    mii.hbmpItem := bmp;
    SetMenuItemInfo(FPopupMenu, imNewShortcut.Command, False, mii);
  end;

  mi := Default(TMenuInfo);
  mi.cbSize := SizeOf(TMenuInfo);
  mi.fMask := MIM_STYLE;
  mi.dwStyle := MNS_CHECKORBMP;
  SetMenuInfo(FPopupMenu, mi);

  MapWindowPoints(Handle, HWND_DESKTOP, APt, 1);

  FLockHotIndex := True;
  FLockAutoHide := True;
  try
    ToolTip.Cancel;
    if (FItemPopup = ITEM_NONE)
    then begin
      // Execute Linkbar context menu
      const command = TrackPopupMenuEx(FPopupMenu, TPM_RETURNCMD or TPM_RIGHTBUTTON or TPM_NONOTIFY, APt.X, APt.Y, Handle, nil);
      DestroyMenu(FPopupMenu);
      if (command)
      then PostMessage(Handle, LM_CM_ITEMS, 0, Integer(command));
    end
    else begin
      // Execute Shell context menu + Linkbar context menu as submenu
      // FPopupMenu will be destroyed automatically
      Items[FItemPopup].DoPopupMenu(Handle, APt, AShift, FPopupMenu);
    end;
  finally
    FLockHotIndex := False;
    if (WindowFromPoint(MakePoint(GetMessagePos)) <> Handle)
    then begin
      HotIndex := ITEM_NONE;
    end;
    FLockAutoHide := False;
  end;

  DeleteObject(bmp);
end;

procedure TLinkbarWcl.OnFormJumplistDestroy(Sender: TObject);
begin
  if (not (csDestroying in Self.ComponentState))
  then begin
    FLockHotIndex := False;
    if (WindowFromPoint(MakePoint(GetMessagePos)) <> Handle)
    then begin
      HotIndex := ITEM_NONE;
    end;
    FLockAutoHide := False;
    FCanAutoHide := True;
    DoAutoHide;
  end;
end;

procedure TLinkbarWcl.DoPopupJumplist(APt: TPoint; AShift: Boolean);
begin
  if (FJumplistShowMode <> EJumplistShowModeDisabled)
  then begin
    const item = Items[FItemPopup];
    var form := TryCreateJumplist(Self, item.Pidl, FJumplistRecentMax);
    if Assigned(form)
    then begin
      var itemRect := item.Rect;
      MapWindowPoints(Handle, HWND_DESKTOP, itemRect, 2);

      if form.Popup(Handle, itemRect, Align)
      then begin
        ToolTip.Cancel;
        form.OnDestroy := OnFormJumplistDestroy;
        FLockHotIndex := True;
        FLockAutoHide := True;
        Exit;
      end;
    end;
  end;

  { Show shell context menu }
  DoPopupMenu(APt, AShift);
end;

procedure TLinkbarWcl.FormContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
begin
  Handled := True;

  if FAutoHiden then Exit;

  var pt := MousePos;
  if (pt.X = -1) and (pt.Y = -1)
  then begin
    // Pressed keyboard key "Menu"
    FItemPopup := HotIndex;
    if IsItemIndex(FItemPopup)
    then pt := Items[HotIndex].Rect.CenterPoint
    else pt := Point(0, 0);
  end
  else
    FItemPopup := ItemIndexByPoint(pt);

  HotIndex := FItemPopup;

  var shift := GetKeyState(VK_SHIFT) < 0;

  if (FItemPopup = ITEM_NONE)
     or (shift) // show extended contextmenu for item with jumplist
     or (Items[FItemPopup] is TItemGroup) // groups: menu with Rename/Delete, no jumplist
  then DoPopupMenu(pt, shift)
  else DoPopupJumplist(pt, shift);
end;

procedure TLinkbarWcl.SetAutoHide(AValue: Boolean);
begin
  // Dock mode has no autohide
  if IsDock and AValue
  then begin
    FAutoHide := False;
    Exit;
  end;
  oAppBar.AutoHide := AValue;
  FAutoHide := oAppBar.AutoHide;
end;

procedure TLinkbarWcl.SetButtonSize(AValue: TSize);
begin
  if (AValue = FButtonSize)
  then Exit;

  FButtonSize := AValue;
  RecreateButtonBitmap(FButtonSize.Width, FButtonSize.Height);
end;

procedure TLinkbarWcl.UpdateItemSizes;
var
  r: TRect;
  w, h: Integer;
  textHeight: Integer;
begin
  // Calc text height
  Canvas.Font := Screen.IconFont;
  if (TextLayout = ETextLayoutNone)
  then textHeight := 0
  else textHeight := DrawText(Canvas.Handle, 'Wp', 2, r, DT_SINGLELINE or DT_NOCLIP or DT_CALCRECT);

  // Calc margin, icon offset & button size
  case TextLayout of
  ETextLayoutLeft, ETextLayoutRight:
    begin
      // button size
      w := FItemMargin.cx + FIconSize + FTextOffset + FTextWidth + FItemMargin.cx;
      h := FItemMargin.cy + Max(FIconSize, textHeight) + FItemMargin.cy;
      // icon offset
      if (TextLayout = ETextLayoutRight)
      then FIconOffset.X := FItemMargin.cx
      else FIconOffset.X := FItemMargin.cx + FTextWidth + FTextOffset;
      FIconOffset.Y := (h - FIconSize) div 2;
      // text rect
      if (TextLayout = ETextLayoutRight)
      then FTextRect := Bounds( FItemMargin.cx + FIconSize + FTextOffset, (h - textHeight) div 2, FTextWidth, textHeight )
      else FTextRect := Bounds( FItemMargin.cx, (h - textHeight) div 2, FTextWidth, textHeight );
    end;
  ETextLayoutTop, ETextLayoutBottom:
    begin
      // button size
      w := FItemMargin.cx + Max(FIconSize, FTextWidth) + FItemMargin.cx;
      h := FItemMargin.cy + FIconSize + FTextOffset + textHeight + FItemMargin.cy;
      // icon offset
      FIconOffset.X := (w - FIconSize) div 2;
      if (TextLayout = ETextLayoutBottom)
      then FIconOffset.Y := FItemMargin.cy
      else FIconOffset.Y := FItemMargin.cy + textHeight + FTextOffset;
      // text rect
      if (TextLayout = ETextLayoutBottom)
      then FTextRect := Bounds( FTextOffset, FItemMargin.cy + FIconSize + FTextOffset, w - 2*FTextOffset, textHeight )
      else FTextRect := Bounds( FTextOffset, FItemMargin.cy, w - 2*FTextOffset, textHeight );
    end;
  else
    begin
      w := FItemMargin.cx + FIconSize + FItemMargin.cx;
      h := FItemMargin.cy + FIconSize + FItemMargin.cy;
      FIconOffset := Point(FItemMargin.cx, FItemMargin.cy);
    end;
  end;

  ButtonSize := TSize.Create(w, h);
end;

procedure TLinkbarWcl.SetIconSize(AValue: integer);
begin
  if AValue = FIconSize then Exit;
  FIconSize := EnsureRange(AValue, ICON_SIZE_MIN, ICON_SIZE_MAX);
  Items.IconSize := FIconSize;
  Items.ZoomIconSize := ZoomIconSizeValue;
end;

procedure TLinkbarWcl.SetIsLightStyle(AValue: Boolean);
begin
  if AValue = FIsLightStyle then Exit;
  FIsLightStyle := AValue;
  ThemeInitData(Handle, FIsLightStyle);
end;

procedure TLinkbarWcl.SetItemMargin(AValue: TSize);
begin
  if AValue = FItemMargin then Exit;
  FItemMargin := AValue;
end;

procedure TLinkbarWcl.SetTextLayout(AValue: TTextLayout);
begin
  if AValue = FTextLayout then Exit;
  FTextLayout := AValue;
end;

procedure TLinkbarWcl.SetTextOffset(AValue: Integer);
begin
  if AValue = FTextOffset then Exit;
  FTextOffset := AValue;
end;

procedure TLinkbarWcl.SetTextWidth(AValue: Integer);
begin
  if AValue = FTextWidth then Exit;
  FTextWidth := AValue;
end;

procedure TLinkbarWcl.SetItemOrder(AValue: TItemOrder);
begin
  if AValue = FItemOrder then Exit;
  FItemOrder := AValue;
end;

procedure TLinkbarWcl.SetPressedIndex(AValue: integer);
begin
  if AValue = FPressedIndex then Exit;
  ToolTip.Cancel;
  FPressedIndex := AValue;

  if (FPressedIndex <> FHotIndex)
  then HotIndex := FPressedIndex;

  if ZoomEnabled
  then Exit; // no pressed effect over magnified icons

  DrawItem(BitmapPanel, FHotIndex, True, FPressedIndex <> ITEM_NONE);
  UpdateWindow;
end;

procedure TLinkbarWcl.SetHotIndex(AValue: integer);
var
  Pt: TPoint;
  HA: TAlignment;
  VA: TVerticalAlignment;
begin
  if not IsItemIndex(AValue)
  then AValue := ITEM_NONE;

  if (FLockHotIndex)
     or (AValue = FHotIndex)
  then Exit;

  if ZoomEnabled
  then FHotIndex := AValue // magnification replaces the hover highlight
  else begin
    if (FHotIndex >= 0)
    then begin // restore pred selected item
      const r = Items[FHotIndex].Rect;
      BitBlt(BitmapPanel.Dc, r.Left, r.Top, r.Width, r.Height, BitmapSelected.Dc, 0, 0, SRCCOPY);
    end;

    FHotIndex := AValue;

    if (FHotIndex >= 0)
    then begin // store current item
      const r = Items[FHotIndex].Rect;
      BitBlt(BitmapSelected.Dc, 0, 0, r.Width, r.Height, BitmapPanel.Dc, r.Left, r.Top, SRCCOPY);
    end;

    DrawItem(BitmapPanel, FHotIndex, True, False); // draw current selected item

    UpdateWindow;
  end;

  // show hint
  if (TooltipShow)
     and (FHotIndex >= 0)
     and (not Items.IsSeparator(Items[FHotIndex]))
  then begin
    const r = Items[FHotIndex].Rect;
    case Align of
      EPanelAlignLeft:
        begin
          Pt.X := r.Right + TOOLTIP_OFFSET;
          Pt.Y := r.CenterPoint.Y;
          VA := taVerticalCenter;
          HA := taLeftJustify;
        end;
      EPanelAlignTop:
        begin
          Pt.X := r.CenterPoint.X;
          Pt.Y := r.Bottom + TOOLTIP_OFFSET;
          VA := taAlignBottom;
          HA := taCenter;
        end;
      EPanelAlignRight:
        begin
          Pt.X := r.Left - TOOLTIP_OFFSET;
          Pt.Y := r.CenterPoint.Y;
          VA := taVerticalCenter;
          HA := taRightJustify;
        end;
      EPanelAlignBottom:
        begin
          Pt.X := r.CenterPoint.X;
          Pt.Y := r.Top - TOOLTIP_OFFSET;
          VA := taAlignTop;
          HA := taCenter;
        end
      else begin
        HA := taLeftJustify;
        VA := taAlignBottom;
      end;
    end;
    MapWindowPoints(Handle, HWND_DESKTOP, Pt, 1);
    if (Items[FHotIndex] is TItemAction)
    then ToolTip.Activate(Pt, TItemAction(Items[FHotIndex]).Description, HA, VA)
    else ToolTip.Activate(Pt, Items[FHotIndex].Caption, HA, VA);
  end
  else begin
    ToolTip.Cancel;
  end;

  ThumbsHotChanged;
end;

procedure TLinkbarWcl.SetHotkeyInfo(AValue: THotkeyInfo);
begin
  if (FHotkeyInfo = AValue)
  then Exit;

  FHotkeyInfo := AValue;
  if (AutoHide)
  then RegisterHotkeyNotify(Handle, FHotkeyInfo)
  else UnregisterHotkeyNotify(Handle);
end;

procedure TLinkbarWcl.SetLayout(AValue: TPanelLayout);
begin
  if (FLayout = AValue)
  then Exit;

  FLayout := AValue;
  GlobalLayout := FLayout;

  //RecreateMainBitmap(Width, Height);
  //UpdateWindow;
end;

procedure TLinkbarWcl.SetAlign(AValue: TPanelAlign);
begin
  //if (FScreenEdge = AValue)
  //then Exit;

  FAlign := AValue;
  FDragAlign := FAlign;
  oAppBar.MonitorNum := FMonitorNum;
  oAppBar.Align := AValue;
end;

procedure TLinkbarWcl.SetSortAlphabetically(AValue: Boolean);
begin
  if (FSortAlphabetically = AValue)
  then Exit;

  FSortAlphabetically := AValue;
  TSettingsFile.Write(FSettingsFileName, INI_SORT_AB, FSortAlphabetically);

  if FSortAlphabetically
  then begin
    Items.Sort;
    RecreateMainBitmap(BitmapPanel.Width, BitmapPanel.Height);
    UpdateWindow;
  end;
end;

procedure TLinkbarWcl.SetStayOnTop(AValue: Boolean);
const FORM_STYLE: array[Boolean] of TFormStyle = (fsNormal, fsStayOnTop);
begin
  if (FStayOnTop = AValue)
  then Exit;

  FStayOnTop := AValue;
  Self.FormStyle := FORM_STYLE[FStayOnTop];

  if Assigned(oAppBar)
  then oAppBar.StayOnTop := FStayOnTop;
end;

procedure TLinkbarWcl.QuerySizingEvent(Sender: TObject; AVertical: Boolean; var AWidth, AHeight: Integer);
begin
  Items.Sizes.Button := ButtonSize;
  Items.Sizes.Separator := SeparatorWidth;
  Items.Sizes.Margin := ItemsMargin;
  Items.Sizes.ZoomRoom := ZoomRoom;
  Items.Sizes.ZoomBefore := ZoomBefore;
  Items.Sizes.Reserved := SysWidgetLength(AVertical);
  Items.UpdateLines(AVertical, AWidth, AHeight);

  if (AVertical)
  then AWidth := ButtonSize.Width * Items.Lines.Count + ZoomRoom
  else AHeight := ButtonSize.Height * Items.Lines.Count + ZoomRoom;
end;

procedure TLinkbarWcl.QuerySizedEvent(Sender: TObject; const AX, AY, AWidth,
  AHeight: Integer);
var r: TRect;
    x, y, w, h: Integer;
begin
  x := AX; y := AY; w := AWidth; h := AHeight;
  // Dock mode: small floating bar centered on the edge
  if IsDock
  then DockBounds(x, y, w, h);

  FBeforeAutoHideBound := Bounds(x, y, w, h);
  RecreateMainBitmap(w, h);

  if (AutoHide and FAutoHiden)
  then r := FAfterAutoHideBound
  else r := FBeforeAutoHideBound;

  MoveWindow(Handle, r.Left, r.Top, r.Width, r.Height, False);
  ApplyDockRegion(r.Width, r.Height);
  UpdateWindow(r);
end;

procedure TLinkbarWcl.QueryHideEvent(Sender: TObject; AEnabled: boolean);
begin
  FAutoHide := AEnabled;
end;

procedure TLinkbarWcl.UpdateBackgroundColor;
var lookmode: TLookMode;
begin
  lookmode.Color := FLook;
  lookmode.Transparency := FTransparencyMode;
  ThemeGetTaskbarColor(FSysBackgroundColor, lookmode);
end;

function TLinkbarWcl.GetBackgroundColor: Cardinal;
begin
  if (FUseBkgndColor)
  then Result := FBackgroundColor
  else Result := FSysBackgroundColor;
end;

procedure TLinkbarWcl.UpdateWindowSize;
var
  t, l, w, h: Integer;
begin
  // Dock: its length depends on the content, recalculate position and size
  if IsDock and Assigned(oAppBar)
  then begin
    oAppBar.AppBarPosChanged;
    Exit;
  end;

  Items.Sizes.Button := ButtonSize;
  Items.Sizes.Separator := SeparatorWidth;
  Items.Sizes.Margin := ItemsMargin;
  Items.Sizes.ZoomRoom := ZoomRoom;
  Items.Sizes.ZoomBefore := ZoomBefore;
  Items.Sizes.Reserved := SysWidgetLength(IsVertical(Align));
  Items.UpdateLines(IsVertical(Align), Width, Height);

  t := Top;
  l := Left;
  w := Width;
  h := Height;

  if IsVertical(Align) then
  begin
    w := ButtonSize.Width * Items.Lines.Count + ZoomRoom;
    if (Align = EPanelAlignRight)
    then l := Left + Width - w;
  end else
  begin
    h := ButtonSize.Height * Items.Lines.Count + ZoomRoom;
    if (Align = EPanelAlignBottom)
    then t := Top + Height - h;
  end;

  RecreateMainBitmap(w, h);
  MoveWindow(Self.Handle, l, t, w, h, FALSE);
  UpdateWindow(Bounds(l, t, w, h));
end;

// Important  Do not use the LOWORD or HIWORD macros to extract the x- and y-
// coordinates of the cursor position because these macros return incorrect results
// on systems with multiple monitors. Systems with multiple monitors can have
// negative x- and y- coordinates, and LOWORD and HIWORD treat the coordinates
// as unsigned quantities.

// Macros from windowsx.h

function GET_X_LPARAM(const uLParam: LPARAM): Integer;
begin
  Result := Integer(uLParam and $FFFF);
end;

function GET_Y_LPARAM(const uLParam: LPARAM): integer;
begin
  Result := Integer((uLParam shr 16) and $FFFF);
end;

procedure TLinkbarWcl.FormResize(Sender: TObject);
begin
  if not FCreated
  then Exit;
  UpdateBlur;
end;

procedure TLinkbarWcl.WndProc(var Msg: TMessage);
begin
  case Msg.Msg of
    //CUSTOM_ABN_FULLSCREENAPP:
    //  begin
    //    oAppBar.AppBarFullScreenApp(Msg.LParam <> 0);
    //  end;
    // DWM Messages
    { TODO: Provide this message for Windows Vista
    WM_DWMWINDOWMAXIMIZE: {}
    (*
    WM_SIZE:
      begin
        Msg.Result := 0;
        if not FCreated then Exit;
        UpdateBlur;
      end; *)
    (*
    WM_SETFOCUS:
      begin
        {$IFDEF DEBUGUS}DebugusMessage('WM_SETFOCUS');{$ENDIF}
        Msg.Result := 0;
        FCanAutoHide := False;
        DoAutoShow;
      end;
    *)
    //WM_WINDOWPOSCHANGED:
    //  begin
        //Beep;
        //p := PWindowPos(Msg.LParam);
        //{$IFDEF DEBUGUS}DebugusMessage( Format('WPC: %d %d %d %d %d %d flags %s', [p.hwnd, p.hwndInsertAfter, p.x, p.y, p.cx, p.cy, GetSwpFlags(p.flags)]) );{$ENDIF}
    //  end;
    WM_THEMECHANGED:
      begin
        inherited;
        Msg.Result := 0;
        if not FCreated then Exit;
        ThemeInitData(Handle, IsLightStyle);
        Exit;
      end;
    WM_SETTINGCHANGE:
      begin
        inherited;
        if (not FCreated)
           //or (Msg.WParam <> SPI_GETICONTITLELOGFONT)
        then Exit;
        UpdateItemSizes;
        RecreateMainBitmap(BitmapPanel.Width, BitmapPanel.Height);
        UpdateWindow;

        if SameText(PChar(Msg.LParam), 'ImmersiveColorSet')
        then begin
          OutputDebugString('1');
          if Assigned(ToolTip)
          then ToolTip.ThemeChanged;
        end;

        Exit;
      end;
    CM_FONTCHANGED:
      begin
        inherited;
        if not FCreated then Exit;
        UpdateItemSizes;
        RecreateMainBitmap(BitmapPanel.Width, BitmapPanel.Height);
        UpdateWindow;
        Exit;
      end;
    WM_SYSCOLORCHANGE:
      begin
        inherited;
        if not FCreated then Exit;
        HotIndex := ITEM_NONE;
        RecreateMainBitmap(BitmapPanel.Width, BitmapPanel.Height);
        RecreateButtonBitmap(FButtonSize.Width, FButtonSize.Height);
        UpdateWindow;
        Exit;
      end;
    WM_DWMCOLORIZATIONCOLORCHANGED:
      begin
        Msg.Result := 0;
        if not FCreated then Exit;

        UpdateBackgroundColor;

        if IsWindows10
        then ApplyWindowAccent;

        // In Windows 8+ theme color may changed smoothly
        HotIndex := ITEM_NONE;
        RecreateMainBitmap(BitmapPanel.Width, BitmapPanel.Height); // <== THIS
        RecreateButtonBitmap(FButtonSize.Width, FButtonSize.Height);
        UpdateWindow;
      end;
    WM_DWMCOMPOSITIONCHANGED:
      // NOTE: As of Windows 8, DWM composition is always enabled, so this message is
      // not sent regardless of video mode changes.
      begin
        inherited;
        Msg.Result := 0;
        if not FCreated then Exit;
        ThemeInitData(Handle, IsLightStyle);
        UpdateItemSizes;
        UpdateBlur;
      end;
    WM_ACTIVATE:
      begin
        //Msg.Result := 0;
      end;
    WM_KILLFOCUS:
      begin
        inherited;
        //Msg.Result := 0;
        if (csDestroying in ComponentState)
        then Exit;
        FCanAutoHide := not Assigned(FrmProperties);
        DoAutoHide;
        Exit;
      end;
    { Display stste changed (count/size/rotate) }
    WM_DISPLAYCHANGE:
      begin
        inherited;
        Msg.Result := 0;
        if not FCreated then Exit;
        // force update Screen
        FMonitorNum := Self.Monitor.MonitorNum; // or Screen.MonitorFromWindow(0, mdNull);
        oAppBar.MonitorNum := FMonitorNum;
        oAppBar.AppBarPosChanged;
        Exit;
      end;
    { Delayed auto show (timer) }
    WM_MOUSEACTIVATE:
      begin
        // remember the window in front before the bar gets activated
        FForegroundAtMouseDown := GetForegroundWindow;
        if not IsOurWindow(FForegroundAtMouseDown)
        then FLastForeignWnd := FForegroundAtMouseDown;
      end;
    WM_MOUSEWHEEL:
      // Ctrl + mouse wheel: next / previous profile
      if (GetKeyState(VK_CONTROL) < 0)
      then begin
        if (SmallInt(Msg.WParamHi) < 0)
        then CycleProfile(1)
        else CycleProfile(-1);
        Msg.Result := 0;
        Exit;
      end;
    WM_TIMER:
      begin
        case Msg.WParam of
          TIMER_AUTO_SHOW:
            begin
              KillTimer(Handle, TIMER_AUTO_SHOW);
              DoAutoShow;
              Exit;
            end;
          TIMER_AUTO_HIDE:
            begin
              KillTimer(Handle, TIMER_AUTO_HIDE);
              DoAutoHide;
              Exit;
            end;
          TIMER_SYS_WIDGETS:
            begin
              RefreshSysWidgets;
              Exit;
            end;
          TIMER_RUNNING:
            begin
              UpdateRunningState;
              Exit;
            end;
          TIMER_FOREGROUND:
            begin
              CheckForeground;
              Exit;
            end;
          TIMER_THUMBS:
            begin
              KillTimer(Handle, TIMER_THUMBS);
              ShowThumbs(FHotIndex);
              Exit;
            end;
        end;
      end;
    { Messages from ShellContextMenu }
    LM_CM_RENAME:
      begin
        DoRenameItem(FItemPopup);
        Exit;
      end;
    LM_CM_ITEMS:
      begin
        DoPopupMenuItemExecute(Msg.LParam);
        Exit;
      end;
    LM_CM_INVOKE:
      begin
        JumpListClose;
        Exit;
      end;
    LM_CM_DELETE:
      begin
        DoDelete(FItemPopup);
        Exit;
      end;
    { WatchDir stop }
    LM_STOPDIRWATCH:
      begin
        StopDirWatch;
        Exit;
      end;
    { Bit Bucket image changed }
    LM_SHELLNOTIFY:
      begin
        UpdateBitBuckets;
        Exit;
      end;
    { Settings/Rename dialog destroyed }
    LM_DOAUTOHIDE:
      begin
        FCanAutoHide := not Focused;
        DoAutoHide;
        Exit;
      end;
  end;

  inherited WndProc(Msg);
end;

function SetForegroundWindowInternal(AWnd: HWND): HWND;
var ip: TInput; // This structure will be used to create the keyboard input event.
begin
  if not IsWindow(AWnd)
  then Exit(0);

  Result := GetForegroundWindow;

  // First try plain SetForegroundWindow
  SetForegroundWindow(AWnd);
  if (AWnd = GetForegroundWindow)
  then Exit;

  // Set up a generic keyboard event.
  FillChar(ip, SizeOf(ip), 0);
  ip.Itype := INPUT_KEYBOARD;
  // Press the "Alt" key
  ip.ki.wVk := VK_MENU; // virtual-key code for the "Alt" key
  ip.ki.dwFlags := 0;   // 0 for key press
  SendInput(1, ip, SizeOf(ip));

  //Sleep(100); //Sometimes SetForegroundWindow will fail and the window will flash instead of it being show. Sleeping for a bit seems to help.
  Application.ProcessMessages;

  SetForegroundWindow(AWnd);

  // Release the "Alt" key
  ip.ki.dwFlags := KEYEVENTF_KEYUP; // for key release
  SendInput(1, ip, sizeof(ip));
end;

procedure TLinkbarWcl.WmHotKey(var Msg: TMessage);
begin
  if (Msg.Msg = WM_HOTKEY)
     and (Msg.WParam = LB_HOTKEY_ID)
     and (Msg.LParamHi = FHotkeyInfo.KeyCode)
     and (Msg.LParamLo = FHotkeyInfo.Modifiers)
     and AutoHide
     //and (FAutoShowMode = smHotkey)
  then begin
    if (FAutoHiden)
    then begin
      FPrevForegroundWnd := SetForegroundWindowInternal(Handle);
      FCanAutoHide := False;
      DoAutoShow;
    end
    else begin
      //SetForegroundWindow(FPrevForegroundWnd);
      // Linkbar will be hidden when it loses Focus
      //DoAutoHide;
    end;
    Exit;
  end;

  inherited;
end;

procedure TLinkbarWcl.UpdateBitBuckets;
begin
  Items.BitBucketUpdateIcon;
  if FAutoHiden
  then RecreateMainBitmap(FBeforeAutoHideBound.Width, FBeforeAutoHideBound.Height)
  else begin
    RecreateMainBitmap(Width, Height);
    UpdateWindow;
  end;
end;

procedure TLinkbarWcl.DoPopupMenuItemExecute(const ACmd: Integer);
var mi: TMenuItem;
begin
  mi := pMenu.FindItem(ACmd, fkCommand);
  if Assigned(mi)
  then mi.Click;
end;

procedure TLinkbarWcl.imPropertiesClick(Sender: TObject);
begin
  if Assigned(FrmProperties)
  then FrmProperties.BringToFront
  else
  begin
    FrmProperties := TFrmProperties.Create(Self);
    FrmProperties.Caption := APP_NAME_LINKBAR + ' - ' + PanelName;
    FrmProperties.Show;
  end;
end;

procedure TLinkbarWcl.imCloseAllClick(Sender: TObject);
begin
  TLinkbarWcl.CloseAll;
end;

procedure TLinkbarWcl.imCloseClick(Sender: TObject);
begin
  StopDirWatch;
  Close;
end;

procedure TLinkbarWcl.imLockBarClick(Sender: TObject);
begin
  FLockLinkbar := not FLockLinkbar;
  TSettingsFile.Write(FSettingsFileName, INI_LOCK_BAR, FLockLinkbar);
end;

procedure TLinkbarWcl.imNewLinkbarClick(Sender: TObject);
var cmd: string;
begin
  cmd := LBCreateCommandParam(CLK_NEW, '');
  if (Locale <> '')
  then cmd := cmd + LBCreateCommandParam(CLK_LANG, Locale);
  LBCreateProcess(ParamStr(0), cmd);
end;

procedure TLinkbarWcl.imNewShortcutClick(Sender: TObject);
begin
  NewShortcut(WorkDir);
end;

procedure TLinkbarWcl.imNewSeparatorClick(Sender: TObject);
begin
  var item := TItemSeparator.Create;
  if (FItemPopup <> ITEM_NONE)
  then Items.Insert(FItemPopup, item)
  else Items.Add(item);
  UpdateWindowSize;
end;

{ New empty group: sub-folder "<name>.group". The folder watcher adds it to the bar.
  Drag shortcuts from the bar onto the group icon to move them inside. }
procedure TLinkbarWcl.imNewGroupClick(Sender: TObject);
var baseName, dirName: string;
    n: Integer;
begin
  baseName := L10NFind('Menu.GroupDefaultName', 'Group');
  dirName := WorkDir + baseName + ES_GROUP;
  n := 2;
  while DirectoryExists(dirName) or FileExists(dirName) do
  begin
    dirName := WorkDir + baseName + ' ' + IntToStr(n) + ES_GROUP;
    Inc(n);
  end;
  ForceDirectories(dirName);
end;

procedure TLinkbarWcl.imOpenWorkdirClick(Sender: TObject);
begin
  OpenDirectoryByName(WorkDir);
end;

procedure TLinkbarWcl.imRemoveBarClick(Sender: TObject);
var td: TTaskDialog;
begin
  td := TTaskDialog.Create(Self);
  FLockAutoHide := True;
  try
    td.Caption := ' ' + APP_NAME_LINKBAR;
    td.MainIcon := tdiNone;
    td.Title := Format( L10NFind('Delete.Title', 'You remove the linkbar "%s"'), [PanelName] );
    td.Text := Format( L10NFind('Delete.Text', 'Working directory: %s'), [FLinksBaseDir] );
    td.VerificationText := L10NFind('Delete.Verification', 'Delete working directory') + Format('%*s', [24, ' ']);
    td.CommonButtons := [tcbOk, tcbCancel];
    td.DefaultButton := tcbCancel;

    if (td.Execute)
       and (td.ModalResult = mrOk)
    then begin
      FRemoved := True;
      DeleteFile(FSettingsFileName);
      if (tfVerificationFlagChecked in td.Flags)
      then begin
        StopDirWatch;
        SHDeleteOp(Handle, FLinksBaseDir, True);
      end;
      PostQuitMessage(0);
    end;
  finally
    FLockAutoHide := False;
    td.Free;
  end;
end;

procedure TLinkbarWcl.imSortAlphabetClick(Sender: TObject);
begin
  SortAlphabetically := not SortAlphabetically;
end;

////////////////////////////////////////////////////////////////////////////////
// Autohide
////////////////////////////////////////////////////////////////////////////////

function TLinkbarWcl.ScaleDimension(const X: Integer): Integer;
begin
  Result := MulDiv(X, Self.PixelsPerInch, 96);
end;

procedure TLinkbarWcl.DoAutoHide;
var r: TRect;
begin
  if (not AutoHide)
     or FLockAutoHide
     or ( WindowFromPoint(MakePoint(GetMessagePos)) = Handle )
  then Exit;

  if FCanAutoHide and not FAutoHiden
  then begin
    FAutoHiden := True;
    HotIndex := ITEM_NONE;
    r := FBeforeAutoHideBound;
    case Align of
      EPanelAlignTop: r.Bottom := r.Top + ScaleDimension(AUTOHIDE_SIZE);
      EPanelAlignLeft: r.Right := r.Left + ScaleDimension(AUTOHIDE_SIZE);
      EPanelAlignRight: r.Left := r.Right - ScaleDimension(AUTOHIDE_SIZE);
      EPanelAlignBottom: r.Top := r.Bottom - ScaleDimension(AUTOHIDE_SIZE);
    end;
    FAfterAutoHideBound := r;
    MoveWindow(Handle, r.Left, r.Top, r.Width, r.Height, False);
    UpdateWindow(FAfterAutoHideBound);
    Self.OnContextPopup := nil;
  end;
end;

procedure TLinkbarWcl.DoAutoShow;
var pt: TPoint;
begin
  pt := MakePoint(GetMessagePos);
  if (AutoHide)
     and (FAutoHiden)
     and ((not FCanAutoHide) or (WindowFromPoint(pt) = Handle))
     //(FAutoShowMode <> smHotKey)
  then begin
    FAutoHiden := False;
    MoveWindow(Handle, FBeforeAutoHideBound.Left, FBeforeAutoHideBound.Top,
      FBeforeAutoHideBound.Width, FBeforeAutoHideBound.Height, False);
    UpdateWindow(FBeforeAutoHideBound);
    Self.OnContextPopup := FormContextPopup;
  end;
end;

procedure TLinkbarWcl.DoDelayedAutoHide(const ADelay: Cardinal);
begin
  if (not AutoHide)
  then Exit;

  if (ADelay = 0)
  then DoAutoHide
  else SetTimer(Handle, TIMER_AUTO_HIDE, ADelay, nil);
end;

procedure TLinkbarWcl.DoDelayedAutoShow;
begin
  if (not AutoHide)
  then Exit;

  if (FAutoShowDelay = 0)
  then DoAutoShow
  else SetTimer(Handle, TIMER_AUTO_SHOW, FAutoShowDelay, nil);
end;

procedure TLinkbarWcl.FormMouseEnter(Sender: TObject);
begin
  if AutoHide
     and FAutoHiden
     and (FAutoShowMode = EAutoShowModeMouseHover)
  then DoDelayedAutoShow;
end;

procedure TLinkbarWcl.FormMouseLeave(Sender: TObject);
begin
  HotIndex := -1;
  if ZoomEnabled and (FZoomCursor >= 0)
  then begin
    FZoomCursor := -1;
    RedrawZoom;
  end;
  if (FAutoShowMode = EAutoShowModeMouseHover) or FCanAutoHide
  then DoDelayedAutoHide(TIMER_AUTO_HIDE_DELAY);
end;

////////////////////////////////////////////////////////////////////////////////
// Drag&Drop
////////////////////////////////////////////////////////////////////////////////

var _FLastDropRect: TRect;
    _FPart: Integer;

procedure TLinkbarWcl.SetDropPosition(AValue: TPoint);

  function GetItemDropRect(const AIndex, APart: Integer): TRect;
  var r: TRect;
  begin
    r := Items[AIndex].Rect;

    case APart of
      -1: begin
        if IsVertical(Align)
        then begin
          r.Top := r.Top - DROP_INDICATOR_SIZE div 2;
          r.Left := r.Left + r.Width div DROP_INDICATOR_PADDING_DIV;
          r.Right := r.Right - r.Width div DROP_INDICATOR_PADDING_DIV;
          r.Height := DROP_INDICATOR_SIZE;
        end
        else begin
          r.Left := r.Left - DROP_INDICATOR_SIZE div 2;
          r.Top := r.Top + r.Height div DROP_INDICATOR_PADDING_DIV;
          r.Bottom := r.Bottom - r.Height div DROP_INDICATOR_PADDING_DIV;
          r.Width := DROP_INDICATOR_SIZE;
        end;
      end;
      1: begin
        if IsVertical(Align)
        then begin
          r.Top := r.Bottom - DROP_INDICATOR_SIZE div 2;
          r.Left := r.Left + r.Width div DROP_INDICATOR_PADDING_DIV;
          r.Right := r.Right - r.Width div DROP_INDICATOR_PADDING_DIV;
          r.Height := DROP_INDICATOR_SIZE;
        end
        else begin
          r.Left := r.Right - DROP_INDICATOR_SIZE div 2;
          r.Top := r.Top + r.Height div DROP_INDICATOR_PADDING_DIV;
          r.Bottom := r.Bottom - r.Height div DROP_INDICATOR_PADDING_DIV;
          r.Width := DROP_INDICATOR_SIZE;
        end;
      end;
    end;

    Result := r;
  end;

var
  r: TRect;
  index: Integer;
  part: Integer;
begin
  index := ItemIndexByPoint(AValue);

  if (index = ITEM_NONE)
  then part := -1
  else begin
    part := Items[index].GetDropPart(AValue, IsVertical(Align), FDragingItem);

    if (part = 1) and (index <> FDragIndex)
    then begin
      index := index + 1;
      part := -1;
    end;

    if index > (Items.Count-1)
    then index := ITEM_NONE;
  end;

  if FDragingItem or (index = ITEM_NONE) or (part <> 0)
  then FPidl := WorkDirPidl
  else FPidl := Items[index].Pidl;

  if (index = FItemDropPosition) and (part = _FPart) then Exit;
  _FPart := part;

  if (FItemDropPosition <> ITEM_NONE) then
  begin
    r := _FLastDropRect;
    BitBlt(BitmapPanel.Dc, r.Left, r.Top, r.Width, r.Height, BitmapDropPosition.Dc, 0, 0, SRCCOPY);
  end;

  FItemDropPosition := index;

  if (FItemDropPosition <> ITEM_NONE) then
  begin
    r := GetItemDropRect(FItemDropPosition, part);
    _FLastDropRect := r;

    BitBlt(BitmapDropPosition.Dc, 0, 0, r.Width, r.Height, BitmapPanel.Dc, r.Left, r.Top, SRCCOPY);

    if (part = 0)
    then begin
      DrawBackground(BitmapPanel, r);
      ThemeDrawHover(BitmapPanel, Align, r);
      DrawItem(BitmapPanel, FItemDropPosition, False, False, False);
    end
    else begin
      var gpDrawer: IGPGraphics := TGpGraphics.Create(BitmapPanel.Dc);
      var gpBrush: IGPSolidBrush := TGPSolidBrush.Create(TGPColor.Create($ff000000));
      gpDrawer.FillRectangle(gpBrush, TGPRect.Create(r));
      gpBrush.Color := TGPColor.Create($ffffffff);
      r.Inflate(-1,-1,-1,-1);
      gpDrawer.FillRectangle(gpBrush, TGPRect.Create(r));
    end;
  end;

  UpdateWindow;
end;

procedure TLinkbarWcl.DoDragEnter(const pt: TPoint);
begin
  if AutoHide
     and FAutoHiden
  then begin
    FCanAutoHide := False;
    DoAutoShow;
  end;
end;

procedure TLinkbarWcl.DoDragOver(const pt: TPoint; var ppidl: PItemIDList);
begin
  if AutoHide
     and FAutoHiden
  then Exit;
  SetDropPosition(pt);
  ppidl := FPidl;
end;

procedure TLinkbarWcl.DoDragLeave;
begin
  SetDropPosition( Point(-1, -1) );
  if AutoHide and not Active
  then begin
    FCanAutoHide := True;
    SetTimer(Handle, TIMER_AUTO_HIDE, TIMER_AUTO_HIDE_DELAY, nil); // DoAutoHide;
  end;
end;

procedure TLinkbarWcl.DoDrop(const pt: TPoint);
begin
  if AutoHide and not Active
  then begin
    FCanAutoHide := True;
  end;

  if FDragingItem
  then begin
    SortAlphabetically := False;
    if (FItemDropPosition = ITEM_NONE)
    then begin
      if (Items.Count > 0)
         and ((Items.First.Rect.TopLeft.X < pt.X) or (Items.First.Rect.TopLeft.Y < pt.Y))
      then Items.Move(FDragIndex, 0)
      else Items.Move(FDragIndex, Items.Count-1);
    end
    else begin
      if (FItemDropPosition <= FDragIndex)
      then Items.Move(FDragIndex, FItemDropPosition)
      else Items.Move(FDragIndex, FItemDropPosition-1);
    end;
    SetDropPosition( Point(-1, -1) );
    UpdateWindowSize;
  end
  else tmrUpdate.Enabled := True;
end;

procedure TLinkbarWcl.QueryDragImage(out ABitmap: THBitmap; out AOffset: TPoint);
var ItemRect: TRect;
    srcDc: HDC;
    old: HGDIOBJ;
    bm: Winapi.Windows.TBitmap;
    blend: TBlendFunction;
begin
  if (not StyleServices.Enabled)
  then begin
    ABitmap := nil;
    Exit;
  end;

  // Dragging a file that is not a bar item (icon dragged out of a group)
  if not IsItemIndex(FDragIndex)
  then begin
    ABitmap := nil;
    AOffset := Point(0, 0);
    if (FExtDragIcon = 0) or (FExtDragIconSize <= 0)
       or (GetObject(FExtDragIcon, SizeOf(bm), @bm) = 0)
    then Exit;

    ABitmap := THBitmap.Create(32);
    ABitmap.SetSize(FExtDragIconSize, FExtDragIconSize);
    blend.BlendOp := AC_SRC_OVER;
    blend.BlendFlags := 0;
    blend.SourceConstantAlpha := 255;
    blend.AlphaFormat := AC_SRC_ALPHA;
    srcDc := CreateCompatibleDC(0);
    old := SelectObject(srcDc, FExtDragIcon);
    Winapi.Windows.AlphaBlend(ABitmap.Dc, 0, 0, FExtDragIconSize, FExtDragIconSize,
      srcDc, 0, 0, bm.bmWidth, Abs(bm.bmHeight), blend);
    SelectObject(srcDc, old);
    DeleteDC(srcDc);
    AOffset := Point(FExtDragIconSize div 2, FExtDragIconSize div 2);
    Exit;
  end;

  ItemRect := Items[FDragIndex].Rect;

  ABitmap := THBitmap.Create(32);
  ABitmap.SetSize(ItemRect.Width, ItemRect.Height);
  // Drag Image will faded when size > 300 px (DPI independent)
  DrawItem(ABitmap, FDragIndex, False, True, False, True);

  AOffset := Point(FMousePosDown.X - ItemRect.Left, FMousePosDown.Y - ItemRect.Top);
end;

var
  _LastModifiedItemHash: Cardinal = 0;
  _RenamedOldItemHash: Cardinal = 0;

procedure TLinkbarWcl.DirWatchChange(const Sender: TObject; const AAction: TWatchAction; const AFileName: string);

  function FindItemByHash(AHash: Cardinal): Integer;
  begin
    for var i := 0 to Items.Count-1
    do if Items[i].Hash = AHash
       then Exit(i);
    Result := ITEM_NONE;
  end;

var ext: string;
    hash: Cardinal;
    index: integer;
begin
  inherited;
  // Skip unsupported files
  ext := ExtractFileExt(AFileName);
  if not MatchText(ext, ES_ITEMS_ARRAY) then Exit;

  tmrUpdate.Enabled := False;

  case AAction of
  waAdded:
  begin
    var item := CreateItemForFile(AFileName);
    item.Hash := StrToHash(AFileName);
    item.FileName := WorkDir + AFileName;
    item.NeedLoad := True;
    if (FItemDropPosition = ITEM_NONE)
    then Items.Add(item)
    else Items.Insert(FItemDropPosition, item);
  end;
  waRemoved:
  begin
    index := FindItemByHash(StrToHash(AFileName));
    if (index <> ITEM_NONE)
    then DeleteItem(index);
  end;
  waModified:
  begin
    hash := StrToHash(AFileName);
    if (_LastModifiedItemHash <> hash)
    then begin
      _LastModifiedItemHash := hash;
      index := FindItemByHash(hash);
      if (index <> ITEM_NONE)
      then Items[index].NeedLoad := True;
    end;
  end;
  waRenamedOld:
  begin
    _RenamedOldItemHash := StrToHash(AFileName);
  end;
  waRenamedNew:
  begin
    index := FindItemByHash(_RenamedOldItemHash);
    if (index <> ITEM_NONE)
    then begin
      var item := Items[index];
      item.FileName := WorkDir + AFileName;
      item.NeedLoad := True;
      _RenamedOldItemHash := 0;
    end;
  end;
  end;

  tmrUpdate.Enabled := True;
end;

procedure TLinkbarWcl.tmrUpdateTimer(Sender: TObject);
begin
  tmrUpdate.Enabled := False;

  for var i := Items.Count-1 downto 0 do
  begin
    const item = Items[i];
    if item.NeedLoad
    then begin
      if item.LoadFromFile(item.FileName)
      then Items.LoadIcon(item)
      else DeleteItem(i);
    end
  end;

  if FSortAlphabetically
  then Items.Sort;

  _LastModifiedItemHash := 0;
  _RenamedOldItemHash := 0;

  SetDropPosition( Point(-1, -1) );
  oAppBar.AppBarPosChanged;
end;

procedure TLinkbarWcl.DirWatchError(const Sender: TObject;
  const ErrorCode: Integer; const ErrorMessage: string);
begin
  if (ErrorCode > 0)
  then begin
    StopDirWatch;
    Sleep(100);
    if not DirectoryExists(WorkDir)
    then begin
      FRemoved := True;
      DeleteFile(FSettingsFileName);
      Close;
    end;
  end;
end;

procedure TLinkbarWcl.SetEnableAeroGlass(AValue: Boolean);
begin
  if (not IsWindows8And8Dot1)
     or (AValue = FEnableAeroGlass)
  then Exit;

  FEnableAeroGlass := AValue;
  GlobalAeroGlassEnabled := FEnableAeroGlass;
  ThemeSetWindowAttribute78(Handle);
  UpdateBlur;
end;

procedure TLinkbarWcl.SetTransparencyMode(AValue: TTransparencyMode);
begin
  if (not IsWindows10)
     //or (AValue = FTransparencyMode)
  then Exit;
  FTransparencyMode := AValue;
  UpdateBackgroundColor;
  ApplyWindowAccent;
end;

procedure TLinkbarWcl.SetLook(AValue: TLook);
begin
  if (not IsWindows10)
     //or (AValue = FTransparencyMode)
  then Exit;

  GlobalLook := AValue;

  BitmapButton.Clear;
  ThemeDrawButton(BitmapButton, BitmapButton.Bound, False);

  FLook := AValue;
  UpdateBackgroundColor;
  ApplyWindowAccent;
end;

procedure TLinkbarWcl.SetModernStyle(AValue: Boolean);
begin
  if (AValue = FModernStyle)
  then Exit;

  FModernStyle := AValue;
  GlobalModernStyle := AValue;

  // Redraw cached button (hover/pressed) bitmap
  BitmapButton.Clear;
  ThemeDrawButton(BitmapButton, BitmapButton.Bound, False);

  // Redraw panel (separators)
  if (BitmapPanel.Width > 0) and (BitmapPanel.Height > 0)
  then begin
    RecreateMainBitmap(BitmapPanel.Width, BitmapPanel.Height);
    UpdateWindow;
  end;
end;

{ ---------- "Program is open" indicator ---------- }

procedure TLinkbarWcl.UpdateRunningState;
var
  paths: TStringList;
  changed, running: Boolean;
  idx: Integer;
begin
  if FAutoHiden or IsDragDrop or FMouseDragLinkbar or FMouseLeftDown
  then Exit;

  paths := TStringList.Create;
  try
    CollectRunningExePaths(paths);

    changed := False;
    for var item in Items do
    begin
      running := (item.TargetPath <> '') and paths.Find(item.TargetPath, idx);
      // Group: open if any of its programs is open
      if (not running) and (item is TItemGroup)
      then begin
        for var t in TItemGroup(item).MemberTargets do
          if (t <> '') and paths.Find(t, idx)
          then begin
            running := True;
            Break;
          end;
      end;
      if (running <> item.Running)
      then begin
        item.Running := running;
        changed := True;
      end;
    end;
  finally
    paths.Free;
  end;

  if changed
     and (BitmapPanel.Width > 0) and (BitmapPanel.Height > 0)
  then begin
    var hot := FHotIndex;
    RecreateMainBitmap(BitmapPanel.Width, BitmapPanel.Height);
    if IsItemIndex(hot) and not ZoomEnabled
    then begin
      // refresh hover snapshot and highlight
      const r = Items[hot].Rect;
      BitBlt(BitmapSelected.Dc, 0, 0, r.Width, r.Height, BitmapPanel.Dc, r.Left, r.Top, SRCCOPY);
      DrawItem(BitmapPanel, hot, True, False);
    end;
    UpdateWindow;
  end;
end;

{ Small pill under the icon, like the taskbar }
procedure TLinkbarWcl.DrawRunningMark(const ABitmap: THBitmap; const AItem: TItemBase; const ARect: TRect);
var
  gp: IGPGraphics;
  brush: IGPBrush;
  r: TRect;
  w, h: Integer;
  color: Cardinal;
begin
  if not AItem.Running
  then Exit;

  w := Max(ScaleDimension(16), (IconSize * 2) div 3); // about 2/3 of the icon width
  h := Max(3, ScaleDimension(3));
  case Align of
    EPanelAlignLeft:   r := Bounds(ARect.Left + 1, ARect.Top + (ARect.Height - w) div 2, h, w);
    EPanelAlignRight:  r := Bounds(ARect.Right - h - 1, ARect.Top + (ARect.Height - w) div 2, h, w);
    else // top/bottom bar: under the icon
      r := Bounds(ARect.Left + (ARect.Width - w) div 2, ARect.Bottom - h - 1, w, h);
  end;

  color := SwapRedBlue(GetImmersiveColorFromName('ImmersiveSystemAccentLight2'));
  if ((color shr 24) = 0)
  then color := color or $FF000000;

  gp := TGPGraphics.Create(ABitmap.Dc);
  brush := TGPSolidBrush.Create(color);
  GPFillRoundRect(gp, brush, r, h div 2);
end;

{ ---------- Live thumbnails ---------- }

{ Hot item changed: schedule the thumbnails for an open program }
procedure TLinkbarWcl.ThumbsHotChanged;
var delay: Integer;
begin
  KillTimer(Handle, TIMER_THUMBS);

  // moved to another item: close the current preview
  if Assigned(FThumbForm) and IsItemIndex(FHotIndex) and (FHotIndex <> FThumbIndex)
  then CloseThumbs;

  if IsItemIndex(FHotIndex)
     and (not Assigned(FThumbForm))
     and Items[FHotIndex].Running
     and (Items[FHotIndex].TargetPath <> '')
  then begin
    delay := 500;
    SetTimer(Handle, TIMER_THUMBS, delay, nil);
  end;
end;

procedure TLinkbarWcl.ShowThumbs(const AIndex: Integer);
var
  wnds: TArray<HWND>;
  r: TRect;
  form: TFormThumbs;
begin
  if not IsItemIndex(AIndex)
     or (not Items[AIndex].Running)
     or FMouseLeftDown or IsDragDrop or FLockHotIndex or FAutoHiden
     or Assigned(FThumbForm)
  then Exit;

  wnds := GetProgramWindows(Items[AIndex].TargetPath);
  if (Length(wnds) = 0)
  then Exit;

  ToolTip.Cancel;
  r := Items[AIndex].Rect;
  MapWindowPoints(Handle, HWND_DESKTOP, r, 2);

  form := TFormThumbs.CreateThumbs(Self, Handle, wnds, IsVertical(Align));
  form.OnDestroy := OnThumbsDestroy;
  FThumbForm := form;
  FThumbIndex := AIndex;
  form.PopupAt(r, Align);
end;

procedure TLinkbarWcl.CloseThumbs;
begin
  KillTimer(Handle, TIMER_THUMBS);
  if Assigned(FThumbForm)
  then begin
    FThumbForm.OnDestroy := nil;
    FThumbForm.Close;
    FThumbForm := nil;
  end;
end;

procedure TLinkbarWcl.OnThumbsDestroy(Sender: TObject);
begin
  if (FThumbForm = Sender)
  then FThumbForm := nil;
end;

{ ---------- Dock mode and magnification ---------- }

function TLinkbarWcl.IsDock: Boolean;
begin
  Result := (FBarStyle = BAR_STYLE_DOCK);
end;

function TLinkbarWcl.ZoomEnabled: Boolean;
begin
  Result := (FZoomPercent > 100);
end;

{ Extra thickness so magnified icons fit in the bar }
function TLinkbarWcl.ZoomRoom: Integer;
begin
  if ZoomEnabled
  then Result := MulDiv(IconSize, FZoomPercent - 100, 100)
  else Result := 0;
end;

{ Icons stay on the screen edge and grow towards the screen center }
function TLinkbarWcl.ZoomBefore: Boolean;
begin
  Result := (Align = EPanelAlignBottom) or (Align = EPanelAlignRight);
end;

function TLinkbarWcl.ZoomIconSizeValue: Integer;
begin
  if ZoomEnabled
  then Result := MulDiv(IconSize, FZoomPercent, 100)
  else Result := 0;
end;

{ Dock: free space at both ends so magnified end icons are not cut }
function TLinkbarWcl.DockPad: Integer;
begin
  if not IsDock
  then Exit(0);
  if ZoomEnabled
  then Result := MulDiv(Max(ButtonSize.cx, ButtonSize.cy), FZoomPercent - 100, 100)
  else Result := ScaleDimension(4);
end;

function TLinkbarWcl.ItemsMargin: Integer;
begin
  Result := FGripSize + DockPad;
end;

{ Dock bounds: only as long as its content, centered, slightly away from the edge }
procedure TLinkbarWcl.DockBounds(var AX, AY, AWidth, AHeight: Integer);
var
  wa: TRect;
  len, gap, mon: Integer;
  vertical: Boolean;
begin
  mon := EnsureRange(FMonitorNum, 0, Screen.MonitorCount - 1);
  wa := Screen.Monitors[mon].WorkareaRect;
  gap := ScaleDimension(6);
  vertical := IsVertical(Align);

  len := Items.LineWidth + 2 * ItemsMargin + SysWidgetLength(vertical);
  if vertical
  then begin
    len := Min(len, wa.Height);
    AHeight := len;
    AY := wa.Top + MulDiv(wa.Height - len, FDockPos, 1000);
    if (Align = EPanelAlignLeft)
    then AX := wa.Left + gap
    else AX := wa.Right - AWidth - gap;
  end
  else begin
    len := Min(len, wa.Width);
    AWidth := len;
    AX := wa.Left + MulDiv(wa.Width - len, FDockPos, 1000);
    if (Align = EPanelAlignTop)
    then AY := wa.Top + gap
    else AY := wa.Bottom - AHeight - gap;
  end;
end;

{ Rounded corners for the dock, plain rectangle otherwise }
procedure TLinkbarWcl.ApplyDockRegion(const AWidth, AHeight: Integer);
begin
  // The dock shape comes from the per-pixel alpha of its own background
  // (smooth corners); a window region would give jagged corners
  SetWindowRgn(Handle, 0, True);
end;

{ Window background effect (Windows 10+). The dock paints its own background }
procedure TLinkbarWcl.ApplyWindowAccent;
begin
  if not IsWindows10
  then Exit;
  if IsDock or (FAutoHiden and FAutoHideTransparency)
  then ThemeSetWindowAccentPolicy10(Handle, tmDisabled, 0)
  else ThemeSetWindowAccentPolicy10(Handle, FTransparencyMode, BackgroundColor);

  // dock background uses the background color: repaint
  if IsDock and Assigned(BitmapPanel)
     and (BitmapPanel.Width > 0) and (BitmapPanel.Height > 0)
  then begin
    RecreateMainBitmap(BitmapPanel.Width, BitmapPanel.Height);
    UpdateWindow;
  end;
end;

{ Dock background: rounded rectangle with anti-aliased edges and a thin
  border, written directly as premultiplied pixels (correct alpha) }
procedure TLinkbarWcl.DrawDockBackground(const ABitmap: THBitmap; const AClipRect: TRect);

  // 0..1 coverage of pixel center (fx, fy) by a rounded rect
  function Coverage(fx, fy: Double; const R: TRect; Radius: Double): Double;
  var dx, dy: Double;
  begin
    if (fx < R.Left) or (fx > R.Right) or (fy < R.Top) or (fy > R.Bottom)
    then begin
      // outside the box: soft edge of half a pixel
      dx := Max(Max(R.Left - fx, fx - R.Right), 0);
      dy := Max(Max(R.Top - fy, fy - R.Bottom), 0);
      Exit(EnsureRange(0.5 - Sqrt(dx*dx + dy*dy), 0, 1));
    end;
    dx := 0;
    if (fx < R.Left + Radius) then dx := R.Left + Radius - fx
    else if (fx > R.Right - Radius) then dx := fx - (R.Right - Radius);
    dy := 0;
    if (fy < R.Top + Radius) then dy := R.Top + Radius - fy
    else if (fy > R.Bottom - Radius) then dy := fy - (R.Bottom - Radius);
    if (dx = 0) or (dy = 0)
    then begin
      // straight edges: distance to the nearest side
      Result := EnsureRange(Min(Min(fx - R.Left, R.Right - fx), Min(fy - R.Top, R.Bottom - fy)) + 0.5, 0, 1);
    end
    else Result := EnsureRange(Radius - Sqrt(dx*dx + dy*dy) + 0.5, 0, 1);
  end;

var
  color, a, ba, br, bg, bb, cr, cg, cb: Cardinal;
  outer, inner, clip: TRect;
  radius, covO, covI, fa, fb: Double;
  x, y: Integer;
  row: PByte;
  px: PCardinal;
  oa, orr, og, ob: Double;
begin
  if (ABitmap.Bits = nil)
  then Exit;

  // fill color (ARGB); opaque mode = fully opaque
  color := BackgroundColor;
  a := color shr 24;
  if (FTransparencyMode = tmOpaque) then a := 255;
  if (a < 8) then a := 8; // keep it clickable
  cr := (color shr 16) and $FF;
  cg := (color shr 8) and $FF;
  cb := color and $FF;

  // thin border: light on dark, dark on light
  if (GlobalLook = ELookLight)
  then begin ba := 50; br := 0; bg := 0; bb := 0; end
  else begin ba := 60; br := 255; bg := 255; bb := 255; end;

  outer := Rect(0, 0, ABitmap.Width, ABitmap.Height);
  inner := Rect(1, 1, ABitmap.Width - 1, ABitmap.Height - 1);
  radius := Min(ScaleDimension(14), Min(ABitmap.Width, ABitmap.Height) div 2);

  clip := AClipRect;
  if not clip.IntersectsWith(outer) then Exit;
  clip.Intersect(outer);

  for y := clip.Top to clip.Bottom - 1 do
  begin
    row := PByte(ABitmap.Bits) + y * ABitmap.Pitch;
    for x := clip.Left to clip.Right - 1 do
    begin
      px := PCardinal(row + x * 4);
      covO := Coverage(x + 0.5, y + 0.5, outer, radius);
      covI := Coverage(x + 0.5, y + 0.5, inner, Max(radius - 1, 0));
      fa := (a / 255) * covI;          // fill alpha
      fb := (ba / 255) * Max(covO - covI, 0); // border alpha
      // composite border over fill (premultiplied)
      oa := fb + fa * (1 - fb);
      orr := br * fb + cr * fa * (1 - fb);
      og := bg * fb + cg * fa * (1 - fb);
      ob := bb * fb + cb * fa * (1 - fb);
      px^ := (Cardinal(Round(oa * 255)) shl 24)
          or (Cardinal(Round(orr)) shl 16)
          or (Cardinal(Round(og)) shl 8)
          or  Cardinal(Round(ob));
    end;
  end;
end;

{ Move the dock along its edge following the mouse (Ctrl+drag) }
procedure TLinkbarWcl.SlideDock(const ACursor: TPoint);
var
  wa: TRect;
  l, t: Integer;
begin
  wa := Screen.Monitors[EnsureRange(FMonitorNum, 0, Screen.MonitorCount - 1)].WorkareaRect;
  l := FSlideStartPos.X;
  t := FSlideStartPos.Y;
  if IsVertical(Align)
  then t := EnsureRange(t + ACursor.Y - FSlideStartCursor.Y, wa.Top, Max(wa.Top, wa.Bottom - Height))
  else l := EnsureRange(l + ACursor.X - FSlideStartCursor.X, wa.Left, Max(wa.Left, wa.Right - Width));
  SetWindowPos(Handle, 0, l, t, 0, 0, SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE);
  FBeforeAutoHideBound := Bounds(l, t, Width, Height);
end;

{ Remember the dock position as a fraction of the free space (survives resolution changes) }
procedure TLinkbarWcl.SaveDockPos;
var
  wa: TRect;
  range, pos: Integer;
begin
  wa := Screen.Monitors[EnsureRange(FMonitorNum, 0, Screen.MonitorCount - 1)].WorkareaRect;
  if IsVertical(Align)
  then begin
    range := wa.Height - Height;
    pos := Top - wa.Top;
  end
  else begin
    range := wa.Width - Width;
    pos := Left - wa.Left;
  end;
  if (range > 0)
  then FDockPos := EnsureRange(MulDiv(pos, 1000, range), 0, 1000)
  else FDockPos := DEF_DOCK_POS;
  TSettingsFile.Write(FSettingsFileName, INI_DOCK_POS, FDockPos);
end;

procedure TLinkbarWcl.SetBarStyle(AValue: Integer);
begin
  AValue := EnsureRange(AValue, BAR_STYLE_NORMAL, BAR_STYLE_DOCK);
  if (AValue = FBarStyle)
  then Exit;
  FBarStyle := AValue;

  if IsDock and AutoHide
  then AutoHide := False;

  ApplyWindowAccent;
  if Assigned(oAppBar)
  then begin
    oAppBar.Floating := IsDock;
    oAppBar.AppBarPosChanged;
  end;
  SetWindowRgn(Handle, 0, True);
end;

procedure TLinkbarWcl.SetZoomPercent(AValue: Integer);
begin
  AValue := EnsureRange(AValue, ZOOM_MIN, ZOOM_MAX);
  if (AValue = FZoomPercent)
  then Exit;
  FZoomPercent := AValue;
  FZoomCursor := -1;
  Items.ZoomIconSize := ZoomIconSizeValue;
  // the bar thickness changes
  if Assigned(oAppBar)
  then oAppBar.AppBarPosChanged
  else UpdateWindowSize;
end;

procedure TLinkbarWcl.RedrawZoom;
begin
  if FAutoHiden or IsDragDrop
     or (BitmapPanel.Width = 0) or (BitmapPanel.Height = 0)
  then Exit;
  RecreateMainBitmap(BitmapPanel.Width, BitmapPanel.Height);
  UpdateWindow;
end;

{ Icons near the mouse grow (cosine falloff over ~2.5 slots), the row spreads
  out around the mouse so the icon under it stays under it }
procedure TLinkbarWcl.DrawItemsZoomed;
const
  RANGE = 2.5; // slots affected on each side
var
  vertical: Boolean;
  z, d, f, shift, t, vis, cursor: Double;
  n, i, k, slot, size, x, y: Integer;
  scales, lens, starts: array of Double;
  base, vr: TRect;
  item: TItemBase;
  baseStart, baseLen: Double;
begin
  vertical := IsVertical(Align);
  z := FZoomPercent / 100;
  n := Items.Count;
  if (n = 0) then Exit;
  if vertical then slot := ButtonSize.cy else slot := ButtonSize.cx;
  if (slot <= 0) then Exit;
  cursor := FZoomCursor;

  SetLength(scales, n);
  SetLength(lens, n);
  SetLength(starts, n);

  // scale and enlarged length of every item
  for i := 0 to n-1 do
  begin
    base := Items[i].Rect;
    if vertical
    then begin baseStart := base.Top;  baseLen := base.Height; end
    else begin baseStart := base.Left; baseLen := base.Width;  end;

    if Items.IsSeparator(Items[i])
    then scales[i] := 1
    else begin
      d := Abs(cursor - (baseStart + baseLen / 2)) / slot;
      if (d < RANGE)
      then f := (1 + Cos(Pi * d / RANGE)) / 2
      else f := 0;
      scales[i] := 1 + (z - 1) * f;
    end;
    lens[i] := baseLen * scales[i];
  end;

  // positions: keep the point under the mouse fixed
  if vertical then vis := Items[0].Rect.Top else vis := Items[0].Rect.Left;
  for i := 0 to n-1 do
  begin
    starts[i] := vis;
    vis := vis + lens[i];
  end;

  k := -1;
  for i := 0 to n-1 do
  begin
    base := Items[i].Rect;
    if vertical
    then begin baseStart := base.Top;  baseLen := base.Height; end
    else begin baseStart := base.Left; baseLen := base.Width;  end;
    if (cursor >= baseStart) and (cursor < baseStart + baseLen)
    then begin
      k := i;
      Break;
    end;
  end;

  if (k >= 0)
  then begin
    base := Items[k].Rect;
    if vertical
    then begin baseStart := base.Top;  baseLen := base.Height; end
    else begin baseStart := base.Left; baseLen := base.Width;  end;
    t := (cursor - baseStart) / baseLen;
    shift := cursor - (starts[k] + t * lens[k]);
  end
  else begin
    // mouse before the first item: grow to the right; after the last: to the left
    if vertical
    then begin
      if (cursor < Items[0].Rect.Top) then shift := 0
      else shift := Items[n-1].Rect.Bottom - (starts[n-1] + lens[n-1]);
    end
    else begin
      if (cursor < Items[0].Rect.Left) then shift := 0
      else shift := Items[n-1].Rect.Right - (starts[n-1] + lens[n-1]);
    end;
  end;

  // draw
  for i := 0 to n-1 do
  begin
    item := Items[i];
    base := item.Rect;
    if vertical
    then vr := Rect(base.Left, Round(starts[i] + shift), base.Right, Round(starts[i] + shift + lens[i]))
    else vr := Rect(Round(starts[i] + shift), base.Top, Round(starts[i] + shift + lens[i]), base.Bottom);

    if Items.IsSeparator(item)
    then begin
      if (FSeparatorStyle <> ESeparatorStyleSpace)
      then ThemeDrawSeparator(BitmapPanel, Align, vr);
      Continue;
    end;

    size := Round(IconSize * scales[i]);
    if vertical
    then begin
      y := vr.Top + (vr.Height - size) div 2;
      if ZoomBefore
      then x := base.Left + FIconOffset.X + IconSize - size   // right bar: grow to the left
      else x := base.Left + FIconOffset.X;                    // left bar: grow to the right
    end
    else begin
      x := vr.Left + (vr.Width - size) div 2;
      if ZoomBefore
      then y := base.Top + FIconOffset.Y + IconSize - size    // bottom bar: grow upwards
      else y := base.Top + FIconOffset.Y;                     // top bar: grow downwards
    end;

    Items.DrawScaled(BitmapPanel.Dc, item, x, y, size);
    DrawRunningMark(BitmapPanel, item, vr);
  end;
end;

{ ---------- CPU / RAM widgets ---------- }

const
  SYSWIDGET_COUNT = 2; // CPU, RAM

function LB_GetSystemTimes(out AIdleTime, AKernelTime, AUserTime: TFileTime): BOOL; stdcall;
  external kernel32 name 'GetSystemTimes';

function FileTimeToUInt64(const AFt: TFileTime): UInt64; inline;
begin
  Result := (UInt64(AFt.dwHighDateTime) shl 32) or AFt.dwLowDateTime;
end;

procedure TLinkbarWcl.SetShowSysWidgets(AValue: Boolean);
begin
  if (AValue = FShowSysWidgets)
  then Exit;
  FShowSysWidgets := AValue;

  if FShowSysWidgets
  then begin
    SampleSysStats;
    SetTimer(Handle, TIMER_SYS_WIDGETS, 1000, nil);
  end
  else KillTimer(Handle, TIMER_SYS_WIDGETS);

  // Re-layout: the end of the bar is reserved for the widgets
  if Assigned(oAppBar)
  then oAppBar.AppBarPosChanged
  else UpdateWindowSize;
end;

{ Space kept at the end of the bar }
function TLinkbarWcl.SysWidgetLength(const AVertical: Boolean): Integer;
begin
  if not FShowSysWidgets
  then Exit(0);
  if AVertical
  then Result := SYSWIDGET_COUNT * Max(ButtonSize.cy, ScaleDimension(40)) + ScaleDimension(8)
  else Result := SYSWIDGET_COUNT * Max(ButtonSize.cx, ScaleDimension(56)) + ScaleDimension(8);
end;

function TLinkbarWcl.SysWidgetRect(const AWidth, AHeight: Integer): TRect;
var len: Integer;
begin
  len := SysWidgetLength(IsVertical(Align));
  if (len = 0)
  then Exit(TRect.Empty);
  if IsVertical(Align)
  then Result := Rect(0, AHeight - len, AWidth, AHeight)
  else Result := Rect(AWidth - len, 0, AWidth, AHeight);
end;

procedure TLinkbarWcl.SampleSysStats;
var
  idleFt, kernelFt, userFt: TFileTime;
  idle, kernel, user, dIdle, dTotal: UInt64;
  mem: TMemoryStatusEx;
begin
  // CPU: (busy time) / (total time) since last sample
  if LB_GetSystemTimes(idleFt, kernelFt, userFt)
  then begin
    idle := FileTimeToUInt64(idleFt);
    kernel := FileTimeToUInt64(kernelFt); // includes idle
    user := FileTimeToUInt64(userFt);
    if (FPrevKernel <> 0)
    then begin
      dIdle := idle - FPrevIdle;
      dTotal := (kernel - FPrevKernel) + (user - FPrevUser);
      if (dTotal > 0)
      then FCpuLoad := EnsureRange(Integer(Round(100.0 * (dTotal - dIdle) / dTotal)), 0, 100);
    end;
    FPrevIdle := idle;
    FPrevKernel := kernel;
    FPrevUser := user;
  end;

  // RAM
  FillChar(mem, SizeOf(mem), 0);
  mem.dwLength := SizeOf(mem);
  if GlobalMemoryStatusEx(mem)
  then FRamLoad := EnsureRange(Integer(mem.dwMemoryLoad), 0, 100);
end;

procedure TLinkbarWcl.DrawSysWidgets(const ABitmap: THBitmap; const AWidth, AHeight: Integer);
const
  CAPTIONS: array[0..SYSWIDGET_COUNT-1] of string = ('CPU', 'RAM');
  COLORS: array[0..SYSWIDGET_COUNT-1] of Cardinal = ($FF3B82F6, $FF22C55E); // blue, green
  COLOR_HIGH: Cardinal = $FFEF4444; // red when > 85%
var
  area, cell, bar, fill, tr: TRect;
  i, value, pad, barW, barH, cellLen, zoff: Integer;
  vertical: Boolean;
  gp: IGPGraphics;
  brushTrack, brushFill: IGPBrush;
  trackColor, fillColor: Cardinal;
  textColor: TColor;
  dc: HDC;
  fnt0: HGDIOBJ;
  s: string;
begin
  if not FShowSysWidgets
  then Exit;
  area := SysWidgetRect(AWidth, AHeight);
  if area.IsEmpty
  then Exit;

  vertical := IsVertical(Align);
  pad := ScaleDimension(4);
  barW := Max(3, ScaleDimension(5));
  if ZoomBefore then zoff := ZoomRoom else zoff := 0;
  if vertical
  then cellLen := (area.Height - pad * 2) div SYSWIDGET_COUNT
  else cellLen := (area.Width - pad * 2) div SYSWIDGET_COUNT;

  if (GlobalLook = ELookLight)
  then trackColor := $33000000
  else trackColor := $33FFFFFF;

  // Text color always readable on the bar: white on dark/accent, black on light
  // (the custom item text color may be dark, e.g. black, and disappear on a dark bar)
  if (GlobalLook = ELookLight)
  then textColor := clBlack
  else textColor := clWhite;

  dc := ABitmap.Dc;

  // 1) Bars (GDI+)
  gp := TGPGraphics.Create(dc);
  brushTrack := TGPSolidBrush.Create(trackColor);
  try
    for i := 0 to SYSWIDGET_COUNT-1 do
    begin
      if (i = 0)
      then value := FCpuLoad
      else value := FRamLoad;

      // Cell (only the button-height part of the first line is used)
      if vertical
      then cell := Rect(area.Left + zoff, area.Top + pad + i * cellLen, area.Left + zoff + ButtonSize.cx, area.Top + pad + (i + 1) * cellLen)
      else cell := Rect(area.Left + pad + i * cellLen, area.Top + zoff, area.Left + pad + (i + 1) * cellLen, area.Top + zoff + ButtonSize.cy);

      // Vertical bar (track + fill from the bottom)
      barH := Min(cell.Height - pad * 2, ScaleDimension(32));
      bar := Bounds(cell.Left + pad, cell.Top + (cell.Height - barH) div 2, barW, barH);
      GPFillRoundRect(gp, brushTrack, bar, barW div 2);

      fill := bar;
      fill.Top := bar.Bottom - Round(bar.Height * value / 100);
      if (fill.Height > 0)
      then begin
        if (value > 85)
        then fillColor := COLOR_HIGH
        else fillColor := COLORS[i];
        brushFill := TGPSolidBrush.Create(fillColor);
        GPFillRoundRect(gp, brushFill, fill, barW div 2);
      end;
    end;
  finally
    brushFill := nil;
    brushTrack := nil;
    gp := nil;
  end;

  // 2) Text (GDI, glass text like item captions)
  if not StyleServices.Enabled
  then Exit;
  fnt0 := SelectObject(dc, Screen.IconFont.Handle);
  try
    for i := 0 to SYSWIDGET_COUNT-1 do
    begin
      if (i = 0)
      then value := FCpuLoad
      else value := FRamLoad;

      if vertical
      then cell := Rect(area.Left + zoff, area.Top + pad + i * cellLen, area.Left + zoff + ButtonSize.cx, area.Top + pad + (i + 1) * cellLen)
      else cell := Rect(area.Left + pad + i * cellLen, area.Top + zoff, area.Left + pad + (i + 1) * cellLen, area.Top + zoff + ButtonSize.cy);
      barH := Min(cell.Height - pad * 2, ScaleDimension(32));
      bar := Bounds(cell.Left + pad, cell.Top + (cell.Height - barH) div 2, barW, barH);

      // Caption (top half) and value (bottom half)
      tr := Rect(bar.Right + pad, bar.Top - pad, cell.Right, bar.Top + bar.Height div 2);
      s := CAPTIONS[i];
      DrawGlassText(dc, s, tr, DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX, 0, textColor);
      tr := Rect(bar.Right + pad, bar.Top + bar.Height div 2, cell.Right, bar.Bottom + pad);
      s := IntToStr(value) + '%';
      DrawGlassText(dc, s, tr, DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX, 0, textColor);
    end;
  finally
    SelectObject(dc, fnt0);
  end;
end;

{ Timer: sample and redraw only the widget area }
procedure TLinkbarWcl.RefreshSysWidgets;
var r: TRect;
begin
  SampleSysStats;
  if FAutoHiden or IsDragDrop or FMouseDragLinkbar
     or (BitmapPanel.Width = 0) or (BitmapPanel.Height = 0)
  then Exit;
  r := SysWidgetRect(BitmapPanel.Width, BitmapPanel.Height);
  if r.IsEmpty
  then Exit;
  DrawBackground(BitmapPanel, r);
  DrawSysWidgets(BitmapPanel, BitmapPanel.Width, BitmapPanel.Height);
  UpdateWindow;
end;

procedure TLinkbarWcl.SetUseBkgndColor(AValue: Boolean);
begin
  if (AValue = FUseBkgndColor)
  then Exit;
  FUseBkgndColor := AValue;
  UpdateBackgroundColor;
end;

end.
