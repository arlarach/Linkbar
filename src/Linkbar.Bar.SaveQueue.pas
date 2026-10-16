{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   Write queue for the bar list files: writes only     }
{   when the content changed and retries when the file  }
{   is locked (Drive, OneDrive)                         }
{*******************************************************}

unit Linkbar.Bar.SaveQueue;

{$i linkbar.inc}

interface

uses
  Classes;

type
  TFileSaveQueue = class
  private
    FPendingFiles: TStringList;   // files whose write failed, retried later
    FPendingTexts: TStringList;   // content for each pending file (same index)
    FRetries: Integer;
    FOnScheduleRetry: TNotifyEvent;
    FOnFailed: TNotifyEvent;
    function WriteLinesFile(const AFileName, AText: string; const ATries: Integer): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    // Write only when the content changed; if the file stays locked keep it pending
    procedure Save(const AFileName, AText: string);
    // Cancel a pending write of a file
    procedure Forget(const AFileName: string);
    // Called by the host when the retry timer fires (the host stops the timer first)
    procedure Retry;
    // The host must start the retry timer
    property OnScheduleRetry: TNotifyEvent read FOnScheduleRetry write FOnScheduleRetry;
    // Gave up after the maximum number of retries
    property OnFailed: TNotifyEvent read FOnFailed write FOnFailed;
  end;

implementation

uses
  SysUtils, Windows;

const
  SAVE_RETRY_MAX = 6;

constructor TFileSaveQueue.Create;
begin
  inherited Create;
  FPendingFiles := TStringList.Create;
  FPendingTexts := TStringList.Create;
end;

destructor TFileSaveQueue.Destroy;
begin
  FPendingFiles.Free;
  FPendingTexts.Free;
  inherited;
end;

{ The folder may be synced (Drive, OneDrive) and the file locked for a moment }
function TFileSaveQueue.WriteLinesFile(const AFileName, AText: string; const ATries: Integer): Boolean;
begin
  var sl := TStringList.Create;
  try
    sl.Text := AText;
    for var attempt := 1 to ATries
    do begin
      try
        sl.SaveToFile(AFileName, TEncoding.UTF8);
        Exit(True);
      except
        if (attempt < ATries)
        then Sleep(150);
      end;
    end;
    Result := False;
  finally
    sl.Free;
  end;
end;

procedure TFileSaveQueue.Forget(const AFileName: string);
begin
  var i := FPendingFiles.IndexOf(AFileName);
  if (i >= 0)
  then begin
    FPendingFiles.Delete(i);
    FPendingTexts.Delete(i);
  end;
end;

procedure TFileSaveQueue.Save(const AFileName, AText: string);
begin
  if FileExists(AFileName)
  then begin
    var current := TStringList.Create;
    try
      try
        current.LoadFromFile(AFileName, TEncoding.UTF8);
        if (current.Text = AText)
        then begin
          Forget(AFileName);
          Exit;
        end;
      except
        // locked: try to write anyway
      end;
    finally
      current.Free;
    end;
  end;

  if WriteLinesFile(AFileName, AText, 5)
  then begin
    Forget(AFileName);
    Exit;
  end;

  var i := FPendingFiles.IndexOf(AFileName);
  if (i >= 0)
  then FPendingTexts[i] := AText
  else begin
    FPendingFiles.Add(AFileName);
    FPendingTexts.Add(AText);
  end;
  FRetries := 0;
  if Assigned(FOnScheduleRetry)
  then FOnScheduleRetry(Self);
end;

procedure TFileSaveQueue.Retry;
begin
  for var i := FPendingFiles.Count-1 downto 0
  do begin
    if WriteLinesFile(FPendingFiles[i], FPendingTexts[i], 1)
    then begin
      FPendingFiles.Delete(i);
      FPendingTexts.Delete(i);
    end;
  end;

  if (FPendingFiles.Count = 0)
  then Exit;

  Inc(FRetries);
  if (FRetries < SAVE_RETRY_MAX)
  then begin
    if Assigned(FOnScheduleRetry)
    then FOnScheduleRetry(Self);
  end
  else begin
    FPendingFiles.Clear;
    FPendingTexts.Clear;
    if Assigned(FOnFailed)
    then FOnFailed(Self);
  end;
end;

end.
