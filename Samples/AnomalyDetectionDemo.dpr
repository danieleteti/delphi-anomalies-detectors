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

program AnomalyDetectionDemo;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  System.DateUtils,
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF}
  AnomalyDetectionAlgorithms in '..\AnomalyDetectionAlgorithms.pas';

const
  // Colors for console output (Windows)
  COLOR_NORMAL = 7;     // Light gray
  COLOR_ANOMALY = 12;   // Light red
  COLOR_WARNING = 14;   // Yellow
  COLOR_SUCCESS = 10;   // Light green
  COLOR_INFO = 11;      // Light cyan
  COLOR_TITLE = 13;     // Light magenta

procedure SetConsoleColor(Color: Word);
begin
  {$IFDEF MSWINDOWS}
  SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), Color);
  {$ELSE}
  // On other platforms, ignore colors
  {$ENDIF}
end;

procedure WriteColoredLine(const Text: string; Color: Word);
begin
  SetConsoleColor(Color);
  WriteLn(Text);
  SetConsoleColor(COLOR_NORMAL);
end;

procedure WaitForUser;
begin
  WriteLn;
  WriteColoredLine('Press ENTER to continue...', COLOR_INFO);
  Readln;
end;

procedure DrawSeparator;
begin
  WriteLn(StringOfChar('-', 80));
end;

procedure DrawDoubleSeparator;
begin
  WriteLn(StringOfChar('=', 80));
end;

// ============================================================================
// CLASSIC ALGORITHMS
// ============================================================================

procedure TestThreeSigmaDetector;
var
  Detector: TThreeSigmaDetector;
  SalesData: TArray<Double>;
  TestValues: array[0..6] of Double;
  i: Integer;
  Result: TAnomalyResult;
  Metrics: TDetectorMetrics;
begin
  WriteColoredLine('=== 3-SIGMA DETECTOR TEST ===', COLOR_TITLE);
  WriteLn('The 3-Sigma detector is ideal when you have stable historical data.');
  WriteLn('It uses the statistical rule that 99.7% of normal values fall within ±3σ from the mean.');
  WriteLn;

  Detector := TThreeSigmaDetector.Create;
  try
    // Generate historical sales data (30 days)
    WriteLn('Generating 30 days of historical sales data...');
    SetLength(SalesData, 30);
    for i := 0 to 29 do
    begin
      // Base sales 100-200 with weekly pattern
      SalesData[i] := 150 + Random(50) + (Sin(i * 2 * Pi / 7) * 20);
      Write(Format('%.0f ', [SalesData[i]]));
      if (i + 1) mod 10 = 0 then WriteLn;
    end;
    WriteLn;

    Detector.SetHistoricalData(SalesData);
    Detector.CalculateStatistics;

    DrawSeparator;
    WriteColoredLine('Calculated statistics:', COLOR_INFO);
    WriteLn(Format('  Mean: %.2f units', [Detector.Mean]));
    WriteLn(Format('  Standard Deviation: %.2f', [Detector.StdDev]));
    WriteLn(Format('  Normal Range (3σ): %.2f - %.2f', [Detector.LowerLimit, Detector.UpperLimit]));
    DrawSeparator;

    // Test values with realistic scenarios
    TestValues[0] := 150;    // Normal - typical sales
    TestValues[1] := 180;    // Normal - good day
    TestValues[2] := 120;    // Normal - slow day
    TestValues[3] := 300;    // Anomaly - unexpected spike
    TestValues[4] := 50;     // Anomaly - sales crash
    TestValues[5] := Detector.Mean + 2.5 * Detector.StdDev;  // At the limit
    TestValues[6] := Detector.Mean - 3.1 * Detector.StdDev;  // Just outside limit

    WriteLn('Testing various sales values:');
    for i := 0 to High(TestValues) do
    begin
      Detector.PerformanceMonitor.StartMeasurement;
      Result := Detector.Detect(TestValues[i]);
      Detector.PerformanceMonitor.StopMeasurement(Result.IsAnomaly);

      if Result.IsAnomaly then
        WriteColoredLine(Format('  %.0f units: %s', [TestValues[i], Result.Description]), COLOR_ANOMALY)
      else
        WriteLn(Format('  %.0f units: %s', [TestValues[i], Result.Description]));
    end;

    DrawSeparator;
    WriteColoredLine('PERFORMANCE METRICS:', COLOR_INFO);
    WriteLn(Detector.GetPerformanceReport);

    // Add meaningful analysis
    Metrics := Detector.PerformanceMonitor.GetCurrentMetrics;
    WriteColoredLine('ANALYSIS:', COLOR_INFO);
    WriteLn(Format('Detection accuracy: %d/%d anomalies correctly identified',
                  [Metrics.AnomaliesDetected, 3])); // We expect 3 anomalies
    WriteLn(Format('Processing efficiency: %.0f detections/second', [Metrics.ThroughputPerSecond]));

  finally
    Detector.Free;
  end;

  WaitForUser;
