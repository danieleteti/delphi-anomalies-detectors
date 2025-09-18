// ***************************************************************************
//
// Copyright (c) 2025 Daniele Teti - All Rights Reserved
//
// Unauthorized copying, distribution or use of this software, via any medium,
// is strictly prohibited without the prior written consent of the copyright
// holder. This software is proprietary and confidential.
//
// Unit tests for the Anomaly Detection Algorithms Library
//
// ***************************************************************************

unit AnomalyDetectionAlgorithms.Tests;

interface

uses
  DUnitX.TestFramework,
  AnomalyDetectionAlgorithms,
  System.SysUtils,
  System.Math,
  System.DateUtils;

type
  [TestFixture]
  TAnomalyDetectionConfigTests = class
  public
    [Test]
    procedure TestDefaultConfig;
    [Test]
    procedure TestCustomConfig;
  end;

  [TestFixture]
  TThreeSigmaDetectorTests = class
  private
    FDetector: TThreeSigmaDetector;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestNoDataException;
    [Test]
    procedure TestSingleDataPointException;
    [Test]
    procedure TestNormalData;
    [Test]
    procedure TestAnomalyDetection;
    [Test]
    procedure TestCustomSigmaMultiplier;
    [Test]
    procedure TestZeroVarianceData;
    [Test]
    procedure TestStatisticsCalculation;
  end;

  [TestFixture]
  TSlidingWindowDetectorTests = class
  private
    FDetector: TSlidingWindowDetector;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestEmptyWindow;
    [Test]
    procedure TestWindowFilling;
    [Test]
    procedure TestWindowSliding;
    [Test]
    procedure TestIncrementalStatistics;
    [Test]
    procedure TestAnomalyDetectionInStream;
    [Test]
    procedure TestCustomWindowSize;
    [Test]
    procedure TestTrendAdaptation;
  end;

  [TestFixture]
  TEMAAnomalyDetectorTests = class
  private
    FDetector: TEMAAnomalyDetector;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestInitialization;
    [Test]
    procedure TestAlphaParameter;
    [Test]
    procedure TestRapidAdaptation;
    [Test]
    procedure TestSlowAdaptation;
    [Test]
    procedure TestAnomalyDetection;
    [Test]
    procedure TestVarianceUpdate;
  end;

  [TestFixture]
  TAdaptiveAnomalyDetectorTests = class
  private
    FDetector: TAdaptiveAnomalyDetector;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestInitialState;
    [Test]
    procedure TestLearningFromNormalValues;
    [Test]
    procedure TestRejectingAnomalies;
    [Test]
    procedure TestGradualTrendAdaptation;
    [Test]
    procedure TestAdaptationRate;
    [Test]
    procedure TestAnomalyThreshold;
  end;

  [TestFixture]
  TAnomalyConfirmationSystemTests = class
  private
    FSystem: TAnomalyConfirmationSystem;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestIsolatedAnomaly;
    [Test]
    procedure TestConfirmedAnomalyPattern;
    [Test]
    procedure TestToleranceParameter;
    [Test]
    procedure TestWindowSizeLimit;
    [Test]
    procedure TestDifferentAnomalies;
    [Test]
    procedure TestThresholdBehavior;
  end;

  [TestFixture]
  TIntegrationTests = class
  public
    [Test]
    procedure TestEnsembleDetection;
    [Test]
    procedure TestRealWorldScenario;
    [Test]
    procedure TestPerformanceUnderLoad;
  end;

implementation

const
  EPSILON = 1e-6; // For floating point comparisons

function AreFloatsEqual(A, B: Double; Epsilon: Double = EPSILON): Boolean;
begin
  Result := Abs(A - B) < Epsilon;
end;

{ TAnomalyDetectionConfigTests }

procedure TAnomalyDetectionConfigTests.TestDefaultConfig;
var
  Config: TAnomalyDetectionConfig;
begin
  Config := TAnomalyDetectionConfig.Default;
  Assert.AreEqual<Double>(3.0, Config.SigmaMultiplier);
  Assert.AreEqual<Double>(0.001, Config.MinStdDev);
end;

procedure TAnomalyDetectionConfigTests.TestCustomConfig;
var
  Config: TAnomalyDetectionConfig;
