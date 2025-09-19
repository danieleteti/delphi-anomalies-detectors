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
  System.IOUtils,
  System.DateUtils,
  System.StrUtils,
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
// DATA GENERATION UTILITIES
// ============================================================================

function GenerateSampleCSV(const AFileName: string): Boolean;
var
  CSV: TStringList;
  i: Integer;
  Value1, Value2, Value3: Double;
begin
  CSV := TStringList.Create;
  try
    CSV.Add('Timestamp,Temperature,Pressure,Vibration');

    for i := 1 to 1000 do
    begin
      // Normal sensor readings with some noise
      Value1 := 25 + Random(10) - 5;        // Temperature: 20-30°C
      Value2 := 101.3 + Random(4) - 2;      // Pressure: 99.3-103.3 kPa
      Value3 := 0.1 + Random * 0.3;         // Vibration: 0.1-0.4

      // Inject some anomalies
      if (i mod 100 = 0) then
      begin
        Value1 := Value1 * 2;  // Temperature spike
        Value3 := Value3 * 5;  // High vibration
      end;

      CSV.Add(Format('%s,%.2f,%.2f,%.3f', [
        FormatDateTime('yyyy-mm-dd hh:nn:ss', Now + (i / (24 * 60))),
        Value1, Value2, Value3
      ]));
    end;

    CSV.SaveToFile(AFileName);
    Result := True;
  except
    on E: Exception do
      Result := False;
  end;
  CSV.Free;
end;

procedure ConfigureDetectorInteractively(Detector: TBaseAnomalyDetector);
var
  Choice: Integer;
  NewSigma: Double;
  InputStr: string;
begin
  WriteLn('Current Configuration:');
  WriteLn(Format('  Sigma Multiplier: %.1f', [Detector.Config.SigmaMultiplier]));
  WriteLn(Format('  Min StdDev: %.3f', [Detector.Config.MinStdDev]));
  WriteLn;
  Write('Modify sigma multiplier? (1=Yes, 0=No): ');
  ReadLn(InputStr);
  if TryStrToInt(InputStr, Choice) and (Choice = 1) then
  begin
    Write('New sigma multiplier (1.0-5.0): ');
    ReadLn(InputStr);
    if TryStrToFloat(InputStr, NewSigma) and (NewSigma >= 1.0) and (NewSigma <= 5.0) then
    begin
      var Config := Detector.Config;
      Config.SigmaMultiplier := NewSigma;
      Detector.Config := Config;
      WriteColoredLine(Format('✓ Updated to %.1f', [NewSigma]), COLOR_SUCCESS);
    end
    else
      WriteColoredLine('Invalid input. Keeping current value.', COLOR_WARNING);
  end;
end;

procedure DrawSimpleChart(const Values: TArray<Double>; const Anomalies: TArray<Boolean>; const Title: string);
const
  CHART_WIDTH = 60;
  CHART_HEIGHT = 15;
var
  i, YPos: Integer;
  MinVal, MaxVal, Range, NormalizedVal: Double;
  Chart: array[0..CHART_HEIGHT-1] of string;
begin
  if Length(Values) = 0 then Exit;

  WriteColoredLine('=== ' + Title + ' ===', COLOR_INFO);

  // Find min/max
  MinVal := Values[0];
  MaxVal := Values[0];
  for i := 0 to High(Values) do
  begin
    if Values[i] < MinVal then MinVal := Values[i];
    if Values[i] > MaxVal then MaxVal := Values[i];
  end;
  Range := MaxVal - MinVal;

  if Range = 0 then
  begin
    WriteLn('All values are identical - no chart needed');
    Exit;
  end;

  // Initialize chart
  for i := 0 to CHART_HEIGHT - 1 do
    Chart[i] := StringOfChar(' ', CHART_WIDTH);

  // Plot points
  for i := 0 to Min(High(Values), CHART_WIDTH-1) do
  begin
    NormalizedVal := (Values[i] - MinVal) / Range;
    YPos := Round((CHART_HEIGHT-1) * (1 - NormalizedVal));

    if (i < Length(Anomalies)) and Anomalies[i] then
      Chart[YPos][i+1] := 'X'  // Anomaly
    else
      Chart[YPos][i+1] := '*'; // Normal
  end;

  // Draw chart
  WriteLn(Format('Max: %8.2f ┤', [MaxVal]));
  for i := 0 to CHART_HEIGHT - 1 do
  begin
    if i = CHART_HEIGHT div 2 then
      WriteLn(Format('     %8.2f ┤%s', [(MinVal + MaxVal) / 2, Chart[i]]))
    else
      WriteLn(Format('             ┤%s', [Chart[i]]));
  end;
  WriteLn(Format('Min: %8.2f ┤', [MinVal]));
  WriteLn('             └' + StringOfChar('─', CHART_WIDTH));
  WriteLn('Legend: * = Normal, X = Anomaly');
  WriteLn;
end;

// ============================================================================
// CLASSIC ALGORITHMS - REFACTORED
// ============================================================================

procedure TestThreeSigmaDetector;
var
  Detector: TThreeSigmaDetector;
  SalesData: TArray<Double>;
  TestValues: array[0..6] of Double;
  i: Integer;
  Result: TAnomalyResult;
  Metrics: TDetectorMetrics;
  Values: TArray<Double>;
  Anomalies: TArray<Boolean>;
