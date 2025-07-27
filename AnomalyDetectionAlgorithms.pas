unit AnomalyDetectionAlgorithms;

{
  Anomaly Detection Algorithms Unit
  Contains various statistical anomaly detection methods for business applications
}

interface

uses
  System.SysUtils, System.Classes, System.Math, System.Generics.Collections;

type
  /// <summary>
  /// Base class for all anomaly detection algorithms
  /// </summary>
  TBaseAnomalyDetector = class
  protected
    FName: string;
  public
    constructor Create(const AName: string);
    function IsAnomaly(const AValue: Double): Boolean; virtual; abstract;
    function GetAnomalyInfo(const AValue: Double): string; virtual; abstract;
    property Name: string read FName;
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
  public
    constructor Create;
    procedure SetHistoricalData(const AData: TArray<Double>);
    procedure CalculateStatistics;
    function IsAnomaly(const AValue: Double): Boolean; override;
    function GetAnomalyInfo(const AValue: Double): string; override;
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
    FWindowData: TQueue<Double>;
    FWindowSize: Integer;
    FMean: Double;
    FStdDev: Double;
    FLowerLimit: Double;
    FUpperLimit: Double;
  public
    constructor Create(AWindowSize: Integer = 100);
    destructor Destroy; override;
    procedure AddValue(const AValue: Double);
    procedure RecalculateStatistics;
    function IsAnomaly(const AValue: Double): Boolean; override;
    function GetAnomalyInfo(const AValue: Double): string; override;
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
  public
    constructor Create(AAlpha: Double = 0.1);
    procedure AddValue(const AValue: Double);
    function IsAnomaly(const AValue: Double): Boolean; override;
    function GetAnomalyInfo(const AValue: Double): string; override;
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
    FSlidingWindow: TQueue<Double>;
    FWindowSize: Integer;
    FMean: Double;
    FVariance: Double;
    FStdDev: Double;
    FAdaptationRate: Double;
    FAlertThreshold: Double;
    FInitialized: Boolean;
  public
    constructor Create(AWindowSize: Integer = 1000; AAdaptationRate: Double = 0.01);
    destructor Destroy; override;
    procedure ProcessValue(const AValue: Double);
    procedure UpdateNormal(const AValue: Double);
    function IsAnomaly(const AValue: Double): Boolean; override;
    function GetAnomalyInfo(const AValue: Double): string; override;
    property CurrentMean: Double read FMean;
    property CurrentStdDev: Double read FStdDev;
  end;

  /// <summary>
  /// Confirmation system to reduce false positives
  /// </summary>
  TAnomalyConfirmationSystem = class
  private
    FRecentAnomalies: TQueue<Double>;
    FConfirmationThreshold: Integer;
    FWindowSize: Integer;
  public
    constructor Create(AWindowSize: Integer = 10; AConfirmationThreshold: Integer = 3);
    destructor Destroy; override;
    function IsConfirmedAnomaly(const AValue: Double): Boolean;
    procedure AddPotentialAnomaly(const AValue: Double);
    property ConfirmationThreshold: Integer read FConfirmationThreshold;
    property WindowSize: Integer read FWindowSize;
  end;

implementation

{ TBaseAnomalyDetector }

constructor TBaseAnomalyDetector.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
end;

{ TThreeSigmaDetector }

constructor TThreeSigmaDetector.Create;
begin
  inherited Create('3-Sigma Detector');
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
begin
  if Length(FData) = 0 then
    raise Exception.Create('No historical data available');

  // Calculate mean
  Sum := 0;
  for i := 0 to High(FData) do
    Sum := Sum + FData[i];
  FMean := Sum / Length(FData);

  // Calculate standard deviation
  Sum := 0;
  for i := 0 to High(FData) do
    Sum := Sum + Power(FData[i] - FMean, 2);
  FStdDev := Sqrt(Sum / Length(FData));

  // Calculate 3-sigma limits
  FLowerLimit := FMean - (3 * FStdDev);
  FUpperLimit := FMean + (3 * FStdDev);

  FIsCalculated := True;
end;

function TThreeSigmaDetector.IsAnomaly(const AValue: Double): Boolean;
begin
  if not FIsCalculated then
    raise Exception.Create('Statistics not calculated. Call CalculateStatistics first.');
    
  Result := (AValue < FLowerLimit) or (AValue > FUpperLimit);
end;