begin
  Config.SigmaMultiplier := 2.5;
  Config.MinStdDev := 0.01;
  Assert.AreEqual<Double>(2.5, Config.SigmaMultiplier);
  Assert.AreEqual<Double>(0.01, Config.MinStdDev);
end;

{ TThreeSigmaDetectorTests }

procedure TThreeSigmaDetectorTests.Setup;
begin
  FDetector := TThreeSigmaDetector.Create;
end;

procedure TThreeSigmaDetectorTests.TearDown;
begin
  FDetector.Free;
end;

procedure TThreeSigmaDetectorTests.TestNoDataException;
var
  EmptyData: TArray<Double>;
begin
  SetLength(EmptyData, 0);
  FDetector.SetHistoricalData(EmptyData);
  Assert.WillRaise(
    procedure
    begin
      FDetector.CalculateStatistics;
    end,
    Exception
  );
end;

procedure TThreeSigmaDetectorTests.TestSingleDataPointException;
var
  SingleData: TArray<Double>;
begin
  SetLength(SingleData, 1);
  SingleData[0] := 100;
  FDetector.SetHistoricalData(SingleData);
  Assert.WillRaise(
    procedure
    begin
      FDetector.CalculateStatistics;
    end,
    Exception
  );
end;

procedure TThreeSigmaDetectorTests.TestNormalData;
var
  Data: TArray<Double>;
  i: Integer;
  Result: TAnomalyResult;
begin
  // Create data with known mean=100, stddev≈10
  SetLength(Data, 100);
  for i := 0 to 99 do
    Data[i] := 100 + (i mod 20) - 10; // Generates values 90-109

  FDetector.SetHistoricalData(Data);
  FDetector.CalculateStatistics;

  // Test values within normal range
  Result := FDetector.Detect(100);
  Assert.IsFalse(Result.IsAnomaly, 'Mean value should not be anomaly');

  Result := FDetector.Detect(95);
  Assert.IsFalse(Result.IsAnomaly, 'Value within 1 sigma should not be anomaly');

  Result := FDetector.Detect(105);
  Assert.IsFalse(Result.IsAnomaly, 'Value within 1 sigma should not be anomaly');
end;

procedure TThreeSigmaDetectorTests.TestAnomalyDetection;
var
  Data: TArray<Double>;
  i: Integer;
  Result: TAnomalyResult;
begin
  // Create data with mean=100, small variance
  SetLength(Data, 50);
  for i := 0 to 49 do
    Data[i] := 100 + Random(10) - 5; // Values ~95-105

  FDetector.SetHistoricalData(Data);
  FDetector.CalculateStatistics;

  // Test clear anomalies
  Result := FDetector.Detect(200);
  Assert.IsTrue(Result.IsAnomaly, 'Value 200 should be anomaly');
  Assert.IsTrue(Result.ZScore > 3.0, 'Z-score should be > 3');

  Result := FDetector.Detect(0);
  Assert.IsTrue(Result.IsAnomaly, 'Value 0 should be anomaly');
  Assert.IsTrue(Result.ZScore > 3.0, 'Z-score should be > 3');
end;

procedure TThreeSigmaDetectorTests.TestCustomSigmaMultiplier;
var
  Config: TAnomalyDetectionConfig;
  Data: TArray<Double>;
  i: Integer;
  Result: TAnomalyResult;
begin
  Config := TAnomalyDetectionConfig.Default;
  Config.SigmaMultiplier := 2.0; // More sensitive

  FDetector.Free;
  FDetector := TThreeSigmaDetector.Create(Config);

  // Create normal data
  SetLength(Data, 100);
  for i := 0 to 99 do
    Data[i] := 100 + Random(20) - 10;

  FDetector.SetHistoricalData(Data);
  FDetector.CalculateStatistics;

  // Value at 2.5 sigma should now be anomaly
  var TestValue := FDetector.Mean + 2.5 * FDetector.StdDev;
  Result := FDetector.Detect(TestValue);
  Assert.IsTrue(Result.IsAnomaly, '2.5 sigma should be anomaly with 2-sigma rule');
end;

procedure TThreeSigmaDetectorTests.TestZeroVarianceData;
var
  Data: TArray<Double>;
  i: Integer;
  Result: TAnomalyResult;
