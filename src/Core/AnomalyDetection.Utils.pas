unit AnomalyDetection.Utils;

{===============================================================================
  Statistical Utility Functions for Anomaly Detection

  This unit provides helper functions for data preprocessing and statistical
  analysis commonly used in anomaly detection workflows.

  Author: Daniele Teti (d.teti@bittime.it)
  License: Commercial software - proprietary and confidential
===============================================================================}

interface

uses
  System.SysUtils,
  System.Math,
  System.Generics.Collections;

type
  /// <summary>
  /// Statistical summary of a dataset
  /// </summary>
  TStatisticalSummary = record
    Count: Integer;
    Min: Double;
    Max: Double;
    Mean: Double;
    Median: Double;
    StdDev: Double;
    Q1: Double;  // 25th percentile
    Q3: Double;  // 75th percentile
    IQR: Double; // Interquartile range (Q3 - Q1)
  end;

  /// <summary>
  /// Result of data cleaning operation
  /// </summary>
  TCleaningResult = record
    CleanData: TArray<Double>;
    OriginalCount: Integer;
    CleanCount: Integer;
    RemovedCount: Integer;
    LowerBound: Double;
    UpperBound: Double;
    function RemovalPercent: Double;
  end;

/// <summary>
/// Calculates the specified percentile of a dataset
/// </summary>
/// <param name="Data">Array of values</param>
/// <param name="Percentile">Percentile to calculate (0-100)</param>
/// <returns>The percentile value</returns>
/// <remarks>
/// Uses linear interpolation between closest ranks.
/// Returns 0 if Data is empty.
/// </remarks>
function CalculatePercentile(const Data: TArray<Double>; Percentile: Integer): Double; overload;

/// <summary>
/// Calculates the specified percentile of a dataset (floating point percentile)
/// </summary>
/// <param name="Data">Array of values</param>
/// <param name="Percentile">Percentile to calculate (0.0-100.0)</param>
/// <returns>The percentile value</returns>
function CalculatePercentile(const Data: TArray<Double>; Percentile: Double): Double; overload;

/// <summary>
/// Removes outliers from data using percentile-based filtering
/// </summary>
/// <param name="Data">Array of values to clean</param>
/// <param name="LowerPercentile">Lower bound percentile (default: 5)</param>
/// <param name="UpperPercentile">Upper bound percentile (default: 95)</param>
/// <returns>TCleaningResult with cleaned data and statistics</returns>
/// <remarks>
/// This is the recommended approach for removing outliers before training
/// detectors like ThreeSigma, SlidingWindow, or EMA.
/// Isolation Forest is robust and doesn't require this preprocessing.
/// </remarks>
function CleanDataWithPercentiles(const Data: TArray<Double>;
                                  LowerPercentile: Integer = 5;
                                  UpperPercentile: Integer = 95): TCleaningResult;

/// <summary>
/// Removes outliers using the IQR (Interquartile Range) method
/// </summary>
/// <param name="Data">Array of values to clean</param>
/// <param name="IQRMultiplier">Multiplier for IQR (default: 1.5)</param>
/// <returns>TCleaningResult with cleaned data and statistics</returns>
/// <remarks>
/// IQR method: removes values below Q1 - (IQR × multiplier) or above Q3 + (IQR × multiplier)
/// Common multipliers: 1.5 (standard), 3.0 (extreme outliers only)
/// </remarks>
function CleanDataWithIQR(const Data: TArray<Double>;
                          IQRMultiplier: Double = 1.5): TCleaningResult;

/// <summary>
/// Calculates comprehensive statistical summary of a dataset
/// </summary>
/// <param name="Data">Array of values</param>
/// <returns>TStatisticalSummary with all statistics</returns>
function CalculateStatistics(const Data: TArray<Double>): TStatisticalSummary;

/// <summary>
/// Calculates the median of a dataset
/// </summary>
/// <param name="Data">Array of values</param>
/// <returns>The median value</returns>
function CalculateMedian(const Data: TArray<Double>): Double;

