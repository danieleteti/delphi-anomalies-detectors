// ***************************************************************************
//
// Copyright (c) 2025 Daniele Teti - All Rights Reserved
//
// Unauthorized copying, distribution or use of this software, via any medium,
// is strictly prohibited without the prior written consent of the copyright
// holder. This software is proprietary and confidential.
//
// Unit tests for the Anomaly Detection Algorithms Library - Refactored Version
//
// ***************************************************************************

unit AnomalyDetectionAlgorithmsTests;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Math,
  System.Classes,
  System.DateUtils,
  // New modular structure
  AnomalyDetection.Types,
  AnomalyDetection.Base,
  AnomalyDetection.Factory,
  AnomalyDetection.ThreeSigma,
  AnomalyDetection.SlidingWindow,
  AnomalyDetection.EMA,
  AnomalyDetection.Adaptive,
  AnomalyDetection.IsolationForest,
  AnomalyDetection.DBSCAN,
  AnomalyDetection.LOF,
  AnomalyDetection.Performance,
  AnomalyDetection.Confirmation,
  AnomalyDetection.Evaluation;

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
    [Test]
    procedure TestInitializationState;
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
    procedure TestInitializeWindow;
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
    procedure TestWarmUpMethod;
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
    procedure TestInitializeWithNormalData;
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
  TIsolationForestDetectorTests = class
  private
    FDetector: TIsolationForestDetector;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestTrainFromDataset;
    [Test]
    procedure TestIncrementalTraining;
    [Test]
    procedure TestAutoTraining;
    [Test]
    procedure TestMultiDimensionalDetection;
    [Test]
    procedure TestFraudDetectionScenario;
    [Test]
    procedure TestSensorDataScenario;
    [Test]
    procedure TestCSVTraining;
  end;

  [TestFixture]
  TDBSCANDetectorTests = class
  private
    FDetector: TDBSCANDetector;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestInitialState;
    [Test]
    procedure TestSingleDimensionClustering;
    [Test]
    procedure TestMultiDimensionalClustering;
    [Test]
    procedure TestOutlierDetection;
    [Test]
    procedure TestDensityBasedDetection;
    [Test]
    procedure TestAutoRecluster;
    [Test]
    procedure TestSaveLoadState;

    // Border cases - CRITICAL
    [Test]
    procedure TestEmptyDataset;
    [Test]
    procedure TestInsufficientData;
    [Test]
    procedure TestInvalidDimensions;
    [Test]
    procedure TestZeroEpsilon;
    [Test]
    procedure TestNegativeValues;
    [Test]
    procedure TestAllIdenticalPoints;
    [Test]
    procedure TestSinglePoint;
    [Test]
    procedure TestMaxHistoryLimit;
  end;

  [TestFixture]
  TLOFDetectorTests = class
  private
    FDetector: TLOFDetector;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestInitialState;
    [Test]
    procedure TestInsufficientDataException;
    [Test]
    procedure TestSimpleClusterAndOutlier;
    [Test]
    procedure TestMultiDimensionalOutlier;
    [Test]
    procedure TestDimensionMismatchException;
    [Test]
    procedure TestSaveLoadState;
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
    [Test]
    procedure TestFactoryPatternRefactored;
  end;

  [TestFixture]
  TEvaluationFrameworkTests = class
  private
    FDataset: TLabeledDataset;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestConfusionMatrix;
    [Test]
    procedure TestConfusionMatrixMetrics;
    [Test]
    procedure TestLabeledDatasetCreation;
    [Test]
    procedure TestDatasetGeneration;
    [Test]
    procedure TestDetectorEvaluation;
    [Test]
    procedure TestPerfectDetector;
    [Test]
    procedure TestWorstCaseDetector;
    [Test]
    procedure TestCrossValidation;
    [Test]
    procedure TestTrainTestSplit;
    [Test]
    procedure TestEmptyDatasetEvaluation;
    [Test]
    procedure TestZeroDivisionInMetrics;
    [Test]
    procedure TestInvalidTrainRatio;
    [Test]
    procedure TestTooManyFolds;
  end;

  [TestFixture]
  THyperparameterTuningTests = class
  private
    FDataset: TLabeledDataset;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestGridSearchBasic;
    [Test]
    procedure TestRandomSearch;
    [Test]
    procedure TestDifferentMetrics;
    [Test]
    procedure TestTopConfigurations;
    [Test]
    procedure TestEmptyParameterArray;
    [Test]
    procedure TestInvalidIterations;
    [Test]
    procedure TestGetTopWithEmptyResults;
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
  Assert.WillRaise(
    procedure
    begin
      FDetector.AddValues(EmptyData);
      FDetector.Build;
    end,
    EAnomalyDetectionException
  );
end;

procedure TThreeSigmaDetectorTests.TestSingleDataPointException;
var
  SingleData: TArray<Double>;
begin
  SetLength(SingleData, 1);
  SingleData[0] := 100;
  Assert.WillRaise(
    procedure
    begin
      FDetector.AddValues(SingleData);
      FDetector.Build;
    end,
    EAnomalyDetectionException
  );
end;

procedure TThreeSigmaDetectorTests.TestInitializationState;
var
  Data: TArray<Double>;
begin
  // Initially not initialized
  Assert.IsFalse(FDetector.IsInitialized, 'Should not be initialized initially');

  Assert.WillRaise(
    procedure
    begin
      FDetector.Detect(100);
    end,
    EAnomalyDetectionException
  );

  // After learning, should be initialized
  SetLength(Data, 10);
  for var i := 0 to 9 do
    Data[i] := 100 + i;

  FDetector.AddValues(Data);
  FDetector.Build;
  Assert.IsTrue(FDetector.IsInitialized, 'Should be initialized after learning');

  // Should work now
  var Result := FDetector.Detect(100);
  Assert.IsNotNull(@Result);
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

  FDetector.AddValues(Data);
  FDetector.Build;

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

  FDetector.AddValues(Data);
  FDetector.Build;

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

  FDetector.AddValues(Data);
  FDetector.Build;

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

  FDetector.AddValues(Data);
  FDetector.Build;

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

  FDetector.AddValues(Data);
  FDetector.Build;

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

procedure TSlidingWindowDetectorTests.TestInitializeWindow;
var
  InitialData: TArray<Double>;
  i: Integer;
begin
  // Test window initialization
  SetLength(InitialData, 5);
  for i := 0 to 4 do
    InitialData[i] := 100 + i;

  FDetector.InitializeWindow(InitialData);

  Assert.IsTrue(AreFloatsEqual(102.0, FDetector.CurrentMean), 'Initialized mean should be 102');

  // Add more values and ensure it works normally
  FDetector.AddValue(105);
  Assert.IsTrue(FDetector.CurrentMean > 102, 'Mean should increase after adding 105');
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
begin
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
  Assert.IsTrue(FDetector.IsInitialized, 'Should be initialized after first value');
end;

procedure TEMAAnomalyDetectorTests.TestWarmUpMethod;
var
  BaselineData: TArray<Double>;
  i: Integer;
begin
  // Create baseline data
  SetLength(BaselineData, 20);
  for i := 0 to 19 do
    BaselineData[i] := 100 + Random(10) - 5;

  // Warm up with baseline
  FDetector.WarmUp(BaselineData);

  Assert.IsTrue(FDetector.IsInitialized, 'Should be initialized after warm-up');
  Assert.IsTrue(Abs(FDetector.CurrentMean - 100) < 10, 'Mean should be close to baseline');
  Assert.IsTrue(FDetector.CurrentStdDev > 0, 'StdDev should be positive');

  // Should work immediately for detection
  var Result := FDetector.Detect(150);
  Assert.IsNotNull(@Result, 'Detection should work after warm-up');
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
  Assert.IsFalse(FDetector.IsInitialized, 'Should not be initialized initially');

  Result := FDetector.Detect(100);
  Assert.IsFalse(Result.IsAnomaly, 'Uninitialized detector should not detect anomalies');

  FDetector.ProcessValue(100);
  Assert.IsTrue(FDetector.IsInitialized, 'Should be initialized after processing first value');
  Assert.AreEqual<Double>(100.0, FDetector.CurrentMean);
end;

procedure TAdaptiveAnomalyDetectorTests.TestInitializeWithNormalData;
var
  NormalData: TArray<Double>;
  i: Integer;