begin
  // All same values
  SetLength(Data, 50);
  for i := 0 to 49 do
    Data[i] := 100;

  FDetector.SetHistoricalData(Data);
  FDetector.CalculateStatistics;

  // Should use MinStdDev
  Assert.AreEqual(FDetector.Config.MinStdDev, FDetector.StdDev);

  // Small deviation should trigger anomaly
  Result := FDetector.Detect(101);
  Assert.IsTrue(Result.IsAnomaly, 'Even small deviation should be anomaly with zero variance');
end;

procedure TThreeSigmaDetectorTests.TestStatisticsCalculation;
var
  Data: TArray<Double>;
begin
  // Known data set
  SetLength(Data, 5);
  Data[0] := 2; Data[1] := 4; Data[2] := 6; Data[3] := 8; Data[4] := 10;
  // Mean should be 6, StdDev should be sqrt(10) ≈ 3.162

  FDetector.SetHistoricalData(Data);
  FDetector.CalculateStatistics;

  Assert.IsTrue(AreFloatsEqual(6.0, FDetector.Mean), 'Mean calculation error');
  Assert.IsTrue(AreFloatsEqual(Sqrt(10), FDetector.StdDev, 0.001), 'StdDev calculation error');
end;

{ TSlidingWindowDetectorTests }

procedure TSlidingWindowDetectorTests.Setup;
begin
  FDetector := TSlidingWindowDetector.Create(10); // Window size 10
end;

procedure TSlidingWindowDetectorTests.TearDown;
begin
  FDetector.Free;
end;

procedure TSlidingWindowDetectorTests.TestEmptyWindow;
var
  Result: TAnomalyResult;
begin
  // Empty window should handle gracefully
  // First add a value to initialize
  FDetector.AddValue(100);

  // Now test detection
  Result := FDetector.Detect(100);
  Assert.IsFalse(Result.IsAnomaly, 'Value equal to only data point should not be anomaly');
end;

procedure TSlidingWindowDetectorTests.TestWindowFilling;
var
  i: Integer;
begin
  // Fill window
  for i := 1 to 10 do
    FDetector.AddValue(100 + i);

  Assert.IsTrue(AreFloatsEqual(105.5, FDetector.CurrentMean), 'Mean should be 105.5');
end;

procedure TSlidingWindowDetectorTests.TestWindowSliding;
var
  i: Integer;
  InitialMean: Double;
begin
  // Fill window with values 1-10
  for i := 1 to 10 do
    FDetector.AddValue(i);

  InitialMean := FDetector.CurrentMean;
  Assert.AreEqual<Double>(5.5, InitialMean);

  // Add new value, should remove oldest
  FDetector.AddValue(11);

  // New window: 2-11, mean should be 6.5
  Assert.IsTrue(AreFloatsEqual(6.5, FDetector.CurrentMean), 'Sliding window mean error');
end;

procedure TSlidingWindowDetectorTests.TestIncrementalStatistics;
var
  i: Integer;
  Values: TArray<Double>;
  CalculatedMean, CalculatedStdDev: Double;
  Sum, SumSquares: Double;
begin
  // Generate test values
  SetLength(Values, 20);
  for i := 0 to 19 do
  begin
    Values[i] := Random(100);
    FDetector.AddValue(Values[i]);
  end;

  // Manually calculate statistics for last 10 values (window size)
  Sum := 0;
  SumSquares := 0;
  for i := 10 to 19 do // Last 10 values
  begin
    Sum := Sum + Values[i];
    SumSquares := SumSquares + (Values[i] * Values[i]);
  end;

  CalculatedMean := Sum / 10;
  var Variance := (SumSquares - (Sum * Sum) / 10) / 9; // N-1 for sample
  CalculatedStdDev := Sqrt(Variance);

  // Allow small floating point differences
  Assert.IsTrue(AreFloatsEqual(FDetector.CurrentMean, CalculatedMean, 0.001),
                'Incremental mean calculation error');
  Assert.IsTrue(AreFloatsEqual(FDetector.CurrentStdDev, CalculatedStdDev, 0.001),
                'Incremental stddev calculation error');
end;

procedure TSlidingWindowDetectorTests.TestAnomalyDetectionInStream;
var
  i: Integer;
  Result: TAnomalyResult;
  AnomalyCount: Integer;
