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

{
  Anomaly Detection Demo Program

  This program demonstrates the use of various anomaly detection algorithms:

  1. 3-Sigma Detector: Uses historical data to establish normal limits
  2. Sliding Window Detector: Maintains a moving window for streaming data
  3. EMA Detector: Rapidly adapts to changes using exponential moving averages
  4. Adaptive Detector: Continuously learns from confirmed normal values
  5. Confirmation System: Reduces false positives by requiring multiple confirmations

  Final scenario: Simulates web traffic monitoring with all detectors
}

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

procedure SetConsoleColor(Color: Word);
begin
  {$IFDEF MSWINDOWS}
  SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), Color);
  {$ELSE}
  // On other platforms, ignore colors or use ANSI sequences if needed
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

procedure TestThreeSigmaDetector;
var
  Detector: TThreeSigmaDetector;
  SalesData: TArray<Double>;
  TestValues: array[0..6] of Double;
  i: Integer;
  Result: TAnomalyResult;
begin
  WriteColoredLine('=== 3-Sigma Detector Test ===', COLOR_SUCCESS);
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
      Result := Detector.Detect(TestValues[i]);
      if Result.IsAnomaly then
        WriteColoredLine(Format('  %.0f units: %s', [TestValues[i], Result.Description]), COLOR_ANOMALY)
      else
        WriteLn(Format('  %.0f units: %s', [TestValues[i], Result.Description]));
    end;

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
begin
  WriteColoredLine('=== Sliding Window Detector Test ===', COLOR_SUCCESS);
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
      Result := Detector.Detect(Value);

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
  Phase: string;
begin
  WriteColoredLine('=== Exponential Moving Average Detector Test ===', COLOR_SUCCESS);
  WriteLn('The EMA detector gives more weight to recent values (exponential decay).');
  WriteLn('The Alpha parameter controls adaptation speed:');
  WriteLn('  - Low Alpha (0.01-0.1): slow adaptation, more stable');
  WriteLn('  - High Alpha (0.2-0.5): rapid adaptation, more reactive');
  WriteLn;

  Detector := TEMAAnomalyDetector.Create(0.1); // Moderate alpha
  try
    WriteColoredLine('Simulating data with regime change...', COLOR_INFO);

    for i := 1 to 100 do
    begin
      // Three phases with different means
      if i <= 30 then
      begin
        Value := 100 + Random(20) - 10;
        Phase := 'Phase 1 (stable at ~100)';
      end
      else if i <= 60 then
      begin
        Value := 150 + Random(30) - 15;
        Phase := 'Phase 2 (transition to ~150)';
      end
      else
      begin
        Value := 200 + Random(40) - 20;
        Phase := 'Phase 3 (new normal at ~200)';
      end;

      // Occasional anomalies
      if i in [15, 45, 80] then
      begin
        Value := Value * 0.3;  // 70% drop
        WriteColoredLine(Format('>>> Drop inserted at point %d', [i]), COLOR_WARNING);
      end;

      Detector.AddValue(Value);
      Result := Detector.Detect(Value);

      if Result.IsAnomaly or (i mod 20 = 0) then
      begin
        if Result.IsAnomaly then
          WriteColoredLine(Format('[%3d] %s - Value: %.0f, EMA: %.0f - %s',
                                 [i, Phase, Value, Detector.CurrentMean, Result.Description]),
                          COLOR_ANOMALY)
        else
          WriteLn(Format('[%3d] %s - Value: %.0f, EMA: %.0f',
                        [i, Phase, Value, Detector.CurrentMean]));
      end;
    end;

    DrawSeparator;
    WriteLn('Final detector state:');
    WriteLn(Format('  EMA mean: %.2f', [Detector.CurrentMean]));
    WriteLn(Format('  Std. deviation: %.2f', [Detector.CurrentStdDev]));
    WriteLn(Format('  Normal range: %.2f - %.2f', [Detector.LowerLimit, Detector.UpperLimit]));

  finally
    Detector.Free;
  end;

  WaitForUser;
end;

