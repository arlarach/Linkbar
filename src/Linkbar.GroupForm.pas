{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   Icon groups popup (Android-like folder)             }
{*******************************************************}

unit Linkbar.GroupForm;

{$i linkbar.inc}

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes, System.Types, System.UITypes,
  System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  LBToolbar, Linkbar.Consts;

type
  { Called when the user drags an icon out of the group window }
  TGroupDragOutEvent = procedure(const AFileName: string; AIcon: HBITMAP;
    AIconSize: Integer) of object;

  { Popup window that shows the shortcuts of a group as a grid of icons }
  TFormGroup = class(TForm)
  private
    FItems: TObjectList<TItemShortcut>;
    FFolder: string;
    FOnDragOut: TGroupDragOutEvent;
    FDownIndex: Integer;      // item under mouse on left button down
    FDownPt: TPoint;
    FDragging: Boolean;       // reordering inside the window
    FDropIndex: Integer;      // insert position while reordering
    FStack: TStringList;      // parent groups (navigation into sub-groups): folder=caption
    FAnchorRect: TRect;
    FAlign: TPanelAlign;
    FModalOpen: Boolean;      // a dialog of ours is open: don't close on deactivate
    FOwnerWnd: HWND;
    FGroupCaption: string;
    FIconSize: Integer;
    FHot: Integer;
    FCols, FRows: Integer;
    FCellW, FCellH: Integer;
    FPad: Integer;
    FHeaderHeight: Integer;
    FRadius: Integer;
    FBgColor, FTextColor, FBorderColor: TColor;
    FHotColor: Cardinal;
    function Scale(const AValue: Integer): Integer;
    function CellRect(const AIndex: Integer): TRect;
    function IndexAt(const APoint: TPoint): Integer;
    procedure DrawItemIcon(const AItem: TItemShortcut; const AX, AY: Integer);
    procedure CalcLayout;
    procedure SetHot(const AValue: Integer);
    procedure ApplyCorners;
    procedure LoadItems;
    procedure UpdateRunning;
    procedure SaveOrder;
    function DropIndexAt(const APoint: TPoint): Integer;
    procedure DoSortAlphabetically(Sender: TObject);
    procedure DoNewGroup(Sender: TObject);
    procedure DoRenameSubGroup(Sender: TObject);
    procedure DoOpenFolder(Sender: TObject);
    procedure Reposition;
    procedure NavigateInto(const AIndex: Integer);
    procedure NavigateBack;
    procedure Reload;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WndProc(var Message: TMessage); override;
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure DoClose(var Action: TCloseAction); override;
  public
    constructor CreateGroup(AOwner: TComponent; AOwnerWnd: HWND;
      const AFolder, ACaption: string; AIconSize: Integer);
    destructor Destroy; override;
    procedure PopupAt(const AItemRect: TRect; const AAlign: TPanelAlign);
    property OnDragOut: TGroupDragOutEvent read FOnDragOut write FOnDragOut;
  end;

implementation

uses
  System.Math, GdiPlus, Vcl.Menus, Vcl.Dialogs, Winapi.ShellAPI,
  ExplorerMenu, Linkbar.Theme, Linkbar.OS, Linkbar.L10n;

{ TFormGroup }

constructor TFormGroup.CreateGroup(AOwner: TComponent; AOwnerWnd: HWND;
  const AFolder, ACaption: string; AIconSize: Integer);
begin
  inherited CreateNew(AOwner);

  FOwnerWnd := AOwnerWnd;
  FFolder := AFolder;
  FGroupCaption := ACaption;
  FIconSize := AIconSize;
  FHot := -1;
  FDownIndex := -1;
  FDropIndex := -1;
  FDragging := False;
  ControlStyle := ControlStyle + [csCaptureMouse];

  BorderStyle := bsNone;
  FormStyle := fsStayOnTop;
  Position := poDesigned;
  DoubleBuffered := True;
  Font.Assign(Screen.IconFont);

  // Colors (follow Linkbar color mode)
  if (GlobalLook = ELookLight)
  then begin
    FBgColor := $00F3F3F3;
    FTextColor := clBlack;
    FBorderColor := $00D0D0D0;
    FHotColor := $14000000; // black 8%
  end
  else begin
    FBgColor := $002B2B2B;
    FTextColor := clWhite;
    FBorderColor := $00454545;
    FHotColor := $1AFFFFFF; // white 10%
  end;
  Color := FBgColor;

  FItems := TObjectList<TItemShortcut>.Create(True);
  FStack := TStringList.Create;
  LoadItems;
  CalcLayout;
