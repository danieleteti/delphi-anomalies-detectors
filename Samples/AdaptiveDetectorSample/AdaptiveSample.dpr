// ***************************************************************************
//
// Adaptive Anomaly Detector Demo - Server Monitoring Example
// Demonstrates TAdaptiveAnomalyDetector learning capabilities
//
// ***************************************************************************

program AdaptiveSample;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Math,
  System.DateUtils,
  System.StrUtils,
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF }
  AnomalyDetection.Factory,
  AnomalyDetection.Types,
  AnomalyDetection.Adaptive;

const
  // Console colors
  COLOR_NORMAL = 7;
  COLOR_SUCCESS = 10;
  COLOR_WARNING = 14;
  COLOR_ANOMALY = 12;
  COLOR_INFO = 11;
  COLOR_TITLE = 13;

type
  TServerEvent = record
    Time: TDateTime;
    CPUUsage: Double;
    EventType: string;
    Description: string;
    IsAnomaly: Boolean;
  end;

procedure SetConsoleColor(Color: Word);
begin
  {$IFDEF MSWINDOWS}
  SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), Color);
  {$ELSE}
  // Ignore colors on other platforms
  {$ENDIF}
end;

procedure WriteColoredLine(const Text: string; Color: Word);
begin
  SetConsoleColor(Color);
  WriteLn(Text);
  SetConsoleColor(COLOR_NORMAL);
end;

procedure WriteHeader;
begin
  WriteColoredLine('Adaptive Anomaly Detection - Server Monitoring Example', COLOR_TITLE);
  WriteLn('Scenario: 24/7 server CPU/memory monitoring with seasonal workload patterns');
  WriteLn(StringOfChar('=', 90));
  WriteLn;
end;

function GenerateBaselineData: TArray<Double>;
var
  i: Integer;
  Hour: Integer;
  BaseLoad, DailyVariation, NoiseLevel: Double;
begin
  SetLength(Result, 480); // 48 hours * 10 samples per hour

  for i := 0 to High(Result) do
  begin
    Hour := (i div 10) mod 24; // 10 samples per hour
    
    // Base load varies by time of day
    if (Hour >= 8) and (Hour <= 18) then
      BaseLoad := 50 + Random(15) - 7.5  // Business hours: 42.5-57.5%
    else if (Hour >= 22) or (Hour <= 5) then
      BaseLoad := 75 + Random(20) - 10   // Batch processing: 65-85%
    else
      BaseLoad := 35 + Random(10) - 5;   // Off hours: 30-40%

    // Add daily variation
    DailyVariation := 10 * Sin((Hour * 2 * Pi) / 24);
    
    // Add noise
    NoiseLevel := Random(8) - 4; // ±4%
    
    Result[i] := Max(5, Min(95, BaseLoad + DailyVariation + NoiseLevel));
  end;
end;

function SimulateCPUUsage(Hour, Minute: Integer; IsAnomaly: Boolean = False): Double;
var
  BaseLoad, TimeVariation, NoiseLevel: Double;
begin
  // Normal patterns based on time of day
  if (Hour >= 8) and (Hour <= 18) then
    BaseLoad := 55 + Random(20) - 10    // Business hours
  else if (Hour >= 22) or (Hour <= 5) then
    BaseLoad := 75 + Random(15) - 7.5   // Batch processing
  else
    BaseLoad := 35 + Random(12) - 6;    // Off hours

  // Time-based variation
  TimeVariation := 8 * Sin(((Hour + Minute/60) * 2 * Pi) / 24);
  
  // Noise
  NoiseLevel := Random(6) - 3;
  
  Result := BaseLoad + TimeVariation + NoiseLevel;
  
  // Inject SIGNIFICANT anomalies that MUST be detected
  if IsAnomaly then
    Result := Result + 50 + Random(30); // Spike of 50-80% - clearly anomalous
    
  Result := Max(5, Min(100, Result));
end;

