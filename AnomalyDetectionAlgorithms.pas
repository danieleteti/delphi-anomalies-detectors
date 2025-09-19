// ***************************************************************************
//
// Copyright (c) 2025 Daniele Teti - All Rights Reserved
//
// Unauthorized copying, distribution or use of this software, via any medium,
// is strictly prohibited without the prior written consent of the copyright
// holder. This software is proprietary and confidential.
//
// This demo application is provided exclusively to showcase the capabilities
// of the Anomaly Detection Algorithms Library and is intended for evaluation
// purposes only.
//
// To use this library in a commercial project, a separate commercial license
// must be purchased. For licensing information, please contact:
//   Daniele Teti
//   Email: d.teti@bittime.it
//   Website: https://www.bittimeprofessionals.com
//
// ***************************************************************************

unit AnomalyDetectionAlgorithms;

{
  Anomaly Detection Algorithms Unit - Extended Version
  Contains various statistical anomaly detection methods for business applications

  Algorithms Included:
  - Traditional 3-Sigma rule based on historical data
  - Sliding Window approach for continuous data streams
  - Exponential Moving Average for adaptive detection
  - Adaptive detector that learns from confirmed normal values
  - Isolation Forest for multi-dimensional anomaly detection
  - Confirmation system to reduce false positives

  Features:
  - Fixed standard deviation calculation (using sample formula N-1)
  - Improved performance for sliding window
  - Complete implementation of adaptive detector
  - Better edge case handling
  - Added configurable sigma multiplier
  - Thread safety with critical sections
  - State persistence support
  - Event notification system
  - Performance metrics and monitoring
  - Factory pattern for easy detector creation
  - Multi-dimensional data support
}

interface

uses
  System.SysUtils, System.Classes, System.Math, System.Generics.Collections,
  System.SyncObjs, System.DateUtils
  {$IFDEF MSWINDOWS}, Winapi.Windows{$ENDIF};

