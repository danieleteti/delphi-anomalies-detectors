// ***************************************************************************
//
// Copyright (c) 2025 Daniele Teti - All Rights Reserved
//
// Anomaly Detection Evaluation Framework
// Provides tools for measuring detector performance with labeled datasets
//
// ***************************************************************************

unit AnomalyDetection.Evaluation;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  AnomalyDetection.Types, AnomalyDetection.Base;

type
  /// <summary>
  /// Labeled data point for evaluation
  /// </summary>
  TLabeledDataPoint = record
    Value: Double;
    IsAnomaly: Boolean;  // Ground truth label
    Timestamp: TDateTime;
    Description: string;
    class function Create(AValue: Double; AIsAnomaly: Boolean; const ADescription: string = ''): TLabeledDataPoint; static;
  end;

  /// <summary>
  /// Multi-dimensional labeled data point
  /// </summary>
  TLabeledMultiDimPoint = record
    Features: TArray<Double>;
    IsAnomaly: Boolean;  // Ground truth label
    Timestamp: TDateTime;
    Description: string;
    class function Create(const AFeatures: TArray<Double>; AIsAnomaly: Boolean; const ADescription: string = ''): TLabeledMultiDimPoint; static;
  end;

  /// <summary>
  /// Confusion Matrix for binary classification
  /// </summary>
  TConfusionMatrix = record
    TruePositives: Int64;   // Correctly identified anomalies
    FalsePositives: Int64;  // Normal data incorrectly marked as anomaly
    TrueNegatives: Int64;   // Correctly identified normal data
    FalseNegatives: Int64;  // Anomalies missed (incorrectly marked as normal)

    function GetAccuracy: Double;
    function GetPrecision: Double;
    function GetRecall: Double;
    function GetF1Score: Double;
    function GetSpecificity: Double;
    function GetFalsePositiveRate: Double;
    function GetFalseNegativeRate: Double;
    function GetMatthewsCorrelationCoefficient: Double;
    procedure Reset;
    function ToString: string;
    function ToDetailedString: string;
  end;

  /// <summary>
  /// Evaluation result with full metrics
  /// </summary>
  TEvaluationResult = record
    ConfusionMatrix: TConfusionMatrix;
    DatasetSize: Int64;
    AnomaliesInDataset: Int64;
    NormalInDataset: Int64;
    DetectorName: string;
    EvaluationTimeMs: Int64;

    function GetSummary: string;
  end;

  /// <summary>
  /// Dataset loader for evaluation
  /// </summary>
  TLabeledDataset = class
  private
    FData: TList<TLabeledDataPoint>;
    FName: string;
    FDescription: string;
  public
    constructor Create(const AName: string = '');
    destructor Destroy; override;

    procedure AddPoint(const AValue: Double; AIsAnomaly: Boolean; const ADescription: string = '');
    procedure AddPoints(const AValues: TArray<Double>; const ALabels: TArray<Boolean>);
    procedure Clear;

    // Dataset loading
    procedure LoadFromCSV(const AFileName: string; AValueColumn: Integer = 0; ALabelColumn: Integer = 1; AHasHeader: Boolean = True);
    procedure SaveToCSV(const AFileName: string);

    // Dataset generation for testing
    procedure GenerateNormalData(ACount: Int64; AMean: Double; AStdDev: Double);
    procedure GenerateAnomalies(ACount: Int64; AMean: Double; AStdDev: Double; ADeviationMultiplier: Double = 5.0);
    procedure GenerateMixedDataset(ANormalCount: Int64; AAnomalyCount: Int64; AMean: Double; AStdDev: Double);

    // Statistics
    function GetAnomalyCount: Int64;
    function GetNormalCount: Int64;
    function GetAnomalyPercentage: Double;

    property Data: TList<TLabeledDataPoint> read FData;
    property Name: string read FName write FName;
    property Description: string read FDescription write FDescription;
    property Count: Int64 read GetNormalCount;
  end;

  /// <summary>
  /// Evaluator for testing detector performance
  /// </summary>
  TAnomalyDetectorEvaluator = class
  private
    FDetector: IAnomalyDetector;
    FDataset: TLabeledDataset;
    FVerbose: Boolean;
  public
    constructor Create(ADetector: IAnomalyDetector; ADataset: TLabeledDataset);

    // Evaluation methods
    function Evaluate: TEvaluationResult;
    function EvaluateWithTrainTestSplit(ATrainRatio: Double = 0.7): TEvaluationResult;
    function CrossValidate(AFolds: Integer = 5): TArray<TEvaluationResult>;

    // Report generation
    function GenerateReport(const AResult: TEvaluationResult): string;
    function GenerateCrossValidationReport(const AResults: TArray<TEvaluationResult>): string;

    property Verbose: Boolean read FVerbose write FVerbose;
  end;

  /// <summary>
  /// Hyperparameter configuration for tuning
  /// </summary>
  THyperparameterConfig = record
    Name: string;
    SigmaMultiplier: Double;
    MinStdDev: Double;
    WindowSize: Integer;
    Alpha: Double;  // For EMA
    LearningRate: Double;  // For Adaptive
    NumTrees: Integer;  // For Isolation Forest
    SampleSize: Integer;  // For Isolation Forest

    class function Default: THyperparameterConfig; static;
  end;

  /// <summary>
  /// Tuning result for a specific hyperparameter configuration
  /// </summary>
  TTuningResult = record
    Config: THyperparameterConfig;
    EvaluationResult: TEvaluationResult;
    Score: Double;  // Primary metric for optimization

    function ToString: string;
  end;

  /// <summary>
  /// Hyperparameter tuning framework
  /// </summary>
  THyperparameterTuner = class
  private
    FDetectorType: TAnomalyDetectorType;
    FDataset: TLabeledDataset;
    FOptimizationMetric: string;  // 'F1', 'Precision', 'Recall', 'Accuracy'
    FResults: TList<TTuningResult>;
    FVerbose: Boolean;

    function CreateDetectorWithConfig(const AConfig: THyperparameterConfig): IAnomalyDetector;
    function GetScoreFromResult(const AResult: TEvaluationResult): Double;
  public
    constructor Create(ADetectorType: TAnomalyDetectorType; ADataset: TLabeledDataset);
    destructor Destroy; override;

    // Grid search over hyperparameter space
    function GridSearch(
      const ASigmaMultipliers: TArray<Double>;
      const AMinStdDevs: TArray<Double> = nil;
      const AWindowSizes: TArray<Integer> = nil;
      const AAlphas: TArray<Double> = nil
    ): TTuningResult;

    // Random search (sample from parameter space)
    function RandomSearch(AIterations: Integer): TTuningResult;

    // Get best N configurations
    function GetTopConfigurations(ACount: Integer = 5): TArray<TTuningResult>;

    // Report generation
    function GenerateTuningReport: string;

    property OptimizationMetric: string read FOptimizationMetric write FOptimizationMetric;
    property Results: TList<TTuningResult> read FResults;
    property Verbose: Boolean read FVerbose write FVerbose;
  end;

