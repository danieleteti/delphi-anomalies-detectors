// ***************************************************************************
//
// DBSCAN Detector Example - Network Intrusion Detection
// Demonstrates density-based clustering for multi-dimensional anomaly detection
//
// ***************************************************************************

program DBSCANExample;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Math,
  System.DateUtils,
  {$IFDEF MSWINDOWS}
  WinAPI.Windows,
  {$ENDIF}
  AnomalyDetection.Factory,
  AnomalyDetection.Types,
  AnomalyDetection.DBSCAN;

type
  TNetworkEvent = record
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

procedure SetConsoleColor(AColor: Word);
begin
  {$IFDEF MSWINDOWS}
  var lHandle := GetStdHandle(STD_OUTPUT_HANDLE);
  SetConsoleTextAttribute(lHandle, AColor);
  {$ENDIF}
end;

procedure WriteColoredLine(const AText: string; AColor: Word);
begin
  SetConsoleColor(AColor);
  WriteLn(AText);
  SetConsoleColor(COLOR_NORMAL);
end;

// Simulate normal network traffic (3D: packets/sec, bytes/packet, connections)
procedure SimulateNormalTraffic(AHour: Integer; out APacketsPerSec, ABytesPerPacket, AConnections: Double);
var
  lHourlyMultiplier, lNoise: Double;
begin
  // Traffic patterns throughout the day
  if (AHour >= 0) and (AHour <= 5) then
    lHourlyMultiplier := 0.2   // Night - very low
  else if (AHour >= 6) and (AHour <= 8) then
    lHourlyMultiplier := 0.6   // Morning ramp-up
  else if (AHour >= 9) and (AHour <= 17) then
    lHourlyMultiplier := 1.0   // Business hours
  else if (AHour >= 18) and (AHour <= 22) then
    lHourlyMultiplier := 0.7   // Evening
  else
    lHourlyMultiplier := 0.3;  // Late night

  // Add realistic noise (±20%)
  lNoise := 1.0 + (Random - 0.5) * 0.4;

  APacketsPerSec := 1000 * lHourlyMultiplier * lNoise;
  ABytesPerPacket := 512 + Random(256) - 128;  // 384-640 bytes
  AConnections := 50 * lHourlyMultiplier * lNoise;
end;

// Simulate attack scenarios
procedure SimulateAttack(const AEventType: string; out APacketsPerSec, ABytesPerPacket, AConnections: Double);
begin
  var lLowerType := LowerCase(AEventType);

  if lLowerType = 'ddos' then
  begin
    // DDoS: Massive packet flood, small packets, many connections
    APacketsPerSec := 10000 + Random(5000);
    ABytesPerPacket := 64 + Random(32);  // Small packets
    AConnections := 500 + Random(200);
  end
  else if lLowerType = 'portscan' then
  begin
    // Port Scan: Many connections, few packets each
    APacketsPerSec := 100 + Random(50);
    ABytesPerPacket := 40 + Random(20);  // SYN packets
    AConnections := 1000 + Random(500);  // Many different ports
  end
  else if lLowerType = 'dataexfil' then
  begin
    // Data Exfiltration: Large packets, sustained traffic
    APacketsPerSec := 2000 + Random(500);
    ABytesPerPacket := 1400 + Random(200);  // Large packets (near MTU)
    AConnections := 10 + Random(5);  // Few connections
  end
  else if lLowerType = 'slowloris' then
  begin
    // Slowloris: Many connections, very few packets
    APacketsPerSec := 10 + Random(5);
    ABytesPerPacket := 100 + Random(50);
    AConnections := 800 + Random(200);
  end
  else
  begin
    // Unknown attack - generate random anomaly
    APacketsPerSec := 5000 + Random(3000);
    ABytesPerPacket := 200 + Random(800);
    AConnections := 200 + Random(400);
  end;
end;

procedure RunNetworkIntrusionDetection;
var
  lDetector: TDBSCANDetector;
  lHour, lMinute: Integer;
  lPacketsPerSec, lBytesPerPacket, lConnections: Double;
  lResult: TAnomalyResult;
  lTotalAnomalies, lEventsDetected: Integer;
  lEvents: array[0..4] of TNetworkEvent;
  i: Integer;
  lIsEventTime: Boolean;
  lEventType: string;
