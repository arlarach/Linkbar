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
  Linkbar.Graphics, Linkbar.Bar.Host, Linkbar.Bar.SaveQueue, Linkbar.Bar.Profiles,
  Linkbar.Bar.SysWidgets, Linkbar.Bar.Collapse, Linkbar.Bar.Fullscreen,
  Linkbar.Bar.Thumbs, Linkbar.Bar.Running, Linkbar.Bar.Launcher,
  Linkbar.Bar.Pinned, Linkbar.Bar.ActionButtons, Linkbar.Bar.Zoom, Linkbar.Bar.Dock, Linkbar.Bar.DropTarget, Linkbar.Bar.Painter, Linkbar.Bar.PopupMenu, Linkbar.Bar.Config,
  Linkbar.Bar.AutoHide, Linkbar.Bar.LinkList,
  Linkbar.Bar.ProfileMenu, Linkbar.Bar.Commands,
  Linkbar.Bar.Presenter, Linkbar.Bar.Metrics,
  Linkbar.Bar.ItemActions, Linkbar.Bar.Keyboard;

type
  TLinkbarWcl = class(TLinkbarCustomFrom, ILinkbarHost, ICollapseHost, IFullscreenHost, IThumbsHost, ILauncherHost, IPinnedHost, IActionButtonsHost, IDockHost, IDropTargetHost, IAutoHideHost, ILinkListHost, IProfileHost, ICommandsHost, IItemActionsHost, IKeyboardHost)
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
    FDropTarget: TBarDropTarget;  // drop indicator
    FPainter: TBarPainter;        // background, captions and icons
    FPresenter: TBarPresenter;    // puts the bar on the layered window
    FAutoHider: TBarAutoHide;     // auto hide of the bar
    FLinkList: TLinkList;         // items of the links folder
    FProfileMenu: TProfileMenu;   // profiles submenu and commands
    FCommands: TBarCommands;      // group and remove commands
    FItemActions: TItemActivator; // run / click / rename an item
    FKeyboard: TBarKeyboard;      // keyboard of the bar
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
    FButtonSize: TSize;
    FGripSize: Integer;
    FExtDragIcon: HBITMAP;
    FZoom: TBarZoom;             // magnification of the dock
    FDock: TBarDock;             // dock style
    FThumbs: TThumbController;  // live thumbnails
    FRunning: TRunningIndicator;  // "program is open" indicator
    FForegroundAtMouseDown: HWND;
    FLauncher: TLauncherMode;    // "taskbar icon" mode
    FPinned: TPinnedItems;       // items kept visible when collapsed
    FActionEditor: TActionButtonEditor;  // new / edit / delete action buttons
    FFullscreen: TFullscreenWatcher;  // window in front / full screen apps
    FProfiles: TProfileManager;  // profile folders (current profile '' = main)
    FSaveQueue: TFileSaveQueue;  // list files write queue (retries when locked)
    imNewAction, imEditAction, imDeleteAction, imActionLine, imProfiles, imPinned, imPinAllActions, imUnpinAll, imAnimateCollapse, imAutoCollapse: TMenuItem;
    FSysWidgets: TSysWidgets;          // CPU / RAM widgets
    FConfig: TBarConfig;         // settings kept in the settings file
    FExtDragIconSize: Integer;
    FHotkeyInfo: THotkeyInfo;
    FLockHotIndex: Boolean;
    FSysBackgroundColor: Cardinal;
    FIconOffset: TPoint;
    FTextRect: TRect;
    FPrevForegroundWnd: HWND;
    FCollapse: TBarCollapse;      // collapse / expand of the bar
    FBtnClickHandled: Boolean;    // the mouse down was the ">>" click: its mouse up must do nothing
    FCollapseMenu: Boolean;       // the popup menu is the one of the ">>" button
    function IsCollapsed: Boolean; inline;
    procedure SetCollapseOnFullscreen(AValue: Boolean);
  private
    // Collapse / expand animation (dock mode only)
    procedure TooltipAnchor(const ARect: TRect; out APt: TPoint; out AHA: TAlignment; out AVA: TVerticalAlignment);
    procedure SetAutoCollapseSecs(AValue: Integer);
    function GetAutoCollapseSecs: Integer;
    function GetAnimateCollapse: Boolean;
    procedure SetAnimateCollapse(AValue: Boolean);
    function GetCollapseOnFullscreen: Boolean;
    procedure imAnimateCollapseClick(Sender: TObject);
    procedure imAutoCollapseClick(Sender: TObject);
  private
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
    function GetShowSysWidgets: Boolean;
    function GetShowCpuTemp: Boolean;
    procedure SetShowCpuTemp(AValue: Boolean);
    procedure SysWidgetsCellsChanged(Sender: TObject);
    procedure SetBarStyle(AValue: Integer);
    procedure SetZoomPercent(AValue: Integer);
    function GetZoomPercent: Integer;
    function IsDock: Boolean;
    function IsTaskbarIcon: Boolean;
    procedure ApplyTaskbarMode;
    procedure WMInitMenuPopup(var Message: TWMInitMenuPopup); message WM_INITMENUPOPUP;
    procedure WMMeasureItem(var Message: TWMMeasureItem); message WM_MEASUREITEM;
    procedure WMDrawItem(var Message: TWMDrawItem); message WM_DRAWITEM;
    procedure LauncherShowAsBar(Sender: TObject);
    procedure UpdateTaskbarIcon;
    procedure SetTaskbarIcon(const AValue: string);
    function GetTaskbarIcon: string;
    function ZoomEnabled: Boolean;
    function ZoomRoom: Integer;
    function ZoomIconSizeValue: Integer;
    function DockPad: Integer;
    function ItemsMargin: Integer;
    procedure ApplyDockRegion(const AWidth, AHeight: Integer);
    procedure RedrawZoom;
    procedure RefreshSysWidgets;
    procedure UpdateRunningState;
    procedure ThumbsHotChanged;
    procedure ShowThumbs(const AIndex: Integer);
    procedure CloseThumbs;
    procedure SetUseBkgndColor(AValue: Boolean);
    function GetAlign: TPanelAlign;
    procedure DrawBackground(const ABitmap: THBitmap; const AClipRect: TRect);
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
    procedure DeleteItem(const AIndex: Integer);
    function ScaleDimension(const X: Integer): Integer; inline;
    // ILinkbarHost
    function ScaleValue(const X: Integer): Integer;
    function BarButtonSize: TSize;
    function ZoomExtra: Integer;
    function BarIsVertical: Boolean;
    function BarIsCollapsed: Boolean;
    function BarOwner: TComponent;
    function BarAlign: TPanelAlign;
    function BarIconSize: Integer;
    procedure BarCancelTooltip;
    // ICollapseHost
    procedure BarUpdateSize;
    procedure BarStartTimer(const AId: UINT; const AMs: Cardinal);
    procedure BarStopTimer(const AId: UINT);
    procedure BarDismissPopups;
    procedure BarSetAutoHideLock(const ALock: Boolean);
    procedure BarRelayout;
    function BarCanAnimate: Boolean;
    function BarCollapsedLength(const AVertical: Boolean): Integer;
    procedure BarShowFrame(const ARect: TRect);
    function BarIsBusy: Boolean;
    function BarHasCollapseButton: Boolean;
    function BarHandleAllocated: Boolean;
    // IFullscreenHost
    function BarHandle: HWND;
    function BarIsTaskbarIcon: Boolean;
    // IThumbsHost
    function BarIsItem(const AIndex: Integer): Boolean;
    function BarItemRunning(const AIndex: Integer): Boolean;
    function BarItemTarget(const AIndex: Integer): string;
    function BarItemRect(const AIndex: Integer): TRect;
    function BarHotIndex: Integer;
    function BarThumbsBlocked: Boolean;
    // ILauncherHost
    function BarPanelName: string;
    function BarSettingsFile: string;
    function BarWorkDir: string;
    procedure BarHideForLauncher;
    procedure BarRestoreFromLauncher;
    function BarActionTarget: HWND;
    function BarSysStatsEnabled: Boolean;
    procedure BarSysStats(out ACpu, ARam: Integer);
    procedure BarFillLauncherMenu(AMenu: TPopupMenu);
    procedure BarCloseRequested(Sender: TObject);
    procedure BarActivate(const AWnd: HWND);
    // IPinnedHost / IActionButtonsHost / common services
    procedure BarPinnedChanged;
    // IItemActionsHost / IKeyboardHost
    function BarForegroundAtMouseDown: HWND;
    procedure BarShowGroup(const AIndex: Integer);
    procedure BarRenameGroup(const AIndex: Integer);
    procedure BarSetHotIndex(const AIndex: Integer);
    function BarItemOrder: TItemOrder;
    function BarMultiLineVertical: Boolean;
    function BarAutoHideTransparency: Boolean;
    function BarCorner1Gap: Integer;
    function BarCorner2Gap: Integer;
    // IProfileHost / ICommandsHost
    procedure BarSaveLinks;
    procedure BarSetWorkDir(const ADir: string);
    procedure BarReloadLinks;
    procedure BarMarkRemoved;
    procedure BarStopDirWatch;
    // ILinkListHost
    function BarEnsureItems: TLBItemList;
    function BarSortAlphabetically: Boolean;
    function BarDropPosition: Integer;
    procedure BarDeleteItem(const AIndex: Integer);
    procedure BarRescanTimer(const AEnabled: Boolean);
    procedure BarClearDropPosition;
    procedure BarLinksChanged;
    // IAutoHideHost
    function BarAutoHideEnabled: Boolean;
    function BarAutoShowDelay: Integer;
    procedure BarClearHot;
    procedure BarPresent(const ABounds: TRect);
    procedure BarEnableContextMenu(const AEnabled: Boolean);
    // IPainterHost (common bar services)
    function BarButtonBitmap: THBitmap;
    function BarIsLightStyle: Boolean;
    function BarPressedIndex: Integer;
    function BarSeparatorWidth: Integer;
    function BarItemsMargin: Integer;
    function BarReservedLength(const AVertical: Boolean): Integer;
    function BarTextLayout: TTextLayout;
    function BarTextRect: TRect;
    function BarUseTextColor: Boolean;
    function BarTextColor: Cardinal;
    function BarGlowSize: Integer;
    // IDropTargetHost
    function BarItemAt(const APt: TPoint): Integer;
    function BarDraggingItem: Boolean;
    function BarDragIndex: Integer;
    function BarPanelBitmap: THBitmap;
    function BarWorkDirPidl: PItemIDList;
    procedure BarPaintDropHighlight(const AIndex: Integer; const ARect: TRect);
    procedure BarRefresh;
    // IDockHost
    function BarIsDock: Boolean;
    function BarExpandedLength(const AVertical: Boolean): Integer;
    function BarBackgroundColor: Cardinal;
    function BarOpaque: Boolean;
    function BarWorkArea: TRect;
    function BarBounds: TRect;
    procedure BarMoveTo(const AX, AY: Integer);
    // IZoomHost
    function BarIconOffset: TPoint;
    function BarSeparatorStyle: TSeparatorStyle;
    procedure BarDrawItemMarks(const ABitmap: THBitmap; const AItem: TItemBase; const ARect: TRect);
    function BarDockPad: Integer;
    procedure BarRescanSoon;
    function BarItems: TLBItemList;
  private
    procedure L10n;
    procedure LoadSettings;
    procedure SaveLinks;
  private
    procedure ShowSaveFailed(Sender: TObject);
    procedure SaveRetryScheduled(Sender: TObject);
  private
    BitBucketNotify: Cardinal;
    procedure UpdateBitBuckets;
  private
    FRemoved: boolean;
    FDragAlign: TPanelAlign;
    FDragMonitorNum: Integer;
    FItemPopup: Integer;
    FDragIndex: Integer;
    MonitorsWorkareaWoTaskbar: TDynRectArray;
    procedure DoClickItem(X, Y: Integer);
    procedure ShowGroup(const AIndex: Integer);
    procedure DragExternalFile(const AFileName: string; AIcon: HBITMAP; AIconSize: Integer);
    procedure GroupChanged(Sender: TObject);
    procedure SetHideOnFullscreen(AValue: Boolean);
    function GetHideOnFullscreen: Boolean;
    procedure RunActionItem(const AIndex: Integer);
    procedure imNewActionClick(Sender: TObject);
    procedure imEditActionClick(Sender: TObject);
    procedure imPinnedClick(Sender: TObject);
    procedure imPinAllActionsClick(Sender: TObject);
    procedure imUnpinAllClick(Sender: TObject);
    procedure ApplyPinned;
    function PinnedLength(const AVertical: Boolean): Integer;
    procedure imDeleteActionClick(Sender: TObject);
    procedure ReloadLinks;
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
    procedure CreateServices;
    procedure DestroyServices;
    procedure CreateExtraMenuItems;
  protected
    // Drag&Drop functions
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
    procedure OnFormJumplistDestroy(Sender: TObject);
  public
    procedure SaveSettings;
    procedure UpdateItemSizes;
    property AutoHide: Boolean read FConfig.AutoHide write SetAutoHide;
    property AutoHideTransparency: Boolean read FConfig.AutoHideTransparency write FConfig.AutoHideTransparency;
    property AutoShowDelay: Integer read FConfig.AutoShowDelay write FConfig.AutoShowDelay;
    property AutoShowMode: TAutoShowMode read FConfig.AutoShowMode write FConfig.AutoShowMode;
    property BackgroundColor: Cardinal read GetBackgroundColor write FConfig.BackgroundColor;
    property ButtonSize: TSize read FButtonSize write SetButtonSize;
    property EnableAeroGlass: Boolean read FConfig.EnableAeroGlass write SetEnableAeroGlass;
    property GlowSize: Integer read FConfig.GlowSize write FConfig.GlowSize;
    property TooltipShow: Boolean read FConfig.TooltipShow write FConfig.TooltipShow;
    property ModernStyle: Boolean read FConfig.ModernStyle write SetModernStyle;
    property ShowSysWidgets: Boolean read GetShowSysWidgets write SetShowSysWidgets;
    property ShowCpuTemp: Boolean read GetShowCpuTemp write SetShowCpuTemp;
    property HideOnFullscreen: Boolean read GetHideOnFullscreen write SetHideOnFullscreen;
    property CollapseOnFullscreen: Boolean read GetCollapseOnFullscreen write SetCollapseOnFullscreen;
    property AnimateCollapse: Boolean read GetAnimateCollapse write SetAnimateCollapse;
    property AutoCollapseSecs: Integer read GetAutoCollapseSecs write SetAutoCollapseSecs;
    property TaskbarIcon: string read GetTaskbarIcon write SetTaskbarIcon;
    property BarStyle: Integer read FConfig.BarStyle write SetBarStyle;
    procedure ApplyWindowAccent;
    property ZoomPercent: Integer read GetZoomPercent write SetZoomPercent;
    property HotIndex: Integer read FHotIndex write SetHotIndex;
    property HotkeyInfo: THotkeyInfo read FHotkeyInfo write SetHotkeyInfo;
    property IconSize: Integer read FConfig.IconSize write SetIconSize;
    property IsLightStyle: Boolean read FConfig.IsLightStyle write SetIsLightStyle;
    property ItemMargin: TSize read FConfig.ItemMargin write SetItemMargin;
    property ItemOrder: TItemOrder read FConfig.ItemOrder write SetItemOrder;
    property JumplistShowMode: TJumplistShowMode read FConfig.JumplistShowMode write FConfig.JumplistShowMode;
    property JumplistRecentMax: Integer read FConfig.JumplistRecentMax write FConfig.JumplistRecentMax;
    property TransparencyMode: TTransparencyMode read FConfig.TransparencyMode write SetTransparencyMode;
    property Look: TLook read FConfig.Look  write SetLook;
    property PressedIndex: Integer read FPressedIndex write SetPressedIndex;
    property Layout: TPanelLayout read FConfig.Layout write SetLayout;
    property Align: TPanelAlign read GetAlign  write SetAlign;
    property SortAlphabetically: Boolean read FConfig.SortAlphabetically write SetSortAlphabetically;
    property StayOnTop: Boolean read FConfig.StayOnTop write SetStayOnTop default True;
    property TextLayout: TTextLayout read FConfig.TextLayout write SetTextLayout;
    property TextOffset: Integer read FConfig.TextOffset write SetTextOffset;
    property TextWidth: Integer read FConfig.TextWidth write SetTextWidth;
    property TextColor: Cardinal read FConfig.TextColor write FConfig.TextColor;
    property UseBkgndColor: Boolean read FConfig.UseBkgndColor write SetUseBkgndColor;
    property UseTextColor: Boolean read FConfig.UseTextColor write FConfig.UseTextColor;
    property SeparatorWidth: Integer read FConfig.SeparatorWidth write FConfig.SeparatorWidth default DEF_SEPARATOR_WIDTH;
    property SeparatorStyle: TSeparatorStyle read FConfig.SeparatorStyle write FConfig.SeparatorStyle default DEF_SEPARATOR_STYLE;
    //
    property Corner1GapWidth: Integer read FConfig.Corner1GapWidth write FConfig.Corner1GapWidth;
    property Corner2GapWidth: Integer read FConfig.Corner2GapWidth write FConfig.Corner2GapWidth;
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
  Linkbar.OS, Linkbar.L10n, JumpLists.Form, JumpLists.Api_2,
  Linkbar.SettingsForm, Linkbar.Settings, Linkbar.GroupForm,
  Linkbar.Actions, Linkbar.Bar.MenuHook;