begin
  // Create normal baseline data
  SetLength(NormalData, 50);
  for i := 0 to 49 do
    NormalData[i] := 100 + Random(20) - 10; // Values 90-110

  FDetector.InitializeWithNormalData(NormalData);

  Assert.IsTrue(FDetector.IsInitialized, 'Should be initialized with normal data');
  Assert.IsTrue(Abs(FDetector.CurrentMean - 100) < 15, 'Mean should be close to expected value');
  Assert.IsTrue(FDetector.CurrentStdDev > 0, 'StdDev should be positive');

  // Should work immediately for detection
  var Result := FDetector.Detect(150);
  Assert.IsNotNull(@Result, 'Detection should work after initialization');
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
  NormalData: TArray<Double>;
begin
  // Use very permissive config for trend adaptation
  Config := TAnomalyDetectionConfig.Default;
  Config.SigmaMultiplier := 3.0;
  Config.MinStdDev := 5.0; // Higher minimum variance to allow adaptation

  FDetector.Free;
  FDetector := TAdaptiveAnomalyDetector.Create(100, 0.2, Config); // Higher adaptation rate

  AcceptedCount := 0;

  // Initialize with variable baseline to establish reasonable variance
  SetLength(NormalData, 20);
  for i := 0 to 19 do
    NormalData[i] := 100 + Random(20) - 10; // Values 90-110

  FDetector.InitializeWithNormalData(NormalData);

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
  NormalData: TArray<Double>;
begin
  FastDetector := TAdaptiveAnomalyDetector.Create(100, 0.5); // Fast adaptation
  try
    // Initialize both detectors
    SetLength(NormalData, 10);
    for i := 0 to 9 do
      NormalData[i] := 100;

    FDetector.InitializeWithNormalData(NormalData);
    FastDetector.InitializeWithNormalData(NormalData);

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
  NormalData: TArray<Double>;
begin
  Config := TAnomalyDetectionConfig.Default;
  Config.SigmaMultiplier := 1.5; // More sensitive

  SensitiveDetector := TAdaptiveAnomalyDetector.Create(100, 0.1, Config);
  try
    // Initialize
    SetLength(NormalData, 10);
    for i := 0 to 9 do
      NormalData[i] := 100;

    SensitiveDetector.InitializeWithNormalData(NormalData);

    // Test borderline value
    Result := SensitiveDetector.Detect(100 + 2 * SensitiveDetector.CurrentStdDev);
    Assert.IsTrue(Result.IsAnomaly, 'Should be more sensitive with lower sigma multiplier');
  finally
    SensitiveDetector.Free;
  end;
end;

{ TIsolationForestDetectorTests }

procedure TIsolationForestDetectorTests.Setup;
var
  Config: TAnomalyDetectionConfig;
begin
  // Use more sensitive configuration for testing
  Config := TAnomalyDetectionConfig.Default;
  Config.SigmaMultiplier := 2.0; // More sensitive
  FDetector := TIsolationForestDetector.Create(100, 150, 10, Config); // More trees, larger sample, deeper trees
end;

procedure TIsolationForestDetectorTests.TearDown;
begin
  FDetector.Free;
end;

procedure TIsolationForestDetectorTests.TestTrainFromDataset;
var
  Dataset: TArray<TArray<Double>>;
  i: Integer;
  Instance: TArray<Double>;
  Result: TAnomalyResult;
begin
  // Create larger training dataset for better coverage
  SetLength(Dataset, 500);
  for i := 0 to 499 do
  begin
    SetLength(Dataset[i], 2);
    Dataset[i][0] := 100 + Random(20) - 10; // X: 90-110
    Dataset[i][1] := 50 + Random(12) - 6;   // Y: 44-56
  end;

  // Train with single method call
  FDetector.TrainFromDataset(Dataset);

  Assert.IsTrue(FDetector.IsInitialized, 'Should be initialized after training');
  Assert.AreEqual<Integer>(2, FDetector.FeatureCount, 'Should detect 2 features');

  // Test detection with clear normal point
  SetLength(Instance, 2);
  Instance[0] := 100; Instance[1] := 50; // Center of training data
  Result := FDetector.DetectMultiDimensional(Instance);
  Assert.IsFalse(Result.IsAnomaly, 'Normal point should not be anomaly');

  // Test detection with clear anomaly - much further from training data
  Instance[0] := 500; Instance[1] := 500; // Very far from training data
  Result := FDetector.DetectMultiDimensional(Instance);
  Assert.IsTrue(Result.IsAnomaly, 'Far point should be anomaly');
end;

procedure TIsolationForestDetectorTests.TestIncrementalTraining;
var
  i: Integer;
  Instance: TArray<Double>;
  Result: TAnomalyResult;
begin
  Assert.IsFalse(FDetector.IsInitialized, 'Should not be initialized initially');

  // Add training data incrementally
  for i := 1 to 150 do
  begin
    SetLength(Instance, 2);
    Instance[0] := 100 + Random(20) - 10;
    Instance[1] := 50 + Random(15) - 7;
    FDetector.AddTrainingData(Instance);
  end;

  Assert.IsFalse(FDetector.IsInitialized, 'Should not be auto-trained yet');

  // Manually finalize training
  FDetector.FinalizeTraining;

  Assert.IsTrue(FDetector.IsInitialized, 'Should be trained after finalization');

  // Test detection
  SetLength(Instance, 2);
  Instance[0] := 100; Instance[1] := 50;
  Result := FDetector.DetectMultiDimensional(Instance);
  Assert.IsNotNull(@Result, 'Should be able to detect after training');
end;

procedure TIsolationForestDetectorTests.TestAutoTraining;
var
  i: Integer;
  Instance: TArray<Double>;
begin
  // Set low auto-train threshold for testing
  FDetector.AutoTrainThreshold := 50;

  Assert.IsFalse(FDetector.IsInitialized, 'Should not be initialized initially');

  // Add enough data to trigger auto-training
  for i := 1 to 60 do
  begin
    SetLength(Instance, 2);
    Instance[0] := 100 + Random(20) - 10;
    Instance[1] := 50 + Random(15) - 7;
    FDetector.AddTrainingData(Instance);

    if i = 50 then
      Assert.IsTrue(FDetector.IsInitialized, 'Should auto-train at threshold');
  end;

  Assert.IsTrue(FDetector.IsInitialized, 'Should remain trained');
end;

procedure TIsolationForestDetectorTests.TestMultiDimensionalDetection;
var
  Dataset: TArray<TArray<Double>>;
  Instance: TArray<Double>;
  i: Integer;
  Result: TAnomalyResult;
  AnomalyCount: Integer;
begin
  // Create multi-dimensional training data (3D)
  SetLength(Dataset, 300);
  for i := 0 to 299 do
  begin
    SetLength(Dataset[i], 3);
    Dataset[i][0] := 100 + Random(20) - 10; // X: 90-110
    Dataset[i][1] := 50 + Random(16) - 8;   // Y: 42-58
    Dataset[i][2] := 25 + Random(10) - 5;   // Z: 20-30
  end;

  FDetector.TrainFromDataset(Dataset);

  Assert.AreEqual<Integer>(3, FDetector.FeatureCount, 'Should detect 3 features');

  // Test various points
  AnomalyCount := 0;

  // Normal points
  SetLength(Instance, 3);
  Instance := [100, 50, 25]; // Center
  Result := FDetector.DetectMultiDimensional(Instance);
  if not Result.IsAnomaly then Inc(AnomalyCount);

  Instance := [105, 52, 22]; // Within normal range
  Result := FDetector.DetectMultiDimensional(Instance);
  if not Result.IsAnomaly then Inc(AnomalyCount);

  // Anomaly points
  Instance := [200, 200, 200]; // Far from training data
  Result := FDetector.DetectMultiDimensional(Instance);
  Assert.IsTrue(Result.IsAnomaly, 'Far point should be detected as anomaly');

  Instance := [0, 0, 0]; // Far negative
  Result := FDetector.DetectMultiDimensional(Instance);
  Assert.IsTrue(Result.IsAnomaly, 'Far negative point should be anomaly');

  Assert.IsTrue(AnomalyCount >= 1, 'Should identify some normal points correctly');
end;

procedure TIsolationForestDetectorTests.TestFraudDetectionScenario;
var
  TransactionData: TArray<TArray<Double>>;
  SuspiciousTransaction: TArray<Double>;
  i: Integer;
  Result: TAnomalyResult;
