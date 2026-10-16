{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   CPU / RAM widgets at the end of the bar: sampling   }
{   of the system load, layout and drawing, and the     }
{   rectangle of the ">>" / "<<" collapse button        }
{*******************************************************}

unit Linkbar.Bar.SysWidgets;

{$i linkbar.inc}

interface

uses
  Windows, Types,
  Linkbar.Graphics, Linkbar.Bar.Host;

type
  TSysWidgets = class
  private
    FHost: ILinkbarHost;
    FEnabled: Boolean;
    FCpuLoad, FRamLoad: Integer;       // 0..100
    FPrevIdle, FPrevKernel, FPrevUser: UInt64;
    FCollapseRect: TRect;              // interactive area of the ">>" / "<<" button
    FCollapseHot: Boolean;             // the mouse is over the button
  public
    constructor Create(const AHost: ILinkbarHost);
    // Reads the current CPU and RAM load
    procedure Sample;
    // Space kept at the end of the bar (0 when the widgets are off)
    function ReservedLength(const AVertical: Boolean): Integer;
    // Area of the widgets inside a bar of the given size
    function WidgetRect(const AWidth, AHeight: Integer): TRect;
    procedure Draw(const ABitmap: THBitmap; const AWidth, AHeight: Integer);
    property Enabled: Boolean read FEnabled write FEnabled;
    property CpuLoad: Integer read FCpuLoad;
    property RamLoad: Integer read FRamLoad;
    property CollapseRect: TRect read FCollapseRect;
    property CollapseHot: Boolean read FCollapseHot write FCollapseHot;
  end;

implementation

uses
  SysUtils, Math, Graphics, Forms, Themes, GdiPlus, Linkbar.Consts, Linkbar.Theme;

const
  SYSWIDGET_COUNT = 2; // CPU, RAM

function LB_GetSystemTimes(out AIdleTime, AKernelTime, AUserTime: TFileTime): BOOL; stdcall;
  external kernel32 name 'GetSystemTimes';

function FileTimeToUInt64(const AFt: TFileTime): UInt64; inline;
begin
  Result := (UInt64(AFt.dwHighDateTime) shl 32) or AFt.dwLowDateTime;
end;

constructor TSysWidgets.Create(const AHost: ILinkbarHost);
begin
  inherited Create;
  FHost := AHost;
end;

{ Space kept at the end of the bar }
function TSysWidgets.ReservedLength(const AVertical: Boolean): Integer;
begin
  if not FEnabled
  then Exit(0);
  if AVertical
  then Result := SYSWIDGET_COUNT * Max(FHost.BarButtonSize.cy, FHost.ScaleValue(40)) + FHost.ScaleValue(8) + FHost.ScaleValue(24)
  else Result := SYSWIDGET_COUNT * Max(FHost.BarButtonSize.cx, FHost.ScaleValue(56)) + FHost.ScaleValue(8) + FHost.ScaleValue(24);
end;

function TSysWidgets.WidgetRect(const AWidth, AHeight: Integer): TRect;
var len: Integer;
begin
  len := ReservedLength(FHost.BarIsVertical);
  if (len = 0)
  then Exit(TRect.Empty);
  if FHost.BarIsVertical
  then Result := Rect(0, AHeight - len, AWidth, AHeight)
  else Result := Rect(AWidth - len, 0, AWidth, AHeight);
end;

procedure TSysWidgets.Sample;
var
  idleFt, kernelFt, userFt: TFileTime;
  idle, kernel, user, dIdle, dTotal: UInt64;
  mem: TMemoryStatusEx;
begin
  // CPU: (busy time) / (total time) since last sample
  if LB_GetSystemTimes(idleFt, kernelFt, userFt)
  then begin
    idle := FileTimeToUInt64(idleFt);
    kernel := FileTimeToUInt64(kernelFt); // includes idle
    user := FileTimeToUInt64(userFt);
    if (FPrevKernel <> 0)
    then begin
      dIdle := idle - FPrevIdle;
      dTotal := (kernel - FPrevKernel) + (user - FPrevUser);
      if (dTotal > 0)
      then FCpuLoad := EnsureRange(Integer(Round(100.0 * (dTotal - dIdle) / dTotal)), 0, 100);
    end;
    FPrevIdle := idle;
    FPrevKernel := kernel;
    FPrevUser := user;
  end;

  // RAM
  FillChar(mem, SizeOf(mem), 0);
  mem.dwLength := SizeOf(mem);
  if GlobalMemoryStatusEx(mem)
  then FRamLoad := EnsureRange(Integer(mem.dwMemoryLoad), 0, 100);
