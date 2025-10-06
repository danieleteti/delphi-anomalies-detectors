// ***************************************************************************
//
// Copyright (c) 2025 Daniele Teti - All Rights Reserved
//
// EMA Anomaly Detector
// Exponential Moving Average for adaptive detection
//
// ***************************************************************************

unit AnomalyDetection.EMA;

interface

uses
  System.SysUtils, System.Classes, System.Math, System.SyncObjs,
  AnomalyDetection.Types,
  AnomalyDetection.Base;

type
  /// <summary>
  /// Exponential Moving Average for adaptive anomaly detection
  /// Best for: Real-time adaptation, trending data, minimal memory
  /// </summary>
  TEMAAnomalyDetector = class(TBaseAnomalyDetector, IStatisticalAnomalyDetector)
  private
    FAlpha: Double;
    FCurrentMean: Double;
    FCurrentVariance: Double;
    FCurrentStdDev: Double;
    FInitialized: Boolean;
    FLowerLimit: Double;
    FUpperLimit: Double;
    procedure CalculateLimits;

    // Interface implementation
    function GetMean: Double;
    function GetStdDev: Double;
    function GetLowerLimit: Double;
    function GetUpperLimit: Double;
  protected
    procedure CheckAndNotifyAnomaly(const AResult: TAnomalyResult);
  public
    constructor Create(AAlpha: Double = 0.1); overload;
    constructor Create(AAlpha: Double; const AConfig: TAnomalyDetectionConfig); overload;
    procedure AddValue(const AValue: Double); override;
    procedure WarmUp(const ABaselineData: TArray<Double>);
    function Detect(const AValue: Double): TAnomalyResult; override;
    procedure SaveState(const AStream: TStream); override;
    procedure LoadState(const AStream: TStream); override;
    function IsInitialized: Boolean; override;
    property CurrentMean: Double read FCurrentMean;
    property CurrentStdDev: Double read FCurrentStdDev;
    property Alpha: Double read FAlpha;
    property LowerLimit: Double read FLowerLimit;
    property UpperLimit: Double read FUpperLimit;
  end;

implementation

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

procedure TEMAAnomalyDetector.WarmUp(const ABaselineData: TArray<Double>);
var
  i: Integer;
begin
  for i := 0 to High(ABaselineData) do
    AddValue(ABaselineData[i]);
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

function TEMAAnomalyDetector.IsInitialized: Boolean;
begin
  Result := FInitialized;
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
    SaveConfigToStream(AStream);
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
    LoadConfigFromStream(AStream);
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

// IStatisticalAnomalyDetector interface implementation

function TEMAAnomalyDetector.GetMean: Double;
begin
  Result := FCurrentMean;
end;

function TEMAAnomalyDetector.GetStdDev: Double;
begin
  Result := FCurrentStdDev;
end;

function TEMAAnomalyDetector.GetLowerLimit: Double;
begin
  Result := FLowerLimit;
end;

function TEMAAnomalyDetector.GetUpperLimit: Double;
begin
  Result := FUpperLimit;
end;

end.