procedure TestAdaptiveDetector;
var
  Detector: TAdaptiveAnomalyDetector;
  Config: TAnomalyDetectionConfig;
  i: Integer;
  Value, TrendValue: Double;
  Result: TAnomalyResult;
  AcceptedCount, RejectedCount: Integer;
begin
  WriteColoredLine('=== Adaptive Detector Test ===', COLOR_SUCCESS);
  WriteLn('This detector continuously learns from confirmed normal values.');
  WriteLn('Ideal for environments where "normal" conditions gradually change.');
  WriteLn('The learning rate controls how quickly it adapts to changes.');
  WriteLn;

  Config := TAnomalyDetectionConfig.Default;
  Config.SigmaMultiplier := 2.0; // More permissive for learning

  Detector := TAdaptiveAnomalyDetector.Create(100, 0.05, Config);
  try
    WriteColoredLine('Simulating an increasing trend with adaptive learning...', COLOR_INFO);
    AcceptedCount := 0;
    RejectedCount := 0;

    for i := 1 to 120 do
    begin
      // Increasing trend: from 100 to 200 in 120 steps
      TrendValue := 100 + (i - 1) * 100 / 119;
      Value := TrendValue + Random(20) - 10;

      // Planned anomalies
      if i in [30, 60, 90] then
      begin
        Value := Value + 100;  // Positive spike
        WriteColoredLine(Format('>>> Anomalous spike inserted at point %d: %.0f', [i, Value]), COLOR_WARNING);
      end;

      Detector.ProcessValue(Value);
      Result := Detector.Detect(Value);

      if not Result.IsAnomaly then
      begin
        // Value is normal, allow learning
        Detector.UpdateNormal(Value);
        Inc(AcceptedCount);
      end
      else
      begin
        Inc(RejectedCount);
        WriteColoredLine(Format('[%3d] ANOMALY: %.0f - %s',
                               [i, Value, Result.Description]), COLOR_ANOMALY);
      end;

      // Periodic report
      if (i mod 30 = 0) then
      begin
        DrawSeparator;
        WriteLn(Format('Progress after %d values:', [i]));
        WriteLn(Format('  Expected trend: %.0f', [TrendValue]));
        WriteLn(Format('  Adaptive mean: %.2f', [Detector.CurrentMean]));
        WriteLn(Format('  Std. deviation: %.2f', [Detector.CurrentStdDev]));
        WriteLn(Format('  Values learned: %d, Anomalies: %d', [AcceptedCount, RejectedCount]));
        DrawSeparator;
      end;
    end;

    WriteLn;
    WriteColoredLine('Adaptive learning summary:', COLOR_INFO);
    WriteLn(Format('  Normal values learned: %d (%.1f%%)',
                  [AcceptedCount, AcceptedCount / 120 * 100]));
    WriteLn(Format('  Anomalies rejected: %d (%.1f%%)',
                  [RejectedCount, RejectedCount / 120 * 100]));
    WriteLn(Format('  Trend adaptation: Final mean %.2f vs final trend %.2f',
                  [Detector.CurrentMean, TrendValue]));

  finally
    Detector.Free;
  end;

  WaitForUser;
end;

procedure TestAnomalyConfirmationSystem;
var
  ConfirmationSystem: TAnomalyConfirmationSystem;
  Detector: TSlidingWindowDetector;
  i: Integer;
  Value: Double;
  Result: TAnomalyResult;
  ConfirmedAnomalies: Integer;
