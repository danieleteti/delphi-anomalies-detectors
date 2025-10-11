program HyperparameterTuningDemo;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Math,
  System.DateUtils,
  AnomalyDetection.Types in '..\src\Core\AnomalyDetection.Types.pas',
  AnomalyDetection.Base in '..\src\Core\AnomalyDetection.Base.pas',
  AnomalyDetection.Performance in '..\src\Core\AnomalyDetection.Performance.pas',
  AnomalyDetection.Factory in '..\src\AnomalyDetection.Factory.pas',
  AnomalyDetection.ThreeSigma in '..\src\Detectors\AnomalyDetection.ThreeSigma.pas',
  AnomalyDetection.SlidingWindow in '..\src\Detectors\AnomalyDetection.SlidingWindow.pas',
  AnomalyDetection.EMA in '..\src\Detectors\AnomalyDetection.EMA.pas',
  AnomalyDetection.Evaluation in '..\src\Core\AnomalyDetection.Evaluation.pas';

procedure Demo1_GridSearchBasic;
var
  Dataset: TLabeledDataset;
  Tuner: THyperparameterTuner;
  BestConfig: TTuningResult;
  SigmaValues: TArray<Double>;
begin
  WriteLn('=================================================================');
  WriteLn('DEMO 1: Grid Search for Optimal Sigma Multiplier');
  WriteLn('=================================================================');
  WriteLn;

  WriteLn('Goal: Find the best sigma multiplier for a Three Sigma detector');
  WriteLn('Dataset: 1000 normal + 50 anomalies (5% anomaly rate)');
  WriteLn;

  // Create dataset
  Dataset := TLabeledDataset.Create('Tuning Dataset');
  try
    Dataset.GenerateMixedDataset(1000, 50, 100.0, 10.0);

    // Create tuner
    Tuner := THyperparameterTuner.Create(adtThreeSigma, Dataset);
    try
      Tuner.OptimizationMetric := 'F1';  // Optimize for F1-Score
      Tuner.Verbose := True;

      WriteLn('Testing sigma multipliers: 2.0, 2.5, 3.0, 3.5, 4.0');
      WriteLn('Default is 3.0 (captures 99.7% of normal data)');
      WriteLn;

      SigmaValues := [2.0, 2.5, 3.0, 3.5, 4.0];
      BestConfig := Tuner.GridSearch(SigmaValues);

      WriteLn;
      WriteLn('=== RESULTS ===');
      WriteLn(Tuner.GenerateTuningReport);

      WriteLn;
      WriteLn('INTERPRETATION:');
      WriteLn('- Lower sigma (2.0): More sensitive, catches more anomalies but more false positives');
      WriteLn('- Higher sigma (4.0): Less sensitive, fewer false positives but may miss anomalies');
      WriteLn('- Optimal sigma: ', Format('%.1f', [BestConfig.Config.SigmaMultiplier]));
    finally
      Tuner.Free;
    end;
  finally
    Dataset.Free;
  end;

  WriteLn;
  WriteLn('Press Enter to continue...');
  ReadLn;
end;

procedure Demo2_SlidingWindowTuning;
var
  Dataset: TLabeledDataset;
  Tuner: THyperparameterTuner;
  BestConfig: TTuningResult;
  SigmaValues: TArray<Double>;
  WindowSizes: TArray<Integer>;
  i: Integer;