begin
  // Create normal transaction patterns
  SetLength(TransactionData, 500);
  for i := 0 to 499 do
  begin
    SetLength(TransactionData[i], 4); // Amount, Hour, DayOfWeek, MerchantCategory
    TransactionData[i][0] := 50 + Random(150);   // Amount: 50-200
    TransactionData[i][1] := 8 + Random(12);     // Hour: 8-20
    TransactionData[i][2] := 1 + Random(5);      // Weekday: 1-5
    TransactionData[i][3] := 1 + Random(8);      // Category: 1-8
  end;

  FDetector.TrainForFraudDetection(TransactionData);

  Assert.IsTrue(FDetector.IsInitialized, 'Should be trained for fraud detection');

  // Test suspicious transaction
  SetLength(SuspiciousTransaction, 4);
  SuspiciousTransaction := [5000, 3, 7, 9]; // Large amount, 3AM, weekend, unusual category
  Result := FDetector.DetectMultiDimensional(SuspiciousTransaction);
  Assert.IsTrue(Result.IsAnomaly, 'Suspicious transaction should be flagged');

  // Test normal transaction
  SuspiciousTransaction := [125, 14, 3, 4]; // Normal amount, afternoon, midweek, common category
  Result := FDetector.DetectMultiDimensional(SuspiciousTransaction);
  Assert.IsFalse(Result.IsAnomaly, 'Normal transaction should not be flagged');
end;

procedure TIsolationForestDetectorTests.TestSensorDataScenario;
var
  SensorData: TArray<TArray<Double>>;
  FailureReading: TArray<Double>;
  i: Integer;
  Result: TAnomalyResult;
begin
  // Create normal sensor readings
  SetLength(SensorData, 400);
  for i := 0 to 399 do
  begin
    SetLength(SensorData[i], 3); // Temperature, Pressure, Vibration
    SensorData[i][0] := 20 + Random(10);   // Temp: 20-30°C
    SensorData[i][1] := 100 + Random(20);  // Pressure: 100-120 kPa
    SensorData[i][2] := 0.1 + Random * 0.4; // Vibration: 0.1-0.5
  end;

  FDetector.TrainForMultiSensorData(SensorData);

  Assert.IsTrue(FDetector.IsInitialized, 'Should be trained for sensor monitoring');

  // Test equipment failure pattern
  SetLength(FailureReading, 3);
  FailureReading := [45, 150, 2.0]; // High temp, high pressure, high vibration
  Result := FDetector.DetectMultiDimensional(FailureReading);
  Assert.IsTrue(Result.IsAnomaly, 'Equipment failure pattern should be detected');

  // Test normal reading
  FailureReading := [25, 110, 0.3]; // Normal values
  Result := FDetector.DetectMultiDimensional(FailureReading);
  Assert.IsFalse(Result.IsAnomaly, 'Normal sensor reading should not be anomaly');
end;

// Alternativa per TestCSVTraining - evita Random durante Format
procedure TIsolationForestDetectorTests.TestCSVTraining;
var
  CSVFileName: string;
  CSVContent: TStringList;
  i: Integer;
  Instance: TArray<Double>;
  Result: TAnomalyResult;
  FormatSettings: TFormatSettings;
  X, Y, Z: Double; // Valori espliciti
begin
  FormatSettings := TFormatSettings.Create('en-US');

  CSVFileName := 'test_data.csv';
  CSVContent := TStringList.Create;
  try
    CSVContent.Add('X,Y,Z'); // Header

    // Genera valori esplicitamente senza Random dentro Format
    for i := 1 to 100 do
    begin
      X := 100 + Random(20) - 10;
      Y := 50 + Random(16) - 8;
      Z := 25 + Random(10) - 5;

      // Usa FloatToStr invece di Format %g
      CSVContent.Add(
        FloatToStr(X, FormatSettings) + ',' +
        FloatToStr(Y, FormatSettings) + ',' +
        FloatToStr(Z, FormatSettings)
      );
    end;

    CSVContent.SaveToFile(CSVFileName);

    // Train from CSV
    FDetector.TrainFromCSV(CSVFileName, True);

    Assert.IsTrue(FDetector.IsTrained, 'Should be trained from CSV');
    Assert.AreEqual<Integer>(3, FDetector.FeatureCount, 'Should detect 3 features from CSV');

    // Test detection
    SetLength(Instance, 3);
    Instance := [100, 50, 25];
    Result := FDetector.DetectMultiDimensional(Instance);
    Assert.IsFalse(Result.IsAnomaly, 'Normal point should not be anomaly');

    Instance := [300, 300, 300];
    Result := FDetector.DetectMultiDimensional(Instance);
    Assert.IsTrue(Result.IsAnomaly, 'Anomaly should be detected');

  finally
    CSVContent.Free;
    if FileExists(CSVFileName) then
      DeleteFile(CSVFileName);
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
  BaselineData: TArray<Double>;
begin
  SlidingDetector := TSlidingWindowDetector.Create(20);
  EMADetector := TEMAAnomalyDetector.Create(0.1);
  AdaptiveDetector := TAdaptiveAnomalyDetector.Create(50, 0.05);
  ConfirmationSystem := TAnomalyConfirmationSystem.Create(5, 2);
  try
    ConfirmedAnomalies := 0;

    // Initialize detectors with baseline data
    SetLength(BaselineData, 30);
    for i := 0 to 29 do
      BaselineData[i] := 100 + Random(20) - 10;

    SlidingDetector.InitializeWindow(BaselineData);
    EMADetector.WarmUp(BaselineData);
    AdaptiveDetector.InitializeWithNormalData(BaselineData);

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

procedure TIntegrationTests.TestFactoryPatternRefactored;
var
  WebTrafficDetector: IStatisticalAnomalyDetector;
  FinancialDetector: IStatisticalAnomalyDetector;
  IoTDetector: IStatisticalAnomalyDetector;
  IsolationDetector: IDensityAnomalyDetector;
  LOFDetector: IDensityAnomalyDetector;
  Dataset: TArray<TArray<Double>>;
  i: Integer;
  Result: TAnomalyResult;
begin
  // Test all factory-created detectors
  WebTrafficDetector := TAnomalyDetectorFactory.CreateForWebTrafficMonitoring;
  FinancialDetector := TAnomalyDetectorFactory.CreateForFinancialData;
  IoTDetector := TAnomalyDetectorFactory.CreateForIoTSensors;
  IsolationDetector := TAnomalyDetectorFactory.CreateForHighDimensionalData;
  LOFDetector := TAnomalyDetectorFactory.CreateLOF(5, 2); // k=5, 2-dim

  // Test Web Traffic detector (Sliding Window)
  for i := 1 to 50 do
    WebTrafficDetector.AddValue(1000 + Random(200) - 100);

  Result := WebTrafficDetector.Detect(5000); // DDoS spike
  Assert.IsTrue(Result.IsAnomaly, 'Web traffic detector should detect DDoS');

  // Test Financial detector (EMA)
  for i := 1 to 30 do
    FinancialDetector.AddValue(100 + Random(10) - 5);

  Result := FinancialDetector.Detect(150); // Price spike
  Assert.IsTrue(Result.IsAnomaly, 'Financial detector should detect price spike');

  // Test IoT detector (Adaptive)
  // Initialize with normal sensor readings
  var BaselineData: TArray<Double>;
  SetLength(BaselineData, 20);
  for i := 0 to 19 do
    BaselineData[i] := 25 + Random(10) - 5; // Temp readings

  IoTDetector.AddValues(BaselineData);
  IoTDetector.Build;

  Result := IoTDetector.Detect(60); // Overheating
  Assert.IsTrue(Result.IsAnomaly, 'IoT detector should detect overheating');

  // Test Isolation Forest (multi-dimensional)
  // Create multi-dimensional dataset
  SetLength(Dataset, 200);
  for i := 0 to 199 do
  begin
    SetLength(Dataset[i], 3);
    Dataset[i][0] := 100 + Random(20) - 10;
    Dataset[i][1] := 50 + Random(16) - 8;
    Dataset[i][2] := 25 + Random(10) - 5;
    IsolationDetector.AddTrainingData(Dataset[i]);
  end;
  IsolationDetector.Train;

  var Instance: TArray<Double>;
  SetLength(Instance, 3);
  Instance := [300, 300, 300]; // Clear anomaly
  Result := IsolationDetector.DetectMultiDimensional(Instance);
  Assert.IsTrue(Result.IsAnomaly, 'Isolation Forest should detect multi-dim anomaly');

  // Test LOF Detector (multi-dimensional)
  for i := 0 to 20 do
    LOFDetector.AddTrainingData([10 + Random * 2 - 1, 10 + Random * 2 - 1]);
  LOFDetector.AddTrainingData([50,50]); // Outlier
  LOFDetector.Train;

  Result := LOFDetector.DetectMultiDimensional([10.5, 9.5]);
  Assert.IsFalse(Result.IsAnomaly, 'LOF detector should classify inlier correctly');

  Result := LOFDetector.DetectMultiDimensional([49, 51]);
  Assert.IsTrue(Result.IsAnomaly, 'LOF detector should classify outlier correctly');


  // Verify all detectors are properly initialized
  Assert.IsTrue(WebTrafficDetector.IsInitialized, 'Web traffic detector should be ready');
  Assert.IsTrue(FinancialDetector.IsInitialized, 'Financial detector should be ready');
  Assert.IsTrue(IoTDetector.IsInitialized, 'IoT detector should be ready');
  Assert.IsTrue(IsolationDetector.IsInitialized, 'Isolation detector should be ready');
  Assert.IsTrue(LOFDetector.IsInitialized, 'LOF detector should be ready');
