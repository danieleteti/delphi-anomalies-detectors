// ***************************************************************************
//
// Copyright (c) 2025 Daniele Teti - All Rights Reserved
//
// DBSCAN Anomaly Detector
// Density-Based Spatial Clustering for anomaly detection
//
// ***************************************************************************

unit AnomalyDetection.DBSCAN;

interface

uses
  System.SysUtils, System.Classes, System.Math, System.SyncObjs,
  System.Generics.Collections,
  AnomalyDetection.Types,
  AnomalyDetection.Base;

type
  /// <summary>
  /// Point in multi-dimensional space with cluster assignment
  /// </summary>
  TDBSCANPoint = record
    Values: TArray<Double>;
    ClusterID: Integer;  // -1 = noise/outlier, 0 = unclassified, >0 = cluster ID
    IsVisited: Boolean;
    function Distance(const AOther: TDBSCANPoint): Double;
  end;

  /// <summary>
  /// DBSCAN (Density-Based Spatial Clustering) Anomaly Detector
  /// Best for: Multi-dimensional data, outlier detection, spatial anomalies
  /// Use cases: Network intrusion, fraud detection, sensor networks, log analysis
  /// </summary>
  TDBSCANDetector = class(TBaseAnomalyDetector)
  private
    FLock: TCriticalSection;
    FPoints: TList<TDBSCANPoint>;
    FEpsilon: Double;          // Neighborhood radius
    FMinPoints: Integer;       // Minimum points to form a dense region
    FDimensions: Integer;      // Number of dimensions
    FMaxHistorySize: Integer;  // Maximum points to keep in history
    FClusterCount: Integer;    // Number of clusters found
    FOutlierCount: Integer;    // Number of outliers detected
    FLastClusteringTime: TDateTime;
    FAutoRecluster: Boolean;   // Automatically recluster when new data arrives
    FReclusterThreshold: Integer; // Recluster after N new points

    function GetRegionNeighbors(const APoint: TDBSCANPoint): TList<Integer>;
    function ExpandCluster(APointIndex: Integer; const ANeighbors: TList<Integer>; AClusterID: Integer): Boolean;
    procedure PerformClustering;
    procedure TrimHistory;
  public
    constructor Create(AEpsilon: Double = 0.5; AMinPoints: Integer = 5; ADimensions: Integer = 1); reintroduce;
    destructor Destroy; override;

    /// <summary>
    /// Add multi-dimensional point to dataset
    /// </summary>
    procedure AddPoint(const AValues: array of Double);

    /// <summary>
    /// Detect anomaly in single value (1D convenience method)
    /// </summary>
    function Detect(const AValue: Double): TAnomalyResult; override;

    /// <summary>
    /// Detect anomaly in multi-dimensional point
    /// </summary>
    function DetectMultiDim(const AValues: array of Double): TAnomalyResult;

    /// <summary>
    /// Force reclustering of all points
    /// </summary>
    procedure Recluster;

    /// <summary>
    /// Clear all historical data
    /// </summary>
    procedure Reset;

    function IsInitialized: Boolean; override;
    procedure SaveState(const AStream: TStream); override;
    procedure LoadState(const AStream: TStream); override;

    property Epsilon: Double read FEpsilon write FEpsilon;
    property MinPoints: Integer read FMinPoints write FMinPoints;
    property Dimensions: Integer read FDimensions;
    property ClusterCount: Integer read FClusterCount;
    property OutlierCount: Integer read FOutlierCount;
    property MaxHistorySize: Integer read FMaxHistorySize write FMaxHistorySize;
    property AutoRecluster: Boolean read FAutoRecluster write FAutoRecluster;
  end;

implementation

{ TDBSCANPoint }

function TDBSCANPoint.Distance(const AOther: TDBSCANPoint): Double;
var
  lSum: Double;
  i: Integer;
begin
  lSum := 0.0;
  for i := 0 to High(Values) do
    lSum := lSum + Sqr(Values[i] - AOther.Values[i]);
  Result := Sqrt(lSum);
end;

{ TDBSCANDetector }

constructor TDBSCANDetector.Create(AEpsilon: Double; AMinPoints: Integer; ADimensions: Integer);
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FPoints := TList<TDBSCANPoint>.Create;
  FEpsilon := AEpsilon;
  FMinPoints := AMinPoints;
  FDimensions := ADimensions;
  FMaxHistorySize := 1000;
  FAutoRecluster := True;
  FReclusterThreshold := 50;
  FClusterCount := 0;
  FOutlierCount := 0;
  FLastClusteringTime := 0;

  // Default configuration
  FConfig.SigmaMultiplier := 3.0;
  FConfig.MinStdDev := 0.01;
end;

destructor TDBSCANDetector.Destroy;
begin
  FPoints.Free;
  FLock.Free;
  inherited;
end;

procedure TDBSCANDetector.AddPoint(const AValues: array of Double);
var
  lPoint: TDBSCANPoint;
  i: Integer;