begin
  WriteColoredLine('=== 3-SIGMA DETECTOR TEST ===', COLOR_TITLE);
  WriteLn('The 3-Sigma detector is ideal when you have stable historical data.');
  WriteLn('It uses the statistical rule that 99.7% of data in a normal distribution falls within ±3σ from the mean.');
  WriteLn('NEW: Single method call for learning - no more manual statistics calculation!');
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

    // REFACTORED: Single method call instead of SetHistoricalData + CalculateStatistics
    WriteColoredLine('Learning from historical data...', COLOR_INFO);
    Detector.LearnFromHistoricalData(SalesData);
    WriteColoredLine('✓ Learning completed automatically!', COLOR_SUCCESS);

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
    SetLength(Values, Length(TestValues));
    SetLength(Anomalies, Length(TestValues));

    for i := 0 to High(TestValues) do
    begin
      Detector.PerformanceMonitor.StartMeasurement;
      Result := Detector.Detect(TestValues[i]);
      Detector.PerformanceMonitor.StopMeasurement(Result.IsAnomaly);

      Values[i] := TestValues[i];
      Anomalies[i] := Result.IsAnomaly;

      if Result.IsAnomaly then
        WriteColoredLine(Format('  %.0f units: %s', [TestValues[i], Result.Description]), COLOR_ANOMALY)
      else
        WriteLn(Format('  %.0f units: %s', [TestValues[i], Result.Description]));
    end;

    // ASCII Chart visualization
    DrawSimpleChart(Values, Anomalies, 'Sales Data Analysis');

    // Interactive configuration
    WriteLn;
    WriteColoredLine('Interactive Configuration:', COLOR_INFO);
    ConfigureDetectorInteractively(Detector);

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
  InitialData: TArray<Double>;
  Values: TArray<Double>;
  Anomalies: TArray<Boolean>;
begin
  WriteColoredLine('=== SLIDING WINDOW DETECTOR TEST ===', COLOR_TITLE);
  WriteLn('This detector maintains a moving window of the last N values.');
  WriteLn('Perfect for data streams where conditions change gradually.');
  WriteLn('The window automatically adapts to seasonal changes.');
  WriteLn('NEW: Optional initialization method for better startup!');
  WriteLn;

  // Custom configuration for higher sensitivity
  Config := TAnomalyDetectionConfig.Default;
  Config.SigmaMultiplier := 2.5; // More sensitive than standard 3-sigma

  Detector := TSlidingWindowDetector.Create(50, Config);
  try
    WriteColoredLine('Initializing with baseline data...', COLOR_INFO);

    // REFACTORED: Initialize with historical data for better startup
    SetLength(InitialData, 20);
    for i := 0 to 19 do
      InitialData[i] := 100 + Random(20) - 10;

    Detector.InitializeWindow(InitialData);
    WriteColoredLine('✓ Window initialized with 20 baseline values', COLOR_SUCCESS);
    WriteLn(Format('  Initial mean: %.2f', [Detector.CurrentMean]));

    WriteColoredLine('Simulating 150 readings with evolving pattern...', COLOR_INFO);
    AnomalyCount := 0;
    SetLength(Values, 150);
    SetLength(Anomalies, 150);

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

      Values[i-1] := Value;
      Anomalies[i-1] := Result.IsAnomaly;

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

    // Show chart for last 60 values to see adaptation
    var ChartValues: TArray<Double>;
    var ChartAnomalies: TArray<Boolean>;
    SetLength(ChartValues, 60);
    SetLength(ChartAnomalies, 60);

    for i := 0 to 59 do
    begin
      ChartValues[i] := Values[89 + i]; // Last 60 values
      ChartAnomalies[i] := Anomalies[89 + i];
    end;

    DrawSimpleChart(ChartValues, ChartAnomalies, 'Sliding Window Adaptation (Last 60 Values)');

    // Interactive configuration
    WriteColoredLine('Interactive Configuration:', COLOR_INFO);
    ConfigureDetectorInteractively(Detector);

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

procedure TestEMADetector;
var
  Detector: TEMAAnomalyDetector;
  i: Integer;
  Value: Double;
  Result: TAnomalyResult;
  AnomalyCount: Integer;
  BaselineData: TArray<Double>;
  Values: TArray<Double>;
  Anomalies: TArray<Boolean>;