end;

procedure TFormGroup.LoadItems;
var
  item: TItemShortcut;
  fileName: string;
begin
  FItems.Clear;
  for fileName in TItemGroup.GetMemberFiles(FFolder) do
  begin
    item := CreateItemForFile(fileName); // TItemGroup for sub-groups
    if item.LoadFromFile(fileName)
    then begin
      item.LoadIcon(FIconSize);
      FItems.Add(item);
    end
    else item.Free;
  end;
  UpdateRunning;
end;

{ "Program is open" indicator for the icons of the group }
procedure TFormGroup.UpdateRunning;
var
  paths: TStringList;
  item: TItemShortcut;
  idx: Integer;
begin
  paths := TStringList.Create;
  try
    CollectRunningExePaths(paths);
    for item in FItems do
    begin
      item.Running := (item.TargetPath <> '') and paths.Find(item.TargetPath, idx);
      if (not item.Running) and (item is TItemGroup)
      then
        for var t in TItemGroup(item).MemberTargets do
          if (t <> '') and paths.Find(t, idx)
          then begin
            item.Running := True;
            Break;
          end;
    end;
  finally
    paths.Free;
  end;
end;

{ Save current order to "<group>\list" (the group icon follows it too) }
procedure TFormGroup.SaveOrder;
var
  sl: TStringList;
  item: TItemShortcut;
begin
  sl := TStringList.Create;
  try
    for item in FItems do
      sl.Add(ExtractFileName(item.FileName));
    try
      sl.SaveToFile(IncludeTrailingPathDelimiter(FFolder) + LINKSLIST_FILE_NAME, TEncoding.UTF8);
    except
      // ignore: read-only folder etc.
    end;
  finally
    sl.Free;
  end;
end;

procedure TFormGroup.Reload;
begin
  LoadItems;
  CalcLayout;
  Reposition;
  Invalidate;
end;

procedure TFormGroup.NavigateInto(const AIndex: Integer);
begin
  FStack.Add(FFolder + '=' + FGroupCaption);
  FFolder := ExcludeTrailingPathDelimiter(FItems[AIndex].FileName);
  FGroupCaption := FItems[AIndex].Caption;
  FHot := -1;
  Reload;
end;

procedure TFormGroup.NavigateBack;
begin
  if (FStack.Count = 0)
  then Exit;
  FFolder := FStack.Names[FStack.Count - 1];
  FGroupCaption := FStack.ValueFromIndex[FStack.Count - 1];
  FStack.Delete(FStack.Count - 1);
  FHot := -1;
  Reload;
end;

{ New sub-group inside the current group }
procedure TFormGroup.DoNewGroup(Sender: TObject);
var baseName, dirName: string;
    n: Integer;
begin
  baseName := L10NFind('Menu.GroupDefaultName', 'Group');
  dirName := IncludeTrailingPathDelimiter(FFolder) + baseName + ES_GROUP;
  n := 2;
  while DirectoryExists(dirName) or FileExists(dirName) do
  begin
    dirName := IncludeTrailingPathDelimiter(FFolder) + baseName + ' ' + IntToStr(n) + ES_GROUP;
    Inc(n);
  end;
  ForceDirectories(dirName);
  Reload;
end;

{ Rename a sub-group (Tag of the menu item = index) }
procedure TFormGroup.DoRenameSubGroup(Sender: TObject);
const InvalidChars = '\/:*?"<>|';
var i: Integer;
    newName, newPath: string;
    ch: Char;
begin
  i := TMenuItem(Sender).Tag;
  if (i < 0) or (i >= FItems.Count) then Exit;
  newName := FItems[i].Caption;
  FModalOpen := True;
  try
    if not InputQuery(L10NFind('Group.RenameTitle', 'Rename group'),
                      L10NFind('Group.RenamePrompt', 'Name:'), newName)
    then Exit;
  finally
    FModalOpen := False;
    SetForegroundWindow(Handle);
  end;
  newName := Trim(newName);
  if (newName = '') then Exit;
  for ch in InvalidChars do
    if (Pos(ch, newName) > 0) then Exit;
  newPath := IncludeTrailingPathDelimiter(FFolder) + newName + ES_GROUP;
  if DirectoryExists(newPath) or FileExists(newPath) then Exit;
  if RenameFile(ExcludeTrailingPathDelimiter(FItems[i].FileName), newPath)
  then Reload;
