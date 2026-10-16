p = 'mUnit.pas'
s = open(p, 'rb').read().decode('utf-8').replace('\r\n', '\n')

def cut(s, start, end):
    a = s.index(start); b = s.index(end)
    assert a < b
    return s[:a] + s[b:]

def rep(s, old, new, count=1):
    assert s.count(old) >= 1, old
    if count: assert s.count(old) == count, (old, s.count(old))
    return s.replace(old, new)

# --- implementaciones que se mueven ---
s = cut(s, '{ The folder may be synced (Drive, OneDrive) and the file locked for a moment }',
           'procedure TLinkbarWcl.ShowSaveFailed;')
s = cut(s, 'function TLinkbarWcl.ProfilesDir: string;', 'procedure TLinkbarWcl.ReloadLinks;')
s = cut(s, 'function ValidProfileName(const AName: string): Boolean;', 'procedure TLinkbarWcl.ProfileNewClick(Sender: TObject);')

# --- CycleProfile ---
a = s.index('procedure TLinkbarWcl.CycleProfile(const ADelta: Integer);')
b = s.index('procedure TLinkbarWcl.BuildProfilesMenu;')
s = s[:a] + 'procedure TLinkbarWcl.CycleProfile(const ADelta: Integer);\nbegin\n  SwitchProfile(FProfiles.Neighbour(ADelta));\nend;\n\n' + s[b:]

# --- ShowSaveFailed con firma de evento ---
s = rep(s, 'procedure TLinkbarWcl.ShowSaveFailed;', 'procedure TLinkbarWcl.ShowSaveFailed(Sender: TObject);')
s = rep(s, '    procedure ShowSaveFailed;\n', '    procedure ShowSaveFailed(Sender: TObject);\n    procedure SaveRetryScheduled(Sender: TObject);\n')
s = rep(s, 'procedure TLinkbarWcl.ShowSaveFailed(Sender: TObject);',
        'procedure TLinkbarWcl.SaveRetryScheduled(Sender: TObject);\nbegin\n  SetTimer(Handle, TIMER_SAVE_RETRY, SAVE_RETRY_MS, nil);\nend;\n\nprocedure TLinkbarWcl.ShowSaveFailed(Sender: TObject);')

# --- declaraciones ---
s = rep(s, '    FLinksBaseDir: string;       // links folder of the main profile\n    FProfile: string;            // current profile (\'\' = main)\n',
           '    FProfiles: TProfileManager;  // profile folders (current profile \'\' = main)\n    FSaveQueue: TFileSaveQueue;  // list files write queue (retries when locked)\n')
s = rep(s, '    FPendingFiles: TStringList;   // files whose write failed (locked by Drive...), retried later\n    FPendingTexts: TStringList;   // content for each pending file (same index)\n    FSaveRetries: Integer;\n', '')
s = rep(s, '    function WriteLinesFile(const AFileName, AText: string; const ATries: Integer): Boolean;\n    procedure ForgetPendingSave(const AFileName: string);\n    procedure QueueSave(const AFileName, AText: string);\n    procedure RetryPendingSaves;\n', '')
s = rep(s, '    function ProfilesDir: string;\n    function ProfileDir(const AName: string): string;\n    function GetProfileNames: TArray<string>;\n', '')
s = rep(s, '  SAVE_RETRY_MAX = 6;\n', '')

# --- usos ---
s = rep(s, 'QueueSave(', 'FSaveQueue.Save(', 0)
s = rep(s, 'ForgetPendingSave(', 'FSaveQueue.Forget(', 0)
s = rep(s, 'GetProfileNames', 'FProfiles.Names', 0)
s = rep(s, 'ValidProfileName(', 'TProfileManager.IsValidName(', 0)
s = rep(s, 'ProfileDir(', 'FProfiles.ProfileDir(', 0)
s = s.replace('FProfiles.FProfiles.', 'FProfiles.')
s = rep(s, 'FLinksBaseDir', 'FProfiles.BaseDir', 0)
import re
s = re.sub(r'\bFProfile\b', 'FProfiles.Current', s)

# --- timer ---
s = rep(s, '          TIMER_SAVE_RETRY:\n            begin\n              RetryPendingSaves;\n',
           '          TIMER_SAVE_RETRY:\n            begin\n              KillTimer(Handle, TIMER_SAVE_RETRY);\n              if Assigned(FSaveQueue)\n              then FSaveQueue.Retry;\n')

# --- FormCreate / FormDestroy ---
s = rep(s, '  TMenuBorderHook.Install;\n',
        '  TMenuBorderHook.Install;\n  FProfiles := TProfileManager.Create;\n  FSaveQueue := TFileSaveQueue.Create;\n  FSaveQueue.OnScheduleRetry := SaveRetryScheduled;\n  FSaveQueue.OnFailed := ShowSaveFailed;\n')
s = rep(s, '  FreeAndNil(FPendingFiles);\n  FreeAndNil(FPendingTexts);\n', '  FreeAndNil(FSaveQueue);\n  FreeAndNil(FProfiles);\n')
s = rep(s, 'Linkbar.IconPicker, Linkbar.Bar.MenuHook;', 'Linkbar.IconPicker, Linkbar.Bar.MenuHook,\n  Linkbar.Bar.SaveQueue, Linkbar.Bar.Profiles;')
open(p, 'wb').write(s.replace('\n', '\r\n').encode('utf-8'))

d = 'Linkbar.dproj'
t = open(d, 'rb').read().decode('utf-8')
k = '        <DCCReference Include="Linkbar.Bar.MenuHook.pas"/>'
nl = '\r\n' if '\r\n' in t else '\n'
t = t.replace(k, k + nl + '        <DCCReference Include="Linkbar.Bar.SaveQueue.pas"/>' + nl + '        <DCCReference Include="Linkbar.Bar.Profiles.pas"/>', 1)
open(d, 'wb').write(t.encode('utf-8'))