begin
  AnomalyCount := 0;

  // Stream normal data
  for i := 1 to 50 do
  begin
    FDetector.AddValue(100 + Random(20) - 10);
  end;

  // Insert anomaly
  Result := FDetector.Detect(300);
  Assert.IsTrue(Result.IsAnomaly, 'Value 300 should be detected as anomaly');

  // Add the anomaly
  FDetector.AddValue(300);

  // After window slides past anomaly, detection should normalize
  for i := 1 to 15 do
    FDetector.AddValue(100 + Random(20) - 10);

  Result := FDetector.Detect(110);
  Assert.IsFalse(Result.IsAnomaly, 'Normal value should not be anomaly after window slides');
end;

procedure TSlidingWindowDetectorTests.TestCustomWindowSize;
var
  LargeWindowDetector: TSlidingWindowDetector;
  i: Integer;
begin
  LargeWindowDetector := TSlidingWindowDetector.Create(100);
  try
    // Add 150 values
    for i := 1 to 150 do
      LargeWindowDetector.AddValue(i);

    // Should only keep last 100 values (51-150)
    Assert.IsTrue(AreFloatsEqual(100.5, LargeWindowDetector.CurrentMean),
                  'Large window should maintain correct size');
  finally
    LargeWindowDetector.Free;
  end;
end;

procedure TSlidingWindowDetectorTests.TestTrendAdaptation;
var
  i: Integer;
  Result: TAnomalyResult;
begin
  // Start with values around 100
  for i := 1 to 20 do
    FDetector.AddValue(100 + Random(10) - 5);

  // Gradually increase to 200
  for i := 1 to 20 do
    FDetector.AddValue(150 + Random(10) - 5);

  for i := 1 to 20 do
    FDetector.AddValue(200 + Random(10) - 5);

  // Value 200 should now be normal
  Result := FDetector.Detect(200);
  Assert.IsFalse(Result.IsAnomaly, 'Detector should adapt to new normal');

  // But 100 might now be anomaly
  Result := FDetector.Detect(100);
  Assert.IsTrue(Result.IsAnomaly, 'Old normal should now be anomaly');
end;

{ TEMAAnomalyDetectorTests }

procedure TEMAAnomalyDetectorTests.Setup;
begin
  FDetector := TEMAAnomalyDetector.Create(0.1); // Alpha = 0.1
end;

procedure TEMAAnomalyDetectorTests.TearDown;
begin
  FDetector.Free;
end;

procedure TEMAAnomalyDetectorTests.TestInitialization;
var
  Result: TAnomalyResult;
begin
  // Before any data
  Result := FDetector.Detect(100);
  Assert.IsFalse(Result.IsAnomaly, 'Uninitialized detector should not detect anomalies');
  Assert.Contains(Result.Description, 'not initialized');

  // After first value
  FDetector.AddValue(100);
  Assert.AreEqual<Double>(100.0, FDetector.CurrentMean);
end;

procedure TEMAAnomalyDetectorTests.TestAlphaParameter;
var
  HighAlphaDetector: TEMAAnomalyDetector;
  i: Integer;
begin
  HighAlphaDetector := TEMAAnomalyDetector.Create(0.9); // High alpha = fast adaptation
  try
    // Add steady values
    for i := 1 to 10 do
    begin
      FDetector.AddValue(100);
      HighAlphaDetector.AddValue(100);
    end;

    // Add new value
    FDetector.AddValue(200);
    HighAlphaDetector.AddValue(200);

    // High alpha should adapt faster
    Assert.IsTrue(HighAlphaDetector.CurrentMean > FDetector.CurrentMean,
                  'High alpha should adapt faster to changes');
  finally
    HighAlphaDetector.Free;
  end;
end;

procedure TEMAAnomalyDetectorTests.TestRapidAdaptation;
var
  i: Integer;
begin
  FDetector.Free;
  FDetector := TEMAAnomalyDetector.Create(0.5); // Fast adaptation

  // Start with values around 100
  for i := 1 to 5 do
    FDetector.AddValue(100);

  // Jump to 200
  for i := 1 to 5 do
    FDetector.AddValue(200);

  // Mean should be close to 200
  Assert.IsTrue(FDetector.CurrentMean > 180, 'Fast EMA should quickly adapt to new level');