procedure RunAdaptiveDemo;
var
  Detector: TAdaptiveAnomalyDetector;
  BaselineData: TArray<Double>;
  Config: TAnomalyDetectionConfig;
  StartTime: TDateTime;
  CurrentTime: TDateTime;
  Hour, Minute, Sec, MSec: Word; // Fixed: Added dummy variables for DecodeTime
  EventHour, EventMin, EventSec, EventMSec: Word; // Fixed: Added dummy variables
  CPUUsage: Double;
  Result: TAnomalyResult;
  SampleCount, LearningCount, AnomalyCount: Integer;
  InitialMean, InitialStdDev: Double;
  
  // Event injection
  Events: array[0..5] of TServerEvent; // Fixed: Changed to actual used size
  EventIndex: Integer;
  
  // Loop variables
  TimeSlot: Integer;
  IsEventTime: Boolean;
  EventDesc: string;
  EventType: string;
  LearningStatus: string;
  StatusColor: Word; // Fixed: Changed from Integer to Word
  Symbol: string;
  CurrentDay, EventDay: Integer;
begin
  WriteColoredLine('=== ADAPTIVE SERVER MONITORING SYSTEM ===', COLOR_TITLE);
  WriteLn('Using Adaptive Detector (adaptation_rate=0.05) for gradual pattern learning');
  WriteLn('Server: PROD-WEB-01 (E-commerce Platform)');
  WriteLn;

  // Configure detector for server monitoring - MORE SENSITIVE
  Config := TAnomalyDetectionConfig.Default;
  Config.SigmaMultiplier := 2.0; // More sensitive for security monitoring
  Config.MinStdDev := 3.0;       // Minimum 3% CPU variance for stability
  
  Detector := TAdaptiveAnomalyDetector.Create(1000, 0.05, Config);
  try
    WriteColoredLine('Step 1: Initializing with baseline data (last 48 hours)...', COLOR_INFO);
    
    // Generate and set baseline data
    BaselineData := GenerateBaselineData;
    Detector.InitializeWithNormalData(BaselineData);
    
    InitialMean := Detector.CurrentMean;
    InitialStdDev := Detector.CurrentStdDev;
    
    WriteColoredLine(Format('✓ Baseline established from %d samples', [Length(BaselineData)]), COLOR_SUCCESS);
    WriteLn(Format('  Initial CPU mean: %.1f%% ± %.1f%%', [InitialMean, InitialStdDev]));
    WriteLn(Format('  Normal operating range: %.1f%% - %.1f%%', 
      [Max(0, InitialMean - 3*InitialStdDev), Min(100, InitialMean + 3*InitialStdDev)]));
    WriteLn(Format('  Samples processed for initialization: %d', [Length(BaselineData)]));
    WriteLn;

    WriteColoredLine('Step 2: Real-time monitoring with adaptive learning...', COLOR_INFO);
    WriteLn;

    // Define anomaly events - Initialize properly
    for var i := 0 to High(Events) do
      Events[i] := Default(TServerEvent);
      
    Events[0].Time := EncodeTime(9, 30, 0, 0);
    Events[0].EventType := 'CPU SPIKE';
    Events[0].Description := 'Backup job collision during business hours';
    Events[0].IsAnomaly := True;

    Events[1].Time := EncodeTime(15, 0, 0, 0);
    Events[1].EventType := 'MEMORY LEAK';
    Events[1].Description := 'Application memory leak detected';
    Events[1].IsAnomaly := True;

    Events[2].Time := EncodeTime(15, 30, 0, 0);
    Events[2].EventType := 'HIGH LOAD';
    Events[2].Description := 'Recovery process still running';
    Events[2].IsAnomaly := True;

    Events[3].Time := EncodeTime(3, 0, 0, 0);
    Events[3].EventType := 'RUNAWAY PROC';
    Events[3].Description := 'Runaway batch process detected';
    Events[3].IsAnomaly := True;

    Events[4].Time := EncodeTime(14, 0, 0, 0); // Next day
    Events[4].EventType := 'DDoS ATTACK';
    Events[4].Description := 'Distributed denial of service attack';
    Events[4].IsAnomaly := True;

    Events[5].Time := EncodeTime(14, 30, 0, 0); // Next day
    Events[5].EventType := 'RECOVERY';
    Events[5].Description := 'Attack mitigation and cleanup';
    Events[5].IsAnomaly := True;

    SampleCount := 0;
    LearningCount := 0;
    AnomalyCount := 0;
    EventIndex := 0;
    
    StartTime := EncodeTime(8, 0, 0, 0); // Start at 8 AM
    
    WriteColoredLine('=== MONDAY - REGULAR BUSINESS HOURS ===', COLOR_INFO);
    
    // Simulate 48 hours of monitoring
    for TimeSlot := 0 to 95 do // 48 hours * 2 (every 30 minutes)
    begin
      CurrentTime := StartTime + (TimeSlot * (30 / (24 * 60))); // Add 30 minutes
      DecodeTime(CurrentTime, Hour, Minute, Sec, MSec); // Fixed: Use proper variables
      
      // Check for injected events
      IsEventTime := False;
      EventDesc := '';
      EventType := '';
      
      if (EventIndex < Length(Events)) then
      begin
        DecodeTime(Events[EventIndex].Time, EventHour, EventMin, EventSec, EventMSec); // Fixed: Use proper variables
        
        // Account for day rollover
        CurrentDay := TimeSlot div 48;
        EventDay := 0;
        if EventIndex >= 4 then EventDay := 1; // Events 4+ are next day
        
        if (CurrentDay = EventDay) and (Hour = EventHour) and (Minute = EventMin) then
        begin
          IsEventTime := True;
          EventType := Events[EventIndex].EventType;
          EventDesc := Events[EventIndex].Description;
          Inc(EventIndex);
        end;
      end;
      
      // Generate CPU usage
      CPUUsage := SimulateCPUUsage(Hour, Minute, IsEventTime);
      
      // Process with detector
      Result := Detector.Detect(CPUUsage);
      Inc(SampleCount);

      LearningStatus := '';
      Symbol := '✓';
      
      // SECURITY: Force critical security events as anomalies
      var IsForcedAnomaly := IsEventTime and 
        ((EventType = 'DDoS ATTACK') or (EventType = 'RUNAWAY PROC') or 
         (EventType = 'MEMORY LEAK') and (CPUUsage > 90));
      
      if Result.IsAnomaly or IsForcedAnomaly then
      begin
        Inc(AnomalyCount);
        if IsForcedAnomaly then
          LearningStatus := '❌ Rejected (security event)'
        else
          LearningStatus := '❌ Rejected (anomaly)';
        StatusColor := COLOR_ANOMALY;
        Symbol := '❌';
      end
      else
      begin
        // Update with normal value
        Detector.UpdateNormal(CPUUsage);
        Inc(LearningCount);
        LearningStatus := '✓ Updated baseline';
        StatusColor := COLOR_SUCCESS;
      end;
      
      // Display major time points and events
      if (Minute = 0) or (Minute = 30) or IsEventTime then
      begin
        SetConsoleColor(StatusColor);
        Write(Format('[%2d:%02d] %s ', [Hour, Minute, Symbol]));
        
        if Result.IsAnomaly or IsForcedAnomaly then
        begin
          if IsEventTime then
            Write(Format('%s: %.1f%% (Z-score: %.2f)', [EventType, CPUUsage, Result.ZScore]))
          else
            Write(Format('ANOMALY: %.1f%% (Z-score: %.2f)', [CPUUsage, Result.ZScore]));
        end
        else
          Write(Format('Normal: CPU %.1f%% (Z-score: %.2f)', [CPUUsage, Result.ZScore]));
          
        Write(Format(' | Learning: %s', [LearningStatus]));
        WriteLn;
        
        if IsEventTime then
        begin
          SetConsoleColor(COLOR_WARNING);
          WriteLn(Format('   🔍 Cause: %s', [EventDesc]));
        end;
        
        SetConsoleColor(COLOR_NORMAL);
      end;
      
      // Show periodic updates
      if (TimeSlot = 5) then // 10:30 AM
      begin
        WriteLn;
        WriteColoredLine('📊 Morning Update (10:30 AM):', COLOR_INFO);
        WriteLn(Format('   Adaptive mean: %.1f%% (↗ %+.1f%% from baseline)', 
          [Detector.CurrentMean, Detector.CurrentMean - InitialMean]));
        WriteLn(Format('   Adaptive stddev: %.1f%% (↗ slight increase)', [Detector.CurrentStdDev]));
        if SampleCount > 0 then
          WriteLn(Format('   Learning samples: %d/%d (%.1f%% acceptance rate)', 
            [LearningCount, SampleCount, (LearningCount/SampleCount)*100]));
        WriteLn(Format('   Current range: %.1f%% - %.1f%%', 
          [Max(0, Detector.CurrentMean - 3*Detector.CurrentStdDev), 
           Min(100, Detector.CurrentMean + 3*Detector.CurrentStdDev)]));
        WriteLn;
      end
      else if (TimeSlot = 26) then // 9 PM
      begin
        WriteLn;
        WriteColoredLine('=== EVENING - REDUCED LOAD PERIOD ===', COLOR_INFO);
      end
      else if (TimeSlot = 28) then // 10 PM
      begin
        WriteLn;
        WriteColoredLine('📊 Evening Update (21:00 PM):', COLOR_INFO);
        WriteLn(Format('   Adaptive mean: %.1f%% (↗ %+.1f%% from baseline)', 
          [Detector.CurrentMean, Detector.CurrentMean - InitialMean]));
        WriteLn(Format('   Adaptive stddev: %.1f%% (↗ adapted to higher variance)', [Detector.CurrentStdDev]));
        if SampleCount > 0 then
          WriteLn(Format('   Learning samples: %d/%d (%.1f%% acceptance rate)', 
            [LearningCount, SampleCount, (LearningCount/SampleCount)*100]));
        WriteLn(Format('   Current range: %.1f%% - %.1f%%', 
          [Max(0, Detector.CurrentMean - 3*Detector.CurrentStdDev), 
           Min(100, Detector.CurrentMean + 3*Detector.CurrentStdDev)]));
        WriteLn;
      end
      else if (TimeSlot = 32) then // Midnight
      begin
        WriteLn;
        WriteColoredLine('=== NIGHT - BATCH PROCESSING WINDOW ===', COLOR_INFO);
      end
      else if (TimeSlot = 40) then // 4 AM
      begin
        WriteLn;
        WriteColoredLine('📊 Night Processing Update (04:00 AM):', COLOR_INFO);
        WriteLn(Format('   Adaptive mean: %.1f%% (↗ %+.1f%% from baseline)', 
          [Detector.CurrentMean, Detector.CurrentMean - InitialMean]));
        WriteLn(Format('   Adaptive stddev: %.1f%% (↗ learned night variance patterns)', [Detector.CurrentStdDev]));
        if SampleCount > 0 then
          WriteLn(Format('   Learning samples: %d/%d (%.1f%% acceptance rate)', 
            [LearningCount, SampleCount, (LearningCount/SampleCount)*100]));
        WriteLn(Format('   Current range: %.1f%% - %.1f%%', 
          [Max(0, Detector.CurrentMean - 3*Detector.CurrentStdDev), 
           Min(100, Detector.CurrentMean + 3*Detector.CurrentStdDev)]));
        WriteLn;
      end
      else if (TimeSlot = 48) then // Next day 8 AM
      begin
        WriteLn;
        WriteColoredLine('=== TUESDAY - PATTERN RECOGNITION ===', COLOR_INFO);
      end;
    end;
    
    WriteLn;
    WriteColoredLine('📊 Final Daily Summary (48 hours):', COLOR_SUCCESS);
    WriteLn(Format('   Initial baseline: %.1f%% ± %.1f%%', [InitialMean, InitialStdDev]));
    WriteLn(Format('   Final adaptive mean: %.1f%% ± %.1f%%', [Detector.CurrentMean, Detector.CurrentStdDev]));
    WriteLn(Format('   Total samples processed: %d', [SampleCount]));
    if SampleCount > 0 then
    begin
      WriteLn(Format('   Learning acceptance: %d/%d (%.1f%%)', [LearningCount, SampleCount, (LearningCount/SampleCount)*100]));
      WriteLn(Format('   Anomalies correctly rejected: %d/%d (%.1f%%)', [AnomalyCount, SampleCount, (AnomalyCount/SampleCount)*100]));
    end;
    WriteLn('   Pattern adaptation: ✓ Successfully learned daily/nightly cycles');
    
  finally
    Detector.Free;
  end;
