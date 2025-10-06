// ***************************************************************************
//
// Copyright (c) 2025 Daniele Teti - All Rights Reserved
//
// Isolation Forest Anomaly Detector
// ML-based approach for multi-dimensional anomaly detection
//
// ***************************************************************************

unit AnomalyDetection.IsolationForest;

interface

uses
  System.SysUtils, System.Classes, System.Math, System.Generics.Collections,
  System.SyncObjs,
  AnomalyDetection.Types,
  AnomalyDetection.Base;

type
  /// <summary>
  /// Node of an Isolation Tree
  /// </summary>
  TIsolationTreeNode = class
  private
    FLeft: TIsolationTreeNode;
    FRight: TIsolationTreeNode;
    FSplitAttribute: Integer;
    FSplitValue: Double;
    FSize: Integer;
    FIsLeaf: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function IsLeaf: Boolean;
    property Left: TIsolationTreeNode read FLeft write FLeft;
    property Right: TIsolationTreeNode read FRight write FRight;
    property SplitAttribute: Integer read FSplitAttribute write FSplitAttribute;
    property SplitValue: Double read FSplitValue write FSplitValue;
    property Size: Integer read FSize write FSize;
  end;

  /// <summary>
  /// Single Isolation Tree
  /// </summary>
  TIsolationTree = class
  private
    FRoot: TIsolationTreeNode;
    FMaxDepth: Integer;
    procedure BuildTree(ANode: TIsolationTreeNode; const AData: TArray<TArray<Double>>;
                       const AIndices: TArray<Integer>; ACurrentDepth: Integer);
    function GetRandomSplit(const AData: TArray<TArray<Double>>;
                           const AIndices: TArray<Integer>): TPair<Integer, Double>;
  public
    constructor Create(AMaxDepth: Integer = 10);
    destructor Destroy; override;
    procedure Train(const AData: TArray<TArray<Double>>);
    function GetPathLength(const AInstance: TArray<Double>): Double;
    function CalculateAveragePathLength(ASize: Integer): Double;
    property Root: TIsolationTreeNode read FRoot;
  end;

  /// <summary>
  /// Isolation Forest anomaly detector
  /// Excellent for high-dimensional data and unsupervised detection
  /// </summary>
  TIsolationForestDetector = class(TBaseAnomalyDetector, IDensityAnomalyDetector)
  private
    FTrees: TObjectList<TIsolationTree>;
    FNumTrees: Integer;
    FSubSampleSize: Integer;
    FMaxDepth: Integer;
    FTrainingData: TArray<TArray<Double>>;
    FIsTrained: Boolean;
    FAveragePathLength: Double;
    FFeatureCount: Integer;
    FAutoTrainThreshold: Integer;
    FThreshold: Double;
    function CalculateAnomalyScore(const AInstance: TArray<Double>): Double;
    function CalculateAveragePathLength(ASize: Integer): Double;
    procedure EnsureTrainingData;
    procedure CalculateOptimalThreshold;

    // Interface implementation
    function GetDimensions: Integer;
  protected
    procedure CheckAndNotifyAnomaly(const AResult: TAnomalyResult);
  public
    constructor Create(ANumTrees: Integer = 100; ASubSampleSize: Integer = 256;
                      AMaxDepth: Integer = 10); overload;
    constructor Create(ANumTrees: Integer; ASubSampleSize: Integer; AMaxDepth: Integer;
                      const AConfig: TAnomalyDetectionConfig); overload;
    destructor Destroy; override;

    procedure AddTrainingData(const AInstance: TArray<Double>);
    procedure Train;
    procedure TrainFromDataset(const ADataset: TArray<TArray<Double>>);
    procedure TrainForFraudDetection(const ATransactionData: TArray<TArray<Double>>);
    procedure TrainForMultiSensorData(const ASensorData: TArray<TArray<Double>>);
    procedure TrainFromCSV(const AFileName: string; ASkipHeader: Boolean = False);
    procedure FinalizeTraining;
    function Detect(const AValue: Double): TAnomalyResult; override;
    function DetectMultiDimensional(const AInstance: TArray<Double>): TAnomalyResult;

    procedure SaveState(const AStream: TStream); override;
    procedure LoadState(const AStream: TStream); override;

    function IsInitialized: Boolean; override;
    property NumTrees: Integer read FNumTrees;
    property SubSampleSize: Integer read FSubSampleSize;
    property IsTrained: Boolean read FIsTrained;
    property FeatureCount: Integer read FFeatureCount;
    property AutoTrainThreshold: Integer read FAutoTrainThreshold write FAutoTrainThreshold;
    property Threshold: Double read FThreshold write FThreshold;
  end;