function TThreeSigmaDetector.GetAnomalyInfo(const AValue: Double): string;
begin
  if not FIsCalculated then
    raise Exception.Create('Statistics not calculated. Call CalculateStatistics first.');
    
  if IsAnomaly(AValue) then
  begin
    if AValue < FLowerLimit then
      Result := Format('ANOMALY: Value %.2f below lower limit (%.2f)', 
                      [AValue, FLowerLimit])
    else
      Result := Format('ANOMALY: Value %.2f above upper limit (%.2f)', 
                      [AValue, FUpperLimit]);
  end
  else
    Result := Format('Normal value: %.2f (range: %.2f - %.2f)', 
                    [AValue, FLowerLimit, FUpperLimit]);
end;

{ TSlidingWindowDetector }

constructor TSlidingWindowDetector.Create(AWindowSize: Integer);
begin
  inherited Create('Sliding Window Detector');
  FWindowSize := AWindowSize;
  FWindowData := TQueue<Double>.Create;
end;

destructor TSlidingWindowDetector.Destroy;
begin
  FWindowData.Free;
  inherited Destroy;
end;

procedure TSlidingWindowDetector.AddValue(const AValue: Double);
begin
  // Add new value
  FWindowData.Enqueue(AValue);
  
  // Remove oldest value if window is full
  if FWindowData.Count > FWindowSize then
    FWindowData.Dequeue;
  
  // Recalculate statistics
  RecalculateStatistics;
end;

procedure TSlidingWindowDetector.RecalculateStatistics;
var
  Values: TArray<Double>;
  i: Integer;
  Sum: Double;
begin
  // Convert queue to array for calculations
  Values := FWindowData.ToArray;
  
  if Length(Values) = 0 then 
  begin
    FMean := 0;
    FStdDev := 0;
    FLowerLimit := 0;
    FUpperLimit := 0;
    Exit;
  end;
  
  // Calculate mean
  Sum := 0;
  for i := 0 to High(Values) do
    Sum := Sum + Values[i];
  FMean := Sum / Length(Values);
  
  // Calculate standard deviation
  Sum := 0;
  for i := 0 to High(Values) do
    Sum := Sum + Power(Values[i] - FMean, 2);
  FStdDev := Sqrt(Sum / Length(Values));
  
  // Calculate 3-sigma limits
  FLowerLimit := FMean - (3 * FStdDev);
  FUpperLimit := FMean + (3 * FStdDev);
end;

function TSlidingWindowDetector.IsAnomaly(const AValue: Double): Boolean;
begin
  Result := (AValue < FLowerLimit) or (AValue > FUpperLimit);
end;

function TSlidingWindowDetector.GetAnomalyInfo(const AValue: Double): string;
begin
  if IsAnomaly(AValue) then
  begin
    if AValue < FLowerLimit then
      Result := Format('WINDOW ANOMALY: Value %.2f below lower limit (%.2f)', 
                      [AValue, FLowerLimit])
    else
      Result := Format('WINDOW ANOMALY: Value %.2f above upper limit (%.2f)', 
                      [AValue, FUpperLimit]);
  end
  else
    Result := Format('Normal value: %.2f (range: %.2f - %.2f)', 
                    [AValue, FLowerLimit, FUpperLimit]);
end;

{ TEMAAnomalyDetector }

constructor TEMAAnomalyDetector.Create(AAlpha: Double);
begin
  inherited Create('Exponential Moving Average Detector');
  FAlpha := AAlpha;
  FInitialized := False;
end;

procedure TEMAAnomalyDetector.AddValue(const AValue: Double);
begin
  if not FInitialized then
  begin
    FCurrentMean := AValue;
    FCurrentVariance := 0;
    FInitialized := True;
    FCurrentStdDev := Sqrt(FCurrentVariance);
  end
  else
  begin
    // Update exponential moving average
    FCurrentMean := FAlpha * AValue + (1 - FAlpha) * FCurrentMean;
    
    // Update variance
    var Delta := AValue - FCurrentMean;
    FCurrentVariance := FAlpha * Delta * Delta + (1 - FAlpha) * FCurrentVariance;
  end;
  
  // Calculate 3-sigma limits
  FCurrentStdDev := Sqrt(FCurrentVariance);
  FLowerLimit := FCurrentMean - (3 * FCurrentStdDev);
  FUpperLimit := FCurrentMean + (3 * FCurrentStdDev);
end;

function TEMAAnomalyDetector.IsAnomaly(const AValue: Double): Boolean;
begin
  if not FInitialized then
    Result := False
  else
    Result := (AValue < FLowerLimit) or (AValue > FUpperLimit);
end;

