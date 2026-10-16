{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   Live thumbnails of the windows of an open program,  }
{   shown when the mouse stays on its icon              }
{*******************************************************}

unit Linkbar.Bar.Thumbs;

{$i linkbar.inc}

interface

uses
  Windows, Types, Vcl.Forms,
  Linkbar.Bar.Host;

const
  TIMER_THUMBS = 19;

type
  // What the thumbnails need from the bar window
  IThumbsHost = interface(ILinkbarHost)
    ['{C84A6E19-3F52-47D0-B1A8-5D29E0F7134C}']
    function BarIsItem(const AIndex: Integer): Boolean;
    function BarItemRunning(const AIndex: Integer): Boolean;
    function BarItemTarget(const AIndex: Integer): string;
    // Rectangle of the item in the bar (client coordinates)
    function BarItemRect(const AIndex: Integer): TRect;
    // Dragging, locked or auto hidden: no thumbnails
    function BarThumbsBlocked: Boolean;
  end;

  TThumbController = class
  private
    FHost: IThumbsHost;
    FForm: TForm;                 // thumbnails popup (Linkbar.ThumbForm)
    FIndex: Integer;
    procedure FormDestroyed(Sender: TObject);
  public
    constructor Create(const AHost: IThumbsHost);
    destructor Destroy; override;
    // Hot item changed: schedule the thumbnails for an open program
    procedure HotChanged;
    procedure Show(const AIndex: Integer);
    procedure Close;
  end;

implementation

uses
  LBToolbar, Linkbar.ThumbForm;

constructor TThumbController.Create(const AHost: IThumbsHost);
begin
  inherited Create;
  FHost := AHost;
end;

destructor TThumbController.Destroy;
begin
  // the popup belongs to the bar window: it is destroyed with it
  if Assigned(FForm)
  then FForm.OnDestroy := nil;
  FForm := nil;
  inherited;
end;

procedure TThumbController.FormDestroyed(Sender: TObject);
begin
  if (FForm = Sender)
  then FForm := nil;
end;

procedure TThumbController.HotChanged;
var hot: Integer;
begin
  FHost.BarStopTimer(TIMER_THUMBS);
  hot := FHost.BarHotIndex;

  // moved to another item: close the current preview
  if Assigned(FForm) and FHost.BarIsItem(hot) and (hot <> FIndex)
  then Close;

  if FHost.BarIsItem(hot)
     and (not Assigned(FForm))
     and FHost.BarItemRunning(hot)
     and (FHost.BarItemTarget(hot) <> '')
  then FHost.BarStartTimer(TIMER_THUMBS, 500);
end;

procedure TThumbController.Show(const AIndex: Integer);
var
  wnds: TArray<HWND>;
  r: TRect;
  form: TFormThumbs;
begin
  if (not FHost.BarIsItem(AIndex))
     or (not FHost.BarItemRunning(AIndex))
     or FHost.BarThumbsBlocked
     or Assigned(FForm)
  then Exit;

  wnds := GetProgramWindows(FHost.BarItemTarget(AIndex));
  if (Length(wnds) = 0)
  then Exit;

  FHost.BarCancelTooltip;
  r := FHost.BarItemRect(AIndex);
  MapWindowPoints(FHost.BarHandle, HWND_DESKTOP, r, 2);

  form := TFormThumbs.CreateThumbs(FHost.BarOwner, FHost.BarHandle, wnds, FHost.BarIsVertical);
  form.OnDestroy := FormDestroyed;
  FForm := form;
  FIndex := AIndex;
  form.PopupAt(r, FHost.BarAlign);
end;

procedure TThumbController.Close;
begin
  FHost.BarStopTimer(TIMER_THUMBS);
  if Assigned(FForm)
  then begin
    FForm.OnDestroy := nil;
    FForm.Close;
    FForm := nil;
  end;
end;

end.