implementation

{ TIsolationTreeNode }

constructor TIsolationTreeNode.Create;
begin
  inherited Create;
  FLeft := nil;
  FRight := nil;
  FSplitAttribute := -1;
  FSplitValue := 0;
  FSize := 0;
  FIsLeaf := True;
end;

destructor TIsolationTreeNode.Destroy;
begin
  FLeft.Free;
  FRight.Free;
  inherited Destroy;
end;

function TIsolationTreeNode.IsLeaf: Boolean;
begin
  Result := (FLeft = nil) and (FRight = nil);
end;

{ TIsolationTree }

constructor TIsolationTree.Create(AMaxDepth: Integer);
begin
  inherited Create;
  FMaxDepth := AMaxDepth;
  FRoot := nil;
end;

destructor TIsolationTree.Destroy;
begin
  FRoot.Free;
  inherited Destroy;
end;

procedure TIsolationTree.Train(const AData: TArray<TArray<Double>>);
var
  Indices: TArray<Integer>;
  i: Integer;
begin
  if Length(AData) = 0 then
    raise EAnomalyDetectionException.Create('Training data cannot be empty');

  // Inizializza gli indici
  SetLength(Indices, Length(AData));
  for i := 0 to High(Indices) do
    Indices[i] := i;

  // Costruisci l'albero
  FRoot := TIsolationTreeNode.Create;
  BuildTree(FRoot, AData, Indices, 0);
end;

procedure TIsolationTree.BuildTree(ANode: TIsolationTreeNode;
  const AData: TArray<TArray<Double>>; const AIndices: TArray<Integer>;
  ACurrentDepth: Integer);
var
  SplitInfo: TPair<Integer, Double>;
  LeftIndices, RightIndices: TArray<Integer>;
  LeftCount, RightCount: Integer;
  i: Integer;
begin
  ANode.FSize := Length(AIndices);

  // Condizioni di terminazione
  if (Length(AIndices) <= 1) or (ACurrentDepth >= FMaxDepth) then
  begin
    ANode.FIsLeaf := True;
    Exit;
  end;

  // Trova uno split casuale
  SplitInfo := GetRandomSplit(AData, AIndices);
  ANode.FSplitAttribute := SplitInfo.Key;
  ANode.FSplitValue := SplitInfo.Value;
  ANode.FIsLeaf := False;

  // Dividi i dati
  SetLength(LeftIndices, Length(AIndices));
  SetLength(RightIndices, Length(AIndices));
  LeftCount := 0;
  RightCount := 0;

  for i := 0 to High(AIndices) do
  begin
    if AData[AIndices[i]][ANode.FSplitAttribute] < ANode.FSplitValue then
    begin
      LeftIndices[LeftCount] := AIndices[i];
      Inc(LeftCount);
    end
    else
    begin
      RightIndices[RightCount] := AIndices[i];
      Inc(RightCount);
    end;
  end;

  SetLength(LeftIndices, LeftCount);
  SetLength(RightIndices, RightCount);

  // Ricorsione sui figli
  if LeftCount > 0 then
  begin
    ANode.FLeft := TIsolationTreeNode.Create;
    BuildTree(ANode.FLeft, AData, LeftIndices, ACurrentDepth + 1);
  end;

  if RightCount > 0 then
  begin
    ANode.FRight := TIsolationTreeNode.Create;
    BuildTree(ANode.FRight, AData, RightIndices, ACurrentDepth + 1);
  end;