type
  /// <summary>
  /// Custom exception for anomaly detection errors
  /// </summary>
  EAnomalyDetectionException = class(Exception);

  /// <summary>
  /// Configuration for anomaly detection sensitivity
  /// </summary>
  TAnomalyDetectionConfig = record
    SigmaMultiplier: Double;  // Default 3.0 for 3-sigma rule
    MinStdDev: Double;        // Minimum std deviation to avoid false positives
    class function Default: TAnomalyDetectionConfig; static;
  end;

  /// <summary>
  /// Result of anomaly detection with detailed information
  /// </summary>
  TAnomalyResult = record
    IsAnomaly: Boolean;
    Value: Double;
    ZScore: Double;
    LowerLimit: Double;
    UpperLimit: Double;
    Description: string;
  end;

  /// <summary>
  /// Event types for anomaly detection
  /// </summary>
  TAnomalyEvent = (aeAnomalyDetected, aeNormalResumed, aeThresholdExceeded);

  /// <summary>
  /// Event arguments for anomaly notifications
  /// </summary>
  TAnomalyEventArgs = record
    EventType: TAnomalyEvent;
    Timestamp: TDateTime;
    Result: TAnomalyResult;
    DetectorName: string;
    AdditionalInfo: string;
  end;

  /// <summary>
  /// Event handler for anomaly detection
  /// </summary>
  TAnomalyDetectedEvent = procedure(Sender: TObject; const AEventArgs: TAnomalyEventArgs) of object;

  /// <summary>
  /// Performance metrics for anomaly detectors
  /// </summary>
  TDetectorMetrics = record
    TotalDetections: Int64;
    AnomaliesDetected: Int64;
    NormalValuesDetected: Int64;
    TotalProcessingTimeMs: Int64;
    AverageProcessingTimeMs: Double;
    MinProcessingTimeMs: Int64;
    MaxProcessingTimeMs: Int64;
    MemoryUsageBytes: Int64;
    ThroughputPerSecond: Double;
    // Ground truth metrics (if available)
    TruePositives: Int64;
    FalsePositives: Int64;
    TrueNegatives: Int64;
    FalseNegatives: Int64;
    LastUpdateTime: TDateTime;

    function GetAccuracy: Double;
    function GetPrecision: Double;
    function GetRecall: Double;
    function GetF1Score: Double;
    function GetFalsePositiveRate: Double;
    function GetFalseNegativeRate: Double;
    procedure Reset;
  end;

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

  // Forward declaration
  TBaseAnomalyDetector = class;

  /// <summary>
  /// Base class for all anomaly detection algorithms
  /// </summary>
  TBaseAnomalyDetector = class
  protected
    FName: string;
    FConfig: TAnomalyDetectionConfig;
    FLock: TCriticalSection;
    FOnAnomalyDetected: TAnomalyDetectedEvent;
    FLastAnomalyState: Boolean;
    FPerformanceMonitor: TDetectorPerformanceMonitor;
    procedure SaveConfigToStream(const AStream: TStream);
    procedure LoadConfigFromStream(const AStream: TStream);
    procedure NotifyAnomalyEvent(const AEventType: TAnomalyEvent; const AResult: TAnomalyResult);
  public
    constructor Create(const AName: string); overload;
    constructor Create(const AName: string; const AConfig: TAnomalyDetectionConfig); overload;
    destructor Destroy; override;
    function Detect(const AValue: Double): TAnomalyResult; virtual; abstract;
    function IsAnomaly(const AValue: Double): Boolean; virtual;
    function GetAnomalyInfo(const AValue: Double): string; virtual;
    procedure SaveState(const AStream: TStream); virtual; abstract;
    procedure LoadState(const AStream: TStream); virtual; abstract;
    procedure SaveToFile(const AFileName: string);
    procedure LoadFromFile(const AFileName: string);
    function GetPerformanceReport: string;
    property Name: string read FName;
    property Config: TAnomalyDetectionConfig read FConfig write FConfig;
    property OnAnomalyDetected: TAnomalyDetectedEvent read FOnAnomalyDetected write FOnAnomalyDetected;
    property PerformanceMonitor: TDetectorPerformanceMonitor read FPerformanceMonitor;
  end;

  /// <summary>
  /// Traditional 3-Sigma rule based on historical data
  /// </summary>
  TThreeSigmaDetector = class(TBaseAnomalyDetector)
  private
    FData: TArray<Double>;
    FMean: Double;
    FStdDev: Double;
    FLowerLimit: Double;
    FUpperLimit: Double;
    FIsCalculated: Boolean;
    procedure CalculateLimits;
  protected
    procedure CheckAndNotifyAnomaly(const AResult: TAnomalyResult);
  public
    constructor Create; overload;
    constructor Create(const AConfig: TAnomalyDetectionConfig); overload;
    procedure SetHistoricalData(const AData: TArray<Double>);
    procedure CalculateStatistics;
    function Detect(const AValue: Double): TAnomalyResult; override;
    procedure SaveState(const AStream: TStream); override;
    procedure LoadState(const AStream: TStream); override;
    property Mean: Double read FMean;
    property StdDev: Double read FStdDev;
    property LowerLimit: Double read FLowerLimit;
    property UpperLimit: Double read FUpperLimit;
  end;

  /// <summary>
  /// Sliding window approach for continuous data streams
  /// </summary>
  TSlidingWindowDetector = class(TBaseAnomalyDetector)
  private
    FWindowData: TList<Double>;
    FWindowSize: Integer;
    FMean: Double;
    FStdDev: Double;
    FLowerLimit: Double;
    FUpperLimit: Double;
    FSum: Double;
    FSumSquares: Double;
    FNeedsRecalculation: Boolean;
    procedure UpdateStatisticsIncremental(const AAddedValue, ARemovedValue: Double; AHasRemoved: Boolean);
    procedure RecalculateStatistics;
    procedure CalculateLimits;
  protected
    procedure CheckAndNotifyAnomaly(const AResult: TAnomalyResult);
  public
    constructor Create(AWindowSize: Integer = 100); overload;
    constructor Create(AWindowSize: Integer; const AConfig: TAnomalyDetectionConfig); overload;
    destructor Destroy; override;
    procedure AddValue(const AValue: Double);
    function Detect(const AValue: Double): TAnomalyResult; override;
    procedure SaveState(const AStream: TStream); override;
    procedure LoadState(const AStream: TStream); override;
    property CurrentMean: Double read FMean;
    property CurrentStdDev: Double read FStdDev;
    property WindowSize: Integer read FWindowSize;
    property LowerLimit: Double read FLowerLimit;
    property UpperLimit: Double read FUpperLimit;
  end;

  /// <summary>
  /// Exponential Moving Average for adaptive anomaly detection
  /// </summary>
  TEMAAnomalyDetector = class(TBaseAnomalyDetector)
  private
    FAlpha: Double;
    FCurrentMean: Double;
    FCurrentVariance: Double;
    FCurrentStdDev: Double;
    FInitialized: Boolean;
    FLowerLimit: Double;
    FUpperLimit: Double;
    procedure CalculateLimits;
  protected
    procedure CheckAndNotifyAnomaly(const AResult: TAnomalyResult);
  public
    constructor Create(AAlpha: Double = 0.1); overload;
    constructor Create(AAlpha: Double; const AConfig: TAnomalyDetectionConfig); overload;
    procedure AddValue(const AValue: Double);
    function Detect(const AValue: Double): TAnomalyResult; override;
    procedure SaveState(const AStream: TStream); override;
    procedure LoadState(const AStream: TStream); override;
    property CurrentMean: Double read FCurrentMean;
    property CurrentStdDev: Double read FCurrentStdDev;
    property Alpha: Double read FAlpha;
    property LowerLimit: Double read FLowerLimit;
    property UpperLimit: Double read FUpperLimit;
  end;

  /// <summary>
  /// Adaptive detector that learns from confirmed normal values
  /// </summary>
  TAdaptiveAnomalyDetector = class(TBaseAnomalyDetector)
  private
    FWindowSize: Integer;
    FMean: Double;
    FVariance: Double;
    FStdDev: Double;
    FAdaptationRate: Double;
    FInitialized: Boolean;
    FSampleCount: Integer;
    procedure CalculateLimits;
  protected
    procedure CheckAndNotifyAnomaly(const AResult: TAnomalyResult);
  public
    constructor Create(AWindowSize: Integer = 1000; AAdaptationRate: Double = 0.01); overload;
    constructor Create(AWindowSize: Integer; AAdaptationRate: Double; const AConfig: TAnomalyDetectionConfig); overload;
    procedure ProcessValue(const AValue: Double);
    procedure UpdateNormal(const AValue: Double);
    function Detect(const AValue: Double): TAnomalyResult; override;
    procedure SaveState(const AStream: TStream); override;
    procedure LoadState(const AStream: TStream); override;
    property CurrentMean: Double read FMean;
    property CurrentStdDev: Double read FStdDev;
  end;

  /// <summary>
  /// Node for Isolation Tree
  /// </summary>
  TIsolationTreeNode = class
  private
    FLeft: TIsolationTreeNode;
    FRight: TIsolationTreeNode;
    FSplitAttribute: Integer;
    FSplitValue: Double;
    FSize: Integer;
    FIsLeaf: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function IsLeaf: Boolean;
    property Left: TIsolationTreeNode read FLeft write FLeft;
    property Right: TIsolationTreeNode read FRight write FRight;
    property SplitAttribute: Integer read FSplitAttribute write FSplitAttribute;
    property SplitValue: Double read FSplitValue write FSplitValue;
    property Size: Integer read FSize write FSize;
  end;

  /// <summary>
  /// Single Isolation Tree
  /// </summary>
  TIsolationTree = class
  private
    FRoot: TIsolationTreeNode;
    FMaxDepth: Integer;
    procedure BuildTree(ANode: TIsolationTreeNode; const AData: TArray<TArray<Double>>;
                       const AIndices: TArray<Integer>; ACurrentDepth: Integer);
    function GetRandomSplit(const AData: TArray<TArray<Double>>;
                           const AIndices: TArray<Integer>): TPair<Integer, Double>;
  public
    constructor Create(AMaxDepth: Integer = 10);
    destructor Destroy; override;
    procedure Train(const AData: TArray<TArray<Double>>);
    function GetPathLength(const AInstance: TArray<Double>): Double;
    function CalculateAveragePathLength(ASize: Integer): Double;
    property Root: TIsolationTreeNode read FRoot;
  end;

  /// <summary>
  /// Isolation Forest anomaly detector
  /// Excellent for high-dimensional data and unsupervised detection
  /// </summary>
  TIsolationForestDetector = class(TBaseAnomalyDetector)
  private
    FTrees: TObjectList<TIsolationTree>;
    FNumTrees: Integer;
    FSubSampleSize: Integer;
    FMaxDepth: Integer;
    FTrainingData: TArray<TArray<Double>>;
    FIsTrained: Boolean;
    FAveragePathLength: Double;
    FFeatureCount: Integer;
    function CalculateAnomalyScore(const AInstance: TArray<Double>): Double;
    function CalculateAveragePathLength(ASize: Integer): Double;
    procedure EnsureTrainingData;
  protected
    procedure CheckAndNotifyAnomaly(const AResult: TAnomalyResult);
  public
    constructor Create(ANumTrees: Integer = 100; ASubSampleSize: Integer = 256;
                      AMaxDepth: Integer = 10); overload;
    constructor Create(ANumTrees: Integer; ASubSampleSize: Integer; AMaxDepth: Integer;
                      const AConfig: TAnomalyDetectionConfig); overload;
    destructor Destroy; override;

    procedure AddTrainingData(const AInstance: TArray<Double>);
    procedure Train;
    function Detect(const AValue: Double): TAnomalyResult; override;
    function DetectMultiDimensional(const AInstance: TArray<Double>): TAnomalyResult;

    procedure SaveState(const AStream: TStream); override;
    procedure LoadState(const AStream: TStream); override;

    property NumTrees: Integer read FNumTrees;
    property SubSampleSize: Integer read FSubSampleSize;
    property IsTrained: Boolean read FIsTrained;
    property FeatureCount: Integer read FFeatureCount;
  end;

  /// <summary>
  /// Confirmation system to reduce false positives
  /// </summary>
  TAnomalyConfirmationSystem = class
  private
    FRecentAnomalies: TList<Double>;
    FConfirmationThreshold: Integer;
    FWindowSize: Integer;
    FTolerance: Double;
    FLock: TCriticalSection;
  public
    constructor Create(AWindowSize: Integer = 10; AConfirmationThreshold: Integer = 3; ATolerance: Double = 0.1);
    destructor Destroy; override;
    function IsConfirmedAnomaly(const AValue: Double): Boolean;
    procedure AddPotentialAnomaly(const AValue: Double);
    procedure SaveState(const AStream: TStream);
    procedure LoadState(const AStream: TStream);
    procedure SaveToFile(const AFileName: string);
    procedure LoadFromFile(const AFileName: string);
    property ConfirmationThreshold: Integer read FConfirmationThreshold;
    property WindowSize: Integer read FWindowSize;
    property Tolerance: Double read FTolerance write FTolerance;
  end;

  /// <summary>
  /// Factory for creating detectors with optimized configurations
  /// </summary>
  TAnomalyDetectorType = (
    adtThreeSigma,
    adtSlidingWindow,
    adtEMA,
    adtAdaptive,
    adtIsolationForest
  );

  TAnomalyDetectorFactory = class
  public
    class function CreateDetector(AType: TAnomalyDetectorType): TBaseAnomalyDetector; overload;
    class function CreateDetector(AType: TAnomalyDetectorType;
                                 const AConfig: TAnomalyDetectionConfig): TBaseAnomalyDetector; overload;
    class function CreateForWebTrafficMonitoring: TBaseAnomalyDetector;
    class function CreateForFinancialData: TBaseAnomalyDetector;
    class function CreateForIoTSensors: TBaseAnomalyDetector;
    class function CreateForHighDimensionalData: TBaseAnomalyDetector;
  end;

implementation

{ TDetectorMetrics }

function TDetectorMetrics.GetAccuracy: Double;
var
  Total: Int64;
begin
  Total := TruePositives + TrueNegatives + FalsePositives + FalseNegatives;
  if Total > 0 then
    Result := (TruePositives + TrueNegatives) / Total
  else
    Result := 0;
end;

function TDetectorMetrics.GetPrecision: Double;
begin
  if (TruePositives + FalsePositives) > 0 then
    Result := TruePositives / (TruePositives + FalsePositives)
  else
    Result := 0;
end;

function TDetectorMetrics.GetRecall: Double;
begin
  if (TruePositives + FalseNegatives) > 0 then
    Result := TruePositives / (TruePositives + FalseNegatives)
  else
    Result := 0;
end;

function TDetectorMetrics.GetF1Score: Double;
var
  P, R: Double;
