// ***************************************************************************
//
// Copyright (c) 2025 Daniele Teti - All Rights Reserved
//
// Sliding Window Anomaly Detector
// Real-time detection with adaptive window
//
// ***************************************************************************

unit AnomalyDetection.SlidingWindow;

interface

uses
  System.SysUtils, System.Classes, System.Math, System.Generics.Collections,
  AnomalyDetection.Types,
  AnomalyDetection.Base;

type
  /// <summary>
  /// Sliding window approach for continuous data streams
  /// Best for: Streaming data, real-time monitoring, changing conditions
  /// </summary>
  TSlidingWindowDetector = class(TBaseAnomalyDetector, IStatisticalAnomalyDetector)
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

    // Interface implementation
    function GetMean: Double;
    function GetStdDev: Double;
    function GetLowerLimit: Double;
    function GetUpperLimit: Double;
  protected
    procedure CheckAndNotifyAnomaly(const AResult: TAnomalyResult);
  public
    constructor Create(AWindowSize: Integer = 100); overload;
    constructor Create(AWindowSize: Integer; const AConfig: TAnomalyDetectionConfig); overload;
    destructor Destroy; override;
    procedure AddValue(const AValue: Double); override;
    procedure InitializeWindow(const AData: TArray<Double>);
    function Detect(const AValue: Double): TAnomalyResult; override;
    procedure SaveState(const AStream: TStream); override;
    procedure LoadState(const AStream: TStream); override;
    function IsInitialized: Boolean; override;
    property CurrentMean: Double read FMean;
    property CurrentStdDev: Double read FStdDev;
    property WindowSize: Integer read FWindowSize;
    property LowerLimit: Double read FLowerLimit;
    property UpperLimit: Double read FUpperLimit;
  end;

implementation

uses
  System.SyncObjs;

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

procedure TSlidingWindowDetector.InitializeWindow(const AData: TArray<Double>);
var
  i: Integer;
begin
  FLock.Enter;
  try
    FWindowData.Clear;
    FSum := 0;
    FSumSquares := 0;

    for i := 0 to High(AData) do
      AddValue(AData[i]);
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

function TSlidingWindowDetector.IsInitialized: Boolean;
begin
  Result := FWindowData.Count > 0;
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

// IStatisticalAnomalyDetector interface implementation

function TSlidingWindowDetector.GetMean: Double;
begin
  Result := FMean;
end;

function TSlidingWindowDetector.GetStdDev: Double;
begin
  Result := FStdDev;
end;

function TSlidingWindowDetector.GetLowerLimit: Double;
begin
  Result := FLowerLimit;
end;

function TSlidingWindowDetector.GetUpperLimit: Double;
begin
  Result := FUpperLimit;
end;

end.