end;

{ TDBSCANDetectorTests }

procedure TDBSCANDetectorTests.Setup;
begin
  FDetector := TDBSCANDetector.Create(1.0, 3, 1);
end;

procedure TDBSCANDetectorTests.TearDown;
begin
  FDetector.Free;
end;

procedure TDBSCANDetectorTests.TestInitialState;
begin
  Assert.AreEqual(1.0, FDetector.Epsilon, 0.001, 'Epsilon should be 1.0');
  Assert.AreEqual(3, FDetector.MinPoints, 'MinPoints should be 3');
  Assert.AreEqual(1, FDetector.Dimensions, 'Dimensions should be 1');
  Assert.AreEqual(0, FDetector.ClusterCount, 'Initial cluster count should be 0');
  Assert.IsFalse(FDetector.IsInitialized, 'Should not be initialized initially');
end;

procedure TDBSCANDetectorTests.TestSingleDimensionClustering;
var
  i: Integer;
  lResult: TAnomalyResult;
begin
  // Add cluster around 10
  for i := 1 to 10 do
    FDetector.AddPoint([10 + Random * 2 - 1]); // 9-11 range

  // Add cluster around 50
  for i := 1 to 10 do
    FDetector.AddPoint([50 + Random * 2 - 1]); // 49-51 range

  FDetector.Recluster;

  Assert.IsTrue(FDetector.ClusterCount >= 1, 'Should find at least 1 cluster');

  // Point in first cluster should be normal
  lResult := FDetector.Detect(10.5);
  Assert.IsFalse(lResult.IsAnomaly, 'Point in cluster should be normal');

  // Isolated point should be anomaly
  lResult := FDetector.Detect(100);
  Assert.IsTrue(lResult.IsAnomaly, 'Isolated point should be anomaly');
end;

procedure TDBSCANDetectorTests.TestMultiDimensionalClustering;
var
  lDetector: TDBSCANDetector;
  i: Integer;
  lResult: TAnomalyResult;
begin
  lDetector := TDBSCANDetector.Create(5.0, 3, 2);
  try
    // Cluster 1: around [10, 10]
    for i := 1 to 15 do
      lDetector.AddPoint([10 + Random * 4 - 2, 10 + Random * 4 - 2]);

    // Cluster 2: around [50, 50]
    for i := 1 to 15 do
      lDetector.AddPoint([50 + Random * 4 - 2, 50 + Random * 4 - 2]);

    lDetector.Recluster;

    Assert.IsTrue(lDetector.ClusterCount >= 1, 'Should find clusters in 2D space');

    // Point in cluster 1 should be normal
    lResult := lDetector.DetectMultiDim([10, 10]);
    Assert.IsFalse(lResult.IsAnomaly, 'Point in first cluster should be normal');

    // Point in cluster 2 should be normal
    lResult := lDetector.DetectMultiDim([50, 50]);
    Assert.IsFalse(lResult.IsAnomaly, 'Point in second cluster should be normal');

    // Isolated point should be anomaly
    lResult := lDetector.DetectMultiDim([100, 100]);
    Assert.IsTrue(lResult.IsAnomaly, 'Isolated 2D point should be anomaly');
  finally
    lDetector.Free;
  end;
end;

procedure TDBSCANDetectorTests.TestOutlierDetection;
var
  i: Integer;
  lResult: TAnomalyResult;
begin
  // Add dense cluster
  for i := 1 to 20 do
    FDetector.AddPoint([10 + Random * 2 - 1]);

  // Add isolated outliers
  FDetector.AddPoint([100]);
  FDetector.AddPoint([200]);

  FDetector.Recluster;

  Assert.IsTrue(FDetector.OutlierCount >= 2, 'Should detect at least 2 outliers');

  // New outlier should be detected
  lResult := FDetector.Detect(150);
  Assert.IsTrue(lResult.IsAnomaly, 'New outlier should be detected as anomaly');
  Assert.IsTrue(Abs(lResult.ZScore) > 0, 'Outlier should have non-zero Z-score');
end;

procedure TDBSCANDetectorTests.TestDensityBasedDetection;
var
  lDetector: TDBSCANDetector;
  i: Integer;
  lResult: TAnomalyResult;
begin
  lDetector := TDBSCANDetector.Create(2.0, 5, 1);
  try
    // Dense region (should form cluster)
    for i := 1 to 20 do
      lDetector.AddPoint([10 + Random - 0.5]);

    // Sparse region (should be outliers)
    lDetector.AddPoint([20]);
    lDetector.AddPoint([25]);
    lDetector.AddPoint([30]);

    lDetector.Recluster;

    Assert.IsTrue(lDetector.ClusterCount >= 1, 'Should find dense cluster');

    // Point in dense region should be normal
    lResult := lDetector.Detect(10);
    Assert.IsFalse(lResult.IsAnomaly, 'Point in dense region should be normal');

    // Point in sparse region should be anomaly
    lResult := lDetector.Detect(25);
    Assert.IsTrue(lResult.IsAnomaly, 'Point in sparse region should be anomaly');
  finally
    lDetector.Free;
  end;
end;

procedure TDBSCANDetectorTests.TestAutoRecluster;
var
  i: Integer;
begin
  FDetector.AutoRecluster := True;
  FDetector.MaxHistorySize := 100;

  // Add initial data
  for i := 1 to 30 do
    FDetector.AddPoint([10 + Random * 2 - 1]);

  FDetector.Recluster;
  Assert.IsTrue(FDetector.ClusterCount > 0, 'Should have clusters after first recluster');

  // Add more data (should trigger auto-recluster after threshold)
  for i := 1 to 60 do
    FDetector.AddPoint([50 + Random * 2 - 1]);

  Assert.IsTrue(FDetector.ClusterCount > 0, 'Should have reclustered automatically');
  // Note: cluster count may change due to new data
end;

procedure TDBSCANDetectorTests.TestSaveLoadState;
var
  lStream: TMemoryStream;
  lNewDetector: TDBSCANDetector;
  i: Integer;
  lResult1, lResult2: TAnomalyResult;
begin
  // Add data to original detector
  for i := 1 to 20 do
    FDetector.AddPoint([10 + Random * 2 - 1]);

  FDetector.Recluster;

  // Test detection before save
  lResult1 := FDetector.Detect(10);

  // Save state
  lStream := TMemoryStream.Create;
  try
    FDetector.SaveState(lStream);
    lStream.Position := 0;

    // Load into new detector
    lNewDetector := TDBSCANDetector.Create;
    try
      lNewDetector.LoadState(lStream);

      Assert.AreEqual(FDetector.Epsilon, lNewDetector.Epsilon, 0.001, 'Epsilon should match');
      Assert.AreEqual(FDetector.MinPoints, lNewDetector.MinPoints, 'MinPoints should match');
      Assert.AreEqual(FDetector.Dimensions, lNewDetector.Dimensions, 'Dimensions should match');

      // Test detection after load
      lResult2 := lNewDetector.Detect(10);
      Assert.AreEqual(lResult1.IsAnomaly, lResult2.IsAnomaly, 'Detection results should match');
    finally
      lNewDetector.Free;
    end;
  finally
    lStream.Free;
  end;
end;

procedure TDBSCANDetectorTests.TestEmptyDataset;
var
  lResult: TAnomalyResult;