const
  bf: TBlendFunction = (BlendOp: AC_SRC_OVER; BlendFlags: 0;
      SourceConstantAlpha: $FF; AlphaFormat: AC_SRC_ALPHA);

  LM_SHELLNOTIFY = WM_USER + 88;
  LM_TASKBARMODE = WM_USER + 89;
  TIMER_SYS_WIDGETS = 17;
  TIMER_RUNNING = 18;
  TIMER_FOREGROUND = 20;
  TIMER_SAVE_RETRY = 21;
  TIMER_SAVE_NOTICE = 22;
  SAVE_RETRY_MS = 5000;

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

procedure TLinkbarWcl.GetOrCreateFilesList(const AFileName: string);
begin
  FLinkList.Load(AFileName);
end;

function TLinkbarWcl.BarEnsureItems: TLBItemList;
begin
  if not Assigned(Items)
  then Items := TLBItemList.Create;
  Result := Items;
end;

function TLinkbarWcl.BarSortAlphabetically: Boolean;
begin
  Result := FConfig.SortAlphabetically;
end;

function TLinkbarWcl.BarDropPosition: Integer;
begin
  Result := FDropTarget.Position;
end;

procedure TLinkbarWcl.BarDeleteItem(const AIndex: Integer);
begin
  DeleteItem(AIndex);
end;

procedure TLinkbarWcl.BarRescanTimer(const AEnabled: Boolean);
begin
  tmrUpdate.Enabled := AEnabled;
end;

procedure TLinkbarWcl.BarClearDropPosition;
begin
  SetDropPosition( Point(-1, -1) );
end;

procedure TLinkbarWcl.BarLinksChanged;
begin
  oAppBar.AppBarPosChanged;
  // Taskbar icon mode: the automatic icon shows the first icons of the bar
  UpdateTaskbarIcon;
end;

function TLinkbarWcl.GetAlign: TPanelAlign;
begin
  if (FMouseDragLinkbar)
  then Result := FDragAlign
  else Result := FConfig.Align;
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
begin
  if Assigned(FPainter)
  then FPainter.DrawBackground(ABitmap, AClipRect);
end;

procedure TLinkbarWcl.DrawItem(ABitmap: THBitmap; AIndex: integer; ASelected,
  APressed: Boolean; ADrawBg: Boolean; ADrawForDrag: Boolean);
begin
  if Assigned(FPainter)
  then FPainter.DrawItem(ABitmap, AIndex, ASelected, APressed, ADrawBg, ADrawForDrag);
end;

procedure TLinkbarWcl.DrawItems(const AWidth, AHeight: integer);
begin
  if Assigned(FPainter)
  then FPainter.DrawItems(AWidth, AHeight);
end;

function TLinkbarWcl.BarButtonBitmap: THBitmap;
begin
  Result := BitmapButton;
end;

function TLinkbarWcl.BarIsLightStyle: Boolean;
begin
  Result := FConfig.IsLightStyle;
end;

function TLinkbarWcl.BarPressedIndex: Integer;
begin
  Result := FPressedIndex;
end;

function TLinkbarWcl.BarSeparatorWidth: Integer;
begin
  Result := FConfig.SeparatorWidth;
end;

function TLinkbarWcl.BarItemsMargin: Integer;
begin
  Result := ItemsMargin;
end;

function TLinkbarWcl.BarReservedLength(const AVertical: Boolean): Integer;
begin
  Result := FSysWidgets.ReservedLength(AVertical);
end;

function TLinkbarWcl.BarTextLayout: TTextLayout;
begin
  Result := FConfig.TextLayout;
end;

function TLinkbarWcl.BarTextRect: TRect;
begin
  Result := FTextRect;
end;

function TLinkbarWcl.BarUseTextColor: Boolean;
begin
  Result := FConfig.UseTextColor;
end;

function TLinkbarWcl.BarTextColor: Cardinal;
begin
  Result := FConfig.TextColor;
end;

function TLinkbarWcl.BarGlowSize: Integer;
begin
  Result := FConfig.GlowSize;
end;

procedure TLinkbarWcl.RecreateMainBitmap(const AWidth, AHeight: integer);
begin
  if FCollapse.Animating  // the animation uses the bitmap rendered at its start
  then Exit;
  BitmapPanel.SetSize(AWidth, AHeight);
  BitmapPanel.Clear;
  // Draw background
  DrawBackground(BitmapPanel, Rect(0, 0, AWidth, AHeight));
  // Draw items
  DrawItems(AWidth, AHeight);
  // CPU/RAM widgets
  FSysWidgets.Draw(BitmapPanel, AWidth, AHeight);
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
  FDropTarget.SetSize(AWidth, AHeight);
end;

procedure TLinkbarWcl.UpdateWindow;
begin
  UpdateWindow(BoundsRect);
end;

procedure TLinkbarWcl.UpdateWindow(const ABounds: TRect);
begin
  if Assigned(FPresenter)
  then FPresenter.Present(ABounds);
end;

function TLinkbarWcl.BarAutoHideTransparency: Boolean;
begin
  Result := FConfig.AutoHideTransparency;
end;

