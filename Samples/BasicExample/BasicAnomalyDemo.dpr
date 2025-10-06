// ***************************************************************************
//
// Basic Anomaly Detection Demo
// Simple interactive example showing learning and detection phases
//
// ***************************************************************************

program BasicAnomalyDemo;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  {$IFDEF MSWINDOWS}
  WinAPI.Windows,
  {$ENDIF}
  AnomalyDetection.Types,
  AnomalyDetection.Base,
  AnomalyDetection.Factory;

const
  {$IFDEF MSWINDOWS}
  COLOR_NORMAL = 7;
  COLOR_ERROR = 12;    // Red
  COLOR_WARNING = 14;  // Yellow
  COLOR_SUCCESS = 10;  // Green
  COLOR_INFO = 11;     // Cyan
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

procedure ShowAnomalyLevel(const AResult: TAnomalyResult);
begin
  if not AResult.IsAnomaly then
  begin
    WriteColoredLine('  ✓ NORMAL - Value is within expected range', COLOR_SUCCESS);
    WriteLn(Format('  Z-score: %.2f (within ±3 standard deviations)', [AResult.ZScore]));
  end
  else
  begin
    // Classify anomaly severity based on Z-score
    if Abs(AResult.ZScore) > 6 then
    begin
      WriteColoredLine('  ❌ SEVERE ANOMALY - Value is extremely unusual!', COLOR_ERROR);
      WriteLn(Format('  Z-score: %.2f (more than 6σ from mean)', [AResult.ZScore]));
      WriteLn('  This value is very far from normal - likely an error or critical event');
    end
    else if Abs(AResult.ZScore) > 4 then
    begin
      WriteColoredLine('  ⚠ MODERATE ANOMALY - Value is quite unusual', COLOR_WARNING);
      WriteLn(Format('  Z-score: %.2f (between 4σ and 6σ from mean)', [AResult.ZScore]));
      WriteLn('  This value deserves attention and investigation');
    end
    else
    begin
      WriteColoredLine('  ⚠ MILD ANOMALY - Value is slightly unusual', COLOR_WARNING);
      WriteLn(Format('  Z-score: %.2f (between 3σ and 4σ from mean)', [AResult.ZScore]));
      WriteLn('  This value is outside normal range but not critical');
    end;

    WriteLn(Format('  Expected range: %.2f - %.2f', [AResult.LowerLimit, AResult.UpperLimit]));
  end;
  WriteLn;
end;

var
  Detector: IStatisticalAnomalyDetector;
  TrainingData: TArray<Double>;
  UserInput: string;
  TestValue: Double;
  Result: TAnomalyResult;
  i: Integer;