begin
  P := GetPrecision;
  R := GetRecall;
  if (P + R) > 0 then
    Result := 2 * P * R / (P + R)
  else
    Result := 0;
end;

function TDetectorMetrics.GetFalsePositiveRate: Double;
begin
  if (FalsePositives + TrueNegatives) > 0 then
    Result := FalsePositives / (FalsePositives + TrueNegatives)
  else
    Result := 0;
end;

function TDetectorMetrics.GetFalseNegativeRate: Double;
begin
  if (FalseNegatives + TruePositives) > 0 then
    Result := FalseNegatives / (FalseNegatives + TruePositives)
  else
    Result := 0;
end;

procedure TDetectorMetrics.Reset;
begin
  TotalDetections := 0;
  AnomaliesDetected := 0;
  NormalValuesDetected := 0;
  TotalProcessingTimeMs := 0;
  AverageProcessingTimeMs := 0;
  MinProcessingTimeMs := MaxInt;
  MaxProcessingTimeMs := 0;
  MemoryUsageBytes := 0;
  ThroughputPerSecond := 0;
  TruePositives := 0;
  FalsePositives := 0;
  TrueNegatives := 0;
  FalseNegatives := 0;
  LastUpdateTime := Now;
end;

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

    // Calcola throughput
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
    var MemInfo: TMemoryManagerState;
    GetMemoryManagerState(MemInfo);
    FMetrics.MemoryUsageBytes := MemInfo.TotalAllocatedMediumBlockSize +
                                MemInfo.TotalAllocatedLargeBlockSize;
    {$ELSE}
    // Placeholder per altre piattaforme
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

  // Aggiungi metriche di accuratezza se disponibili
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

{ TAnomalyDetectionConfig }

class function TAnomalyDetectionConfig.Default: TAnomalyDetectionConfig;
begin
  Result.SigmaMultiplier := 3.0;
  Result.MinStdDev := 0.001;
end;

{ TBaseAnomalyDetector }

constructor TBaseAnomalyDetector.Create(const AName: string);
begin
  Create(AName, TAnomalyDetectionConfig.Default);
end;

constructor TBaseAnomalyDetector.Create(const AName: string; const AConfig: TAnomalyDetectionConfig);
begin
  inherited Create;
  FName := AName;
  FConfig := AConfig;
  FLock := TCriticalSection.Create;
  FLastAnomalyState := False;
  FPerformanceMonitor := TDetectorPerformanceMonitor.Create;
end;

destructor TBaseAnomalyDetector.Destroy;
begin
  FPerformanceMonitor.Free;
  FLock.Free;
  inherited;
end;

procedure TBaseAnomalyDetector.NotifyAnomalyEvent(const AEventType: TAnomalyEvent; const AResult: TAnomalyResult);
var
  EventArgs: TAnomalyEventArgs;
begin
  if Assigned(FOnAnomalyDetected) then
  begin
    EventArgs.EventType := AEventType;
    EventArgs.Timestamp := Now;
    EventArgs.Result := AResult;
    EventArgs.DetectorName := FName;

    case AEventType of
      aeAnomalyDetected: EventArgs.AdditionalInfo := 'Anomaly detected: ' + AResult.Description;
      aeNormalResumed: EventArgs.AdditionalInfo := 'Normal state resumed';
      aeThresholdExceeded: EventArgs.AdditionalInfo := Format('Threshold exceeded: Z-score %.2f', [AResult.ZScore]);
    end;

    FOnAnomalyDetected(Self, EventArgs);
  end;
end;

function TBaseAnomalyDetector.IsAnomaly(const AValue: Double): Boolean;
begin
  Result := Detect(AValue).IsAnomaly;
end;

function TBaseAnomalyDetector.GetAnomalyInfo(const AValue: Double): string;
begin
  Result := Detect(AValue).Description;
end;

function TBaseAnomalyDetector.GetPerformanceReport: string;
begin
  Result := FPerformanceMonitor.GetReport;
end;

procedure TBaseAnomalyDetector.SaveConfigToStream(const AStream: TStream);
begin
  AStream.WriteData(FConfig.SigmaMultiplier);
  AStream.WriteData(FConfig.MinStdDev);
end;

procedure TBaseAnomalyDetector.LoadConfigFromStream(const AStream: TStream);
begin
  AStream.ReadData(FConfig.SigmaMultiplier);
  AStream.ReadData(FConfig.MinStdDev);
end;

procedure TBaseAnomalyDetector.SaveToFile(const AFileName: string);
var
  FileStream: TFileStream;
begin
  FileStream := TFileStream.Create(AFileName, fmCreate);
  try
    SaveState(FileStream);
  finally
    FileStream.Free;
  end;
end;

procedure TBaseAnomalyDetector.LoadFromFile(const AFileName: string);
var
  FileStream: TFileStream;
begin
  FileStream := TFileStream.Create(AFileName, fmOpenRead);
  try
    LoadState(FileStream);
  finally
    FileStream.Free;
  end;
end;

{ TThreeSigmaDetector }

constructor TThreeSigmaDetector.Create;
begin
  inherited Create('3-Sigma Detector');
  FIsCalculated := False;
end;

constructor TThreeSigmaDetector.Create(const AConfig: TAnomalyDetectionConfig);
begin
  inherited Create('3-Sigma Detector', AConfig);
  FIsCalculated := False;
end;

procedure TThreeSigmaDetector.SetHistoricalData(const AData: TArray<Double>);
begin
  FLock.Enter;
  try
    FData := AData;
    FIsCalculated := False;
  finally
    FLock.Leave;
  end;
end;

procedure TThreeSigmaDetector.CalculateStatistics;
var
  i: Integer;
  Sum: Double;
  N: Integer;
begin
  FLock.Enter;
  try
    N := Length(FData);
    if N = 0 then
      raise EAnomalyDetectionException.Create('No historical data available');

    if N = 1 then
      raise EAnomalyDetectionException.Create('At least 2 data points required for standard deviation');

    // Validazione valori NaN/Inf
    for i := 0 to High(FData) do
    begin
      if IsNaN(FData[i]) or IsInfinite(FData[i]) then
        raise EAnomalyDetectionException.CreateFmt('Invalid data value at index %d: %g', [i, FData[i]]);
    end;

    // Calculate mean
    Sum := 0;
    for i := 0 to High(FData) do
      Sum := Sum + FData[i];
    FMean := Sum / N;

    // Calculate standard deviation (sample formula)
    Sum := 0;
    for i := 0 to High(FData) do
      Sum := Sum + Power(FData[i] - FMean, 2);
    FStdDev := Sqrt(Sum / (N - 1));

    // Ensure minimum standard deviation
    if FStdDev < FConfig.MinStdDev then
      FStdDev := FConfig.MinStdDev;

    CalculateLimits;
    FIsCalculated := True;
  finally
    FLock.Leave;
  end;
end;

procedure TThreeSigmaDetector.CalculateLimits;
begin
  FLowerLimit := FMean - (FConfig.SigmaMultiplier * FStdDev);
  FUpperLimit := FMean + (FConfig.SigmaMultiplier * FStdDev);
end;

procedure TThreeSigmaDetector.CheckAndNotifyAnomaly(const AResult: TAnomalyResult);
begin
  if AResult.IsAnomaly and not FLastAnomalyState then
  begin
    // Transition from normal to anomaly
    NotifyAnomalyEvent(aeAnomalyDetected, AResult);
    if AResult.ZScore > FConfig.SigmaMultiplier * 1.5 then
      NotifyAnomalyEvent(aeThresholdExceeded, AResult);
  end
  else if not AResult.IsAnomaly and FLastAnomalyState then
  begin
    // Transition from anomaly to normal
    NotifyAnomalyEvent(aeNormalResumed, AResult);
  end;

  FLastAnomalyState := AResult.IsAnomaly;
end;