begin
  WriteColoredLine('=== NETWORK INTRUSION DETECTION (3D DBSCAN) ===', COLOR_INFO);
  WriteLn('Monitoring: Packets/sec, Bytes/packet, Active Connections');
  WriteLn('Using DBSCAN (ε=150, MinPts=5, 3 dimensions)');
  WriteLn;

  // Create 3D DBSCAN detector
  lDetector := TDBSCANDetector.Create(150.0, 5, 3);
  try
    lDetector.MaxHistorySize := 500;
    lDetector.AutoRecluster := True;
    lTotalAnomalies := 0;
    lEventsDetected := 0;

    // Schedule attack events
    lEvents[0].Hour := 3; lEvents[0].Minute := 15;
    lEvents[0].EventType := 'portscan'; lEvents[0].Description := 'Port Scan Attack';

    lEvents[1].Hour := 9; lEvents[1].Minute := 30;
    lEvents[1].EventType := 'ddos'; lEvents[1].Description := 'DDoS Attack';

    lEvents[2].Hour := 14; lEvents[2].Minute := 45;
    lEvents[2].EventType := 'dataexfil'; lEvents[2].Description := 'Data Exfiltration';

    lEvents[3].Hour := 18; lEvents[3].Minute := 20;
    lEvents[3].EventType := 'slowloris'; lEvents[3].Description := 'Slowloris Attack';

    lEvents[4].Hour := 22; lEvents[4].Minute := 10;
    lEvents[4].EventType := 'ddos'; lEvents[4].Description := 'DDoS Attack (2nd wave)';

    WriteColoredLine('Step 1: Building baseline (first 2 hours)...', COLOR_INFO);

    // Build baseline with normal traffic
    for lHour := 0 to 1 do
    begin
      for lMinute := 0 to 59 do
      begin
        SimulateNormalTraffic(lHour, lPacketsPerSec, lBytesPerPacket, lConnections);
        lDetector.AddPoint([lPacketsPerSec, lBytesPerPacket, lConnections]);
      end;
    end;

    // Force initial clustering
    lDetector.Recluster;

    WriteColoredLine(Format('✓ Baseline established: %d clusters, %d outliers',
      [lDetector.ClusterCount, lDetector.OutlierCount]), COLOR_SUCCESS);
    WriteLn;

    WriteColoredLine('Step 2: Real-time monitoring (24 hours)...', COLOR_INFO);
    WriteLn;

    // Monitor 24 hours of traffic
    for lHour := 2 to 23 do
    begin
      for lMinute := 0 to 59 do
      begin
        SimulateNormalTraffic(lHour, lPacketsPerSec, lBytesPerPacket, lConnections);
        lIsEventTime := False;
        lEventType := '';

        // Check for scheduled attacks
        for i := 0 to High(lEvents) do
        begin
          if (lEvents[i].Hour = lHour) and (lEvents[i].Minute = lMinute) then
          begin
            WriteColoredLine(Format('[%02d:%02d] 🎯 %s',
              [lHour, lMinute, lEvents[i].Description]), COLOR_WARNING);
            SimulateAttack(lEvents[i].EventType, lPacketsPerSec, lBytesPerPacket, lConnections);
            lIsEventTime := True;
            lEventType := lEvents[i].EventType;
          end;
        end;

        // Add to dataset and detect
        lDetector.AddPoint([lPacketsPerSec, lBytesPerPacket, lConnections]);
        lResult := lDetector.DetectMultiDim([lPacketsPerSec, lBytesPerPacket, lConnections]);

        if lResult.IsAnomaly then
        begin
          Inc(lTotalAnomalies);
          if lIsEventTime then
            Inc(lEventsDetected);

          WriteColoredLine(Format('[%02d:%02d] 🚨 INTRUSION DETECTED (Z-score: %.2f)',
            [lHour, lMinute, lResult.ZScore]), COLOR_ANOMALY);
          WriteLn(Format('   Traffic: %.0f pkt/s, %.0f bytes/pkt, %.0f connections',
            [lPacketsPerSec, lBytesPerPacket, lConnections]));

          // Provide intelligent classification
          if lPacketsPerSec > 5000 then
            WriteLn('   → Possible: DDoS or flooding attack')
          else if lConnections > 500 then
            WriteLn('   → Possible: Port scan or connection flooding')
          else if lBytesPerPacket > 1200 then
            WriteLn('   → Possible: Data exfiltration or large payload attack')
          else
            WriteLn('   → Unusual traffic pattern detected');
        end
        else if (lMinute mod 30) = 0 then
        begin
          // Show normal status every 30 minutes
          WriteLn(Format('[%02d:%02d] ✓ Normal traffic: %.0f pkt/s, %.0f bytes/pkt, %.0f conn',
            [lHour, lMinute, lPacketsPerSec, lBytesPerPacket, lConnections]));
        end;
      end;

      // Show clustering update every 4 hours
      if (lHour mod 4) = 0 then
      begin
        WriteLn;
        WriteColoredLine(Format('--- Hour %02d Clustering Update ---', [lHour]), COLOR_INFO);
        WriteLn(Format('Clusters identified: %d', [lDetector.ClusterCount]));
        WriteLn(Format('Historical outliers: %d', [lDetector.OutlierCount]));
        WriteLn(Format('Data points in memory: %d', [lDetector.MaxHistorySize]));
        WriteLn;
      end;
    end;

    WriteLn;
    WriteColoredLine('=== 24-HOUR MONITORING SUMMARY ===', COLOR_SUCCESS);
    WriteLn(Format('• Total intrusions detected: %d', [lTotalAnomalies]));
    WriteLn(Format('• Scheduled attacks simulated: %d', [Length(lEvents)]));
    WriteLn(Format('• Scheduled attacks detected: %d', [lEventsDetected]));
    if Length(lEvents) > 0 then
      WriteLn(Format('• Attack detection rate: %.1f%% (%d/%d)',
        [(lEventsDetected / Length(lEvents)) * 100, lEventsDetected, Length(lEvents)]));
    WriteLn(Format('• Final cluster count: %d', [lDetector.ClusterCount]));
    WriteLn(Format('• Total outliers found: %d', [lDetector.OutlierCount]));

    WriteLn;
    WriteColoredLine('=== DBSCAN ADVANTAGES ===', COLOR_INFO);
    WriteLn('✓ Detects anomalies in multi-dimensional space');
    WriteLn('✓ No need to define "normal" threshold for each dimension');
    WriteLn('✓ Automatically identifies clusters of similar behavior');
    WriteLn('✓ Robust to noise and outliers');
    WriteLn('✓ Finds arbitrarily shaped attack patterns');
    WriteLn('✓ Excellent for: network security, fraud detection, spatial data');

  finally
    lDetector.Free;
  end;