function TLinkbarWcl.BarCorner1Gap: Integer;
begin
  Result := FConfig.Corner1GapWidth;
end;

function TLinkbarWcl.BarCorner2Gap: Integer;
begin
  Result := FConfig.Corner2GapWidth;
end;

procedure TLinkbarWcl.UpdateBlur;
var blurEnabled: Boolean;
begin
  if IsWindows10
  then begin
    ApplyWindowAccent;
  end
  else begin
    blurEnabled := not (FAutoHider.Hidden and FConfig.AutoHideTransparency);
    if (IsWindows8And8Dot1 and not FConfig.EnableAeroGlass)
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
  FProfiles.BaseDir     := WorkDir;  // expanded by SetWorkDir
  FProfiles.Current     := Trim(settings.Read(INI_PROFILE, ''));
  if (FProfiles.Current <> '')
  then begin
    if DirectoryExists(FProfiles.ProfileDir(FProfiles.Current))
    then WorkDir := FProfiles.ProfileDir(FProfiles.Current)
    else FProfiles.Current := '';
  end;
  FFullscreen.HideOnFullscreen     := settings.Read(INI_HIDE_FULLSCREEN, DEF_HIDE_FULLSCREEN);
  FCollapse.OnFullscreen := settings.Read(INI_COLLAPSE_FULLSCREEN, DEF_COLLAPSE_FULLSCREEN);
  FCollapse.AnimateEnabled      := settings.Read(INI_ANIMATE_COLLAPSE, DEF_ANIMATE_COLLAPSE);
  FCollapse.AutoSecs     := settings.Read(INI_AUTOCOLLAPSE, DEF_AUTOCOLLAPSE, 0, 3600);
  FLauncher.IconSpec          := Trim(settings.Read(INI_TASKBAR_ICON, ''));
  FConfig.Load(settings);
  FSysWidgets.Enabled       := settings.Read(INI_SYS_WIDGETS, DEF_SYS_WIDGETS);
  FSysWidgets.TempEnabled   := settings.Read(INI_CPU_TEMP, DEF_CPU_TEMP);
  // Without the CPU/RAM widgets there is no ">>" button to expand again
  FCollapse.ManualCollapsed         := settings.Read(INI_COLLAPSED, DEF_COLLAPSED) and FSysWidgets.Enabled;
  FZoom.Percent          := settings.Read(INI_ZOOM, DEF_ZOOM, ZOOM_MIN, ZOOM_MAX);
  FZoom.Cursor           := -1;
  FDock.Pos             := settings.Read(INI_DOCK_POS, DEF_DOCK_POS, 0, 1000);
  hki                   := settings.Read(INI_AUTOHIDE_HOTKEY, DEF_AUTOHIDE_HOTKEY);
  FConfig.StayOnTop := (FormStyle = fsStayOnTop);
  StayOnTop             := settings.Read(INI_STAYONTOP, DEF_STAYONTOP);
  //
  settings.Close;

  // Set other values
  FGripSize := GRIP_SIZE;
  FHotIndex := ITEM_NONE;
  FPressedIndex := ITEM_NONE;
  FDropTarget.Position := ITEM_NONE;
  FItemPopup := ITEM_NONE;
  FDragIndex := ITEM_NONE;
  FMouseLeftDown := False;
  FMouseDragLinkbar := False;
  FMouseDragItem := False;
  FDragingItem := False;

  GlobalLayout := FConfig.Layout;
  GlobalLook := FConfig.Look;
  GlobalAeroGlassEnabled := FConfig.EnableAeroGlass;
  GlobalModernStyle := FConfig.ModernStyle;

  // CPU/RAM widgets
  if FSysWidgets.Enabled
  then begin
    FSysWidgets.Sample;
    SetTimer(Handle, TIMER_SYS_WIDGETS, 1000, nil);
  end;

  // "Program is open" indicator
  SetTimer(Handle, TIMER_RUNNING, 2000, nil);

  // Window in front: action buttons target + hide on full screen
  SetTimer(Handle, TIMER_FOREGROUND, 500, nil);
  FCollapse.ArmAuto;

  // Register Hotkey
  HotkeyInfo := hki;
end;

procedure TLinkbarWcl.SaveRetryScheduled(Sender: TObject);
begin
  SetTimer(Handle, TIMER_SAVE_RETRY, SAVE_RETRY_MS, nil);
end;

procedure TLinkbarWcl.ShowSaveFailed(Sender: TObject);
begin
  var pt := Point(Width div 2, Height div 2);
  MapWindowPoints(Handle, HWND_DESKTOP, pt, 1);
  ToolTip.Activate(pt, L10NFind('Message.SaveFailed', 'Could not save the bar list (file in use)'), taCenter, taAlignBottom);
  SetTimer(Handle, TIMER_SAVE_NOTICE, 4000, nil);
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

      FSaveQueue.Save(WorkDir + LINKSLIST_FILE_NAME, sl.Text);

      // Items that stay visible when the bar is collapsed
      FPinned.Save(WorkDir, FSaveQueue);
    finally
      sl.Free;
    end;
  end;
end;

{ Length taken by the pinned items when the bar is collapsed }
function TLinkbarWcl.PinnedLength(const AVertical: Boolean): Integer;
begin
  Result := FPinned.CollapsedLength;
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
    FConfig.Save(settings, Align, BackgroundColor);
    settings.Write(INI_HIDE_FULLSCREEN, FFullscreen.HideOnFullscreen);
    settings.Write(INI_COLLAPSE_FULLSCREEN, FCollapse.OnFullscreen);
    settings.Write(INI_ANIMATE_COLLAPSE, FCollapse.AnimateEnabled);
    settings.Write(INI_AUTOCOLLAPSE, FCollapse.AutoSecs);
    settings.Write(INI_TASKBAR_ICON, FLauncher.IconSpec);
    settings.Write(INI_PROFILE, FProfiles.Current);
    settings.Write(INI_AUTOHIDE_HOTKEY, string(HotkeyInfo));
    settings.Write(INI_SYS_WIDGETS, FSysWidgets.Enabled);
    settings.Write(INI_CPU_TEMP, FSysWidgets.TempEnabled);
    settings.Write(INI_ZOOM, FZoom.Percent);
    settings.Write(INI_DOCK_POS, FDock.Pos);
    settings.Write(INI_COLLAPSED, FCollapse.ManualCollapsed);
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

{ Services of the bar (one class per responsibility, see Linkbar.Bar.*). The order matters:
  some of them take others as collaborators }
procedure TLinkbarWcl.CreateServices;
begin
  TMenuBorderHook.Install;
  FProfiles := TProfileManager.Create;
  FAutoHider := TBarAutoHide.Create(Self);
  FSaveQueue := TFileSaveQueue.Create;
  FSaveQueue.OnScheduleRetry := SaveRetryScheduled;
  FSaveQueue.OnFailed := ShowSaveFailed;
  FSysWidgets := TSysWidgets.Create(Self);
  FSysWidgets.OnCellsChanged := SysWidgetsCellsChanged;
  FCollapse := TBarCollapse.Create(Self);
  FFullscreen := TFullscreenWatcher.Create(Self, FCollapse);
  FThumbs := TThumbController.Create(Self);
  FLauncher := TLauncherMode.Create(Self);
  FPinned := TPinnedItems.Create(Self);
  FZoom := TBarZoom.Create(Self);
  FDock := TBarDock.Create(Self, FZoom);
  FDropTarget := TBarDropTarget.Create(Self);
  FPainter := TBarPainter.Create(Self, FDock, FZoom);
  FPresenter := TBarPresenter.Create(Self, FCollapse, FAutoHider);
  FLinkList := TLinkList.Create(Self, FPinned, FZoom);
  FProfileMenu := TProfileMenu.Create(Self, FProfiles);
  FCommands := TBarCommands.Create(Self, FProfiles);
  FItemActions := TItemActivator.Create(Self, FFullscreen);
  FKeyboard := TBarKeyboard.Create(Self, FAutoHider, FItemActions);
  FActionEditor := TActionButtonEditor.Create(Self);
  FRunning := TRunningIndicator.Create(Self);
end;

procedure TLinkbarWcl.DestroyServices;
begin
  FreeAndNil(FSaveQueue);
  FreeAndNil(FActionEditor);
  FreeAndNil(FKeyboard);
  FreeAndNil(FItemActions);
  FreeAndNil(FCommands);
  FreeAndNil(FProfileMenu);
  FreeAndNil(FLinkList);
  FreeAndNil(FPresenter);
  FreeAndNil(FPainter);
  FreeAndNil(FAutoHider);
  FreeAndNil(FDropTarget);
  FreeAndNil(FDock);
  FreeAndNil(FZoom);
  FreeAndNil(FPinned);
  FreeAndNil(FLauncher);
  FreeAndNil(FRunning);
  FreeAndNil(FThumbs);
  FreeAndNil(FFullscreen);
  FreeAndNil(FCollapse);
  FreeAndNil(FSysWidgets);
  FreeAndNil(FProfiles);
end;

{ Menu items that are created by code (the others are in the form) }
procedure TLinkbarWcl.CreateExtraMenuItems;
begin
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
  // Keep the item visible when the bar is collapsed (">>")
  imPinned := TMenuItem.Create(pMenu);
  imPinned.Caption := L10NFind('Menu.Pinned', 'Keep visible when collapsed');
  imPinned.OnClick := imPinnedClick;
  pMenu.Items.Insert(0, imPinned);
  // Pin / unpin several items (bar menu, no item under the cursor)
  imPinAllActions := TMenuItem.Create(pMenu);
  imPinAllActions.Caption := L10NFind('Menu.PinAllActions', 'Keep all action buttons visible when collapsed');
  imPinAllActions.OnClick := imPinAllActionsClick;
  pMenu.Items.Insert(1, imPinAllActions);
  imUnpinAll := TMenuItem.Create(pMenu);
  imUnpinAll.Caption := L10NFind('Menu.UnpinAll', 'Clear all items kept visible when collapsed');
  imUnpinAll.OnClick := imUnpinAllClick;
  pMenu.Items.Insert(2, imUnpinAll);
  // Options of the ">>" button menu (only shown there)
  imAnimateCollapse := TMenuItem.Create(pMenu);
  imAnimateCollapse.OnClick := imAnimateCollapseClick;
  pMenu.Items.Insert(3, imAnimateCollapse);
  imAutoCollapse := TMenuItem.Create(pMenu);
  imAutoCollapse.OnClick := imAutoCollapseClick;
  pMenu.Items.Insert(4, imAutoCollapse);
  // Profiles (sub-menu filled when the menu opens)
  imProfiles := TMenuItem.Create(pMenu);
  imProfiles.Caption := L10NFind('Menu.Profile', 'Profile');
  pMenu.Items.Insert(pMenu.Items.IndexOf(imNew) + 1, imProfiles);

  pMenu.Items.RethinkHotkeys;
  imNew.RethinkHotkeys;
end;