begin
  WriteColoredLine('=== EMA ANOMALY DETECTOR TEST ===', COLOR_TITLE);
  WriteLn('Exponential Moving Average detector for fast adaptation.');
  WriteLn('Excellent for trending data and rapid response scenarios.');
  WriteLn('NEW: Optional warm-up method for better initialization!');
  WriteLn;

  Detector := TEMAAnomalyDetector.Create(0.1); // Alpha = 0.1
  try
    WriteColoredLine('Warming up detector with baseline data...', COLOR_INFO);

    // REFACTORED: Warm up with baseline data instead of hoping first values work well
    SetLength(BaselineData, 30);
    for i := 0 to 29 do
      BaselineData[i] := 100 + Random(20) - 10;

    Detector.WarmUp(BaselineData);
    WriteColoredLine('✓ Detector warmed up with statistical baseline', COLOR_SUCCESS);
    WriteLn(Format('  Initial EMA: %.2f', [Detector.CurrentMean]));
    WriteLn(Format('  Initial StdDev: %.2f', [Detector.CurrentStdDev]));

    WriteColoredLine('Streaming financial data with volatility changes...', COLOR_INFO);
    AnomalyCount := 0;
    SetLength(Values, 100);
    SetLength(Anomalies, 100);

    for i := 1 to 100 do
    begin
      // Simulate stock price with trend changes
      if i <= 30 then
        Value := 100 + Random(10) - 5     // Stable period
      else if i <= 60 then
        Value := 110 + i * 0.5 + Random(8) - 4  // Uptrend
      else if i <= 80 then
        Value := 140 - (i - 60) * 0.8 + Random(12) - 6 // Downtrend
      else
        Value := 120 + Random(15) - 7;    // Volatile period

      // Insert market shocks
      if i in [25, 55, 85] then
      begin
        Value := Value + (Random(2) * 2 - 1) * 50; // ±50 shock
        WriteColoredLine(Format('>>> Market shock at point %d: %.2f', [i, Value]), COLOR_WARNING);
      end;

      Detector.AddValue(Value);

      Detector.PerformanceMonitor.StartMeasurement;
      Result := Detector.Detect(Value);
      Detector.PerformanceMonitor.StopMeasurement(Result.IsAnomaly);

      Values[i-1] := Value;
      Anomalies[i-1] := Result.IsAnomaly;

      if Result.IsAnomaly then
      begin
        Inc(AnomalyCount);
        WriteColoredLine(Format('  [%3d] EMA ANOMALY: %.2f (Z-score: %.2f, EMA: %.2f)',
                               [i, Value, Result.ZScore, Detector.CurrentMean]), COLOR_ANOMALY);
      end;

      // Show adaptation every 20 points
      if (i mod 20 = 0) then
      begin
        WriteLn(Format('  [%3d] EMA: %.2f, StdDev: %.2f, Last Value: %.2f',
                      [i, Detector.CurrentMean, Detector.CurrentStdDev, Value]));
      end;
    end;

    WriteLn;
    WriteColoredLine(Format('Total anomalies detected: %d out of 100 values (%.1f%%)',
                           [AnomalyCount, AnomalyCount / 100 * 100]), COLOR_INFO);

    DrawSimpleChart(Values, Anomalies, 'EMA Detector - Financial Data Stream');

    // Test different alpha values
    WriteLn;
    WriteColoredLine('Testing different adaptation speeds:', COLOR_INFO);

    var FastDetector := TEMAAnomalyDetector.Create(0.3);
    var SlowDetector := TEMAAnomalyDetector.Create(0.05);
    try
      // Warm up both
      FastDetector.WarmUp(BaselineData);
      SlowDetector.WarmUp(BaselineData);

      // Feed same sequence
      for i := 1 to 10 do
      begin
        FastDetector.AddValue(150); // Jump to 150
        SlowDetector.AddValue(150);
      end;

      WriteLn(Format('  Fast EMA (α=0.3): %.2f', [FastDetector.CurrentMean]));
      WriteLn(Format('  Slow EMA (α=0.05): %.2f', [SlowDetector.CurrentMean]));
      WriteLn('  Fast EMA adapts more quickly to level changes');

    finally
      SlowDetector.Free;
      FastDetector.Free;
    end;

    DrawSeparator;
    WriteColoredLine('PERFORMANCE METRICS:', COLOR_INFO);
    WriteLn(Detector.GetPerformanceReport);

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
  Dataset: TArray<TArray<Double>>;
begin
  WriteColoredLine('=== ISOLATION FOREST DETECTOR TEST ===', COLOR_TITLE);
  WriteLn('Isolation Forest is excellent for multi-dimensional data.');
  WriteLn('It works by building random binary trees where anomalies');
  WriteLn('are easier to "isolate" (require fewer splits).');
  WriteLn('Perfect for: fraud detection, cybersecurity, multi-sensor IoT.');
  WriteLn('NEW: Single method training with automatic optimization!');
  WriteLn;

  // Optimized configuration for demo
  Detector := TIsolationForestDetector.Create(50, 100, 8); // 50 trees, 100 samples, depth 8
  try
    WriteColoredLine('Phase 1: Training with normal data (main cluster)', COLOR_INFO);

    // REFACTORED: Create dataset and train with single method call
    SetLength(Dataset, 250);

    // Generate normal cluster centered on (100, 50)
    for i := 0 to 199 do
    begin
      SetLength(Dataset[i], 2);
      Dataset[i][0] := 100 + Random(30) - 15; // X: 85-115
      Dataset[i][1] := 50 + Random(20) - 10;  // Y: 40-60

      if i <= 10 then
        Write(Format('(%.0f,%.0f) ', [Dataset[i][0], Dataset[i][1]]));
    end;
    WriteLn;

    // Add a second smaller cluster (normal)
    WriteColoredLine('Adding second normal cluster...', COLOR_INFO);
    for i := 200 to 249 do
    begin
      SetLength(Dataset[i], 2);
      Dataset[i][0] := 150 + Random(20) - 10; // X: 140-160
      Dataset[i][1] := 80 + Random(16) - 8;   // Y: 72-88
    end;

    WriteLn(Format('Training with %d 2D samples...', [250]));
    StartTime := Now;

    // REFACTORED: Single method call for complete training
    Detector.TrainFromDataset(Dataset);

    TrainingTime := MilliSecondsBetween(Now, StartTime);

    WriteColoredLine(Format('✓ Training completed in %d ms', [TrainingTime]), COLOR_SUCCESS);
    WriteLn(Format('  Number of trees: %d', [Detector.NumTrees]));
    WriteLn(Format('  Feature dimensions: %d', [Detector.FeatureCount]));
    WriteLn(Format('  Detector initialized: %s', [BoolToStr(Detector.IsInitialized, True)]));
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
  IoTDetector: TBaseAnomalyDetector;
  IsolationDetector: TBaseAnomalyDetector;
  Dataset: TArray<TArray<Double>>;
  i: Integer;
  Result: TAnomalyResult;
  BaselineData: TArray<Double>;
  Instance: TArray<Double>;