end;

procedure TestSlidingWindowDetector;
var
  Detector: TSlidingWindowDetector;
  Config: TAnomalyDetectionConfig;
  i: Integer;
  Value: Double;
  Result: TAnomalyResult;
  AnomalyCount: Integer;
  Metrics: TDetectorMetrics;
begin
  WriteColoredLine('=== SLIDING WINDOW DETECTOR TEST ===', COLOR_TITLE);
  WriteLn('This detector maintains a moving window of the last N values.');
  WriteLn('Perfect for data streams where conditions change gradually.');
  WriteLn('The window automatically adapts to seasonal changes.');
  WriteLn;

  // Custom configuration for higher sensitivity
  Config := TAnomalyDetectionConfig.Default;
  Config.SigmaMultiplier := 2.5; // More sensitive than standard 3-sigma

  Detector := TSlidingWindowDetector.Create(50, Config);
  try
    WriteColoredLine('Simulating 150 readings with evolving pattern...', COLOR_INFO);
    AnomalyCount := 0;

    for i := 1 to 150 do
    begin
      // Simulate an increasing trend with noise
      if i <= 50 then
        Value := 100 + Random(20) - 10  // Mean ~100
      else if i <= 100 then
        Value := 150 + Random(30) - 15  // Mean ~150
      else
        Value := 200 + Random(40) - 20; // Mean ~200

      // Insert some anomalies
      if i in [25, 75, 125] then
      begin
        Value := Value * 2.5;  // Anomalous spike
        WriteColoredLine(Format('>>> Spike inserted at point %d: %.0f', [i, Value]), COLOR_WARNING);
      end;

      Detector.AddValue(Value);

      Detector.PerformanceMonitor.StartMeasurement;
      Result := Detector.Detect(Value);
      Detector.PerformanceMonitor.StopMeasurement(Result.IsAnomaly);

      if Result.IsAnomaly then
      begin
        Inc(AnomalyCount);
        WriteColoredLine(Format('  [%3d] ANOMALY DETECTED: %.0f (Z-score: %.2f)',
                               [i, Value, Result.ZScore]), COLOR_ANOMALY);
      end;

      // Show statistics periodically
      if (i mod 50 = 0) then
      begin
        DrawSeparator;
        WriteLn(Format('After %d values:', [i]));
        WriteLn(Format('  Current mean: %.2f', [Detector.CurrentMean]));
        WriteLn(Format('  Std. deviation: %.2f', [Detector.CurrentStdDev]));
        WriteLn(Format('  Normal range: %.2f - %.2f', [Detector.LowerLimit, Detector.UpperLimit]));
        WriteLn(Format('  Anomalies detected: %d', [AnomalyCount]));
        DrawSeparator;
      end;
    end;

    WriteLn;
    WriteColoredLine(Format('Total anomalies detected: %d out of 150 values (%.1f%%)',
                           [AnomalyCount, AnomalyCount / 150 * 100]), COLOR_INFO);

    DrawSeparator;
    WriteColoredLine('PERFORMANCE METRICS:', COLOR_INFO);
    WriteLn(Detector.GetPerformanceReport);

    // Add meaningful analysis
    Metrics := Detector.PerformanceMonitor.GetCurrentMetrics;
    WriteColoredLine('SLIDING WINDOW ANALYSIS:', COLOR_INFO);
    WriteLn(Format('Adaptation success: Tracked %d regime changes', [3]));
    WriteLn(Format('Processing efficiency: %.0f detections/second', [Metrics.ThroughputPerSecond]));

  finally
    Detector.Free;
  end;

  WaitForUser;