end;

procedure TFormGroup.DoOpenFolder(Sender: TObject);
var i: Integer;
begin
  i := TMenuItem(Sender).Tag;
  if (i >= 0) and (i < FItems.Count)
  then ShellExecute(0, 'open', PChar(FItems[i].FileName), nil, nil, SW_SHOWNORMAL)
  else ShellExecute(0, 'open', PChar(FFolder), nil, nil, SW_SHOWNORMAL);
  Close;
end;

procedure TFormGroup.DoSortAlphabetically(Sender: TObject);
begin
  System.SysUtils.DeleteFile(IncludeTrailingPathDelimiter(FFolder) + LINKSLIST_FILE_NAME);
  Reload;
end;

{ Insert position for reordering: before the cell under the point (left half)
  or after it (right half) }
function TFormGroup.DropIndexAt(const APoint: TPoint): Integer;
var
  i: Integer;
  r: TRect;
begin
  for i := 0 to FItems.Count-1 do
  begin
    r := CellRect(i);
    if r.Contains(APoint)
    then begin
      if (APoint.X < r.CenterPoint.X)
      then Exit(i)
      else Exit(i + 1);
    end;
  end;
  Result := -1;
end;

destructor TFormGroup.Destroy;
begin
  FStack.Free;
  FItems.Free;
  inherited;
end;

function TFormGroup.Scale(const AValue: Integer): Integer;
begin
  Result := MulDiv(AValue, Screen.PixelsPerInch, 96);
end;

procedure TFormGroup.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := WS_POPUP;
  Params.ExStyle := (Params.ExStyle or WS_EX_TOOLWINDOW) and not WS_EX_APPWINDOW;
  Params.WindowClass.style := Params.WindowClass.style or CS_DROPSHADOW;
  Params.WndParent := FOwnerWnd;
end;

procedure TFormGroup.CalcLayout;
var
  bmp: Vcl.Graphics.TBitmap;
  textH, n: Integer;
begin
  bmp := Vcl.Graphics.TBitmap.Create;
  try
    bmp.Canvas.Font.Assign(Font);
    textH := bmp.Canvas.TextHeight('Wg');
  finally
    bmp.Free;
  end;

  FPad := Scale(8);
  FRadius := Scale(8);
  FCellW := Max(FIconSize + Scale(24), Scale(84));
  FCellH := Scale(10) + FIconSize + Scale(6) + textH * 2 + Scale(8);
  FHeaderHeight := Scale(10) + textH + Scale(6);

  n := FItems.Count;
  if (n <= 4) then FCols := Max(n, 1)
  else if (n <= 9) then FCols := 3
  else FCols := 4;
  FRows := Max(1, (n + FCols - 1) div FCols);

  if (n = 0)
  then begin
    // Room for the "empty group" hint
    FCols := 3;
    FRows := 1;
  end;

  ClientWidth := FPad * 2 + FCols * FCellW;
  ClientHeight := FHeaderHeight + FRows * FCellH + FPad;
end;

function TFormGroup.CellRect(const AIndex: Integer): TRect;
begin
  Result := Bounds(
    FPad + (AIndex mod FCols) * FCellW,
    FHeaderHeight + (AIndex div FCols) * FCellH,
    FCellW, FCellH);
end;

function TFormGroup.IndexAt(const APoint: TPoint): Integer;
var i: Integer;
begin
  for i := 0 to FItems.Count-1 do
    if CellRect(i).Contains(APoint)
    then Exit(i);
  Result := -1;
end;

procedure TFormGroup.SetHot(const AValue: Integer);
begin
  if (AValue = FHot)
  then Exit;
  FHot := AValue;
  Invalidate;
end;

procedure TFormGroup.DrawItemIcon(const AItem: TItemShortcut; const AX, AY: Integer);
var
  dc: HDC;
  old: HGDIOBJ;
  bm: Winapi.Windows.TBitmap;
  bf: TBlendFunction;
