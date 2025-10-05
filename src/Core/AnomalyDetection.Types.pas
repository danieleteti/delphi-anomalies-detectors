// ***************************************************************************
//
// Copyright (c) 2025 Daniele Teti - All Rights Reserved
//
// Anomaly Detection Types and Records
// Common types shared across all detector implementations
//
// ***************************************************************************

unit AnomalyDetection.Types;

interface

uses
  System.SysUtils, System.DateUtils;

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
  /// Cluster state for DBSCAN algorithm
  /// </summary>
  TClusterState = (csUnvisited, csNoise, csClustered);

  /// <summary>
  /// Point for DBSCAN clustering
  /// </summary>
  TClusterPoint = record
    Features: TArray<Double>;
    ClusterID: Integer;
    State: TClusterState;
    Index: Integer;
  end;

  /// <summary>
  /// Kernel types for One-Class SVM
  /// </summary>
  TKernelType = (ktLinear, ktRBF, ktPolynomial, ktSigmoid);

  /// <summary>
  /// Seasonal component for S-H-ESD
  /// </summary>
  TSeasonalComponent = record
    Seasonal: TArray<Double>;
    Trend: TArray<Double>;
    Remainder: TArray<Double>;
  end;

  /// <summary>
  /// Time series data point with timestamp
  /// </summary>
  TTimeSeriesPoint = record
    Timestamp: TDateTime;
    Value: Double;
  end;

  /// <summary>
  /// LSTM cell state
  /// </summary>
  TLSTMState = record
    CellState: TArray<Double>;
    HiddenState: TArray<Double>;
  end;

  /// <summary>
  /// Detector types for factory pattern
  /// </summary>
  TAnomalyDetectorType = (
    adtThreeSigma,
    adtSlidingWindow,
    adtEMA,
    adtAdaptive,
    adtIsolationForest,
    adtDBSCAN,
    adtOneClassSVM,
    adtSeasonalHybridESD,
    adtLSTMAutoencoder
  );

implementation

{ TAnomalyDetectionConfig }

class function TAnomalyDetectionConfig.Default: TAnomalyDetectionConfig;
begin
  Result.SigmaMultiplier := 3.0;
  Result.MinStdDev := 0.001;
end;

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

end.