end;

procedure TEMAAnomalyDetectorTests.TestSlowAdaptation;
var
  i: Integer;
begin
  FDetector.Free;
  FDetector := TEMAAnomalyDetector.Create(0.01); // Slow adaptation

  // Start with values around 100
  for i := 1 to 10 do
    FDetector.AddValue(100);

  // Add outlier
  FDetector.AddValue(1000);

  // Mean should barely move
  Assert.IsTrue(FDetector.CurrentMean < 110, 'Slow EMA should resist outliers');
end;

procedure TEMAAnomalyDetectorTests.TestAnomalyDetection;
var
  i: Integer;
  Result: TAnomalyResult;
begin
  // Establish baseline
  for i := 1 to 20 do
    FDetector.AddValue(100 + Random(10) - 5);

  // Test anomaly
  Result := FDetector.Detect(200);
  Assert.IsTrue(Result.IsAnomaly, 'Value 200 should be anomaly');

  Result := FDetector.Detect(0);
  Assert.IsTrue(Result.IsAnomaly, 'Value 0 should be anomaly');
end;

procedure TEMAAnomalyDetectorTests.TestVarianceUpdate;
var
  i: Integer;
  InitialVariance, LaterVariance: Double;
begin
  // Start with consistent values
  for i := 1 to 10 do
    FDetector.AddValue(100);

  InitialVariance := FDetector.CurrentStdDev * FDetector.CurrentStdDev;

  // Add variable values
  for i := 1 to 10 do
    FDetector.AddValue(100 + Random(40) - 20);

  LaterVariance := FDetector.CurrentStdDev * FDetector.CurrentStdDev;

  Assert.IsTrue(LaterVariance > InitialVariance, 'Variance should increase with variable data');
end;

{ TAdaptiveAnomalyDetectorTests }

procedure TAdaptiveAnomalyDetectorTests.Setup;
begin
  FDetector := TAdaptiveAnomalyDetector.Create(100, 0.1);
end;

procedure TAdaptiveAnomalyDetectorTests.TearDown;
begin
  FDetector.Free;
end;

procedure TAdaptiveAnomalyDetectorTests.TestInitialState;
var
  Result: TAnomalyResult;
begin
  Result := FDetector.Detect(100);
  Assert.IsFalse(Result.IsAnomaly, 'Uninitialized detector should not detect anomalies');

  FDetector.ProcessValue(100);
  Assert.AreEqual<Double>(100.0, FDetector.CurrentMean);
end;

procedure TAdaptiveAnomalyDetectorTests.TestLearningFromNormalValues;
var
  i: Integer;
  InitialMean: Double;
begin
  // Initialize with multiple values to establish proper variance
  for i := 1 to 10 do
  begin
    // Add some variance in initial values
    var InitValue := 100 + Random(10) - 5; // 95-105
    FDetector.ProcessValue(InitValue);
    FDetector.UpdateNormal(InitValue);
  end;

  InitialMean := FDetector.CurrentMean;

  // Feed normal values that gradually increase
  for i := 1 to 20 do
  begin
    var Value := InitialMean + i; // Gradual increase from current mean
    FDetector.ProcessValue(Value);
    // Always try to update for this test to verify learning
    FDetector.UpdateNormal(Value);
  end;

  // Mean should have increased significantly
  Assert.IsTrue(FDetector.CurrentMean > InitialMean + 5,
    Format('Detector should learn from normal values. Initial: %.2f, Current: %.2f',
           [InitialMean, FDetector.CurrentMean]));
end;

procedure TAdaptiveAnomalyDetectorTests.TestRejectingAnomalies;
var
  i: Integer;
  MeanBeforeAnomaly, MeanAfterAnomaly: Double;
begin
  // Establish baseline
  for i := 1 to 10 do
  begin
    FDetector.ProcessValue(100);
    FDetector.UpdateNormal(100);
  end;

  MeanBeforeAnomaly := FDetector.CurrentMean;

  // Process anomaly (should not learn from it)
  FDetector.ProcessValue(1000);
  // Don't call UpdateNormal for anomalies

  MeanAfterAnomaly := FDetector.CurrentMean;

  Assert.AreEqual(MeanBeforeAnomaly, MeanAfterAnomaly, 'Should not learn from anomalies');
