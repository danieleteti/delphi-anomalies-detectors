unit AnomalyDetectionAlgorithms;

{
  Anomaly Detection Algorithms Unit
  Contains various statistical anomaly detection methods for business applications

  Improvements:
  - Fixed standard deviation calculation (using sample formula N-1)
  - Improved performance for sliding window
  - Complete implementation of adaptive detector
  - Better edge case handling
  - Added configurable sigma multiplier
}

interface

uses
  System.SysUtils, System.Classes, System.Math, System.Generics.Collections,
  System.SyncObjs;

type
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
  /// Base class for all anomaly detection algorithms
  /// </summary>
  TBaseAnomalyDetector = class
  protected
    FName: string;
    FConfig: TAnomalyDetectionConfig;
    FLock: TCriticalSection;
  public
    constructor Create(const AName: string); overload;
    constructor Create(const AName: string; const AConfig: TAnomalyDetectionConfig); overload;
    destructor Destroy; override;
    function Detect(const AValue: Double): TAnomalyResult; virtual; abstract;
    function IsAnomaly(const AValue: Double): Boolean; virtual;
    function GetAnomalyInfo(const AValue: Double): string; virtual;
    property Name: string read FName;
    property Config: TAnomalyDetectionConfig read FConfig write FConfig;
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
  public
    constructor Create; overload;
    constructor Create(const AConfig: TAnomalyDetectionConfig); overload;
    procedure SetHistoricalData(const AData: TArray<Double>);
    procedure CalculateStatistics;
    function Detect(const AValue: Double): TAnomalyResult; override;
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
  public
    constructor Create(AWindowSize: Integer = 100); overload;
    constructor Create(AWindowSize: Integer; const AConfig: TAnomalyDetectionConfig); overload;
    destructor Destroy; override;
    procedure AddValue(const AValue: Double);
    function Detect(const AValue: Double): TAnomalyResult; override;
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
  public
    constructor Create(AAlpha: Double = 0.1); overload;
    constructor Create(AAlpha: Double; const AConfig: TAnomalyDetectionConfig); overload;
    procedure AddValue(const AValue: Double);
    function Detect(const AValue: Double): TAnomalyResult; override;
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
  public
    constructor Create(AWindowSize: Integer = 1000; AAdaptationRate: Double = 0.01); overload;
    constructor Create(AWindowSize: Integer; AAdaptationRate: Double; const AConfig: TAnomalyDetectionConfig); overload;
    procedure ProcessValue(const AValue: Double);
    procedure UpdateNormal(const AValue: Double);
    function Detect(const AValue: Double): TAnomalyResult; override;
    property CurrentMean: Double read FMean;
    property CurrentStdDev: Double read FStdDev;
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
  public
    constructor Create(AWindowSize: Integer = 10; AConfirmationThreshold: Integer = 3; ATolerance: Double = 0.1);
    destructor Destroy; override;
    function IsConfirmedAnomaly(const AValue: Double): Boolean;
    procedure AddPotentialAnomaly(const AValue: Double);
    property ConfirmationThreshold: Integer read FConfirmationThreshold;
    property WindowSize: Integer read FWindowSize;
    property Tolerance: Double read FTolerance write FTolerance;
  end;

implementation

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
end;

destructor TBaseAnomalyDetector.Destroy;
begin
  FLock.Free;
  inherited;
end;

function TBaseAnomalyDetector.IsAnomaly(const AValue: Double): Boolean;
begin
  Result := Detect(AValue).IsAnomaly;
end;

function TBaseAnomalyDetector.GetAnomalyInfo(const AValue: Double): string;
begin
  Result := Detect(AValue).Description;
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
  FData := AData;
  FIsCalculated := False;
end;

procedure TThreeSigmaDetector.CalculateStatistics;
var
  i: Integer;
  Sum: Double;
  N: Integer;
begin
  N := Length(FData);
  if N = 0 then
    raise Exception.Create('No historical data available');

  if N = 1 then
    raise Exception.Create('Need at least 2 data points for standard deviation');

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
end;

procedure TThreeSigmaDetector.CalculateLimits;
begin
  FLowerLimit := FMean - (FConfig.SigmaMultiplier * FStdDev);
  FUpperLimit := FMean + (FConfig.SigmaMultiplier * FStdDev);
end;

function TThreeSigmaDetector.Detect(const AValue: Double): TAnomalyResult;
begin
  if not FIsCalculated then
    raise Exception.Create('Statistics not calculated. Call CalculateStatistics first.');

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

function TSlidingWindowDetector.Detect(const AValue: Double): TAnomalyResult;
begin
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
end;

procedure TEMAAnomalyDetector.CalculateLimits;
begin
  FLowerLimit := FCurrentMean - (FConfig.SigmaMultiplier * FCurrentStdDev);
  FUpperLimit := FCurrentMean + (FConfig.SigmaMultiplier * FCurrentStdDev);
end;

function TEMAAnomalyDetector.Detect(const AValue: Double): TAnomalyResult;
begin
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
begin
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

    // If not an anomaly, update statistics
    if not IsAnomaly(AValue) then
      UpdateNormal(AValue);
  end;

  CalculateLimits;
end;

procedure TAdaptiveAnomalyDetector.UpdateNormal(const AValue: Double);
var
  Delta: Double;
  NewMean: Double;
  NewVariance: Double;
begin
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
end;

procedure TAdaptiveAnomalyDetector.CalculateLimits;
begin
  // Dynamic limits based on current statistics
  // Note: Limits are calculated dynamically in Detect method
  // This method is kept for interface consistency
end;

function TAdaptiveAnomalyDetector.Detect(const AValue: Double): TAnomalyResult;
begin
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
end;

{ TAnomalyConfirmationSystem }

constructor TAnomalyConfirmationSystem.Create(AWindowSize: Integer; AConfirmationThreshold: Integer; ATolerance: Double);
begin
  inherited Create;
  FWindowSize := AWindowSize;
  FConfirmationThreshold := AConfirmationThreshold;
  FTolerance := ATolerance;
  FRecentAnomalies := TList<Double>.Create;
end;

destructor TAnomalyConfirmationSystem.Destroy;
begin
  FRecentAnomalies.Free;
  inherited Destroy;
end;

procedure TAnomalyConfirmationSystem.AddPotentialAnomaly(const AValue: Double);
begin
  FRecentAnomalies.Add(AValue);

  // Keep only recent anomalies
  while FRecentAnomalies.Count > FWindowSize do
    FRecentAnomalies.Delete(0);
end;

function TAnomalyConfirmationSystem.IsConfirmedAnomaly(const AValue: Double): Boolean;
var
  AnomalyCount: Integer;
  i: Integer;
  ToleranceValue: Double;
begin
  AnomalyCount := 0;
  ToleranceValue := Max(Abs(AValue), 1) * FTolerance;

  // Count how many similar anomalies occurred recently
  for i := 0 to FRecentAnomalies.Count - 1 do
  begin
    if Abs(FRecentAnomalies[i] - AValue) < ToleranceValue then
      Inc(AnomalyCount);
  end;

  Result := AnomalyCount >= FConfirmationThreshold;
end;

end.
