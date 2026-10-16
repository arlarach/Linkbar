def rd(path):
    return open(path, 'rb').read().decode('utf-8').replace('\r\n', '\n')


def wr(path, text):
    open(path, 'wb').write(text.replace('\n', '\r\n').encode('utf-8'))


def seg(s, start, end):
    a = s.index(start)
    b = s.index(end)
    assert a < b
    return s[a:b]


def rep(s, old, new, count=1):
    assert s.count(old) >= 1, old
    if count:
        assert s.count(old) == count, (old, s.count(old))
    return s.replace(old, new)


UNIT = """{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   Context menu of the bar: owner-drawn popup menu     }
{   with the dark look (build, measure and draw)        }
{*******************************************************}

unit Linkbar.Bar.PopupMenu;

{$i linkbar.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, Vcl.Menus;

type
  // A menu item to show, with its check mark
  TPopupEntry = record
    Item: TMenuItem;
    Checked: Boolean;
  end;

  TSciFiMenu = class
  public
    // Builds the owner-drawn popup menu (dark look, no check column). The caller
    // destroys the brush when the menu is closed; the menu is destroyed by the
    // caller or by the shell menu that takes it as a submenu
    class function Build(const AEntries: TArray<TPopupEntry>; out ABrush: HBRUSH): HMENU; static;
    // Owner draw messages of the menu items; False when the message is not for a menu
    class function Measure(const AWnd: HWND; var Message: TWMMeasureItem): Boolean; static;
    class function Draw(var Message: TWMDrawItem): Boolean; static;
  end;

implementation

uses
  SysUtils, Types, Vcl.Forms, GdiPlus, Linkbar.Theme;

class function TSciFiMenu.Build(const AEntries: TArray<TPopupEntry>; out ABrush: HBRUSH): HMENU;
var
  Flags: Integer;
  mi: TMenuInfo;
begin
  ABrush := 0;
  Result := CreatePopupMenu;
  if (Result = 0)
  then Exit;

  for var entry in AEntries
  do begin
    var item := entry.Item;
    Flags := MF_BYCOMMAND;

    if (item.IsLine)
    then Flags := Flags or MF_SEPARATOR
    else Flags := Flags or MF_STRING;

    if entry.Checked
    then Flags := Flags or MF_CHECKED;

    if (item.Count = 0)
    then begin
      // Convertir a OwnerDraw
      Flags := (Flags and not MF_STRING) or MF_OWNERDRAW;
      AppendMenu(Result, Flags, item.Command, PChar(item));
    end
    else begin
      var subMenu := CreatePopupMenu;

      for var subItem: TMenuItem in item
      do begin
        Flags := MF_BYCOMMAND or MF_OWNERDRAW;
        if (subItem.IsLine)
        then Flags := Flags or MF_SEPARATOR;
        if subItem.Checked
        then Flags := Flags or MF_CHECKED;
        AppendMenu(subMenu, Flags, subItem.Command, PChar(subItem));
      end;

      Flags := MF_POPUP or MF_OWNERDRAW;
      AppendMenu(Result, Flags, subMenu, PChar(item));
    end;
  end;

  // [OWNERDRAW] Se omiten los íconos nativos de Windows porque el dibujado Sci-Fi
  // es manual y los íconos nativos (MIIM_BITMAP) rompen la selección y los colores oscuros.

  mi := Default(TMenuInfo);
  mi.cbSize := SizeOf(TMenuInfo);
  mi.fMask := MIM_STYLE or MIM_BACKGROUND;
  mi.dwStyle := MNS_NOCHECK; // Quita el marco/columna izquierda de iconos de Windows clásico

  // Creamos el brush para el marco exterior/fondo
  ABrush := CreateSolidBrush(RGB(10, 20, 35)); // Azul muy oscuro Sci-Fi
  mi.hbrBack := ABrush;
  SetMenuInfo(Result, mi);

  // Los submenús (ej. Perfil, Nuevo) también necesitan el fondo oscuro y sin columna de checks;
  // si no, se ve el fondo claro por defecto entre los ítems.
  for var si := 0 to GetMenuItemCount(Result) - 1
  do begin
    var hSub := GetSubMenu(Result, si);
    if (hSub <> 0)
    then SetMenuInfo(hSub, mi);
  end;
end;

class function TSciFiMenu.Measure(const AWnd: HWND; var Message: TWMMeasureItem): Boolean;
var
  str: string;
  size: TSize;
  dc: HDC;
  fnt0: HGDIOBJ;
  item: TMenuItem;
begin
  Result := (Message.MeasureItemStruct^.CtlType = ODT_MENU);
  if not Result
  then Exit;

  item := TMenuItem(Message.MeasureItemStruct^.itemData);
  if item = nil then Exit;
  if item.IsLine then
  begin
    Message.MeasureItemStruct^.itemWidth := 10;
    Message.MeasureItemStruct^.itemHeight := 12;
  end
  else
  begin
    dc := GetDC(AWnd);
    fnt0 := SelectObject(dc, Screen.IconFont.Handle);
    str := item.Caption;
    str := StringReplace(str, '&', '', [rfReplaceAll]);
    GetTextExtentPoint32(dc, PChar(str), Length(str), size);
    SelectObject(dc, fnt0);
    ReleaseDC(AWnd, dc);
    Message.MeasureItemStruct^.itemWidth := size.cx + 50; // Margen
    Message.MeasureItemStruct^.itemHeight := 28;
  end;
end;

class function TSciFiMenu.Draw(var Message: TWMDrawItem): Boolean;
var
  dc: HDC;
  r, tr: TRect;
  item: TMenuItem;
  gp: TGPGraphics;
  brushFill, brushSel: TGPSolidBrush;
  str: string;
  fnt0: HGDIOBJ;
begin
  Result := (Message.DrawItemStruct^.CtlType = ODT_MENU);
  if not Result
  then Exit;

  item := TMenuItem(Message.DrawItemStruct^.itemData);
  if item = nil then Exit;
  dc := Message.DrawItemStruct^.hDC;
  r := Message.DrawItemStruct^.rcItem;

  gp := TGPGraphics.Create(dc);

  // Fondo general gris muy oscuro
  brushFill := TGPSolidBrush.Create($FF101010);
  GPFillRoundRect(gp, brushFill, r, 0);
  brushFill := nil;

  // Selección en azul translúcido
  if (Message.DrawItemStruct^.itemState and ODS_SELECTED) <> 0 then
  begin
    brushSel := TGPSolidBrush.Create($3300AAFF);
    tr := r;
    InflateRect(tr, -2, -2);
    GPFillRoundRect(gp, brushSel, tr, 4);
    brushSel := nil;
  end;

  if item.IsLine then
  begin
    brushFill := TGPSolidBrush.Create($FF333333);
    tr := r;
    tr.Top := r.Top + r.Height div 2;
    tr.Bottom := tr.Top + 1;
    tr.Left := tr.Left + 8;
    tr.Right := tr.Right - 8;
    GPFillRoundRect(gp, brushFill, tr, 0);
    brushFill := nil;
  end
  else
  begin
    str := item.Caption;
    str := StringReplace(str, '&', '', [rfReplaceAll]);

    fnt0 := SelectObject(dc, Screen.IconFont.Handle);
    SetBkMode(dc, TRANSPARENT);
    if (Message.DrawItemStruct^.itemState and ODS_SELECTED) <> 0 then
      SetTextColor(dc, RGB(0, 200, 255)) // Azul Sci-Fi
    else if item.Enabled then
      SetTextColor(dc, RGB(140, 165, 180)) // Celeste agrisado tenue (menor contraste)
    else
      SetTextColor(dc, RGB(70, 80, 90));

    r.Left := r.Left + 20;
    DrawText(dc, PChar(str), Length(str), r, DT_SINGLELINE or DT_VCENTER);

    if item.Count > 0 then
    begin
      r.Left := Message.DrawItemStruct^.rcItem.Right - 20;
      DrawText(dc, PChar('>'), 1, r, DT_SINGLELINE or DT_VCENTER);
    end;

    SelectObject(dc, fnt0);
  end;

  gp := nil;
end;

end.
"""
wr('Linkbar.Bar.PopupMenu.pas', UNIT)