begin
  try
    WriteLn('═══════════════════════════════════════════════════════════');
    WriteColoredLine('  BASIC ANOMALY DETECTION - Interactive Demo', COLOR_INFO);
    WriteLn('═══════════════════════════════════════════════════════════');
    WriteLn;
    WriteLn('This demo shows how anomaly detection works in 3 simple steps:');
    WriteLn('  1. Learn from historical "normal" data');
    WriteLn('  2. Calculate statistical thresholds');
    WriteLn('  3. Detect anomalies in new data');
    WriteLn;
    WriteLn('Press ENTER to start...');
    ReadLn;

    // =========================================================================
    // PHASE 1: LEARNING FROM HISTORICAL DATA
    // =========================================================================
    WriteLn;
    WriteColoredLine('═══ PHASE 1: LEARNING FROM HISTORICAL DATA ═══', COLOR_INFO);
    WriteLn;
    WriteLn('Imagine you are monitoring daily website visitors.');
    WriteLn('Here are the visitor counts from the last 30 days:');
    WriteLn;

    // Generate realistic "normal" data: average ~500 visitors with some variation
    SetLength(TrainingData, 30);
    Randomize;
    for i := 0 to 29 do
      TrainingData[i] := 480 + Random(40); // Range: 480-520 visitors

    // Display the training data
    Write('Data: ');
    for i := 0 to 29 do
    begin
      Write(Format('%.0f', [TrainingData[i]]));
      if i < 29 then
        Write(', ');
      if (i + 1) mod 10 = 0 then
      begin
        WriteLn;
        Write('      ');
      end;
    end;
    WriteLn;
    WriteLn;

    WriteColoredLine('→ Loading this data into the detector...', COLOR_INFO);

    // Create detector using factory for historical analysis
    Detector := TAnomalyDetectorFactory.CreateForHistoricalAnalysis;
    Detector.AddValues(TrainingData);
    Detector.Build;

    WriteColoredLine('✓ Learning completed!', COLOR_SUCCESS);
    WriteLn;
    WriteLn('Statistical analysis results:');
    WriteLn(Format('  • Average (Mean): %.2f visitors per day', [Detector.Mean]));
    WriteLn(Format('  • Standard Deviation: %.2f', [Detector.StdDev]));
    WriteLn(Format('  • Normal range (Mean ± 3σ): %.2f - %.2f visitors',
                   [Detector.LowerLimit, Detector.UpperLimit]));
      WriteLn;
      WriteLn('The detector now knows what "normal" looks like!');
      WriteLn;
      WriteLn('Press ENTER to continue...');
      ReadLn;

      // =========================================================================
      // PHASE 2: TESTING WITH KNOWN EXAMPLES
      // =========================================================================
      WriteLn;
      WriteColoredLine('═══ PHASE 2: TESTING WITH EXAMPLES ═══', COLOR_INFO);
      WriteLn;
      WriteLn('Let''s test the detector with some example values:');
      WriteLn;

      // Test 1: Normal value
      WriteColoredLine('Test 1: Today we had 505 visitors', COLOR_INFO);
      Result := Detector.Detect(505);
      ShowAnomalyLevel(Result);

      WriteLn('Press ENTER for next test...');
      ReadLn;

      // Test 2: Mild anomaly
      WriteColoredLine('Test 2: Today we had 570 visitors', COLOR_INFO);
      Result := Detector.Detect(570);
      ShowAnomalyLevel(Result);

      WriteLn('Press ENTER for next test...');
      ReadLn;

      // Test 3: Moderate anomaly
      WriteColoredLine('Test 3: Today we had 700 visitors', COLOR_INFO);
      Result := Detector.Detect(700);
      ShowAnomalyLevel(Result);

      WriteLn('Press ENTER for next test...');
      ReadLn;

      // Test 4: Severe anomaly
      WriteColoredLine('Test 4: Today we had 5000 visitors (viral post?)', COLOR_INFO);
      Result := Detector.Detect(5000);
      ShowAnomalyLevel(Result);

      WriteLn('Press ENTER for next test...');
      ReadLn;

      // Test 5: Low anomaly
      WriteColoredLine('Test 5: Today we had 50 visitors (server down?)', COLOR_INFO);
      Result := Detector.Detect(50);
      ShowAnomalyLevel(Result);

      WriteLn('Press ENTER to continue...');
      ReadLn;

      // =========================================================================
      // PHASE 3: INTERACTIVE TESTING
      // =========================================================================
      WriteLn;
      WriteColoredLine('═══ PHASE 3: INTERACTIVE TESTING ═══', COLOR_INFO);
      WriteLn;
      WriteLn('Now it''s your turn! Enter visitor counts and see if they are anomalies.');
      WriteLn(Format('Remember: Normal range is %.0f - %.0f visitors',
                     [Detector.LowerLimit, Detector.UpperLimit]));
      WriteLn;
      WriteLn('Enter a number (or ''q'' to quit):');

      repeat
        WriteLn;
        Write('Visitors today: ');
        ReadLn(UserInput);

        if LowerCase(Trim(UserInput)) = 'q' then
          Break;

        try
          TestValue := StrToFloat(UserInput);
          WriteLn;
          WriteColoredLine(Format('Testing value: %.2f', [TestValue]), COLOR_INFO);
          Result := Detector.Detect(TestValue);
          ShowAnomalyLevel(Result);

          WriteLn('Enter another number (or ''q'' to quit):');
        except
          on E: Exception do
          begin
            WriteColoredLine('Invalid number! Please enter a valid number.', COLOR_ERROR);
            WriteLn('Try again:');
          end;
        end;
      until False;

    WriteLn;
    WriteLn('═══════════════════════════════════════════════════════════');
    WriteColoredLine('Thank you for trying the Basic Anomaly Detection Demo!', COLOR_SUCCESS);
    WriteLn('═══════════════════════════════════════════════════════════');
    WriteLn;
    WriteLn('Key Concepts:');
    WriteLn('  • LEARNING: The detector learns what "normal" looks like from data');
    WriteLn('  • Z-SCORE: Measures how many standard deviations away from the mean');
    WriteLn('  • THRESHOLDS: Values beyond ±3σ are typically considered anomalies');
    WriteLn('  • SEVERITY: Larger Z-scores indicate more severe anomalies');
    WriteLn;

  except
    on E: Exception do
    begin
      WriteColoredLine('ERROR: ' + E.Message, COLOR_ERROR);
      WriteLn('Press ENTER to exit...');
      ReadLn;
      ExitCode := 1;
    end;
  end;
end.