end;

procedure Demonstrate2DSpatialClustering;
var
  lDetector: TDBSCANDetector;
  i: Integer;
  lX, lY: Double;
  lResult: TAnomalyResult;
begin
  WriteColoredLine('=== 2D SPATIAL CLUSTERING DEMO ===', COLOR_INFO);
  WriteLn('Simulating GPS coordinates of normal activity vs outliers');
  WriteLn;

  lDetector := TDBSCANDetector.Create(5.0, 3, 2);
  try
    WriteColoredLine('Phase 1: Add cluster of normal locations (downtown area)', COLOR_INFO);

    // Cluster 1: Downtown (around 0,0)
    for i := 1 to 20 do
    begin
      lX := Random * 10 - 5;  // -5 to +5
      lY := Random * 10 - 5;
      lDetector.AddPoint([lX, lY]);
    end;

    // Cluster 2: Suburb (around 20,20)
    for i := 1 to 15 do
    begin
      lX := 20 + Random * 8 - 4;  // 16 to 24
      lY := 20 + Random * 8 - 4;
      lDetector.AddPoint([lX, lY]);
    end;

    lDetector.Recluster;
    WriteLn(Format('  Clusters found: %d', [lDetector.ClusterCount]));
    WriteLn;

    WriteColoredLine('Phase 2: Test suspicious locations', COLOR_INFO);

    // Test point in downtown cluster - should be normal
    lResult := lDetector.DetectMultiDim([2.0, 3.0]);
    if lResult.IsAnomaly then
      WriteColoredLine('  [2.0, 3.0] → ANOMALY (unexpected!)', COLOR_ANOMALY)
    else
      WriteColoredLine('  [2.0, 3.0] → Normal (downtown area)', COLOR_SUCCESS);

    // Test point in suburb cluster - should be normal
    lResult := lDetector.DetectMultiDim([21.0, 22.0]);
    if lResult.IsAnomaly then
      WriteColoredLine('  [21.0, 22.0] → ANOMALY (unexpected!)', COLOR_ANOMALY)
    else
      WriteColoredLine('  [21.0, 22.0] → Normal (suburb area)', COLOR_SUCCESS);

    // Test isolated point - should be anomaly
    lResult := lDetector.DetectMultiDim([100.0, 100.0]);
    if lResult.IsAnomaly then
      WriteColoredLine(Format('  [100.0, 100.0] → ANOMALY DETECTED (Z-score: %.2f)',
        [lResult.ZScore]), COLOR_ANOMALY)
    else
      WriteColoredLine('  [100.0, 100.0] → Normal (unexpected!)', COLOR_WARNING);

    // Test another isolated point
    lResult := lDetector.DetectMultiDim([-50.0, -50.0]);
    if lResult.IsAnomaly then
      WriteColoredLine(Format('  [-50.0, -50.0] → ANOMALY DETECTED (Z-score: %.2f)',
        [lResult.ZScore]), COLOR_ANOMALY)
    else
      WriteColoredLine('  [-50.0, -50.0] → Normal (unexpected!)', COLOR_WARNING);

    WriteLn;
    WriteColoredLine('Key Insight:', COLOR_SUCCESS);
    WriteLn('• Points within existing clusters → Normal behavior');
    WriteLn('• Isolated points far from clusters → Anomalies');
    WriteLn('• No need to define explicit boundaries for each cluster!');

  finally
    lDetector.Free;
  end;
end;

// Main program
begin
  try
    Randomize;

    WriteLn('DBSCAN Anomaly Detection - Practical Example');
    WriteLn('Scenario: Real-time network intrusion detection system');
    WriteLn(StringOfChar('=', 70));
    WriteLn;

    RunNetworkIntrusionDetection;

    WriteLn;
    WriteLn(StringOfChar('-', 70));
    WriteLn;

    Demonstrate2DSpatialClustering;

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