end;

procedure TSysWidgets.Draw(const ABitmap: THBitmap; const AWidth, AHeight: Integer);
const
  CAPTIONS: array[0..SYSWIDGET_COUNT-1] of string = ('CPU', 'RAM');
  COLORS: array[0..SYSWIDGET_COUNT-1] of Cardinal = ($FF3B82F6, $FF22C55E); // blue, green
  COLOR_HIGH: Cardinal = $FFEF4444; // red when > 85%
var
  area, cell, bar, fill, tr: TRect;
  i, value, pad, barW, barH, cellLen, zoff: Integer;
  vertical: Boolean;
  gp: IGPGraphics;
  brushTrack, brushFill: IGPBrush;
  trackColor, fillColor: Cardinal;
  textColor: TColor;
  dc: HDC;
  fnt0: HGDIOBJ;
  s: string;
  bs: TSize;
begin
  bs := FHost.BarButtonSize;
  if not FEnabled
  then Exit;
  area := WidgetRect(AWidth, AHeight);
  if area.IsEmpty
  then Exit;

  vertical := FHost.BarIsVertical;
  if vertical then begin
    FCollapseRect := Rect(area.Left, area.Top, area.Right, area.Top + FHost.ScaleValue(24));
    area.Top := FCollapseRect.Bottom;
  end else begin
    FCollapseRect := Rect(area.Left, area.Top, area.Left + FHost.ScaleValue(24), area.Bottom);
    area.Left := FCollapseRect.Right;
  end;

  pad := FHost.ScaleValue(4);
  barW := Max(3, FHost.ScaleValue(5));
  zoff := FHost.ZoomExtra div 2;  // items are centered in the extra zoom thickness
  if vertical
  then cellLen := (area.Height - pad * 2) div SYSWIDGET_COUNT
  else cellLen := (area.Width - pad * 2) div SYSWIDGET_COUNT;

  if (GlobalLook = ELookLight)
  then trackColor := $33000000
  else trackColor := $33FFFFFF;

  // Text color always readable on the bar: white on dark/accent, black on light
  // (the custom item text color may be dark, e.g. black, and disappear on a dark bar)
  if (GlobalLook = ELookLight)
  then textColor := clBlack
  else textColor := RGB(165, 180, 192); // gris azulado suave (menos brillo que blanco)

  dc := ABitmap.Dc;

  // 1) Bars (GDI+)
  gp := TGPGraphics.Create(dc);
  brushTrack := TGPSolidBrush.Create(trackColor);
  try
    for i := 0 to SYSWIDGET_COUNT-1 do
    begin
      if (i = 0)
      then value := FCpuLoad
      else value := FRamLoad;

      // Cell (only the button-height part of the first line is used)
      if vertical
      then cell := Rect(area.Left + zoff, area.Top + pad + i * cellLen, area.Left + zoff + bs.cx, area.Top + pad + (i + 1) * cellLen)
      else cell := Rect(area.Left + pad + i * cellLen, area.Top + zoff, area.Left + pad + (i + 1) * cellLen, area.Top + zoff + bs.cy);

      // Vertical bar (track + fill from the bottom)
      barH := Min(cell.Height - pad * 2, FHost.ScaleValue(32));
      bar := Bounds(cell.Left + pad, cell.Top + (cell.Height - barH) div 2, barW, barH);
      GPFillRoundRect(gp, brushTrack, bar, barW div 2);

      fill := bar;
      fill.Top := bar.Bottom - Round(bar.Height * value / 100);
      if (fill.Height > 0)
      then begin
        if (value > 85)
        then fillColor := COLOR_HIGH
        else fillColor := COLORS[i];
        brushFill := TGPSolidBrush.Create(fillColor);
        GPFillRoundRect(gp, brushFill, fill, barW div 2);
      end;
    end;

    if (not FCollapseRect.IsEmpty) and FCollapseHot then
    begin
      tr := FCollapseRect;
      InflateRect(tr, -2, -2);
      brushFill := TGPSolidBrush.Create($22FFFFFF);
      GPFillRoundRect(gp, brushFill, tr, 4);
    end;

    // ">>" / "<<" icon: two chevrons drawn with GDI+ (visible but muted)
    if not FCollapseRect.IsEmpty then
    begin
      var chevColor: Cardinal;
      if (GlobalLook = ELookLight)
      then begin
        if FCollapseHot then chevColor := $FF222222 else chevColor := $FF666666;
      end
      else begin
        if FCollapseHot then chevColor := $FFD2DEE9 else chevColor := $FF8696A6;
      end;

      const chevW = Single(Max(3, FHost.ScaleValue(4)));    // chevron width
      const chevH = Single(Max(4, FHost.ScaleValue(5)));    // half height
      const chevGap = Single(Max(3, FHost.ScaleValue(4)));  // space between the two chevrons
      const totalW = chevW * 2 + chevGap;
      var chevCx, chevCy: Single;
      if vertical
      then begin
        chevCx := FCollapseRect.Left + zoff + bs.cx / 2;
        chevCy := (FCollapseRect.Top + FCollapseRect.Bottom) / 2;
      end
      else begin
        chevCx := (FCollapseRect.Left + FCollapseRect.Right) / 2;
        chevCy := FCollapseRect.Top + zoff + bs.cy / 2;
      end;

      gp.SmoothingMode := SmoothingModeAntiAlias;
      var chevPen: IGPPen := TGPPen.Create(chevColor, Max(1.8, FHost.ScaleValue(2) * 1.0));
      chevPen.StartCap := LineCapRound;
      chevPen.EndCap := LineCapRound;
      chevPen.LineJoin := LineJoinRound;

      for var k := 0 to 1
      do begin
        var x0: Single := chevCx - totalW / 2 + k * (chevW + chevGap);
        if FHost.BarIsCollapsed
        then gp.DrawLines(chevPen, [TGPPointF.Create(x0 + chevW, chevCy - chevH),
                                    TGPPointF.Create(x0, chevCy),
                                    TGPPointF.Create(x0 + chevW, chevCy + chevH)])
        else gp.DrawLines(chevPen, [TGPPointF.Create(x0, chevCy - chevH),
                                    TGPPointF.Create(x0 + chevW, chevCy),
                                    TGPPointF.Create(x0, chevCy + chevH)]);
      end;
    end;

  finally
    brushFill := nil;
    brushTrack := nil;
    gp := nil;
  end;

  // 2) Text (GDI, glass text like item captions)
  if not StyleServices.Enabled
  then Exit;
  fnt0 := SelectObject(dc, Screen.IconFont.Handle);
  try
    for i := 0 to SYSWIDGET_COUNT-1 do
    begin
      if (i = 0)
      then value := FCpuLoad
      else value := FRamLoad;

      if vertical
      then cell := Rect(area.Left + zoff, area.Top + pad + i * cellLen, area.Left + zoff + bs.cx, area.Top + pad + (i + 1) * cellLen)
      else cell := Rect(area.Left + pad + i * cellLen, area.Top + zoff, area.Left + pad + (i + 1) * cellLen, area.Top + zoff + bs.cy);
      barH := Min(cell.Height - pad * 2, FHost.ScaleValue(32));
      bar := Bounds(cell.Left + pad, cell.Top + (cell.Height - barH) div 2, barW, barH);

      // Caption (top half) and value (bottom half)
      tr := Rect(bar.Right + pad, bar.Top - pad, cell.Right, bar.Top + bar.Height div 2);
      s := CAPTIONS[i];
      DrawGlassText(dc, s, tr, DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX, 0, textColor);
      tr := Rect(bar.Right + pad, bar.Top + bar.Height div 2, cell.Right, bar.Bottom + pad);
      s := IntToStr(value) + '%';
      DrawGlassText(dc, s, tr, DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX, 0, textColor);
    end;

  finally
    SelectObject(dc, fnt0);
  end;
end;

end.