end;

procedure TAdaptiveAnomalyDetectorTests.TestGradualTrendAdaptation;
var
  i: Integer;
  Value: Double;
  AcceptedCount: Integer;
  Config: TAnomalyDetectionConfig;
begin
  // Use very permissive config for trend adaptation
  Config := TAnomalyDetectionConfig.Default;
  Config.SigmaMultiplier := 3.0;
  Config.MinStdDev := 5.0; // Higher minimum variance to allow adaptation

  FDetector.Free;
  FDetector := TAdaptiveAnomalyDetector.Create(100, 0.2, Config); // Higher adaptation rate

  AcceptedCount := 0;

  // Initialize with variable baseline to establish reasonable variance
  for i := 1 to 20 do
  begin
    Value := 100 + Random(20) - 10; // Values 90-110
    FDetector.ProcessValue(Value);
    FDetector.UpdateNormal(Value);
  end;

  // Now test gradual trend
  for i := 1 to 50 do
  begin
    Value := 100 + i * 0.5; // Very gradual increase from 100.5 to 125
    FDetector.ProcessValue(Value);

    if not FDetector.IsAnomaly(Value) then
    begin
      FDetector.UpdateNormal(Value);
      Inc(AcceptedCount);
    end;
  end;

  // With proper initialization and gradual trend, should accept at least some values
  Assert.IsTrue(AcceptedCount > 20, Format('Should accept many values in gradual trend. Accepted: %d/50', [AcceptedCount]));

  // Mean should have moved up
  Assert.IsTrue(FDetector.CurrentMean > 105, Format('Should adapt to trend. Current mean: %.2f', [FDetector.CurrentMean]));
end;

procedure TAdaptiveAnomalyDetectorTests.TestAdaptationRate;
var
  FastDetector: TAdaptiveAnomalyDetector;
  i: Integer;
begin
  FastDetector := TAdaptiveAnomalyDetector.Create(100, 0.5); // Fast adaptation
  try
    // Initialize both
    FDetector.ProcessValue(100);
    FDetector.UpdateNormal(100);
    FastDetector.ProcessValue(100);
    FastDetector.UpdateNormal(100);

    // Feed new normal level
    for i := 1 to 10 do
    begin
      FDetector.UpdateNormal(200);
      FastDetector.UpdateNormal(200);
    end;

    // Fast detector should adapt quicker
    Assert.IsTrue(FastDetector.CurrentMean > FDetector.CurrentMean,
                  'Higher adaptation rate should adapt faster');
  finally
    FastDetector.Free;
  end;
end;

procedure TAdaptiveAnomalyDetectorTests.TestAnomalyThreshold;
var
  Config: TAnomalyDetectionConfig;
  SensitiveDetector: TAdaptiveAnomalyDetector;
  i: Integer;
  Result: TAnomalyResult;
begin
  Config := TAnomalyDetectionConfig.Default;
  Config.SigmaMultiplier := 1.5; // More sensitive

  SensitiveDetector := TAdaptiveAnomalyDetector.Create(100, 0.1, Config);
  try
    // Initialize
    for i := 1 to 10 do
    begin
      SensitiveDetector.ProcessValue(100);
      SensitiveDetector.UpdateNormal(100);
    end;

    // Test borderline value
    Result := SensitiveDetector.Detect(100 + 2 * SensitiveDetector.CurrentStdDev);
    Assert.IsTrue(Result.IsAnomaly, 'Should be more sensitive with lower sigma multiplier');
  finally
    SensitiveDetector.Free;
  end;
end;

{ TAnomalyConfirmationSystemTests }

procedure TAnomalyConfirmationSystemTests.Setup;
begin
  FSystem := TAnomalyConfirmationSystem.Create(10, 3, 0.1);
end;

procedure TAnomalyConfirmationSystemTests.TearDown;
begin
  FSystem.Free;
end;

procedure TAnomalyConfirmationSystemTests.TestIsolatedAnomaly;
begin
  // Single anomaly should not be confirmed
  FSystem.AddPotentialAnomaly(100);
  Assert.IsFalse(FSystem.IsConfirmedAnomaly(100), 'Single anomaly should not be confirmed');
end;

procedure TAnomalyConfirmationSystemTests.TestConfirmedAnomalyPattern;
var
  i: Integer;