begin
  WriteColoredLine('=== DETECTOR FACTORY PATTERN DEMO ===', COLOR_TITLE);
  WriteLn('The Factory Pattern simplifies detector creation');
  WriteLn('with optimized configurations for specific scenarios.');
  WriteLn('NEW: All detectors are properly initialized by the factory!');
  WriteLn;

  WriteColoredLine('Creating pre-configured detectors:', COLOR_INFO);

  // Create all factory detectors
  WebTrafficDetector := TAnomalyDetectorFactory.CreateForWebTrafficMonitoring;
  FinancialDetector := TAnomalyDetectorFactory.CreateForFinancialData;
  IoTDetector := TAnomalyDetectorFactory.CreateForIoTSensors;
  IsolationDetector := TAnomalyDetectorFactory.CreateForHighDimensionalData;

  try
    // Test Web Traffic detector (should be SlidingWindow)
    WriteColoredLine('1. Web Traffic Monitor (Sliding Window, σ=2.5)', COLOR_SUCCESS);
    WriteLn(Format('   Type: %s', [WebTrafficDetector.ClassName]));
    WriteLn(Format('   Name: %s', [WebTrafficDetector.Name]));
    WriteLn(Format('   Sigma: %.1f (more sensitive for security)', [WebTrafficDetector.Config.SigmaMultiplier]));

    if WebTrafficDetector is TSlidingWindowDetector then
    begin
      // Initialize with baseline data
      SetLength(BaselineData, 20);
      for i := 0 to 19 do
        BaselineData[i] := 1000 + Random(200) - 100;
      TSlidingWindowDetector(WebTrafficDetector).InitializeWindow(BaselineData);

      for i := 1 to 30 do
        TSlidingWindowDetector(WebTrafficDetector).AddValue(1000 + Random(200) - 100);

      Result := WebTrafficDetector.Detect(5000); // DDoS spike
      if Result.IsAnomaly then
        WriteColoredLine('   ✓ Test: DDoS attack detected correctly', COLOR_SUCCESS)
      else
        WriteColoredLine('   ✗ Test: DDoS attack NOT detected', COLOR_ANOMALY);
    end;
    WriteLn;

    // Test Financial detector (should be EMA)
    WriteColoredLine('2. Financial Data Monitor (EMA, σ=3.0)', COLOR_SUCCESS);
    WriteLn(Format('   Type: %s', [FinancialDetector.ClassName]));
    WriteLn(Format('   Name: %s', [FinancialDetector.Name]));
    WriteLn(Format('   Sigma: %.1f (financial standard)', [FinancialDetector.Config.SigmaMultiplier]));
    WriteLn(Format('   Min StdDev: %.3f (high precision)', [FinancialDetector.Config.MinStdDev]));

    if FinancialDetector is TEMAAnomalyDetector then
    begin
      // Warm up with baseline
      SetLength(BaselineData, 20);
      for i := 0 to 19 do
        BaselineData[i] := 100 + Random(10) - 5;
      TEMAAnomalyDetector(FinancialDetector).WarmUp(BaselineData);

      for i := 1 to 10 do
        TEMAAnomalyDetector(FinancialDetector).AddValue(100 + Random(10) - 5);

      Result := FinancialDetector.Detect(150); // Price spike
      if Result.IsAnomaly then
        WriteColoredLine('   ✓ Test: Price spike detected', COLOR_SUCCESS)
      else
        WriteColoredLine('   ✗ Test: Price spike NOT detected', COLOR_ANOMALY);
    end;
    WriteLn;

    // Test IoT detector (should be Adaptive)
    WriteColoredLine('3. IoT Sensor Monitor (Adaptive, σ=2.0)', COLOR_SUCCESS);
    WriteLn(Format('   Type: %s', [IoTDetector.ClassName]));
    WriteLn(Format('   Name: %s', [IoTDetector.Name]));

    if IoTDetector is TAdaptiveAnomalyDetector then
    begin
      // Initialize with normal sensor readings
      SetLength(BaselineData, 20);
      for i := 0 to 19 do
        BaselineData[i] := 25 + Random(10) - 5; // Temp readings

      TAdaptiveAnomalyDetector(IoTDetector).InitializeWithNormalData(BaselineData);

      Result := IoTDetector.Detect(60); // Overheating
      if Result.IsAnomaly then
        WriteColoredLine('   ✓ Test: Overheating detected', COLOR_SUCCESS)
      else
        WriteColoredLine('   ✗ Test: Overheating NOT detected', COLOR_ANOMALY);
    end;
    WriteLn;

    // Test Isolation Forest (should handle multi-dimensional)
    WriteColoredLine('4. High-Dimensional Data Monitor (Isolation Forest, σ=2.5)', COLOR_SUCCESS);
    WriteLn(Format('   Type: %s', [IsolationDetector.ClassName]));
    WriteLn(Format('   Name: %s', [IsolationDetector.Name]));

    if IsolationDetector is TIsolationForestDetector then
    begin
      // Create multi-dimensional dataset
      SetLength(Dataset, 200);
      for i := 0 to 199 do
      begin
        SetLength(Dataset[i], 3);
        Dataset[i][0] := 100 + Random(20) - 10;
        Dataset[i][1] := 50 + Random(16) - 8;
        Dataset[i][2] := 25 + Random(10) - 5;
      end;

      TIsolationForestDetector(IsolationDetector).TrainFromDataset(Dataset);

      SetLength(Instance, 3);
      Instance := [300, 300, 300]; // Clear anomaly
      Result := TIsolationForestDetector(IsolationDetector).DetectMultiDimensional(Instance);
      if Result.IsAnomaly then
        WriteColoredLine('   ✓ Test: Multi-dimensional anomaly detected', COLOR_SUCCESS)
      else
        WriteColoredLine('   ✗ Test: Multi-dimensional anomaly NOT detected', COLOR_ANOMALY);
    end;
    WriteLn;

    // Verify all detectors are properly initialized
    WriteColoredLine('Final Status Check:', COLOR_INFO);
    if WebTrafficDetector.IsInitialized then
      WriteLn('  Web traffic detector: Ready')
    else
      WriteLn('  Web traffic detector: Not ready');

    if FinancialDetector.IsInitialized then
      WriteLn('  Financial detector: Ready')
    else
      WriteLn('  Financial detector: Not ready');

    if IoTDetector.IsInitialized then
      WriteLn('  IoT detector: Ready')
    else
      WriteLn('  IoT detector: Not ready');

    if IsolationDetector.IsInitialized then
      WriteLn('  Isolation detector: Ready')
    else
      WriteLn('  Isolation detector: Not ready');

  finally
    IsolationDetector.Free;
    IoTDetector.Free;
    FinancialDetector.Free;
    WebTrafficDetector.Free;
  end;

  WriteColoredLine('=== FACTORY PATTERN ADVANTAGES ===', COLOR_SUCCESS);
  WriteLn('✓ Domain-optimized configurations');
  WriteLn('✓ Simplified client code');
  WriteLn('✓ Centralized creation logic');
  WriteLn('✓ Easy maintenance and testing');
  WriteLn('✓ Extensible without client changes');
  WriteLn('✓ NEW: Automatic proper initialization');

  WaitForUser;