p = 'mUnit.pas'
s = rd(p)

# --- DoPopupMenu: se conserva el filtro de ítems; la construcción pasa a TSciFiMenu ---
o_popup = seg(s, 'procedure TLinkbarWcl.DoPopupMenu(APt: TPoint; AShift: Boolean);', 'procedure TLinkbarWcl.WMMeasureItem(var Message: TWMMeasureItem);')
a = o_popup.index('  //for i := 0 to pMenu.Items.Count-1 do')
b = o_popup.index('    Flags := MF_BYCOMMAND;')
filters = o_popup[a:b]
filters = filters.replace('  //for i := 0 to pMenu.Items.Count-1 do\n', '')

NEW_POPUP = """procedure TLinkbarWcl.DoPopupMenu(APt: TPoint; AShift: Boolean);
var
  entries: TArray<TPopupEntry>;
  entry: TPopupEntry;
  FPopupMenu: HMENU;
  hbrBg: HBRUSH;
begin
  BuildProfilesMenu;
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

""" + filters + """    entry.Item := item;
    entry.Checked := ((item = imPinned) and IsItemIndex(FItemPopup) and Items[FItemPopup].Pinned)
                  or ((item = imLockBar) and FLockLinkbar)
                  or ((item = imSortAlphabet) and FSortAlphabetically);
    entries := entries + [entry];
  end;

  FPopupMenu := TSciFiMenu.Build(entries, hbrBg);
  if (FPopupMenu = 0)
  then Exit;

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
    DeleteObject(hbrBg);
    FLockHotIndex := False;
    if (WindowFromPoint(MakePoint(GetMessagePos)) <> Handle)
    then begin
      HotIndex := ITEM_NONE;
    end;
    FLockAutoHide := False;
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

"""
# la parte de los filtros termina antes de 'Flags := ...': hay que cerrar el for en el texto nuevo
assert filters.rstrip().endswith('end;') or True
s = s.replace(seg(s, 'procedure TLinkbarWcl.DoPopupMenu(APt: TPoint; AShift: Boolean);', 'procedure TLinkbarWcl.WMInitMenuPopup'), NEW_POPUP)
s = rep(s, 'Linkbar.Bar.DropTarget, Linkbar.Bar.Painter;', 'Linkbar.Bar.DropTarget, Linkbar.Bar.Painter, Linkbar.Bar.PopupMenu;')
wr(p, s)

d = rd('Linkbar.dproj')
k = '        <DCCReference Include="Linkbar.Bar.Painter.pas"/>'
d = rep(d, k, k + '\n        <DCCReference Include="Linkbar.Bar.PopupMenu.pas"/>')
wr('Linkbar.dproj', d)