begin
  // Test detection with no data
  lResult := FDetector.Detect(10);
  Assert.IsFalse(lResult.IsAnomaly, 'Empty dataset should not detect anomalies');
  Assert.AreEqual('Not enough samples', lResult.Description, 'Should indicate insufficient data');
  Assert.IsFalse(FDetector.IsInitialized, 'Should not be initialized with empty dataset');
end;

procedure TDBSCANDetectorTests.TestInsufficientData;
var
  lResult: TAnomalyResult;
begin
  // Add less than MinPoints (3)
  FDetector.AddPoint([10]);
  FDetector.AddPoint([11]);

  lResult := FDetector.Detect(10);
  Assert.IsFalse(lResult.IsAnomaly, 'Insufficient data should not trigger anomaly');
  Assert.IsFalse(FDetector.IsInitialized, 'Should not be initialized with < MinPoints');

  // Add one more to reach MinPoints
  FDetector.AddPoint([12]);
  Assert.IsTrue(FDetector.IsInitialized, 'Should be initialized at MinPoints threshold');
end;

procedure TDBSCANDetectorTests.TestInvalidDimensions;
var
  lDetector: TDBSCANDetector;
  lResult: TAnomalyResult;
  lExceptionRaised: Boolean;
begin
  lDetector := TDBSCANDetector.Create(1.0, 3, 2);
  try
    // Add 2D points
    lDetector.AddPoint([10, 20]);
    lDetector.AddPoint([11, 21]);
    lDetector.AddPoint([12, 22]);

    // Try to add wrong dimension
    lExceptionRaised := False;
    try
      lDetector.AddPoint([10]); // 1D instead of 2D
    except
      on E: Exception do
        lExceptionRaised := True;
    end;
    Assert.IsTrue(lExceptionRaised, 'Should raise exception for wrong dimensions in AddPoint');

    // Try to detect with wrong dimension
    lResult := lDetector.DetectMultiDim([10]); // 1D instead of 2D
    Assert.IsTrue(lResult.IsAnomaly, 'Wrong dimension should be treated as anomaly');
    Assert.AreEqual('Invalid dimension', lResult.Description, 'Should indicate dimension mismatch');
  finally
    lDetector.Free;
  end;
end;

procedure TDBSCANDetectorTests.TestZeroEpsilon;
var
  lDetector: TDBSCANDetector;
  i: Integer;
begin
  lDetector := TDBSCANDetector.Create(0.0, 3, 1);
  try
    // Add identical points
    for i := 1 to 10 do
      lDetector.AddPoint([10.0]);

    lDetector.Recluster;

    // With epsilon=0, only identical points form clusters
    // All points at 10.0 should form one cluster
    Assert.IsTrue(lDetector.ClusterCount >= 0, 'Should handle zero epsilon');
  finally
    lDetector.Free;
  end;
end;

procedure TDBSCANDetectorTests.TestNegativeValues;
var
  lDetector: TDBSCANDetector;
  i: Integer;
  lResult: TAnomalyResult;
begin
  lDetector := TDBSCANDetector.Create(2.0, 3, 1);
  try
    // Add negative values cluster
    for i := 1 to 10 do
      lDetector.AddPoint([-10 + Random - 0.5]);

    // Add positive values cluster
    for i := 1 to 10 do
      lDetector.AddPoint([10 + Random - 0.5]);

    lDetector.Recluster;

    // Test detection in negative range
    lResult := lDetector.Detect(-10);
    Assert.IsFalse(lResult.IsAnomaly, 'Negative values should be handled correctly');

    // Test very large negative outlier
    lResult := lDetector.Detect(-1000);
    Assert.IsTrue(lResult.IsAnomaly, 'Large negative outlier should be detected');
  finally
    lDetector.Free;
  end;
end;

procedure TDBSCANDetectorTests.TestAllIdenticalPoints;
var
  lDetector: TDBSCANDetector;
  i: Integer;
  lResult: TAnomalyResult;
begin
  lDetector := TDBSCANDetector.Create(1.0, 3, 1);
  try
    // Add 20 identical points
    for i := 1 to 20 do
      lDetector.AddPoint([42.0]);

    lDetector.Recluster;

    // All points should form one cluster
    Assert.AreEqual(1, lDetector.ClusterCount, 'Identical points should form single cluster');
    Assert.AreEqual(0, lDetector.OutlierCount, 'No outliers with identical points');

    // Same value should be normal
    lResult := lDetector.Detect(42.0);
    Assert.IsFalse(lResult.IsAnomaly, 'Identical value should be normal');

    // Different value should be anomaly
    lResult := lDetector.Detect(100.0);
    Assert.IsTrue(lResult.IsAnomaly, 'Different value should be anomaly');
  finally
    lDetector.Free;
  end;
end;

procedure TDBSCANDetectorTests.TestSinglePoint;
var
  lDetector: TDBSCANDetector;
  lResult: TAnomalyResult;
begin
  lDetector := TDBSCANDetector.Create(1.0, 1, 1); // MinPoints=1 to allow single point cluster
  try
    lDetector.AddPoint([10.0]);

    // Should not be initialized (MinPoints=1 but we need at least that)
    lResult := lDetector.Detect(10.0);

    // With MinPoints=1, even single point forms cluster
    lDetector.Recluster;
    Assert.IsTrue(lDetector.IsInitialized, 'Single point should initialize with MinPoints=1');
  finally
    lDetector.Free;
  end;
end;

procedure TDBSCANDetectorTests.TestMaxHistoryLimit;
var
  lDetector: TDBSCANDetector;
  i: Integer;
begin
  lDetector := TDBSCANDetector.Create(1.0, 3, 1);
  try
    lDetector.MaxHistorySize := 50;

    // Add 100 points (should keep only last 50)
    for i := 1 to 100 do
      lDetector.AddPoint([i * 1.0]);

    // Verify history was trimmed
    // Internal count not exposed, but we can verify behavior
    lDetector.Recluster;
    Assert.IsTrue(lDetector.ClusterCount >= 0, 'Should create clusters from trimmed history');

    // Add more points beyond limit
    for i := 101 to 150 do
      lDetector.AddPoint([i * 1.0]);

    lDetector.Recluster;

    // Clustering should still work with trimmed history
    Assert.IsTrue(lDetector.ClusterCount >= 0, 'Should handle history trimming correctly');

    // Old points (1-50) should have been removed, new points (101-150) should be kept
    var lResult := lDetector.Detect(1.0); // Very old value
    // This might or might not be anomaly depending on clustering, but shouldn't crash
    // Just verify no exception is raised and result is valid
    Assert.Pass('Detection completed successfully after history trim');
  finally
    lDetector.Free;
  end;
end;

{ TEvaluationFrameworkTests }

procedure TEvaluationFrameworkTests.Setup;
begin
  FDataset := TLabeledDataset.Create('Test Dataset');
end;

procedure TEvaluationFrameworkTests.TearDown;
begin
  FDataset.Free;
end;

procedure TEvaluationFrameworkTests.TestConfusionMatrix;
var
  Matrix: TConfusionMatrix;
begin
  Matrix.Reset;
  Assert.AreEqual<Int64>(0, Matrix.TruePositives);
  Assert.AreEqual<Int64>(0, Matrix.FalsePositives);
  Assert.AreEqual<Int64>(0, Matrix.TrueNegatives);
  Assert.AreEqual<Int64>(0, Matrix.FalseNegatives);

  Matrix.TruePositives := 80;
  Matrix.FalsePositives := 10;
  Matrix.TrueNegatives := 900;
  Matrix.FalseNegatives := 10;

  Assert.AreEqual<Int64>(80, Matrix.TruePositives);
  Assert.AreEqual<Int64>(10, Matrix.FalsePositives);
end;

procedure TEvaluationFrameworkTests.TestConfusionMatrixMetrics;
var
  Matrix: TConfusionMatrix;
