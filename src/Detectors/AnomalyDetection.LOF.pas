// ***************************************************************************
//
// Copyright (c) 2025 Daniele Teti - All Rights Reserved
//
// Local Outlier Factor (LOF) Detector
// Density-based anomaly detection using local neighborhood comparison
//
// ***************************************************************************

unit AnomalyDetection.LOF;

interface

uses
  System.SysUtils, System.Classes, System.Math, System.SyncObjs,
  System.Generics.Collections,
  AnomalyDetection.Types,
  AnomalyDetection.Base;

type
  /// <summary>
  /// Data point for LOF algorithm
  /// </summary>
  TLOFPoint = record
    Values: TArray<Double>;
    LOFScore: Double;
    IsProcessed: Boolean;
  end;

  /// <summary>
  /// Local Outlier Factor (LOF) detector
  /// Best for: Finding local anomalies in multi-dimensional data where global methods fail
  /// </summary>
  /// <remarks>
  /// LOF compares the local density of a point with the local densities of its neighbors.
  /// Points that have substantially lower density than their neighbors are considered outliers.
  ///
  /// Key advantages:
  /// - Detects local anomalies (points anomalous in their local neighborhood)
  /// - Handles varying densities in the dataset
  /// - Works well with clusters of different densities
  /// - Multi-dimensional support
  ///
  /// Algorithm steps:
  /// 1. Find k-nearest neighbors for each point
  /// 2. Calculate reachability distance for each point
  /// 3. Compute local reachability density (LRD)
  /// 4. Calculate LOF score by comparing LRD with neighbors
  ///
  /// LOF Score interpretation:
  /// - ~1.0: Point has similar density to neighbors (normal)
  /// - >1.0: Point has lower density than neighbors (potential outlier)
  /// - >>1.0: Point is significantly less dense (strong outlier)
  /// - <1.0: Point is denser than neighbors (inlier)
  /// </remarks>
  TLOFDetector = class(TBaseAnomalyDetector, IDensityAnomalyDetector)
  private
    FDataPoints: TList<TLOFPoint>;
    FKNeighbors: Integer;
    FDimensions: Integer;
    FThreshold: Double;  // LOF threshold for anomaly (default 1.5)
    FMinPts: Integer;    // Minimum points required
    FIsBuilt: Boolean;

    function CalculateDistance(const Point1, Point2: TArray<Double>): Double;
    function FindKNearestNeighbors(const Point: TArray<Double>; K: Integer): TArray<Integer>;
    function CalculateKDistance(PointIndex: Integer; K: Integer): Double;
    function CalculateReachabilityDistance(PointIndex, NeighborIndex: Integer; K: Integer): Double;
    function CalculateLocalReachabilityDensity(PointIndex: Integer; K: Integer): Double;
    function CalculateLOFScore(PointIndex: Integer): Double;
    procedure BuildLOFModel;
    function GetDataPointsCount: Integer;

    // Interface implementation
    function GetDimensions: Integer;
  protected
    procedure CheckAndNotifyAnomaly(const AResult: TAnomalyResult);
  public
    // IDensityAnomalyDetector interface methods
    procedure AddTrainingData(const AInstance: TArray<Double>);
    procedure Train;
    constructor Create(AKNeighbors: Integer = 20; ADimensions: Integer = 1); overload;
    constructor Create(AKNeighbors: Integer; ADimensions: Integer; const AConfig: TAnomalyDetectionConfig); overload;
    destructor Destroy; override;

    // Training phase - add multi-dimensional data points
    procedure AddValue(const AValue: Double); override;
    procedure AddValues(const AValues: TArray<Double>); override;
    procedure AddPoint(const APoint: TArray<Double>);
    procedure AddPoints(const APoints: TArray<TArray<Double>>);

    // Build phase - compute LOF scores for all points
    procedure Build; override;

    // Detection phase
    function Detect(const AValue: Double): TAnomalyResult; override;
    function DetectMultiDimensional(const APoint: TArray<Double>): TAnomalyResult;

    // Persistence
    procedure SaveState(const AStream: TStream); override;
    procedure LoadState(const AStream: TStream); override;

    // Utilities
    function IsInitialized: Boolean; override;
    procedure Clear;

    property KNeighbors: Integer read FKNeighbors write FKNeighbors;
    property Dimensions: Integer read FDimensions;
    property Threshold: Double read FThreshold write FThreshold;
    property DataPointsCount: Integer read GetDataPointsCount;
  end;

implementation

{ TLOFDetector }

