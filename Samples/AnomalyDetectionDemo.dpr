program AnomalyDetectionDemo;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  System.DateUtils,
  AnomalyDetectionAlgorithms in '..\AnomalyDetectionAlgorithms.pas'; // Assicurati che il path sia corretto

procedure WaitForUser;
begin
  WriteLn('Press ENTER to continue...');
  Readln;
end;

procedure TestThreeSigmaDetector;
var
  Detector: TThreeSigmaDetector;
  SalesData: TArray<Double>;
  TestValues: array[0..4] of Double;
  i: Integer;
begin
  WriteLn('=== 3-Sigma Detector Test ===');
  WriteLn('This detector uses historical data to establish normal ranges.');
  WriteLn('');

  Detector := TThreeSigmaDetector.Create;
  try
    // Historical sales data (30 days)
    SetLength(SalesData, 30);
    for i := 0 to 29 do
      SalesData[i] := 100 + Random(100) + (Sin(i * 0.5) * 10); // Some pattern

    Detector.SetHistoricalData(SalesData);
    Detector.CalculateStatistics;

    WriteLn(Format('Statistics calculated from %d data points:', [Length(SalesData)]));
    WriteLn(Format('  Mean: %.2f', [Detector.Mean]));
    WriteLn(Format('  Std Dev: %.2f', [Detector.StdDev]));
    WriteLn(Format('  Normal Range (3σ): %.2f - %.2f', [Detector.LowerLimit, Detector.UpperLimit]));
    WriteLn('');

    // Test values
    TestValues[0] := 150;    // Normal
    TestValues[1] := 250;    // Normal
    TestValues[2] := 400;    // Anomaly
    TestValues[3] := 50;     // Anomaly
    TestValues[4] := 175;    // Normal

    WriteLn('Testing various values:');
    for i := 0 to High(TestValues) do
    begin
      WriteLn(Format('  Value %6.2f: %s', [TestValues[i], Detector.GetAnomalyInfo(TestValues[i])]));
    end;

  finally
    Detector.Free;
  end;

  WriteLn('');
  WaitForUser;
end;

procedure TestSlidingWindowDetector;
var
  Detector: TSlidingWindowDetector;
  i: Integer;
  Value: Double;
begin
  WriteLn('=== Sliding Window Detector Test ===');
  WriteLn('This detector maintains a moving window of recent values.');
  WriteLn('It''s perfect for streaming data where conditions change over time.');
  WriteLn('');

  Detector := TSlidingWindowDetector.Create(50); // 50-value window
  try
    WriteLn('Adding 100 normal values (mean around 100)...');

    // Add normal values
    for i := 1 to 100 do
    begin
      Value := 100 + (Random(40) - 20); // 80-120 range
      Detector.AddValue(Value);

      if (i mod 20 = 0) or (i = 100) then
      begin
        WriteLn(Format('  After %3d values - Mean: %6.2f, StdDev: %6.2f, Range: %6.2f - %6.2f',
                      [i, Detector.CurrentMean, Detector.CurrentStdDev, Detector.LowerLimit, Detector.UpperLimit]));
      end;
    end;

    WriteLn('');
    WriteLn('Testing anomalies:');
    WriteLn(Format('  Normal value 105: %s', [Detector.GetAnomalyInfo(105)]));
    WriteLn(Format('  Anomaly value 250: %s', [Detector.GetAnomalyInfo(250)]));
    WriteLn(Format('  Anomaly value  10: %s', [Detector.GetAnomalyInfo(10)]));

  finally
    Detector.Free;
  end;

  WriteLn('');
  WaitForUser;
end;

// Helper function to convert boolean to string
function BooleanToString(AValue: Boolean; const ATrue: string = 'YES'; const AFalse: string = 'NO'): string;
begin
  if AValue then
    Result := ATrue
  else
    Result := AFalse;
end;

procedure TestEMADetector;
var
  Detector: TEMAAnomalyDetector;
  i: Integer;
  Value: Double;