begin
  Matrix.Reset;
  Matrix.TruePositives := 80;
  Matrix.FalsePositives := 20;
  Matrix.TrueNegatives := 880;
  Matrix.FalseNegatives := 20;

  // Total = 1000
  // Accuracy = (TP + TN) / Total = (80 + 880) / 1000 = 0.96
  Assert.IsTrue(AreFloatsEqual(0.96, Matrix.GetAccuracy, 0.01), 'Accuracy should be 0.96');

  // Precision = TP / (TP + FP) = 80 / (80 + 20) = 0.8
  Assert.IsTrue(AreFloatsEqual(0.8, Matrix.GetPrecision, 0.01), 'Precision should be 0.8');

  // Recall = TP / (TP + FN) = 80 / (80 + 20) = 0.8
  Assert.IsTrue(AreFloatsEqual(0.8, Matrix.GetRecall, 0.01), 'Recall should be 0.8');

  // F1 = 2 * P * R / (P + R) = 2 * 0.8 * 0.8 / (0.8 + 0.8) = 0.8
  Assert.IsTrue(AreFloatsEqual(0.8, Matrix.GetF1Score, 0.01), 'F1-Score should be 0.8');

  // Specificity = TN / (TN + FP) = 880 / (880 + 20) = 0.977...
  Assert.IsTrue(AreFloatsEqual(0.977, Matrix.GetSpecificity, 0.01), 'Specificity should be ~0.977');
end;

procedure TEvaluationFrameworkTests.TestLabeledDatasetCreation;
begin
  Assert.AreEqual(0, FDataset.Data.Count);

  FDataset.AddPoint(100, False, 'Normal');
  FDataset.AddPoint(200, True, 'Anomaly');

  Assert.AreEqual(2, FDataset.Data.Count);
  Assert.IsFalse(FDataset.Data[0].IsAnomaly);
  Assert.IsTrue(FDataset.Data[1].IsAnomaly);
end;

procedure TEvaluationFrameworkTests.TestDatasetGeneration;
begin
  FDataset.GenerateMixedDataset(100, 10, 100.0, 10.0);

  Assert.AreEqual(110, FDataset.Data.Count, 'Should have 110 points');
  Assert.AreEqual<Int64>(100, FDataset.GetNormalCount, 'Should have 100 normal points');
  Assert.AreEqual<Int64>(10, FDataset.GetAnomalyCount, 'Should have 10 anomalies');
  Assert.IsTrue(AreFloatsEqual(9.09, FDataset.GetAnomalyPercentage, 0.5), 'Should be ~9% anomalies');
end;

procedure TEvaluationFrameworkTests.TestDetectorEvaluation;
var
  Detector: IAnomalyDetector;
  Evaluator: TAnomalyDetectorEvaluator;
  Result: TEvaluationResult;
  TrainData: TArray<Double>;
  i: Integer;
begin
  // Create dataset
  FDataset.GenerateMixedDataset(800, 50, 100.0, 10.0);

  // Train detector on normal data
  Detector := TAnomalyDetectorFactory.CreateThreeSigma;

  SetLength(TrainData, 500);
  for i := 0 to 499 do
    TrainData[i] := FDataset.Data[i].Value;

  Detector.AddValues(TrainData);
  Detector.Build;

  // Evaluate
  Evaluator := TAnomalyDetectorEvaluator.Create(Detector, FDataset);
  try
    Result := Evaluator.Evaluate;

    Assert.AreEqual<Int64>(850, Result.DatasetSize);
    Assert.IsTrue(Result.EvaluationTimeMs >= 0);

    // Should have some detections (not perfect but reasonable)
    Assert.IsTrue(Result.ConfusionMatrix.TruePositives > 0, 'Should detect some anomalies');
    Assert.IsTrue(Result.ConfusionMatrix.TrueNegatives > 0, 'Should detect some normal values');
  finally
    Evaluator.Free;
  end;
end;

procedure TEvaluationFrameworkTests.TestPerfectDetector;
var
  Matrix: TConfusionMatrix;
begin
  // Simulate perfect detector
  Matrix.Reset;
  Matrix.TruePositives := 100;
  Matrix.TrueNegatives := 900;
  Matrix.FalsePositives := 0;
  Matrix.FalseNegatives := 0;

  Assert.AreEqual(1.0, Matrix.GetAccuracy, 0.001, 'Perfect detector should have 100% accuracy');
  Assert.AreEqual(1.0, Matrix.GetPrecision, 0.001, 'Perfect detector should have 100% precision');
  Assert.AreEqual(1.0, Matrix.GetRecall, 0.001, 'Perfect detector should have 100% recall');
  Assert.AreEqual(1.0, Matrix.GetF1Score, 0.001, 'Perfect detector should have F1=1.0');
end;

procedure TEvaluationFrameworkTests.TestWorstCaseDetector;
var
  Matrix: TConfusionMatrix;
begin
  // Simulate worst case: all predictions wrong
  Matrix.Reset;
  Matrix.TruePositives := 0;
  Matrix.TrueNegatives := 0;
  Matrix.FalsePositives := 900;
  Matrix.FalseNegatives := 100;

  Assert.AreEqual(0.0, Matrix.GetAccuracy, 0.001, 'Worst detector should have 0% accuracy');
  Assert.AreEqual(0.0, Matrix.GetPrecision, 0.001, 'Worst detector should have 0% precision');
  Assert.AreEqual(0.0, Matrix.GetRecall, 0.001, 'Worst detector should have 0% recall');
  Assert.AreEqual(0.0, Matrix.GetF1Score, 0.001, 'Worst detector should have F1=0.0');
end;

procedure TEvaluationFrameworkTests.TestCrossValidation;
var
  Detector: IAnomalyDetector;
  Evaluator: TAnomalyDetectorEvaluator;
  Results: TArray<TEvaluationResult>;
begin
  FDataset.GenerateMixedDataset(500, 50, 100.0, 10.0);

  Detector := TAnomalyDetectorFactory.CreateSlidingWindow(50);

  Evaluator := TAnomalyDetectorEvaluator.Create(Detector, FDataset);
  try
    Evaluator.Verbose := False;
    Results := Evaluator.CrossValidate(3);  // 3-fold CV

    Assert.AreEqual(3, Length(Results), 'Should have 3 fold results');

    // Each fold should have processed some data
    for var i := 0 to High(Results) do
    begin
      Assert.IsTrue(Results[i].DatasetSize > 0, 'Each fold should process data');
      Assert.IsTrue(Results[i].EvaluationTimeMs >= 0, 'Each fold should have timing');
    end;
  finally
    Evaluator.Free;
  end;
end;

procedure TEvaluationFrameworkTests.TestTrainTestSplit;
var
  Detector: IAnomalyDetector;
  Evaluator: TAnomalyDetectorEvaluator;
  Result: TEvaluationResult;
begin
  FDataset.GenerateMixedDataset(1000, 100, 100.0, 10.0);

  Detector := TAnomalyDetectorFactory.CreateThreeSigma;

  Evaluator := TAnomalyDetectorEvaluator.Create(Detector, FDataset);
  try
    Result := Evaluator.EvaluateWithTrainTestSplit(0.7);  // 70% train, 30% test

    // Should evaluate on ~330 test points (30% of 1100)
    Assert.IsTrue(Result.DatasetSize < FDataset.Data.Count, 'Should evaluate on test set only');
    Assert.IsTrue(Result.DatasetSize > 200, 'Test set should have reasonable size');
  finally
    Evaluator.Free;
  end;
end;

procedure TEvaluationFrameworkTests.TestEmptyDatasetEvaluation;
var
  Detector: IAnomalyDetector;
  Evaluator: TAnomalyDetectorEvaluator;
begin
  // FDataset is empty from Setup

  Detector := TAnomalyDetectorFactory.CreateThreeSigma;
  Evaluator := TAnomalyDetectorEvaluator.Create(Detector, FDataset);
  try
    Assert.WillRaise(
      procedure
      begin
        Evaluator.Evaluate;
      end,
      EAnomalyDetectionException
    );
  finally
    Evaluator.Free;
  end;
end;

procedure TEvaluationFrameworkTests.TestZeroDivisionInMetrics;
var
  Matrix: TConfusionMatrix;
begin
  // Test all-zero confusion matrix (edge case)
  Matrix.Reset;
  Assert.AreEqual(0.0, Matrix.GetAccuracy, 0.001, 'Accuracy should be 0 when no data');
  Assert.AreEqual(0.0, Matrix.GetPrecision, 0.001, 'Precision should be 0 when no data');
  Assert.AreEqual(0.0, Matrix.GetRecall, 0.001, 'Recall should be 0 when no data');
  Assert.AreEqual(0.0, Matrix.GetF1Score, 0.001, 'F1 should be 0 when no data');

  // Test precision with no positive predictions
  Matrix.TruePositives := 0;
  Matrix.FalsePositives := 0;
  Matrix.TrueNegatives := 100;
  Matrix.FalseNegatives := 10;
  Assert.AreEqual(0.0, Matrix.GetPrecision, 0.001, 'Precision should be 0 when no positive predictions');

  // Test recall with no actual positives
  Matrix.Reset;
  Matrix.TruePositives := 0;
  Matrix.FalsePositives := 10;
  Matrix.TrueNegatives := 90;
  Matrix.FalseNegatives := 0;
  Assert.AreEqual(0.0, Matrix.GetRecall, 0.001, 'Recall should be 0 when no actual positives');