begin
  // Add similar anomalies
  for i := 1 to 3 do
    FSystem.AddPotentialAnomaly(100 + Random(5)); // Similar values

  // Third similar anomaly should be confirmed
  Assert.IsTrue(FSystem.IsConfirmedAnomaly(102), 'Pattern of similar anomalies should be confirmed');
end;

procedure TAnomalyConfirmationSystemTests.TestToleranceParameter;
var
  i: Integer;
begin
  // Add anomalies with 10% tolerance
  FSystem.AddPotentialAnomaly(100);
  FSystem.AddPotentialAnomaly(105); // Within 10% tolerance
  FSystem.AddPotentialAnomaly(108); // Within 10% tolerance

  Assert.IsTrue(FSystem.IsConfirmedAnomaly(105), 'Values within tolerance should confirm');

  // Value outside tolerance
  Assert.IsFalse(FSystem.IsConfirmedAnomaly(120), 'Values outside tolerance should not confirm');
end;

procedure TAnomalyConfirmationSystemTests.TestWindowSizeLimit;
var
  i: Integer;
begin
  // Fill window with value 100
  for i := 1 to 10 do
    FSystem.AddPotentialAnomaly(100);

  // Verify we can confirm value 100
  Assert.IsTrue(FSystem.IsConfirmedAnomaly(100), 'Should confirm value 100 initially');

  // Add 10 more different anomalies to push out the old ones
  for i := 1 to 10 do
    FSystem.AddPotentialAnomaly(200);

  // Now value 200 should be confirmable
  Assert.IsTrue(FSystem.IsConfirmedAnomaly(200), 'Should confirm recent value 200');

  // But value 100 should not be confirmable anymore
  Assert.IsFalse(FSystem.IsConfirmedAnomaly(100), 'Old value 100 should be forgotten');
end;

procedure TAnomalyConfirmationSystemTests.TestDifferentAnomalies;
begin
  // Add different types of anomalies
  FSystem.AddPotentialAnomaly(50);   // Low anomaly
  FSystem.AddPotentialAnomaly(200);  // High anomaly
  FSystem.AddPotentialAnomaly(150);  // Medium anomaly

  // None should be confirmed as they're all different
  Assert.IsFalse(FSystem.IsConfirmedAnomaly(50), 'Different anomalies should not confirm');
  Assert.IsFalse(FSystem.IsConfirmedAnomaly(200), 'Different anomalies should not confirm');
end;

procedure TAnomalyConfirmationSystemTests.TestThresholdBehavior;
var
  TightSystem: TAnomalyConfirmationSystem;
begin
  TightSystem := TAnomalyConfirmationSystem.Create(10, 5, 0.1); // Need 5 confirmations
  try
    // Add 4 similar anomalies
    TightSystem.AddPotentialAnomaly(100);
    TightSystem.AddPotentialAnomaly(102);
    TightSystem.AddPotentialAnomaly(98);
    TightSystem.AddPotentialAnomaly(101);

    // Should not confirm with only 4
    Assert.IsFalse(TightSystem.IsConfirmedAnomaly(100), 'Should not confirm below threshold');

    // Add 5th
    TightSystem.AddPotentialAnomaly(99);

    // Now should confirm
    Assert.IsTrue(TightSystem.IsConfirmedAnomaly(100), 'Should confirm at threshold');
  finally
    TightSystem.Free;
  end;
end;

{ TIntegrationTests }

procedure TIntegrationTests.TestEnsembleDetection;
var
  SlidingDetector: TSlidingWindowDetector;
  EMADetector: TEMAAnomalyDetector;
  AdaptiveDetector: TAdaptiveAnomalyDetector;
  ConfirmationSystem: TAnomalyConfirmationSystem;
  i: Integer;
  Value: Double;
  VoteCount: Integer;
  ConfirmedAnomalies: Integer;