begin
  if (AItem.Bitmap = 0)
     or (GetObject(AItem.Bitmap, SizeOf(bm), @bm) = 0)
  then Exit;

  bf.BlendOp := AC_SRC_OVER;
  bf.BlendFlags := 0;
  bf.SourceConstantAlpha := 255;
  bf.AlphaFormat := AC_SRC_ALPHA;

  dc := CreateCompatibleDC(Canvas.Handle);
  old := SelectObject(dc, AItem.Bitmap);
  Winapi.Windows.AlphaBlend(Canvas.Handle, AX, AY, FIconSize, FIconSize,
    dc, 0, 0, bm.bmWidth, Abs(bm.bmHeight), bf);
  SelectObject(dc, old);
  DeleteDC(dc);
end;

procedure TFormGroup.Paint;
var
  i: Integer;
  r, tr: TRect;
  gp: IGPGraphics;
  brush: IGPBrush;
  s: string;
begin
  // Background + border
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := FBgColor;
  Canvas.FillRect(ClientRect);
  Canvas.Pen.Color := FBorderColor;
  Canvas.Brush.Style := bsClear;
  if IsWindows11OrAbove
  then Canvas.Rectangle(ClientRect)
  else Canvas.RoundRect(0, 0, ClientWidth, ClientHeight, FRadius * 2, FRadius * 2);

  SetBkMode(Canvas.Handle, TRANSPARENT);
  Canvas.Font.Assign(Font);
  Canvas.Font.Color := FTextColor;

  // Title
  Canvas.Font.Style := [fsBold];
  r := Rect(FPad, Scale(10), ClientWidth - FPad, FHeaderHeight);
  if (FStack.Count > 0)
  then s := #$2039 + '  ' + FGroupCaption  // "back" arrow: click the title to go up
  else s := FGroupCaption;
  DrawText(Canvas.Handle, PChar(s), -1, r,
    DT_CENTER or DT_TOP or DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX);
  Canvas.Font.Style := [];

  // Empty group hint
  if (FItems.Count = 0)
  then begin
    s := L10NFind('Group.Empty', 'Empty group. Drag shortcuts onto the group icon.');
    r := Rect(FPad * 2, FHeaderHeight, ClientWidth - FPad * 2, ClientHeight - FPad);
    DrawText(Canvas.Handle, PChar(s), -1, r,
      DT_CENTER or DT_WORDBREAK or DT_NOPREFIX);
    Exit;
  end;

  // Items
  for i := 0 to FItems.Count-1 do
  begin
    r := CellRect(i);

    if (i = FHot)
    then begin
      gp := TGPGraphics.Create(Canvas.Handle);
      brush := TGPSolidBrush.Create(FHotColor);
      tr := r;
      tr.Inflate(-Scale(2), -Scale(2));
      GPFillRoundRect(gp, brush, tr, Scale(6));
      gp := nil;
    end;

    DrawItemIcon(FItems[i], r.Left + (r.Width - FIconSize) div 2, r.Top + Scale(10));

    // "Program is open" indicator under the icon
    if FItems[i].Running
    then begin
      gp := TGPGraphics.Create(Canvas.Handle);
      brush := TGPSolidBrush.Create(SwapRedBlue(GetImmersiveColorFromName('ImmersiveSystemAccentLight2')) or $FF000000);
      tr := Bounds(r.Left + (r.Width - Max(Scale(16), (FIconSize * 2) div 3)) div 2,
                   r.Top + Scale(10) + FIconSize + Scale(2),
                   Max(Scale(16), (FIconSize * 2) div 3), Max(3, Scale(3)));
      GPFillRoundRect(gp, brush, tr, tr.Height div 2);
      gp := nil;
    end;

    tr := Rect(r.Left + Scale(4), r.Top + Scale(10) + FIconSize + Scale(6),
               r.Right - Scale(4), r.Bottom - Scale(4));
    DrawText(Canvas.Handle, PChar(FItems[i].Caption), -1, tr,
      DT_CENTER or DT_WORDBREAK or DT_EDITCONTROL or DT_END_ELLIPSIS or DT_NOPREFIX);
  end;

  // Reorder: insertion marker
  if FDragging and (FDropIndex >= 0)
  then begin
    if (FDropIndex < FItems.Count)
    then begin
      r := CellRect(FDropIndex);
      tr := Rect(r.Left - Scale(1), r.Top + Scale(6), r.Left + Scale(2), r.Top + Scale(10) + FIconSize + Scale(4));
    end
    else begin
      r := CellRect(FItems.Count - 1);
      tr := Rect(r.Right - Scale(2), r.Top + Scale(6), r.Right + Scale(1), r.Top + Scale(10) + FIconSize + Scale(4));
    end;
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := FTextColor;
    Canvas.FillRect(tr);
  end;
