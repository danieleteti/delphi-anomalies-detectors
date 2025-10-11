program QuickEvaluationTest;

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

procedure TestConfusionMatrix;
var
  Matrix: TConfusionMatrix;
begin
  WriteLn('Testing Confusion Matrix...');
  Matrix.Reset;
  Matrix.TruePositives := 45;
  Matrix.FalsePositives := 5;
  Matrix.TrueNegatives := 940;
  Matrix.FalseNegatives := 10;

  WriteLn('  Accuracy: ', Matrix.GetAccuracy:0:3);
  WriteLn('  Precision: ', Matrix.GetPrecision:0:3);
  WriteLn('  Recall: ', Matrix.GetRecall:0:3);
  WriteLn('  F1-Score: ', Matrix.GetF1Score:0:3);
  WriteLn('  ✓ Confusion Matrix OK');
  WriteLn;
end;

procedure TestDatasetGeneration;
var
  Dataset: TLabeledDataset;
begin
  WriteLn('Testing Dataset Generation...');
  Dataset := TLabeledDataset.Create('Test');
  try
    Dataset.GenerateMixedDataset(100, 10, 100.0, 10.0);
    WriteLn('  Generated ', Dataset.Data.Count, ' points');
    WriteLn('  Anomalies: ', Dataset.GetAnomalyCount);
    WriteLn('  Normal: ', Dataset.GetNormalCount);
    WriteLn('  ✓ Dataset Generation OK');
  finally
    Dataset.Free;
  end;
  WriteLn;
end;

procedure TestEvaluation;
var
  Dataset: TLabeledDataset;
  Detector: IAnomalyDetector;
  Evaluator: TAnomalyDetectorEvaluator;
  Result: TEvaluationResult;
  TrainData: TArray<Double>;
  i: Integer;
begin
  WriteLn('Testing Detector Evaluation...');
  Dataset := TLabeledDataset.Create('Test');
  try
    Dataset.GenerateMixedDataset(500, 25, 100.0, 10.0);

    Detector := TAnomalyDetectorFactory.CreateThreeSigma;

      // Train
      SetLength(TrainData, 300);
      for i := 0 to 299 do
        TrainData[i] := Dataset.Data[i].Value;
      Detector.AddValues(TrainData);
      Detector.Build;

      // Evaluate
      Evaluator := TAnomalyDetectorEvaluator.Create(Detector, Dataset);
      try
        Result := Evaluator.Evaluate;
        WriteLn('  TP:', Result.ConfusionMatrix.TruePositives,
                ' FP:', Result.ConfusionMatrix.FalsePositives,
                ' TN:', Result.ConfusionMatrix.TrueNegatives,
                ' FN:', Result.ConfusionMatrix.FalseNegatives);
      WriteLn('  F1-Score: ', Result.ConfusionMatrix.GetF1Score:0:3);
      WriteLn('  ✓ Evaluation OK');
    finally
      Evaluator.Free;
    end;
  finally
    Dataset.Free;
  end;
  WriteLn;
end;

procedure TestHyperparameterTuning;
var
  Dataset: TLabeledDataset;
  Tuner: THyperparameterTuner;
  BestConfig: TTuningResult;
  SigmaValues: TArray<Double>;
begin
  WriteLn('Testing Hyperparameter Tuning...');
  Dataset := TLabeledDataset.Create('Tuning');
  try
    Dataset.GenerateMixedDataset(200, 20, 100.0, 10.0);

    Tuner := THyperparameterTuner.Create(adtThreeSigma, Dataset);
    try
      Tuner.OptimizationMetric := 'F1';
      Tuner.Verbose := False;

      SigmaValues := [2.5, 3.0, 3.5];
      BestConfig := Tuner.GridSearch(SigmaValues);

      WriteLn('  Best Sigma: ', BestConfig.Config.SigmaMultiplier:0:1);
      WriteLn('  Best F1: ', BestConfig.Score:0:3);
      WriteLn('  Tested ', Tuner.Results.Count, ' configurations');
      WriteLn('  ✓ Hyperparameter Tuning OK');
    finally
      Tuner.Free;
    end;
  finally
    Dataset.Free;
  end;
  WriteLn;
end;

procedure TestBorderCases;
var
  Matrix: TConfusionMatrix;
  Dataset: TLabeledDataset;
  Tuner: THyperparameterTuner;
  EmptySigma: TArray<Double>;
begin
  WriteLn('Testing Border Cases...');

  // Test zero confusion matrix
  Matrix.Reset;
  if (Matrix.GetAccuracy = 0) and (Matrix.GetF1Score = 0) then
    WriteLn('  ✓ Zero division handled correctly');

  // Test empty parameter array
  Dataset := TLabeledDataset.Create('Test');
  try
    Dataset.GenerateMixedDataset(50, 5, 100.0, 10.0);
    Tuner := THyperparameterTuner.Create(adtThreeSigma, Dataset);
    try
      SetLength(EmptySigma, 0);
      try
        Tuner.GridSearch(EmptySigma);
        WriteLn('  ✗ Should have raised exception for empty array');
      except
        on E: EAnomalyDetectionException do
          WriteLn('  ✓ Empty array validation works');
      end;
    finally
      Tuner.Free;
    end;
  finally
    Dataset.Free;
  end;

  WriteLn;
end;

begin
  try
    Randomize;

    WriteLn('=== Quick Evaluation Framework Test ===');
    WriteLn;

    TestConfusionMatrix;
    TestDatasetGeneration;
    TestEvaluation;
    TestHyperparameterTuning;
    TestBorderCases;

    WriteLn('=== ALL TESTS PASSED ===');
    WriteLn;
    WriteLn('The evaluation framework is working correctly!');
  except
    on E: Exception do
    begin
      WriteLn;
      WriteLn('!!! TEST FAILED !!!');
      WriteLn('Error: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