procedure TLinkbarWcl.FormCreate(Sender: TObject);
begin
  CreateServices;
  FCreated := False;
  CreateBitmaps;

  Self.DesktopFont := True;

  L10n;

  CreateExtraMenuItems;

  ToolTip := TTooltip32.Create(Handle);

  Color := 0;
  FrmProperties := nil;
  FAutoHider.Locked := False;
  FAutoHider.CanAutoHide := True;

  LoadSettings;

  UpdateBackgroundColor;

  if IsWindows10
  then ThemeSetWindowAttribute10(Handle, FConfig.TransparencyMode, BackgroundColor)
  else ThemeSetWindowAttribute78(Handle);
  // Dock: its own anti-aliased background, no DWM accent (that one has jagged corners)
  if IsWindows10 and IsDock
  then ThemeSetWindowAccentPolicy10(Handle, tmDisabled, 0);

  ThemeInitData(Handle, FConfig.IsLightStyle);

  GetOrCreateFilesList(WorkDir + LINKSLIST_FILE_NAME);

  UpdateItemSizes;

  oAppBar := TAccessBar.Create2(self, FConfig.Align, FALSE);
  oAppBar.StayOnTop := StayOnTop;
  oAppBar.MonitorNum := FConfig.MonitorNum;
  oAppBar.QuerySizing := QuerySizingEvent;
  oAppBar.QuerySized := QuerySizedEvent;
  oAppBar.QueryAutoHide := QueryHideEvent;

  // Dock mode: floating bar, no autohide
  oAppBar.Floating := IsDock or IsTaskbarIcon;
  if IsDock or IsTaskbarIcon then FConfig.AutoHide := False;

  if not AutoHide then oAppBar.Loaded
  else AutoHide := TRUE;

  BitBucketNotify := RegisterBitBucketNotify(Handle, LM_SHELLNOTIFY);

  FCreated := True;
  UpdateBlur;

  CreateLinkbarTasksJumplist;

  FAutoHider.DelayedHide(1000);

  // Taskbar icon mode: hide the bar once the form has been shown
  if IsTaskbarIcon
  then PostMessage(Handle, LM_TASKBARMODE, 0, 0);
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
  TMenuBorderHook.Remove;
  UnregisterBitBucketNotify(BitBucketNotify);
  UnregisterHotkeyNotify(Handle);

  if Assigned(FrmProperties)
  then FrmProperties.Free;

  oAppBar.Free;
  StopDirWatch;

  if (not FRemoved)
  then SaveLinks;
  DestroyServices;

  ThemeCloseData;

  if Assigned(ToolTip) then ToolTip.Free;
  if Assigned(BitmapPanel) then BitmapPanel.Free;
  if Assigned(BitmapButton) then BitmapButton.Free;
  if Assigned(BitmapSelected) then BitmapSelected.Free;
  if Assigned(Items) then Items.Free;
end;

procedure TLinkbarWcl.CreateBitmaps;
begin
  BitmapSelected := THBitmap.Create(32);
  BitmapButton := THBitmap.Create(32);
  BitmapPanel := THBitmap.Create(32);
end;

function TLinkbarWcl.IsItemIndex(const AIndex: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex < Items.Count);
end;

procedure TLinkbarWcl.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Assigned(FKeyboard)
  then FKeyboard.KeyDown(Key);
end;

function TLinkbarWcl.BarForegroundAtMouseDown: HWND;
begin
  Result := FForegroundAtMouseDown;
end;

procedure TLinkbarWcl.BarShowGroup(const AIndex: Integer);
begin
  ShowGroup(AIndex);
end;

procedure TLinkbarWcl.BarRenameGroup(const AIndex: Integer);
begin
  RenameGroup(AIndex);
end;

procedure TLinkbarWcl.BarSetHotIndex(const AIndex: Integer);
begin
  HotIndex := AIndex;
end;

function TLinkbarWcl.BarItemOrder: TItemOrder;
begin
  Result := FConfig.ItemOrder;
end;

function TLinkbarWcl.BarMultiLineVertical: Boolean;
begin
  Result := oAppBar.Vertical;
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
  if AutoHide and FAutoHider.Hidden
  then Exit;

  FCollapse.CancelAuto;  // the bar is being used
  FBtnClickHandled := False;
  FMousePosDown := Point(X, Y);
  // window that was in front before clicking the bar (for minimize on click)
  if (GetForegroundWindow <> Handle)
  then FForegroundAtMouseDown := GetForegroundWindow;
  CloseThumbs;

  // Dock: Ctrl + drag slides it along the same screen edge
  if IsDock and (Button = mbLeft)
     and (ssCtrl in Shift) and not (ssShift in Shift)
  then begin
    FDock.BeginSlide;
    SetCapture(Handle);
    ToolTip.Cancel;
    Exit;
  end;

  if (Button = mbLeft) and FSysWidgets.Enabled and PtInRect(FSysWidgets.CollapseRect, Point(X, Y)) then
  begin
    ToolTip.Cancel;
    // The layout changes under the cursor: the mouse up would fall on the CPU/RAM widgets (Task Manager)
    FBtnClickHandled := True;
    if FCollapse.CollapsedByIdle
    then begin
      // Collapsed for inactivity: the click only expands again (saved state untouched)
      FCollapse.CollapsedByIdle := False;
    end
    else begin
      FCollapse.ManualCollapsed := not FCollapse.ManualCollapsed;
      TSettingsFile.Write(FSettingsFileName, INI_COLLAPSED, FCollapse.ManualCollapsed);
    end;
    if FCollapse.CanAnimate
    then FCollapse.StartAnim(FCollapse.ManualCollapsed)
    else UpdateWindowSize;
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
  if FDock.Sliding
  then begin
    FDock.Drag;
    Exit;
  end;

  if (X = prevX) and (Y = prevY)
  then Exit;
  prevX := X; prevY := Y;

  if FAutoHider.Hidden then Exit;

  if Self.IsDragDrop then Exit;
  if FDropTarget.Position <> ITEM_NONE then Exit;

  if not FMouseLeftDown then
  begin
    HotIndex := ItemIndexByPoint( Point(X, Y), HotIndex );

    // Magnification follows the mouse
    if ZoomEnabled and (not FMouseDragLinkbar)
    then begin
      if IsVertical(Align)
      then FZoom.Cursor := Y
      else FZoom.Cursor := X;
      RedrawZoom;
    end;
  end;

  if FSysWidgets.Enabled then
  begin
    var isHot: Boolean;
    isHot := PtInRect(FSysWidgets.CollapseRect, Point(X, Y));
    if isHot <> FSysWidgets.CollapseHot then
    begin
      FSysWidgets.CollapseHot := isHot;
      UpdateWindow;

      // Hint of the ">>" / "<<" button
      if isHot and TooltipShow
      then begin
        var hintPt: TPoint;
        var hintHA: TAlignment;
        var hintVA: TVerticalAlignment;
        TooltipAnchor(FSysWidgets.CollapseRect, hintPt, hintHA, hintVA);
        if IsCollapsed
        then ToolTip.Activate(hintPt, L10NFind('Hint.Expand', 'Expand the bar'), hintHA, hintVA)
        else ToolTip.Activate(hintPt, L10NFind('Hint.Collapse', 'Collapse: pinned items and CPU/RAM stay'), hintHA, hintVA);
      end
      else if not isHot
      then ToolTip.Cancel;
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
    else if (not FConfig.LockLinkbar)
    then begin
      if (FPressedIndex = ITEM_NONE)
      then begin
        if ( TPoint.Create(X,Y).Distance(FMousePosDown) > PANEL_DRAG_THRESHOLD )
        then begin
          FMouseDragLinkbar := True;
          FMouseDragItem := False;
          GetUserWorkArea(MonitorsWorkareaWoTaskbar);
          FBeforeDragBounds := BoundsRect;
          FDragMonitorNum := FConfig.MonitorNum;
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
  if FAutoHider.Hidden
  then begin
    if ( (AutoShowMode = EAutoShowModeMouseClickLeft) and (Button =  mbLeft) )
       or
       ( (AutoShowMode = EAutoShowModeMouseClickRight) and (Button = mbRight) )
    then begin
      if PtInRect(Rect(0,0,Width,Height), Point(X, Y))
      then begin
        FAutoHider.CanAutoHide := False;
        FAutoHider.Show;
      end;
    end;
    Exit;
  end;

  // Release of the ">>" / "<<" click
  if FBtnClickHandled and (Button = mbLeft)
  then begin
    FBtnClickHandled := False;
    Exit;
  end;

  // End of Ctrl+drag of the dock
  if FDock.Sliding and (Button = mbLeft)
  then begin
    FDock.Sliding := False;
    ReleaseCapture;
    Screen.Cursor := crDefault;
    if FDock.SlideMoved
    then FDock.SavePos
    else if (ItemIndexByPoint(Point(X, Y)) = ITEM_NONE)
    then begin
      // Ctrl+click on an empty area: center the dock again
      FDock.ResetPos;
      oAppBar.AppBarPosChanged;
    end
    else DoClickItem(X, Y);
    Exit;
  end;

  FAutoHider.CanAutoHide := False;
  FMousePosUp := Point(X, Y);
  case Button of
    mbLeft:
      begin
        FMouseLeftDown := False;
        // drag linkbar end
        if FMouseDragLinkbar then
        begin
          FMouseDragLinkbar := False;
          FConfig.MonitorNum := FDragMonitorNum;
          Align := FDragAlign;
          TSettingsFile.Write(FSettingsFileName, INI_MONITORNUM, FConfig.MonitorNum);
          TSettingsFile.Write(FSettingsFileName, INI_EDGE, Integer(FConfig.Align));
        end
        else if FMouseDragItem
        then begin // drag item end
          FMouseDragItem := False;
          FDragingItem := False;
          FDragIndex := ITEM_NONE;
        end
        else if (PressedIndex = ITEM_NONE)
             and FSysWidgets.Enabled
             and PtInRect(FSysWidgets.WidgetRect(Width, Height), Point(X, Y))
             and PtInRect(FSysWidgets.WidgetRect(Width, Height), FMousePosDown)
             and not PtInRect(FSysWidgets.CollapseRect, Point(X, Y))
             and not PtInRect(FSysWidgets.CollapseRect, FMousePosDown)
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
  FAutoHider.Locked := True;
  form.PopupAt(itemRect, Align);
end;

procedure TLinkbarWcl.DoClickItem(X, Y: Integer);
begin
  FItemActions.Click( ItemIndexByPoint( Point(X, Y) ) );
end;

procedure TLinkbarWcl.DoRenameItem(const AIndex: Integer);
begin
  FItemActions.Rename(AIndex);
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

procedure TLinkbarWcl.SetHideOnFullscreen(AValue: Boolean);
begin
  FFullscreen.ChangeHide(AValue);
end;

function TLinkbarWcl.GetHideOnFullscreen: Boolean;
begin
  Result := FFullscreen.HideOnFullscreen;
end;

function TLinkbarWcl.IsCollapsed: Boolean;
begin
  Result := Assigned(FCollapse) and FCollapse.IsCollapsed;
end;

{ Position and alignment of a tooltip next to ARect (client coordinates -> screen) }
procedure TLinkbarWcl.TooltipAnchor(const ARect: TRect; out APt: TPoint; out AHA: TAlignment; out AVA: TVerticalAlignment);
begin
  APt := ARect.CenterPoint;
  AHA := taLeftJustify;
  AVA := taAlignBottom;
  case Align of
    EPanelAlignLeft:
      begin
        APt.X := ARect.Right + TOOLTIP_OFFSET;
        AVA := taVerticalCenter;
        AHA := taLeftJustify;
      end;
    EPanelAlignTop:
      begin
        APt.Y := ARect.Bottom + TOOLTIP_OFFSET;
        AVA := taAlignBottom;
        AHA := taCenter;
      end;
    EPanelAlignRight:
      begin
        APt.X := ARect.Left - TOOLTIP_OFFSET;
        AVA := taVerticalCenter;
        AHA := taRightJustify;
      end;
    EPanelAlignBottom:
      begin
        APt.Y := ARect.Top - TOOLTIP_OFFSET;
        AVA := taAlignTop;
        AHA := taCenter;
      end;
  end;
  MapWindowPoints(Handle, HWND_DESKTOP, APt, 1);