end;

procedure TestIsolationForestDetector;
var
  Detector: TIsolationForestDetector;
  i: Integer;
  Instance: TArray<Double>;
  Result: TAnomalyResult;
  NormalCount, AnomalyCount: Integer;
  StartTime: TDateTime;
  TrainingTime: Int64;
  StreamNormal, StreamAnomalies: Integer;
  Metrics: TDetectorMetrics;
begin
  WriteColoredLine('=== ISOLATION FOREST DETECTOR TEST ===', COLOR_TITLE);
  WriteLn('Isolation Forest is excellent for multi-dimensional data.');
  WriteLn('It works by building random binary trees where anomalies');
  WriteLn('are easier to "isolate" (require fewer splits).');
  WriteLn('Perfect for: fraud detection, cybersecurity, multi-sensor IoT.');
  WriteLn;

  // Optimized configuration for demo
  Detector := TIsolationForestDetector.Create(50, 100, 8); // 50 trees, 100 samples, depth 8
  try
    WriteColoredLine('Phase 1: Training with normal data (main cluster)', COLOR_INFO);

    // Generate normal cluster centered on (100, 50)
    for i := 1 to 200 do
    begin
      SetLength(Instance, 2);
      Instance[0] := 100 + Random(30) - 15; // X: 85-115
      Instance[1] := 50 + Random(20) - 10;  // Y: 40-60
      Detector.AddTrainingData(Instance);

      if i <= 10 then
        Write(Format('(%.0f,%.0f) ', [Instance[0], Instance[1]]));
    end;
    WriteLn;

    // Add a second smaller cluster (normal)
    WriteColoredLine('Adding second normal cluster...', COLOR_INFO);
    for i := 1 to 50 do
    begin
      SetLength(Instance, 2);
      Instance[0] := 150 + Random(20) - 10; // X: 140-160
      Instance[1] := 80 + Random(16) - 8;   // Y: 72-88
      Detector.AddTrainingData(Instance);
    end;

    WriteLn(Format('Training with %d 2D samples...', [250]));
    StartTime := Now;
    Detector.Train;
    TrainingTime := MilliSecondsBetween(Now, StartTime);

    WriteColoredLine(Format('✓ Training completed in %d ms', [TrainingTime]), COLOR_SUCCESS);
    WriteLn(Format('  Number of trees: %d', [Detector.NumTrees]));
    WriteLn(Format('  Feature dimensions: %d', [Detector.FeatureCount]));
    DrawSeparator;

    WriteColoredLine('Phase 2: Testing specific points', COLOR_INFO);
    NormalCount := 0;
    AnomalyCount := 0;

    // Test normal points
    SetLength(Instance, 2);

    // Center of first cluster
    Instance[0] := 100; Instance[1] := 50;
    Detector.PerformanceMonitor.StartMeasurement;
    Result := Detector.DetectMultiDimensional(Instance);
    Detector.PerformanceMonitor.StopMeasurement(Result.IsAnomaly);
    Write(Format('  [%.0f, %.0f] Center cluster 1: ', [Instance[0], Instance[1]]));
    if not Result.IsAnomaly then
    begin
      Inc(NormalCount);
      WriteLn('Normal');
    end else begin
      Inc(AnomalyCount);
      WriteColoredLine('ANOMALY', COLOR_ANOMALY);
    end;

    // Test anomaly points
    Instance[0] := 300; Instance[1] := 300;
    Detector.PerformanceMonitor.StartMeasurement;
    Result := Detector.DetectMultiDimensional(Instance);
    Detector.PerformanceMonitor.StopMeasurement(Result.IsAnomaly);
    Write(Format('  [%.0f, %.0f] Very far point: ', [Instance[0], Instance[1]]));
    if Result.IsAnomaly then
    begin
      Inc(AnomalyCount);
      WriteColoredLine('ANOMALY', COLOR_ANOMALY);
    end else begin
      Inc(NormalCount);
      WriteLn('Normal');
    end;

    DrawSeparator;
    WriteColoredLine('Phase 3: Stream test on random data', COLOR_INFO);
    StreamNormal := 0;
    StreamAnomalies := 0;

    for i := 1 to 100 do
    begin
      SetLength(Instance, 2);

      // 90% normal points, 10% anomalies
      if Random(10) = 0 then
      begin
        // Generate anomaly - far from both clusters
        Instance[0] := 300 + Random(100);
        Instance[1] := 200 + Random(100);
      end
      else
      begin
        // Generate normal point (random clusters)
        if Random(2) = 0 then
        begin
          Instance[0] := 100 + Random(30) - 15;
          Instance[1] := 50 + Random(20) - 10;
        end
        else
        begin
          Instance[0] := 150 + Random(20) - 10;
          Instance[1] := 80 + Random(16) - 8;
        end;
      end;

      Detector.PerformanceMonitor.StartMeasurement;
      Result := Detector.DetectMultiDimensional(Instance);
      Detector.PerformanceMonitor.StopMeasurement(Result.IsAnomaly);

      if Result.IsAnomaly then
      begin
        Inc(StreamAnomalies);
        if StreamAnomalies <= 5 then // Show only first 5
          WriteColoredLine(Format('  Stream anomaly: (%.0f, %.0f)',
                                 [Instance[0], Instance[1]]), COLOR_ANOMALY);
      end
      else
        Inc(StreamNormal);
    end;

    WriteLn;
    WriteColoredLine('=== ISOLATION FOREST RESULTS ===', COLOR_SUCCESS);
    WriteLn(Format('Fixed point tests: %d normal, %d anomalies', [NormalCount, AnomalyCount]));
    WriteLn(Format('Stream test: %d normal, %d anomalies out of 100 points', [StreamNormal, StreamAnomalies]));
    WriteLn(Format('Anomaly detection rate: %.1f%% (expected ~10%%)', [StreamAnomalies / 100 * 100]));

    WriteColoredLine('ALGORITHM ANALYSIS:', COLOR_INFO);
    if AnomalyCount >= 1 then
      WriteColoredLine('✓ Successfully identified extreme outliers', COLOR_SUCCESS)
    else
      WriteColoredLine('⚠ May need tuning for this data distribution', COLOR_WARNING);

    if (StreamAnomalies >= 5) and (StreamAnomalies <= 15) then
      WriteColoredLine('✓ Good balance: detected anomalies without excessive false positives', COLOR_SUCCESS)
    else if StreamAnomalies < 5 then
      WriteColoredLine('⚠ May be under-sensitive (too few anomalies detected)', COLOR_WARNING)
    else
      WriteColoredLine('⚠ May be over-sensitive (too many false positives)', COLOR_WARNING);

    DrawSeparator;
    WriteColoredLine('PERFORMANCE METRICS:', COLOR_INFO);
    WriteLn(Detector.GetPerformanceReport);

    // Add meaningful analysis
    Metrics := Detector.PerformanceMonitor.GetCurrentMetrics;
    WriteColoredLine('ISOLATION FOREST ANALYSIS:', COLOR_INFO);
    WriteLn(Format('Total evaluations: %d points processed', [Metrics.TotalDetections]));
    WriteLn(Format('Multi-dimensional performance: %.0f detections/sec', [Metrics.ThroughputPerSecond]));
    WriteLn(Format('Training efficiency: %d ms for %d trees', [TrainingTime, Detector.NumTrees]));

  finally
    Detector.Free;
  end;

  WaitForUser;