end;

function TIsolationTree.GetRandomSplit(const AData: TArray<TArray<Double>>;
  const AIndices: TArray<Integer>): TPair<Integer, Double>;
var
  Attribute: Integer;
  MinVal, MaxVal, SplitVal: Double;
  i: Integer;
begin
  // Scegli un attributo casuale
  if Length(AData) > 0 then
    Attribute := Random(Length(AData[0]))
  else
    Attribute := 0;

  // Trova min e max per quell'attributo
  MinVal := AData[AIndices[0]][Attribute];
  MaxVal := MinVal;

  for i := 1 to High(AIndices) do
  begin
    var Val := AData[AIndices[i]][Attribute];
    if Val < MinVal then MinVal := Val;
    if Val > MaxVal then MaxVal := Val;
  end;

  // Genera uno split casuale
  if MaxVal > MinVal then
    SplitVal := MinVal + Random * (MaxVal - MinVal)
  else
    SplitVal := MinVal;

  Result := TPair<Integer, Double>.Create(Attribute, SplitVal);
end;

function TIsolationTree.CalculateAveragePathLength(ASize: Integer): Double;
begin
  if ASize > 2 then
    Result := 2.0 * (Ln(ASize - 1) + 0.5772156649) - (2.0 * (ASize - 1) / ASize) // Eulero-Mascheroni constant
  else if ASize = 2 then
    Result := 1.0
  else
    Result := 0.0;
end;

function TIsolationTree.GetPathLength(const AInstance: TArray<Double>): Double;
var
  CurrentNode: TIsolationTreeNode;
  PathLength: Integer;
begin
  CurrentNode := FRoot;
  PathLength := 0;

  while (CurrentNode <> nil) and not CurrentNode.IsLeaf do
  begin
    if AInstance[CurrentNode.FSplitAttribute] < CurrentNode.FSplitValue then
      CurrentNode := CurrentNode.FLeft
    else
      CurrentNode := CurrentNode.FRight;

    Inc(PathLength);
  end;

  // Aggiungi la stima per il sottoalbero non esplorato
  if CurrentNode <> nil then
    Result := PathLength + CalculateAveragePathLength(CurrentNode.FSize)
  else
    Result := PathLength;
end;

{ TIsolationForestDetector }

constructor TIsolationForestDetector.Create(ANumTrees: Integer;
  ASubSampleSize: Integer; AMaxDepth: Integer);
begin
  Create(ANumTrees, ASubSampleSize, AMaxDepth, TAnomalyDetectionConfig.Default);
end;

constructor TIsolationForestDetector.Create(ANumTrees: Integer;
  ASubSampleSize: Integer; AMaxDepth: Integer; const AConfig: TAnomalyDetectionConfig);
begin
  inherited Create('Isolation Forest Detector', AConfig);
  FNumTrees := ANumTrees;
  FSubSampleSize := ASubSampleSize;
  FMaxDepth := AMaxDepth;
  FTrees := TObjectList<TIsolationTree>.Create(True);
  FIsTrained := False;
  FAveragePathLength := 0;
  FFeatureCount := 1; // Default per dati 1D
  FAutoTrainThreshold := 256; // Default threshold
  FThreshold := 0.5; // Default threshold, sarà ricalcolata
  SetLength(FTrainingData, 0);
end;

destructor TIsolationForestDetector.Destroy;
begin
  FTrees.Free;
  inherited Destroy;
end;

procedure TIsolationForestDetector.AddTrainingData(const AInstance: TArray<Double>);
var
  NewLength: Integer;