end;

procedure TLinkbarWcl.SetAutoCollapseSecs(AValue: Integer);
begin
  FCollapse.ChangeAutoSecs(AValue);
end;

function TLinkbarWcl.GetAutoCollapseSecs: Integer;
begin
  Result := FCollapse.AutoSecs;
end;

function TLinkbarWcl.GetAnimateCollapse: Boolean;
begin
  Result := FCollapse.AnimateEnabled;
end;

procedure TLinkbarWcl.SetAnimateCollapse(AValue: Boolean);
begin
  FCollapse.AnimateEnabled := AValue;
end;

function TLinkbarWcl.GetCollapseOnFullscreen: Boolean;
begin
  Result := FCollapse.OnFullscreen;
end;

procedure TLinkbarWcl.imAnimateCollapseClick(Sender: TObject);
begin
  FCollapse.AnimateEnabled := not FCollapse.AnimateEnabled;
  TSettingsFile.Write(FSettingsFileName, INI_ANIMATE_COLLAPSE, FCollapse.AnimateEnabled);
end;

procedure TLinkbarWcl.imAutoCollapseClick(Sender: TObject);
begin
  if (FCollapse.AutoSecs > 0)
  then SetAutoCollapseSecs(0)
  else SetAutoCollapseSecs(AUTOCOLLAPSE_DEFAULT_SECS);
  TSettingsFile.Write(FSettingsFileName, INI_AUTOCOLLAPSE, FCollapse.AutoSecs);
end;

procedure TLinkbarWcl.SetCollapseOnFullscreen(AValue: Boolean);
begin
  FCollapse.ChangeOnFullscreen(AValue);
end;

{ ---------- action buttons ---------- }

procedure TLinkbarWcl.RunActionItem(const AIndex: Integer);
begin
  FItemActions.RunAction(AIndex);
end;

procedure TLinkbarWcl.imNewActionClick(Sender: TObject);
begin
  FActionEditor.Add;
end;

procedure TLinkbarWcl.imEditActionClick(Sender: TObject);
begin
  if IsItemIndex(FItemPopup) and (Items[FItemPopup] is TItemAction)
  then FActionEditor.Modify(TItemAction(Items[FItemPopup]));
end;

procedure TLinkbarWcl.imDeleteActionClick(Sender: TObject);
begin
  if IsItemIndex(FItemPopup) and (Items[FItemPopup] is TItemAction)
  then FActionEditor.Remove(TItemAction(Items[FItemPopup]));
end;

procedure TLinkbarWcl.imPinnedClick(Sender: TObject);
begin
  if IsItemIndex(FItemPopup)
  then FPinned.Toggle(Items[FItemPopup]);
end;

{ After changing the pinned flags: pinned items go to the end, save and re-layout }
procedure TLinkbarWcl.ApplyPinned;
begin
  Items.PinnedToEnd;
  SaveLinks;
  UpdateWindowSize;
end;

procedure TLinkbarWcl.imPinAllActionsClick(Sender: TObject);
begin
  FPinned.PinAllActions;
end;

procedure TLinkbarWcl.imUnpinAllClick(Sender: TObject);
begin
  FPinned.UnpinAll;
end;

procedure TLinkbarWcl.BarPinnedChanged;
begin
  ApplyPinned;
end;

function TLinkbarWcl.BarDockPad: Integer;
begin
  Result := DockPad;
end;

procedure TLinkbarWcl.BarRescanSoon;
begin
  tmrUpdate.Enabled := False;
  tmrUpdate.Enabled := True;
end;

function TLinkbarWcl.BarItems: TLBItemList;
begin
  Result := Items;
end;

{ ---------- profiles ---------- }

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
  UpdateTaskbarIcon;
end;

procedure TLinkbarWcl.BarSaveLinks;
begin
  SaveLinks;
end;

procedure TLinkbarWcl.BarSetWorkDir(const ADir: string);
begin
  WorkDir := ADir;
end;

procedure TLinkbarWcl.BarReloadLinks;
begin
  ReloadLinks;
end;

procedure TLinkbarWcl.BarMarkRemoved;
begin
  FRemoved := True;
end;

procedure TLinkbarWcl.BarStopDirWatch;
begin
  StopDirWatch;
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
begin
  FCommands.RenameGroup(AIndex);
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

  if (FDragAlign = FConfig.Align)
     and (FDragMonitorNum = FConfig.MonitorNum)
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
      if (FDragMonitorNum = FConfig.MonitorNum)
         and IsVertical(FDragAlign)
      then begin
        case FConfig.Align of
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
  entries: TArray<TPopupEntry>;
  entry: TPopupEntry;
  FPopupMenu: HMENU;
  hbrBg: HBRUSH;
begin
  FProfileMenu.Build(imProfiles, pMenu);
  var isAction := IsItemIndex(FItemPopup) and (Items[FItemPopup] is TItemAction);

  // The menu is owner-drawn (no check mark): the text tells the current state
  if IsItemIndex(FItemPopup) and Items[FItemPopup].Pinned
  then imPinned.Caption := L10NFind('Menu.Unpinned', 'Do not keep visible when collapsed')
  else imPinned.Caption := L10NFind('Menu.Pinned', 'Keep visible when collapsed');

  // Options of the ">>" button menu: the text tells the current state
  if FCollapse.AnimateEnabled
  then imAnimateCollapse.Caption := L10NFind('Menu.AnimateOn', 'Turn off collapse animation')
  else imAnimateCollapse.Caption := L10NFind('Menu.AnimateOff', 'Turn on collapse animation');
  if (FCollapse.AutoSecs > 0)
  then imAutoCollapse.Caption := L10NFind('Menu.AutoCollapseOn', 'Turn off automatic collapse')
  else imAutoCollapse.Caption := Format(L10NFind('Menu.AutoCollapseOff', 'Collapse automatically after %d s without use'), [AUTOCOLLAPSE_DEFAULT_SECS]);

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

    // Menu of the ">>" button: only its own options. Normal menu: without them
    if FCollapseMenu
    then begin
      if not ((item = imPinAllActions) or (item = imUnpinAll)
              or (item = imAnimateCollapse) or (item = imAutoCollapse))
      then Continue;
    end
    else if (item = imAnimateCollapse) or (item = imAutoCollapse)
    then Continue;

    // "Edit/Delete action" only for action buttons
    if ((item = imEditAction) or (item = imDeleteAction) or (item = imActionLine))
       and not isAction
    then Continue;

    // "Keep visible when collapsed" only for an item (not separators nor the bar)
    if (item = imPinned)
       and (not IsItemIndex(FItemPopup) or Items.IsSeparator(Items[FItemPopup]))
    then Continue;

    // "Keep all actions / clear all" only in the bar menu, when they change something
    if (item = imPinAllActions) or (item = imUnpinAll)
    then begin
      if IsItemIndex(FItemPopup)
      then Continue;
      var any := False;
      for var it in Items
      do if ((item = imPinAllActions) and (it is TItemAction) and not it.Pinned)
            or ((item = imUnpinAll) and it.Pinned)
         then begin
           any := True;
           Break;
         end;
      if not any
      then Continue;
    end;

    entry.Item := item;
    entry.Checked := ((item = imPinned) and IsItemIndex(FItemPopup) and Items[FItemPopup].Pinned)
                  or ((item = imLockBar) and FConfig.LockLinkbar)
                  or ((item = imSortAlphabet) and FConfig.SortAlphabetically);
    entries := entries + [entry];
  end;

  FPopupMenu := TSciFiMenu.Build(entries, hbrBg);
  if (FPopupMenu = 0)
  then Exit;

  MapWindowPoints(Handle, HWND_DESKTOP, APt, 1);

  FLockHotIndex := True;
  FAutoHider.Locked := True;
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
    DeleteObject(hbrBg);
    FLockHotIndex := False;
    if (WindowFromPoint(MakePoint(GetMessagePos)) <> Handle)
    then begin
      HotIndex := ITEM_NONE;
    end;
    FAutoHider.Locked := False;
  end;
end;

procedure TLinkbarWcl.WMMeasureItem(var Message: TWMMeasureItem);
begin
  if not TSciFiMenu.Measure(Handle, Message)
  then inherited;
end;

procedure TLinkbarWcl.WMDrawItem(var Message: TWMDrawItem);
begin
  if not TSciFiMenu.Draw(Message)
  then inherited;
end;

procedure TLinkbarWcl.WMInitMenuPopup(var Message: TWMInitMenuPopup);
begin
  // El borde del menú se quita en TMenuBorderHook (WinEventHook de menús)
  inherited;
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
    FAutoHider.Locked := False;
    FAutoHider.CanAutoHide := True;
    FAutoHider.Hide;
  end;
end;

procedure TLinkbarWcl.DoPopupJumplist(APt: TPoint; AShift: Boolean);
begin
  if (FConfig.JumplistShowMode <> EJumplistShowModeDisabled)
  then begin
    const item = Items[FItemPopup];
    var form := TryCreateJumplist(Self, item.Pidl, FConfig.JumplistRecentMax);
    if Assigned(form)
    then begin
      var itemRect := item.Rect;
      MapWindowPoints(Handle, HWND_DESKTOP, itemRect, 2);

      if form.Popup(Handle, itemRect, Align)
      then begin
        ToolTip.Cancel;
        form.OnDestroy := OnFormJumplistDestroy;
        FLockHotIndex := True;
        FAutoHider.Locked := True;
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

  if FAutoHider.Hidden then Exit;

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

  // Right click on ">>" / "<<": menu with the collapse options
  if FSysWidgets.Enabled
     and (FItemPopup = ITEM_NONE)
     and PtInRect(FSysWidgets.CollapseRect, pt)
  then begin
    FCollapseMenu := True;
    try
      DoPopupMenu(pt, shift);
    finally
      FCollapseMenu := False;
    end;
    Exit;
  end;

  if (FItemPopup = ITEM_NONE)
     or (shift) // show extended contextmenu for item with jumplist
     or (Items[FItemPopup] is TItemGroup) // groups: menu with Rename/Delete, no jumplist
  then DoPopupMenu(pt, shift)
  else DoPopupJumplist(pt, shift);
end;

procedure TLinkbarWcl.SetAutoHide(AValue: Boolean);
begin
  // Dock and taskbar icon modes have no autohide
  if (IsDock or IsTaskbarIcon) and AValue
  then begin
    FConfig.AutoHide := False;
    Exit;
  end;
  oAppBar.AutoHide := AValue;
  FConfig.AutoHide := oAppBar.AutoHide;
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
  textHeight: Integer;
  bs: TSize;
begin
  // Calc text height
  Canvas.Font := Screen.IconFont;
  if (TextLayout = ETextLayoutNone)
  then textHeight := 0
  else textHeight := DrawText(Canvas.Handle, 'Wp', 2, r, DT_SINGLELINE or DT_NOCLIP or DT_CALCRECT);

  // Calc margin, icon offset & button size
  TItemMetrics.Calc(FConfig, textHeight, bs, FIconOffset, FTextRect);
  ButtonSize := bs;