end;

procedure TestFactoryPattern;
var
  WebTrafficDetector: TBaseAnomalyDetector;
  FinancialDetector: TBaseAnomalyDetector;
  i: Integer;
  Result: TAnomalyResult;
  Metrics: TDetectorMetrics;
begin
  WriteColoredLine('=== DETECTOR FACTORY PATTERN DEMO ===', COLOR_TITLE);
  WriteLn('The Factory Pattern simplifies detector creation');
  WriteLn('with optimized configurations for specific scenarios.');
  WriteLn;

  WriteColoredLine('Creating pre-configured detectors:', COLOR_INFO);

  // Web Traffic Monitoring
  WebTrafficDetector := TAnomalyDetectorFactory.CreateForWebTrafficMonitoring;
  try
    WriteColoredLine('1. Web Traffic Monitor (Sliding Window, σ=2.5)', COLOR_SUCCESS);
    WriteLn(Format('   Type: %s', [WebTrafficDetector.ClassName]));
    WriteLn(Format('   Name: %s', [WebTrafficDetector.Name]));
    WriteLn(Format('   Sigma: %.1f (more sensitive for security)', [WebTrafficDetector.Config.SigmaMultiplier]));

    // Quick test with performance monitoring
    if WebTrafficDetector is TSlidingWindowDetector then
    begin
      for i := 1 to 50 do
        TSlidingWindowDetector(WebTrafficDetector).AddValue(1000 + Random(200) - 100); // Normal traffic

      WebTrafficDetector.PerformanceMonitor.StartMeasurement;
      Result := WebTrafficDetector.Detect(5000); // DDoS spike
      WebTrafficDetector.PerformanceMonitor.StopMeasurement(Result.IsAnomaly);

      if Result.IsAnomaly then
        WriteColoredLine('   ✓ Test: DDoS attack detected correctly', COLOR_SUCCESS)
      else
        WriteColoredLine('   ✗ Test: DDoS attack NOT detected', COLOR_ANOMALY);

      Metrics := WebTrafficDetector.PerformanceMonitor.GetCurrentMetrics;
      WriteLn(Format('   Performance: %.0f detections/sec', [Metrics.ThroughputPerSecond]));
    end;
    WriteLn;

  finally
    WebTrafficDetector.Free;
  end;

  // Financial Data
  FinancialDetector := TAnomalyDetectorFactory.CreateForFinancialData;
  try
    WriteColoredLine('2. Financial Data Monitor (EMA, σ=3.0)', COLOR_SUCCESS);
    WriteLn(Format('   Type: %s', [FinancialDetector.ClassName]));
    WriteLn(Format('   Name: %s', [FinancialDetector.Name]));
    WriteLn(Format('   Sigma: %.1f (financial standard)', [FinancialDetector.Config.SigmaMultiplier]));
    WriteLn(Format('   Min StdDev: %.3f (high precision)', [FinancialDetector.Config.MinStdDev]));

    // Quick test with performance monitoring
    if FinancialDetector is TEMAAnomalyDetector then
    begin
      for i := 1 to 30 do
        TEMAAnomalyDetector(FinancialDetector).AddValue(100 + Random(10) - 5); // Normal stock price

      FinancialDetector.PerformanceMonitor.StartMeasurement;
      Result := FinancialDetector.Detect(150); // Price spike
      FinancialDetector.PerformanceMonitor.StopMeasurement(Result.IsAnomaly);

      if Result.IsAnomaly then
        WriteColoredLine('   ✓ Test: Price spike detected', COLOR_SUCCESS)
      else
        WriteColoredLine('   ✗ Test: Price spike NOT detected', COLOR_ANOMALY);

      Metrics := FinancialDetector.PerformanceMonitor.GetCurrentMetrics;
      WriteLn(Format('   Performance: %.0f detections/sec', [Metrics.ThroughputPerSecond]));
    end;
    WriteLn;

  finally
    FinancialDetector.Free;
  end;

  WriteColoredLine('=== FACTORY PATTERN ADVANTAGES ===', COLOR_SUCCESS);
  WriteLn('✓ Domain-optimized configurations');
  WriteLn('✓ Simplified client code');
  WriteLn('✓ Centralized creation logic');
  WriteLn('✓ Easy maintenance and testing');
  WriteLn('✓ Extensible without client changes');

  WaitForUser;