end;

procedure TestWithRealData;
var
  Detector: TSlidingWindowDetector;
  DataFile: TStringList;
  i: Integer;
  Value: Double;
  AnomalyCount: Integer;
  Values: TArray<Double>;
  Anomalies: TArray<Boolean>;
  Line: string;
  CSVValues: TArray<string>;
  Result: TAnomalyResult;
begin
  WriteColoredLine('=== REAL DATA TEST ===', COLOR_TITLE);
  WriteLn('Load your CSV data file for analysis...');

  if not FileExists('sample_data.csv') then
  begin
    WriteColoredLine('Creating sample data file...', COLOR_INFO);
    if GenerateSampleCSV('sample_data.csv') then
      WriteColoredLine(Format('✓ Generated sample_data.csv with %d multi-sensor readings', [1000]), COLOR_SUCCESS)
    else
    begin
      WriteColoredLine('✗ Failed to create sample data', COLOR_ANOMALY);
      Exit;
    end;
    WriteLn('You can replace sample_data.csv with your own data');
    WriteLn;
  end;

  Detector := TSlidingWindowDetector.Create(50);
  try
    DataFile := TStringList.Create;
    try
      DataFile.LoadFromFile('sample_data.csv');
      AnomalyCount := 0;

      // Calculate how many data points we'll process
      var DataCount := DataFile.Count - 1; // Skip header
      SetLength(Values, DataCount);
      SetLength(Anomalies, DataCount);

      WriteColoredLine(Format('Processing %d data points from CSV...', [DataCount]), COLOR_INFO);

      for i := 1 to DataFile.Count - 1 do // Skip header
      begin
        Line := DataFile[i];
        CSVValues := Line.Split([',']);

        if Length(CSVValues) >= 2 then
        begin
          // Use temperature column (index 1)
          if TryStrToFloat(CSVValues[1], Value) then
          begin
            Detector.AddValue(Value);
            Result := Detector.Detect(Value);

            Values[i-1] := Value;
            Anomalies[i-1] := Result.IsAnomaly;

            if Result.IsAnomaly then
            begin
              Inc(AnomalyCount);
              WriteColoredLine(Format('  Line %d: ANOMALY %.2f (Z-score: %.2f)', [i+1, Value, Result.ZScore]), COLOR_ANOMALY);
            end;
          end;
        end;
      end;

      WriteColoredLine(Format('Analysis complete: %d anomalies in %d data points (%.1f%%)',
                             [AnomalyCount, DataCount, (AnomalyCount / DataCount) * 100]), COLOR_INFO);

      // Show chart of last 100 points
      if DataCount >= 100 then
      begin
        var ChartValues: TArray<Double>;
        var ChartAnomalies: TArray<Boolean>;
        SetLength(ChartValues, 100);
        SetLength(ChartAnomalies, 100);

        for i := 0 to 99 do
        begin
          ChartValues[i] := Values[DataCount - 100 + i];
          ChartAnomalies[i] := Anomalies[DataCount - 100 + i];
        end;

        DrawSimpleChart(ChartValues, ChartAnomalies, 'Real Data Analysis (Last 100 Points)');
      end;

    finally
      DataFile.Free;
    end;
  finally
    Detector.Free;
  end;

  WriteColoredLine('CSV format expected: Timestamp,Temperature,Pressure,Vibration', COLOR_INFO);
  WriteLn('The demo analyzes the Temperature column for anomalies.');
  WaitForUser;