function TThreeSigmaDetector.Detect(const AValue: Double): TAnomalyResult;
begin
  FLock.Enter;
  try
    if not FIsCalculated then
      raise EAnomalyDetectionException.Create('Statistics not calculated. Call CalculateStatistics first.');

    Result.Value := AValue;
    Result.LowerLimit := FLowerLimit;
    Result.UpperLimit := FUpperLimit;
    Result.IsAnomaly := (AValue < FLowerLimit) or (AValue > FUpperLimit);

    if FStdDev > 0 then
      Result.ZScore := Abs(AValue - FMean) / FStdDev
    else
      Result.ZScore := 0;

    if Result.IsAnomaly then
    begin
      if AValue < FLowerLimit then
        Result.Description := Format('ANOMALY: Value %.2f below lower limit (%.2f), Z-score: %.2f',
                                    [AValue, FLowerLimit, Result.ZScore])
      else
        Result.Description := Format('ANOMALY: Value %.2f above upper limit (%.2f), Z-score: %.2f',
                                    [AValue, FUpperLimit, Result.ZScore]);
    end
    else
      Result.Description := Format('Normal value: %.2f (range: %.2f - %.2f), Z-score: %.2f',
                                  [AValue, FLowerLimit, FUpperLimit, Result.ZScore]);

    CheckAndNotifyAnomaly(Result);
  finally
    FLock.Leave;
  end;
end;

procedure TThreeSigmaDetector.SaveState(const AStream: TStream);
var
  DataCount: Integer;
  i: Integer;
begin
  FLock.Enter;
  try
    // Save configuration
    SaveConfigToStream(AStream);

    // Save state
    AStream.WriteData(FIsCalculated);
    AStream.WriteData(FMean);
    AStream.WriteData(FStdDev);
    AStream.WriteData(FLowerLimit);
    AStream.WriteData(FUpperLimit);

    // Save historical data
    DataCount := Length(FData);
    AStream.WriteData(DataCount);
    for i := 0 to DataCount - 1 do
      AStream.WriteData(FData[i]);
  finally
    FLock.Leave;
  end;
end;

procedure TThreeSigmaDetector.LoadState(const AStream: TStream);
var
  DataCount: Integer;
  i: Integer;
begin
  FLock.Enter;
  try
    // Load configuration
    LoadConfigFromStream(AStream);

    // Load state
    AStream.ReadData(FIsCalculated);
    AStream.ReadData(FMean);
    AStream.ReadData(FStdDev);
    AStream.ReadData(FLowerLimit);
    AStream.ReadData(FUpperLimit);

    // Load historical data
    AStream.ReadData(DataCount);
    SetLength(FData, DataCount);
    for i := 0 to DataCount - 1 do
      AStream.ReadData(FData[i]);
  finally
    FLock.Leave;
  end;
end;

{ TSlidingWindowDetector }

constructor TSlidingWindowDetector.Create(AWindowSize: Integer);
begin
  Create(AWindowSize, TAnomalyDetectionConfig.Default);
end;

constructor TSlidingWindowDetector.Create(AWindowSize: Integer; const AConfig: TAnomalyDetectionConfig);
begin
  inherited Create('Sliding Window Detector', AConfig);
  FWindowSize := AWindowSize;
  FWindowData := TList<Double>.Create;
  FSum := 0;
  FSumSquares := 0;
  FNeedsRecalculation := False;
end;

destructor TSlidingWindowDetector.Destroy;
begin
  FWindowData.Free;
  inherited Destroy;
end;

procedure TSlidingWindowDetector.AddValue(const AValue: Double);
var
  RemovedValue: Double;
  HasRemoved: Boolean;
begin
  FLock.Enter;
  try
    HasRemoved := False;
    RemovedValue := 0;

    // Remove oldest value if window is full
    if FWindowData.Count >= FWindowSize then
    begin
      RemovedValue := FWindowData[0];
      FWindowData.Delete(0);
      HasRemoved := True;
    end;

    // Add new value
    FWindowData.Add(AValue);

    // Update statistics incrementally
    UpdateStatisticsIncremental(AValue, RemovedValue, HasRemoved);
  finally
    FLock.Leave;
  end;
end;

procedure TSlidingWindowDetector.UpdateStatisticsIncremental(const AAddedValue, ARemovedValue: Double; AHasRemoved: Boolean);
var
  N: Integer;
begin
  N := FWindowData.Count;

  if N = 0 then
  begin
    FMean := 0;
    FStdDev := 0;
    FSum := 0;
    FSumSquares := 0;
    FLowerLimit := 0;
    FUpperLimit := 0;
    Exit;
  end;

  // Update sums
  FSum := FSum + AAddedValue;
  FSumSquares := FSumSquares + (AAddedValue * AAddedValue);

  if AHasRemoved then
  begin
    FSum := FSum - ARemovedValue;
    FSumSquares := FSumSquares - (ARemovedValue * ARemovedValue);
  end;

  // Calculate mean
  FMean := FSum / N;

  // Calculate variance and standard deviation
  if N > 1 then
  begin
    var Variance := (FSumSquares - (FSum * FSum) / N) / (N - 1);
    if Variance < 0 then // Handle numerical errors
      Variance := 0;
    FStdDev := Sqrt(Variance);

    // Ensure minimum standard deviation
    if FStdDev < FConfig.MinStdDev then
      FStdDev := FConfig.MinStdDev;
  end
  else
  begin
    FStdDev := FConfig.MinStdDev;
  end;

  CalculateLimits;
end;

procedure TSlidingWindowDetector.RecalculateStatistics;
var
  i: Integer;
  Sum, SumSquares: Double;
  N: Integer;
begin
  N := FWindowData.Count;

  if N = 0 then
  begin
    FMean := 0;
    FStdDev := 0;
    FLowerLimit := 0;
    FUpperLimit := 0;
    Exit;
  end;

  // Recalculate from scratch
  Sum := 0;
  SumSquares := 0;

  for i := 0 to N - 1 do
  begin
    Sum := Sum + FWindowData[i];
    SumSquares := SumSquares + (FWindowData[i] * FWindowData[i]);
  end;

  FSum := Sum;
  FSumSquares := SumSquares;
  FMean := Sum / N;

  if N > 1 then
  begin
    var Variance := (SumSquares - (Sum * Sum) / N) / (N - 1);
    if Variance < 0 then
      Variance := 0;
    FStdDev := Sqrt(Variance);

    if FStdDev < FConfig.MinStdDev then
      FStdDev := FConfig.MinStdDev;
  end
  else
  begin
    FStdDev := FConfig.MinStdDev;
  end;

  CalculateLimits;
  FNeedsRecalculation := False;
end;

procedure TSlidingWindowDetector.CalculateLimits;
begin
  FLowerLimit := FMean - (FConfig.SigmaMultiplier * FStdDev);
  FUpperLimit := FMean + (FConfig.SigmaMultiplier * FStdDev);
end;

procedure TSlidingWindowDetector.CheckAndNotifyAnomaly(const AResult: TAnomalyResult);
begin
  if AResult.IsAnomaly and not FLastAnomalyState then
  begin
    NotifyAnomalyEvent(aeAnomalyDetected, AResult);
    if AResult.ZScore > FConfig.SigmaMultiplier * 1.5 then
      NotifyAnomalyEvent(aeThresholdExceeded, AResult);
  end
  else if not AResult.IsAnomaly and FLastAnomalyState then
  begin
    NotifyAnomalyEvent(aeNormalResumed, AResult);
  end;

  FLastAnomalyState := AResult.IsAnomaly;
end;

function TSlidingWindowDetector.Detect(const AValue: Double): TAnomalyResult;
begin
  FLock.Enter;
  try
    if FNeedsRecalculation then
      RecalculateStatistics;

    Result.Value := AValue;
    Result.LowerLimit := FLowerLimit;
    Result.UpperLimit := FUpperLimit;
    Result.IsAnomaly := (AValue < FLowerLimit) or (AValue > FUpperLimit);

    if FStdDev > 0 then
      Result.ZScore := Abs(AValue - FMean) / FStdDev
    else
      Result.ZScore := 0;

    if Result.IsAnomaly then
    begin
      if AValue < FLowerLimit then
        Result.Description := Format('WINDOW ANOMALY: Value %.2f below lower limit (%.2f), Z-score: %.2f',
                                    [AValue, FLowerLimit, Result.ZScore])
      else
        Result.Description := Format('WINDOW ANOMALY: Value %.2f above upper limit (%.2f), Z-score: %.2f',
                                    [AValue, FUpperLimit, Result.ZScore]);
    end
    else
      Result.Description := Format('Normal value: %.2f (range: %.2f - %.2f), Z-score: %.2f',
                                  [AValue, FLowerLimit, FUpperLimit, Result.ZScore]);

    CheckAndNotifyAnomaly(Result);
  finally
    FLock.Leave;
  end;
end;

procedure TSlidingWindowDetector.SaveState(const AStream: TStream);
var
  Count, i: Integer;