implementation

uses
  System.Math, System.DateUtils, System.StrUtils, System.Generics.Defaults,
  AnomalyDetection.Factory;

{ TLabeledDataPoint }

class function TLabeledDataPoint.Create(AValue: Double; AIsAnomaly: Boolean; const ADescription: string): TLabeledDataPoint;
begin
  Result.Value := AValue;
  Result.IsAnomaly := AIsAnomaly;
  Result.Timestamp := Now;
  Result.Description := ADescription;
end;

{ TLabeledMultiDimPoint }

class function TLabeledMultiDimPoint.Create(const AFeatures: TArray<Double>; AIsAnomaly: Boolean; const ADescription: string): TLabeledMultiDimPoint;
begin
  Result.Features := AFeatures;
  Result.IsAnomaly := AIsAnomaly;
  Result.Timestamp := Now;
  Result.Description := ADescription;
end;

{ TConfusionMatrix }

function TConfusionMatrix.GetAccuracy: Double;
var
  Total: Integer;
begin
  Total := TruePositives + TrueNegatives + FalsePositives + FalseNegatives;
  if Total > 0 then
    Result := (TruePositives + TrueNegatives) / Total
  else
    Result := 0;
end;

function TConfusionMatrix.GetPrecision: Double;
begin
  if (TruePositives + FalsePositives) > 0 then
    Result := TruePositives / (TruePositives + FalsePositives)
  else
    Result := 0;
end;

function TConfusionMatrix.GetRecall: Double;
begin
  if (TruePositives + FalseNegatives) > 0 then
    Result := TruePositives / (TruePositives + FalseNegatives)
  else
    Result := 0;
end;

function TConfusionMatrix.GetF1Score: Double;
var
  P, R: Double;
begin
  P := GetPrecision;
  R := GetRecall;
  if (P + R) > 0 then
    Result := 2 * P * R / (P + R)
  else
    Result := 0;
end;

function TConfusionMatrix.GetSpecificity: Double;
begin
  if (TrueNegatives + FalsePositives) > 0 then
    Result := TrueNegatives / (TrueNegatives + FalsePositives)
  else
    Result := 0;
end;

function TConfusionMatrix.GetFalsePositiveRate: Double;
begin
  Result := 1 - GetSpecificity;
end;

function TConfusionMatrix.GetFalseNegativeRate: Double;
begin
  Result := 1 - GetRecall;
end;