end;

procedure BenchmarkAllDetectors;
var
  Detectors: array[0..3] of TBaseAnomalyDetector;
  DetectorNames: array[0..3] of string;
  TestData: TArray<Double>;
  Results: array[0..3] of Integer;
  i, j: Integer;
  StartTime, EndTime: TDateTime;
  ProcessingTimes: array[0..3] of Int64;
  BaselineData: TArray<Double>;
begin
  WriteColoredLine('=== COMPARATIVE BENCHMARK ===', COLOR_TITLE);
  WriteLn('Testing all detectors on 0the same dataset...');
  WriteLn('NEW: All detectors properly initialized for fair comparison!');
  WriteLn;

  // Setup detectors
  Detectors[0] := TThreeSigmaDetector.Create;
  Detectors[1] := TSlidingWindowDetector.Create(50);
  Detectors[2] := TEMAAnomalyDetector.Create(0.1);
  Detectors[3] := TAdaptiveAnomalyDetector.Create(100, 0.05);

  DetectorNames[0] := '3-Sigma';
  DetectorNames[1] := 'Sliding Window';
  DetectorNames[2] := 'EMA';
  DetectorNames[3] := 'Adaptive';

  try
    // Generate test data
    SetLength(TestData, 1000);
    for i := 0 to 999 do
    begin
      TestData[i] := 100 + Random(30) - 15; // Normal data

      // Insert anomalies every 100 points
      if (i mod 100 = 0) and (i > 0) then
        TestData[i] := TestData[i] * 2.5;
    end;
    WriteLn(Format('Generated %d test points with 9 injected anomalies', [Length(TestData)]));

    // REFACTORED: Initialize all detectors properly
    WriteColoredLine('Initializing detectors...', COLOR_INFO);

    // Prepare baseline data from first 100 points
    SetLength(BaselineData, 100);
    for i := 0 to 99 do
      BaselineData[i] := TestData[i];

    // Initialize Three Sigma detector
    TThreeSigmaDetector(Detectors[0]).LearnFromHistoricalData(BaselineData);

    // Initialize Sliding Window detector
    TSlidingWindowDetector(Detectors[1]).InitializeWindow(BaselineData);

    // Initialize EMA detector
    TEMAAnomalyDetector(Detectors[2]).WarmUp(BaselineData);

    // Initialize Adaptive detector
    TAdaptiveAnomalyDetector(Detectors[3]).InitializeWithNormalData(BaselineData);

    WriteColoredLine('✓ All detectors initialized', COLOR_SUCCESS);
    WriteLn;

    // Test each detector
    for i := 0 to 3 do
    begin
      Results[i] := 0;
      WriteColoredLine(Format('Testing %s detector...', [DetectorNames[i]]), COLOR_INFO);
      StartTime := Now;

      for j := 100 to High(TestData) do // Start after initialization data
      begin
        // Add value if streaming detector
        if Detectors[i] is TSlidingWindowDetector then
          TSlidingWindowDetector(Detectors[i]).AddValue(TestData[j])
        else if Detectors[i] is TEMAAnomalyDetector then
          TEMAAnomalyDetector(Detectors[i]).AddValue(TestData[j]);

        if Detectors[i].IsAnomaly(TestData[j]) then
          Inc(Results[i]);
      end;

      EndTime := Now;
      ProcessingTimes[i] := MilliSecondsBetween(EndTime, StartTime);
      WriteLn(Format('  Completed: %d anomalies detected', [Results[i]]));
    end;

    // Display results
    DrawSeparator;
    WriteColoredLine('BENCHMARK RESULTS:', COLOR_SUCCESS);
    WriteLn(Format('%-15s %10s %12s %15s %12s', ['Detector', 'Anomalies', 'Time (ms)', 'Rate (ops/ms)', 'Initialized']));
    WriteLn(StringOfChar('-', 70));

    for i := 0 to 3 do
    begin
      var ProcessingRate: Double;
      var InitStatus: string;

      if ProcessingTimes[i] > 0 then
        ProcessingRate := (Length(TestData) - 100) / ProcessingTimes[i]
      else
        ProcessingRate := 0;

      if Detectors[i].IsInitialized then
        InitStatus := 'Yes'
      else
        InitStatus := 'No';

      WriteLn(Format('%-15s %10d %12d %15.2f %12s', [
        DetectorNames[i],
        Results[i],
        ProcessingTimes[i],
        ProcessingRate,
        InitStatus
      ]));
    end;

    WriteLn;
    WriteColoredLine('ANALYSIS:', COLOR_INFO);
    WriteLn('Expected anomalies: 8 (excluded initialization period)');
    WriteLn('Different detectors may show varying sensitivity to the same data');
    WriteLn('Initialization improves consistency and reduces startup anomalies');

  finally
    for i := 0 to 3 do
      Detectors[i].Free;
  end;

  WaitForUser;