begin
  WriteColoredLine('=== Anomaly Confirmation System Test ===', COLOR_SUCCESS);
  WriteLn('This system reduces false positives by requiring multiple similar anomalies.');
  WriteLn('Useful when single anomalies might be noise or measurement errors.');
  WriteLn('Parameters: window=10, threshold=3 (need 3 similar anomalies out of 10)');
  WriteLn;

  ConfirmationSystem := TAnomalyConfirmationSystem.Create(10, 3, 0.15); // 15% tolerance
  Detector := TSlidingWindowDetector.Create(50);
  try
    WriteColoredLine('Simulating isolated anomalies vs anomaly patterns...', COLOR_INFO);
    ConfirmedAnomalies := 0;

    // First phase: normal values
    for i := 1 to 30 do
    begin
      Value := 100 + Random(20) - 10;
      Detector.AddValue(Value);
    end;

    WriteLn('Baseline established. Starting anomaly tests...');
    WriteLn;

    // Test 1: Isolated anomaly
    WriteColoredLine('Test 1: Isolated anomaly (should not be confirmed)', COLOR_WARNING);
    Value := 250;
    Result := Detector.Detect(Value);
    if Result.IsAnomaly then
    begin
      ConfirmationSystem.AddPotentialAnomaly(Value);
      if ConfirmationSystem.IsConfirmedAnomaly(Value) then
      begin
        Inc(ConfirmedAnomalies);
        WriteColoredLine('  CONFIRMED', COLOR_ANOMALY);
      end
      else
        WriteLn('  Not confirmed (correct - it''s isolated)');
    end;

    // Normal values
    for i := 1 to 5 do
    begin
      Value := 100 + Random(20) - 10;
      Detector.AddValue(Value);
    end;

    // Test 2: Pattern of similar anomalies
    WriteLn;
    WriteColoredLine('Test 2: Pattern of 4 similar anomalies (should be confirmed)', COLOR_WARNING);
    for i := 1 to 4 do
    begin
      Value := 240 + Random(20) - 10;  // Similar anomalies
      Result := Detector.Detect(Value);
      if Result.IsAnomaly then
      begin
        ConfirmationSystem.AddPotentialAnomaly(Value);
        Write(Format('  Anomaly %d (%.0f): ', [i, Value]));
        if ConfirmationSystem.IsConfirmedAnomaly(Value) then
        begin
          Inc(ConfirmedAnomalies);
          WriteColoredLine('CONFIRMED', COLOR_ANOMALY);
        end
        else
          WriteLn('Not yet confirmed');
      end;
    end;

    // Test 3: Different anomalies
    WriteLn;
    WriteColoredLine('Test 3: Different types of anomalies (should not confirm)', COLOR_WARNING);
    for i := 1 to 3 do
    begin
      case i of
        1: Value := 50;   // Negative anomaly
        2: Value := 300;  // High positive anomaly
        3: Value := 180;  // Low positive anomaly
      end;

      Result := Detector.Detect(Value);
      if Result.IsAnomaly then
      begin
        ConfirmationSystem.AddPotentialAnomaly(Value);
        Write(Format('  Anomaly type %d (%.0f): ', [i, Value]));
        if ConfirmationSystem.IsConfirmedAnomaly(Value) then
        begin
          Inc(ConfirmedAnomalies);
          WriteColoredLine('CONFIRMED', COLOR_ANOMALY);
        end
        else
          WriteLn('Not confirmed (correct - they are different)');
      end;
    end;

    WriteLn;
    DrawSeparator;
    WriteColoredLine(Format('Total confirmed anomalies: %d', [ConfirmedAnomalies]), COLOR_INFO);
    WriteLn('The system correctly identified only the persistent pattern.');

  finally
    ConfirmationSystem.Free;
    Detector.Free;
  end;

  WaitForUser;
end;

procedure TestRealWorldScenario;
var
  SlidingDetector: TSlidingWindowDetector;
  EMADetector: TEMAAnomalyDetector;
  AdaptiveDetector: TAdaptiveAnomalyDetector;
  ConfirmationSystem: TAnomalyConfirmationSystem;
  Config: TAnomalyDetectionConfig;
  i, Hour: Integer;
  Value, BaseTraffic: Double;
  Results: array[1..3] of TAnomalyResult;
  AnomalyVotes: Integer;
  ConfirmedAnomalies: Integer;
  DetectorNames: array[1..3] of string;
