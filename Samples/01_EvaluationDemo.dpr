program EvaluationDemo;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  AnomalyDetection.Types in '..\src\Core\AnomalyDetection.Types.pas',
  AnomalyDetection.Base in '..\src\Core\AnomalyDetection.Base.pas',
  AnomalyDetection.Performance in '..\src\Core\AnomalyDetection.Performance.pas',
  AnomalyDetection.Factory in '..\src\AnomalyDetection.Factory.pas',
  AnomalyDetection.ThreeSigma in '..\src\Detectors\AnomalyDetection.ThreeSigma.pas',
  AnomalyDetection.SlidingWindow in '..\src\Detectors\AnomalyDetection.SlidingWindow.pas',
  AnomalyDetection.EMA in '..\src\Detectors\AnomalyDetection.EMA.pas',
  AnomalyDetection.Evaluation in '..\src\Core\AnomalyDetection.Evaluation.pas';

procedure Demo1_BasicEvaluation;
var
  Dataset: TLabeledDataset;
  Detector: IAnomalyDetector;
  Evaluator: TAnomalyDetectorEvaluator;
  Result: TEvaluationResult;
  i: Integer;
  TrainData: TArray<Double>;
begin
  WriteLn('=================================================================');
  WriteLn('DEMO 1: Basic Detector Evaluation with Synthetic Dataset');
  WriteLn('=================================================================');
  WriteLn;

  // Create a labeled dataset with known anomalies
  Dataset := TLabeledDataset.Create('Synthetic Data');
  try
    WriteLn('Generating dataset: 1000 normal points + 50 anomalies...');
    Dataset.GenerateMixedDataset(1000, 50, 100.0, 10.0);
    WriteLn(Format('Dataset created: %d total points (%.1f%% anomalies)',
      [Dataset.Data.Count, Dataset.GetAnomalyPercentage]));
    WriteLn;

    // Create and train a Three Sigma detector
    WriteLn('Training Three Sigma Detector on normal data...');
    Detector := TAnomalyDetectorFactory.CreateThreeSigma;

      // Train only on normal data (first 70% of dataset)
      SetLength(TrainData, 700);
      for i := 0 to 699 do
        TrainData[i] := Dataset.Data[i].Value;

    Detector.AddValues(TrainData);
    Detector.Build;
    WriteLn('Training complete!');
    WriteLn;

    // Evaluate on full dataset
    WriteLn('Evaluating detector performance...');
    Evaluator := TAnomalyDetectorEvaluator.Create(Detector, Dataset);
    try
      Evaluator.Verbose := False;
      Result := Evaluator.Evaluate;

      WriteLn(Evaluator.GenerateReport(Result));
    finally
      Evaluator.Free;
    end;
  finally
    Dataset.Free;
  end;

  WriteLn;
  WriteLn('Press Enter to continue...');
  ReadLn;
end;

procedure Demo2_ComparingDetectors;
var
  Dataset: TLabeledDataset;
  Detectors: array[0..2] of IAnomalyDetector;
  Evaluator: TAnomalyDetectorEvaluator;
  Results: array[0..2] of TEvaluationResult;
  i: Integer;
  TrainData: TArray<Double>;
begin
  WriteLn;
  WriteLn('=================================================================');
  WriteLn('DEMO 2: Comparing Multiple Detectors');
  WriteLn('=================================================================');
  WriteLn;

  Dataset := TLabeledDataset.Create('Comparison Dataset');
  try
    WriteLn('Generating challenging dataset with gradual drift...');
    // Normal data with slight trend
    for i := 1 to 800 do
      Dataset.AddPoint(100 + i * 0.05 + Random * 10, False, 'Normal');

    // Add anomalies - sudden spikes
    for i := 1 to 40 do
      Dataset.AddPoint(100 + Random * 200, True, 'Spike');

    WriteLn(Format('Dataset: %d points (%.1f%% anomalies)',
      [Dataset.Data.Count, Dataset.GetAnomalyPercentage]));
    WriteLn;

    // Prepare training data
    SetLength(TrainData, 500);
    for i := 0 to 499 do
      TrainData[i] := Dataset.Data[i].Value;

    // Create three different detectors
    WriteLn('Creating and training detectors...');
    Detectors[0] := TAnomalyDetectorFactory.CreateThreeSigma;
    Detectors[1] := TAnomalyDetectorFactory.CreateSlidingWindow(100);
    Detectors[2] := TAnomalyDetectorFactory.CreateEMA(0.3);

      // Train all detectors
      for i := 0 to 2 do
      begin
        Detectors[i].AddValues(TrainData);
        Detectors[i].Build;
      end;
      WriteLn('Training complete!');
      WriteLn;

      // Evaluate each detector
      WriteLn('Evaluating all detectors...');
      WriteLn('-----------------------------------------------------------------');
      for i := 0 to 2 do
      begin
        Evaluator := TAnomalyDetectorEvaluator.Create(Detectors[i], Dataset);
        try
          Results[i] := Evaluator.Evaluate;
          WriteLn(Format('%s: F1=%.3f Precision=%.3f Recall=%.3f',
            [Results[i].DetectorName,
             Results[i].ConfusionMatrix.GetF1Score,
             Results[i].ConfusionMatrix.GetPrecision,
             Results[i].ConfusionMatrix.GetRecall]));
        finally
          Evaluator.Free;
        end;
      end;

    WriteLn;
    WriteLn('Analysis:');
    WriteLn('- ThreeSigma: Good for stable environments, may miss gradual changes');
    WriteLn('- SlidingWindow: Adapts to trends, balanced performance');
    WriteLn('- EMA: Fast adaptation, sensitive to recent changes');
  finally
    Dataset.Free;
  end;

  WriteLn;
  WriteLn('Press Enter to continue...');
  ReadLn;
