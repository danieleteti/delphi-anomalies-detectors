// ***************************************************************************
//
// Copyright (c) 2025 Daniele Teti - All Rights Reserved
//
// Anomaly Detection Performance Monitor
// Tracks metrics, throughput, and accuracy
//
// ***************************************************************************

unit AnomalyDetection.Performance;

interface

uses
  System.SysUtils, System.SyncObjs, System.DateUtils, System.Math, System.StrUtils,
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF}
  AnomalyDetection.Types;

type
  /// <summary>
  /// Performance monitor for detectors
  /// </summary>
  TDetectorPerformanceMonitor = class
  private
    FMetrics: TDetectorMetrics;
    FLock: TCriticalSection;
    FStartTime: TDateTime;
    FEnabled: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    procedure StartMeasurement;
    procedure StopMeasurement(AIsAnomaly: Boolean);
    procedure RecordGroundTruth(AActualAnomaly, APredictedAnomaly: Boolean);
    procedure UpdateMemoryUsage;
    procedure Reset;

    function GetCurrentMetrics: TDetectorMetrics;
    function GetReport: string;

    property Enabled: Boolean read FEnabled write FEnabled;
    property Metrics: TDetectorMetrics read FMetrics;
  end;

implementation

{ TDetectorPerformanceMonitor }

constructor TDetectorPerformanceMonitor.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FEnabled := True;
  FMetrics.Reset;
end;

destructor TDetectorPerformanceMonitor.Destroy;
begin
  FLock.Free;
  inherited Destroy;
end;

procedure TDetectorPerformanceMonitor.StartMeasurement;
begin
  if not FEnabled then Exit;

  FLock.Enter;
  try
    FStartTime := Now;
  finally
    FLock.Leave;
  end;
end;

procedure TDetectorPerformanceMonitor.StopMeasurement(AIsAnomaly: Boolean);
var
  ElapsedMs: Int64;
begin
  if not FEnabled then Exit;

  FLock.Enter;
  try
    ElapsedMs := MilliSecondsBetween(Now, FStartTime);

    Inc(FMetrics.TotalDetections);
    FMetrics.TotalProcessingTimeMs := FMetrics.TotalProcessingTimeMs + ElapsedMs;

    if ElapsedMs < FMetrics.MinProcessingTimeMs then
      FMetrics.MinProcessingTimeMs := ElapsedMs;
    if ElapsedMs > FMetrics.MaxProcessingTimeMs then
      FMetrics.MaxProcessingTimeMs := ElapsedMs;

    FMetrics.AverageProcessingTimeMs := FMetrics.TotalProcessingTimeMs / FMetrics.TotalDetections;

    if AIsAnomaly then
      Inc(FMetrics.AnomaliesDetected)
    else
      Inc(FMetrics.NormalValuesDetected);

    // Calculate throughput
    var TotalSeconds := FMetrics.TotalProcessingTimeMs / 1000;
    if TotalSeconds > 0 then
      FMetrics.ThroughputPerSecond := FMetrics.TotalDetections / TotalSeconds;

    FMetrics.LastUpdateTime := Now;
  finally
    FLock.Leave;
  end;
end;

procedure TDetectorPerformanceMonitor.RecordGroundTruth(AActualAnomaly, APredictedAnomaly: Boolean);
begin
  if not FEnabled then Exit;

  FLock.Enter;
  try
    if AActualAnomaly and APredictedAnomaly then
      Inc(FMetrics.TruePositives)
    else if AActualAnomaly and not APredictedAnomaly then
      Inc(FMetrics.FalseNegatives)
    else if not AActualAnomaly and APredictedAnomaly then
      Inc(FMetrics.FalsePositives)
    else
      Inc(FMetrics.TrueNegatives);
  finally
    FLock.Leave;
  end;
end;

procedure TDetectorPerformanceMonitor.UpdateMemoryUsage;
begin
  if not FEnabled then Exit;

  FLock.Enter;
  try
    {$IFDEF MSWINDOWS}
    {$WARN SYMBOL_PLATFORM OFF}
    var MemInfo: TMemoryManagerState;
    GetMemoryManagerState(MemInfo);
    {$WARN SYMBOL_PLATFORM ON}
    FMetrics.MemoryUsageBytes := MemInfo.TotalAllocatedMediumBlockSize +
                                MemInfo.TotalAllocatedLargeBlockSize;
    {$ELSE}
    // Placeholder for other platforms
    FMetrics.MemoryUsageBytes := 0;
    {$ENDIF}
  finally
    FLock.Leave;
  end;
end;

procedure TDetectorPerformanceMonitor.Reset;
begin
  FLock.Enter;
  try
    FMetrics.Reset;
  finally
    FLock.Leave;
  end;
end;

function TDetectorPerformanceMonitor.GetCurrentMetrics: TDetectorMetrics;
begin
  FLock.Enter;
  try
    Result := FMetrics;
  finally
    FLock.Leave;
  end;
end;

function TDetectorPerformanceMonitor.GetReport: string;
var
  Metrics: TDetectorMetrics;
begin
  Metrics := GetCurrentMetrics;

  Result := Format(
    'PERFORMANCE REPORT'#13#10 +
    '=================='#13#10 +
    'Total Detections: %d'#13#10 +
    'Anomalies: %d (%.1f%%)'#13#10 +
    'Normal Values: %d (%.1f%%)'#13#10 +
    'Average Processing Time: %.2f ms'#13#10 +
    'Min/Max Processing Time: %d/%d ms'#13#10 +
    'Throughput: %.1f detections/sec'#13#10 +
    'Memory Usage: %.1f KB'#13#10,
    [
      Metrics.TotalDetections,
      Metrics.AnomaliesDetected,
      IfThen(Metrics.TotalDetections > 0, (Metrics.AnomaliesDetected / Metrics.TotalDetections) * 100, 0),
      Metrics.NormalValuesDetected,
      IfThen(Metrics.TotalDetections > 0, (Metrics.NormalValuesDetected / Metrics.TotalDetections) * 100, 0),
      Metrics.AverageProcessingTimeMs,
      Metrics.MinProcessingTimeMs,
      Metrics.MaxProcessingTimeMs,
      Metrics.ThroughputPerSecond,
      Metrics.MemoryUsageBytes / 1024
    ]
  );

  // Add accuracy metrics if available
  if (Metrics.TruePositives + Metrics.FalsePositives + Metrics.TrueNegatives + Metrics.FalseNegatives) > 0 then
  begin
    Result := Result + #13#10 +
      'ACCURACY METRICS'#13#10 +
      '================'#13#10 +
      Format('Accuracy: %.2f%%'#13#10, [Metrics.GetAccuracy * 100]) +
      Format('Precision: %.2f%%'#13#10, [Metrics.GetPrecision * 100]) +
      Format('Recall: %.2f%%'#13#10, [Metrics.GetRecall * 100]) +
      Format('F1-Score: %.2f%%'#13#10, [Metrics.GetF1Score * 100]) +
      Format('False Positive Rate: %.2f%%'#13#10, [Metrics.GetFalsePositiveRate * 100]) +
      Format('False Negative Rate: %.2f%%'#13#10, [Metrics.GetFalseNegativeRate * 100]);
  end;
end;

end.