/// <summary>
/// Calculates the mean (average) of a dataset
/// </summary>
/// <param name="Data">Array of values</param>
/// <returns>The mean value</returns>
function CalculateMean(const Data: TArray<Double>): Double;

/// <summary>
/// Calculates the standard deviation of a dataset
/// </summary>
/// <param name="Data">Array of values</param>
/// <param name="UseSampleStdDev">If true, uses N-1 denominator (default: true)</param>
/// <returns>The standard deviation</returns>
function CalculateStdDev(const Data: TArray<Double>; UseSampleStdDev: Boolean = True): Double;

/// <summary>
/// Finds minimum value in dataset
/// </summary>
function FindMin(const Data: TArray<Double>): Double;

/// <summary>
/// Finds maximum value in dataset
/// </summary>
function FindMax(const Data: TArray<Double>): Double;

/// <summary>
/// Sorts a copy of the data array
/// </summary>
/// <param name="Data">Array to sort</param>
/// <returns>Sorted copy of the array</returns>
function SortData(const Data: TArray<Double>): TArray<Double>;

implementation

{ TCleaningResult }

function TCleaningResult.RemovalPercent: Double;
begin
  if OriginalCount = 0 then
    Result := 0
  else
    Result := (RemovedCount / OriginalCount) * 100.0;
end;

{ Utility Functions }

function SortData(const Data: TArray<Double>): TArray<Double>;
begin
  Result := Copy(Data);
  TArray.Sort<Double>(Result);
end;

function CalculatePercentile(const Data: TArray<Double>; Percentile: Integer): Double;
begin
  Result := CalculatePercentile(Data, Double(Percentile));
end;

function CalculatePercentile(const Data: TArray<Double>; Percentile: Double): Double;
var
  SortedData: TArray<Double>;
  Index: Double;
  LowerIndex, UpperIndex: Integer;
begin
  if Length(Data) = 0 then
    Exit(0);

  if Length(Data) = 1 then
    Exit(Data[0]);

  // Validate percentile range
  if Percentile < 0 then
    Percentile := 0
  else if Percentile > 100 then
    Percentile := 100;

  // Sort data
  SortedData := SortData(Data);

  // Calculate the index for the percentile
  Index := (Percentile / 100.0) * (Length(SortedData) - 1);
  LowerIndex := Floor(Index);
  UpperIndex := Ceil(Index);

  if LowerIndex = UpperIndex then
    Result := SortedData[LowerIndex]
  else
    // Linear interpolation between the two closest values
    Result := SortedData[LowerIndex] +
              (SortedData[UpperIndex] - SortedData[LowerIndex]) *
              (Index - LowerIndex);
end;

function CleanDataWithPercentiles(const Data: TArray<Double>;
                                  LowerPercentile: Integer = 5;
                                  UpperPercentile: Integer = 95): TCleaningResult;
var
  P_Low, P_High: Double;
  Value: Double;
  CleanList: TList<Double>;
begin
  Result.CleanData := [];
  Result.OriginalCount := Length(Data);
  Result.CleanCount := 0;
  Result.RemovedCount := 0;
  Result.LowerBound := 0;
  Result.UpperBound := 0;

  if Length(Data) = 0 then
    Exit;

  // Calculate percentile bounds
  P_Low := CalculatePercentile(Data, LowerPercentile);
  P_High := CalculatePercentile(Data, UpperPercentile);

  Result.LowerBound := P_Low;
  Result.UpperBound := P_High;

  // Filter data within bounds
  CleanList := TList<Double>.Create;
  try
    for Value in Data do
    begin
      if (Value >= P_Low) and (Value <= P_High) then
        CleanList.Add(Value);
    end;

    Result.CleanData := CleanList.ToArray;
    Result.CleanCount := Length(Result.CleanData);
    Result.RemovedCount := Result.OriginalCount - Result.CleanCount;
  finally
    CleanList.Free;
  end;