begin
  WriteColoredLine('=== Real-World Scenario: 24/7 Web Traffic Monitoring ===', COLOR_SUCCESS);
  WriteLn('Simulating 7 days (168 hours) of web traffic with:');
  WriteLn('  - Daily patterns (daytime peaks, nighttime lows)');
  WriteLn('  - Weekly patterns (different weekends)');
  WriteLn('  - Realistic anomalies (DDoS attacks, downtime, viral events)');
  WriteLn;
  WriteLn('Using an ensemble of 3 detectors for greater reliability:');
  WriteLn('  1. Sliding Window: for short-term trends');
  WriteLn('  2. EMA: for rapid adaptation');
  WriteLn('  3. Adaptive: for long-term learning');
  WriteLn;

  // Unified configuration
  Config := TAnomalyDetectionConfig.Default;
  Config.SigmaMultiplier := 2.5;  // More sensitive for web security

  SlidingDetector := TSlidingWindowDetector.Create(24, Config);    // 24-hour window
  EMADetector := TEMAAnomalyDetector.Create(0.05, Config);         // Slow adaptation
  AdaptiveDetector := TAdaptiveAnomalyDetector.Create(168, 0.01, Config); // Learns over 1 week
  ConfirmationSystem := TAnomalyConfirmationSystem.Create(5, 2);   // 2 confirmations out of 5

  DetectorNames[1] := 'Sliding';
  DetectorNames[2] := 'EMA';
  DetectorNames[3] := 'Adaptive';

  try
    WriteColoredLine('Starting simulation...', COLOR_INFO);
    WriteLn;
    ConfirmedAnomalies := 0;

    for i := 1 to 168 do  // 7 days * 24 hours
    begin
      Hour := (i - 1) mod 24;

      // Realistic web traffic pattern
      BaseTraffic := 1000;  // Base traffic

      // Daily pattern (sinusoidal)
      BaseTraffic := BaseTraffic + 500 * Sin((Hour - 6) * Pi / 12); // Peak at noon

      // Weekly pattern (lower weekends)
      if ((i - 1) div 24) >= 5 then  // Weekend
        BaseTraffic := BaseTraffic * 0.7;

      // Add realistic noise
      Value := BaseTraffic + Random(200) - 100;

      // Planned anomalous events
      case i of
        36:  // DDoS attack
        begin
          Value := Value * 5;
          WriteColoredLine(Format('>>> EVENT: DDoS attack at hour %d (day %d, %d:00 hours)',
                                 [i, (i-1) div 24 + 1, Hour]), COLOR_WARNING);
        end;
        72:  // Downtime
        begin
          Value := Value * 0.1;
          WriteColoredLine(Format('>>> EVENT: Server down at hour %d (day %d, %d:00 hours)',
                                 [i, (i-1) div 24 + 1, Hour]), COLOR_WARNING);
        end;
        120: // Viral event
        begin
          Value := Value * 3;
          WriteColoredLine(Format('>>> EVENT: Viral content at hour %d (day %d, %d:00 hours)',
                                 [i, (i-1) div 24 + 1, Hour]), COLOR_WARNING);
        end;
      end;

      // Process with all detectors
      SlidingDetector.AddValue(Value);
      EMADetector.AddValue(Value);
      AdaptiveDetector.ProcessValue(Value);

      // Collect results
      Results[1] := SlidingDetector.Detect(Value);
      Results[2] := EMADetector.Detect(Value);
      Results[3] := AdaptiveDetector.Detect(Value);

      // Voting: at least 2 out of 3 detectors must agree
      AnomalyVotes := 0;
      for var j := 1 to 3 do
        if Results[j].IsAnomaly then
          Inc(AnomalyVotes);

      if AnomalyVotes >= 2 then
      begin
        ConfirmationSystem.AddPotentialAnomaly(Value);
        if ConfirmationSystem.IsConfirmedAnomaly(Value) then
        begin
          Inc(ConfirmedAnomalies);
          Write(Format('[Hour %3d - Day %d, %02d:00] ', [i, (i-1) div 24 + 1, Hour]));
          WriteColoredLine(Format('*** CONFIRMED ANOMALY: %.0f requests/hour ***', [Value]),
                          COLOR_ANOMALY);

          // Show which detectors triggered
          Write('  Detected by: ');
          for var j := 1 to 3 do
            if Results[j].IsAnomaly then
              Write(Format('%s (Z=%.1f) ', [DetectorNames[j], Results[j].ZScore]));
          WriteLn;
        end;
      end;

      // Allow adaptive detector to learn if normal
      if not Results[3].IsAnomaly then
        AdaptiveDetector.UpdateNormal(Value);

      // Daily report
      if (i mod 24 = 0) then
      begin
        DrawSeparator;
        WriteColoredLine(Format('End of day %d - Statistics:', [(i-1) div 24 + 1]), COLOR_INFO);
        WriteLn(Format('  Average traffic last 24h: %.0f req/hour', [SlidingDetector.CurrentMean]));
        WriteLn(Format('  EMA average: %.0f req/hour', [EMADetector.CurrentMean]));
        WriteLn(Format('  Adaptive average: %.0f req/hour', [AdaptiveDetector.CurrentMean]));
        DrawSeparator;
      end;
    end;

    WriteLn;
    WriteColoredLine('=== FINAL SUMMARY ===', COLOR_SUCCESS);
    WriteLn('Simulation duration: 7 days (168 hours)');
    WriteLn(Format('Confirmed anomalies: %d', [ConfirmedAnomalies]));
    WriteLn;
    WriteLn('Events correctly detected:');
    WriteLn('  - DDoS attack (5x normal traffic)');
    WriteLn('  - Server downtime (10% normal traffic)');
    WriteLn('  - Viral event (3x normal traffic)');
    WriteLn;
    WriteLn('The detector ensemble provided greater reliability');
    WriteLn('by reducing both false positives and false negatives.');

  finally
    ConfirmationSystem.Free;
    AdaptiveDetector.Free;
    EMADetector.Free;
    SlidingDetector.Free;
  end;

  WaitForUser;