function TEMAAnomalyDetector.GetAnomalyInfo(const AValue: Double): string;
begin
  if not FInitialized then
    Result := Format('EMA not initialized. First value: %.2f', [AValue])
  else if IsAnomaly(AValue) then
  begin
    if AValue < FLowerLimit then
      Result := Format('EMA ANOMALY: Value %.2f below lower limit (%.2f)', 
                      [AValue, FLowerLimit])
    else
      Result := Format('EMA ANOMALY: Value %.2f above upper limit (%.2f)', 
                      [AValue, FUpperLimit]);
  end
  else
    Result := Format('Normal value: %.2f (EMA: %.2f, range: %.2f - %.2f)', 
                    [AValue, FCurrentMean, FLowerLimit, FUpperLimit]);
end;

{ TAdaptiveAnomalyDetector }

constructor TAdaptiveAnomalyDetector.Create(AWindowSize: Integer; AAdaptationRate: Double);
begin
  inherited Create('Adaptive Detector');
  FWindowSize := AWindowSize;
  FAdaptationRate := AAdaptationRate;
  FSlidingWindow := TQueue<Double>.Create;
  FAlertThreshold := 3.0;
  FInitialized := False;
end;

destructor TAdaptiveAnomalyDetector.Destroy;
begin
  FSlidingWindow.Free;
  inherited Destroy;
end;

procedure TAdaptiveAnomalyDetector.ProcessValue(const AValue: Double);
begin
  // Add value to sliding window
  FSlidingWindow.Enqueue(AValue);
  if FSlidingWindow.Count > FWindowSize then
    FSlidingWindow.Dequeue;
    
  // Initialize if needed
  if not FInitialized and (FSlidingWindow.Count > 10) then
  begin
    FMean := AValue;
    FVariance := 1;
    FInitialized := True;
  end;
end;

procedure TAdaptiveAnomalyDetector.UpdateNormal(const AValue: Double);
begin
  if not FInitialized then
  begin
    FMean := AValue;
    FVariance := 1;
    FInitialized := True;
  end
  else
  begin
    var ZScore := Abs(AValue - FMean) / Max(Sqrt(FVariance), 0.001);
    if ZScore <= FAlertThreshold then
    begin
      // Value is normal, gradually update parameters
      FMean := FMean + FAdaptationRate * (AValue - FMean);
      var NewVariance := FVariance + FAdaptationRate * (Power(AValue - FMean, 2) - FVariance);
      FVariance := Max(NewVariance, 0.1); // Prevent variance from becoming too small
    end;
  end;
end;

function TAdaptiveAnomalyDetector.IsAnomaly(const AValue: Double): Boolean;
begin
  if not FInitialized then
    Result := False
  else
  begin
    var StdDev := Max(Sqrt(FVariance), 0.001);
    var ZScore := Abs(AValue - FMean) / StdDev;
    Result := ZScore > FAlertThreshold;
  end;
end;

function TAdaptiveAnomalyDetector.GetAnomalyInfo(const AValue: Double): string;
begin
  if not FInitialized then
    Result := Format('Adaptive detector not initialized. First value: %.2f', [AValue])
  else
  begin
    var StdDev := Max(Sqrt(FVariance), 0.001);
    var ZScore := Abs(AValue - FMean) / StdDev;
    
    if IsAnomaly(AValue) then
      Result := Format('ADAPTIVE ANOMALY: Value %.2f (Z-score: %.2f, threshold: %.2f)', 
                      [AValue, ZScore, FAlertThreshold])
    else
      Result := Format('Normal value: %.2f (Z-score: %.2f, mean: %.2f)', 
                      [AValue, ZScore, FMean]);
  end;
end;

{ TAnomalyConfirmationSystem }

constructor TAnomalyConfirmationSystem.Create(AWindowSize: Integer; AConfirmationThreshold: Integer);
begin
  inherited Create;
  FWindowSize := AWindowSize;
  FConfirmationThreshold := AConfirmationThreshold;
  FRecentAnomalies := TQueue<Double>.Create;
end;

destructor TAnomalyConfirmationSystem.Destroy;
begin
  FRecentAnomalies.Free;
  inherited Destroy;
end;

procedure TAnomalyConfirmationSystem.AddPotentialAnomaly(const AValue: Double);
begin
  FRecentAnomalies.Enqueue(AValue);
  if FRecentAnomalies.Count > FWindowSize then
    FRecentAnomalies.Dequeue;
end;

function TAnomalyConfirmationSystem.IsConfirmedAnomaly(const AValue: Double): Boolean;
var
  AnomalyCount: Integer;
  RecentValue: Double;
begin
  AnomalyCount := 0;
  
  // Count how many similar anomalies occurred recently
  for RecentValue in FRecentAnomalies do
  begin
    if Abs(RecentValue - AValue) < (Max(Abs(AValue), 1) * 0.1) then // 10% tolerance
      Inc(AnomalyCount);
  end;
  
  Result := AnomalyCount >= FConfirmationThreshold;
end;

end.