begin
  if Length(AValues) <> FDimensions then
    raise Exception.CreateFmt('Invalid dimension: expected %d, got %d', [FDimensions, Length(AValues)]);

  FLock.Enter;
  try
    SetLength(lPoint.Values, FDimensions);
    for i := 0 to FDimensions - 1 do
      lPoint.Values[i] := AValues[i];
    lPoint.ClusterID := 0;  // Unclassified
    lPoint.IsVisited := False;

    FPoints.Add(lPoint);
    TrimHistory;

    // Auto-recluster if threshold reached
    if FAutoRecluster and ((FPoints.Count mod FReclusterThreshold) = 0) then
      PerformClustering;
  finally
    FLock.Leave;
  end;
end;

function TDBSCANDetector.Detect(const AValue: Double): TAnomalyResult;
begin
  Result := DetectMultiDim([AValue]);
end;

function TDBSCANDetector.DetectMultiDim(const AValues: array of Double): TAnomalyResult;
var
  lPoint: TDBSCANPoint;
  lNeighbors: TList<Integer>;
  i: Integer;
  lMinDistance: Double;
  lNearestCluster: Integer;
begin
  Result := Default(TAnomalyResult);
  Result.Value := 0;
  Result.IsAnomaly := False;
  Result.ZScore := 0;
  Result.LowerLimit := 0;
  Result.UpperLimit := 0;
  Result.Description := '';

  if Length(AValues) <> FDimensions then
  begin
    Result.IsAnomaly := True;
    Result.Description := 'Invalid dimension';
    Exit;
  end;

  // Build temporary point
  SetLength(lPoint.Values, FDimensions);
  for i := 0 to FDimensions - 1 do
  begin
    lPoint.Values[i] := AValues[i];
    Result.Value := Result.Value + AValues[i]; // Sum for single value representation
  end;
  Result.Value := Result.Value / FDimensions; // Average
  lPoint.ClusterID := 0;
  lPoint.IsVisited := False;

  FLock.Enter;
  try
    // Need minimum samples for clustering
    if FPoints.Count < FMinPoints then
    begin
      Result.IsAnomaly := False;
      Result.Description := 'Not enough samples';
      Exit;
    end;

    // Ensure clustering is performed
    if FClusterCount = 0 then
      PerformClustering;

    // Find neighbors of the new point
    lNeighbors := GetRegionNeighbors(lPoint);
    try
      // Point is anomaly if it has too few neighbors (low density region)
      if lNeighbors.Count < FMinPoints then
      begin
        Result.IsAnomaly := True;
        Result.Description := 'Low density region';
        Result.ZScore := (FMinPoints - lNeighbors.Count) / Max(1.0, Sqrt(FMinPoints));
      end
      else
      begin
        // Check if point would belong to an existing cluster
        lMinDistance := MaxDouble;
        lNearestCluster := -1;

        for i in lNeighbors do
        begin
          if FPoints[i].ClusterID > 0 then
          begin
            var lDist := lPoint.Distance(FPoints[i]);
            if lDist < lMinDistance then
            begin
              lMinDistance := lDist;
              lNearestCluster := FPoints[i].ClusterID;
            end;
          end;
        end;

        // Point is normal if it's close to a cluster
        Result.IsAnomaly := (lNearestCluster = -1);
        if lNearestCluster = -1 then
          Result.Description := 'Not in any cluster'
        else
          Result.Description := 'Normal';
        Result.ZScore := lMinDistance / FEpsilon;
      end;
    finally
      lNeighbors.Free;
    end;
  finally
    FLock.Leave;
  end;
end;

function TDBSCANDetector.GetRegionNeighbors(const APoint: TDBSCANPoint): TList<Integer>;
var
  i: Integer;
  lDistance: Double;
begin
  Result := TList<Integer>.Create;
  for i := 0 to FPoints.Count - 1 do
  begin
    lDistance := APoint.Distance(FPoints[i]);
    if lDistance <= FEpsilon then
      Result.Add(i);
  end;
end;

function TDBSCANDetector.ExpandCluster(APointIndex: Integer; const ANeighbors: TList<Integer>;
  AClusterID: Integer): Boolean;
var
  i, lNeighborIndex: Integer;
  lPoint: TDBSCANPoint;
  lNewNeighbors: TList<Integer>;
begin
  // Assign cluster to initial point
  lPoint := FPoints[APointIndex];
  lPoint.ClusterID := AClusterID;
  FPoints[APointIndex] := lPoint;

  i := 0;
  while i < ANeighbors.Count do
  begin
    lNeighborIndex := ANeighbors[i];
    lPoint := FPoints[lNeighborIndex];

    // Mark as visited
    if not lPoint.IsVisited then
    begin
      lPoint.IsVisited := True;
      FPoints[lNeighborIndex] := lPoint;

      // Find neighbors of this point
      lNewNeighbors := GetRegionNeighbors(lPoint);
      try
        // If this point has enough neighbors, it's a core point - expand further
        if lNewNeighbors.Count >= FMinPoints then
        begin
          var j: Integer;
          for j := 0 to lNewNeighbors.Count - 1 do
            if not ANeighbors.Contains(lNewNeighbors[j]) then
              ANeighbors.Add(lNewNeighbors[j]);
        end;
      finally
        lNewNeighbors.Free;
      end;
    end;

    // Assign to cluster if not yet assigned
    lPoint := FPoints[lNeighborIndex];
    if lPoint.ClusterID = 0 then
    begin
      lPoint.ClusterID := AClusterID;
      FPoints[lNeighborIndex] := lPoint;
    end;

    Inc(i);
  end;

  Result := True;