begin
  FLock.Enter;
  try
    // Save configuration
    SaveConfigToStream(AStream);

    // Save window parameters
    AStream.WriteData(FWindowSize);

    // Save current statistics
    AStream.WriteData(FMean);
    AStream.WriteData(FStdDev);
    AStream.WriteData(FSum);
    AStream.WriteData(FSumSquares);
    AStream.WriteData(FLowerLimit);
    AStream.WriteData(FUpperLimit);
    AStream.WriteData(FNeedsRecalculation);

    // Save window data
    Count := FWindowData.Count;
    AStream.WriteData(Count);
    for i := 0 to Count - 1 do
      AStream.WriteData(FWindowData[i]);
  finally
    FLock.Leave;
  end;
end;

procedure TSlidingWindowDetector.LoadState(const AStream: TStream);
var
  Count, i: Integer;
  Value: Double;
begin
  FLock.Enter;
  try
    // Load configuration
    LoadConfigFromStream(AStream);

    // Load window parameters
    AStream.ReadData(FWindowSize);

    // Load current statistics
    AStream.ReadData(FMean);
    AStream.ReadData(FStdDev);
    AStream.ReadData(FSum);
    AStream.ReadData(FSumSquares);
    AStream.ReadData(FLowerLimit);
    AStream.ReadData(FUpperLimit);
    AStream.ReadData(FNeedsRecalculation);

    // Load window data
    FWindowData.Clear;
    AStream.ReadData(Count);
    for i := 0 to Count - 1 do
    begin
      AStream.ReadData(Value);
      FWindowData.Add(Value);
    end;
  finally
    FLock.Leave;
  end;
end;

{ TEMAAnomalyDetector }

constructor TEMAAnomalyDetector.Create(AAlpha: Double);
begin
  Create(AAlpha, TAnomalyDetectionConfig.Default);
end;

constructor TEMAAnomalyDetector.Create(AAlpha: Double; const AConfig: TAnomalyDetectionConfig);
begin
  inherited Create('Exponential Moving Average Detector', AConfig);
  FAlpha := AAlpha;
  FInitialized := False;
end;

procedure TEMAAnomalyDetector.AddValue(const AValue: Double);
begin
  FLock.Enter;
  try
    if not FInitialized then
    begin
      FCurrentMean := AValue;
      FCurrentVariance := FConfig.MinStdDev * FConfig.MinStdDev;
      FCurrentStdDev := FConfig.MinStdDev;
      FInitialized := True;
    end
    else
    begin
      var Delta := AValue - FCurrentMean;

      // Update exponential moving average
      FCurrentMean := FAlpha * AValue + (1 - FAlpha) * FCurrentMean;

      // Update variance using EMA
      FCurrentVariance := FAlpha * (Delta * Delta) + (1 - FAlpha) * FCurrentVariance;

      // Ensure minimum variance
      if FCurrentVariance < FConfig.MinStdDev * FConfig.MinStdDev then
        FCurrentVariance := FConfig.MinStdDev * FConfig.MinStdDev;

      FCurrentStdDev := Sqrt(FCurrentVariance);
    end;

    CalculateLimits;
  finally
    FLock.Leave;
  end;
end;

procedure TEMAAnomalyDetector.CalculateLimits;
begin
  FLowerLimit := FCurrentMean - (FConfig.SigmaMultiplier * FCurrentStdDev);
  FUpperLimit := FCurrentMean + (FConfig.SigmaMultiplier * FCurrentStdDev);
end;

procedure TEMAAnomalyDetector.CheckAndNotifyAnomaly(const AResult: TAnomalyResult);
begin
  if AResult.IsAnomaly and not FLastAnomalyState then
  begin
    NotifyAnomalyEvent(aeAnomalyDetected, AResult);
    if AResult.ZScore > FConfig.SigmaMultiplier * 1.5 then
      NotifyAnomalyEvent(aeThresholdExceeded, AResult);
  end
  else if not AResult.IsAnomaly and FLastAnomalyState then
  begin
    NotifyAnomalyEvent(aeNormalResumed, AResult);
  end;

  FLastAnomalyState := AResult.IsAnomaly;
end;

function TEMAAnomalyDetector.Detect(const AValue: Double): TAnomalyResult;
begin
  FLock.Enter;
  try
    Result.Value := AValue;

    if not FInitialized then
    begin
      Result.IsAnomaly := False;
      Result.ZScore := 0;
      Result.LowerLimit := 0;
      Result.UpperLimit := 0;
      Result.Description := Format('EMA not initialized. First value: %.2f', [AValue]);
    end
    else
    begin
      Result.LowerLimit := FLowerLimit;
      Result.UpperLimit := FUpperLimit;
      Result.IsAnomaly := (AValue < FLowerLimit) or (AValue > FUpperLimit);

      if FCurrentStdDev > 0 then
        Result.ZScore := Abs(AValue - FCurrentMean) / FCurrentStdDev
      else
        Result.ZScore := 0;

      if Result.IsAnomaly then
      begin
        if AValue < FLowerLimit then
          Result.Description := Format('EMA ANOMALY: Value %.2f below lower limit (%.2f), Z-score: %.2f',
                                      [AValue, FLowerLimit, Result.ZScore])
        else
          Result.Description := Format('EMA ANOMALY: Value %.2f above upper limit (%.2f), Z-score: %.2f',
                                      [AValue, FUpperLimit, Result.ZScore]);
      end
      else
        Result.Description := Format('Normal value: %.2f (EMA: %.2f, range: %.2f - %.2f), Z-score: %.2f',
                                    [AValue, FCurrentMean, FLowerLimit, FUpperLimit, Result.ZScore]);
    end;

    if FInitialized then
      CheckAndNotifyAnomaly(Result);
  finally
    FLock.Leave;
  end;
end;

procedure TEMAAnomalyDetector.SaveState(const AStream: TStream);
begin
  FLock.Enter;
  try
    // Save configuration
    SaveConfigToStream(AStream);

    // Save EMA parameters
    AStream.WriteData(FAlpha);
    AStream.WriteData(FInitialized);
    AStream.WriteData(FCurrentMean);
    AStream.WriteData(FCurrentVariance);
    AStream.WriteData(FCurrentStdDev);
    AStream.WriteData(FLowerLimit);
    AStream.WriteData(FUpperLimit);
  finally
    FLock.Leave;
  end;
end;

procedure TEMAAnomalyDetector.LoadState(const AStream: TStream);
begin
  FLock.Enter;
  try
    // Load configuration
    LoadConfigFromStream(AStream);

    // Load EMA parameters
    AStream.ReadData(FAlpha);
    AStream.ReadData(FInitialized);
    AStream.ReadData(FCurrentMean);
    AStream.ReadData(FCurrentVariance);
    AStream.ReadData(FCurrentStdDev);
    AStream.ReadData(FLowerLimit);
    AStream.ReadData(FUpperLimit);
  finally
    FLock.Leave;
  end;
end;

{ TAdaptiveAnomalyDetector }

constructor TAdaptiveAnomalyDetector.Create(AWindowSize: Integer; AAdaptationRate: Double);
begin
  Create(AWindowSize, AAdaptationRate, TAnomalyDetectionConfig.Default);
end;

constructor TAdaptiveAnomalyDetector.Create(AWindowSize: Integer; AAdaptationRate: Double; const AConfig: TAnomalyDetectionConfig);
begin
  inherited Create('Adaptive Detector', AConfig);
  FWindowSize := AWindowSize;
  FAdaptationRate := AAdaptationRate;
  FInitialized := False;
  FSampleCount := 0;
end;

procedure TAdaptiveAnomalyDetector.ProcessValue(const AValue: Double);
var
  Result: TAnomalyResult;
begin
  FLock.Enter;
  try
    if not FInitialized then
    begin
      FMean := AValue;
      FVariance := FConfig.MinStdDev * FConfig.MinStdDev;
      FStdDev := FConfig.MinStdDev;
      FInitialized := True;
      FSampleCount := 1;
    end
    else
    begin
      Inc(FSampleCount);

      // Check if anomaly without recursive lock
      Result.LowerLimit := FMean - (FConfig.SigmaMultiplier * FStdDev);
      Result.UpperLimit := FMean + (FConfig.SigmaMultiplier * FStdDev);

      if FStdDev > 0 then
        Result.ZScore := Abs(AValue - FMean) / FStdDev
      else
        Result.ZScore := 0;

      Result.IsAnomaly := Result.ZScore > FConfig.SigmaMultiplier;

      // If not an anomaly, update statistics
      if not Result.IsAnomaly then
      begin
        // Inline update to avoid recursive lock
        var Delta := AValue - FMean;
        var NewMean := FMean + FAdaptationRate * Delta;
        var NewVariance := (1 - FAdaptationRate) * FVariance + FAdaptationRate * Delta * (AValue - NewMean);

        FMean := NewMean;
        FVariance := NewVariance;

        if FVariance < FConfig.MinStdDev * FConfig.MinStdDev then
          FVariance := FConfig.MinStdDev * FConfig.MinStdDev;

        FStdDev := Sqrt(FVariance);
      end;
    end;

    CalculateLimits;
  finally
    FLock.Leave;
  end;
