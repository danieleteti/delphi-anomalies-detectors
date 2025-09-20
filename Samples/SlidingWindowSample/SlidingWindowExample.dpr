// ***************************************************************************
//
// Sliding Window Detector Example - Real-Time Web Traffic Monitoring
// Demonstrates adaptive anomaly detection for streaming data
//
// ***************************************************************************

program SlidingWindowExample;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Math,
  System.DateUtils,
  {$IFDEF MSWINDOWS}
  WinAPI.Windows,
  {$ENDIF }
  AnomalyDetectionAlgorithms;

type
  TTrafficEvent = record
    Hour, Minute: Integer;
    EventType: string;
    Description: string;
  end;

const
  // Console colors
  {$IFDEF MSWINDOWS}
  COLOR_NORMAL = 7;
  COLOR_ANOMALY = 12;  // Light red
  COLOR_WARNING = 14;  // Yellow
  COLOR_INFO = 11;     // Light cyan
  COLOR_SUCCESS = 10;  // Light green
  {$ENDIF}

procedure SetConsoleColor(Color: Word);
begin
  {$IFDEF MSWINDOWS}
  var Handle := GetStdHandle(STD_OUTPUT_HANDLE);
  SetConsoleTextAttribute(Handle, Color);
  {$ENDIF}
end;

procedure WriteColoredLine(const Text: string; Color: Word);
begin
  SetConsoleColor(Color);
  WriteLn(Text);
  SetConsoleColor(COLOR_NORMAL);
end;

function SimulateWebTrafficHour(Hour: Integer): Double;
var
  BaseTraffic, HourlyMultiplier, Noise: Double;
begin
  // Simulate realistic web traffic patterns
  BaseTraffic := 1000; // Base requests per minute

  // Traffic patterns throughout the day
  if (Hour >= 0) and (Hour <= 5) then
    HourlyMultiplier := 0.3   // Night time - low traffic
  else if (Hour >= 6) and (Hour <= 8) then
    HourlyMultiplier := 0.7   // Morning ramp-up
  else if (Hour >= 9) and (Hour <= 11) then
    HourlyMultiplier := 1.2   // Morning peak
  else if (Hour >= 12) and (Hour <= 13) then
    HourlyMultiplier := 1.5   // Lunch peak
  else if (Hour >= 14) and (Hour <= 17) then
    HourlyMultiplier := 1.3   // Afternoon steady
  else if (Hour >= 18) and (Hour <= 20) then
    HourlyMultiplier := 1.8   // Evening peak
  else if (Hour >= 21) and (Hour <= 23) then
    HourlyMultiplier := 1.0   // Evening decline
  else
    HourlyMultiplier := 1.0;

  // Add realistic noise (±15%)
  Noise := 1.0 + (Random - 0.5) * 0.3;

  Result := BaseTraffic * HourlyMultiplier * Noise;
end;

procedure SimulateTrafficEvent(var Traffic: Double; const EventType: string);
var
  LowerEvent: string;
begin
  LowerEvent := LowerCase(EventType);

  if LowerEvent = 'ddos' then
    Traffic := Traffic * 8.0      // DDoS attack - 8x traffic spike
  else if LowerEvent = 'viral' then
    Traffic := Traffic * 4.5      // Viral content - 4.5x increase
  else if LowerEvent = 'outage' then
    Traffic := Traffic * 0.1      // Service outage - 90% drop
  else if LowerEvent = 'bot' then
    Traffic := Traffic * 2.8      // Bot traffic - 2.8x increase
  else if LowerEvent = 'flash' then
    Traffic := Traffic * 6.2;     // Flash sale - 6.2x increase
end;

procedure RunWebTrafficMonitoring;
var
  Detector: TSlidingWindowDetector;
  Hour, Minute: Integer;
  Traffic: Double;
  Result: TAnomalyResult;
  TotalAnomalies, Events: Integer;
  EventsDetected: Integer;
  CurrentTime: TDateTime;
  EventSchedule: array[0..4] of TTrafficEvent;
  i: Integer;