begin
  WriteLn('=== Exponential Moving Average Detector Test ===');
  WriteLn('This detector gives more weight to recent values and adapts quickly.');
  WriteLn('Alpha parameter controls adaptation speed (lower = slower adaptation).');
  WriteLn('');

  Detector := TEMAAnomalyDetector.Create(0.1); // Moderate adaptation
  try
    WriteLn('Processing streaming data with changing patterns...');

    // Simulate data with changing mean
    for i := 1 to 50 do
    begin
      if i < 20 then
        Value := 100 + (Random(20) - 10) // Mean around 100
      else if i < 40 then
        Value := 150 + (Random(20) - 10) // Mean around 150
      else
        Value := 200 + (Random(20) - 10); // Mean around 200

      Detector.AddValue(Value);

      if (i mod 10 = 0) or (i = 50) then
      begin
        WriteLn(Format('  Step %2d - Value: %6.2f, EMA: %6.2f, StdDev: %6.2f, Range: %6.2f - %6.2f',
                      [i, Value, Detector.CurrentMean, Detector.CurrentStdDev, Detector.LowerLimit, Detector.UpperLimit]));
      end;
    end;

    WriteLn('');
    WriteLn('Testing current state:');
    WriteLn(Format('  Normal value 195: %s', [Detector.GetAnomalyInfo(195)]));
    WriteLn(Format('  Anomaly value  50: %s', [Detector.GetAnomalyInfo(50)]));
    WriteLn(Format('  Anomaly value 300: %s', [Detector.GetAnomalyInfo(300)]));

  finally
    Detector.Free;
  end;

  WriteLn('');
  WaitForUser;
end;

procedure TestAdaptiveDetector;
var
  Detector: TAdaptiveAnomalyDetector;
  i: Integer;
  Value: Double;
begin
  WriteLn('=== Adaptive Detector Test ===');
  WriteLn('This detector learns from confirmed normal values and adapts over time.');
  WriteLn('It''s ideal for environments where normal conditions gradually change.');
  WriteLn('');

  Detector := TAdaptiveAnomalyDetector.Create(100, 0.05); // 100-value window, 5% adaptation rate
  try
    WriteLn('Simulating gradual change in data patterns...');

    // Simulate gradual change
    for i := 1 to 80 do
    begin
      // Gradually increasing mean
      var BaseValue := 100 + (i * 0.5);
      Value := BaseValue + (Random(20) - 10);

      Detector.ProcessValue(Value);

      // Confirm normal values to help adaptation
      if not Detector.IsAnomaly(Value) then
        Detector.UpdateNormal(Value);

      if (i mod 20 = 0) or (i = 80) then
      begin
        WriteLn(Format('  Step %2d - Value: %6.2f, Mean: %6.2f, StdDev: %6.2f',
                      [i, Value, Detector.CurrentMean, Detector.CurrentStdDev]));
      end;
    end;

    WriteLn('');
    WriteLn('Testing current state:');
    WriteLn(Format('  Normal value 135: %s', [Detector.GetAnomalyInfo(135)]));
    WriteLn(Format('  Normal value 145: %s', [Detector.GetAnomalyInfo(145)]));
    WriteLn(Format('  Anomaly value  50: %s', [Detector.GetAnomalyInfo(50)]));
    WriteLn(Format('  Anomaly value 250: %s', [Detector.GetAnomalyInfo(250)]));

  finally
    Detector.Free;
  end;

  WriteLn('');
  WaitForUser;
end;

procedure TestAnomalyConfirmationSystem;
var
  ConfirmationSystem: TAnomalyConfirmationSystem;
  i: Integer;
  Value: Double;
begin
  WriteLn('=== Anomaly Confirmation System Test ===');
  WriteLn('This system reduces false positives by requiring multiple similar anomalies.');
  WriteLn('It''s useful when single anomalies might be false positives.');
  WriteLn('');

  ConfirmationSystem := TAnomalyConfirmationSystem.Create(10, 3); // 10-window, 3 confirmations needed
  try
    WriteLn('Simulating anomaly detection with confirmation...');

    // Add some normal values first
    for i := 1 to 5 do
    begin
      Value := 100 + (Random(20) - 10);
      WriteLn(Format('  Normal value: %6.2f', [Value]));
    end;

    WriteLn('');
    WriteLn('Adding potential anomalies:');

    // Add similar anomalies to trigger confirmation
    for i := 1 to 5 do
    begin
      Value := 300 + (Random(20) - 10); // Similar high anomalies
      ConfirmationSystem.AddPotentialAnomaly(Value);

      var IsConfirmed := ConfirmationSystem.IsConfirmedAnomaly(Value);
      WriteLn(Format('  Potential anomaly %6.2f - Confirmed: %s', [Value,
                     BooleanToString(IsConfirmed, 'YES', 'NO')]));
    end;

    WriteLn('');
    WriteLn('Testing with different anomaly:');
    Value := 500; // Different anomaly
    ConfirmationSystem.AddPotentialAnomaly(Value);
    WriteLn(Format('  Different anomaly %6.2f - Confirmed: %s', [Value,
                   BooleanToString(ConfirmationSystem.IsConfirmedAnomaly(Value), 'YES', 'NO')]));

  finally
    ConfirmationSystem.Free;
  end;

  WriteLn('');
  WaitForUser;