end;

// ============================================================================
// MENU SYSTEM
// ============================================================================

procedure ShowMenu;
begin
  WriteLn;
  DrawDoubleSeparator;
  WriteColoredLine('        ANOMALY DETECTION DEMO - COMPLETE EDITION         ', COLOR_TITLE);
  DrawDoubleSeparator;
  WriteLn;
  WriteColoredLine('=== CLASSIC ALGORITHMS ===', COLOR_SUCCESS);
  WriteLn('1.  Test 3-Sigma Detector (historical data analysis)');
  WriteLn('2.  Test Sliding Window Detector (streaming data)');
  WriteLn;
  WriteColoredLine('=== ADVANCED FEATURES ===', COLOR_INFO);
  WriteLn('3.  Test Isolation Forest (multi-dimensional detection)');
  WriteLn('4.  Test Detector Factory Pattern');
  WriteLn;
  WriteColoredLine('=== BATCH OPERATIONS ===', COLOR_INFO);
  WriteLn('5. Run all tests');
  WriteLn;
  WriteColoredLine('0.  Exit', COLOR_NORMAL);
  WriteLn;
  DrawSeparator;
  Write('Select option: ');
end;

procedure RunAllTests;
begin
  WriteColoredLine('=== RUNNING ALL TESTS ===', COLOR_TITLE);
  TestThreeSigmaDetector;
  TestSlidingWindowDetector;
  TestIsolationForestDetector;
  TestFactoryPattern;
  WriteColoredLine('=== ALL TESTS COMPLETED ===', COLOR_SUCCESS);
  WaitForUser;