end;

function CleanDataWithIQR(const Data: TArray<Double>;
                          IQRMultiplier: Double = 1.5): TCleaningResult;
var
  Q1, Q3, IQR: Double;
  LowerBound, UpperBound: Double;
  Value: Double;
  CleanList: TList<Double>;
begin
  Result.CleanData := [];
  Result.OriginalCount := Length(Data);
  Result.CleanCount := 0;
  Result.RemovedCount := 0;
  Result.LowerBound := 0;
  Result.UpperBound := 0;

  if Length(Data) = 0 then
    Exit;

  // Calculate quartiles
  Q1 := CalculatePercentile(Data, 25.0);
  Q3 := CalculatePercentile(Data, 75.0);
  IQR := Q3 - Q1;

  // Calculate bounds using IQR method
  LowerBound := Q1 - (IQR * IQRMultiplier);
  UpperBound := Q3 + (IQR * IQRMultiplier);

  Result.LowerBound := LowerBound;
  Result.UpperBound := UpperBound;

  // Filter data within bounds
  CleanList := TList<Double>.Create;
  try
    for Value in Data do
    begin
      if (Value >= LowerBound) and (Value <= UpperBound) then
        CleanList.Add(Value);
    end;

    Result.CleanData := CleanList.ToArray;
    Result.CleanCount := Length(Result.CleanData);
    Result.RemovedCount := Result.OriginalCount - Result.CleanCount;
  finally
    CleanList.Free;
  end;
end;

function CalculateMean(const Data: TArray<Double>): Double;
var
  Sum: Double;
  Value: Double;
begin
  if Length(Data) = 0 then
    Exit(0);

  Sum := 0;
  for Value in Data do
    Sum := Sum + Value;

  Result := Sum / Length(Data);
end;

function CalculateMedian(const Data: TArray<Double>): Double;
begin
  Result := CalculatePercentile(Data, 50.0);
end;

function CalculateStdDev(const Data: TArray<Double>; UseSampleStdDev: Boolean = True): Double;
var
  Mean, SumSquaredDiff: Double;
  Value: Double;
  N: Integer;
begin
  N := Length(Data);

  if N = 0 then
    Exit(0);

  if N = 1 then
    Exit(0);

  Mean := CalculateMean(Data);

  SumSquaredDiff := 0;
  for Value in Data do
    SumSquaredDiff := SumSquaredDiff + Sqr(Value - Mean);

  if UseSampleStdDev then
    Result := Sqrt(SumSquaredDiff / (N - 1))
  else
    Result := Sqrt(SumSquaredDiff / N);
end;

function FindMin(const Data: TArray<Double>): Double;
var
  Value: Double;
begin
  if Length(Data) = 0 then
    Exit(0);

  Result := Data[0];
  for Value in Data do
    if Value < Result then
      Result := Value;
end;

function FindMax(const Data: TArray<Double>): Double;
var
  Value: Double;
begin
  if Length(Data) = 0 then
    Exit(0);

  Result := Data[0];
  for Value in Data do
    if Value > Result then
      Result := Value;
end;

function CalculateStatistics(const Data: TArray<Double>): TStatisticalSummary;
begin
  Result.Count := Length(Data);

  if Result.Count = 0 then
  begin
    Result.Min := 0;
    Result.Max := 0;
    Result.Mean := 0;
    Result.Median := 0;
    Result.StdDev := 0;
    Result.Q1 := 0;
    Result.Q3 := 0;
    Result.IQR := 0;
    Exit;
  end;

  Result.Min := FindMin(Data);
  Result.Max := FindMax(Data);
  Result.Mean := CalculateMean(Data);
  Result.Median := CalculateMedian(Data);
  Result.StdDev := CalculateStdDev(Data, True);
  Result.Q1 := CalculatePercentile(Data, 25.0);
  Result.Q3 := CalculatePercentile(Data, 75.0);
  Result.IQR := Result.Q3 - Result.Q1;
end;

end.