constructor TLOFDetector.Create(AKNeighbors: Integer = 20; ADimensions: Integer = 1);
begin
  inherited Create('LOF Detector');
  FDataPoints := TList<TLOFPoint>.Create;
  FKNeighbors := AKNeighbors;
  FDimensions := ADimensions;
  FThreshold := 1.5;  // Default: LOF > 1.5 indicates outlier
  FMinPts := AKNeighbors + 1;  // Minimum points needed
  FIsBuilt := False;
end;

constructor TLOFDetector.Create(AKNeighbors: Integer; ADimensions: Integer; const AConfig: TAnomalyDetectionConfig);
begin
  inherited Create('LOF Detector', AConfig);
  FDataPoints := TList<TLOFPoint>.Create;
  FKNeighbors := AKNeighbors;
  FDimensions := ADimensions;
  FThreshold := 1.5;
  FMinPts := AKNeighbors + 1;
  FIsBuilt := False;
end;

destructor TLOFDetector.Destroy;
begin
  FDataPoints.Free;
  inherited;
end;

procedure TLOFDetector.AddValue(const AValue: Double);
var
  Point: TArray<Double>;
begin
  FLock.Enter;
  try
    SetLength(Point, 1);
    Point[0] := AValue;
    AddPoint(Point);
  finally
    FLock.Leave;
  end;
end;

procedure TLOFDetector.AddValues(const AValues: TArray<Double>);
var
  Value: Double;
begin
  for Value in AValues do
    AddValue(Value);
end;

procedure TLOFDetector.AddPoint(const APoint: TArray<Double>);
var
  NewPoint: TLOFPoint;
begin
  FLock.Enter;
  try
    if Length(APoint) <> FDimensions then
      raise EAnomalyDetectionException.CreateFmt(
        'Point dimension mismatch: expected %d, got %d', [FDimensions, Length(APoint)]);

    NewPoint.Values := Copy(APoint);
    NewPoint.LOFScore := 0;
    NewPoint.IsProcessed := False;

    FDataPoints.Add(NewPoint);
    FIsBuilt := False;  // Need to rebuild model
  finally
    FLock.Leave;
  end;
end;

procedure TLOFDetector.AddPoints(const APoints: TArray<TArray<Double>>);
var
  Point: TArray<Double>;
begin
  for Point in APoints do
    AddPoint(Point);
end;

function TLOFDetector.CalculateDistance(const Point1, Point2: TArray<Double>): Double;
var
  i: Integer;
  Sum: Double;
begin
  Sum := 0;
  for i := 0 to High(Point1) do
    Sum := Sum + Sqr(Point1[i] - Point2[i]);
  Result := Sqrt(Sum);
end;

function TLOFDetector.FindKNearestNeighbors(const Point: TArray<Double>; K: Integer): TArray<Integer>;
type
  TDistanceIndex = record
    Distance: Double;
    Index: Integer;
  end;
var
  Distances: TArray<TDistanceIndex>;
  i, j: Integer;
  Temp: TDistanceIndex;
begin
  // Calculate distances to all points
  SetLength(Distances, FDataPoints.Count);
  for i := 0 to FDataPoints.Count - 1 do
  begin
    Distances[i].Distance := CalculateDistance(Point, FDataPoints[i].Values);
    Distances[i].Index := i;
  end;

  // Sort by distance (simple bubble sort for clarity)
  for i := 0 to Length(Distances) - 2 do
    for j := i + 1 to Length(Distances) - 1 do
      if Distances[j].Distance < Distances[i].Distance then
      begin
        Temp := Distances[i];
        Distances[i] := Distances[j];
        Distances[j] := Temp;
      end;

  // Return indices of K nearest neighbors (excluding point itself if distance=0)
  SetLength(Result, K);
  j := 0;
  i := 0;
  while (j < K) and (i < Length(Distances)) do
  begin
    if Distances[i].Distance > 0 then  // Skip the point itself
    begin
      Result[j] := Distances[i].Index;
      Inc(j);
    end;
    Inc(i);
  end;

  // If not enough neighbors, fill with what we have
  if j < K then
    SetLength(Result, j);
end;

function TLOFDetector.CalculateKDistance(PointIndex: Integer; K: Integer): Double;
var
  Neighbors: TArray<Integer>;
  MaxDist: Double;
  i: Integer;
begin
  Neighbors := FindKNearestNeighbors(FDataPoints[PointIndex].Values, K);

  MaxDist := 0;
  for i := 0 to High(Neighbors) do
  begin
    var Dist := CalculateDistance(FDataPoints[PointIndex].Values, FDataPoints[Neighbors[i]].Values);
    if Dist > MaxDist then
      MaxDist := Dist;
  end;

  Result := MaxDist;