end;

procedure TAdaptiveAnomalyDetector.UpdateNormal(const AValue: Double);
var
  Delta: Double;
  NewMean: Double;
  NewVariance: Double;
begin
  FLock.Enter;
  try
    if not FInitialized then
    begin
      FMean := AValue;
      FVariance := FConfig.MinStdDev * FConfig.MinStdDev;
      FStdDev := FConfig.MinStdDev;
      FInitialized := True;
      FSampleCount := 1;
    end
    else
    begin
      // Welford's online algorithm adapted for exponential weighting
      Delta := AValue - FMean;
      NewMean := FMean + FAdaptationRate * Delta;
      NewVariance := (1 - FAdaptationRate) * FVariance + FAdaptationRate * Delta * (AValue - NewMean);

      FMean := NewMean;
      FVariance := NewVariance;

      // Ensure minimum variance
      if FVariance < FConfig.MinStdDev * FConfig.MinStdDev then
        FVariance := FConfig.MinStdDev * FConfig.MinStdDev;

      FStdDev := Sqrt(FVariance);
    end;

    CalculateLimits;
  finally
    FLock.Leave;
  end;
end;

procedure TAdaptiveAnomalyDetector.CalculateLimits;
begin
  // Dynamic limits based on current statistics
  // Note: Limits are calculated dynamically in Detect method
  // This method is kept for interface consistency
end;

procedure TAdaptiveAnomalyDetector.CheckAndNotifyAnomaly(const AResult: TAnomalyResult);
begin
  if AResult.IsAnomaly and not FLastAnomalyState then
  begin
    NotifyAnomalyEvent(aeAnomalyDetected, AResult);
    if AResult.ZScore > FConfig.SigmaMultiplier * 1.5 then
      NotifyAnomalyEvent(aeThresholdExceeded, AResult);
  end
  else if not AResult.IsAnomaly and FLastAnomalyState then
  begin
    NotifyAnomalyEvent(aeNormalResumed, AResult);
  end;

  FLastAnomalyState := AResult.IsAnomaly;
end;

function TAdaptiveAnomalyDetector.Detect(const AValue: Double): TAnomalyResult;
begin
  FLock.Enter;
  try
    Result.Value := AValue;

    if not FInitialized then
    begin
      Result.IsAnomaly := False;
      Result.ZScore := 0;
      Result.LowerLimit := 0;
      Result.UpperLimit := 0;
      Result.Description := Format('Adaptive detector not initialized. First value: %.2f', [AValue]);
    end
    else
    begin
      Result.LowerLimit := FMean - (FConfig.SigmaMultiplier * FStdDev);
      Result.UpperLimit := FMean + (FConfig.SigmaMultiplier * FStdDev);

      if FStdDev > 0 then
        Result.ZScore := Abs(AValue - FMean) / FStdDev
      else
        Result.ZScore := 0;

      Result.IsAnomaly := Result.ZScore > FConfig.SigmaMultiplier;

      if Result.IsAnomaly then
        Result.Description := Format('ADAPTIVE ANOMALY: Value %.2f (Z-score: %.2f, threshold: %.2f)',
                                    [AValue, Result.ZScore, FConfig.SigmaMultiplier])
      else
        Result.Description := Format('Normal value: %.2f (Z-score: %.2f, mean: %.2f, stddev: %.2f)',
                                    [AValue, Result.ZScore, FMean, FStdDev]);
    end;

    if FInitialized then
      CheckAndNotifyAnomaly(Result);
  finally
    FLock.Leave;
  end;
end;

procedure TAdaptiveAnomalyDetector.SaveState(const AStream: TStream);
begin
  FLock.Enter;
  try
    // Save configuration
    SaveConfigToStream(AStream);

    // Save adaptive parameters
    AStream.WriteData(FWindowSize);
    AStream.WriteData(FAdaptationRate);
    AStream.WriteData(FInitialized);
    AStream.WriteData(FSampleCount);
    AStream.WriteData(FMean);
    AStream.WriteData(FVariance);
    AStream.WriteData(FStdDev);
  finally
    FLock.Leave;
  end;
end;

procedure TAdaptiveAnomalyDetector.LoadState(const AStream: TStream);
begin
  FLock.Enter;
  try
    // Load configuration
    LoadConfigFromStream(AStream);

    // Load adaptive parameters
    AStream.ReadData(FWindowSize);
    AStream.ReadData(FAdaptationRate);
    AStream.ReadData(FInitialized);
    AStream.ReadData(FSampleCount);
    AStream.ReadData(FMean);
    AStream.ReadData(FVariance);
    AStream.ReadData(FStdDev);
  finally
    FLock.Leave;
  end;
end;

{ TIsolationTreeNode }

constructor TIsolationTreeNode.Create;
begin
  inherited Create;
  FLeft := nil;
  FRight := nil;
  FSplitAttribute := -1;
  FSplitValue := 0;
  FSize := 0;
  FIsLeaf := True;
end;

destructor TIsolationTreeNode.Destroy;
begin
  FLeft.Free;
  FRight.Free;
  inherited Destroy;
end;

function TIsolationTreeNode.IsLeaf: Boolean;
begin
  Result := (FLeft = nil) and (FRight = nil);
end;

{ TIsolationTree }

constructor TIsolationTree.Create(AMaxDepth: Integer);
begin
  inherited Create;
  FMaxDepth := AMaxDepth;
  FRoot := nil;
end;

destructor TIsolationTree.Destroy;
begin
  FRoot.Free;
  inherited Destroy;
end;

procedure TIsolationTree.Train(const AData: TArray<TArray<Double>>);
var
  Indices: TArray<Integer>;
  i: Integer;
begin
  if Length(AData) = 0 then
    raise EAnomalyDetectionException.Create('Training data cannot be empty');

  // Inizializza gli indici
  SetLength(Indices, Length(AData));
  for i := 0 to High(Indices) do
    Indices[i] := i;

  // Costruisci l'albero
  FRoot := TIsolationTreeNode.Create;
  BuildTree(FRoot, AData, Indices, 0);
end;

procedure TIsolationTree.BuildTree(ANode: TIsolationTreeNode;
  const AData: TArray<TArray<Double>>; const AIndices: TArray<Integer>;
  ACurrentDepth: Integer);
var
  SplitInfo: TPair<Integer, Double>;
  LeftIndices, RightIndices: TArray<Integer>;
  LeftCount, RightCount: Integer;
  i: Integer;
begin
  ANode.FSize := Length(AIndices);

  // Condizioni di terminazione
  if (Length(AIndices) <= 1) or (ACurrentDepth >= FMaxDepth) then
  begin
    ANode.FIsLeaf := True;
    Exit;
  end;

  // Trova uno split casuale
  SplitInfo := GetRandomSplit(AData, AIndices);
  ANode.FSplitAttribute := SplitInfo.Key;
  ANode.FSplitValue := SplitInfo.Value;
  ANode.FIsLeaf := False;

  // Dividi i dati
  SetLength(LeftIndices, Length(AIndices));
  SetLength(RightIndices, Length(AIndices));
  LeftCount := 0;
  RightCount := 0;

  for i := 0 to High(AIndices) do
  begin
    if AData[AIndices[i]][ANode.FSplitAttribute] < ANode.FSplitValue then
    begin
      LeftIndices[LeftCount] := AIndices[i];
      Inc(LeftCount);
    end
    else
    begin
      RightIndices[RightCount] := AIndices[i];
      Inc(RightCount);
    end;
  end;

  SetLength(LeftIndices, LeftCount);
  SetLength(RightIndices, RightCount);

  // Ricorsione sui figli
  if LeftCount > 0 then
  begin
    ANode.FLeft := TIsolationTreeNode.Create;
    BuildTree(ANode.FLeft, AData, LeftIndices, ACurrentDepth + 1);
  end;

  if RightCount > 0 then
  begin
    ANode.FRight := TIsolationTreeNode.Create;
    BuildTree(ANode.FRight, AData, RightIndices, ACurrentDepth + 1);
  end;