function TConfusionMatrix.GetMatthewsCorrelationCoefficient: Double;
var
  Numerator, Denominator: Double;
begin
  // Int64 multiplication avoids overflow for large datasets
  Numerator := (Int64(TruePositives) * Int64(TrueNegatives)) - (Int64(FalsePositives) * Int64(FalseNegatives));
  Denominator := Sqrt((TruePositives + FalsePositives) * (TruePositives + FalseNegatives) *
                      (TrueNegatives + FalsePositives) * (TrueNegatives + FalseNegatives));

  if Denominator > 0 then
    Result := Numerator / Denominator
  else
    Result := 0;
end;

procedure TConfusionMatrix.Reset;
begin
  TruePositives := 0;
  FalsePositives := 0;
  TrueNegatives := 0;
  FalseNegatives := 0;
end;

function TConfusionMatrix.ToString: string;
begin
  Result := Format('TP=%d FP=%d TN=%d FN=%d | Acc=%.3f Prec=%.3f Rec=%.3f F1=%.3f',
    [TruePositives, FalsePositives, TrueNegatives, FalseNegatives,
     GetAccuracy, GetPrecision, GetRecall, GetF1Score]);
end;

function TConfusionMatrix.ToDetailedString: string;
begin
  Result := 'Confusion Matrix:' + sLineBreak +
            '                 Predicted' + sLineBreak +
            '               Anomaly  Normal' + sLineBreak +
            Format('Actual Anomaly    %4d    %4d', [TruePositives, FalseNegatives]) + sLineBreak +
            Format('       Normal     %4d    %4d', [FalsePositives, TrueNegatives]) + sLineBreak +
            sLineBreak +
            'Metrics:' + sLineBreak +
            Format('  Accuracy:  %.3f', [GetAccuracy]) + sLineBreak +
            Format('  Precision: %.3f (of detected anomalies, %.1f%% were correct)', [GetPrecision, GetPrecision * 100]) + sLineBreak +
            Format('  Recall:    %.3f (detected %.1f%% of actual anomalies)', [GetRecall, GetRecall * 100]) + sLineBreak +
            Format('  F1-Score:  %.3f (harmonic mean of precision and recall)', [GetF1Score]) + sLineBreak +
            Format('  Specificity: %.3f', [GetSpecificity]) + sLineBreak +
            Format('  False Positive Rate: %.3f', [GetFalsePositiveRate]) + sLineBreak +
            Format('  False Negative Rate: %.3f', [GetFalseNegativeRate]) + sLineBreak +
            Format('  Matthews Correlation: %.3f', [GetMatthewsCorrelationCoefficient]);
end;

{ TEvaluationResult }

function TEvaluationResult.GetSummary: string;
begin
  Result := Format('Evaluation Results for %s:', [DetectorName]) + sLineBreak +
            Format('Dataset: %d points (%d anomalies, %d normal)',
              [DatasetSize, AnomaliesInDataset, NormalInDataset]) + sLineBreak +
            Format('Evaluation time: %d ms', [EvaluationTimeMs]) + sLineBreak +
            sLineBreak +
            ConfusionMatrix.ToDetailedString;
end;

{ TLabeledDataset }

constructor TLabeledDataset.Create(const AName: string);
begin
  inherited Create;
  FData := TList<TLabeledDataPoint>.Create;
  FName := AName;
end;

destructor TLabeledDataset.Destroy;
begin
  FData.Free;
  inherited;
end;

procedure TLabeledDataset.AddPoint(const AValue: Double; AIsAnomaly: Boolean; const ADescription: string);
var
  Point: TLabeledDataPoint;
begin
  Point := TLabeledDataPoint.Create(AValue, AIsAnomaly, ADescription);
  FData.Add(Point);
end;

procedure TLabeledDataset.AddPoints(const AValues: TArray<Double>; const ALabels: TArray<Boolean>);
var
  i: Integer;
begin
  if Length(AValues) <> Length(ALabels) then
    raise EAnomalyDetectionException.Create('Values and labels arrays must have the same length');

  for i := 0 to High(AValues) do
    AddPoint(AValues[i], ALabels[i]);
end;

procedure TLabeledDataset.Clear;
begin
  FData.Clear;
end;

procedure TLabeledDataset.LoadFromCSV(const AFileName: string; AValueColumn, ALabelColumn: Integer; AHasHeader: Boolean);
var
  Lines: TStringList;
  i, StartIdx: Integer;
  Parts: TArray<string>;
  Value: Double;
  IsAnomaly: Boolean;