end;

procedure TLinkbarWcl.SetIconSize(AValue: integer);
begin
  if AValue = FConfig.IconSize then Exit;
  FConfig.IconSize := EnsureRange(AValue, ICON_SIZE_MIN, ICON_SIZE_MAX);
  Items.IconSize := FConfig.IconSize;
  Items.ZoomIconSize := ZoomIconSizeValue;
end;

procedure TLinkbarWcl.SetIsLightStyle(AValue: Boolean);
begin
  if AValue = FConfig.IsLightStyle then Exit;
  FConfig.IsLightStyle := AValue;
  ThemeInitData(Handle, FConfig.IsLightStyle);
end;

procedure TLinkbarWcl.SetItemMargin(AValue: TSize);
begin
  if AValue = FConfig.ItemMargin then Exit;
  FConfig.ItemMargin := AValue;
end;

procedure TLinkbarWcl.SetTextLayout(AValue: TTextLayout);
begin
  if AValue = FConfig.TextLayout then Exit;
  FConfig.TextLayout := AValue;
end;

procedure TLinkbarWcl.SetTextOffset(AValue: Integer);
begin
  if AValue = FConfig.TextOffset then Exit;
  FConfig.TextOffset := AValue;
end;

procedure TLinkbarWcl.SetTextWidth(AValue: Integer);
begin
  if AValue = FConfig.TextWidth then Exit;
  FConfig.TextWidth := AValue;
end;

procedure TLinkbarWcl.SetItemOrder(AValue: TItemOrder);
begin
  if AValue = FConfig.ItemOrder then Exit;
  FConfig.ItemOrder := AValue;
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
    TooltipAnchor(Items[FHotIndex].Rect, Pt, HA, VA);
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
  if (FConfig.Layout = AValue)
  then Exit;

  FConfig.Layout := AValue;
  GlobalLayout := FConfig.Layout;

  //RecreateMainBitmap(Width, Height);
  //UpdateWindow;
end;

procedure TLinkbarWcl.SetAlign(AValue: TPanelAlign);
begin
  //if (FScreenEdge = AValue)
  //then Exit;

  FConfig.Align := AValue;
  FDragAlign := FConfig.Align;
  oAppBar.MonitorNum := FConfig.MonitorNum;
  oAppBar.Align := AValue;
end;

procedure TLinkbarWcl.SetSortAlphabetically(AValue: Boolean);
begin
  if (FConfig.SortAlphabetically = AValue)
  then Exit;

  FConfig.SortAlphabetically := AValue;
  TSettingsFile.Write(FSettingsFileName, INI_SORT_AB, FConfig.SortAlphabetically);

  if FConfig.SortAlphabetically
  then begin
    Items.Sort;
    RecreateMainBitmap(BitmapPanel.Width, BitmapPanel.Height);
    UpdateWindow;
  end;
end;

procedure TLinkbarWcl.SetStayOnTop(AValue: Boolean);
const FORM_STYLE: array[Boolean] of TFormStyle = (fsNormal, fsStayOnTop);
begin
  if (FConfig.StayOnTop = AValue)
  then Exit;

  FConfig.StayOnTop := AValue;
  Self.FormStyle := FORM_STYLE[FConfig.StayOnTop];

  if Assigned(oAppBar)
  then oAppBar.StayOnTop := FConfig.StayOnTop;
end;

procedure TLinkbarWcl.QuerySizingEvent(Sender: TObject; AVertical: Boolean; var AWidth, AHeight: Integer);
begin
  Items.Sizes.Button := ButtonSize;
  Items.Sizes.Separator := SeparatorWidth;
  Items.Sizes.Margin := ItemsMargin;
  Items.Sizes.ZoomRoom := ZoomRoom;
  Items.Sizes.ZoomOffset := ZoomRoom div 2;
  Items.Sizes.Reserved := FSysWidgets.ReservedLength(AVertical);
  Items.Sizes.OnlyPinned := IsCollapsed;
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
  then FDock.CalcBounds(x, y, w, h);

  // Animation start: only render the expanded bitmap, the window is not changed
  if FCollapse.AnimBuild
  then begin
    FCollapse.AnimRectExp := Bounds(x, y, w, h);
    RecreateMainBitmap(w, h);
    Exit;
  end;

  FAutoHider.BeforeBound := Bounds(x, y, w, h);
  RecreateMainBitmap(w, h);

  if (AutoHide and FAutoHider.Hidden)
  then r := FAutoHider.AfterBound
  else r := FAutoHider.BeforeBound;

  MoveWindow(Handle, r.Left, r.Top, r.Width, r.Height, False);
  ApplyDockRegion(r.Width, r.Height);
  UpdateWindow(r);
end;

procedure TLinkbarWcl.QueryHideEvent(Sender: TObject; AEnabled: boolean);
begin
  FConfig.AutoHide := AEnabled;
end;

procedure TLinkbarWcl.UpdateBackgroundColor;
var lookmode: TLookMode;
begin
  lookmode.Color := FConfig.Look;
  lookmode.Transparency := FConfig.TransparencyMode;
  ThemeGetTaskbarColor(FSysBackgroundColor, lookmode);
end;

function TLinkbarWcl.GetBackgroundColor: Cardinal;
begin
  if (FConfig.UseBkgndColor)
  then Result := FConfig.BackgroundColor
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
  Items.Sizes.ZoomOffset := ZoomRoom div 2;
  Items.Sizes.Reserved := FSysWidgets.ReservedLength(IsVertical(Align));
  Items.Sizes.OnlyPinned := IsCollapsed;
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
    LM_TASKBARMODE:
      begin
        ApplyTaskbarMode;
        Exit;
      end;
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
        FAutoHider.CanAutoHide := False;
        FAutoHider.Show;
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
        FAutoHider.CanAutoHide := not Assigned(FrmProperties);
        FAutoHider.Hide;
        Exit;
      end;
    { Display stste changed (count/size/rotate) }
    WM_DISPLAYCHANGE:
      begin
        inherited;
        Msg.Result := 0;
        if not FCreated then Exit;
        // force update Screen
        FConfig.MonitorNum := Self.Monitor.MonitorNum; // or Screen.MonitorFromWindow(0, mdNull);
        oAppBar.MonitorNum := FConfig.MonitorNum;
        oAppBar.AppBarPosChanged;
        Exit;
      end;
    { Delayed auto show (timer) }
    WM_MOUSEACTIVATE:
      begin
        // remember the window in front before the bar gets activated
        FForegroundAtMouseDown := GetForegroundWindow;
        if not TFullscreenWatcher.IsOurWindow(FForegroundAtMouseDown) and not TFullscreenWatcher.IsShellUiWindow(FForegroundAtMouseDown)
        then FFullscreen.LastForeignWnd := FForegroundAtMouseDown;
      end;
    WM_MOUSEWHEEL:
      // Ctrl + mouse wheel: next / previous profile
      if (GetKeyState(VK_CONTROL) < 0)
      then begin
        if (SmallInt(Msg.WParamHi) < 0)
        then FProfileMenu.Cycle(1)
        else FProfileMenu.Cycle(-1);
        Msg.Result := 0;
        Exit;
      end;
    WM_TIMER:
      begin
        case Msg.WParam of
          TIMER_AUTO_SHOW:
            begin
              KillTimer(Handle, TIMER_AUTO_SHOW);
              if Assigned(FAutoHider)
              then FAutoHider.Show;
              Exit;
            end;
          TIMER_AUTO_HIDE:
            begin
              KillTimer(Handle, TIMER_AUTO_HIDE);
              if Assigned(FAutoHider)
              then FAutoHider.Hide;
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
              if Assigned(FFullscreen)
              then FFullscreen.Check;
              Exit;
            end;
          TIMER_AUTOCOLLAPSE:
            begin
              if Assigned(FCollapse)
              then FCollapse.AutoTick;
              Exit;
            end;
          TIMER_COLLAPSE_ANIM:
            begin
              if Assigned(FCollapse)
              then FCollapse.AnimStep;
              Exit;
            end;
          TIMER_SAVE_RETRY:
            begin
              KillTimer(Handle, TIMER_SAVE_RETRY);
              if Assigned(FSaveQueue)
              then FSaveQueue.Retry;
              Exit;
            end;
          TIMER_SAVE_NOTICE:
            begin
              KillTimer(Handle, TIMER_SAVE_NOTICE);
              ToolTip.Cancel;
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
        FAutoHider.CanAutoHide := not Focused;
        FAutoHider.Hide;
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
     //and (FConfig.AutoShowMode = smHotkey)
  then begin
    if (FAutoHider.Hidden)
    then begin
      FPrevForegroundWnd := SetForegroundWindowInternal(Handle);
      FAutoHider.CanAutoHide := False;
      FAutoHider.Show;
    end
    else begin
      //SetForegroundWindow(FPrevForegroundWnd);
      // Linkbar will be hidden when it loses Focus
      //FAutoHider.Hide;
    end;
    Exit;
  end;

  inherited;
end;

procedure TLinkbarWcl.UpdateBitBuckets;
begin
  Items.BitBucketUpdateIcon;
  if FAutoHider.Hidden
  then RecreateMainBitmap(FAutoHider.BeforeBound.Width, FAutoHider.BeforeBound.Height)
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
  FConfig.LockLinkbar := not FConfig.LockLinkbar;
  TSettingsFile.Write(FSettingsFileName, INI_LOCK_BAR, FConfig.LockLinkbar);
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

{ New empty group: sub-folder "<name>.group". The folder watcher adds it to the bar }
procedure TLinkbarWcl.imNewGroupClick(Sender: TObject);
begin
  FCommands.NewGroup;
end;

procedure TLinkbarWcl.imOpenWorkdirClick(Sender: TObject);
begin
  OpenDirectoryByName(WorkDir);
end;

procedure TLinkbarWcl.imRemoveBarClick(Sender: TObject);
begin
  FCommands.RemoveBar;
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

function TLinkbarWcl.ScaleValue(const X: Integer): Integer;
begin
  Result := ScaleDimension(X);
end;

function TLinkbarWcl.BarButtonSize: TSize;
begin
  Result := FButtonSize;
end;

function TLinkbarWcl.ZoomExtra: Integer;
begin
  Result := ZoomRoom;
end;

function TLinkbarWcl.BarIsVertical: Boolean;
begin
  Result := IsVertical(Align);
end;

function TLinkbarWcl.BarIsCollapsed: Boolean;
begin
  Result := IsCollapsed;
end;

procedure TLinkbarWcl.BarUpdateSize;
begin
  UpdateWindowSize;
end;

procedure TLinkbarWcl.BarStartTimer(const AId: UINT; const AMs: Cardinal);
begin
  SetTimer(Handle, AId, AMs, nil);
end;

procedure TLinkbarWcl.BarStopTimer(const AId: UINT);
begin
  KillTimer(Handle, AId);
end;

procedure TLinkbarWcl.BarDismissPopups;
begin
  CloseThumbs;
  ToolTip.Cancel;
end;

procedure TLinkbarWcl.BarSetAutoHideLock(const ALock: Boolean);
begin
  FAutoHider.Locked := ALock;
end;

