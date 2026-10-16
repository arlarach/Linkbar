{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   CPU temperature: read in a thread of its own (WMI   }
{   is slow) from LibreHardwareMonitor / Open Hardware  }
{   Monitor when they run, or from the thermal zone     }
{   that Windows exposes                                }
{*******************************************************}

unit Linkbar.Bar.CpuTemp;

{$i linkbar.inc}

interface

uses
  System.Classes, System.SyncObjs;

const
  NO_TEMPERATURE = -1000;  // no sensor gave a value

type
  TCpuTemperature = class
  private
    FValue: Integer;       // degrees Celsius; read and written without locks
    FStop: TEvent;
    FThread: TThread;
  public
    constructor Create;
    destructor Destroy; override;
    // Starts reading the temperature every few seconds
    procedure Start;
    procedure Stop;
    // Last temperature in degrees Celsius, NO_TEMPERATURE when there is none
    function Value: Integer;
    function Available: Boolean;
  end;

implementation

uses
  Winapi.Windows, Winapi.ActiveX, System.SysUtils, System.Variants, System.Win.ComObj;

const
  POLL_MS = 3000;
  MIN_VALID = 1;    // degrees Celsius considered a real reading
  MAX_VALID = 130;

type
  TPollThread = class(TThread)
  private
    FOwner: TCpuTemperature;
  protected
    procedure Execute; override;
  public
    constructor Create(const AOwner: TCpuTemperature);
  end;

{ ---------- WMI ---------- }

{ Connects to a WMI namespace; Unassigned when it does not exist }
function ConnectNamespace(const ANamespace: string): OleVariant;
var
  locator: OleVariant;
begin
  Result := Unassigned;
  try
    locator := CreateOleObject('WbemScripting.SWbemLocator');
    Result := locator.ConnectServer('.', ANamespace);
  except
    Result := Unassigned;
  end;
end;

function IsValidCelsius(const AValue: Double): Boolean;
begin
  Result := (AValue >= MIN_VALID) and (AValue <= MAX_VALID);
end;

{ LibreHardwareMonitor and Open Hardware Monitor publish their sensors with the same schema.
  Preferred: CPU Package (Intel) or Core (Tctl/Tdie) (AMD); otherwise the hottest CPU sensor }
function ReadHardwareMonitor(const ANamespace: string): Integer;
var
  service, rs, item: OleVariant;
  enum: IEnumVariant;
  got: LongWord;
  name, ident: string;
  value, best, preferred: Double;
begin
  Result := NO_TEMPERATURE;
  service := ConnectNamespace(ANamespace);
  if VarIsEmpty(service) or VarIsNull(service)
  then Exit;
  try
    rs := service.ExecQuery('SELECT Name, Identifier, Value FROM Sensor WHERE SensorType = ''Temperature''');
    enum := IUnknown(rs._NewEnum) as IEnumVariant;
    best := -1;
    preferred := -1;
    while (enum.Next(1, item, got) = S_OK) do
    begin
      name := VarToStr(item.Name);
      ident := LowerCase(VarToStr(item.Identifier));
      if not VarIsNull(item.Value)
      then begin
        value := item.Value;
        if IsValidCelsius(value)
           and (ident.StartsWith('/intelcpu') or ident.StartsWith('/amdcpu'))
        then begin
          if (value > best)
          then best := value;
          if SameText(name, 'CPU Package') or SameText(name, 'Core (Tctl/Tdie)')
          then preferred := value;
        end;
      end;
      item := Unassigned;
    end;
    if (preferred >= 0)
    then Result := Round(preferred)
    else if (best >= 0)
    then Result := Round(best);
  except
    Result := NO_TEMPERATURE;
  end;
end;

{ Thermal zone of Windows (ACPI): temperature in Kelvin, no administrator rights needed.
  Many computers do not have it and others report the chassis, not the processor }
function ReadThermalZone: Integer;
var
  service, rs, item: OleVariant;
  enum: IEnumVariant;
  got: LongWord;
  celsius, best: Double;
begin
  Result := NO_TEMPERATURE;
  service := ConnectNamespace('root\cimv2');
  if VarIsEmpty(service) or VarIsNull(service)
  then Exit;
  try
    rs := service.ExecQuery('SELECT Temperature FROM Win32_PerfFormattedData_Counters_ThermalZoneInformation');
    enum := IUnknown(rs._NewEnum) as IEnumVariant;
    best := -1;
    while (enum.Next(1, item, got) = S_OK) do
    begin
      if not VarIsNull(item.Temperature)
      then begin
        celsius := Double(item.Temperature) - 273.15;
        if IsValidCelsius(celsius) and (celsius > best)
        then best := celsius;
      end;
      item := Unassigned;
    end;
    if (best >= 0)
    then Result := Round(best);
  except
    Result := NO_TEMPERATURE;
  end;
end;

function ReadCpuTemperature: Integer;
begin
  Result := ReadHardwareMonitor('root\LibreHardwareMonitor');
  if (Result = NO_TEMPERATURE)
  then Result := ReadHardwareMonitor('root\OpenHardwareMonitor');
  if (Result = NO_TEMPERATURE)
  then Result := ReadThermalZone;
end;

{ ---------- thread ---------- }

constructor TPollThread.Create(const AOwner: TCpuTemperature);
begin
  inherited Create(False);
  FOwner := AOwner;
end;

procedure TPollThread.Execute;
var
  needUninit: Boolean;
begin
  needUninit := SUCCEEDED(CoInitializeEx(nil, COINIT_MULTITHREADED));
  try
    while not Terminated do
    begin
      TInterlocked.Exchange(FOwner.FValue, ReadCpuTemperature);
      if (FOwner.FStop.WaitFor(POLL_MS) = wrSignaled)
      then Break;
    end;
  finally
    if needUninit
    then CoUninitialize;
  end;
end;

{ ---------- TCpuTemperature ---------- }

constructor TCpuTemperature.Create;
begin
  inherited Create;
  FValue := NO_TEMPERATURE;
  FStop := TEvent.Create(nil, True, False, '');
end;

destructor TCpuTemperature.Destroy;
begin
  Stop;
  FStop.Free;
  inherited;
end;

procedure TCpuTemperature.Start;
begin
  if Assigned(FThread)
  then Exit;
  FStop.ResetEvent;
  FThread := TPollThread.Create(Self);
end;

procedure TCpuTemperature.Stop;
begin
  if Assigned(FThread)
  then begin
    FThread.Terminate;
    FStop.SetEvent;
    FThread.WaitFor;
    FreeAndNil(FThread);
  end;
  TInterlocked.Exchange(FValue, NO_TEMPERATURE);
end;

function TCpuTemperature.Value: Integer;
begin
  Result := TInterlocked.CompareExchange(FValue, NO_TEMPERATURE, NO_TEMPERATURE);
end;

function TCpuTemperature.Available: Boolean;
begin
  Result := (Value <> NO_TEMPERATURE);
end;

end.