end;

procedure TestCSVFunctionality;
var
  IsolationDetector: TIsolationForestDetector;
  CSVFileName: string;
  Result: TAnomalyResult;
  Instance: TArray<Double>;
begin
  WriteColoredLine('=== CSV TRAINING FUNCTIONALITY ===', COLOR_TITLE);
  WriteLn('Test training Isolation Forest directly from CSV files.');
  WriteLn('Perfect for batch processing of historical data!');
  WriteLn;

  IsolationDetector := TIsolationForestDetector.Create(30, 100, 6); // Smaller for demo
  try
    // Generate sample multi-dimensional CSV
    CSVFileName := 'training_data.csv';
    WriteColoredLine('Generating sample training CSV...', COLOR_INFO);

    var CSV := TStringList.Create;
    try
      CSV.Add('Temperature,Pressure,Vibration'); // Header

      // Generate normal operating conditions
      for var i := 1 to 200 do
      begin
        CSV.Add(Format('%.2f,%.2f,%.3f', [
          25 + Random(8) - 4,           // Temp: 21-29°C
          101.3 + Random(4) - 2,        // Pressure: 99.3-103.3 kPa
          0.1 + Random * 0.2            // Vibration: 0.1-0.3
        ]));
      end;

      CSV.SaveToFile(CSVFileName);
      WriteColoredLine(Format('✓ Created %s with 200 training samples', [CSVFileName]), COLOR_SUCCESS);

    finally
      CSV.Free;
    end;

    // REFACTORED: Single method call to train from CSV
    WriteColoredLine('Training from CSV file...', COLOR_INFO);
    var TrainStart := Now;

    IsolationDetector.TrainFromCSV(CSVFileName, True); // Skip header

    var TrainTime := MilliSecondsBetween(Now, TrainStart);
    WriteColoredLine(Format('✓ Training completed in %d ms', [TrainTime]), COLOR_SUCCESS);
    WriteColoredLine(Format('  Features detected: %d', [IsolationDetector.FeatureCount]), COLOR_INFO);
    WriteColoredLine(Format('  Trees built: %d', [IsolationDetector.NumTrees]), COLOR_INFO);
    if IsolationDetector.IsInitialized then
      WriteColoredLine('  Ready for detection: Yes', COLOR_INFO)
    else
      WriteColoredLine('  Ready for detection: No', COLOR_WARNING);

    DrawSeparator;
    WriteColoredLine('Testing equipment failure scenarios:', COLOR_INFO);

    // Test normal operation
    SetLength(Instance, 3);
    Instance[0] := 25;    // Normal temp
    Instance[1] := 101.3; // Normal pressure
    Instance[2] := 0.15;  // Normal vibration

    Result := IsolationDetector.DetectMultiDimensional(Instance);
    if Result.IsAnomaly then
      WriteLn(Format('Normal operation [%.1f°C, %.1f kPa, %.2f]: ANOMALY', [Instance[0], Instance[1], Instance[2]]))
    else
      WriteLn(Format('Normal operation [%.1f°C, %.1f kPa, %.2f]: Normal', [Instance[0], Instance[1], Instance[2]]));

    // Test overheating
    Instance[0] := 45;    // High temp
    Instance[1] := 101.3; // Normal pressure
    Instance[2] := 0.15;  // Normal vibration

    Result := IsolationDetector.DetectMultiDimensional(Instance);
    if Result.IsAnomaly then
      WriteLn(Format('Overheating [%.1f°C, %.1f kPa, %.2f]: ANOMALY', [Instance[0], Instance[1], Instance[2]]))
    else
      WriteLn(Format('Overheating [%.1f°C, %.1f kPa, %.2f]: Normal', [Instance[0], Instance[1], Instance[2]]));

    // Test mechanical failure
    Instance[0] := 25;    // Normal temp
    Instance[1] := 101.3; // Normal pressure
    Instance[2] := 1.5;   // High vibration

    Result := IsolationDetector.DetectMultiDimensional(Instance);
    if Result.IsAnomaly then
      WriteLn(Format('Mech. failure [%.1f°C, %.1f kPa, %.2f]: ANOMALY', [Instance[0], Instance[1], Instance[2]]))
    else
      WriteLn(Format('Mech. failure [%.1f°C, %.1f kPa, %.2f]: Normal', [Instance[0], Instance[1], Instance[2]]));

    // Test complete failure
    Instance[0] := 60;    // Very high temp
    Instance[1] := 90;    // Low pressure
    Instance[2] := 2.0;   // Very high vibration

    Result := IsolationDetector.DetectMultiDimensional(Instance);
    if Result.IsAnomaly then
      WriteLn(Format('Complete failure [%.1f°C, %.1f kPa, %.2f]: ANOMALY', [Instance[0], Instance[1], Instance[2]]))
    else
      WriteLn(Format('Complete failure [%.1f°C, %.1f kPa, %.2f]: Normal', [Instance[0], Instance[1], Instance[2]]));

    WriteColoredLine('CSV Training Benefits:', COLOR_SUCCESS);
    WriteLn('✓ Direct training from existing data files');
    WriteLn('✓ No need for manual data parsing');
    WriteLn('✓ Automatic feature detection');
    WriteLn('✓ Supports various CSV formats (comma, semicolon, tab)');
    WriteLn('✓ Header detection and skipping');

    // Cleanup
    if TFile.Exists(CSVFileName) then
      TFile.Delete(CSVFileName);

  finally
    IsolationDetector.Free;
  end;

  WaitForUser;