end;

function TIsolationTree.GetRandomSplit(const AData: TArray<TArray<Double>>;
  const AIndices: TArray<Integer>): TPair<Integer, Double>;
var
  Attribute: Integer;
  MinVal, MaxVal, SplitVal: Double;
  i: Integer;
begin
  // Scegli un attributo casuale
  if Length(AData) > 0 then
    Attribute := Random(Length(AData[0]))
  else
    Attribute := 0;

  // Trova min e max per quell'attributo
  MinVal := AData[AIndices[0]][Attribute];
  MaxVal := MinVal;

  for i := 1 to High(AIndices) do
  begin
    var Val := AData[AIndices[i]][Attribute];
    if Val < MinVal then MinVal := Val;
    if Val > MaxVal then MaxVal := Val;
  end;

  // Genera uno split casuale
  if MaxVal > MinVal then
    SplitVal := MinVal + Random * (MaxVal - MinVal)
  else
    SplitVal := MinVal;

  Result := TPair<Integer, Double>.Create(Attribute, SplitVal);
end;

function TIsolationTree.CalculateAveragePathLength(ASize: Integer): Double;
begin
  if ASize > 2 then
    Result := 2.0 * (Ln(ASize - 1) + 0.5772156649) - (2.0 * (ASize - 1) / ASize) // Eulero-Mascheroni constant
  else if ASize = 2 then
    Result := 1.0
  else
    Result := 0.0;
end;

function TIsolationTree.GetPathLength(const AInstance: TArray<Double>): Double;
var
  CurrentNode: TIsolationTreeNode;
  PathLength: Integer;
begin
  CurrentNode := FRoot;
  PathLength := 0;

  while (CurrentNode <> nil) and not CurrentNode.IsLeaf do
  begin
    if AInstance[CurrentNode.FSplitAttribute] < CurrentNode.FSplitValue then
      CurrentNode := CurrentNode.FLeft
    else
      CurrentNode := CurrentNode.FRight;

    Inc(PathLength);
  end;

  // Aggiungi la stima per il sottoalbero non esplorato
  if CurrentNode <> nil then
    Result := PathLength + CalculateAveragePathLength(CurrentNode.FSize)
  else
    Result := PathLength;
end;

{ TIsolationForestDetector }

constructor TIsolationForestDetector.Create(ANumTrees: Integer;
  ASubSampleSize: Integer; AMaxDepth: Integer);
begin
  Create(ANumTrees, ASubSampleSize, AMaxDepth, TAnomalyDetectionConfig.Default);
end;

constructor TIsolationForestDetector.Create(ANumTrees: Integer;
  ASubSampleSize: Integer; AMaxDepth: Integer; const AConfig: TAnomalyDetectionConfig);
begin
  inherited Create('Isolation Forest Detector', AConfig);
  FNumTrees := ANumTrees;
  FSubSampleSize := ASubSampleSize;
  FMaxDepth := AMaxDepth;
  FTrees := TObjectList<TIsolationTree>.Create(True);
  FIsTrained := False;
  FAveragePathLength := 0;
  FFeatureCount := 1; // Default per dati 1D
  SetLength(FTrainingData, 0);
end;

destructor TIsolationForestDetector.Destroy;
begin
  FTrees.Free;
  inherited Destroy;
end;

procedure TIsolationForestDetector.AddTrainingData(const AInstance: TArray<Double>);
var
  NewLength: Integer;
begin
  FLock.Enter;
  try
    NewLength := Length(FTrainingData);
    SetLength(FTrainingData, NewLength + 1);
    SetLength(FTrainingData[NewLength], Length(AInstance));

    for var i := 0 to High(AInstance) do
      FTrainingData[NewLength][i] := AInstance[i];

    FFeatureCount := Length(AInstance);
    FIsTrained := False; // Require retraining
  finally
    FLock.Leave;
  end;
end;

procedure TIsolationForestDetector.Train;
var
  i, j: Integer;
  SubSample: TArray<TArray<Double>>;
  SampleIndices: TArray<Integer>;
  Tree: TIsolationTree;
  ActualSubSampleSize: Integer;
begin
  FLock.Enter;
  try
    if Length(FTrainingData) = 0 then
      raise EAnomalyDetectionException.Create('No training data available');

    FTrees.Clear;

    ActualSubSampleSize := Min(FSubSampleSize, Length(FTrainingData));
    FAveragePathLength := CalculateAveragePathLength(ActualSubSampleSize);

    for i := 1 to FNumTrees do
    begin
      // Crea un subsample casuale
      SetLength(SampleIndices, Length(FTrainingData));
      for j := 0 to High(SampleIndices) do
        SampleIndices[j] := j;

      // Shuffle
      for j := High(SampleIndices) downto 1 do
      begin
        var k := Random(j + 1);
        var temp := SampleIndices[j];
        SampleIndices[j] := SampleIndices[k];
        SampleIndices[k] := temp;
      end;

      // Prendi i primi ActualSubSampleSize elementi
      SetLength(SubSample, ActualSubSampleSize);
      for j := 0 to ActualSubSampleSize - 1 do
      begin
        SetLength(SubSample[j], FFeatureCount);
        for var k := 0 to FFeatureCount - 1 do
          SubSample[j][k] := FTrainingData[SampleIndices[j]][k];
      end;

      // Crea e allena l'albero
      Tree := TIsolationTree.Create(FMaxDepth);
      Tree.Train(SubSample);
      FTrees.Add(Tree);
    end;

    FIsTrained := True;
  finally
    FLock.Leave;
  end;
end;

function TIsolationForestDetector.CalculateAveragePathLength(ASize: Integer): Double;
begin
  if ASize > 2 then
    Result := 2.0 * (Ln(ASize - 1) + 0.5772156649) - (2.0 * (ASize - 1) / ASize) // Eulero-Mascheroni constant
  else if ASize = 2 then
    Result := 1.0
  else
    Result := 0.0;
end;

function TIsolationForestDetector.CalculateAnomalyScore(const AInstance: TArray<Double>): Double;
var
  i: Integer;
  TotalPathLength: Double;
  AveragePathLength: Double;
begin
  if not FIsTrained then
    raise EAnomalyDetectionException.Create('Detector must be trained first');

  TotalPathLength := 0;
  for i := 0 to FTrees.Count - 1 do
    TotalPathLength := TotalPathLength + FTrees[i].GetPathLength(AInstance);

  AveragePathLength := TotalPathLength / FTrees.Count;

  // Score normalizzato: più piccolo = più anomalo
  Result := Power(2, -AveragePathLength / FAveragePathLength);
end;

function TIsolationForestDetector.Detect(const AValue: Double): TAnomalyResult;
var
  Instance: TArray<Double>;
begin
  // Converte valore singolo in array per compatibilità
  SetLength(Instance, 1);
  Instance[0] := AValue;
  Result := DetectMultiDimensional(Instance);
end;

function TIsolationForestDetector.DetectMultiDimensional(const AInstance: TArray<Double>): TAnomalyResult;
var
  AnomalyScore: Double;
  Threshold: Double;
begin
  FLock.Enter;
  try
    EnsureTrainingData;

    Result.Value := AInstance[0]; // Per compatibilità con interfaccia base

    AnomalyScore := CalculateAnomalyScore(AInstance);

    // Soglia empirica: valori < 0.5 sono tipicamente anomalie
    Threshold := 0.5;
    Result.IsAnomaly := AnomalyScore < Threshold;

    Result.ZScore := (Threshold - AnomalyScore) / 0.2; // Normalizzazione approssimativa
    Result.LowerLimit := 0;
    Result.UpperLimit := Threshold;

    if Result.IsAnomaly then
      Result.Description := Format('ISOLATION FOREST ANOMALY: Score %.4f (threshold %.2f), easier to isolate',
                                  [AnomalyScore, Threshold])
    else
      Result.Description := Format('Normal: Score %.4f (threshold %.2f)', [AnomalyScore, Threshold]);

    CheckAndNotifyAnomaly(Result);
  finally
    FLock.Leave;
  end;
end;

procedure TIsolationForestDetector.EnsureTrainingData;
begin
  if not FIsTrained and (Length(FTrainingData) > 0) then
    Train;
end;