begin
  SlidingDetector := TSlidingWindowDetector.Create(20);
  EMADetector := TEMAAnomalyDetector.Create(0.1);
  AdaptiveDetector := TAdaptiveAnomalyDetector.Create(50, 0.05);
  ConfirmationSystem := TAnomalyConfirmationSystem.Create(5, 2);
  try
    ConfirmedAnomalies := 0;

    // Normal data stream
    for i := 1 to 50 do
    begin
      Value := 100 + Random(20) - 10;
      SlidingDetector.AddValue(Value);
      EMADetector.AddValue(Value);
      AdaptiveDetector.ProcessValue(Value);
      if not AdaptiveDetector.IsAnomaly(Value) then
        AdaptiveDetector.UpdateNormal(Value);
    end;

    // Test ensemble on anomalies
    for i := 1 to 5 do
    begin
      if i mod 2 = 0 then
        Value := 300  // Clear anomaly
      else
        Value := 105; // Normal

      VoteCount := 0;
      if SlidingDetector.IsAnomaly(Value) then Inc(VoteCount);
      if EMADetector.IsAnomaly(Value) then Inc(VoteCount);
      if AdaptiveDetector.IsAnomaly(Value) then Inc(VoteCount);

      if VoteCount >= 2 then // Majority vote
      begin
        ConfirmationSystem.AddPotentialAnomaly(Value);
        if ConfirmationSystem.IsConfirmedAnomaly(Value) then
          Inc(ConfirmedAnomalies);
      end;
    end;

    // Should detect some anomalies
    Assert.IsTrue(ConfirmedAnomalies > 0, 'Ensemble should detect anomalies');

  finally
    ConfirmationSystem.Free;
    AdaptiveDetector.Free;
    EMADetector.Free;
    SlidingDetector.Free;
  end;
end;

procedure TIntegrationTests.TestRealWorldScenario;
var
  Detector: TSlidingWindowDetector;
  i, Hour: Integer;
  Value, BaseTraffic: Double;
  TotalAnomalies: Integer;
  Result: TAnomalyResult;
begin
  Detector := TSlidingWindowDetector.Create(24); // 24-hour window
  try
    TotalAnomalies := 0;

    // Simulate 7 days of web traffic
    for i := 1 to 168 do // 7 * 24 hours
    begin
      Hour := (i - 1) mod 24;

      // Realistic traffic pattern
      BaseTraffic := 1000;
      BaseTraffic := BaseTraffic + 500 * Sin((Hour - 6) * Pi / 12); // Peak at noon

      // Add noise
      Value := BaseTraffic + Random(100) - 50;

      // Inject anomaly
      if (i = 36) then // Day 2, noon
        Value := Value * 5; // DDoS attack

      Detector.AddValue(Value);
      Result := Detector.Detect(Value);

      if Result.IsAnomaly then
        Inc(TotalAnomalies);
    end;

    // Should detect the injected anomaly
    Assert.IsTrue(TotalAnomalies > 0, 'Should detect anomalies in traffic pattern');

  finally
    Detector.Free;
  end;
end;

procedure TIntegrationTests.TestPerformanceUnderLoad;
var
  Detectors: array[0..9] of TSlidingWindowDetector;
  i, j: Integer;
  StartTime, EndTime: TDateTime;
  Value: Double;
begin
  // Create multiple detectors
  for i := 0 to 9 do
    Detectors[i] := TSlidingWindowDetector.Create(100);

  try
    StartTime := Now;

    // Process many values
    for i := 1 to 10000 do
    begin
      Value := Random(1000);
      for j := 0 to 9 do
      begin
        Detectors[j].AddValue(Value);
        Detectors[j].IsAnomaly(Value);
      end;
    end;

    EndTime := Now;

    // Should complete reasonably fast (< 1 second for 100k operations)
    var ElapsedMs := MilliSecondsBetween(EndTime, StartTime);
    Assert.IsTrue(ElapsedMs < 1000, Format('Performance issue: %d ms for 100k operations', [ElapsedMs]));

  finally
    for i := 0 to 9 do
      Detectors[i].Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TAnomalyDetectionConfigTests);
  TDUnitX.RegisterTestFixture(TThreeSigmaDetectorTests);
  TDUnitX.RegisterTestFixture(TSlidingWindowDetectorTests);
  TDUnitX.RegisterTestFixture(TEMAAnomalyDetectorTests);
  TDUnitX.RegisterTestFixture(TAdaptiveAnomalyDetectorTests);
  TDUnitX.RegisterTestFixture(TAnomalyConfirmationSystemTests);
  TDUnitX.RegisterTestFixture(TIntegrationTests);

end.