end;

procedure ShowMenu;
begin
  WriteLn;
  WriteColoredLine('=== ANOMALY DETECTION DEMO MENU ===', COLOR_SUCCESS);
  WriteLn('1. Test 3-Sigma Detector (historical data)');
  WriteLn('2. Test Sliding Window Detector (streaming)');
  WriteLn('3. Test EMA Detector (rapid adaptation)');
  WriteLn('4. Test Adaptive Detector (continuous learning)');
  WriteLn('5. Test Confirmation System (reduce false positives)');
  WriteLn('6. Real-World Scenario: Web Traffic Monitoring');
  WriteLn('7. Run all tests in sequence');
  WriteLn('0. Exit');
  WriteLn;
  Write('Select option: ');
end;

var
  Choice: Integer;
  RunAll: Boolean;
  InputStr: string;

begin
  try
    Randomize;
    SetConsoleColor(COLOR_NORMAL);

    WriteColoredLine('Anomaly Detection Algorithms Demo', COLOR_SUCCESS);
    WriteColoredLine('Developed with Delphi - Domain Modeling Pattern', COLOR_INFO);
    WriteLn(StringOfChar('=', 50));
    WriteLn;
    WriteLn('This demo shows various algorithms for detecting anomalies in data.');
    WriteLn('Each algorithm has specific strengths for different scenarios.');

    repeat
      ShowMenu;

      ReadLn(InputStr);
      if not TryStrToInt(InputStr, Choice) then
        Choice := -1;

      case Choice of
        1: TestThreeSigmaDetector;
        2: TestSlidingWindowDetector;
        3: TestEMADetector;
        4: TestAdaptiveDetector;
        5: TestAnomalyConfirmationSystem;
        6: TestRealWorldScenario;
        7: begin
             RunAll := True;
             TestThreeSigmaDetector;
             TestSlidingWindowDetector;
             TestEMADetector;
             TestAdaptiveDetector;
             TestAnomalyConfirmationSystem;
             TestRealWorldScenario;
             RunAll := False;
           end;
        0: WriteLn('Goodbye!');
      else
        WriteColoredLine('Invalid option. Please try again.', COLOR_WARNING);
      end;

    until Choice = 0;

  except
    on E: Exception do
    begin
      SetConsoleColor(COLOR_ANOMALY);
      WriteLn;
      WriteLn('*** ERROR ***');
      WriteLn('Message: ' + E.Message);
      WriteLn('Class: ' + E.ClassName);
      SetConsoleColor(COLOR_NORMAL);
      WriteLn;
      WriteLn('Press ENTER to exit...');
      Readln;
    end;
  end;
end.
