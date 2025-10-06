// ***************************************************************************
//
// Three Sigma Detector Example - Data Center Temperature Monitoring
// Minimal but realistic example showing quality control use case
//
// ***************************************************************************

program ThreeSigmaExample;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Math,
  {$IFDEF MSWINDOWS}
  WinAPI.Windows,
  {$ENDIF }
  AnomalyDetection.Factory,
  AnomalyDetection.Types,
  AnomalyDetection.ThreeSigma;

const
  // Console colors for Windows
  {$IFDEF MSWINDOWS}
  COLOR_NORMAL = 7;
  COLOR_ANOMALY = 12; // Light red
  COLOR_INFO = 11;    // Light cyan
  COLOR_SUCCESS = 10; // Light green
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

function GenerateHistoricalTemperatures: TArray<Double>;
var
  i: Integer;
  Temperatures: TArray<Double>;
begin
  // Generate 30 days of historical temperature data for a data center
  // Normal operating temperature: 18-22°C with some daily variations
  SetLength(Temperatures, 720); // 30 days * 24 hours
  
  for i := 0 to High(Temperatures) do
  begin
    var HourOfDay := i mod 24;
    var BaseTemp := 20.0; // Base temperature 20°C
    
    // Daily temperature variation (slightly higher during day)
    var DailyVariation := Sin(HourOfDay * 2 * Pi / 24) * 0.5;
    
    // Random noise ±1°C
    var Noise := (Random - 0.5) * 2.0;
    
    Temperatures[i] := BaseTemp + DailyVariation + Noise;
  end;
  
  Result := Temperatures;
end;

procedure TestThreeSigmaDetector;
var
  Detector: TThreeSigmaDetector;
  HistoricalData: TArray<Double>;
  TestValues: TArray<Double>;
  Result: TAnomalyResult;
  i: Integer;
begin
  WriteColoredLine('=== DATA CENTER TEMPERATURE MONITORING ===', COLOR_INFO);
  WriteLn('Using 3-Sigma detector for equipment anomaly detection');
  WriteLn;
  
  Detector := TThreeSigmaDetector.Create;
  try
    // Step 1: Generate and learn from historical data
    WriteColoredLine('Step 1: Loading historical temperature data (30 days)...', COLOR_INFO);
    HistoricalData := GenerateHistoricalTemperatures;

    // Add historical data and build the model
    Detector.AddValues(HistoricalData);
    Detector.Build;
    
    WriteColoredLine('✓ Historical analysis completed', COLOR_SUCCESS);
    WriteLn(Format('  Normal temperature range: %.1f°C - %.1f°C', 
                  [Detector.LowerLimit, Detector.UpperLimit]));
    WriteLn(Format('  Average temperature: %.1f°C (±%.1f°C)', 
                  [Detector.Mean, Detector.StdDev]));
    WriteLn;
    
    // Step 2: Test various temperature scenarios
    WriteColoredLine('Step 2: Testing current temperature readings...', COLOR_INFO);
    
    // Define realistic test scenarios
    TestValues := [
      20.5,   // Normal operation
      19.8,   // Normal operation
      21.2,   // Normal operation  
      25.0,   // Warning - getting warm
      28.5,   // ANOMALY - overheating risk
      15.0,   // ANOMALY - cooling malfunction
      17.5,   // Border case
      35.0    // CRITICAL - equipment failure
    ];
    
    for i := 0 to High(TestValues) do
    begin
      Result := Detector.Detect(TestValues[i]);
      
      Write(Format('[Reading %d] %.1f°C: ', [i+1, TestValues[i]]));
      
      if Result.IsAnomaly then
      begin
        WriteColoredLine(Format('🚨 ANOMALY DETECTED! (Z-score: %.2f)', [Result.ZScore]), COLOR_ANOMALY);
        
        // Provide actionable insights
        if TestValues[i] > Detector.Mean then
          WriteLn('   → Action: Check cooling system, possible overheating')
        else
          WriteLn('   → Action: Check heating/airflow, possible cold spot');
      end
      else
      begin
        WriteLn(Format('✓ Normal (Z-score: %.2f)', [Result.ZScore]));
      end;
    end;
    
    WriteLn;
    WriteColoredLine('=== SUMMARY ===', COLOR_INFO);
    WriteLn('The 3-Sigma detector is ideal when:');
    WriteLn('• You have stable historical data');
    WriteLn('• Operating conditions are consistent');
    WriteLn('• You need reliable statistical baselines');
    WriteLn('• False positives must be minimized');
    
  finally
    Detector.Free;
  end;
end;

// Main program
begin
  try
    Randomize;
    
    WriteLn('Three Sigma Anomaly Detection - Practical Example');
    WriteLn('Scenario: Monitoring data center server temperatures');
    WriteLn(StringOfChar('=', 60));
    WriteLn;
    
    TestThreeSigmaDetector;
    
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