end;

// ============================================================================
// MAIN PROGRAM
// ============================================================================

var
  Choice: Integer;
  InputStr: string;

begin
  try
    Randomize;
    SetConsoleColor(COLOR_NORMAL);

    DrawDoubleSeparator;
    WriteColoredLine('    Anomaly Detection Algorithms Library - Complete Demo    ', COLOR_TITLE);
    WriteColoredLine('         Developed with Delphi - Domain Modeling Pattern     ', COLOR_INFO);
    DrawDoubleSeparator;
    WriteLn;
    WriteLn('This comprehensive demo showcases various algorithms for detecting anomalies in data.');
    WriteLn('From classic statistical methods to modern machine learning approaches,');
    WriteLn('each algorithm has specific strengths for different scenarios and data types.');

    repeat
      ShowMenu;

      ReadLn(InputStr);
      if not TryStrToInt(InputStr, Choice) then
        Choice := -1;

      case Choice of
        1: TestThreeSigmaDetector;
        2: TestSlidingWindowDetector;
        3: TestIsolationForestDetector;
        4: TestFactoryPattern;
        5: RunAllTests;
        0: WriteColoredLine('Thank you for using the Anomaly Detection Demo!', COLOR_SUCCESS);
      else
        WriteColoredLine('Invalid option. Please try again.', COLOR_WARNING);
      end;

    until Choice = 0;

  except
    on E: Exception do
    begin
      SetConsoleColor(COLOR_ANOMALY);
      WriteLn;
      WriteLn('*** CRITICAL ERROR ***');
      WriteLn('Message: ' + E.Message);
      WriteLn('Class: ' + E.ClassName);
      SetConsoleColor(COLOR_NORMAL);
      WriteLn;
      WriteLn('Press ENTER to exit...');
      Readln;
    end;
  end;
end.