end;

function TLOFDetector.CalculateReachabilityDistance(PointIndex, NeighborIndex: Integer; K: Integer): Double;
var
  DirectDistance: Double;
  KDist: Double;
begin
  DirectDistance := CalculateDistance(FDataPoints[PointIndex].Values, FDataPoints[NeighborIndex].Values);
  KDist := CalculateKDistance(NeighborIndex, K);

  // Reachability distance is max of direct distance and k-distance of neighbor
  Result := Max(DirectDistance, KDist);
end;

function TLOFDetector.CalculateLocalReachabilityDensity(PointIndex: Integer; K: Integer): Double;
var
  Neighbors: TArray<Integer>;
  SumReachDist: Double;
  i: Integer;
begin
  Neighbors := FindKNearestNeighbors(FDataPoints[PointIndex].Values, K);

  if Length(Neighbors) = 0 then
    Exit(0);

  SumReachDist := 0;
  for i := 0 to High(Neighbors) do
    SumReachDist := SumReachDist + CalculateReachabilityDistance(PointIndex, Neighbors[i], K);

  if SumReachDist > 0 then
    Result := Length(Neighbors) / SumReachDist
  else
    Result := 1.0;  // Perfect density if all neighbors are at same point
end;

function TLOFDetector.CalculateLOFScore(PointIndex: Integer): Double;
var
  Neighbors: TArray<Integer>;
  LRD_Point: Double;
  SumLRD_Neighbors: Double;
  i: Integer;
begin
  Neighbors := FindKNearestNeighbors(FDataPoints[PointIndex].Values, FKNeighbors);

  if Length(Neighbors) = 0 then
    Exit(1.0);  // No neighbors, assume normal

  LRD_Point := CalculateLocalReachabilityDensity(PointIndex, FKNeighbors);

  if LRD_Point = 0 then
    Exit(1.0);

  SumLRD_Neighbors := 0;
  for i := 0 to High(Neighbors) do
    SumLRD_Neighbors := SumLRD_Neighbors + CalculateLocalReachabilityDensity(Neighbors[i], FKNeighbors);

  // LOF = average LRD of neighbors / LRD of point
  Result := (SumLRD_Neighbors / Length(Neighbors)) / LRD_Point;
end;

procedure TLOFDetector.BuildLOFModel;
var
  i: Integer;
  Point: TLOFPoint;
begin
  FLock.Enter;
  try
    if FDataPoints.Count < FMinPts then
      raise EAnomalyDetectionException.CreateFmt(
        'Insufficient data points: need at least %d, have %d', [FMinPts, FDataPoints.Count]);

    // Calculate LOF score for each point
    for i := 0 to FDataPoints.Count - 1 do
    begin
      Point := FDataPoints[i];
      Point.LOFScore := CalculateLOFScore(i);
      Point.IsProcessed := True;
      FDataPoints[i] := Point;
    end;

    FIsBuilt := True;
  finally
    FLock.Leave;
  end;
end;

procedure TLOFDetector.Build;
begin
  BuildLOFModel;
end;

function TLOFDetector.Detect(const AValue: Double): TAnomalyResult;
var
  Point: TArray<Double>;
begin
  SetLength(Point, 1);
  Point[0] := AValue;
  Result := DetectMultiDimensional(Point);
end;

function TLOFDetector.DetectMultiDimensional(const APoint: TArray<Double>): TAnomalyResult;
var
  Neighbors: TArray<Integer>;
  LRD_Point: Double;
  SumLRD_Neighbors: Double;
  LOFScore: Double;
  i: Integer;