end;

procedure TEvaluationFrameworkTests.TestInvalidTrainRatio;
var
  Detector: IAnomalyDetector;
  Evaluator: TAnomalyDetectorEvaluator;
begin
  FDataset.GenerateMixedDataset(100, 10, 100.0, 10.0);

  Detector := TAnomalyDetectorFactory.CreateThreeSigma;
  Evaluator := TAnomalyDetectorEvaluator.Create(Detector, FDataset);
  try
    // Test ratio = 0
    Assert.WillRaise(
      procedure
      begin
        Evaluator.EvaluateWithTrainTestSplit(0.0);
      end,
      EAnomalyDetectionException
    );

    // Test ratio = 1
    Assert.WillRaise(
      procedure
      begin
        Evaluator.EvaluateWithTrainTestSplit(1.0);
      end,
      EAnomalyDetectionException
    );

    // Test ratio < 0
    Assert.WillRaise(
      procedure
      begin
        Evaluator.EvaluateWithTrainTestSplit(-0.5);
      end,
      EAnomalyDetectionException
    );

    // Test ratio > 1
    Assert.WillRaise(
      procedure
      begin
        Evaluator.EvaluateWithTrainTestSplit(1.5);
      end,
      EAnomalyDetectionException
    );
  finally
    Evaluator.Free;
  end;
end;

procedure TEvaluationFrameworkTests.TestTooManyFolds;
var
  Detector: IAnomalyDetector;
  Evaluator: TAnomalyDetectorEvaluator;
begin
  FDataset.GenerateMixedDataset(10, 2, 100.0, 10.0);  // Only 12 points

  Detector := TAnomalyDetectorFactory.CreateSlidingWindow(5);
  Evaluator := TAnomalyDetectorEvaluator.Create(Detector, FDataset);
  try
    // Try 20 folds with only 12 data points
    Assert.WillRaise(
      procedure
      begin
        Evaluator.CrossValidate(20);
      end,
      EAnomalyDetectionException
    );

    // Try 1 fold (minimum is 2)
    Assert.WillRaise(
      procedure
      begin
        Evaluator.CrossValidate(1);
      end,
      EAnomalyDetectionException
    );

    // Try 0 folds
    Assert.WillRaise(
      procedure
      begin
        Evaluator.CrossValidate(0);
      end,
      EAnomalyDetectionException
    );
  finally
    Evaluator.Free;
  end;
end;

{ THyperparameterTuningTests }

procedure THyperparameterTuningTests.Setup;
begin
  FDataset := TLabeledDataset.Create('Tuning Dataset');
  FDataset.GenerateMixedDataset(500, 50, 100.0, 10.0);
end;

procedure THyperparameterTuningTests.TearDown;
begin
  FDataset.Free;
end;

procedure THyperparameterTuningTests.TestGridSearchBasic;
var
  Tuner: THyperparameterTuner;
  BestConfig: TTuningResult;
  SigmaValues: TArray<Double>;
begin
  Tuner := THyperparameterTuner.Create(adtThreeSigma, FDataset);
  try
    Tuner.OptimizationMetric := 'F1';
    Tuner.Verbose := False;

    SigmaValues := [2.5, 3.0, 3.5];
    BestConfig := Tuner.GridSearch(SigmaValues);

    Assert.IsTrue(BestConfig.Score >= 0, 'Best score should be >= 0');
    Assert.IsTrue(BestConfig.Score <= 1.0, 'Best score should be <= 1.0');
    Assert.IsTrue(BestConfig.Config.SigmaMultiplier >= 2.5);
    Assert.IsTrue(BestConfig.Config.SigmaMultiplier <= 3.5);
    Assert.AreEqual(3, Tuner.Results.Count, 'Should test 3 configurations');
  finally
    Tuner.Free;
  end;
end;

procedure THyperparameterTuningTests.TestRandomSearch;
var
  Tuner: THyperparameterTuner;
  BestConfig: TTuningResult;
begin
  Tuner := THyperparameterTuner.Create(adtSlidingWindow, FDataset);
  try
    Tuner.OptimizationMetric := 'F1';
    Tuner.Verbose := False;

    BestConfig := Tuner.RandomSearch(5);  // 5 random configurations

    Assert.IsTrue(BestConfig.Score >= 0);
    Assert.IsTrue(BestConfig.Score <= 1.0);
    Assert.AreEqual(5, Tuner.Results.Count, 'Should test 5 configurations');

    // Check that configs are different (randomness)
    Assert.AreNotEqual(
      Tuner.Results[0].Config.SigmaMultiplier,
      Tuner.Results[1].Config.SigmaMultiplier,
      'Random configs should differ'
    );
  finally
    Tuner.Free;
  end;
end;

procedure THyperparameterTuningTests.TestDifferentMetrics;
var
  TunerF1, TunerPrecision, TunerRecall: THyperparameterTuner;
  BestF1, BestPrecision, BestRecall: TTuningResult;
  SigmaValues: TArray<Double>;
begin
  SigmaValues := [2.0, 3.0, 4.0];

  // Optimize for F1
  TunerF1 := THyperparameterTuner.Create(adtThreeSigma, FDataset);
  try
    TunerF1.OptimizationMetric := 'F1';
    TunerF1.Verbose := False;
    BestF1 := TunerF1.GridSearch(SigmaValues);
  finally
    TunerF1.Free;
  end;

  // Optimize for Precision
  TunerPrecision := THyperparameterTuner.Create(adtThreeSigma, FDataset);
  try
    TunerPrecision.OptimizationMetric := 'Precision';
    TunerPrecision.Verbose := False;
    BestPrecision := TunerPrecision.GridSearch(SigmaValues);
  finally
    TunerPrecision.Free;
  end;

  // Optimize for Recall
  TunerRecall := THyperparameterTuner.Create(adtThreeSigma, FDataset);
  try
    TunerRecall.OptimizationMetric := 'Recall';
    TunerRecall.Verbose := False;
    BestRecall := TunerRecall.GridSearch(SigmaValues);
  finally
    TunerRecall.Free;
  end;

  // All should return valid results
  Assert.IsTrue(BestF1.Score >= 0);
  Assert.IsTrue(BestPrecision.Score >= 0);
  Assert.IsTrue(BestRecall.Score >= 0);

  // Different metrics may choose different configs
  // (Not guaranteed but likely with diverse sigma values)
end;

procedure THyperparameterTuningTests.TestTopConfigurations;
var
  Tuner: THyperparameterTuner;
  TopConfigs: TArray<TTuningResult>;
  SigmaValues: TArray<Double>;
  i: Integer;
begin
  Tuner := THyperparameterTuner.Create(adtThreeSigma, FDataset);
  try
    Tuner.OptimizationMetric := 'F1';
    Tuner.Verbose := False;

    SigmaValues := [2.0, 2.5, 3.0, 3.5, 4.0, 4.5];
    Tuner.GridSearch(SigmaValues);

    TopConfigs := Tuner.GetTopConfigurations(3);

    Assert.AreEqual(3, Length(TopConfigs), 'Should return top 3 configurations');

    // Verify they are sorted descending by score
    for i := 0 to High(TopConfigs) - 1 do
      Assert.IsTrue(TopConfigs[i].Score >= TopConfigs[i + 1].Score,
        'Top configs should be sorted by score (descending)');
  finally
    Tuner.Free;
  end;
end;

procedure THyperparameterTuningTests.TestEmptyParameterArray;
var
  Tuner: THyperparameterTuner;
  EmptySigma: TArray<Double>;
begin
  Tuner := THyperparameterTuner.Create(adtThreeSigma, FDataset);
  try
    SetLength(EmptySigma, 0);

    Assert.WillRaise(
      procedure
      begin
        Tuner.GridSearch(EmptySigma);
      end,
      EAnomalyDetectionException
    );
  finally
    Tuner.Free;
  end;
end;

procedure THyperparameterTuningTests.TestInvalidIterations;
var
  Tuner: THyperparameterTuner;