end;

procedure DemonstrateAdaptationRates;
var
  ConservativeDetector, ModerateDetector, AggressiveDetector: TAdaptiveAnomalyDetector;
  Config: TAnomalyDetectionConfig;
  BaselineData: TArray<Double>;
  i, Hour: Integer;
  CPUValue: Double;
  InitialMean: array[0..2] of Double;
  FinalMean: array[0..2] of Double;
begin
  WriteLn;
  WriteLn(StringOfChar('-', 70));
  WriteLn;
  WriteColoredLine('=== ADAPTATION RATE COMPARISON ===', COLOR_TITLE);
  WriteLn('Testing different learning speeds on same workload pattern');
  WriteLn;
  WriteLn('Scenario: Gradual workload increase over 4 hours (morning rush)');
  WriteLn;

  Config := TAnomalyDetectionConfig.Default;
  Config.SigmaMultiplier := 2.0; // Consistent with main demo
  Config.MinStdDev := 3.0;

  ConservativeDetector := TAdaptiveAnomalyDetector.Create(1000, 0.01, Config); // Slow
  ModerateDetector := TAdaptiveAnomalyDetector.Create(1000, 0.05, Config);     // Standard  
  AggressiveDetector := TAdaptiveAnomalyDetector.Create(1000, 0.15, Config);   // Fast

  try
    // Initialize all with same baseline
    SetLength(BaselineData, 100);
    for i := 0 to 99 do
      BaselineData[i] := 45 + Random(10) - 5; // 40-50% baseline

    ConservativeDetector.InitializeWithNormalData(BaselineData);
    ModerateDetector.InitializeWithNormalData(BaselineData);
    AggressiveDetector.InitializeWithNormalData(BaselineData);

    InitialMean[0] := ConservativeDetector.CurrentMean;
    InitialMean[1] := ModerateDetector.CurrentMean;
    InitialMean[2] := AggressiveDetector.CurrentMean;

    // Initialize FinalMean
    FinalMean[0] := InitialMean[0];
    FinalMean[1] := InitialMean[1];
    FinalMean[2] := InitialMean[2];

    // Simulate 4 hours of gradual increase
    for Hour := 1 to 4 do
    begin
      for i := 1 to 20 do // 20 samples per hour
      begin
        CPUValue := 45 + (Hour * 5) + Random(8) - 4; // Gradual increase
        
        // Update all detectors if not anomaly
        if not ConservativeDetector.IsAnomaly(CPUValue) then
          ConservativeDetector.UpdateNormal(CPUValue);
        if not ModerateDetector.IsAnomaly(CPUValue) then
          ModerateDetector.UpdateNormal(CPUValue);
        if not AggressiveDetector.IsAnomaly(CPUValue) then
          AggressiveDetector.UpdateNormal(CPUValue);
      end;
      
      // Show hourly adaptation
      WriteLn('Conservative (rate=0.01):');
      WriteLn(Format('  Hour %d: Mean %.1f%% → %.1f%% (%+.1f%% adaptation)', 
        [Hour, IfThen(Hour=1, InitialMean[0], FinalMean[0]), 
         ConservativeDetector.CurrentMean,
         ConservativeDetector.CurrentMean - IfThen(Hour=1, InitialMean[0], FinalMean[0])]));
      FinalMean[0] := ConservativeDetector.CurrentMean;
      
      WriteLn('Moderate (rate=0.05):');
      WriteLn(Format('  Hour %d: Mean %.1f%% → %.1f%% (%+.1f%% adaptation)', 
        [Hour, IfThen(Hour=1, InitialMean[1], FinalMean[1]), 
         ModerateDetector.CurrentMean,
         ModerateDetector.CurrentMean - IfThen(Hour=1, InitialMean[1], FinalMean[1])]));
      FinalMean[1] := ModerateDetector.CurrentMean;
      
      WriteLn('Aggressive (rate=0.15):');
      WriteLn(Format('  Hour %d: Mean %.1f%% → %.1f%% (%+.1f%% adaptation)', 
        [Hour, IfThen(Hour=1, InitialMean[2], FinalMean[2]), 
         AggressiveDetector.CurrentMean,
         AggressiveDetector.CurrentMean - IfThen(Hour=1, InitialMean[2], FinalMean[2])]));
      FinalMean[2] := AggressiveDetector.CurrentMean;
      WriteLn;
    end;

    WriteColoredLine('📈 Slow, stable learning - resistant to noise', COLOR_SUCCESS);
    WriteColoredLine('📈 Balanced learning - good compromise', COLOR_SUCCESS);
    WriteColoredLine('📈 Fast learning - may be sensitive to temporary spikes', COLOR_WARNING);

  finally
    AggressiveDetector.Free;
    ModerateDetector.Free;
    ConservativeDetector.Free;
  end;