procedure TIsolationForestDetector.CheckAndNotifyAnomaly(const AResult: TAnomalyResult);
begin
  if AResult.IsAnomaly and not FLastAnomalyState then
  begin
    NotifyAnomalyEvent(aeAnomalyDetected, AResult);
  end
  else if not AResult.IsAnomaly and FLastAnomalyState then
  begin
    NotifyAnomalyEvent(aeNormalResumed, AResult);
  end;

  FLastAnomalyState := AResult.IsAnomaly;
end;

procedure TIsolationForestDetector.SaveState(const AStream: TStream);
var
  DataCount, i, j: Integer;
begin
  FLock.Enter;
  try
    SaveConfigToStream(AStream);

    // Salva parametri
    AStream.WriteData(FNumTrees);
    AStream.WriteData(FSubSampleSize);
    AStream.WriteData(FMaxDepth);
    AStream.WriteData(FIsTrained);
    AStream.WriteData(FAveragePathLength);
    AStream.WriteData(FFeatureCount);

    // Salva dati di training
    DataCount := Length(FTrainingData);
    AStream.WriteData(DataCount);
    for i := 0 to DataCount - 1 do
    begin
      var FeatureCount := Length(FTrainingData[i]);
      AStream.WriteData(FeatureCount);
      for j := 0 to FeatureCount - 1 do
        AStream.WriteData(FTrainingData[i][j]);
    end;

    // Nota: Gli alberi non vengono serializzati per semplicità
    // In produzione si potrebbe implementare la serializzazione completa
  finally
    FLock.Leave;
  end;
end;

procedure TIsolationForestDetector.LoadState(const AStream: TStream);
var
  DataCount, i, j, FeatureCount: Integer;
begin
  FLock.Enter;
  try
    LoadConfigFromStream(AStream);

    AStream.ReadData(FNumTrees);
    AStream.ReadData(FSubSampleSize);
    AStream.ReadData(FMaxDepth);
    AStream.ReadData(FIsTrained);
    AStream.ReadData(FAveragePathLength);
    AStream.ReadData(FFeatureCount);

    // Carica dati di training
    AStream.ReadData(DataCount);
    SetLength(FTrainingData, DataCount);
    for i := 0 to DataCount - 1 do
    begin
      AStream.ReadData(FeatureCount);
      SetLength(FTrainingData[i], FeatureCount);
      for j := 0 to FeatureCount - 1 do
        AStream.ReadData(FTrainingData[i][j]);
    end;

    // Se erano stati allenati, riallena
    if FIsTrained then
    begin
      FIsTrained := False;
      Train;
    end;
  finally
    FLock.Leave;
  end;
end;

{ TAnomalyConfirmationSystem }

constructor TAnomalyConfirmationSystem.Create(AWindowSize: Integer; AConfirmationThreshold: Integer; ATolerance: Double);
begin
  inherited Create;
  FWindowSize := AWindowSize;
  FConfirmationThreshold := AConfirmationThreshold;
  FTolerance := ATolerance;
  FRecentAnomalies := TList<Double>.Create;
  FLock := TCriticalSection.Create;
end;

destructor TAnomalyConfirmationSystem.Destroy;
begin
  FLock.Free;
  FRecentAnomalies.Free;
  inherited Destroy;
end;

procedure TAnomalyConfirmationSystem.AddPotentialAnomaly(const AValue: Double);
begin
  FLock.Enter;
  try
    FRecentAnomalies.Add(AValue);

    // Keep only recent anomalies
    while FRecentAnomalies.Count > FWindowSize do
      FRecentAnomalies.Delete(0);
  finally
    FLock.Leave;
  end;
end;

function TAnomalyConfirmationSystem.IsConfirmedAnomaly(const AValue: Double): Boolean;
var
  AnomalyCount: Integer;
  i: Integer;
  ToleranceValue: Double;
begin
  FLock.Enter;
  try
    AnomalyCount := 0;
    ToleranceValue := Max(Abs(AValue), 1) * FTolerance;

    // Count how many similar anomalies occurred recently
    for i := 0 to FRecentAnomalies.Count - 1 do
    begin
      if Abs(FRecentAnomalies[i] - AValue) < ToleranceValue then
        Inc(AnomalyCount);
    end;

    Result := AnomalyCount >= FConfirmationThreshold;
  finally
    FLock.Leave;
  end;
end;

procedure TAnomalyConfirmationSystem.SaveState(const AStream: TStream);
var
  Count, i: Integer;
begin
  FLock.Enter;
  try
    // Save parameters
    AStream.WriteData(FWindowSize);
    AStream.WriteData(FConfirmationThreshold);
    AStream.WriteData(FTolerance);

    // Save recent anomalies
    Count := FRecentAnomalies.Count;
    AStream.WriteData(Count);
    for i := 0 to Count - 1 do
      AStream.WriteData(FRecentAnomalies[i]);
  finally
    FLock.Leave;
  end;
end;

procedure TAnomalyConfirmationSystem.LoadState(const AStream: TStream);
var
  Count, i: Integer;
  Value: Double;
begin
  FLock.Enter;
  try
    // Load parameters
    AStream.ReadData(FWindowSize);
    AStream.ReadData(FConfirmationThreshold);
    AStream.ReadData(FTolerance);

    // Load recent anomalies
    FRecentAnomalies.Clear;
    AStream.ReadData(Count);
    for i := 0 to Count - 1 do
    begin
      AStream.ReadData(Value);
      FRecentAnomalies.Add(Value);
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TAnomalyConfirmationSystem.SaveToFile(const AFileName: string);
var
  FileStream: TFileStream;
begin
  FileStream := TFileStream.Create(AFileName, fmCreate);
  try
    SaveState(FileStream);
  finally
    FileStream.Free;
  end;
end;

procedure TAnomalyConfirmationSystem.LoadFromFile(const AFileName: string);
var
  FileStream: TFileStream;
begin
  FileStream := TFileStream.Create(AFileName, fmOpenRead);
  try
    LoadState(FileStream);
  finally
    FileStream.Free;
  end;
end;

{ TAnomalyDetectorFactory }

class function TAnomalyDetectorFactory.CreateDetector(AType: TAnomalyDetectorType): TBaseAnomalyDetector;
begin
  Result := CreateDetector(AType, TAnomalyDetectionConfig.Default);
end;

class function TAnomalyDetectorFactory.CreateDetector(AType: TAnomalyDetectorType;
  const AConfig: TAnomalyDetectionConfig): TBaseAnomalyDetector;
begin
  case AType of
    adtThreeSigma: Result := TThreeSigmaDetector.Create(AConfig);
    adtSlidingWindow: Result := TSlidingWindowDetector.Create(100, AConfig);
    adtEMA: Result := TEMAAnomalyDetector.Create(0.1, AConfig);
    adtAdaptive: Result := TAdaptiveAnomalyDetector.Create(1000, 0.01, AConfig);
    adtIsolationForest: Result := TIsolationForestDetector.Create(100, 256, 10, AConfig);
  else
    raise EAnomalyDetectionException.Create('Unknown detector type');
  end;
end;

class function TAnomalyDetectorFactory.CreateForWebTrafficMonitoring: TBaseAnomalyDetector;
var
  Config: TAnomalyDetectionConfig;
begin
  Config := TAnomalyDetectionConfig.Default;
  Config.SigmaMultiplier := 2.5; // Più sensibile per sicurezza web
  Result := CreateDetector(adtSlidingWindow, Config);
end;

class function TAnomalyDetectorFactory.CreateForFinancialData: TBaseAnomalyDetector;
var
  Config: TAnomalyDetectionConfig;
begin
  Config := TAnomalyDetectionConfig.Default;
  Config.SigmaMultiplier := 3.0; // Standard per dati finanziari
  Config.MinStdDev := 0.01; // Maggiore precisione
  Result := CreateDetector(adtEMA, Config);
end;

class function TAnomalyDetectorFactory.CreateForIoTSensors: TBaseAnomalyDetector;
var
  Config: TAnomalyDetectionConfig;
begin
  Config := TAnomalyDetectionConfig.Default;
  Config.SigmaMultiplier := 2.0; // Sensibile ai guasti sensori
  Result := CreateDetector(adtAdaptive, Config);
end;

class function TAnomalyDetectorFactory.CreateForHighDimensionalData: TBaseAnomalyDetector;
var
  Config: TAnomalyDetectionConfig;
begin
  Config := TAnomalyDetectionConfig.Default;
  Config.SigmaMultiplier := 2.5;
  Result := CreateDetector(adtIsolationForest, Config);
end;

end.