begin
  FLock.Enter;
  try
    NewLength := Length(FTrainingData);
    SetLength(FTrainingData, NewLength + 1);
    SetLength(FTrainingData[NewLength], Length(AInstance));

    for var i := 0 to High(AInstance) do
      FTrainingData[NewLength][i] := AInstance[i];

    FFeatureCount := Length(AInstance);
    FIsTrained := False; // Require retraining

    // Auto-train se raggiungiamo la soglia
    if Length(FTrainingData) >= FAutoTrainThreshold then
    begin
      Train;
      CalculateOptimalThreshold;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TIsolationForestDetector.Train;
var
  i, j: Integer;
  SubSample: TArray<TArray<Double>>;
  SampleIndices: TArray<Integer>;
  Tree: TIsolationTree;
  ActualSubSampleSize: Integer;
begin
  FLock.Enter;
  try
    if Length(FTrainingData) = 0 then
      raise EAnomalyDetectionException.Create('No training data available');

    FTrees.Clear;

    ActualSubSampleSize := Min(FSubSampleSize, Length(FTrainingData));
    FAveragePathLength := CalculateAveragePathLength(ActualSubSampleSize);

    for i := 1 to FNumTrees do
    begin
      // Crea un subsample casuale
      SetLength(SampleIndices, Length(FTrainingData));
      for j := 0 to High(SampleIndices) do
        SampleIndices[j] := j;

      // Shuffle
      for j := High(SampleIndices) downto 1 do
      begin
        var k := Random(j + 1);
        var temp := SampleIndices[j];
        SampleIndices[j] := SampleIndices[k];
        SampleIndices[k] := temp;
      end;

      // Prendi i primi ActualSubSampleSize elementi
      SetLength(SubSample, ActualSubSampleSize);
      for j := 0 to ActualSubSampleSize - 1 do
      begin
        SetLength(SubSample[j], FFeatureCount);
        for var k := 0 to FFeatureCount - 1 do
          SubSample[j][k] := FTrainingData[SampleIndices[j]][k];
      end;

      // Crea e allena l'albero
      Tree := TIsolationTree.Create(FMaxDepth);
      Tree.Train(SubSample);
      FTrees.Add(Tree);
    end;

    FIsTrained := True;
  finally
    FLock.Leave;
  end;
end;

procedure TIsolationForestDetector.TrainFromDataset(const ADataset: TArray<TArray<Double>>);
var
  i, j: Integer;
  OldThreshold: Integer;
begin
  FLock.Enter;
  try
    // Disabilita temporaneamente auto-training
    OldThreshold := FAutoTrainThreshold;
    FAutoTrainThreshold := MaxInt;

    // Clear existing training data
    SetLength(FTrainingData, 0);

    // Aggiungi direttamente senza auto-training
    SetLength(FTrainingData, Length(ADataset));
    for i := 0 to High(ADataset) do
    begin
      SetLength(FTrainingData[i], Length(ADataset[i]));
      for j := 0 to High(ADataset[i]) do
        FTrainingData[i][j] := ADataset[i][j];
    end;

    FFeatureCount := Length(ADataset[0]);
    FIsTrained := False;

    // Ripristina threshold
    FAutoTrainThreshold := OldThreshold;

    // Train manualmente
    Train;
    CalculateOptimalThreshold;
  finally
    FLock.Leave;
  end;
end;

procedure TIsolationForestDetector.TrainForFraudDetection(const ATransactionData: TArray<TArray<Double>>);
begin
  TrainFromDataset(ATransactionData);
  FThreshold := 0.55; // Score alto per fraud detection
end;

procedure TIsolationForestDetector.TrainForMultiSensorData(const ASensorData: TArray<TArray<Double>>);
begin
  TrainFromDataset(ASensorData);
  FThreshold := 0.50; // Score alto per sensori guasti
end;

procedure TIsolationForestDetector.TrainFromCSV(const AFileName: string; ASkipHeader: Boolean);
var
  Lines: TStringList;
  i, StartIdx: Integer;
  Values: TArray<String>;
  Instance: TArray<Double>;
  j: Integer;
  FormatSettings: TFormatSettings;