procedure TLinkbarWcl.BarRelayout;
begin
  oAppBar.AppBarPosChanged;
end;

function TLinkbarWcl.BarCanAnimate: Boolean;
begin
  Result := IsDock and Assigned(oAppBar) and (not FAutoHider.Hidden) and IsWindowVisible(Handle);
end;

function TLinkbarWcl.BarCollapsedLength(const AVertical: Boolean): Integer;
begin
  Result := ItemsMargin + PinnedLength(AVertical) + FSysWidgets.ReservedLength(AVertical);
end;

procedure TLinkbarWcl.BarShowFrame(const ARect: TRect);
var
  pt1, pt2: TPoint;
  sz: TSize;
begin
  if IsVertical(Align)
  then pt2 := Point(0, BitmapPanel.Height - ARect.Height)
  else pt2 := Point(BitmapPanel.Width - ARect.Width, 0);
  pt1 := ARect.TopLeft;
  sz := TSize.Create(ARect.Width, ARect.Height);
  UpdateLayeredWindow(Handle, 0, @pt1, @sz, BitmapPanel.Dc, @pt2, 0, @bf, ULW_ALPHA);
end;

function TLinkbarWcl.BarIsBusy: Boolean;
var
  pt: TPoint;
begin
  GetCursorPos(pt);
  Result := FAutoHider.Hidden or FFullscreen.HiddenByFullscreen
         or FAutoHider.Locked or FLockHotIndex or FMouseLeftDown or FDock.Sliding
         or PtInRect(BoundsRect, pt);
end;

function TLinkbarWcl.BarHasCollapseButton: Boolean;
begin
  Result := FSysWidgets.Enabled;
end;

function TLinkbarWcl.BarHandleAllocated: Boolean;
begin
  Result := HandleAllocated;
end;

function TLinkbarWcl.BarHandle: HWND;
begin
  Result := Handle;
end;

function TLinkbarWcl.BarIsTaskbarIcon: Boolean;
begin
  Result := IsTaskbarIcon;
end;

function TLinkbarWcl.GetShowSysWidgets: Boolean;
begin
  Result := FSysWidgets.Enabled;
end;

function TLinkbarWcl.GetShowCpuTemp: Boolean;
begin
  Result := FSysWidgets.TempEnabled;
end;

procedure TLinkbarWcl.SetShowCpuTemp(AValue: Boolean);
begin
  FSysWidgets.TempEnabled := AValue;  // lays the bar out again if the cells change
end;

{ The temperature cell appeared or went away: the end of the bar changes length }
procedure TLinkbarWcl.SysWidgetsCellsChanged(Sender: TObject);
begin
  FCollapse.FinishAnim;
  if Assigned(oAppBar)
  then oAppBar.AppBarPosChanged
  else UpdateWindowSize;
end;

function TLinkbarWcl.BarAutoHideEnabled: Boolean;
begin
  Result := AutoHide;
end;

function TLinkbarWcl.BarAutoShowDelay: Integer;
begin
  Result := FConfig.AutoShowDelay;
end;

procedure TLinkbarWcl.BarClearHot;
begin
  HotIndex := ITEM_NONE;
end;

procedure TLinkbarWcl.BarPresent(const ABounds: TRect);
begin
  UpdateWindow(ABounds);
end;

procedure TLinkbarWcl.BarEnableContextMenu(const AEnabled: Boolean);
begin
  if AEnabled
  then Self.OnContextPopup := FormContextPopup
  else Self.OnContextPopup := nil;
end;

procedure TLinkbarWcl.FormMouseEnter(Sender: TObject);
begin
  FCollapse.CancelAuto;
  if AutoHide
     and FAutoHider.Hidden
     and (FConfig.AutoShowMode = EAutoShowModeMouseHover)
  then FAutoHider.DelayedShow;
end;

procedure TLinkbarWcl.FormMouseLeave(Sender: TObject);
begin
  FCollapse.ArmAuto;
  HotIndex := -1;
  if ZoomEnabled and (FZoom.Cursor >= 0)
  then begin
    FZoom.Cursor := -1;
    RedrawZoom;
  end;
  if (FConfig.AutoShowMode = EAutoShowModeMouseHover) or FAutoHider.CanAutoHide
  then FAutoHider.DelayedHide(TIMER_AUTO_HIDE_DELAY);
end;

////////////////////////////////////////////////////////////////////////////////
// Drag&Drop
////////////////////////////////////////////////////////////////////////////////

procedure TLinkbarWcl.SetDropPosition(AValue: TPoint);
begin
  if Assigned(FDropTarget)
  then FDropTarget.Update(AValue);
end;

function TLinkbarWcl.BarItemAt(const APt: TPoint): Integer;
begin
  Result := ItemIndexByPoint(APt);
end;

function TLinkbarWcl.BarDraggingItem: Boolean;
begin
  Result := FDragingItem;
end;

function TLinkbarWcl.BarDragIndex: Integer;
begin
  Result := FDragIndex;
end;

function TLinkbarWcl.BarPanelBitmap: THBitmap;
begin
  Result := BitmapPanel;
end;

function TLinkbarWcl.BarWorkDirPidl: PItemIDList;
begin
  Result := WorkDirPidl;
end;

procedure TLinkbarWcl.BarPaintDropHighlight(const AIndex: Integer; const ARect: TRect);
begin
  DrawBackground(BitmapPanel, ARect);
  ThemeDrawHover(BitmapPanel, Align, ARect);
  DrawItem(BitmapPanel, AIndex, False, False, False);
end;

procedure TLinkbarWcl.BarRefresh;
begin
  UpdateWindow;
end;

procedure TLinkbarWcl.DoDragEnter(const pt: TPoint);
begin
  if AutoHide
     and FAutoHider.Hidden
  then begin
    FAutoHider.CanAutoHide := False;
    FAutoHider.Show;
  end;
end;

procedure TLinkbarWcl.DoDragOver(const pt: TPoint; var ppidl: PItemIDList);
begin
  if AutoHide
     and FAutoHider.Hidden
  then Exit;
  SetDropPosition(pt);
  ppidl := FDropTarget.Pidl;
end;

procedure TLinkbarWcl.DoDragLeave;
begin
  SetDropPosition( Point(-1, -1) );
  if AutoHide and not Active
  then begin
    FAutoHider.CanAutoHide := True;
    SetTimer(Handle, TIMER_AUTO_HIDE, TIMER_AUTO_HIDE_DELAY, nil); // FAutoHider.Hide;
  end;
end;

procedure TLinkbarWcl.DoDrop(const pt: TPoint);
begin
  if AutoHide and not Active
  then begin
    FAutoHider.CanAutoHide := True;
  end;

  if FDragingItem
  then begin
    // Dropped on the center of a group: move the item (shortcut, action...) inside the group folder.
    // The shell does not do it: drops that start in the bar itself are not forwarded to the target.
    if (FDropTarget.Part = 0)
       and IsItemIndex(FDragIndex)
       and IsItemIndex(FDropTarget.Position)
       and (FDropTarget.Position <> FDragIndex)
       and (Items[FDropTarget.Position] is TItemGroup)
       and (not Items.IsSeparator(Items[FDragIndex]))
    then begin
      var srcFile := ExcludeTrailingPathDelimiter(Items[FDragIndex].FileName);
      var dstFile := IncludeTrailingPathDelimiter(Items[FDropTarget.Position].FileName) + ExtractFileName(srcFile);
      if not (FileExists(dstFile) or DirectoryExists(dstFile))
      then begin
        if MoveFile(PChar(srcFile), PChar(dstFile))
        then begin
          // Reload the group icon (mini icons of its members), same as GroupChanged
          Items[FDropTarget.Position].NeedLoad := True;
          tmrUpdate.Enabled := False;
          tmrUpdate.Enabled := True;
        end;
      end;
    end;

    if FDropTarget.Part <> 0 then
    begin
      SortAlphabetically := False;
      if (FDropTarget.Position = ITEM_NONE)
      then begin
        if (Items.Count > 0)
           and ((Items.First.Rect.TopLeft.X < pt.X) or (Items.First.Rect.TopLeft.Y < pt.Y))
        then Items.Move(FDragIndex, 0)
        else Items.Move(FDragIndex, Items.Count-1);
      end
      else begin
        if (FDropTarget.Position <= FDragIndex)
        then Items.Move(FDragIndex, FDropTarget.Position)
        else Items.Move(FDragIndex, FDropTarget.Position-1);
      end;
    end;
    Items.PinnedToEnd;
    SetDropPosition( Point(-1, -1) );
    SaveLinks;
    UpdateWindowSize;
  end
  else tmrUpdate.Enabled := True;
end;

procedure TLinkbarWcl.QueryDragImage(out ABitmap: THBitmap; out AOffset: TPoint);
var ItemRect: TRect;
    bm: Winapi.Windows.TBitmap;
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

    ABitmap := TBarDropTarget.CreateExternalImage(FExtDragIcon, FExtDragIconSize);
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

procedure TLinkbarWcl.DirWatchChange(const Sender: TObject; const AAction: TWatchAction; const AFileName: string);
begin
  inherited;
  if Assigned(FLinkList)
  then FLinkList.FolderChanged(AAction, AFileName);
end;

procedure TLinkbarWcl.tmrUpdateTimer(Sender: TObject);
begin
  if Assigned(FLinkList)
  then FLinkList.RescanTick;
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
     or (AValue = FConfig.EnableAeroGlass)
  then Exit;

  FConfig.EnableAeroGlass := AValue;
  GlobalAeroGlassEnabled := FConfig.EnableAeroGlass;
  ThemeSetWindowAttribute78(Handle);
  UpdateBlur;
end;

procedure TLinkbarWcl.SetTransparencyMode(AValue: TTransparencyMode);
begin
  if (not IsWindows10)
     //or (AValue = FConfig.TransparencyMode)
  then Exit;
  FConfig.TransparencyMode := AValue;
  UpdateBackgroundColor;
  ApplyWindowAccent;
end;

procedure TLinkbarWcl.SetLook(AValue: TLook);
begin
  if (not IsWindows10)
     //or (AValue = FConfig.TransparencyMode)
  then Exit;

  GlobalLook := AValue;

  BitmapButton.Clear;
  ThemeDrawButton(BitmapButton, BitmapButton.Bound, False);

  FConfig.Look := AValue;
  UpdateBackgroundColor;
  ApplyWindowAccent;
end;

procedure TLinkbarWcl.SetModernStyle(AValue: Boolean);
begin
  if (AValue = FConfig.ModernStyle)
  then Exit;

  FConfig.ModernStyle := AValue;
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
begin
  if (not Assigned(FRunning)) or FAutoHider.Hidden or IsDragDrop or FMouseDragLinkbar or FMouseLeftDown
  then Exit;

  if FRunning.Refresh(Items)
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

{ ---------- Live thumbnails ---------- }

procedure TLinkbarWcl.ThumbsHotChanged;
begin
  if Assigned(FThumbs)
  then FThumbs.HotChanged;
end;

procedure TLinkbarWcl.ShowThumbs(const AIndex: Integer);
begin
  if Assigned(FThumbs)
  then FThumbs.Show(AIndex);
end;

procedure TLinkbarWcl.CloseThumbs;
begin
  if Assigned(FThumbs)
  then FThumbs.Close;
end;