begin
  WriteColoredLine('=== REAL-TIME WEB TRAFFIC MONITORING ===', COLOR_INFO);
  WriteLn('Using Sliding Window (4-hour window) for adaptive detection');
  WriteLn;

  // Create detector with 4-hour sliding window (240 minutes) - faster adaptation
  Detector := TSlidingWindowDetector.Create(240);
  try
    TotalAnomalies := 0;
    Events := 0;
    EventsDetected := 0;

    // Schedule some events for demonstration
    EventSchedule[0].Hour := 2; EventSchedule[0].Minute := 30;
    EventSchedule[0].EventType := 'ddos'; EventSchedule[0].Description := 'DDoS Attack Simulation';

    EventSchedule[1].Hour := 9; EventSchedule[1].Minute := 15;
    EventSchedule[1].EventType := 'viral'; EventSchedule[1].Description := 'Viral Content Spike';

    EventSchedule[2].Hour := 14; EventSchedule[2].Minute := 45;
    EventSchedule[2].EventType := 'outage'; EventSchedule[2].Description := 'Service Outage';

    EventSchedule[3].Hour := 18; EventSchedule[3].Minute := 20;
    EventSchedule[3].EventType := 'bot'; EventSchedule[3].Description := 'Bot Traffic Detection';

    EventSchedule[4].Hour := 21; EventSchedule[4].Minute := 0;
    EventSchedule[4].EventType := 'flash'; EventSchedule[4].Description := 'Flash Sale Event';

    WriteColoredLine('Step 1: Initializing with baseline traffic (first 2 hours)...', COLOR_INFO);

    // Initialize detector with 2 hours of baseline data
    for Hour := 0 to 1 do
    begin
      for Minute := 0 to 59 do
      begin
        Traffic := SimulateWebTrafficHour(Hour);
        Detector.AddValue(Traffic);
      end;
    end;

    WriteColoredLine('✓ Baseline established', COLOR_SUCCESS);
    WriteLn(Format('  Normal traffic range: %.0f - %.0f requests/min',
                  [Detector.LowerLimit, Detector.UpperLimit]));
    WriteLn;

    WriteColoredLine('Step 2: Monitoring traffic stream (simulating 24 hours)...', COLOR_INFO);
    WriteLn;

    // Simulate 24 hours of traffic monitoring
    for Hour := 2 to 23 do
    begin
      for Minute := 0 to 59 do
      begin
        Traffic := SimulateWebTrafficHour(Hour);
        CurrentTime := EncodeTime(Hour, Minute, 0, 0);

        // Check for scheduled events
        var EventTriggered := False;
        for i := 0 to High(EventSchedule) do
        begin
          if (EventSchedule[i].Hour = Hour) and (EventSchedule[i].Minute = Minute) then
          begin
            WriteColoredLine(Format('[%02d:%02d] 🎯 %s',
              [Hour, Minute, EventSchedule[i].Description]), COLOR_WARNING);
            SimulateTrafficEvent(Traffic, EventSchedule[i].EventType);
            Inc(Events);
            EventTriggered := True;
          end;
        end;

        // Add to sliding window and detect
        Detector.AddValue(Traffic);
        Result := Detector.Detect(Traffic);

        if Result.IsAnomaly then
        begin
          Inc(TotalAnomalies);

          // Track if this anomaly corresponds to a scheduled event
          if EventTriggered then
            Inc(EventsDetected);

          WriteColoredLine(Format('[%02d:%02d] 🚨 ANOMALY: %.0f req/min (Z-score: %.2f)',
            [Hour, Minute, Traffic, Result.ZScore]), COLOR_ANOMALY);

          // Provide intelligent analysis
          if Traffic > Detector.CurrentMean * 2 then
            WriteLn('   → Possible: DDoS attack, viral content, or bot traffic')
          else if Traffic < Detector.CurrentMean * 0.5 then
            WriteLn('   → Possible: Service outage or network issues')
          else
            WriteLn('   → Unusual traffic pattern detected');
        end
        else if (Minute mod 30) = 0 then // Show normal status every 30 minutes
        begin
          WriteLn(Format('[%02d:%02d] ✓ Normal: %.0f req/min (avg: %.0f)',
            [Hour, Minute, Traffic, Detector.CurrentMean]));
        end;
      end;

      // Show adaptation every 4 hours
      if (Hour mod 4) = 0 then
      begin
        WriteLn;
        WriteColoredLine(Format('--- Hour %02d Update ---', [Hour]), COLOR_INFO);
        WriteLn(Format('Current normal range: %.0f - %.0f req/min',
          [Detector.LowerLimit, Detector.UpperLimit]));
        WriteLn(Format('Window adaptation: Mean=%.0f, StdDev=%.0f',
          [Detector.CurrentMean, Detector.CurrentStdDev]));
        WriteLn;
      end;
    end;

    WriteLn;
    WriteColoredLine('=== 24-HOUR MONITORING SUMMARY ===', COLOR_SUCCESS);
    WriteLn(Format('• Total anomalies detected: %d', [TotalAnomalies]));
    WriteLn(Format('• Scheduled events simulated: %d', [Events]));
    WriteLn(Format('• Scheduled events detected: %d', [EventsDetected]));
    if Events > 0 then
      WriteLn(Format('• Event detection rate: %.1f%% (%d/%d)',
        [(EventsDetected / Events) * 100, EventsDetected, Events]))
    else
      WriteLn('• Event detection rate: N/A (no events)');
    WriteLn(Format('• Final traffic range: %.0f - %.0f req/min',
      [Max(0.0, Detector.LowerLimit), Detector.UpperLimit]));

    WriteLn;
    WriteColoredLine('=== SLIDING WINDOW ADVANTAGES ===', COLOR_INFO);
    WriteLn('✓ Adapts to daily traffic patterns automatically');
    WriteLn('✓ Maintains recent context (24-hour window)');
    WriteLn('✓ Excellent for trending and cyclical data');
    WriteLn('✓ Real-time detection with minimal latency');
    WriteLn('✓ No need for historical training data');

  finally
    Detector.Free;
  end;