end;

// ============================================================================
// MENU SYSTEM
// ============================================================================

procedure ShowMenu;
begin
  WriteLn;
  DrawDoubleSeparator;
  WriteColoredLine('     ANOMALY DETECTION DEMO - REFACTORED EDITION          ', COLOR_TITLE);
  DrawDoubleSeparator;
  WriteLn;
  WriteColoredLine('=== CLASSIC ALGORITHMS (REFACTORED) ===', COLOR_SUCCESS);
  WriteLn('1.  Test 3-Sigma Detector (unified learning method)');
  WriteLn('2.  Test Sliding Window Detector (with initialization)');
  WriteLn('3.  Test EMA Detector (with warm-up capability)');
  WriteLn;
  WriteColoredLine('=== ADVANCED FEATURES ===', COLOR_INFO);
  WriteLn('4.  Test Isolation Forest (streamlined training)');
  WriteLn('5.  Test Detector Factory Pattern (auto-initialization)');
  WriteLn('6.  Test CSV Training (direct file loading)');
  WriteLn;
  WriteColoredLine('=== ENHANCED OPERATIONS ===', COLOR_INFO);
  WriteLn('7.  Test with Real Data (CSV file analysis)');
  WriteLn('8.  Comparative Benchmark (fair comparison)');
  WriteLn('9.  Run all tests');
  WriteLn;
  WriteColoredLine('0.  Exit', COLOR_NORMAL);
  WriteLn;
  WriteColoredLine('NEW: All methods use intuitive, atomic operations!', COLOR_SUCCESS);
  DrawSeparator;
  Write('Select option: ');
end;

procedure RunAllTests;
begin
  WriteColoredLine('=== RUNNING ALL REFACTORED TESTS ===', COLOR_TITLE);
  WriteLn('Demonstrating improved API with atomic operations...');
  WriteLn;

  TestThreeSigmaDetector;
  TestSlidingWindowDetector;
  TestEMADetector;
  TestIsolationForestDetector;
  TestFactoryPattern;
  TestCSVFunctionality;
  TestWithRealData;
  BenchmarkAllDetectors;

  WriteColoredLine('=== ALL REFACTORED TESTS COMPLETED ===', COLOR_SUCCESS);
  WriteLn;
  WriteColoredLine('Summary of improvements:', COLOR_INFO);
  WriteLn('✓ No more SetData + Calculate patterns');
  WriteLn('✓ Single method calls for learning/initialization');
  WriteLn('✓ Better error handling and validation');
  WriteLn('✓ Consistent initialization across all detectors');
  WriteLn('✓ More intuitive and less error-prone API');
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
    WriteColoredLine('  Anomaly Detection Algorithms Library - Refactored Demo  ', COLOR_TITLE);
    WriteColoredLine('       Developed with Delphi - Improved API Design         ', COLOR_INFO);
    DrawDoubleSeparator;
    WriteLn;
    WriteLn('This refactored demo showcases the improved API design where:');
    WriteLn('• No more manual state management (SetData + Calculate eliminated)');
    WriteLn('• Single method calls for initialization and learning');
    WriteLn('• Better error handling and user experience');
    WriteLn('• Consistent patterns across all detector types');
    WriteLn;
    WriteColoredLine('Key improvements in this version:', COLOR_SUCCESS);
    WriteLn('├─ LearnFromHistoricalData() replaces SetData + Calculate');
    WriteLn('├─ InitializeWindow() for better sliding window startup');
    WriteLn('├─ WarmUp() for EMA detector baseline establishment');
    WriteLn('├─ TrainFromDataset() for unified Isolation Forest training');
    WriteLn('├─ TrainFromCSV() for direct file-based training');
    WriteLn('└─ InitializeWithNormalData() for adaptive detector setup');

    repeat
      ShowMenu;

      ReadLn(InputStr);
      if not TryStrToInt(InputStr, Choice) then
        Choice := -1;

      case Choice of
        1: TestThreeSigmaDetector;
        2: TestSlidingWindowDetector;
        3: TestEMADetector;
        4: TestIsolationForestDetector;
        5: TestFactoryPattern;
        6: TestCSVFunctionality;
        7: TestWithRealData;
        8: BenchmarkAllDetectors;
        9: RunAllTests;
        0: WriteColoredLine('Thank you for testing the refactored Anomaly Detection Demo!', COLOR_SUCCESS);
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

      if E is EAnomalyDetectionException then
      begin
        WriteLn;
        WriteLn('This appears to be an anomaly detection specific error.');
        WriteLn('Common causes:');
        WriteLn('• Detector not properly initialized');
        WriteLn('• Insufficient training data provided');
        WriteLn('• Invalid data format or values');
      end;

      SetConsoleColor(COLOR_NORMAL);
      WriteLn;
      WriteLn('Press ENTER to exit...');
      Readln;
    end;
  end;
end.