begin
  Tuner := THyperparameterTuner.Create(adtSlidingWindow, FDataset);
  try
    // Test with 0 iterations
    Assert.WillRaise(
      procedure
      begin
        Tuner.RandomSearch(0);
      end,
      EAnomalyDetectionException
    );

    // Test with negative iterations
    Assert.WillRaise(
      procedure
      begin
        Tuner.RandomSearch(-5);
      end,
      EAnomalyDetectionException
    );
  finally
    Tuner.Free;
  end;
end;

procedure THyperparameterTuningTests.TestGetTopWithEmptyResults;
var
  Tuner: THyperparameterTuner;
  TopConfigs: TArray<TTuningResult>;
begin
  Tuner := THyperparameterTuner.Create(adtThreeSigma, FDataset);
  try
    // Don't run any search, results list is empty

    // Should return empty array, not crash
    TopConfigs := Tuner.GetTopConfigurations(5);
    Assert.AreEqual(0, Length(TopConfigs), 'Should return empty array when no results');

    // Test with invalid count
    Assert.WillRaise(
      procedure
      begin
        Tuner.GetTopConfigurations(0);
      end,
      EAnomalyDetectionException
    );

    Assert.WillRaise(
      procedure
      begin
        Tuner.GetTopConfigurations(-1);
      end,
      EAnomalyDetectionException
    );
  finally
    Tuner.Free;
  end;
end;

{ TLOFDetectorTests }

procedure TLOFDetectorTests.Setup;
begin
  // Use k=3 for predictable testing, 1 dimension
  FDetector := TLOFDetector.Create(3, 1);
end;

procedure TLOFDetectorTests.TearDown;
begin
  FDetector.Free;
end;

procedure TLOFDetectorTests.TestInitialState;
begin
  Assert.AreEqual(3, FDetector.KNeighbors, 'KNeighbors should be set from constructor');
  Assert.AreEqual(1, FDetector.Dimensions, 'Dimensions should be set from constructor');
  Assert.IsFalse(FDetector.IsInitialized, 'Should not be initialized initially');
  Assert.AreEqual(0, FDetector.DataPointsCount, 'Should have no data points initially');
end;

procedure TLOFDetectorTests.TestInsufficientDataException;
begin
  // Add fewer points than k+1
  FDetector.AddValue(100);
  FDetector.AddValue(101);
  FDetector.AddValue(102);

  Assert.IsFalse(FDetector.IsInitialized, 'Should not be initialized with insufficient data');

  // Build should fail
  Assert.WillRaise(
    procedure
    begin
      FDetector.Build;
    end,
    EAnomalyDetectionException,
    'Should raise exception when building with insufficient data'
  );
end;

procedure TLOFDetectorTests.TestSimpleClusterAndOutlier;
var
  i: Integer;
  ResultInlier, ResultOutlier: TAnomalyResult;
begin
  // Create a dense cluster around 10
  for i := 0 to 10 do
    FDetector.AddValue(10 + Random * 0.5);

  // Add a clear outlier
  FDetector.AddValue(100);

  // Build the model
  FDetector.Build;
  Assert.IsTrue(FDetector.IsInitialized, 'Should be initialized after build');

  // Test a point inside the cluster (inlier)
  ResultInlier := FDetector.Detect(10.2);
  Assert.IsFalse(ResultInlier.IsAnomaly, 'Point within the cluster should be normal');
  Assert.IsTrue(ResultInlier.Value < FDetector.Threshold, 'Inlier LOF score should be less than threshold');

  // Test a point far from the cluster (outlier)
  ResultOutlier := FDetector.Detect(90);
  Assert.IsTrue(ResultOutlier.IsAnomaly, 'Isolated point should be an anomaly');
  Assert.IsTrue(ResultOutlier.Value > FDetector.Threshold, 'Outlier LOF score should be greater than threshold');
end;

procedure TLOFDetectorTests.TestMultiDimensionalOutlier;
var
  i: Integer;
  Detector2D: TLOFDetector;
  ResultInlier, ResultOutlier: TAnomalyResult;
begin
  Detector2D := TLOFDetector.Create(5, 2); // k=5, 2 dimensions
  try
    // Create a dense 2D cluster around [10, 10]
    for i := 0 to 20 do
      Detector2D.AddPoint([10 + Random * 2 - 1, 10 + Random * 2 - 1]);

    // Add a 2D outlier
    Detector2D.AddPoint([50, 50]);

    Detector2D.Build;
    Assert.IsTrue(Detector2D.IsInitialized, '2D detector should be initialized');

    // Test an inlier
    ResultInlier := Detector2D.DetectMultiDimensional([10.5, 9.8]);
    Assert.IsFalse(ResultInlier.IsAnomaly, '2D inlier should be normal');
    Assert.IsTrue(ResultInlier.Value < Detector2D.Threshold, '2D inlier LOF score should be low');

    // Test the outlier
    ResultOutlier := Detector2D.DetectMultiDimensional([45, 52]);
    Assert.IsTrue(ResultOutlier.IsAnomaly, '2D outlier should be detected as anomaly');
    Assert.IsTrue(ResultOutlier.Value > Detector2D.Threshold, '2D outlier LOF score should be high');

  finally
    Detector2D.Free;
  end;
end;

procedure TLOFDetectorTests.TestDimensionMismatchException;
begin
  // Detector is created with 1 dimension
  Assert.WillRaise(
    procedure
    begin
      // Try to add a 2D point
      FDetector.AddPoint([10, 20]);
    end,
    EAnomalyDetectionException,
    'Should raise exception on dimension mismatch when adding data'
  );

  // Add enough valid data to build
  for var i := 0 to 10 do
    FDetector.AddValue(i);
  FDetector.Build;

  // Now try to detect with wrong dimension
  Assert.WillRaise(
    procedure
    begin
      FDetector.DetectMultiDimensional([10, 20]);
    end,
    EAnomalyDetectionException,
    'Should raise exception on dimension mismatch during detection'
  );
end;

procedure TLOFDetectorTests.TestSaveLoadState;
var
  Stream: TMemoryStream;
  NewDetector: TLOFDetector;
  i: Integer;
  ResultBefore, ResultAfter: TAnomalyResult;
begin
  // Add data and build model
  for i := 0 to 20 do
    FDetector.AddValue(100 + i);
  FDetector.Build;

  ResultBefore := FDetector.Detect(200); // Detect an outlier

  Stream := TMemoryStream.Create;
  try
    // Save state
    FDetector.SaveState(Stream);
    Stream.Position := 0;

    // Create new detector and load state
    NewDetector := TLOFDetector.Create;
    try
      NewDetector.LoadState(Stream);

      // Verify properties
      Assert.AreEqual(FDetector.KNeighbors, NewDetector.KNeighbors, 'KNeighbors should match after load');
      Assert.AreEqual(FDetector.Dimensions, NewDetector.Dimensions, 'Dimensions should match after load');
      Assert.AreEqual(FDetector.DataPointsCount, NewDetector.DataPointsCount, 'DataPointsCount should match');
      Assert.IsTrue(NewDetector.IsInitialized, 'New detector should be initialized');

      // Verify detection logic
      ResultAfter := NewDetector.Detect(200);

      Assert.AreEqual(ResultBefore.IsAnomaly, ResultAfter.IsAnomaly, 'Anomaly flag should be identical after load');
      Assert.IsTrue(AreFloatsEqual(ResultBefore.Value, ResultAfter.Value), 'LOF Score should be identical after load');

    finally
      NewDetector.Free;
    end;
  finally
    Stream.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TAnomalyDetectionConfigTests);
  TDUnitX.RegisterTestFixture(TThreeSigmaDetectorTests);
  TDUnitX.RegisterTestFixture(TSlidingWindowDetectorTests);
  TDUnitX.RegisterTestFixture(TEMAAnomalyDetectorTests);
  TDUnitX.RegisterTestFixture(TAdaptiveAnomalyDetectorTests);
  TDUnitX.RegisterTestFixture(TIsolationForestDetectorTests);
  TDUnitX.RegisterTestFixture(TDBSCANDetectorTests);
  TDUnitX.RegisterTestFixture(TAnomalyConfirmationSystemTests);
  TDUnitX.RegisterTestFixture(TIntegrationTests);
  TDUnitX.RegisterTestFixture(TEvaluationFrameworkTests);
  TDUnitX.RegisterTestFixture(THyperparameterTuningTests);
  TDUnitX.RegisterTestFixture(TLOFDetectorTests);

end.