end;

procedure TDBSCANDetector.PerformClustering;
var
  i: Integer;
  lClusterID: Integer;
  lNeighbors: TList<Integer>;
  lPoint: TDBSCANPoint;
begin
  // Reset all points
  for i := 0 to FPoints.Count - 1 do
  begin
    lPoint := FPoints[i];
    lPoint.ClusterID := 0;
    lPoint.IsVisited := False;
    FPoints[i] := lPoint;
  end;

  lClusterID := 0;
  FOutlierCount := 0;

  // DBSCAN algorithm
  for i := 0 to FPoints.Count - 1 do
  begin
    lPoint := FPoints[i];

    if lPoint.IsVisited then
      Continue;

    lPoint.IsVisited := True;
    FPoints[i] := lPoint;

    // Get neighbors
    lNeighbors := GetRegionNeighbors(lPoint);
    try
      // Check if core point
      if lNeighbors.Count < FMinPoints then
      begin
        // Mark as noise/outlier
        lPoint.ClusterID := -1;
        FPoints[i] := lPoint;
        Inc(FOutlierCount);
      end
      else
      begin
        // Start new cluster
        Inc(lClusterID);
        ExpandCluster(i, lNeighbors, lClusterID);
      end;
    finally
      lNeighbors.Free;
    end;
  end;

  FClusterCount := lClusterID;
  FLastClusteringTime := Now;
end;

procedure TDBSCANDetector.Recluster;
begin
  FLock.Enter;
  try
    PerformClustering;
  finally
    FLock.Leave;
  end;
end;

procedure TDBSCANDetector.Reset;
begin
  FLock.Enter;
  try
    FPoints.Clear;
    FClusterCount := 0;
    FOutlierCount := 0;
    FLastClusteringTime := 0;
  finally
    FLock.Leave;
  end;
end;

procedure TDBSCANDetector.TrimHistory;
begin
  while FPoints.Count > FMaxHistorySize do
    FPoints.Delete(0);
end;

function TDBSCANDetector.IsInitialized: Boolean;
begin
  FLock.Enter;
  try
    Result := FPoints.Count >= FMinPoints;
  finally
    FLock.Leave;
  end;
end;

procedure TDBSCANDetector.SaveState(const AStream: TStream);
var
  i, j: Integer;
  lCount: Integer;
  lDimCount: Integer;
  lValue: Double;
  lClusterID: Integer;
begin
  FLock.Enter;
  try
    // Write parameters
    AStream.Write(FEpsilon, SizeOf(FEpsilon));
    AStream.Write(FMinPoints, SizeOf(FMinPoints));
    AStream.Write(FDimensions, SizeOf(FDimensions));
    AStream.Write(FMaxHistorySize, SizeOf(FMaxHistorySize));

    // Write points
    lCount := FPoints.Count;
    AStream.Write(lCount, SizeOf(lCount));

    for i := 0 to FPoints.Count - 1 do
    begin
      lDimCount := Length(FPoints[i].Values);
      AStream.Write(lDimCount, SizeOf(lDimCount));

      for j := 0 to lDimCount - 1 do
      begin
        lValue := FPoints[i].Values[j];
        AStream.Write(lValue, SizeOf(lValue));
      end;

      lClusterID := FPoints[i].ClusterID;
      AStream.Write(lClusterID, SizeOf(lClusterID));
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TDBSCANDetector.LoadState(const AStream: TStream);
var
  i, j: Integer;
  lCount: Integer;
  lDimCount: Integer;
  lValue: Double;
  lClusterID: Integer;
  lPoint: TDBSCANPoint;
begin
  FLock.Enter;
  try
    FPoints.Clear;

    // Read parameters
    AStream.Read(FEpsilon, SizeOf(FEpsilon));
    AStream.Read(FMinPoints, SizeOf(FMinPoints));
    AStream.Read(FDimensions, SizeOf(FDimensions));
    AStream.Read(FMaxHistorySize, SizeOf(FMaxHistorySize));

    // Read points
    AStream.Read(lCount, SizeOf(lCount));

    for i := 0 to lCount - 1 do
    begin
      AStream.Read(lDimCount, SizeOf(lDimCount));
      SetLength(lPoint.Values, lDimCount);

      for j := 0 to lDimCount - 1 do
      begin
        AStream.Read(lValue, SizeOf(lValue));
        lPoint.Values[j] := lValue;
      end;

      AStream.Read(lClusterID, SizeOf(lClusterID));
      lPoint.ClusterID := lClusterID;
      lPoint.IsVisited := False;

      FPoints.Add(lPoint);
    end;

    // Recluster after loading
    if FPoints.Count >= FMinPoints then
      PerformClustering;
  finally
    FLock.Leave;
  end;
end;

end.