function TLinkbarWcl.BarIsItem(const AIndex: Integer): Boolean;
begin
  Result := IsItemIndex(AIndex);
end;

function TLinkbarWcl.BarItemRunning(const AIndex: Integer): Boolean;
begin
  Result := Items[AIndex].Running;
end;

function TLinkbarWcl.BarItemTarget(const AIndex: Integer): string;
begin
  Result := Items[AIndex].TargetPath;
end;

function TLinkbarWcl.BarItemRect(const AIndex: Integer): TRect;
begin
  Result := Items[AIndex].Rect;
end;

function TLinkbarWcl.BarHotIndex: Integer;
begin
  Result := FHotIndex;
end;

function TLinkbarWcl.BarThumbsBlocked: Boolean;
begin
  Result := FMouseLeftDown or IsDragDrop or FLockHotIndex or FAutoHider.Hidden;
end;

function TLinkbarWcl.BarOwner: TComponent;
begin
  Result := Self;
end;

function TLinkbarWcl.BarAlign: TPanelAlign;
begin
  Result := Align;
end;

function TLinkbarWcl.BarIconSize: Integer;
begin
  Result := FConfig.IconSize;
end;

procedure TLinkbarWcl.BarCancelTooltip;
begin
  ToolTip.Cancel;
end;

{ ---------- Dock mode and magnification ---------- }

function TLinkbarWcl.IsDock: Boolean;
begin
  Result := (FConfig.BarStyle = BAR_STYLE_DOCK);
end;

function TLinkbarWcl.ZoomEnabled: Boolean;
begin
  Result := Assigned(FZoom) and FZoom.Enabled;
end;

{ Extra thickness so magnified icons fit in the bar }
function TLinkbarWcl.ZoomRoom: Integer;
begin
  if Assigned(FZoom)
  then Result := FZoom.Room
  else Result := 0;
end;

function TLinkbarWcl.ZoomIconSizeValue: Integer;
begin
  if Assigned(FZoom)
  then Result := FZoom.IconSizeValue
  else Result := 0;
end;

{ Dock: free space at both ends so magnified end icons are not cut }
function TLinkbarWcl.DockPad: Integer;
begin
  if Assigned(FDock)
  then Result := FDock.Pad
  else Result := 0;
end;

function TLinkbarWcl.ItemsMargin: Integer;
begin
  Result := FGripSize + DockPad;
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
  if IsDock or (FAutoHider.Hidden and FConfig.AutoHideTransparency)
  then ThemeSetWindowAccentPolicy10(Handle, tmDisabled, 0)
  else ThemeSetWindowAccentPolicy10(Handle, FConfig.TransparencyMode, BackgroundColor);

  // dock background uses the background color: repaint
  if IsDock and Assigned(BitmapPanel)
     and (BitmapPanel.Width > 0) and (BitmapPanel.Height > 0)
  then begin
    RecreateMainBitmap(BitmapPanel.Width, BitmapPanel.Height);
    UpdateWindow;
  end;
end;

function TLinkbarWcl.BarIsDock: Boolean;
begin
  Result := IsDock;
end;

function TLinkbarWcl.BarExpandedLength(const AVertical: Boolean): Integer;
begin
  Result := Items.LineWidth + 2 * ItemsMargin + FSysWidgets.ReservedLength(AVertical);
end;

function TLinkbarWcl.BarBackgroundColor: Cardinal;
begin
  Result := BackgroundColor;
end;

function TLinkbarWcl.BarOpaque: Boolean;
begin
  Result := (FConfig.TransparencyMode = tmOpaque);
end;

function TLinkbarWcl.BarWorkArea: TRect;
begin
  Result := Screen.Monitors[EnsureRange(FConfig.MonitorNum, 0, Screen.MonitorCount - 1)].WorkareaRect;
end;

function TLinkbarWcl.BarBounds: TRect;
begin
  Result := BoundsRect;
end;

procedure TLinkbarWcl.BarMoveTo(const AX, AY: Integer);
begin
  SetWindowPos(Handle, 0, AX, AY, 0, 0, SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE);
  FAutoHider.BeforeBound := Bounds(AX, AY, Width, Height);
end;

procedure TLinkbarWcl.SetBarStyle(AValue: Integer);
begin
  AValue := EnsureRange(AValue, BAR_STYLE_NORMAL, BAR_STYLE_TASKBAR);
  if (AValue = FConfig.BarStyle)
  then Exit;
  FConfig.BarStyle := AValue;
  FCollapse.FinishAnim;

  if (IsDock or IsTaskbarIcon) and AutoHide
  then AutoHide := False;

  ApplyWindowAccent;
  if Assigned(oAppBar)
  then begin
    oAppBar.Floating := IsDock or IsTaskbarIcon;
    if not IsTaskbarIcon
    then oAppBar.AppBarPosChanged;
  end;
  SetWindowRgn(Handle, 0, True);
  ApplyTaskbarMode;
end;

{ ---------- "taskbar icon" mode ---------- }

function TLinkbarWcl.IsTaskbarIcon: Boolean;
begin
  Result := (FConfig.BarStyle = BAR_STYLE_TASKBAR);
end;

{ Show the bar or only its taskbar button, depending on the style }
procedure TLinkbarWcl.ApplyTaskbarMode;
begin
  if Assigned(FLauncher)
  then FLauncher.Apply(IsTaskbarIcon);
end;

procedure TLinkbarWcl.UpdateTaskbarIcon;
begin
  if Assigned(FLauncher)
  then FLauncher.UpdateIcon;
end;

procedure TLinkbarWcl.SetTaskbarIcon(const AValue: string);
begin
  FLauncher.ChangeIcon(AValue);
end;

function TLinkbarWcl.GetTaskbarIcon: string;
begin
  Result := FLauncher.IconSpec;
end;

function TLinkbarWcl.BarPanelName: string;
begin
  Result := PanelName;
end;

function TLinkbarWcl.BarSettingsFile: string;
begin
  Result := FSettingsFileName;
end;

function TLinkbarWcl.BarWorkDir: string;
begin
  Result := WorkDir;
end;

procedure TLinkbarWcl.BarHideForLauncher;
begin
  CloseThumbs;
  ToolTip.Cancel;
  ShowWindow(Handle, SW_HIDE);
end;

procedure TLinkbarWcl.BarRestoreFromLauncher;
begin
  if not IsWindowVisible(Handle) and not FFullscreen.HiddenByFullscreen
  then begin
    ShowWindow(Handle, SW_SHOWNA);
    oAppBar.AppBarPosChanged;
  end;
end;

function TLinkbarWcl.BarActionTarget: HWND;
begin
  Result := GetForegroundWindow;
  if TFullscreenWatcher.IsOurWindow(Result) or TFullscreenWatcher.IsShellUiWindow(Result)
  then Result := FFullscreen.LastForeignWnd;
  if TFullscreenWatcher.IsOurWindow(Result)
  then Result := 0;
end;

function TLinkbarWcl.BarSysStatsEnabled: Boolean;
begin
  Result := FSysWidgets.Enabled;
end;

procedure TLinkbarWcl.BarSysStats(out ACpu, ARam: Integer);
begin
  // the widgets timer keeps sampling while the bar is hidden
  ACpu := FSysWidgets.CpuLoad;
  ARam := FSysWidgets.RamLoad;
end;

{ Extra items in the popup menu: settings and back to a normal bar }
procedure TLinkbarWcl.BarFillLauncherMenu(AMenu: TPopupMenu);
var mi: TMenuItem;
begin
  mi := TMenuItem.Create(AMenu);
  mi.Caption := L10NFind('Menu.ShowAsBar', 'Show as a bar');
  mi.OnClick := LauncherShowAsBar;
  AMenu.Items.Add(mi);
  mi := TMenuItem.Create(AMenu);
  mi.Caption := imProperties.Caption;
  mi.OnClick := imPropertiesClick;
  AMenu.Items.Add(mi);
end;

procedure TLinkbarWcl.BarCloseRequested(Sender: TObject);
begin
  imCloseClick(Sender);
end;

procedure TLinkbarWcl.BarActivate(const AWnd: HWND);
begin
  SetForegroundWindowInternal(AWnd);
end;

procedure TLinkbarWcl.LauncherShowAsBar(Sender: TObject);
begin
  BarStyle := BAR_STYLE_NORMAL;
  SaveSettings;
end;

procedure TLinkbarWcl.SetZoomPercent(AValue: Integer);
begin
  if not FZoom.ChangePercent(AValue)
  then Exit;
  // the bar thickness changes
  if Assigned(oAppBar)
  then oAppBar.AppBarPosChanged
  else UpdateWindowSize;
end;

function TLinkbarWcl.GetZoomPercent: Integer;
begin
  Result := FZoom.Percent;
end;

function TLinkbarWcl.BarIconOffset: TPoint;
begin
  Result := FIconOffset;
end;

function TLinkbarWcl.BarSeparatorStyle: TSeparatorStyle;
begin
  Result := FConfig.SeparatorStyle;
end;

procedure TLinkbarWcl.BarDrawItemMarks(const ABitmap: THBitmap; const AItem: TItemBase; const ARect: TRect);
begin
  FRunning.DrawMark(ABitmap, AItem, ARect);
  FPinned.DrawMark(ABitmap, AItem, ARect);
end;

procedure TLinkbarWcl.RedrawZoom;
begin
  if FAutoHider.Hidden or IsDragDrop
     or (BitmapPanel.Width = 0) or (BitmapPanel.Height = 0)
  then Exit;
  RecreateMainBitmap(BitmapPanel.Width, BitmapPanel.Height);
  UpdateWindow;
end;

{ ---------- CPU / RAM widgets ---------- }

procedure TLinkbarWcl.SetShowSysWidgets(AValue: Boolean);
begin
  if (AValue = FSysWidgets.Enabled)
  then Exit;
  FSysWidgets.Enabled := AValue;
  FCollapse.FinishAnim;

  if FSysWidgets.Enabled
  then begin
    FSysWidgets.Sample;
    SetTimer(Handle, TIMER_SYS_WIDGETS, 1000, nil);
  end
  else begin
    KillTimer(Handle, TIMER_SYS_WIDGETS);
    // No ">>" button any more: the bar cannot stay collapsed
    FCollapse.ManualCollapsed := False;
  end;

  // Re-layout: the end of the bar is reserved for the widgets
  if Assigned(oAppBar)
  then oAppBar.AppBarPosChanged
  else UpdateWindowSize;
end;

{ Timer: sample and redraw only the widget area }
procedure TLinkbarWcl.RefreshSysWidgets;
var r: TRect;
begin
  FSysWidgets.Sample;
  if FAutoHider.Hidden or IsDragDrop or FMouseDragLinkbar
     or (BitmapPanel.Width = 0) or (BitmapPanel.Height = 0)
  then Exit;
  r := FSysWidgets.WidgetRect(BitmapPanel.Width, BitmapPanel.Height);
  if r.IsEmpty
  then Exit;
  DrawBackground(BitmapPanel, r);
  FSysWidgets.Draw(BitmapPanel, BitmapPanel.Width, BitmapPanel.Height);
  UpdateWindow;
end;

procedure TLinkbarWcl.SetUseBkgndColor(AValue: Boolean);
begin
  if (AValue = FConfig.UseBkgndColor)
  then Exit;
  FConfig.UseBkgndColor := AValue;
  UpdateBackgroundColor;
end;

end.
