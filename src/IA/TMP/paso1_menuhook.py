import re
p = 'mUnit.pas'
s = open(p, 'rb').read().decode('utf-8')
a = s.index('{ --- Menús sin borde (estilo Sci-Fi) --- }')
b = s.index('procedure TLinkbarWcl.FormCreate(Sender: TObject);')
s = s[:a] + s[b:]
assert s.count('  LbInstallMenuHook;') == 1 and s.count('  LbRemoveMenuHook;') == 1
s = s.replace('  LbInstallMenuHook;', '  TMenuBorderHook.Install;')
s = s.replace('  LbRemoveMenuHook;', '  TMenuBorderHook.Remove;')
s = s.replace('LbMenuWinEvent (WinEventHook de menús)', 'TMenuBorderHook (WinEventHook de menús)')
s = s.replace('  Linkbar.Actions, Linkbar.TaskbarButton, Linkbar.IconPicker;',
              '  Linkbar.Actions, Linkbar.TaskbarButton, Linkbar.IconPicker, Linkbar.Bar.MenuHook;', 1)
open(p, 'wb').write(s.encode('utf-8'))
d = 'Linkbar.dproj'
t = open(d, 'rb').read().decode('utf-8')
k = '        <DCCReference Include="Linkbar.IconPicker.pas"/>'
nl = '\r\n' if '\r\n' in t else '\n'
t = t.replace(k, k + nl + '        <DCCReference Include="Linkbar.Bar.MenuHook.pas"/>', 1)
open(d, 'wb').write(t.encode('utf-8'))