end;

procedure TestRealWorldScenario;
var
  SlidingDetector: TSlidingWindowDetector;
  EMADetector: TEMAAnomalyDetector;
  AdaptiveDetector: TAdaptiveAnomalyDetector;
  ConfirmationSystem: TAnomalyConfirmationSystem;
  i: Integer;
  Value: Double;
  AnomalyCount: Integer;
begin
  WriteLn('=== Real-World Scenario: Web Traffic Monitoring ===');
  WriteLn('Monitoring website traffic with multiple detection methods...');
  WriteLn('');

  SlidingDetector := TSlidingWindowDetector.Create(100);
  EMADetector := TEMAAnomalyDetector.Create(0.05);
  AdaptiveDetector := TAdaptiveAnomalyDetector.Create(200, 0.02);
  ConfirmationSystem := TAnomalyConfirmationSystem.Create(15, 3);

  try
    AnomalyCount := 0;
    WriteLn('Simulating 200 hours of web traffic data...');

    for i := 1 to 200 do
    begin
      // Normal traffic pattern with daily/weekly cycles
      var BaseTraffic := 1000 + Sin(i * 0.1) * 200 + Sin(i * 0.02) * 300;

      // Add some randomness
      Value := BaseTraffic + (Random(300) - 150);

      // Occasional spike (anomaly)
      if (i = 50) or (i = 100) or (i = 150) then
        Value := Value * 3;

      // Process with all detectors
      SlidingDetector.AddValue(Value);
      EMADetector.AddValue(Value);
      AdaptiveDetector.ProcessValue(Value);

      // Check for anomalies
      var SlidingAnomaly := SlidingDetector.IsAnomaly(Value);
      var EMAAnomaly := EMADetector.IsAnomaly(Value);
      var AdaptiveAnomaly := AdaptiveDetector.IsAnomaly(Value);

      // If multiple detectors agree, it's likely a real anomaly
      if Ord(SlidingAnomaly) + Ord(EMAAnomaly) + Ord(AdaptiveAnomaly) >= 2 then
      begin
        ConfirmationSystem.AddPotentialAnomaly(Value);
        if ConfirmationSystem.IsConfirmedAnomaly(Value) then
        begin
          Inc(AnomalyCount);
          WriteLn(Format('  *** CONFIRMED ANOMALY at hour %3d: %6.0f requests ***', [i, Value]));
        end;
      end;

      // Show status every 50 hours
      if (i mod 50 = 0) or (i = 200) then
      begin
        WriteLn(Format('  Hour %3d - Traffic: %6.0f, Sliding Mean: %6.0f, EMA: %6.0f, Adaptive: %6.0f',
                      [i, Value, SlidingDetector.CurrentMean, EMADetector.CurrentMean,
                       AdaptiveDetector.CurrentMean]));
      end;
    end;

    WriteLn('');
    WriteLn(Format('Total confirmed anomalies detected: %d', [AnomalyCount]));
    WriteLn('These could indicate: traffic spikes, system issues, or security events.');

  finally
    ConfirmationSystem.Free;
    AdaptiveDetector.Free;
    EMADetector.Free;
    SlidingDetector.Free;
  end;

  WriteLn('');
  WaitForUser;
end;

begin
  try
    Randomize;
    WriteLn('Anomaly Detection Algorithms Demo');
    WriteLn('=================================');
    WriteLn('');

    TestThreeSigmaDetector;
    TestSlidingWindowDetector;
    TestEMADetector;
    TestAdaptiveDetector;
    TestAnomalyConfirmationSystem;
    TestRealWorldScenario;

    WriteLn('Demo completed successfully.');
    WriteLn('Press ENTER to exit...');
    Readln;

  except
    on E: Exception do
    begin
      WriteLn('*** ERROR ***');
      WriteLn('Error: ' + E.Message);
      // Includi la classe dell'eccezione per ulteriore dettaglio
      WriteLn('Exception Class: ' + E.ClassName);
      WriteLn('');
      WriteLn('Press ENTER to exit...');
      Readln;
    end;
  end;
end.