end;

procedure TFormGroup.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if (Button = mbLeft)
  then begin
    FDownIndex := IndexAt(Point(X, Y));
    FDownPt := Point(X, Y);
    FDragging := False;
    FDropIndex := -1;
  end;
end;

procedure TFormGroup.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  pt: TPoint;
  item: TItemShortcut;
begin
  inherited;
  pt := Point(X, Y);

  if (ssLeft in Shift) and (FDownIndex >= 0)
  then begin
    // Start dragging after the system drag threshold
    if not FDragging
       and ((Abs(X - FDownPt.X) > GetSystemMetrics(SM_CXDRAG))
            or (Abs(Y - FDownPt.Y) > GetSystemMetrics(SM_CYDRAG)))
    then FDragging := True;

    if FDragging
    then begin
      if PtInRect(ClientRect, pt)
      then begin
        // Reorder inside the window
        FDropIndex := DropIndexAt(pt);
        SetHot(-1);
        Invalidate;
      end
      else begin
        // Left the window: drag the shortcut out (e.g. back to the bar)
        item := FItems[FDownIndex];
        FDragging := False;
        FDownIndex := -1;
        FDropIndex := -1;
        MouseCapture := False;
        Invalidate;
        if Assigned(FOnDragOut)
        then FOnDragOut(item.FileName, item.Bitmap, FIconSize);
        Close;
      end;
      Exit;
    end;
  end;

  SetHot(IndexAt(pt));
end;

procedure TFormGroup.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  i, src, dst: Integer;
  pt: TPoint;
  menu: TPopupMenu;
  mi: TMenuItem;
begin
  inherited;

  // Finish reordering
  if (Button = mbLeft) and FDragging
  then begin
    src := FDownIndex;
    dst := FDropIndex;
    FDragging := False;
    FDownIndex := -1;
    FDropIndex := -1;

    // Dropped on the center of a sub-group: move the shortcut inside it
    i := IndexAt(Point(X, Y));
    if (src >= 0) and (i >= 0) and (i <> src) and (FItems[i] is TItemGroup)
    then begin
      var cell := CellRect(i);
      cell.Inflate(-cell.Width div 4, -cell.Height div 4);
      if cell.Contains(Point(X, Y))
      then begin
        var srcFile := ExcludeTrailingPathDelimiter(FItems[src].FileName);
        var dstFile := IncludeTrailingPathDelimiter(FItems[i].FileName) + ExtractFileName(srcFile);
        if not (FileExists(dstFile) or DirectoryExists(dstFile))
        then MoveFile(PChar(srcFile), PChar(dstFile));
        Reload;
        Exit;
      end;
    end;

    if (src >= 0) and (dst >= 0)
    then begin
      if (dst > src) then Dec(dst);
      if (dst <> src) and (dst < FItems.Count)
      then begin
        FItems.Move(src, dst);
        SaveOrder;
      end;
    end;
    Invalidate;
    Exit;
  end;

  // Left click on the title of a sub-group: go back to the parent group
  if (Button = mbLeft) and (Y < FHeaderHeight) and (FStack.Count > 0)
  then begin
    FDownIndex := -1;
    NavigateBack;
    Exit;
  end;

  // Right click on the title / empty area: group menu
  if (Button = mbRight) and (IndexAt(Point(X, Y)) < 0)
  then begin
    menu := TPopupMenu.Create(Self);
    mi := TMenuItem.Create(menu);
    mi.Caption := L10NFind('Group.NewSubGroup', 'New group inside');
    mi.OnClick := DoNewGroup;
    menu.Items.Add(mi);
    mi := TMenuItem.Create(menu);
    mi.Caption := L10NFind('Group.SortAlphabetically', 'Sort alphabetically');
    mi.OnClick := DoSortAlphabetically;
    menu.Items.Add(mi);
    mi := TMenuItem.Create(menu);
    mi.Caption := L10NFind('Group.OpenFolder', 'Open folder');
    mi.Tag := -1;
    mi.OnClick := DoOpenFolder;
    menu.Items.Add(mi);
    pt := ClientToScreen(Point(X, Y));
    menu.Popup(pt.X, pt.Y);
    Exit;
  end;

  // Right click on a sub-group: its own menu
  i := IndexAt(Point(X, Y));
  if (Button = mbRight) and (i >= 0) and (FItems[i] is TItemGroup)
  then begin
    menu := TPopupMenu.Create(Self);
    mi := TMenuItem.Create(menu);
    mi.Caption := L10NFind('Group.RenameTitle', 'Rename group');
    mi.Tag := i;
    mi.OnClick := DoRenameSubGroup;
    menu.Items.Add(mi);
    mi := TMenuItem.Create(menu);
    mi.Caption := L10NFind('Group.OpenFolder', 'Open folder');
    mi.Tag := i;
    mi.OnClick := DoOpenFolder;
    menu.Items.Add(mi);
    pt := ClientToScreen(Point(X, Y));
    menu.Popup(pt.X, pt.Y);
    Exit;
  end;

  i := IndexAt(Point(X, Y));
  if (i < 0) or ((Button = mbLeft) and (i <> FDownIndex))
  then begin
    FDownIndex := -1;
    Exit;
  end;
  FDownIndex := -1;

  // Click on a sub-group: show its content in this window
  if (Button = mbLeft) and (FItems[i] is TItemGroup)
  then begin
    NavigateInto(i);
    Exit;
  end;

  if (Button = mbLeft)
  then begin
    try
      // Open program: bring it to the front, otherwise launch it
      if not (FItems[i].Running and ActivateProgram(FItems[i].TargetPath, 0))
      then OpenByDefaultVerb(FOwnerWnd, FItems[i].Pidl);
    finally
      Close;
    end;
  end
  else if (Button = mbRight)
  then begin
    pt := ClientToScreen(Point(X, Y));
    ExplorerMenuPopup(Handle, FItems[i].Pidl, pt, ssShift in Shift, 0);
  end;