end;

procedure DemonstrateSlidingAdaptation;
var
  Detector: TSlidingWindowDetector;
  i: Integer;
  Value: Double;
begin
  WriteColoredLine('=== SLIDING WINDOW ADAPTATION DEMO ===', COLOR_INFO);
  WriteLn('Showing how the detector adapts to changing baselines');
  WriteLn;

  Detector := TSlidingWindowDetector.Create(10); // Small window for demo
  try
    // Phase 1: Low traffic period
    WriteColoredLine('Phase 1: Low traffic baseline (100-200 req/min)', COLOR_INFO);
    for i := 1 to 15 do
    begin
      Value := 150 + Random(50) - 25; // 125-175 range
      Detector.AddValue(Value);
      if (i mod 5) = 0 then
        WriteLn(Format('  After %2d values: Mean=%.0f, Range=[%.0f-%.0f]',
          [i, Detector.CurrentMean, Detector.LowerLimit, Detector.UpperLimit]));
    end;

    WriteLn;

    // Phase 2: Gradual increase
    WriteColoredLine('Phase 2: Traffic gradually increasing to high levels', COLOR_INFO);
    for i := 1 to 15 do
    begin
      Value := 300 + Random(100) - 50; // 250-350 range
      Detector.AddValue(Value);
      if (i mod 5) = 0 then
        WriteLn(Format('  After %2d values: Mean=%.0f, Range=[%.0f-%.0f]',
          [i, Detector.CurrentMean, Detector.LowerLimit, Detector.UpperLimit]));
    end;

    WriteLn;
    WriteColoredLine('Notice how the detection range adapted automatically!', COLOR_SUCCESS);
    WriteLn('• Old "normal" (150) would now be detected as anomaly');
    WriteLn('• New "normal" (300) is now within expected range');

  finally
    Detector.Free;
  end;
end;

// Main program
begin
  try
    Randomize;

    WriteLn('Sliding Window Anomaly Detection - Practical Example');
    WriteLn('Scenario: Real-time web server traffic monitoring');
    WriteLn(StringOfChar('=', 65));
    WriteLn;

    RunWebTrafficMonitoring;

    WriteLn;
    WriteLn(StringOfChar('-', 65));
    WriteLn;

    DemonstrateSlidingAdaptation;

    WriteLn;
    WriteColoredLine('Demo completed successfully!', COLOR_SUCCESS);
    WriteLn('Press ENTER to exit...');
    ReadLn;

  except
    on E: Exception do
    begin
      WriteColoredLine('ERROR: ' + E.Message, COLOR_ANOMALY);
      WriteLn('Press ENTER to exit...');
      ReadLn;
      ExitCode := 1;
    end;
  end;
end.
