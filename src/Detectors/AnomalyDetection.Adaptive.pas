// ***************************************************************************
//
// Copyright (c) 2025 Daniele Teti - All Rights Reserved
//
// Adaptive Anomaly Detector
// Learning detector that adapts to normal patterns
//
// ***************************************************************************

unit AnomalyDetection.Adaptive;

interface

uses
  System.SysUtils, System.Classes, System.Math, System.SyncObjs,
  AnomalyDetection.Types,
  AnomalyDetection.Base;

type
  /// <summary>
  /// Adaptive detector that learns from confirmed normal values
  /// Best for: Learning systems, evolving patterns, feedback-driven
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
    procedure InitializeWithNormalData(const ANormalData: TArray<Double>);
    function Detect(const AValue: Double): TAnomalyResult; override;
    procedure SaveState(const AStream: TStream); override;
    procedure LoadState(const AStream: TStream); override;
    function IsInitialized: Boolean; override;
    property CurrentMean: Double read FMean;
    property CurrentStdDev: Double read FStdDev;
    property WindowSize: Integer read FWindowSize;
    property Tolerance: Double read FAdaptationRate write FAdaptationRate;
  end;

implementation

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

      Result.LowerLimit := FMean - (FConfig.SigmaMultiplier * FStdDev);
      Result.UpperLimit := FMean + (FConfig.SigmaMultiplier * FStdDev);

      if FStdDev > 0 then
        Result.ZScore := Abs(AValue - FMean) / FStdDev
      else
        Result.ZScore := 0;

      Result.IsAnomaly := Result.ZScore > FConfig.SigmaMultiplier;

      if not Result.IsAnomaly then
      begin
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
  Delta, NewMean, NewVariance: Double;
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
      Delta := AValue - FMean;
      NewMean := FMean + FAdaptationRate * Delta;
      NewVariance := (1 - FAdaptationRate) * FVariance + FAdaptationRate * Delta * (AValue - NewMean);

      FMean := NewMean;
      FVariance := NewVariance;

      if FVariance < FConfig.MinStdDev * FConfig.MinStdDev then
        FVariance := FConfig.MinStdDev * FConfig.MinStdDev;

      FStdDev := Sqrt(FVariance);
    end;

    CalculateLimits;
  finally
    FLock.Leave;
  end;
end;

procedure TAdaptiveAnomalyDetector.InitializeWithNormalData(const ANormalData: TArray<Double>);
var
  i, N: Integer;
  Sum, SumSquares: Double;
begin
  FLock.Enter;
  try
    N := Length(ANormalData);
    if N = 0 then Exit;

    Sum := 0;
    for i := 0 to High(ANormalData) do
      Sum := Sum + ANormalData[i];
    FMean := Sum / N;

    SumSquares := 0;
    for i := 0 to High(ANormalData) do
      SumSquares := SumSquares + Power(ANormalData[i] - FMean, 2);

    if N > 1 then
      FVariance := SumSquares / (N - 1)
    else
      FVariance := FConfig.MinStdDev * FConfig.MinStdDev;

    if FVariance < FConfig.MinStdDev * FConfig.MinStdDev then
      FVariance := FConfig.MinStdDev * FConfig.MinStdDev;

    FStdDev := Sqrt(FVariance);
    FInitialized := True;
    FSampleCount := N;

    CalculateLimits;
  finally
    FLock.Leave;
  end;
end;

procedure TAdaptiveAnomalyDetector.CalculateLimits;
begin
  // Dynamic limits calculated in Detect
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

function TAdaptiveAnomalyDetector.IsInitialized: Boolean;
begin
  Result := FInitialized;
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
        Result.Description := Format('ADAPTIVE ANOMALY: Value %.2f (mean: %.2f, Z-score: %.2f)',
                                    [AValue, FMean, Result.ZScore])
      else
        Result.Description := Format('Normal value: %.2f (mean: %.2f, range: %.2f - %.2f)',
                                    [AValue, FMean, Result.LowerLimit, Result.UpperLimit]);
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
    SaveConfigToStream(AStream);
    AStream.WriteData(FWindowSize);
    AStream.WriteData(FAdaptationRate);
    AStream.WriteData(FInitialized);
    AStream.WriteData(FMean);
    AStream.WriteData(FVariance);
    AStream.WriteData(FStdDev);
    AStream.WriteData(FSampleCount);
  finally
    FLock.Leave;
  end;
end;

procedure TAdaptiveAnomalyDetector.LoadState(const AStream: TStream);
begin
  FLock.Enter;
  try
    LoadConfigFromStream(AStream);
    AStream.ReadData(FWindowSize);
    AStream.ReadData(FAdaptationRate);
    AStream.ReadData(FInitialized);
    AStream.ReadData(FMean);
    AStream.ReadData(FVariance);
    AStream.ReadData(FStdDev);
    AStream.ReadData(FSampleCount);
  finally
    FLock.Leave;
  end;
end;

end.