begin
  WriteLn;
  WriteLn('=================================================================');
  WriteLn('DEMO 2: Tuning Sliding Window Detector (2D Grid Search)');
  WriteLn('=================================================================');
  WriteLn;

  WriteLn('Goal: Find optimal window size AND sigma multiplier');
  WriteLn('Dataset: Streaming data with concept drift');
  WriteLn;

  Dataset := TLabeledDataset.Create('Streaming Data');
  try
    // Create data with gradual drift
    WriteLn('Generating dataset with gradual drift...');
    for i := 0 to 999 do
      Dataset.AddPoint(100 + i * 0.1 + Random * 10, False);

    // Add anomalies
    for i := 1 to 50 do
      Dataset.AddPoint(100 + Random * 200, True);

    WriteLn(Format('Dataset: %d points', [Dataset.Data.Count]));
    WriteLn;

    Tuner := THyperparameterTuner.Create(adtSlidingWindow, Dataset);
    try
      Tuner.OptimizationMetric := 'F1';
      Tuner.Verbose := True;

      WriteLn('Testing combinations:');
      WriteLn('  Sigma: 2.0, 2.5, 3.0, 3.5');
      WriteLn('  Window Size: 50, 100, 150, 200');
      WriteLn('  Total: 16 combinations');
      WriteLn;

      SigmaValues := [2.0, 2.5, 3.0, 3.5];
      WindowSizes := [50, 100, 150, 200];

      BestConfig := Tuner.GridSearch(SigmaValues, nil, WindowSizes, nil);

      WriteLn;
      WriteLn('=== RESULTS ===');
      WriteLn(Tuner.GenerateTuningReport);

      WriteLn;
      WriteLn('INTERPRETATION:');
      WriteLn(Format('- Best window size: %d', [BestConfig.Config.WindowSize]));
      WriteLn('  • Smaller window: Adapts faster, but more sensitive to noise');
      WriteLn('  • Larger window: More stable, but slower adaptation');
      WriteLn(Format('- Best sigma: %.1f', [BestConfig.Config.SigmaMultiplier]));
    finally
      Tuner.Free;
    end;
  finally
    Dataset.Free;
  end;

  WriteLn;
  WriteLn('Press Enter to continue...');
  ReadLn;
end;

procedure Demo3_EMATuning;
var
  Dataset: TLabeledDataset;
  Tuner: THyperparameterTuner;
  BestConfig: TTuningResult;
  SigmaValues: TArray<Double>;
  AlphaValues: TArray<Double>;
  i: Integer;
begin
  WriteLn;
  WriteLn('=================================================================');
  WriteLn('DEMO 3: Tuning EMA Detector - Finding Optimal Alpha');
  WriteLn('=================================================================');
  WriteLn;

  WriteLn('Goal: Find optimal smoothing factor (alpha) for EMA detector');
  WriteLn('Alpha controls how fast the detector adapts to new data:');
  WriteLn('  • Low alpha (0.1): Slow adaptation, smooth, stable');
  WriteLn('  • High alpha (0.5): Fast adaptation, responsive, volatile');
  WriteLn;

  Dataset := TLabeledDataset.Create('EMA Dataset');
  try
    WriteLn('Generating dataset with sudden level shifts...');

    // Normal data at level 100
    for i := 0 to 399 do
      Dataset.AddPoint(100 + Random * 10, False);

    // Level shift to 150
    for i := 400 to 799 do
      Dataset.AddPoint(150 + Random * 10, False);

    // Add anomalies
    for i := 1 to 40 do
      Dataset.AddPoint(50 + Random * 250, True);

    WriteLn(Format('Dataset: %d points with level shift at point 400', [Dataset.Data.Count]));
    WriteLn;

    Tuner := THyperparameterTuner.Create(adtEMA, Dataset);
    try
      Tuner.OptimizationMetric := 'F1';
      Tuner.Verbose := True;

      WriteLn('Testing combinations:');
      WriteLn('  Sigma: 2.5, 3.0, 3.5');
      WriteLn('  Alpha: 0.1, 0.2, 0.3, 0.4, 0.5');
      WriteLn('  Total: 15 combinations');
      WriteLn;

      SigmaValues := [2.5, 3.0, 3.5];
      AlphaValues := [0.1, 0.2, 0.3, 0.4, 0.5];

      BestConfig := Tuner.GridSearch(SigmaValues, nil, nil, AlphaValues);

      WriteLn;
      WriteLn('=== RESULTS ===');
      WriteLn(Tuner.GenerateTuningReport);

      WriteLn;
      WriteLn('INTERPRETATION:');
      WriteLn(Format('- Best alpha: %.2f', [BestConfig.Config.Alpha]));
      if BestConfig.Config.Alpha <= 0.2 then
        WriteLn('  ➜ Low alpha chosen: Data is stable, slow adaptation preferred')
      else if BestConfig.Config.Alpha >= 0.4 then
        WriteLn('  ➜ High alpha chosen: Data changes rapidly, fast adaptation needed')
      else
        WriteLn('  ➜ Medium alpha chosen: Balanced between stability and responsiveness');
    finally
      Tuner.Free;
    end;
  finally
    Dataset.Free;
  end;

  WriteLn;
  WriteLn('Press Enter to continue...');
  ReadLn;
end;

procedure Demo4_RandomSearchVsGrid;
var
  Dataset: TLabeledDataset;
  GridTuner, RandomTuner: THyperparameterTuner;
  GridBest, RandomBest: TTuningResult;
  SigmaValues: TArray<Double>;
  WindowSizes: TArray<Integer>;
  StartTime: TDateTime;
  GridTime, RandomTime: Integer;