begin
  FLock.Enter;
  try
    if not FIsBuilt then
      raise EAnomalyDetectionException.Create('LOF model not built. Call Build() first.');

    if Length(APoint) <> FDimensions then
      raise EAnomalyDetectionException.CreateFmt(
        'Point dimension mismatch: expected %d, got %d', [FDimensions, Length(APoint)]);

    // Find neighbors of the new point
    Neighbors := FindKNearestNeighbors(APoint, FKNeighbors);

    if Length(Neighbors) = 0 then
    begin
      Result.IsAnomaly := True;
      Result.Value := 0;
      Result.ZScore := 999;
      Result.Description := 'No neighbors found - isolated point';
      Exit;
    end;

    // Calculate LRD for new point
    var SumReachDist: Double := 0;
    for i := 0 to High(Neighbors) do
    begin
      var DirectDist := CalculateDistance(APoint, FDataPoints[Neighbors[i]].Values);
      var KDist := CalculateKDistance(Neighbors[i], FKNeighbors);
      SumReachDist := SumReachDist + Max(DirectDist, KDist);
    end;

    if SumReachDist > 0 then
      LRD_Point := Length(Neighbors) / SumReachDist
    else
      LRD_Point := 1.0;

    // Calculate average LRD of neighbors
    SumLRD_Neighbors := 0;
    for i := 0 to High(Neighbors) do
      SumLRD_Neighbors := SumLRD_Neighbors + CalculateLocalReachabilityDensity(Neighbors[i], FKNeighbors);

    if LRD_Point > 0 then
      LOFScore := (SumLRD_Neighbors / Length(Neighbors)) / LRD_Point
    else
      LOFScore := 1.0;

    // Build result
    Result.Value := LOFScore;
    Result.ZScore := LOFScore;
    Result.LowerLimit := 0;
    Result.UpperLimit := FThreshold;
    Result.IsAnomaly := LOFScore > FThreshold;

    if Result.IsAnomaly then
      Result.Description := Format('ANOMALY: LOF score %.3f (threshold: %.2f) - Point has lower density than neighbors',
                                  [LOFScore, FThreshold])
    else
      Result.Description := Format('Normal: LOF score %.3f (similar density to neighbors)', [LOFScore]);

    CheckAndNotifyAnomaly(Result);
  finally
    FLock.Leave;
  end;
end;

procedure TLOFDetector.CheckAndNotifyAnomaly(const AResult: TAnomalyResult);
begin
  if AResult.IsAnomaly and not FLastAnomalyState then
    NotifyAnomalyEvent(aeAnomalyDetected, AResult)
  else if not AResult.IsAnomaly and FLastAnomalyState then
    NotifyAnomalyEvent(aeNormalResumed, AResult);

  FLastAnomalyState := AResult.IsAnomaly;
end;

procedure TLOFDetector.SaveState(const AStream: TStream);
var
  Count, i, j: Integer;
  Point: TLOFPoint;
begin
  FLock.Enter;
  try
    SaveConfigToStream(AStream);

    AStream.WriteData(FKNeighbors);
    AStream.WriteData(FDimensions);
    AStream.WriteData(FThreshold);
    AStream.WriteData(FIsBuilt);

    Count := FDataPoints.Count;
    AStream.WriteData(Count);

    for i := 0 to Count - 1 do
    begin
      Point := FDataPoints[i];
      for j := 0 to High(Point.Values) do
        AStream.WriteData(Point.Values[j]);
      AStream.WriteData(Point.LOFScore);
      AStream.WriteData(Point.IsProcessed);
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TLOFDetector.LoadState(const AStream: TStream);
var
  Count, i, j: Integer;
  Point: TLOFPoint;
begin
  FLock.Enter;
  try
    LoadConfigFromStream(AStream);

    AStream.ReadData(FKNeighbors);
    AStream.ReadData(FDimensions);
    AStream.ReadData(FThreshold);
    AStream.ReadData(FIsBuilt);

    AStream.ReadData(Count);
    FDataPoints.Clear;
    FDataPoints.Capacity := Count;

    for i := 0 to Count - 1 do
    begin
      SetLength(Point.Values, FDimensions);
      for j := 0 to FDimensions - 1 do
        AStream.ReadData(Point.Values[j]);
      AStream.ReadData(Point.LOFScore);
      AStream.ReadData(Point.IsProcessed);
      FDataPoints.Add(Point);
    end;

    FMinPts := FKNeighbors + 1;
  finally
    FLock.Leave;
  end;
end;

function TLOFDetector.IsInitialized: Boolean;
begin
  FLock.Enter;
  try
    Result := FIsBuilt and (FDataPoints.Count >= FMinPts);
  finally
    FLock.Leave;
  end;
end;

procedure TLOFDetector.Clear;
begin
  FLock.Enter;
  try
    FDataPoints.Clear;
    FIsBuilt := False;
  finally
    FLock.Leave;
  end;
end;

function TLOFDetector.GetDataPointsCount: Integer;
begin
  FLock.Enter;
  try
    Result := FDataPoints.Count;
  finally
    FLock.Leave;
  end;
end;

// IDensityAnomalyDetector interface implementation

function TLOFDetector.GetDimensions: Integer;
begin
  Result := FDimensions;
end;

procedure TLOFDetector.AddTrainingData(const AInstance: TArray<Double>);
begin
  AddPoint(AInstance);
end;

procedure TLOFDetector.Train;
begin
  Build;
end;

end.