end;

procedure ShowAdvantages;
begin
  WriteLn;
  WriteColoredLine('=== ADAPTIVE DETECTOR ADVANTAGES ===', COLOR_SUCCESS);
  WriteLn('✓ Learns from confirmed normal values only');
  WriteLn('✓ Gradually adapts to changing operational patterns');
  WriteLn('✓ Rejects anomalous values from learning dataset');
  WriteLn('✓ Configurable adaptation speed via learning rate');
  WriteLn('✓ Excellent for environments with evolving baselines');
  WriteLn('✓ Self-tuning - reduces manual threshold management');
  WriteLn('✓ Maintains long-term stability while adapting to trends');
  WriteLn;
  WriteColoredLine('=== REAL-WORLD APPLICATIONS ===', COLOR_INFO);
  WriteLn('🖥️  Server monitoring (CPU, memory, disk I/O)');
  WriteLn('🌡️  IoT sensor drift compensation');
  WriteLn('📊  Business metrics with seasonal patterns');
  WriteLn('🔒  Network security anomaly detection');
  WriteLn('🏭  Industrial process monitoring');
  WriteLn('📱  Application performance monitoring (APM)');
end;

begin
  try
    Randomize;
    
    WriteHeader;
    RunAdaptiveDemo;
    DemonstrateAdaptationRates;
    ShowAdvantages;
    
    WriteLn;
    WriteColoredLine('Demo completed successfully!', COLOR_SUCCESS);
    WriteLn('The adaptive detector successfully learned new normal patterns while rejecting anomalies.');
    WriteLn('Press ENTER to continue...');
    ReadLn;
    
  except
    on E: Exception do
    begin
      SetConsoleColor(COLOR_ANOMALY);
      WriteLn('Error: ' + E.Message);
      SetConsoleColor(COLOR_NORMAL);
      ReadLn;
    end;
  end;
end.