end;

procedure Demo3_CrossValidation;
var
  Dataset: TLabeledDataset;
  Detector: IAnomalyDetector;
  Evaluator: TAnomalyDetectorEvaluator;
  Results: TArray<TEvaluationResult>;
begin
  WriteLn;
  WriteLn('=================================================================');
  WriteLn('DEMO 3: K-Fold Cross-Validation');
  WriteLn('=================================================================');
  WriteLn;

  Dataset := TLabeledDataset.Create('CV Dataset');
  try
    WriteLn('Generating balanced dataset...');
    Dataset.GenerateMixedDataset(800, 200, 100.0, 15.0);
    WriteLn(Format('Dataset: %d points (%.1f%% anomalies)',
      [Dataset.Data.Count, Dataset.GetAnomalyPercentage]));
    WriteLn;

    Detector := TAnomalyDetectorFactory.CreateSlidingWindow(80);

    WriteLn('Performing 5-fold cross-validation...');
    WriteLn('This tests the detector on different data splits to ensure robustness.');
    WriteLn;

    Evaluator := TAnomalyDetectorEvaluator.Create(Detector, Dataset);
    try
      Evaluator.Verbose := True;
      Results := Evaluator.CrossValidate(5);

      WriteLn;
      WriteLn(Evaluator.GenerateCrossValidationReport(Results));
    finally
      Evaluator.Free;
    end;
  finally
    Dataset.Free;
  end;

  WriteLn;
  WriteLn('Press Enter to continue...');
  ReadLn;
end;

procedure Demo4_RealWorldScenario;
var
  Dataset: TLabeledDataset;
  Detector: IAnomalyDetector;
  Evaluator: TAnomalyDetectorEvaluator;
  Result: TEvaluationResult;
  i: Integer;
  BaseValue: Double;
begin
  WriteLn;
  WriteLn('=================================================================');
  WriteLn('DEMO 4: Real-World Scenario - Server Response Time Monitoring');
  WriteLn('=================================================================');
  WriteLn;

  Dataset := TLabeledDataset.Create('Server Response Times');
  try
    WriteLn('Simulating server response times over 24 hours (1 sample/minute)...');

    // Simulate daily pattern: slower during peak hours (9-17), faster at night
    for i := 0 to 1439 do  // 24 hours * 60 minutes
    begin
      var Hour := (i div 60) mod 24;
      if (Hour >= 9) and (Hour <= 17) then
        BaseValue := 250 + Random * 50  // Peak hours: 250-300ms
      else
        BaseValue := 100 + Random * 30;  // Off-peak: 100-130ms

      Dataset.AddPoint(BaseValue, False, Format('Hour %d', [Hour]));
    end;

    // Add realistic anomalies - server issues
    WriteLn('Injecting 20 anomaly events (timeouts, errors)...');
    for i := 1 to 20 do
    begin
      var AnomalyIdx := Random(Dataset.Data.Count);
      Dataset.Data[AnomalyIdx] := TLabeledDataPoint.Create(
        2000 + Random * 1000,  // 2-3 second timeouts
        True,
        'Timeout/Error'
      );
    end;

    WriteLn(Format('Dataset: %d points (%.2f%% anomalies)',
      [Dataset.Data.Count, Dataset.GetAnomalyPercentage]));
    WriteLn;

    // Use Sliding Window detector (adapts to daily patterns)
    WriteLn('Using Sliding Window detector (window=60) for adaptive monitoring...');
    Detector := TAnomalyDetectorFactory.CreateSlidingWindow(60);

    Evaluator := TAnomalyDetectorEvaluator.Create(Detector, Dataset);
    try
      Result := Evaluator.EvaluateWithTrainTestSplit(0.5);  // Train on first 12 hours

      WriteLn;
      WriteLn(Evaluator.GenerateReport(Result));
      WriteLn;

      if Result.ConfusionMatrix.GetRecall >= 0.8 then
        WriteLn('✓ Good recall! Detector catches most issues.')
      else
        WriteLn('⚠ Low recall. Some issues may go undetected.');

      if Result.ConfusionMatrix.GetPrecision >= 0.7 then
        WriteLn('✓ Good precision! Few false alarms.')
      else
        WriteLn('⚠ Low precision. May generate too many false alerts.');
    finally
      Evaluator.Free;
    end;
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
    WriteLn('     Anomaly Detection Library - Evaluation Framework Demo');
    WriteLn('=================================================================');
    WriteLn;
    WriteLn('This demo shows how to evaluate detector performance using:');
    WriteLn('  • Confusion Matrix (TP, FP, TN, FN)');
    WriteLn('  • Classification Metrics (Accuracy, Precision, Recall, F1-Score)');
    WriteLn('  • Cross-Validation for robust testing');
    WriteLn('  • Train/Test splits for realistic scenarios');
    WriteLn;

    Demo1_BasicEvaluation;
    Demo2_ComparingDetectors;
    Demo3_CrossValidation;
    Demo4_RealWorldScenario;

    WriteLn;
    WriteLn('All demos completed!');
  except
    on E: Exception do
    begin
      WriteLn('ERROR: ', E.ClassName, ': ', E.Message);
      ReadLn;
    end;
  end;
end.