begin
  WriteLn;
  WriteLn('=================================================================');
  WriteLn('DEMO 4: Grid Search vs Random Search - Speed Comparison');
  WriteLn('=================================================================');
  WriteLn;

  WriteLn('Comparing two hyperparameter optimization strategies:');
  WriteLn('  • Grid Search: Tests all combinations (exhaustive)');
  WriteLn('  • Random Search: Tests random combinations (faster)');
  WriteLn;

  Dataset := TLabeledDataset.Create('Comparison Dataset');
  try
    Dataset.GenerateMixedDataset(800, 80, 100.0, 15.0);

    // Grid Search
    WriteLn('--- GRID SEARCH ---');
    GridTuner := THyperparameterTuner.Create(adtSlidingWindow, Dataset);
    try
      GridTuner.OptimizationMetric := 'F1';
      GridTuner.Verbose := False;

      SigmaValues := [2.0, 2.5, 3.0, 3.5, 4.0];
      WindowSizes := [50, 80, 100, 120, 150];

      WriteLn(Format('Testing %d combinations (5 sigmas × 5 windows)...', [Length(SigmaValues) * Length(WindowSizes)]));
      StartTime := Now;
      GridBest := GridTuner.GridSearch(SigmaValues, nil, WindowSizes, nil);
      GridTime := MilliSecondsBetween(Now, StartTime);

      WriteLn(Format('Grid Search completed in %d ms', [GridTime]));
      WriteLn(Format('Best: Sigma=%.1f, Window=%d, F1=%.3f',
        [GridBest.Config.SigmaMultiplier, GridBest.Config.WindowSize,
         GridBest.EvaluationResult.ConfusionMatrix.GetF1Score]));
    finally
      GridTuner.Free;
    end;

    WriteLn;
    WriteLn('--- RANDOM SEARCH ---');
    RandomTuner := THyperparameterTuner.Create(adtSlidingWindow, Dataset);
    try
      RandomTuner.OptimizationMetric := 'F1';
      RandomTuner.Verbose := False;

      WriteLn('Testing 25 random combinations...');
      StartTime := Now;
      RandomBest := RandomTuner.RandomSearch(25);
      RandomTime := MilliSecondsBetween(Now, StartTime);

      WriteLn(Format('Random Search completed in %d ms', [RandomTime]));
      WriteLn(Format('Best: Sigma=%.1f, Window=%d, F1=%.3f',
        [RandomBest.Config.SigmaMultiplier, RandomBest.Config.WindowSize,
         RandomBest.EvaluationResult.ConfusionMatrix.GetF1Score]));
    finally
      RandomTuner.Free;
    end;

    WriteLn;
    WriteLn('=== COMPARISON ===');
    WriteLn(Format('Grid Search:   %d ms, F1=%.3f', [GridTime, GridBest.EvaluationResult.ConfusionMatrix.GetF1Score]));
    WriteLn(Format('Random Search: %d ms, F1=%.3f', [RandomTime, RandomBest.EvaluationResult.ConfusionMatrix.GetF1Score]));
    WriteLn;
    WriteLn('RECOMMENDATION:');
    WriteLn('  • Use Grid Search when: Few parameters, exhaustive search needed');
    WriteLn('  • Use Random Search when: Many parameters, faster results needed');
    WriteLn('  • Random search often finds good-enough solutions much faster!');
  finally
    Dataset.Free;
  end;

  WriteLn;
  WriteLn('Press Enter to continue...');
  ReadLn;
end;

procedure Demo5_OptimizingForSpecificMetric;
var
  Dataset: TLabeledDataset;
  Tuner: THyperparameterTuner;
  Results: array[0..2] of TTuningResult;
  Metrics: array[0..2] of string;
  SigmaValues: TArray<Double>;
  i: Integer;
