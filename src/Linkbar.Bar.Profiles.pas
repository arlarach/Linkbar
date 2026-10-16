{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   Profiles: each profile is a folder of links inside  }
{   "profiles" under the links folder of the main one   }
{*******************************************************}

unit Linkbar.Bar.Profiles;

{$i linkbar.inc}

interface

type
  TProfileManager = class
  private
    FBaseDir: string;
    FCurrent: string;
  public
    // Name of a valid profile (not empty, no path characters)
    class function IsValidName(const AName: string): Boolean;
    function ProfilesDir: string;
    // Folder of a profile; '' = the main profile
    function ProfileDir(const AName: string): string;
    function Names: TArray<string>;
    // Name of the profile ADelta positions away, cycling (main = '')
    function Neighbour(const ADelta: Integer): string;
    // Links folder of the main profile
    property BaseDir: string read FBaseDir write FBaseDir;
    // Current profile ('' = main)
    property Current: string read FCurrent write FCurrent;
  end;

implementation

uses
  SysUtils, Classes, Linkbar.Consts;

class function TProfileManager.IsValidName(const AName: string): Boolean;
const InvalidChars = '\/:*?"<>|';
var ch: Char;
begin
  Result := (AName <> '') and (AName <> '.') and (AName <> '..');
  if Result then
    for ch in InvalidChars do
      if (Pos(ch, AName) > 0) then Exit(False);
end;

function TProfileManager.ProfilesDir: string;
begin
  Result := IncludeTrailingPathDelimiter(FBaseDir) + PROFILES_DIR_NAME + '\';
end;

function TProfileManager.ProfileDir(const AName: string): string;
begin
  if (AName = '')
  then Result := IncludeTrailingPathDelimiter(FBaseDir)
  else Result := ProfilesDir + AName + '\';
end;

function TProfileManager.Names: TArray<string>;
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

function TProfileManager.Neighbour(const ADelta: Integer): string;
var all: TArray<string>;
    i, cur: Integer;
begin
  all := [''] + Names;
  if (Length(all) < 2)
  then Exit(FCurrent);
  cur := 0;
  for i := 0 to High(all) do
    if SameText(all[i], FCurrent) then cur := i;
  cur := (cur + ADelta + Length(all)) mod Length(all);
  Result := all[cur];
end;

end.
