{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2021 Asaq               }
{*******************************************************}

unit Linkbar.SettingsForm;

{$i linkbar.inc}

interface

uses
  System.SysUtils, System.Classes,
  Winapi.Windows, Winapi.Messages,
  Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Buttons, Vcl.Controls, Vcl.ComCtrls, Vcl.Menus,
  NewSpin, mUnit, ColorPicker, HotKey;

type
  TFrmProperties = class(TForm)
    pgc1: TPageControl;
    tsAbout: TTabSheet;
    lblScreenEdge: TLabel;
    lblIconSize: TLabel;
    lblMargin: TLabel;
    lblOrder: TLabel;
    lblTextWidthIdent: TLabel;
    lblTextPosition: TLabel;
    cbbTextLayout: TComboBox;
    chbAutoHide: TCheckBox;
    lblVer: TLabel;
    lblEmail: TLabel;
    linkEmail: TLinkLabel;
    linkWeb: TLinkLabel;
    lblWeb: TLabel;
    lblSystemInfo: TLabel;
    chbAutoHideTransparency: TCheckBox;
    cbbScreenPosition: TComboBox;
    pnlDummy1: TPanel;
    pnlDummy2: TPanel;
    pnlDummy3: TPanel;
    pnlDummy7: TPanel;
    pnlDummy4: TPanel;
    pnlDummy6: TPanel;
    cbbItemOrder: TComboBox;
    btnApply: TButton;
    btnCancel: TButton;
    btnOk: TButton;
    nseIconSize: TnSpinEdit;
    nseMarginH: TnSpinEdit;
    nseMarginV: TnSpinEdit;
    nseTextWidth: TnSpinEdit;
    nseTextOffset: TnSpinEdit;
    lblSection3: TLabel;
    lblSection1: TLabel;
    pnlDummy22: TPanel;
    lblShow: TLabel;
    cbbAutoShowMode: TComboBox;
    pnlDummy21: TPanel;
    lbl2: TLabel;
    tsAdditionally: TTabSheet;
    lblLocalizer: TLabel;
    lblSysInfo: TLabel;
    pnlDelay: TPanel;
    lblDelay: TLabel;
    nseAutoShowDelay: TnSpinEdit;
    pnlDummy33: TPanel;
    btnBkgndColorEdit: TSpeedButton;
    pnlDummy8: TPanel;
    edtBkgndColor: TEdit;
    chbUseBkgndColor: TCheckBox;
    chbTextColor: TCheckBox;
    bvlSpacer2: TBevel;
    bvlSpacer3: TBevel;
    pnlDummy9: TPanel;
    lblTextGlowSize: TLabel;
    nseGlowSize: TnSpinEdit;
    clbTextColor: TColorBox;
    pnlLightStyle: TPanel;
    chbLightStyle: TCheckBox;
    lblSectionWindows: TLabel;
    chbAeroGlass: TCheckBox;
    pnlHotkey: TPanel;
    lblHotKey: TLabel;
    pnlJumplistShowMode: TPanel;
    lblJumplistShowMode: TLabel;
    cbbJumplistShowMode: TComboBox;
    lblSectionJumplist: TLabel;
    pnlDummy10: TPanel;
    chbStayOnTop: TCheckBox;
    pnlJumplistRecentMax: TPanel;
    lblJumplistRecentMax: TLabel;
    nseJumplistRecentMax: TnSpinEdit;
    pnlDummy31: TPanel;
    Bevel1: TBevel;
    pnlColorMode: TPanel;
    lblColorMode: TLabel;
    cbbColorMode: TComboBox;
    pnlCornerGapWidth: TPanel;
    lblCornerGapWidth: TLabel;
    Bevel2: TBevel;
    nseCorner1GapWidth: TnSpinEdit;
    nseCorner2GapWidth: TnSpinEdit;
    lblGithub: TLabel;
    linkGithub: TLinkLabel;
    lblOrigAuthor: TLabel;
    lblModBy: TLabel;
    lblFork: TLabel;
    linkFork: TLinkLabel;
    pnlTransparencyMode: TPanel;
    lblTransparencyMode: TLabel;
    cbbTransparencyMode: TComboBox;
    pnlDummy5: TPanel;
    lblItemsAlign: TLabel;
    cbbItemsAlign: TComboBox;
    tsPanel: TTabSheet;
    tsItems: TTabSheet;
    lblShortcuts: TLabel;
    tsAutoHide: TTabSheet;
    lblSeperators: TLabel;
    pnlSeparator1: TPanel;
    lblSeparatorWidth: TLabel;
    nseSeparatorWidth: TnSpinEdit;
    pnlSeparator2: TPanel;
    lblSeparatorStyle: TLabel;
    cbbSeparatorStyle: TComboBox;
    chbTooltipShow: TCheckBox;
    pnlTooltipShow: TPanel;
    pnlModernStyle: TPanel;
    chbModernStyle: TCheckBox;
    pnlOpacity: TPanel;
    lblOpacity: TLabel;
    lblOpacityValue: TLabel;
    trbOpacity: TTrackBar;
    pnlSysWidgets: TPanel;
    chbSysWidgets: TCheckBox;
    pnlAutoStart: TPanel;
    chbAutoStart: TCheckBox;
    pnlBarStyle: TPanel;
    lblBarStyle: TLabel;
    cbbBarStyle: TComboBox;
    pnlZoom: TPanel;
    lblZoom: TLabel;
    lblZoomValue: TLabel;
    trbZoom: TTrackBar;
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure linkEmailLinkClick(Sender: TObject; const Link: string;
      LinkType: TSysLinkType);
    procedure linkWebLinkClick(Sender: TObject; const Link: string;
      LinkType: TSysLinkType);
    procedure DialogButtonClick(Sender: TObject);
    procedure Changed(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnCancelClick(Sender: TObject);
    procedure btnBgColorClick(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure edtBkgndColorKeyPress(Sender: TObject; var Key: Char);
    procedure edtBkgndColorChange(Sender: TObject);
    procedure imCopyClick(Sender: TObject);
    procedure trbOpacityChange(Sender: TObject);
    procedure trbZoomChange(Sender: TObject);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
  private
    FLinkbar: TLinkbarWcl;
    FColorPicker: TfrmColorPicker;
    FBackgroundColor: Cardinal;
    FTextColor: Cardinal;
    edtHotKey: THotKeyEdit;
    FCanChanged: Boolean;
    FOpacityUpdating: Boolean;
    procedure SetBackgroundColor(AValue: Cardinal);
    procedure ApplyDarkStyle;
    procedure SyncOpacityFromColor;
    procedure PreviewBackground;
    procedure SetTextColor(AValue: Cardinal);
    function ScaleDimension(const X: Integer): Integer;
    procedure L10n;
  private
    RowHeight: Integer;
    RowOffset: Integer;
    procedure InitOffsetSize(const AControl, ARelativeControl: TControl);
    procedure InitSpinEdit(const AControl: TnSpinEdit; const AMin, AMax: Integer);
  public
    constructor Create(AOwner: TLinkbarWcl); reintroduce;
    property BackgroundColor: Cardinal read FBackgroundColor write SetBackgroundColor;
    property TextColor: Cardinal read FTextColor write SetTextColor;
  end;

var
  FrmProperties: TFrmProperties;

implementation

{$R *.dfm}

uses
  Math, Graphics, Vcl.Clipbrd, Vcl.Themes, System.Win.Registry, System.StrUtils,
  Linkbar.Consts, Linkbar.OS, Linkbar.Shell, Linkbar.Theme, Linkbar.L10n, Linkbar.Common;

const
  AUTOSTART_KEY   = 'Software\Microsoft\Windows\CurrentVersion\Run';
  AUTOSTART_VALUE = 'Linkbar';

{ Linkbar is registered to start with Windows (current user) }
function IsAutoStartEnabled: Boolean;
var reg: TRegistry;
begin
  Result := False;
  reg := TRegistry.Create(KEY_READ);
  try
    reg.RootKey := HKEY_CURRENT_USER;
    if reg.OpenKeyReadOnly(AUTOSTART_KEY)
    then Result := reg.ValueExists(AUTOSTART_VALUE);
  finally
    reg.Free;
  end;
end;

{ Running Linkbar.exe without parameters opens all saved bars }
procedure SetAutoStart(AEnable: Boolean);
var reg: TRegistry;
begin
  reg := TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    reg.RootKey := HKEY_CURRENT_USER;
    if reg.OpenKey(AUTOSTART_KEY, True)
    then begin
      if AEnable
      then reg.WriteString(AUTOSTART_VALUE, '"' + ParamStr(0) + '"')
      else if reg.ValueExists(AUTOSTART_VALUE)
      then reg.DeleteValue(AUTOSTART_VALUE);
    end;
  finally
    reg.Free;
  end;
end;

function TFrmProperties.ScaleDimension(const X: Integer): Integer;
begin
  Result := MulDiv(X, Self.PixelsPerInch, 96);
end;

procedure TFrmProperties.SpeedButton2Click(Sender: TObject);
begin
  nseIconSize.Value := StrToIntDef(TSpeedButton(Sender).Caption, nseIconSize.Value);
end;

procedure TFrmProperties.InitOffsetSize(const AControl, ARelativeControl: TControl);
begin
  AControl.Top := ARelativeControl.BoundsRect.Bottom + RowOffset;
  AControl.Height := RowHeight;
end;

procedure TFrmProperties.InitSpinEdit(const AControl: TnSpinEdit; const AMin, AMax: Integer);
begin
  AControl.MinValue := AMin;
  AControl.MaxValue := AMax;
end;

{ Prevent window resizing }
procedure TFrmProperties.WMNCHitTest(var Message: TWMNCHitTest);
begin
  inherited;
  PreventSizing(Message.Result);
end;

procedure TFrmProperties.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.ExStyle := Params.ExStyle or WS_EX_APPWINDOW;
end;

constructor TFrmProperties.Create(AOwner: TLinkbarWcl);
var maxlabelwidth, ctrlwidth, y1: integer;
    VO1, VO2, VO3: Integer;
begin
  FCanChanged := False;

  inherited Create(AOwner);

  FLinkbar := AOwner;
  Font.Name := Screen.MenuFont.Name;

  // Create editors
  edtHotKey := THotKeyEdit.Create(pnlHotkey);
  edtHotKey.Parent := pnlHotkey;
  edtHotKey.Align := alClient;
  edtHotKey.OnChange := Changed;
  FColorPicker := TfrmColorPicker.Create(Self);
  FColorPicker.Font := Font;

  L10n;

  ReduceSysMenu(Handle);

  VO1 := ScaleDimension(7);
  VO2 := ScaleDimension(9);
  VO3 := ScaleDimension(12);

  pgc1.ActivePageIndex := 0;

  maxlabelwidth := 0;
  maxlabelwidth := Max(maxlabelwidth, lblScreenEdge.Width);
  maxlabelwidth := Max(maxlabelwidth, lblIconSize.Width);
  maxlabelwidth := Max(maxlabelwidth, lblMargin.Width);
  maxlabelwidth := Max(maxlabelwidth, lblOrder.Width);
  maxlabelwidth := Max(maxlabelwidth, lblTextPosition.Width);
  maxlabelwidth := Max(maxlabelwidth, lblTextWidthIdent.Width);
  maxlabelwidth := Max(maxlabelwidth, lblCornerGapWidth.Width);
  maxlabelwidth := Max(maxlabelwidth, ScaleDimension(180));
  maxlabelwidth := maxlabelwidth + ScaleDimension(16);
  ctrlwidth := cbbScreenPosition.Width;

  GetTitleFont(lblSection1.Font);
  lblShortcuts.Font := lblSection1.Font;
  lblSection3.Font := lblSection1.Font;
  lblVer.Font := lblSection1.Font;

  RowHeight := cbbScreenPosition.BoundsRect.Bottom;
  RowOffset := ScaleDimension(7);

  { Page Panel }

  // Position on screen
  InitOffsetSize(pnlDummy1, lblSection1);
  // Item order
  InitOffsetSize(pnlDummy4, pnlDummy1);
  InitOffsetSize(pnlDummy5, pnlDummy4);
  // Color
  InitOffsetSize(pnlDummy33, pnlDummy5);
  // Opacity (Windows 10+ only)
  InitOffsetSize(pnlOpacity, pnlDummy33);
  pnlOpacity.Visible := IsWindows10;
  // Always on top
  if IsWindows10
  then InitOffsetSize(pnlDummy10, pnlOpacity)
  else InitOffsetSize(pnlDummy10, pnlDummy33);

  { OS-dependent options }
  //IsWindows7 := False; IsWindows8And8Dot1 := True; IsWindows10 := False;
  lblSectionWindows.Font := lblSection1.Font;
  lblSectionWindows.Top := pnlDummy10.BoundsRect.Bottom + VO1*2;
  // Windows 7
  pnlLightStyle.Visible := IsWindows7;
  pnlLightStyle.Top := lblSectionWindows.BoundsRect.Bottom + VO1;
  pnlLightStyle.Height := (pnlDummy1.Height * 3) div 2;
  // Windows 8/8.1
  chbAeroGlass.Visible := IsWindows8And8Dot1;
  chbAeroGlass.Top := lblSectionWindows.BoundsRect.Bottom + VO1;
  // Windows 10
  pnlColorMode.Visible := IsWindows10;
  InitOffsetSize(pnlColorMode, lblSectionWindows);
  pnlTransparencyMode.Visible := IsWindows10;
  InitOffsetSize(pnlTransparencyMode, pnlColorMode);
  pnlModernStyle.Visible := IsWindows10;
  InitOffsetSize(pnlModernStyle, pnlTransparencyMode);

  { Page Items }

  // Icon size
  InitOffsetSize(pnlDummy2, lblShortcuts);
  InitSpinEdit(nseIconSize, ICON_SIZE_MIN, ICON_SIZE_MAX);
  // Margins
  InitOffsetSize(pnlDummy3, pnlDummy2);
  InitSpinEdit(nseMarginH, MARGIN_MIN, MARGIN_MAX);
  InitSpinEdit(nseMarginV, MARGIN_MIN, MARGIN_MAX);
  // Text position
  InitOffsetSize(pnlDummy6, pnlDummy3);
  // Text width/offset
  InitOffsetSize(pnlDummy7, pnlDummy6);
  InitSpinEdit(nseTextWidth, TEXT_WIDTH_MIN, TEXT_WIDTH_MAX);
  InitSpinEdit(nseTextOffset, TEXT_OFFSET_MIN, TEXT_OFFSET_MAX);
  // Text color
  InitOffsetSize(pnlDummy8, pnlDummy7);
  clbTextColor.ItemHeight := ScaleDimension(16);
  // Text glow size
  InitOffsetSize(pnlDummy9, pnlDummy8);
  InitSpinEdit(nseGlowSize, GLOW_SIZE_MIN, GLOW_SIZE_MAX);

  InitOffsetSize(pnlTooltipShow, pnlDummy9);

  // Icon size
  lblSeperators.Font := lblSection1.Font;
  lblSeperators.Top := pnlTooltipShow.BoundsRect.Bottom + VO1*2;
  // Width
  InitOffsetSize(pnlSeparator1, lblSeperators);
  InitSpinEdit(nseSeparatorWidth, 2, 256);
  // Style
  InitOffsetSize(pnlSeparator2, pnlSeparator1);


  { Page AutoHide }

  InitOffsetSize(pnlDummy21, lblSection3);
  InitOffsetSize(pnlDummy22, pnlDummy21);
  InitOffsetSize(pnlDelay, pnlDummy22);

  InitOffsetSize(pnlCornerGapWidth, pnlDelay);
  InitSpinEdit(nseCorner1GapWidth, CORNER_GAP_WIDTH_MIN, CORNER_GAP_WIDTH_MAX);
  InitSpinEdit(nseCorner2GapWidth, CORNER_GAP_WIDTH_MIN, CORNER_GAP_WIDTH_MAX);

  InitOffsetSize(pnlHotkey, pnlCornerGapWidth);

  chbAutoHideTransparency.Top := pnlHotkey.BoundsRect.Bottom + VO3;

  { Page Additionally }

  lblSectionJumplist.Font := lblSection1.Font;
  InitOffsetSize(pnlJumplistShowMode, lblSectionJumplist);



  pnlJumplistRecentMax.Top := pnlJumplistShowMode.BoundsRect.Bottom + VO1;
  pnlJumplistRecentMax.Height := (pnlDummy1.Height * 3) div 2;
  nseJumplistRecentMax.Top := (pnlDummy21.Height - nseJumplistRecentMax.Height) div 2;

  InitSpinEdit(nseJumplistRecentMax, JUMPLIST_RECENTMAX_MIN, JUMPLIST_RECENTMAX_MAX);

  // CPU/RAM widgets
  InitOffsetSize(pnlSysWidgets, pnlJumplistRecentMax);
  // Start with Windows
  InitOffsetSize(pnlAutoStart, pnlSysWidgets);
  // Bar style (normal / dock) and magnification
  InitOffsetSize(pnlBarStyle, pnlAutoStart);
  InitOffsetSize(pnlZoom, pnlBarStyle);


  pgc1.Height := tsPanel.Top + pnlSeparator2.BoundsRect.Bottom + VO2 + tsPanel.Left;

  btnOk.Top := pgc1.BoundsRect.Bottom + ScaleDimension(8);
  btnCancel.Top := btnOk.Top;
  btnApply.Top := btnOk.Top;

  // Calc Client Width & Height
  ClientWidth := maxlabelwidth + ctrlwidth + (pnlDummy1.Left + tsPanel.Left + pgc1.Left) * 2;
  //if IsWindows7 then y1 := 5 else y1 := 8;
  y1 := 5;
  ClientHeight := btnOk.BoundsRect.Bottom + ScaleDimension(y1);

  linkWeb.Left := lblWeb.BoundsRect.Right + ScaleDimension(8);
  linkEmail.Left := lblEmail.BoundsRect.Right + ScaleDimension(8);
  linkGithub.Left := lblGithub.BoundsRect.Right + ScaleDimension(8);

  // Set values
  nseIconSize.Value := FLinkbar.IconSize;
  nseMarginH.Value := FLinkbar.ItemMargin.cx;
  nseMarginV.Value := FLinkbar.ItemMargin.cy;
  nseTextWidth.Value := FLinkbar.TextWidth;
  nseTextOffset.Value := FLinkbar.TextOffset;
  nseGlowSize.Value := FLinkbar.GlowSize;
  nseSeparatorWidth.Value := FLinkbar.SeparatorWidth;
  cbbSeparatorStyle.ItemIndex := Ord(FLinkbar.SeparatorStyle);
  chbTooltipShow.Checked := FLinkbar.TooltipShow;
  chbModernStyle.Checked := FLinkbar.ModernStyle;
  chbSysWidgets.Checked := FLinkbar.ShowSysWidgets;
  chbAutoStart.Checked := IsAutoStartEnabled;
  cbbBarStyle.ItemIndex := FLinkbar.BarStyle;
  trbZoom.Position := FLinkbar.ZoomPercent;
  trbZoomChange(nil);

  cbbScreenPosition.ItemIndex := Ord(FLinkbar.Align);
  cbbItemOrder.ItemIndex := Ord(FLinkbar.ItemOrder);
  cbbItemsAlign.ItemIndex := Ord(FLinkbar.Layout);
  cbbTextLayout.ItemIndex := Ord(FLinkbar.TextLayout);
  chbAutoHide.Checked := FLinkbar.AutoHide;
  chbAutoHideTransparency.Checked := FLinkbar.AutoHideTransparency;
  cbbAutoShowMode.ItemIndex := Ord(FLinkbar.AutoShowMode);
  nseAutoShowDelay.Value := FLinkbar.AutoShowDelay;
  chbLightStyle.Checked := FLinkbar.IsLightStyle;
  chbUseBkgndColor.Checked := FLinkbar.UseBkgndColor;
  chbTextColor.Checked := FLinkbar.UseTextColor;
  cbbJumplistShowMode.ItemIndex := Ord(FLinkbar.JumplistShowMode);
  nseJumplistRecentMax.Value := FLinkbar.JumplistRecentMax;
  chbStayOnTop.Checked := FLinkbar.StayOnTop;
  cbbColorMode.ItemIndex := Ord(FLinkbar.Look);
  cbbTransparencyMode.ItemIndex := Ord(FLinkbar.TransparencyMode);
  nseCorner1GapWidth.Value := FLinkbar.Corner1GapWidth;
  nseCorner2GapWidth.Value := FLinkbar.Corner2GapWidth;

  edtHotKey.HotkeyInfo := FLinkbar.HotkeyInfo;

  BackgroundColor := FLinkbar.BackgroundColor;
  TextColor := FLinkbar.TextColor;
  SyncOpacityFromColor;

  chbAeroGlass.Checked := FLinkbar.EnableAeroGlass;

  lblVer.Caption     := Format(lblVer.Caption, [VersionToString]);
  linkWeb.Caption    := '<a>' + URL_WEB + '</a>';
  linkEmail.Caption  := '<a>' + URL_EMAIL + '</a>';
  linkGithub.Caption := '<a>' + URL_GITHUB + '</a>';
  linkFork.Caption   := '<a>' + URL_FORK_GITHUB + '</a>';
  // Credits: original author is kept, modifications are credited separately
  lblOrigAuthor.Caption := L10NFind('Properties.OriginalAuthor', 'Original author') + ': ' + ORIGINAL_AUTHOR;
  lblModBy.Caption      := L10NFind('Properties.ModifiedBy', 'Modified by') + ': ' + MOD_AUTHOR;
  linkEmail.Left := linkGithub.Left;
  linkWeb.Left := linkGithub.Left;
  linkFork.Left := linkGithub.Left;

  lblSysInfo.Caption := SystemInfo;

  ApplyDarkStyle;

  FCanChanged := True;
  Changed(nil);
  btnApply.Enabled := False;
end;

{ True when Windows "Choose your default app mode" = Dark }
function SystemAppsUseDarkTheme: Boolean;
var reg: TRegistry;
begin
  Result := False;
  reg := TRegistry.Create(KEY_READ);
  try
    reg.RootKey := HKEY_CURRENT_USER;
    if reg.OpenKeyReadOnly('Software\Microsoft\Windows\CurrentVersion\Themes\Personalize')
       and reg.ValueExists('AppsUseLightTheme')
    then Result := (reg.ReadInteger('AppsUseLightTheme') = 0);
  finally
    reg.Free;
  end;
end;

{ Dark Settings window when Windows uses dark mode for apps.
  Uses a VCL style applied only to this form (per-form styling, Delphi 11+).
  The style must be embedded in the exe:
  Project > Options > Application > Appearance > check "Windows11 Modern Dark".
  If no dark style is embedded, nothing changes. }
procedure TFrmProperties.ApplyDarkStyle;
const
  DarkStyles: array[0..3] of string = (
    'Windows11 Modern Dark', 'Windows11 Polar Dark', 'Windows10 Dark', 'Windows10 SlateGray');
var
  wanted, available: string;
begin
  if not (IsWindows10 and SystemAppsUseDarkTheme)
  then Exit;

  for wanted in DarkStyles do
    for available in TStyleManager.StyleNames do
      if SameText(wanted, available)
      then begin
        StyleName := available;
        Exit;
      end;

  // Fallback: any embedded style with "Dark" in its name
  for available in TStyleManager.StyleNames do
    if ContainsText(available, 'Dark')
    then begin
      StyleName := available;
      Exit;
    end;
end;

procedure TFrmProperties.L10n;
begin
  // Pages
  L10nControl(tsPanel,                 'Properties.PagePanel');
  L10nControl(tsItems,                 'Properties.PageItems');
  L10nControl(tsAutoHide,              'Properties.PageAutoHide');
  L10nControl(tsAdditionally,          'Properties.PageAdditional');
  L10nControl(tsAbout,                 'Properties.PageAbout');

  // Panel
  L10nControl(lblSection1,             'Properties.Appearance');
  L10nControl(lblScreenEdge,           'Properties.Position');
  L10nControl(cbbScreenPosition,      ['Properties.Left', 'Properties.Top', 'Properties.Right', 'Properties.Bottom']);
  L10nControl(lblOrder,                'Properties.Order');
  L10nControl(cbbItemOrder,           ['Properties.LtR', 'Properties.UtD']);
  L10nControl(lblItemsAlign,           'Properties.ItemsAlign');
  L10nControl(cbbItemsAlign,          ['Properties.Left', 'Properties.Center']);
  L10nControl(chbUseBkgndColor,        'Properties.BgColor');
  L10nControl(lblOpacity,              'Properties.Opacity');
  L10nControl(chbStayOnTop,            'Properties.AlwaysOnTop');

  // Windows specific
  L10nControl(lblSectionWindows,       'Properties.ForWindows');
  // Windows 7
  L10nControl(chbLightStyle,           'Properties.Style1');
  // Windows 8
  L10nControl(chbAeroGlass,            'Properties.AeroGlass');
  // Windows 10
  L10nControl(lblColorMode,            'Properties.Theme');
  L10nControl(cbbColorMode,           ['Properties.Light', 'Properties.Dark', 'Properties.Accent']);
  L10nControl(lblTransparencyMode,     'Properties.Transparency');
  L10nControl(cbbTransparencyMode,    ['Properties.Opaque', 'Properties.Transparent', 'Properties.Glass']);
  L10nControl(chbModernStyle,          'Properties.ModernStyle');
  L10nControl(chbSysWidgets,           'Properties.SysWidgets');
  L10nControl(chbAutoStart,            'Properties.AutoStart');
  L10nControl(lblBarStyle,             'Properties.BarStyle');
  L10nControl(cbbBarStyle,            ['Properties.BarStyleNormal', 'Properties.BarStyleDock']);
  L10nControl(lblZoom,                 'Properties.Zoom');

  // Items
  L10nControl(lblShortcuts,            'Properties.Shortcuts');
  L10nControl(lblIconSize,             'Properties.IconSize');
  L10nControl(lblMargin,               'Properties.Margins');
  L10nControl(lblTextPosition,         'Properties.TextPos');
  L10nControl(cbbTextLayout,          ['Properties.Without' , 'Properties.Left', 'Properties.Top', 'Properties.Right', 'Properties.Bottom']);
  L10nControl(lblTextWidthIdent,       'Properties.TextWidth');
  L10nControl(chbTextColor,            'Properties.TextColor');
  L10nControl(lblTextGlowSize,         'Properties.GlowSize');
  L10nControl(chbTooltipShow,          'Properties.ShowTooltips');
  L10nControl(lblSeperators,           'Properties.Separators');
  L10nControl(lblSeparatorWidth,       'Properties.Width');
  L10nControl(lblSeparatorStyle,       'Properties.Style');
  L10nControl(cbbSeparatorStyle,      ['Properties.Line', 'Properties.Spacer']);

  // Autohide
  L10nControl(lblSection3,             'Properties.AutoHide');
  L10nControl(lbl2,                    'Properties.Hide');
  L10nControl(chbAutoHide,             'Properties.Automatically');
  L10nControl(lblShow,                 'Properties.Show');
  L10nControl(cbbAutoShowMode,        ['Properties.MouseHover', 'Properties.MouseLC', 'Properties.MouseRC']);
  L10nControl(lblDelay,                'Properties.Delay');
  L10nControl(lblCornerGapWidth,       'Properties.CornerTransWidth');
  L10nControl(lblHotKey,               'Properties.HotKey');
  L10nControl(chbAutoHideTransparency, 'Properties.AutoHideTransparency');

  // Additional
  L10nControl(lblSectionJumplist,       'Properties.Jumplists');
  L10nControl(lblJumplistShowMode,      'Properties.Show');
  L10nControl(cbbJumplistShowMode,     ['Properties.No', 'Properties.MouseRC']);
  L10nControl(lblJumplistRecentMax,     'Properties.JumplistRecentMaxItems');

  // About
  L10nControl(lblVer,                   'Properties.Version');
  L10nControl(lblLocalizer,             'Properties.Localizer');
  L10nControl(lblSystemInfo,            'Properties.SystemInfo');

  // Buttons
  L10nControl(btnOk,                    'Button.Ok');
  L10nControl(btnCancel,                'Button.Cancel');
  L10nControl(btnApply,                 'Button.Apply');
end;

procedure TFrmProperties.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TFrmProperties.FormDestroy(Sender: TObject);
begin
  FrmProperties := nil;
  FColorPicker.Free;
  // Undo live preview if not applied (after Apply/OK this re-applies the saved values)
  FLinkbar.ApplyWindowAccent;
  PostMessage(FLinkbar.Handle, LM_DOAUTOHIDE, 0, 0);
end;

procedure TFrmProperties.FormMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
var spin: TnSpinedit;
begin
  if Assigned(ActiveControl)
     and (ActiveControl.ClassType = TnSpinedit)
  then begin
    spin := TnSpinedit(ActiveControl);
    spin.Value := spin.Value + Sign(WheelDelta) * spin.Increment;
    Handled := True;
  end;
end;

procedure TFrmProperties.imCopyClick(Sender: TObject);
begin
  Clipboard.AsText := lblSysInfo.Caption;
end;

procedure TFrmProperties.linkEmailLinkClick(Sender: TObject; const Link: string;
  LinkType: TSysLinkType);
begin
  if not SendShellEmail(Application.Handle, URL_EMAIL,
    APP_NAME_LINKBAR,
    lblVer.Caption
    + '%0D%0A' + 'OS: ' + lblSysInfo.Caption)
  then begin
  end;
end;

procedure TFrmProperties.linkWebLinkClick(Sender: TObject; const Link: string;
  LinkType: TSysLinkType);
begin
  if (Sender = linkGithub)
  then LBShellExecute(0, 'open', URL_GITHUB)
  else if (Sender = linkFork)
  then LBShellExecute(0, 'open', URL_FORK_GITHUB)
  else LBShellExecute(0, 'open', URL_WEB);
end;

procedure TFrmProperties.Changed(Sender: TObject);
var //sm: TAutoShowMode;
    ah: Boolean;
begin
  if (not FCanChanged)
  then Exit;

  btnApply.Enabled := True;

  // Color additional options
  edtBkgndColor.Enabled := chbUseBkgndColor.Checked;
  btnBkgndColorEdit.Enabled := chbUseBkgndColor.Checked;

  // Live preview when transparency mode changes
  if (Sender = cbbTransparencyMode)
  then PreviewBackground;

  // Autohide additional options
  ah := chbAutoHide.Checked;
  cbbAutoShowMode.Enabled := ah;
  chbAutoHideTransparency.Enabled := ah;
  lblShow.Enabled := ah;
  //sm := TAutoShowMode(cbbAutoShowMode.ItemIndex);
  // Mouse-Hover Delay
  lblDelay.Enabled := ah;// and (sm = smMouseHover);
  nseAutoShowDelay.Enabled := lblDelay.Enabled;
  // Hotkey
  lblHotKey.Enabled := ah;// and (sm = smHotKey);
  edtHotKey.Enabled := lblHotKey.Enabled;

  lblCornerGapWidth.Enabled := ah;
  nseCorner1GapWidth.Enabled := ah;
  nseCorner2GapWidth.Enabled := ah;

  //if (sm = smHotKey)
  //then pnlHotkey.BringToFront
  //else pnlDelay.BringToFront;

  // Text additional options
  const enabled: Boolean = cbbTextLayout.ItemIndex > 0;
  lblTextWidthIdent.Enabled := enabled;
  nseTextWidth.Enabled := enabled;
  nseTextOffset.Enabled := enabled;
  lblTextGlowSize.Enabled := enabled;
  nseGlowSize.Enabled := enabled;
  chbTextColor.Enabled := enabled;
  clbTextColor.Enabled := enabled and chbTextColor.Checked;

  // Check Hotkey
  //if ((Sender = edtHotKey) and (FLinkbar.HotkeyInfo <> edtHotKey.HotkeyInfo))
  //   or
  //   ((Sender = chbAutoHide) and chbAutoHide.Checked)
  //then CheckHotkey(Handle, edtHotKey.HotkeyInfo);

end;

procedure TFrmProperties.btnCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TFrmProperties.DialogButtonClick(Sender: TObject);
var temp_ah: Boolean;
begin
  if ((Sender = btnOk) and not btnApply.Enabled)
  then begin
    Close;
    Exit;
  end;

  if (Sender = btnOk)
  then begin
    AlphaBlendValue := 0;
    AlphaBlend := True;
  end;

  FLinkbar.EnableAeroGlass := chbAeroGlass.Checked;

  FLinkbar.AutoShowDelay := nseAutoShowDelay.Value;

  FLinkbar.Layout := TPanelLayout(cbbItemsAlign.ItemIndex);

  FLinkbar.BackgroundColor := FBackgroundColor;
  FLinkbar.TextColor := FTextColor;
  FLinkbar.UseBkgndColor := chbUseBkgndColor.Checked;
  FLinkbar.UseTextColor := chbTextColor.Checked;

  FLinkbar.GlowSize := nseGlowSize.Value;

  FLinkbar.IsLightStyle := chbLightStyle.Checked;
  FLinkbar.AutoShowMode := TAutoShowMode(cbbAutoShowMode.ItemIndex);
  FLinkbar.ItemOrder := TItemOrder(cbbItemOrder.ItemIndex);
  FLinkbar.TextLayout := TTextLayout(cbbTextLayout.ItemIndex);
  FLinkbar.TextWidth := EnsureRange(nseTextWidth.Value, TEXT_WIDTH_MIN, TEXT_WIDTH_MAX);
  FLinkbar.TextOffset := EnsureRange(nseTextOffset.Value, TEXT_OFFSET_MIN, TEXT_OFFSET_MAX);
  FLinkbar.IconSize := EnsureRange(nseIconSize.Value, ICON_SIZE_MIN, ICON_SIZE_MAX);
  FLinkbar.ItemMargin := TSize.Create(
    EnsureRange(nseMarginH.Value, MARGIN_MIN, MARGIN_MAX),
    EnsureRange(nseMarginV.Value, MARGIN_MIN, MARGIN_MAX)
  );
  FLinkbar.AutoHideTransparency := chbAutoHideTransparency.Checked;
  FLinkbar.JumplistShowMode := TJumplistShowMode(cbbJumplistShowMode.ItemIndex);
  FLinkbar.JumplistRecentMax := nseJumplistRecentMax.Value;
  FLinkbar.StayOnTop := chbStayOnTop.Checked;
  FLinkbar.TransparencyMode := TTransparencyMode(cbbTransparencyMode.ItemIndex);
  FLinkbar.Look := TLook(cbbColorMode.ItemIndex);
  FLinkbar.Corner1GapWidth := nseCorner1GapWidth.Value;
  FLinkbar.Corner2GapWidth := nseCorner2GapWidth.Value;
  FLinkbar.SeparatorWidth := nseSeparatorWidth.Value;
  FLinkbar.SeparatorStyle := TSeparatorStyle(cbbSeparatorStyle.ItemIndex);
  FLinkbar.TooltipShow := chbTooltipShow.Checked;
  FLinkbar.ModernStyle := chbModernStyle.Checked;
  FLinkbar.ShowSysWidgets := chbSysWidgets.Checked;
  SetAutoStart(chbAutoStart.Checked);
  FLinkbar.ZoomPercent := trbZoom.Position;
  FLinkbar.BarStyle := cbbBarStyle.ItemIndex;
  FLinkbar.ApplyWindowAccent; // dock: repaint with the new color

  FLinkbar.UpdateItemSizes;

  // for avoid double message "autohide panel already exists..."
  temp_ah := FLinkbar.AutoHide;
  FLinkbar.Align := TPanelAlign(cbbScreenPosition.ItemIndex);
  if (temp_ah = FLinkbar.AutoHide)
  then FLinkbar.AutoHide := chbAutohide.Checked;

  FLinkbar.HotkeyInfo := edtHotKey.HotkeyInfo;

  FLinkbar.SaveSettings;

  if (Sender = btnOk)
  then begin
    Close;
    Exit;
  end;

  chbAutoHide.Checked := FLinkbar.AutoHide;
  btnApply.Enabled := False;
  ActiveControl := btnOk;
end;

procedure TFrmProperties.edtBkgndColorChange(Sender: TObject);
begin
  if (Sender = edtBkgndColor)
  then begin
    FBackgroundColor := Cardinal(StrToIntDef(HexDisplayPrefix + edtBkgndColor.Text, 0));
    SyncOpacityFromColor;
    PreviewBackground;
  end;

  if (Sender = clbTextColor)
  then FTextColor := Cardinal(clbTextColor.Selected);

  Changed(Sender);
end;

procedure TFrmProperties.edtBkgndColorKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #8)
  then Exit;

  if not CharInSet(Key, ['a'..'f', 'A'..'F', '0'..'9'])
  then Key := #0;
end;

procedure TFrmProperties.btnBgColorClick(Sender: TObject);
begin
  if (Sender = btnBkgndColorEdit)
  then begin
    FColorPicker.Color := BackgroundColor;
    if (FColorPicker.ShowModal = mrOk)
    then BackgroundColor := FColorPicker.Color;
  end;
end;

{ Opacity slider position (0..100 %) from alpha byte of background color }
procedure TFrmProperties.SyncOpacityFromColor;
begin
  if FOpacityUpdating
  then Exit;
  FOpacityUpdating := True;
  try
    trbOpacity.Position := Round((FBackgroundColor shr 24) * 100 / 255);
    lblOpacityValue.Caption := IntToStr(trbOpacity.Position) + ' %';
  finally
    FOpacityUpdating := False;
  end;
end;

{ Slider moved: update alpha byte, make sure the color is used and visible }
procedure TFrmProperties.trbOpacityChange(Sender: TObject);
var alpha: Cardinal;
begin
  lblOpacityValue.Caption := IntToStr(trbOpacity.Position) + ' %';
  if FOpacityUpdating or (not FCanChanged)
  then Exit;

  FOpacityUpdating := True;
  try
    // Opacity needs custom background color
    if not chbUseBkgndColor.Checked
    then chbUseBkgndColor.Checked := True;
    // Opaque mode ignores alpha: switch to Transparent
    if (trbOpacity.Position < 100) and (cbbTransparencyMode.ItemIndex = 0)
    then cbbTransparencyMode.ItemIndex := 1;

    alpha := Cardinal(Round(trbOpacity.Position * 255 / 100));
    BackgroundColor := (FBackgroundColor and $00FFFFFF) or (alpha shl 24);
  finally
    FOpacityUpdating := False;
  end;
  PreviewBackground;
  Changed(Sender);
end;

{ Magnification slider: 100% = off }
procedure TFrmProperties.trbZoomChange(Sender: TObject);
begin
  if (trbZoom.Position <= 100)
  then lblZoomValue.Caption := L10NFind('Properties.ZoomOff', 'Off')
  else lblZoomValue.Caption := IntToStr(trbZoom.Position) + ' %';
  if (Sender <> nil)
  then Changed(Sender);
end;

{ Live preview of background color/opacity on the bar (not saved until Apply/OK) }
procedure TFrmProperties.PreviewBackground;
begin
  if (not FCanChanged) or (not IsWindows10)
     or (not chbUseBkgndColor.Checked)
  then Exit;
  // the dock paints its own background: no accent preview (shown after Apply)
  if (FLinkbar.BarStyle = BAR_STYLE_DOCK)
  then Exit;
  ThemeSetWindowAccentPolicy10(FLinkbar.Handle,
    TTransparencyMode(cbbTransparencyMode.ItemIndex), FBackgroundColor);
end;

procedure TFrmProperties.SetBackgroundColor(AValue: Cardinal);
begin
  FBackgroundColor := AValue;
  edtBkgndColor.Text := IntToHex(FBackgroundColor, 8);
end;

procedure TFrmProperties.SetTextColor(AValue: Cardinal);
begin
  FTextColor := AValue and $ffffff;
  clbTextColor.Selected := FTextColor;
end;

end.