begin
  if not FileExists(AFileName) then
    raise EAnomalyDetectionException.Create('CSV file not found: ' + AFileName);

  FormatSettings := TFormatSettings.Create('en-US'); // Force decimal point
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(AFileName);

    StartIdx := IfThen(ASkipHeader, 1, 0);

    for i := StartIdx to Lines.Count - 1 do
    begin
      if Trim(Lines[i]) = '' then Continue;

      Values := Lines[i].Split([',']);
      SetLength(Instance, Length(Values));

      for j := 0 to High(Values) do
      begin
        try
          Instance[j] := StrToFloat(Trim(Values[j]), FormatSettings);
        except
          on E: EConvertError do
            raise EAnomalyDetectionException.CreateFmt('Invalid numeric value in CSV line %d, column %d: %s',
              [i + 1, j + 1, Values[j]]);
        end;
      end;

      AddTrainingData(Instance);
    end;

    Train;
    CalculateOptimalThreshold;

  finally
    Lines.Free;
  end;
end;

procedure TIsolationForestDetector.FinalizeTraining;
begin
  if Length(FTrainingData) > 0 then
  begin
    Train;
    CalculateOptimalThreshold;
  end;
end;

function TIsolationForestDetector.IsInitialized: Boolean;
begin
  Result := FIsTrained;
end;

procedure TIsolationForestDetector.CalculateOptimalThreshold;
var
  i: Integer;
  Scores: TArray<Double>;
  SortedScores: TArray<Double>;
begin
  if not FIsTrained or (Length(FTrainingData) = 0) then Exit;

  SetLength(Scores, Min(100, Length(FTrainingData)));
  for i := 0 to High(Scores) do
    Scores[i] := CalculateAnomalyScore(FTrainingData[i]);

  SortedScores := Copy(Scores);
  TArray.Sort<Double>(SortedScores);

  // Usa il 90° percentile come soglia (score alto = anomalia)
  var PercentileIndex := Round(Length(SortedScores) * 0.9);
  if PercentileIndex < Length(SortedScores) then
    FThreshold := SortedScores[PercentileIndex]
  else
    FThreshold := 0.5;

  // Per score alti, range 0.5-0.9
  FThreshold := Max(0.5, Min(0.9, FThreshold));
end;

function TIsolationForestDetector.CalculateAveragePathLength(ASize: Integer): Double;
begin
  if ASize > 2 then
    Result := 2.0 * (Ln(ASize - 1) + 0.5772156649) - (2.0 * (ASize - 1) / ASize) // Eulero-Mascheroni constant
  else if ASize = 2 then
    Result := 1.0
  else
    Result := 0.0;
end;

function TIsolationForestDetector.CalculateAnomalyScore(const AInstance: TArray<Double>): Double;
var
  i: Integer;
  TotalPathLength: Double;
  AveragePathLength: Double;
begin
  if not FIsTrained then
    raise EAnomalyDetectionException.Create('Detector must be trained first');

  TotalPathLength := 0;
  for i := 0 to FTrees.Count - 1 do
    TotalPathLength := TotalPathLength + FTrees[i].GetPathLength(AInstance);

  AveragePathLength := TotalPathLength / FTrees.Count;

  // Score normalizzato: più piccolo = più anomalo
  Result := Power(2, -AveragePathLength / FAveragePathLength);
end;

function TIsolationForestDetector.Detect(const AValue: Double): TAnomalyResult;
var
  Instance: TArray<Double>;
begin
  // Converte valore singolo in array per compatibilità
  SetLength(Instance, 1);
  Instance[0] := AValue;
  Result := DetectMultiDimensional(Instance);
end;

function TIsolationForestDetector.DetectMultiDimensional(const AInstance: TArray<Double>): TAnomalyResult;
var
  AnomalyScore: Double;
