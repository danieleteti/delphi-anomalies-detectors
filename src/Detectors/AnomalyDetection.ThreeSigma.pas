// ***************************************************************************
//
// Copyright (c) 2025 Daniele Teti - All Rights Reserved
//
// Three Sigma Anomaly Detector
// Traditional 3-Sigma rule based on historical data
//
// ***************************************************************************

unit AnomalyDetection.ThreeSigma;

interface

uses
  System.SysUtils, System.Classes, System.Math, System.SyncObjs,
  System.Generics.Collections,
  AnomalyDetection.Types,
  AnomalyDetection.Base;

type
  /// <summary>
  /// Traditional 3-Sigma rule based on historical data
  /// Best for: Historical data analysis, static datasets, batch processing
  /// </summary>
  TThreeSigmaDetector = class(TBaseAnomalyDetector, IStatisticalAnomalyDetector)
  private
    FData: TList<Double>;
    FMean: Double;
    FStdDev: Double;
    FLowerLimit: Double;
    FUpperLimit: Double;
    FIsCalculated: Boolean;
    procedure CalculateLimits;
    procedure InternalCalculateStatistics;

    // Interface implementation
    function GetMean: Double;
    function GetStdDev: Double;
    function GetLowerLimit: Double;
    function GetUpperLimit: Double;
  protected
    procedure CheckAndNotifyAnomaly(const AResult: TAnomalyResult);
  public
    constructor Create; overload;
    constructor Create(const AConfig: TAnomalyDetectionConfig); overload;
    destructor Destroy; override;

    // Training phase - add data incrementally
    procedure AddValue(const AValue: Double); override;
    procedure AddValues(const AValues: TArray<Double>); override;

    // Build/finalize phase - calculate statistics from accumulated data
    procedure Build; override;

    function Detect(const AValue: Double): TAnomalyResult; override;
    procedure SaveState(const AStream: TStream); override;
    procedure LoadState(const AStream: TStream); override;
    function IsInitialized: Boolean; override;

    property Mean: Double read FMean;
    property StdDev: Double read FStdDev;
    property LowerLimit: Double read FLowerLimit;
    property UpperLimit: Double read FUpperLimit;
  end;

implementation

{ TThreeSigmaDetector }

constructor TThreeSigmaDetector.Create;
begin
  Create(TAnomalyDetectionConfig.Default);
end;

constructor TThreeSigmaDetector.Create(const AConfig: TAnomalyDetectionConfig);
begin
  inherited Create('3-Sigma Detector', AConfig);
  FData := TList<Double>.Create;
  FIsCalculated := False;
end;

destructor TThreeSigmaDetector.Destroy;
begin
  FData.Free;
  inherited;
end;

procedure TThreeSigmaDetector.AddValue(const AValue: Double);
begin
  FLock.Enter;
  try
    if IsNaN(AValue) or IsInfinite(AValue) then
      raise EAnomalyDetectionException.CreateFmt('Invalid value: %g', [AValue]);

    FData.Add(AValue);
    FIsCalculated := False; // Mark as needing rebuild
  finally
    FLock.Leave;
  end;
end;

procedure TThreeSigmaDetector.AddValues(const AValues: TArray<Double>);
var
  Value: Double;
begin
  FLock.Enter;
  try
    for Value in AValues do
    begin
      if IsNaN(Value) or IsInfinite(Value) then
        raise EAnomalyDetectionException.CreateFmt('Invalid value: %g', [Value]);
      FData.Add(Value);
    end;
    FIsCalculated := False;
  finally
    FLock.Leave;
  end;
end;

procedure TThreeSigmaDetector.Build;
begin
  FLock.Enter;
  try
    InternalCalculateStatistics;
  finally
    FLock.Leave;
  end;
end;

procedure TThreeSigmaDetector.InternalCalculateStatistics;
var
  i: Integer;
  Sum: Double;
  N: Integer;
begin
  // Note: Lock already acquired by caller (Build method)
  N := FData.Count;
  if N = 0 then
    raise EAnomalyDetectionException.Create('No historical data available. Call AddValue() or AddValues() first.');

  if N = 1 then
    raise EAnomalyDetectionException.Create('At least 2 data points required for standard deviation');

  // Calculate mean
  Sum := 0;
  for i := 0 to N - 1 do
    Sum := Sum + FData[i];
  FMean := Sum / N;

  // Calculate standard deviation (sample formula)
  Sum := 0;
  for i := 0 to N - 1 do
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

function TThreeSigmaDetector.IsInitialized: Boolean;
begin
  Result := FIsCalculated;
end;

function TThreeSigmaDetector.Detect(const AValue: Double): TAnomalyResult;
begin
  FLock.Enter;
  try
    if not FIsCalculated then
      raise EAnomalyDetectionException.Create('Statistics not calculated. Call Build() first.');

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
    DataCount := FData.Count;
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
  Value: Double;
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
    FData.Clear;
    FData.Capacity := DataCount;
    for i := 0 to DataCount - 1 do
    begin
      AStream.ReadData(Value);
      FData.Add(Value);
    end;
  finally
    FLock.Leave;
  end;
end;

// IStatisticalAnomalyDetector interface implementation

function TThreeSigmaDetector.GetMean: Double;
begin
  Result := FMean;
end;

function TThreeSigmaDetector.GetStdDev: Double;
begin
  Result := FStdDev;
end;

function TThreeSigmaDetector.GetLowerLimit: Double;
begin
  Result := FLowerLimit;
end;

function TThreeSigmaDetector.GetUpperLimit: Double;
begin
  Result := FUpperLimit;
end;

end.