begin
  WriteLn;
  WriteLn('=================================================================');
  WriteLn('DEMO 5: Optimizing for Different Business Objectives');
  WriteLn('=================================================================');
  WriteLn;

  WriteLn('Different metrics optimize for different goals:');
  WriteLn('  • PRECISION: Minimize false positives (avoid alert fatigue)');
  WriteLn('  • RECALL: Minimize false negatives (don''t miss critical issues)');
  WriteLn('  • F1-SCORE: Balance between precision and recall');
  WriteLn;

  Dataset := TLabeledDataset.Create('Business Dataset');
  try
    // Create imbalanced dataset (realistic: few anomalies)
    Dataset.GenerateMixedDataset(950, 50, 100.0, 10.0);
    WriteLn(Format('Dataset: %d points (%.1f%% anomalies - realistic imbalance)',
      [Dataset.Data.Count, Dataset.GetAnomalyPercentage]));
    WriteLn;

    SigmaValues := [2.0, 2.5, 3.0, 3.5, 4.0];
    Metrics[0] := 'Precision';
    Metrics[1] := 'Recall';
    Metrics[2] := 'F1';

    for i := 0 to 2 do
    begin
      WriteLn(Format('--- Optimizing for %s ---', [Metrics[i]]));

      Tuner := THyperparameterTuner.Create(adtThreeSigma, Dataset);
      try
        Tuner.OptimizationMetric := Metrics[i];
        Tuner.Verbose := False;

        Results[i] := Tuner.GridSearch(SigmaValues);

        WriteLn(Format('Best sigma: %.1f', [Results[i].Config.SigmaMultiplier]));
        WriteLn(Format('  Precision: %.3f', [Results[i].EvaluationResult.ConfusionMatrix.GetPrecision]));
        WriteLn(Format('  Recall:    %.3f', [Results[i].EvaluationResult.ConfusionMatrix.GetRecall]));
        WriteLn(Format('  F1-Score:  %.3f', [Results[i].EvaluationResult.ConfusionMatrix.GetF1Score]));
        WriteLn;
      finally
        Tuner.Free;
      end;
    end;

    WriteLn('=== BUSINESS SCENARIOS ===');
    WriteLn;
    WriteLn('Scenario 1: Financial Fraud Detection');
    WriteLn('  Goal: Don''t miss ANY fraud (high recall)');
    WriteLn(Format('  ➜ Use sigma=%.1f (Recall-optimized)', [Results[1].Config.SigmaMultiplier]));
    WriteLn('  Trade-off: More false positives, but no fraud slips through');
    WriteLn;

    WriteLn('Scenario 2: Server Monitoring (24/7 operations)');
    WriteLn('  Goal: Minimize false alerts to avoid fatigue (high precision)');
    WriteLn(Format('  ➜ Use sigma=%.1f (Precision-optimized)', [Results[0].Config.SigmaMultiplier]));
    WriteLn('  Trade-off: May miss minor issues, but alerts are trustworthy');
    WriteLn;

    WriteLn('Scenario 3: General Quality Control');
    WriteLn('  Goal: Balanced detection (high F1)');
    WriteLn(Format('  ➜ Use sigma=%.1f (F1-optimized)', [Results[2].Config.SigmaMultiplier]));
    WriteLn('  Trade-off: Good compromise for most applications');
  finally
    Dataset.Free;
  end;

  WriteLn;
  WriteLn('Press Enter to exit...');
  ReadLn;
end;

begin
  try
    Randomize;

    WriteLn('=================================================================');
    WriteLn('   Anomaly Detection Library - Hyperparameter Tuning Demo');
    WriteLn('=================================================================');
    WriteLn;
    WriteLn('This demo shows how to optimize detector performance by:');
    WriteLn('  • Finding optimal hyperparameters (sigma, window size, alpha)');
    WriteLn('  • Using Grid Search (exhaustive) or Random Search (faster)');
    WriteLn('  • Optimizing for specific business objectives');
    WriteLn('  • Understanding trade-offs between different metrics');
    WriteLn;

    Demo1_GridSearchBasic;
    Demo2_SlidingWindowTuning;
    Demo3_EMATuning;
    Demo4_RandomSearchVsGrid;
    Demo5_OptimizingForSpecificMetric;

    WriteLn;
    WriteLn('All demos completed!');
    WriteLn;
    WriteLn('KEY TAKEAWAYS:');
    WriteLn('1. Default parameters (sigma=3.0) are good starting points');
    WriteLn('2. Always tune on representative data from your domain');
    WriteLn('3. Choose optimization metric based on business cost of errors');
    WriteLn('4. Grid search for few parameters, random search for many');
    WriteLn('5. Use cross-validation to ensure robustness');
  except
    on E: Exception do
    begin
      WriteLn('ERROR: ', E.ClassName, ': ', E.Message);
      ReadLn;
    end;
  end;
end.