begin
  FLock.Enter;
  try
    EnsureTrainingData;
    Result.Value := AInstance[0];
    AnomalyScore := CalculateAnomalyScore(AInstance);

    // CORREGGI: Score ALTO = anomalia
    Result.IsAnomaly := AnomalyScore > FThreshold;  // Cambia da < a >

    Result.ZScore := (AnomalyScore - FThreshold) / 0.2; // Cambia anche questo
    Result.LowerLimit := FThreshold;  // Swap
    Result.UpperLimit := 1.0;         // Swap

    if Result.IsAnomaly then
      Result.Description := Format('ISOLATION FOREST ANOMALY: Score %.4f (threshold %.4f)',
                                  [AnomalyScore, FThreshold])
    else
      Result.Description := Format('Normal: Score %.4f (threshold %.4f)', [AnomalyScore, FThreshold]);

    CheckAndNotifyAnomaly(Result);
  finally
    FLock.Leave;
  end;
end;

procedure TIsolationForestDetector.EnsureTrainingData;
begin
  if not FIsTrained and (Length(FTrainingData) > 0) then
    Train;
end;

procedure TIsolationForestDetector.CheckAndNotifyAnomaly(const AResult: TAnomalyResult);
begin
  if AResult.IsAnomaly and not FLastAnomalyState then
  begin
    NotifyAnomalyEvent(aeAnomalyDetected, AResult);
  end
  else if not AResult.IsAnomaly and FLastAnomalyState then
  begin
    NotifyAnomalyEvent(aeNormalResumed, AResult);
  end;

  FLastAnomalyState := AResult.IsAnomaly;
end;

procedure TIsolationForestDetector.SaveState(const AStream: TStream);
var
  DataCount, i, j: Integer;
begin
  FLock.Enter;
  try
    SaveConfigToStream(AStream);

    // Salva parametri
    AStream.WriteData(FNumTrees);
    AStream.WriteData(FSubSampleSize);
    AStream.WriteData(FMaxDepth);
    AStream.WriteData(FIsTrained);
    AStream.WriteData(FAveragePathLength);
    AStream.WriteData(FFeatureCount);
    AStream.WriteData(FAutoTrainThreshold);
    AStream.WriteData(FThreshold);

    // Salva dati di training
    DataCount := Length(FTrainingData);
    AStream.WriteData(DataCount);
    for i := 0 to DataCount - 1 do
    begin
      var FeatureCount := Length(FTrainingData[i]);
      AStream.WriteData(FeatureCount);
      for j := 0 to FeatureCount - 1 do
        AStream.WriteData(FTrainingData[i][j]);
    end;

    // Nota: Gli alberi non vengono serializzati per semplicità
    // In produzione si potrebbe implementare la serializzazione completa
  finally
    FLock.Leave;
  end;
end;

procedure TIsolationForestDetector.LoadState(const AStream: TStream);
var
  DataCount, i, j, FeatureCount: Integer;
begin
  FLock.Enter;
  try
    LoadConfigFromStream(AStream);

    AStream.ReadData(FNumTrees);
    AStream.ReadData(FSubSampleSize);
    AStream.ReadData(FMaxDepth);
    AStream.ReadData(FIsTrained);
    AStream.ReadData(FAveragePathLength);
    AStream.ReadData(FFeatureCount);
    AStream.ReadData(FAutoTrainThreshold);
    AStream.ReadData(FThreshold);

    // Carica dati di training
    AStream.ReadData(DataCount);
    SetLength(FTrainingData, DataCount);
    for i := 0 to DataCount - 1 do
    begin
      AStream.ReadData(FeatureCount);
      SetLength(FTrainingData[i], FeatureCount);
      for j := 0 to FeatureCount - 1 do
        AStream.ReadData(FTrainingData[i][j]);
    end;

    // Se erano stati allenati, riallena
    if FIsTrained then
    begin
      FIsTrained := False;
      Train;
      CalculateOptimalThreshold;
    end;
  finally
    FLock.Leave;
  end;
end;

// IDensityAnomalyDetector interface implementation

function TIsolationForestDetector.GetDimensions: Integer;
begin
  Result := FFeatureCount;
end;

end.