end;

procedure TFormGroup.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_ESCAPE)
  then begin
    if (FStack.Count > 0)
    then NavigateBack
    else Close;
  end
  else if (Key = VK_BACK)
  then NavigateBack;
end;

procedure TFormGroup.DoClose(var Action: TCloseAction);
begin
  inherited;
  Action := caFree;
end;

procedure TFormGroup.WndProc(var Message: TMessage);
begin
  case Message.Msg of
    WM_ACTIVATE:
      // Close when user clicks outside
      if (LoWord(Message.WParam) = WA_INACTIVE) and (not FModalOpen)
      then PostMessage(Handle, WM_CLOSE, 0, 0);
    CM_MOUSELEAVE:
      SetHot(-1);
  end;
  inherited WndProc(Message);
end;

procedure TFormGroup.ApplyCorners;
var rgn: HRGN;
begin
  if IsWindows11OrAbove
  then ThemeSetRoundCorners11(Handle, False)
  else begin
    rgn := CreateRoundRectRgn(0, 0, Width + 1, Height + 1, FRadius * 2, FRadius * 2);
    SetWindowRgn(Handle, rgn, True); // the system owns rgn now
  end;
end;

procedure TFormGroup.PopupAt(const AItemRect: TRect; const AAlign: TPanelAlign);
begin
  FAnchorRect := AItemRect;
  FAlign := AAlign;
  Reposition;
  Show;
  SetForegroundWindow(Handle);
end;

{ Place the window next to the bar item (also after the size changed) }
procedure TFormGroup.Reposition;
var
  wa, AItemRect: TRect;
  AAlign: TPanelAlign;
  L, T, gap: Integer;
begin
  AItemRect := FAnchorRect;
  AAlign := FAlign;
  gap := Scale(6);
  wa := Screen.MonitorFromRect(AItemRect, mdNearest).WorkareaRect;

  case AAlign of
    EPanelAlignTop:
      begin
        L := AItemRect.CenterPoint.X - Width div 2;
        T := AItemRect.Bottom + gap;
      end;
    EPanelAlignBottom:
      begin
        L := AItemRect.CenterPoint.X - Width div 2;
        T := AItemRect.Top - Height - gap;
      end;
    EPanelAlignLeft:
      begin
        L := AItemRect.Right + gap;
        T := AItemRect.CenterPoint.Y - Height div 2;
      end;
    else // EPanelAlignRight
      begin
        L := AItemRect.Left - Width - gap;
        T := AItemRect.CenterPoint.Y - Height div 2;
      end;
  end;

  L := Max(wa.Left, Min(L, wa.Right - Width));
  T := Max(wa.Top, Min(T, wa.Bottom - Height));

  SetBounds(L, T, Width, Height);
  ApplyCorners;
end;

end.