begin
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(AFileName);

    StartIdx := 0;
    if AHasHeader and (Lines.Count > 0) then
      StartIdx := 1;

    for i := StartIdx to Lines.Count - 1 do
    begin
      Parts := Lines[i].Split([',', ';', #9]);
      if (Length(Parts) > Max(AValueColumn, ALabelColumn)) then
      begin
        if TryStrToFloat(Parts[AValueColumn], Value) then
        begin
          IsAnomaly := (Parts[ALabelColumn] = '1') or
                       (Parts[ALabelColumn].ToLower = 'true') or
                       (Parts[ALabelColumn].ToLower = 'anomaly');
          AddPoint(Value, IsAnomaly);
        end;
      end;
    end;
  finally
    Lines.Free;
  end;
end;

procedure TLabeledDataset.SaveToCSV(const AFileName: string);
var
  Lines: TStringList;
  Point: TLabeledDataPoint;
begin
  Lines := TStringList.Create;
  try
    Lines.Add('value,is_anomaly,timestamp,description');
    for Point in FData do
    begin
      Lines.Add(Format('%f,%d,%s,%s',
        [Point.Value, Integer(Point.IsAnomaly), DateTimeToStr(Point.Timestamp), Point.Description]));
    end;
    Lines.SaveToFile(AFileName);
  finally
    Lines.Free;
  end;
end;

procedure TLabeledDataset.GenerateNormalData(ACount: Int64; AMean, AStdDev: Double);
var
  i: Int64;
  Value: Double;
begin
  for i := 1 to ACount do
  begin
    // Box-Muller transform for normal distribution
    Value := AMean + AStdDev * Sqrt(-2 * Ln(Random)) * Cos(2 * PI * Random);
    AddPoint(Value, False, 'Normal');
  end;
end;

procedure TLabeledDataset.GenerateAnomalies(ACount: Int64; AMean, AStdDev, ADeviationMultiplier: Double);
var
  i: Int64;
  Value: Double;
begin
  for i := 1 to ACount do
  begin
    // Generate values far from mean
    if Random < 0.5 then
      Value := AMean + (AStdDev * ADeviationMultiplier * (1 + Random))
    else
      Value := AMean - (AStdDev * ADeviationMultiplier * (1 + Random));

    AddPoint(Value, True, 'Anomaly');
  end;
end;

procedure TLabeledDataset.GenerateMixedDataset(ANormalCount, AAnomalyCount: Int64; AMean, AStdDev: Double);
begin
  GenerateNormalData(ANormalCount, AMean, AStdDev);
  GenerateAnomalies(AAnomalyCount, AMean, AStdDev);

  // Shuffle the dataset
  // Simple Fisher-Yates shuffle
  var i, j: Integer;
  var Temp: TLabeledDataPoint;
  for i := FData.Count - 1 downto 1 do
  begin
    j := Random(i + 1);
    Temp := FData[i];
    FData[i] := FData[j];
    FData[j] := Temp;
  end;
end;

function TLabeledDataset.GetAnomalyCount: Int64;
var
  Point: TLabeledDataPoint;
begin
  Result := 0;
  for Point in FData do
    if Point.IsAnomaly then
      Inc(Result);
end;

function TLabeledDataset.GetNormalCount: Int64;
begin
  Result := FData.Count - GetAnomalyCount;
end;

function TLabeledDataset.GetAnomalyPercentage: Double;
begin
  if FData.Count > 0 then
    Result := (GetAnomalyCount / FData.Count) * 100
  else
    Result := 0;
end;

{ TAnomalyDetectorEvaluator }

constructor TAnomalyDetectorEvaluator.Create(ADetector: IAnomalyDetector; ADataset: TLabeledDataset);
begin
  inherited Create;
  FDetector := ADetector;
  FDataset := ADataset;
  FVerbose := False;
end;

function TAnomalyDetectorEvaluator.Evaluate: TEvaluationResult;
var
  StartTime: TDateTime;
  Point: TLabeledDataPoint;
  DetectionResult: TAnomalyResult;
  Matrix: TConfusionMatrix;
begin
  StartTime := Now;
  Matrix.Reset;

  // Validate dataset
  if FDataset.Data.Count = 0 then
    raise EAnomalyDetectionException.Create('Evaluate: Dataset is empty');

  if FVerbose then
    WriteLn('Starting evaluation on ', FDataset.Data.Count, ' data points...');

  for Point in FDataset.Data do
  begin
    DetectionResult := FDetector.Detect(Point.Value);

    // Update confusion matrix
    if Point.IsAnomaly then
    begin
      if DetectionResult.IsAnomaly then
        Inc(Matrix.TruePositives)
      else
        Inc(Matrix.FalseNegatives);
    end
    else
    begin
      if DetectionResult.IsAnomaly then
        Inc(Matrix.FalsePositives)
      else
        Inc(Matrix.TrueNegatives);
    end;
  end;

  Result.ConfusionMatrix := Matrix;
  Result.DatasetSize := FDataset.Data.Count;
  Result.AnomaliesInDataset := FDataset.GetAnomalyCount;
  Result.NormalInDataset := FDataset.GetNormalCount;
  Result.DetectorName := FDetector.Name;
  Result.EvaluationTimeMs := MilliSecondsBetween(Now, StartTime);

  if FVerbose then
  begin
    WriteLn('Evaluation complete!');
    WriteLn(Matrix.ToString);
  end;
end;

function TAnomalyDetectorEvaluator.EvaluateWithTrainTestSplit(ATrainRatio: Double): TEvaluationResult;
var
  TrainSize: Integer;
  i: Integer;
  TrainData: TArray<Double>;
begin
  // Validate inputs
  if FDataset.Data.Count = 0 then
    raise EAnomalyDetectionException.Create('EvaluateWithTrainTestSplit: Dataset is empty');

  if (ATrainRatio <= 0) or (ATrainRatio >= 1) then
    raise EAnomalyDetectionException.Create('Train ratio must be between 0 and 1');

  TrainSize := Trunc(FDataset.Data.Count * ATrainRatio);

  if TrainSize = 0 then
    raise EAnomalyDetectionException.Create('Train size too small (need at least 1 sample for training)');

  if (FDataset.Data.Count - TrainSize) = 0 then
    raise EAnomalyDetectionException.Create('Test size too small (need at least 1 sample for testing)');

  if FVerbose then
    WriteLn(Format('Train/Test split: %d train, %d test', [TrainSize, FDataset.Data.Count - TrainSize]));

  // Train on first portion (assuming normal data)
  SetLength(TrainData, TrainSize);
  for i := 0 to TrainSize - 1 do
    TrainData[i] := FDataset.Data[i].Value;

  FDetector.AddValues(TrainData);
  FDetector.Build;

  // Create temporary dataset with test data only
  var TestDataset := TLabeledDataset.Create('Test Set');
  try
    for i := TrainSize to FDataset.Data.Count - 1 do
      TestDataset.Data.Add(FDataset.Data[i]);

    // Evaluate on test set
    var OriginalDataset := FDataset;
    FDataset := TestDataset;
    try
      Result := Evaluate;
    finally
      FDataset := OriginalDataset;
    end;
  finally
    TestDataset.Free;
  end;
end;

function TAnomalyDetectorEvaluator.CrossValidate(AFolds: Integer): TArray<TEvaluationResult>;
var
  FoldSize, i, FoldStart, FoldEnd: Integer;
  TrainData: TList<Double>;
  TestDataset: TLabeledDataset;
  j: Integer;
begin
  // Validate inputs
  if FDataset.Data.Count = 0 then
    raise EAnomalyDetectionException.Create('CrossValidate: Dataset is empty');

  if AFolds < 2 then
    raise EAnomalyDetectionException.Create('Number of folds must be at least 2');

  if AFolds > FDataset.Data.Count then
    raise EAnomalyDetectionException.Create(
      Format('Number of folds (%d) cannot exceed dataset size (%d)', [AFolds, FDataset.Data.Count]));

  SetLength(Result, AFolds);
  FoldSize := FDataset.Data.Count div AFolds;

  if FoldSize = 0 then
    raise EAnomalyDetectionException.Create(
      Format('Fold size too small (dataset: %d, folds: %d). Need more data or fewer folds.',
        [FDataset.Data.Count, AFolds]));

  if FVerbose then
    WriteLn(Format('Starting %d-fold cross-validation...', [AFolds]));

  for i := 0 to AFolds - 1 do
  begin
    if FVerbose then
      WriteLn(Format('  Fold %d/%d', [i + 1, AFolds]));

    FoldStart := i * FoldSize;
    FoldEnd := FoldStart + FoldSize - 1;
    if i = AFolds - 1 then
      FoldEnd := FDataset.Data.Count - 1;

    // Prepare training data (all except current fold)
    TrainData := TList<Double>.Create;
    TestDataset := TLabeledDataset.Create(Format('Fold %d', [i + 1]));
    try
      for j := 0 to FDataset.Data.Count - 1 do
      begin
        if (j < FoldStart) or (j > FoldEnd) then
          TrainData.Add(FDataset.Data[j].Value)
        else
          TestDataset.Data.Add(FDataset.Data[j]);
      end;

      // Train detector
      FDetector.AddValues(TrainData.ToArray);
      FDetector.Build;

      // Evaluate on test fold
      var OriginalDataset := FDataset;
      FDataset := TestDataset;
      try
        Result[i] := Evaluate;
      finally
        FDataset := OriginalDataset;
      end;
    finally
      TrainData.Free;
      TestDataset.Free;
    end;
  end;
end;

function TAnomalyDetectorEvaluator.GenerateReport(const AResult: TEvaluationResult): string;
begin
  Result := AResult.GetSummary;
end;

function TAnomalyDetectorEvaluator.GenerateCrossValidationReport(const AResults: TArray<TEvaluationResult>): string;
var
  i: Integer;
  AvgAccuracy, AvgPrecision, AvgRecall, AvgF1: Double;
begin
  Result := Format('Cross-Validation Results (%d folds):', [Length(AResults)]) + sLineBreak;
  Result := Result + '=' + StringOfChar('=', 60) + sLineBreak + sLineBreak;

  AvgAccuracy := 0;
  AvgPrecision := 0;
  AvgRecall := 0;
  AvgF1 := 0;

  for i := 0 to High(AResults) do
  begin
    Result := Result + Format('Fold %d: %s', [i + 1, AResults[i].ConfusionMatrix.ToString]) + sLineBreak;
    AvgAccuracy := AvgAccuracy + AResults[i].ConfusionMatrix.GetAccuracy;
    AvgPrecision := AvgPrecision + AResults[i].ConfusionMatrix.GetPrecision;
    AvgRecall := AvgRecall + AResults[i].ConfusionMatrix.GetRecall;
    AvgF1 := AvgF1 + AResults[i].ConfusionMatrix.GetF1Score;
  end;

  AvgAccuracy := AvgAccuracy / Length(AResults);
  AvgPrecision := AvgPrecision / Length(AResults);
  AvgRecall := AvgRecall / Length(AResults);
  AvgF1 := AvgF1 / Length(AResults);

  Result := Result + sLineBreak;
  Result := Result + 'Average Metrics:' + sLineBreak;
  Result := Result + Format('  Accuracy:  %.3f', [AvgAccuracy]) + sLineBreak;
  Result := Result + Format('  Precision: %.3f', [AvgPrecision]) + sLineBreak;
  Result := Result + Format('  Recall:    %.3f', [AvgRecall]) + sLineBreak;
  Result := Result + Format('  F1-Score:  %.3f', [AvgF1]) + sLineBreak;
end;

{ THyperparameterConfig }

class function THyperparameterConfig.Default: THyperparameterConfig;
begin
  Result.Name := 'Default';
  Result.SigmaMultiplier := 3.0;
  Result.MinStdDev := 0.001;
  Result.WindowSize := 100;
  Result.Alpha := 0.3;
  Result.LearningRate := 0.1;
  Result.NumTrees := 100;
  Result.SampleSize := 256;
end;

{ TTuningResult }

function TTuningResult.ToString: string;
begin
  Result := Format('%s: Score=%.3f | %s',
    [Config.Name, Score, EvaluationResult.ConfusionMatrix.ToString]);
end;

{ THyperparameterTuner }

constructor THyperparameterTuner.Create(ADetectorType: TAnomalyDetectorType; ADataset: TLabeledDataset);
begin
  inherited Create;
  FDetectorType := ADetectorType;
  FDataset := ADataset;
  FOptimizationMetric := 'F1';
  FResults := TList<TTuningResult>.Create;
  FVerbose := False;
end;

destructor THyperparameterTuner.Destroy;
begin
  FResults.Free;
  inherited;
end;

function THyperparameterTuner.CreateDetectorWithConfig(const AConfig: THyperparameterConfig): IAnomalyDetector;
var
  DetConfig: TAnomalyDetectionConfig;
  TrainData: TArray<Double>;
  i: Integer;
begin
  DetConfig.SigmaMultiplier := AConfig.SigmaMultiplier;
  DetConfig.MinStdDev := AConfig.MinStdDev;

  case FDetectorType of
    adtThreeSigma:
      Result := TAnomalyDetectorFactory.CreateThreeSigma(DetConfig);
    adtSlidingWindow:
      Result := TAnomalyDetectorFactory.CreateSlidingWindow(AConfig.WindowSize, DetConfig);
    adtEMA:
      Result := TAnomalyDetectorFactory.CreateEMA(AConfig.Alpha, DetConfig);
    adtAdaptive:
      Result := TAnomalyDetectorFactory.CreateAdaptive(AConfig.WindowSize, AConfig.LearningRate, DetConfig);
    adtIsolationForest:
      Result := TAnomalyDetectorFactory.CreateIsolationForest(AConfig.NumTrees, AConfig.SampleSize, AConfig.NumTrees, DetConfig);
  else
    raise EAnomalyDetectionException.Create('Unsupported detector type for tuning');
  end;

  // Train detector with all normal data from dataset
  SetLength(TrainData, 0);
  for i := 0 to FDataset.Data.Count - 1 do
  begin
    if not FDataset.Data[i].IsAnomaly then
    begin
      SetLength(TrainData, Length(TrainData) + 1);
      TrainData[High(TrainData)] := FDataset.Data[i].Value;
    end;
  end;

  if Length(TrainData) > 0 then
  begin
    Result.AddValues(TrainData);
    Result.Build;
  end;
end;

function THyperparameterTuner.GetScoreFromResult(const AResult: TEvaluationResult): Double;
begin
  if FOptimizationMetric = 'F1' then
    Result := AResult.ConfusionMatrix.GetF1Score
  else if FOptimizationMetric = 'Precision' then
    Result := AResult.ConfusionMatrix.GetPrecision
  else if FOptimizationMetric = 'Recall' then
    Result := AResult.ConfusionMatrix.GetRecall
  else if FOptimizationMetric = 'Accuracy' then
    Result := AResult.ConfusionMatrix.GetAccuracy
  else
    Result := AResult.ConfusionMatrix.GetF1Score;  // Default to F1
end;

function THyperparameterTuner.GridSearch(
  const ASigmaMultipliers: TArray<Double>;
  const AMinStdDevs: TArray<Double>;
  const AWindowSizes: TArray<Integer>;
  const AAlphas: TArray<Double>): TTuningResult;
var
  BestResult: TTuningResult;
  CurrentResult: TTuningResult;
  Config: THyperparameterConfig;
  Detector: IAnomalyDetector;
  Evaluator: TAnomalyDetectorEvaluator;
  i, j, k, l, TotalCombinations, CurrentIteration: Integer;
  MinStdDevArray: TArray<Double>;
  WindowArray: TArray<Integer>;
  AlphaArray: TArray<Double>;
begin
  FResults.Clear;
  BestResult.Score := -1;

  // Validate input
  if Length(ASigmaMultipliers) = 0 then
    raise EAnomalyDetectionException.Create('GridSearch: ASigmaMultipliers cannot be empty');

  // Calculate total combinations
  TotalCombinations := Length(ASigmaMultipliers);
  if Length(AMinStdDevs) > 0 then TotalCombinations := TotalCombinations * Length(AMinStdDevs);
  if Length(AWindowSizes) > 0 then TotalCombinations := TotalCombinations * Length(AWindowSizes);
  if Length(AAlphas) > 0 then TotalCombinations := TotalCombinations * Length(AAlphas);

  if FVerbose then
    WriteLn(Format('Grid Search: Testing %d configurations...', [TotalCombinations]));

  CurrentIteration := 0;
  Config := THyperparameterConfig.Default;

  // Iterate over all combinations
  for i := 0 to High(ASigmaMultipliers) do
  begin
    Config.SigmaMultiplier := ASigmaMultipliers[i];

    if Length(AMinStdDevs) = 0 then
      SetLength(MinStdDevArray, 1)
    else
      MinStdDevArray := AMinStdDevs;

    for j := 0 to High(MinStdDevArray) do
    begin
      if Length(AMinStdDevs) > 0 then
        Config.MinStdDev := AMinStdDevs[j];

      if Length(AWindowSizes) = 0 then
        SetLength(WindowArray, 1)
      else
        WindowArray := AWindowSizes;

      for k := 0 to High(WindowArray) do
      begin
        if Length(AWindowSizes) > 0 then
          Config.WindowSize := AWindowSizes[k];

        if Length(AAlphas) = 0 then
          SetLength(AlphaArray, 1)
        else
          AlphaArray := AAlphas;

        for l := 0 to High(AlphaArray) do
        begin
          if Length(AAlphas) > 0 then
            Config.Alpha := AAlphas[l];

          Inc(CurrentIteration);
          Config.Name := Format('Config_%d', [CurrentIteration]);

          if FVerbose then
            WriteLn(Format('  [%d/%d] Testing: Sigma=%.2f, MinStd=%.4f, Window=%d, Alpha=%.2f',
              [CurrentIteration, TotalCombinations, Config.SigmaMultiplier, Config.MinStdDev,
               Config.WindowSize, Config.Alpha]));

          // Create and evaluate detector
          Detector := CreateDetectorWithConfig(Config);
          Evaluator := TAnomalyDetectorEvaluator.Create(Detector, FDataset);
          try
            CurrentResult.Config := Config;
            CurrentResult.EvaluationResult := Evaluator.Evaluate;
            CurrentResult.Score := GetScoreFromResult(CurrentResult.EvaluationResult);

            FResults.Add(CurrentResult);

            if CurrentResult.Score > BestResult.Score then
            begin
              BestResult := CurrentResult;
              if FVerbose then
                WriteLn(Format('    New best! Score: %.3f', [BestResult.Score]));
            end;
          finally
            Evaluator.Free;
          end;
        end;
      end;
    end;
  end;

  Result := BestResult;

  if FVerbose then
  begin
    WriteLn;
    WriteLn('Grid Search Complete!');
    WriteLn('Best configuration: ', Result.ToString);
  end;
end;

function THyperparameterTuner.RandomSearch(AIterations: Integer): TTuningResult;
var
  BestResult, CurrentResult: TTuningResult;
  Config: THyperparameterConfig;
  Detector: IAnomalyDetector;
  Evaluator: TAnomalyDetectorEvaluator;
  i: Integer;
begin
  FResults.Clear;
  BestResult.Score := -1;

  // Validate input
  if AIterations <= 0 then
    raise EAnomalyDetectionException.Create('RandomSearch: AIterations must be > 0');

  if FVerbose then
    WriteLn(Format('Random Search: Testing %d random configurations...', [AIterations]));

  for i := 1 to AIterations do
  begin
    // Generate random configuration
    Config := THyperparameterConfig.Default;
    Config.Name := Format('Random_%d', [i]);
    Config.SigmaMultiplier := 2.0 + Random * 2.0;  // 2.0 to 4.0
    Config.MinStdDev := 0.0001 + Random * 0.01;     // 0.0001 to 0.0101
    Config.WindowSize := 50 + Random(150);          // 50 to 200
    Config.Alpha := 0.1 + Random * 0.4;             // 0.1 to 0.5
    Config.LearningRate := 0.01 + Random * 0.19;    // 0.01 to 0.2

    if FVerbose then
      WriteLn(Format('  [%d/%d] Testing random config: Sigma=%.2f, Window=%d, Alpha=%.2f',
        [i, AIterations, Config.SigmaMultiplier, Config.WindowSize, Config.Alpha]));

    // Create and evaluate
    Detector := CreateDetectorWithConfig(Config);
    Evaluator := TAnomalyDetectorEvaluator.Create(Detector, FDataset);
    try
      CurrentResult.Config := Config;
      CurrentResult.EvaluationResult := Evaluator.Evaluate;
      CurrentResult.Score := GetScoreFromResult(CurrentResult.EvaluationResult);

      FResults.Add(CurrentResult);

      if CurrentResult.Score > BestResult.Score then
      begin
        BestResult := CurrentResult;
        if FVerbose then
          WriteLn(Format('    New best! Score: %.3f', [BestResult.Score]));
      end;
    finally
      Evaluator.Free;
    end;
  end;

  Result := BestResult;

  if FVerbose then
  begin
    WriteLn;
    WriteLn('Random Search Complete!');
    WriteLn('Best configuration: ', Result.ToString);
  end;
end;

function THyperparameterTuner.GetTopConfigurations(ACount: Integer): TArray<TTuningResult>;
var
  SortedResults: TList<TTuningResult>;
  i: Integer;
begin
  // Validate input
  if ACount <= 0 then
    raise EAnomalyDetectionException.Create('GetTopConfigurations: ACount must be > 0');

  if FResults.Count = 0 then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  SortedResults := TList<TTuningResult>.Create(FResults);
  try
    SortedResults.Sort(TComparer<TTuningResult>.Construct(
      function(const Left, Right: TTuningResult): Integer
      begin
        Result := CompareValue(Right.Score, Left.Score);  // Descending order
      end
    ));

    SetLength(Result, Min(ACount, SortedResults.Count));
    for i := 0 to High(Result) do
      Result[i] := SortedResults[i];
  finally
    SortedResults.Free;
  end;
end;

function THyperparameterTuner.GenerateTuningReport: string;
var
  TopConfigs: TArray<TTuningResult>;
  i: Integer;
begin
  Result := Format('Hyperparameter Tuning Report (%s optimization)', [FOptimizationMetric]) + sLineBreak;
  Result := Result + '=' + StringOfChar('=', 70) + sLineBreak;
  Result := Result + Format('Total configurations tested: %d', [FResults.Count]) + sLineBreak;
  Result := Result + Format('Dataset: %s (%d points)', [FDataset.Name, FDataset.Data.Count]) + sLineBreak;
  Result := Result + sLineBreak;

  TopConfigs := GetTopConfigurations(5);
  Result := Result + 'Top 5 Configurations:' + sLineBreak;
  Result := Result + '-' + StringOfChar('-', 70) + sLineBreak;

  for i := 0 to High(TopConfigs) do
  begin
    Result := Result + Format('%d. %s', [i + 1, TopConfigs[i].ToString]) + sLineBreak;
    Result := Result + Format('   Sigma=%.2f, MinStdDev=%.4f, Window=%d, Alpha=%.2f',
      [TopConfigs[i].Config.SigmaMultiplier, TopConfigs[i].Config.MinStdDev,
       TopConfigs[i].Config.WindowSize, TopConfigs[i].Config.Alpha]) + sLineBreak;
    Result := Result + sLineBreak;
  end;
end;

end.
