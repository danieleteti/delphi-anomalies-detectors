# Anomaly Detection Algorithms Library

A comprehensive Delphi library for detecting anomalies in business data using various statistical and machine learning approaches. This library provides multiple anomaly detection algorithms suitable for different scenarios, from historical data analysis to real-time streaming data monitoring.

## Features

- **Multiple Detection Algorithms**: Implements 6 different approaches for various use cases
- **Machine Learning Support**: Includes Isolation Forest for high-dimensional data
- **Interactive Demo**: Comprehensive demo with real-world scenarios and benchmarking
- **Performance Monitoring**: Built-in metrics and performance analysis
- **Data Visualization**: ASCII charts and result export capabilities
- **Factory Pattern**: Pre-configured detectors for common business domains
- **Memory Safe**: No memory leaks, proper object lifetime management
- **Thread Safe**: Critical sections for concurrent usage
- **Easy to Use**: Clear, intuitive method names and comprehensive documentation
- **Production Ready**: Well-tested algorithms used in real business applications
- **Extensible**: Object-oriented design allows easy extension and customization

## Algorithms Included

### 1. Three Sigma Detector (`TThreeSigmaDetector`)

**Best for**: Historical data analysis, static datasets, batch processing

The classic statistical approach based on the empirical rule that 99.7% of data in a normal distribution falls within 3 standard deviations from the mean.

**Characteristics**:
- Uses all historical data for calculation
- Static thresholds once calculated
- Excellent for detecting outliers in stable datasets
- Simple and reliable for one-time analysis
- Requires sufficient historical data

**Use Cases**:
- Quality control in manufacturing
- Financial audit anomaly detection
- One-time dataset validation
- Baseline establishment for other detectors

### 2. Sliding Window Detector (`TSlidingWindowDetector`)

**Best for**: Streaming data, real-time monitoring, changing conditions

Maintains a fixed-size window of recent data points and recalculates statistics as new data arrives and old data expires.

**Characteristics**:
- Adaptive to changing data patterns
- Fixed memory footprint (window size)
- Real-time capable
- Good balance between responsiveness and stability
- Window size determines sensitivity vs. stability trade-off

**Use Cases**:
- Real-time system monitoring
- Network traffic anomaly detection
- Sensor data monitoring
- Live dashboard alerts

### 3. Exponential Moving Average Detector (`TEMAAnomalyDetector`)

**Best for**: Fast adaptation scenarios, trending data, immediate response needed

Uses exponential smoothing to give more weight to recent observations, making it highly responsive to changes while maintaining some historical context.

**Characteristics**:
- Very responsive to changes (adjustable via Alpha parameter)
- Minimal memory usage (only current state)
- Smooth adaptation to gradual changes
- Alpha parameter controls adaptation speed (0.01-0.3 typical range)
- Excellent for trending data

**Use Cases**:
- Stock price monitoring
- Performance metrics tracking
- Rapidly changing business KPIs
- Real-time alert systems requiring quick response

### 4. Adaptive Detector (`TAdaptiveAnomalyDetector`)

**Best for**: Environments with gradual changes, learning systems, feedback loops

Learns from confirmed normal values to continuously adapt the detection model, making it suitable for environments where "normal" behavior evolves over time.

**Characteristics**:
- Learns and adapts from normal data
- Resistant to concept drift
- Configurable adaptation rate
- Requires feedback on normal vs. anomalous data
- Good for long-term monitoring scenarios

**Use Cases**:
- Seasonal business pattern monitoring
- User behavior analysis
- System performance baselining
- Long-term operational metrics

### 5. Isolation Forest Detector (`TIsolationForestDetector`)

**Best for**: High-dimensional data, unsupervised detection, complex patterns

Uses ensemble of isolation trees to identify anomalies by measuring how easily points can be "isolated" from the rest of the data. Excellent for multi-dimensional anomaly detection.

**Characteristics**:
- Works well with high-dimensional data (multiple features)
- Unsupervised learning (no labeled training data needed)
- Handles complex, non-linear patterns
- Configurable ensemble size and tree depth
- Resistant to normal data contamination

**Use Cases**:
- Fraud detection (multiple transaction features)
- Cybersecurity (network behavior analysis)
- Multi-sensor IoT monitoring
- Financial risk assessment
- Medical diagnosis support

### 6. Anomaly Confirmation System (`TAnomalyConfirmationSystem`)

**Best for**: Reducing false positives, critical alert systems, multi-source validation

A meta-detector that requires multiple similar anomalies before confirming an alert, reducing false positives while maintaining sensitivity.

**Characteristics**:
- Reduces false positive rate
- Requires multiple detections for confirmation
- Configurable confirmation threshold
- Works with any base detector
- Adds robustness to detection pipeline

**Use Cases**:
- Critical system alerts
- Security incident detection
- Financial fraud detection
- Any scenario where false positives are costly

## Demo Application Features

The comprehensive demo application (`AnomalyDetectionDemo.dpr`) provides:

### Interactive Testing
- **Real-time Configuration**: Modify detector parameters during execution
- **CSV Data Loading**: Test with your own datasets or generated sample data
- **ASCII Visualization**: See anomaly patterns directly in the console
- **Performance Benchmarks**: Compare all detectors on identical datasets

### Realistic Scenarios
- **Fraud Detection**: Multi-dimensional transaction analysis
- **Web Traffic Monitoring**: DDoS and security threat detection  
- **IoT Sensor Monitoring**: Equipment failure prediction
- **Financial Analysis**: Market anomaly identification

### Export & Analysis
- **CSV Export**: Export results for external analysis
- **Performance Metrics**: Detailed timing and accuracy statistics
- **Comparative Reports**: Side-by-side algorithm comparison

### Factory Pattern Support
Pre-configured detectors for common domains:
```pascal
// Optimized for web security monitoring
WebTrafficDetector := TAnomalyDetectorFactory.CreateForWebTrafficMonitoring;

// Configured for financial data precision
FinancialDetector := TAnomalyDetectorFactory.CreateForFinancialData;

// Tuned for IoT sensor reliability
IoTDetector := TAnomalyDetectorFactory.CreateForIoTSensors;

// Optimized for high-dimensional analysis
MLDetector := TAnomalyDetectorFactory.CreateForHighDimensionalData;
```

## Installation

1. Add `AnomalyDetectionAlgorithms.pas` to your Delphi project
2. Include the unit in your uses clause:
   ```pascal
   uses AnomalyDetectionAlgorithms;
   ```

## Utility Functions

The library includes statistical utility functions in `AnomalyDetection.Utils` for data preprocessing:

### Cleaning Data with Percentiles

When your historical data might contain anomalies (errors, fraud, bugs), use percentile-based filtering before training:

```pascal
uses
  AnomalyDetection.Utils,
  AnomalyDetection.ThreeSigma;

var
  RawData: TArray<Double>;
  CleaningResult: TCleaningResult;
  Detector: TThreeSigmaDetector;
begin
  // Load data from database (may contain outliers)
  RawData := LoadHistoricalOrders;

  // Clean data using 5th-95th percentile range (removes top/bottom 5%)
  CleaningResult := CleanDataWithPercentiles(RawData, 5, 95);

  WriteLn(Format('Removed %d outliers (%.1f%%)',
         [CleaningResult.RemovedCount, CleaningResult.RemovalPercent]));

  // Train detector on clean data only
  Detector := TThreeSigmaDetector.Create;
  try
    Detector.SetHistoricalData(CleaningResult.CleanData);
    Detector.CalculateStatistics;
  finally
    Detector.Free;
  end;
end;
```

**Alternative: IQR Method**
```pascal
// Remove outliers using Interquartile Range (IQR) method
CleaningResult := CleanDataWithIQR(RawData, 1.5); // Standard multiplier
```

### Statistical Analysis

```pascal
var
  Stats: TStatisticalSummary;
begin
  Stats := CalculateStatistics(Data);

  WriteLn('Count: ', Stats.Count);
  WriteLn('Mean: ', Stats.Mean:0:2);
  WriteLn('Median: ', Stats.Median:0:2);
  WriteLn('StdDev: ', Stats.StdDev:0:2);
  WriteLn('Min/Max: ', Stats.Min:0:2, ' / ', Stats.Max:0:2);
  WriteLn('Q1/Q3: ', Stats.Q1:0:2, ' / ', Stats.Q3:0:2);
  WriteLn('IQR: ', Stats.IQR:0:2);
end;
```

**Available utility functions**:
- `CalculatePercentile(Data, Percentile)` - Get specific percentile value
- `CleanDataWithPercentiles(Data, Lower, Upper)` - Remove outliers using percentiles
- `CleanDataWithIQR(Data, Multiplier)` - Remove outliers using IQR method
- `CalculateStatistics(Data)` - Get full statistical summary
- `CalculateMean(Data)` - Calculate average
- `CalculateMedian(Data)` - Calculate median (50th percentile)
- `CalculateStdDev(Data)` - Calculate standard deviation
- `FindMin(Data)` / `FindMax(Data)` - Find min/max values

**When to use data cleaning**:
- ✅ **Required** for ThreeSigma, SlidingWindow, EMA if data may contain anomalies
- ✅ **Recommended** when loading historical data from production databases
- ❌ **Not needed** for Isolation Forest (already robust to outliers)
- ❌ **Skip** if data is pre-validated or synthetic/test data

## Quick Start Examples

### Basic Usage - Three Sigma Detector
```pascal
var
  Detector: TThreeSigmaDetector;
  Data: TArray<Double>;
  Result: TAnomalyResult;
begin
  Detector := TThreeSigmaDetector.Create;
  try
    // Add historical data
    Data := [100, 105, 98, 102, 107, 99, 103, 101, 104, 106];
    Detector.AddValues(Data);

    // Build the statistical model
    Detector.Build;

    // Check for anomalies with detailed results
    Result := Detector.Detect(150);
    if Result.IsAnomaly then
      WriteLn(Format('Anomaly detected: %.2f (Z-score: %.2f)', [Result.Value, Result.ZScore]));
  finally
    Detector.Free;
  end;
end;
```

**Incremental approach:**
```pascal
// Add data incrementally, then build
for Value in HistoricalData do
  Detector.AddValue(Value);

Detector.Build;  // Calculate statistics when ready
```

### Real-time Monitoring - Sliding Window
```pascal
var
  Detector: TSlidingWindowDetector;
  Result: TAnomalyResult;
begin
  Detector := TSlidingWindowDetector.Create(100); // 100-value window
  try
    // Process streaming data
    while HasNewData do
    begin
      var NewValue := GetNextDataPoint;
      Detector.AddValue(NewValue);
      
      Result := Detector.Detect(NewValue);
      if Result.IsAnomaly then
        TriggerAlert(Format('Anomaly: %.2f (Z-score: %.2f)', [Result.Value, Result.ZScore]));
    end;
  finally
    Detector.Free;
  end;
end;
```

### Multi-Dimensional Analysis - Isolation Forest
```pascal
var
  Detector: TIsolationForestDetector;
  Transaction: TArray<Double>;
  Result: TAnomalyResult;
begin
  Detector := TIsolationForestDetector.Create(100, 256, 10);
  try
    // Training with normal transaction patterns
    for i := 1 to 1000 do
    begin
      SetLength(Transaction, 5); // Amount, Hour, Day, Category, Age
      Transaction[0] := 50 + Random(200);     // Amount
      Transaction[1] := 8 + Random(14);       // Hour
      Transaction[2] := 1 + Random(5);        // Weekday
      Transaction[3] := 1 + Random(10);       // Category
      Transaction[4] := 25 + Random(40);      // Age
      Detector.AddTrainingData(Transaction);
    end;
    
    Detector.Train;
    
    // Test suspicious transaction
    SetLength(Transaction, 5);
    Transaction := [5000, 3, 2, 5, 35]; // Large amount at 3 AM
    Result := Detector.DetectMultiDimensional(Transaction);
    
    if Result.IsAnomaly then
      WriteLn('Potential fraud detected!');
  finally
    Detector.Free;
  end;
end;
```

### Performance Monitoring
```pascal
var
  Detector: TSlidingWindowDetector;
  Metrics: TDetectorMetrics;
begin
  Detector := TSlidingWindowDetector.Create(50);
  try
    // Enable performance monitoring
    Detector.PerformanceMonitor.Enabled := True;
    
    // Process data
    for var Value in DataStream do
    begin
      Detector.PerformanceMonitor.StartMeasurement;
      var Result := Detector.Detect(Value);
      Detector.PerformanceMonitor.StopMeasurement(Result.IsAnomaly);
    end;
    
    // Get performance report
    WriteLn(Detector.GetPerformanceReport);
    
    // Access detailed metrics
    Metrics := Detector.PerformanceMonitor.GetCurrentMetrics;
    WriteLn(Format('Throughput: %.1f ops/sec', [Metrics.ThroughputPerSecond]));
  finally
    Detector.Free;
  end;
end;
```

## API Reference

### Base Class Methods (All Detectors)
- `Detect(const AValue: Double): TAnomalyResult` - Full anomaly analysis with details
- `IsAnomaly(const AValue: Double): Boolean` - Simple anomaly check
- `GetAnomalyInfo(const AValue: Double): string` - Human-readable anomaly description
- `GetPerformanceReport: string` - Detailed performance metrics
- `SaveToFile(const AFileName: string)` - Persist detector state
- `LoadFromFile(const AFileName: string)` - Restore detector state
- `Name: string` - Readable name of the detector
- `PerformanceMonitor: TDetectorPerformanceMonitor` - Access to performance metrics

### TAnomalyResult Record
- `IsAnomaly: Boolean` - Whether value is anomalous
- `Value: Double` - The tested value
- `ZScore: Double` - Statistical Z-score
- `LowerLimit: Double` - Lower threshold
- `UpperLimit: Double` - Upper threshold  
- `Description: string` - Human-readable description

### TThreeSigmaDetector
- `SetHistoricalData(const AData: TArray<Double>)` - Set historical data
- `CalculateStatistics` - Calculate mean, std dev, and limits
- `Mean: Double` - Calculated mean
- `StdDev: Double` - Calculated standard deviation
- `LowerLimit: Double` - Lower 3-sigma limit
- `UpperLimit: Double` - Upper 3-sigma limit

### TSlidingWindowDetector
- `AddValue(const AValue: Double)` - Add new value and recalculate
- `CurrentMean: Double` - Current window mean
- `CurrentStdDev: Double` - Current window standard deviation
- `WindowSize: Integer` - Size of the sliding window
- `LowerLimit: Double` - Current lower limit
- `UpperLimit: Double` - Current upper limit

### TEMAAnomalyDetector
- `AddValue(const AValue: Double)` - Add new value and update EMA
- `CurrentMean: Double` - Current exponential moving average
- `CurrentStdDev: Double` - Current standard deviation estimate
- `Alpha: Double` - Adaptation rate parameter
- `LowerLimit: Double` - Current lower limit
- `UpperLimit: Double` - Current upper limit

### TAdaptiveAnomalyDetector
- `ProcessValue(const AValue: Double)` - Process new value
- `UpdateNormal(const AValue: Double)` - Confirm value as normal (for learning)
- `CurrentMean: Double` - Current adaptive mean
- `CurrentStdDev: Double` - Current adaptive standard deviation

### TIsolationForestDetector
- `AddTrainingData(const AInstance: TArray<Double>)` - Add multi-dimensional training data
- `Train` - Build isolation forest from training data
- `DetectMultiDimensional(const AInstance: TArray<Double>): TAnomalyResult` - Multi-dimensional detection
- `NumTrees: Integer` - Number of trees in forest
- `FeatureCount: Integer` - Number of features/dimensions
- `IsTrained: Boolean` - Whether forest has been trained

### TAnomalyConfirmationSystem
- `AddPotentialAnomaly(const AValue: Double)` - Register potential anomaly
- `IsConfirmedAnomaly(const AValue: Double): Boolean` - Check if anomaly is confirmed
- `ConfirmationThreshold: Integer` - Number of similar anomalies needed
- `WindowSize: Integer` - Size of confirmation window
- `Tolerance: Double` - Similarity tolerance for confirmation

### TDetectorPerformanceMonitor
- `StartMeasurement` - Begin timing measurement
- `StopMeasurement(AIsAnomaly: Boolean)` - End timing and record result
- `GetCurrentMetrics: TDetectorMetrics` - Access current metrics
- `GetReport: string` - Formatted performance report
- `Reset` - Clear all metrics
- `Enabled: Boolean` - Enable/disable monitoring

### TAnomalyDetectorFactory
- `CreateDetector(AType: TAnomalyDetectorType): TBaseAnomalyDetector` - Create detector by type
- `CreateForWebTrafficMonitoring: TBaseAnomalyDetector` - Web security optimized
- `CreateForFinancialData: TBaseAnomalyDetector` - Financial precision optimized
- `CreateForIoTSensors: TBaseAnomalyDetector` - IoT reliability optimized
- `CreateForHighDimensionalData: TBaseAnomalyDetector` - ML analysis optimized

## Performance Considerations

### Memory Usage
- **Three Sigma**: O(n) where n is historical data size
- **Sliding Window**: O(window_size) - constant memory after initialization
- **EMA**: O(1) - minimal constant memory
- **Adaptive**: O(window_size) - depends on configured window
- **Isolation Forest**: O(trees × sample_size) during training, O(trees × depth) during detection
- **Confirmation**: O(window_size) - depends on configured window

### Processing Speed
- **Three Sigma**: Fast calculation but requires full dataset
- **Sliding Window**: Moderate - recalculates on each new value  
- **EMA**: Very fast - simple mathematical operations
- **Adaptive**: Fast - minimal calculations per value
- **Isolation Forest**: Slow training, fast detection - O(trees × log(sample_size))
- **Confirmation**: Very fast - queue operations only

### Throughput Benchmarks
Typical performance on modern hardware (single-threaded):
- **EMA**: ~100,000 detections/second
- **Sliding Window**: ~50,000 detections/second
- **Three Sigma**: ~80,000 detections/second (after initial calculation)
- **Adaptive**: ~70,000 detections/second
- **Isolation Forest**: ~20,000 detections/second (multi-dimensional)

## Choosing the Right Algorithm

### For Static Analysis
Use **Three Sigma Detector** when:
- You have complete historical dataset
- Conditions are relatively stable
- You need one-time analysis
- False positives are acceptable

### For Real-time Monitoring
Use **Sliding Window Detector** when:
- Data arrives continuously
- You want to adapt to recent changes
- You have memory constraints
- You need balanced sensitivity and stability

### For Fast Response
Use **EMA Detector** when:
- You need immediate response to changes
- Data patterns change frequently
- You can tolerate some noise
- Minimal memory usage is important

### For Learning Systems
Use **Adaptive Detector** when:
- Normal behavior evolves over time
- You can provide feedback on normal data
- Long-term monitoring is required
- You want to minimize false positives over time

### For Complex Patterns
Use **Isolation Forest** when:
- Data has multiple dimensions/features
- Patterns are complex or non-linear
- You need unsupervised detection
- Traditional statistical methods are insufficient

### For Critical Alerts
Use **Anomaly Confirmation System** when:
- False positives are very costly
- You can afford slight delay in detection
- Multiple detection sources are available
- You need high confidence in alerts

## Running the Demos

### Sample Demos (Console Applications)

All sample applications are located in the `Samples/` directory and demonstrate specific use cases:

```bash
# Data Entry Validation (3 separate demos)
Samples\DataEntrySample\InvoiceValidationDemo.exe    # Invoice amounts per supplier
Samples\DataEntrySample\OrderValidationDemo.exe      # Multi-dimensional fraud detection
Samples\DataEntrySample\TimesheetValidationDemo.exe  # Employee hours with learning

# Three Sigma - Data center temperature monitoring
Samples\ThreeSigmaDetectorSample\ThreeSigmaExample.exe

# Sliding Window - Real-time web traffic monitoring
Samples\SlidingWindowSample\SlidingWindowExample.exe

# EMA - Financial markets monitoring
Samples\EMASample\EMASample.exe

# Adaptive - Server CPU monitoring with learning
Samples\AdaptiveDetectorSample\AdaptiveSample.exe

# DBSCAN - Network intrusion detection
Samples\DBSCANSample\DBSCANExample.exe
```

### Main Interactive Demo
```bash
AnomalyDetectionDemo.exe
```

### Test Menu Options
1. **Classical Algorithms**: Test statistical approaches
2. **Advanced Features**: Try Isolation Forest and multi-dimensional detection
3. **Batch Operations**: Run comprehensive benchmarks
4. **Interactive Configuration**: Tune parameters in real-time
5. **Load Your Data**: Test with CSV files

### Sample Data Generation
The demo can generate realistic sample data for:
- Financial time series with volatility
- IoT sensor readings with drift
- Web traffic with seasonal patterns
- Transaction data with fraud cases

## Best Practices

### 1. Algorithm Selection Strategy
```pascal
// For unknown data characteristics, start with ensemble approach
var Detectors: array[0..2] of TBaseAnomalyDetector;
Detectors[0] := TSlidingWindowDetector.Create(50);
Detectors[1] := TEMAAnomalyDetector.Create(0.1);
Detectors[2] := TAdaptiveAnomalyDetector.Create(100, 0.05);

// Majority voting for robust detection
function EnsembleDetect(Value: Double): Boolean;
var VoteCount: Integer;
begin
  VoteCount := 0;
  for var Detector in Detectors do
    if Detector.IsAnomaly(Value) then Inc(VoteCount);
  Result := VoteCount >= 2; // Majority vote
end;
```

### 2. Parameter Optimization
```pascal
// Use performance monitoring to tune parameters
function OptimizeWindowSize(const TestData: TArray<Double>): Integer;
var
  BestSize, Size: Integer;
  BestF1Score, CurrentF1Score: Double;
  Detector: TSlidingWindowDetector;
begin
  BestF1Score := 0;
  BestSize := 50;
  
  for Size := 10 to 200 do
  begin
    Detector := TSlidingWindowDetector.Create(Size);
    try
      // Test detector and calculate F1 score
      CurrentF1Score := EvaluateDetector(Detector, TestData);
      if CurrentF1Score > BestF1Score then
      begin
        BestF1Score := CurrentF1Score;
        BestSize := Size;
      end;
    finally
      Detector.Free;
    end;
  end;
  
  Result := BestSize;
end;
```

### 3. Production Deployment
```pascal
// Production-ready anomaly detection service
type
  TAnomalyDetectionService = class
  private
    FDetector: TBaseAnomalyDetector;
    FConfirmation: TAnomalyConfirmationSystem;
    FLock: TCriticalSection;
  public
    constructor Create(DetectorType: TAnomalyDetectorType);
    function ProcessValue(Value: Double; out AnomalyInfo: string): Boolean;
    procedure SaveState(const FileName: string);
    procedure LoadState(const FileName: string);
  end;

constructor TAnomalyDetectionService.Create(DetectorType: TAnomalyDetectorType);
begin
  inherited Create;
  FDetector := TAnomalyDetectorFactory.CreateDetector(DetectorType);
  FConfirmation := TAnomalyConfirmationSystem.Create(10, 3, 0.1);
  FLock := TCriticalSection.Create;
end;

function TAnomalyDetectionService.ProcessValue(Value: Double; out AnomalyInfo: string): Boolean;
begin
  FLock.Enter;
  try
    if FDetector.IsAnomaly(Value) then
    begin
      FConfirmation.AddPotentialAnomaly(Value);
      Result := FConfirmation.IsConfirmedAnomaly(Value);
      if Result then
        AnomalyInfo := FDetector.GetAnomalyInfo(Value);
    end
    else
      Result := False;
  finally
    FLock.Leave;
  end;
end;
```

### 4. Data Preprocessing
```pascal
// Normalize data for better detection
function NormalizeData(const RawData: TArray<Double>): TArray<Double>;
var
  i: Integer;
  Mean, StdDev, Sum, SumSquares: Double;
begin
  // Calculate mean and standard deviation
  Sum := 0;
  for i := 0 to High(RawData) do
    Sum := Sum + RawData[i];
  Mean := Sum / Length(RawData);
  
  SumSquares := 0;
  for i := 0 to High(RawData) do
    SumSquares := SumSquares + Power(RawData[i] - Mean, 2);
  StdDev := Sqrt(SumSquares / (Length(RawData) - 1));
  
  // Z-score normalization
  SetLength(Result, Length(RawData));
  for i := 0 to High(RawData) do
    Result[i] := (RawData[i] - Mean) / StdDev;
end;
```

## Common Business Applications

### E-commerce
- **Fraud Detection**: Multi-dimensional transaction analysis using Isolation Forest
- **Inventory Anomalies**: Stock level monitoring with Sliding Window
- **Customer Behavior**: Purchase pattern changes with Adaptive Detector
- **Price Monitoring**: Competitive pricing anomalies with EMA

### Manufacturing
- **Quality Control**: Statistical process control with Three Sigma
- **Predictive Maintenance**: Equipment sensor monitoring with Sliding Window
- **Supply Chain**: Delivery time anomalies with Adaptive Detector
- **Energy Consumption**: Usage pattern analysis with EMA

### Finance
- **Market Surveillance**: Trading pattern anomalies with Isolation Forest
- **Risk Management**: Portfolio deviation monitoring with Multiple Detectors
- **Compliance**: Regulatory threshold monitoring with Confirmation System
- **Algorithmic Trading**: Price movement detection with EMA

### IT Operations
- **Performance Monitoring**: System metrics with Sliding Window
- **Security**: Intrusion detection with Isolation Forest
- **Capacity Planning**: Resource usage trends with Adaptive Detector
- **SLA Monitoring**: Response time anomalies with Confirmation System

## Data Entry Validation Examples

The library can be effectively used to detect anomalies during data entry operations, helping prevent user errors and identify suspicious input patterns.

### Example 1: Invoice Amount Validation

Detect unusual invoice amounts based on historical data for a specific supplier:

```pascal
type
  TInvoiceValidator = class
  private
    FDetectors: TDictionary<string, TSlidingWindowDetector>;
  public
    constructor Create;
    destructor Destroy; override;
    function ValidateInvoiceAmount(const ASupplierCode: string;
                                   AAmount: Double;
                                   out AWarning: string): Boolean;
  end;

constructor TInvoiceValidator.Create;
begin
  inherited;
  FDetectors := TDictionary<string, TSlidingWindowDetector>.Create;
end;

destructor TInvoiceValidator.Destroy;
var
  Detector: TSlidingWindowDetector;
begin
  for Detector in FDetectors.Values do
    Detector.Free;
  FDetectors.Free;
  inherited;
end;

function TInvoiceValidator.ValidateInvoiceAmount(const ASupplierCode: string;
                                                  AAmount: Double;
                                                  out AWarning: string): Boolean;
var
  Detector: TSlidingWindowDetector;
  AnomalyResult: TAnomalyResult;
begin
  // Get or create detector for this supplier
  if not FDetectors.TryGetValue(ASupplierCode, Detector) then
  begin
    Detector := TSlidingWindowDetector.Create(50); // Track last 50 invoices
    FDetectors.Add(ASupplierCode, Detector);
  end;

  // Check for anomaly
  AnomalyResult := Detector.Detect(AAmount);

  if AnomalyResult.IsAnomaly then
  begin
    AWarning := Format('Unusual amount for supplier %s: %.2f € ' +
                       '(Expected range: %.2f - %.2f €, Z-score: %.2f)',
                       [ASupplierCode, AAmount,
                        AnomalyResult.LowerLimit, AnomalyResult.UpperLimit,
                        AnomalyResult.ZScore]);
    Result := False; // Requires verification
  end
  else
  begin
    AWarning := '';
    Result := True; // Normal amount
  end;

  // Add to history for learning
  Detector.AddValue(AAmount);
end;

// Usage in data entry form
procedure TInvoiceEntryForm.ValidateInvoiceClick(Sender: TObject);
var
  SupplierCode: string;
  Amount: Double;
  Warning: string;
begin
  SupplierCode := edtSupplierCode.Text;
  Amount := StrToFloat(edtAmount.Text);

  if not FValidator.ValidateInvoiceAmount(SupplierCode, Amount, Warning) then
  begin
    // Show warning to user
    if MessageDlg('Anomaly Detected',
                  Warning + #13#10#13#10 + 'Do you want to proceed anyway?',
                  mtWarning, [mbYes, mbNo], 0) = mrNo then
      Exit;
  end;

  // Save invoice...
end;
```

### Example 2: Multi-Field Order Validation

Validate order patterns using multiple fields (amount, quantity, discount) with Isolation Forest:

```pascal
type
  TOrderValidator = class
  private
    FDetector: TIsolationForestDetector;
    FIsTraining: Boolean;
    FTrainingCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddTrainingOrder(AAmount, AQuantity, ADiscount: Double);
    procedure FinishTraining;
    function ValidateOrder(AAmount, AQuantity, ADiscount: Double;
                          out ASuspicionLevel: string): Boolean;
  end;

constructor TOrderValidator.Create;
begin
  inherited;
  // 3 dimensions: Amount, Quantity, Discount%
  FDetector := TIsolationForestDetector.Create(100, 256, 3);
  FIsTraining := True;
  FTrainingCount := 0;
end;

destructor TOrderValidator.Destroy;
begin
  FDetector.Free;
  inherited;
end;

procedure TOrderValidator.AddTrainingOrder(AAmount, AQuantity, ADiscount: Double);
begin
  if FIsTraining then
  begin
    FDetector.AddTrainingData([AAmount, AQuantity, ADiscount]);
    Inc(FTrainingCount);

    // Auto-train after 1000 samples
    if FTrainingCount >= 1000 then
      FinishTraining;
  end;
end;

procedure TOrderValidator.FinishTraining;
begin
  if FIsTraining and (FTrainingCount > 0) then
  begin
    FDetector.Train;
    FIsTraining := False;
  end;
end;

function TOrderValidator.ValidateOrder(AAmount, AQuantity, ADiscount: Double;
                                       out ASuspicionLevel: string): Boolean;
var
  AnomalyResult: TAnomalyResult;
  OrderData: TArray<Double>;
begin
  if FIsTraining then
  begin
    ASuspicionLevel := 'System still learning (collecting data)';
    Result := True; // Allow during training
    AddTrainingOrder(AAmount, AQuantity, ADiscount);
    Exit;
  end;

  OrderData := [AAmount, AQuantity, ADiscount];
  AnomalyResult := FDetector.DetectMultiDimensional(OrderData);

  if AnomalyResult.IsAnomaly then
  begin
    // Classify suspicion level based on anomaly score
    if AnomalyResult.ZScore > 2.0 then
      ASuspicionLevel := 'HIGH - Highly unusual order pattern detected'
    else if AnomalyResult.ZScore > 1.0 then
      ASuspicionLevel := 'MEDIUM - Uncommon order combination'
    else
      ASuspicionLevel := 'LOW - Slightly unusual order';

    Result := False;
  end
  else
  begin
    ASuspicionLevel := 'Normal order pattern';
    Result := True;
  end;
end;

// Usage in order entry form
procedure TOrderEntryForm.btnValidateClick(Sender: TObject);
var
  Amount, Quantity, Discount: Double;
  SuspicionLevel: string;
begin
  Amount := StrToFloat(edtAmount.Text);
  Quantity := StrToFloat(edtQuantity.Text);
  Discount := StrToFloat(edtDiscount.Text);

  if not FOrderValidator.ValidateOrder(Amount, Quantity, Discount, SuspicionLevel) then
  begin
    // Show alert panel
    pnlWarning.Visible := True;
    lblWarning.Caption := 'ANOMALY DETECTED: ' + SuspicionLevel;
    lblWarning.Font.Color := clRed;

    // Log for audit
    LogAnomalousOrder(Amount, Quantity, Discount, SuspicionLevel);
  end
  else
  begin
    pnlWarning.Visible := False;
  end;
end;
```

### Example 3: Real-time Employee Hours Validation

Detect anomalous timesheet entries using Adaptive Detector:

```pascal
type
  TTimesheetValidator = class
  private
    FDetectorsByEmployee: TDictionary<Integer, TAdaptiveAnomalyDetector>;
  public
    constructor Create;
    destructor Destroy; override;
    function ValidateHours(AEmployeeID: Integer; AHours: Double;
                          out AMessage: string): TValidationLevel;
    procedure ConfirmNormalHours(AEmployeeID: Integer; AHours: Double);
  end;

type
  TValidationLevel = (vlNormal, vlWarning, vlError);

constructor TTimesheetValidator.Create;
begin
  inherited;
  FDetectorsByEmployee := TDictionary<Integer, TAdaptiveAnomalyDetector>.Create;
end;

destructor TTimesheetValidator.Destroy;
var
  Detector: TAdaptiveAnomalyDetector;
begin
  for Detector in FDetectorsByEmployee.Values do
    Detector.Free;
  FDetectorsByEmployee.Free;
  inherited;
end;

function TTimesheetValidator.ValidateHours(AEmployeeID: Integer;
                                           AHours: Double;
                                           out AMessage: string): TValidationLevel;
var
  Detector: TAdaptiveAnomalyDetector;
  AnomalyResult: TAnomalyResult;
  HistoricalData: TArray<Double>;
  i: Integer;
begin
  // Get or create detector for this employee
  if not FDetectorsByEmployee.TryGetValue(AEmployeeID, Detector) then
  begin
    Detector := TAdaptiveAnomalyDetector.Create(30, 0.05); // 30-day window, slow adaptation

    // Initialize with typical 8-hour workdays (if no history available)
    SetLength(HistoricalData, 20);
    for i := 0 to High(HistoricalData) do
      HistoricalData[i] := 7.5 + Random * 1.5; // 7.5-9 hours
    Detector.InitializeWithNormalData(HistoricalData);

    FDetectorsByEmployee.Add(AEmployeeID, Detector);
  end;

  AnomalyResult := Detector.Detect(AHours);

  if AnomalyResult.IsAnomaly then
  begin
    if AHours > AnomalyResult.UpperLimit then
    begin
      // Overtime or data entry error
      if AHours > 16 then
      begin
        AMessage := Format('ERROR: %.1f hours exceeds physical limit. ' +
                          'Expected max: %.1f hours',
                          [AHours, AnomalyResult.UpperLimit]);
        Result := vlError; // Block entry
      end
      else
      begin
        AMessage := Format('WARNING: %.1f hours is unusually high. ' +
                          'Typical range: %.1f - %.1f hours',
                          [AHours, AnomalyResult.LowerLimit, AnomalyResult.UpperLimit]);
        Result := vlWarning; // Require confirmation
      end;
    end
    else
    begin
      // Unusually low hours
      AMessage := Format('WARNING: %.1f hours is unusually low. ' +
                        'Typical minimum: %.1f hours',
                        [AHours, AnomalyResult.LowerLimit]);
      Result := vlWarning;
    end;
  end
  else
  begin
    AMessage := 'Normal working hours';
    Result := vlNormal;
  end;
end;

procedure TTimesheetValidator.ConfirmNormalHours(AEmployeeID: Integer; AHours: Double);
var
  Detector: TAdaptiveAnomalyDetector;
begin
  // User confirmed hours are correct - teach the detector
  if FDetectorsByEmployee.TryGetValue(AEmployeeID, Detector) then
    Detector.UpdateNormal(AHours); // Adapt to new normal pattern
end;

// Usage in timesheet form
procedure TTimesheetForm.edtHoursExit(Sender: TObject);
var
  Hours: Double;
  Message: string;
  ValidationLevel: TValidationLevel;
begin
  if not TryStrToFloat(edtHours.Text, Hours) then
    Exit;

  ValidationLevel := FValidator.ValidateHours(FCurrentEmployeeID, Hours, Message);

  case ValidationLevel of
    vlNormal:
      begin
        lblValidation.Caption := Message;
        lblValidation.Font.Color := clGreen;
      end;

    vlWarning:
      begin
        lblValidation.Caption := Message;
        lblValidation.Font.Color := clOrange;

        if MessageDlg('Confirm Hours',
                      Message + #13#10#13#10 + 'Is this correct?',
                      mtConfirmation, [mbYes, mbNo], 0) = mrYes then
        begin
          // User confirmed - teach the detector
          FValidator.ConfirmNormalHours(FCurrentEmployeeID, Hours);
        end;
      end;

    vlError:
      begin
        lblValidation.Caption := Message;
        lblValidation.Font.Color := clRed;
        edtHours.SetFocus;
        MessageDlg('Invalid Entry', Message, mtError, [mbOK], 0);
      end;
  end;
end;
```

### Example 4: Bank Transaction Input Validation

Prevent fraudulent transactions using real-time pattern analysis:

```pascal
type
  TTransactionValidator = class
  private
    FAmountDetector: TEMAAnomalyDetector;
    FFrequencyDetector: TSlidingWindowDetector;
    FLastTransactionTime: TDateTime;
    FDailyTransactionCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    function ValidateTransaction(AAmount: Double;
                                out ARiskLevel: string): Boolean;
  end;

constructor TTransactionValidator.Create;
begin
  inherited;
  // EMA for fast detection of amount changes
  FAmountDetector := TEMAAnomalyDetector.Create(0.1); // Fast adaptation

  // Sliding window for frequency monitoring
  FFrequencyDetector := TSlidingWindowDetector.Create(100); // Last 100 transactions

  FLastTransactionTime := Now;
  FDailyTransactionCount := 0;
end;

destructor TTransactionValidator.Destroy;
begin
  FAmountDetector.Free;
  FFrequencyDetector.Free;
  inherited;
end;

function TTransactionValidator.ValidateTransaction(AAmount: Double;
                                                   out ARiskLevel: string): Boolean;
var
  AmountResult: TAnomalyResult;
  TimeSinceLastTransaction: Double; // in minutes
  FrequencyResult: TAnomalyResult;
begin
  Result := True; // Assume valid
  ARiskLevel := 'LOW';

  // Check 1: Amount anomaly
  AmountResult := FAmountDetector.Detect(AAmount);
  if AmountResult.IsAnomaly then
  begin
    if AAmount > AmountResult.UpperLimit * 2 then
    begin
      ARiskLevel := 'CRITICAL - Amount is ' +
                    FormatFloat('0.0', AmountResult.ZScore) +
                    'σ above normal';
      Result := False; // Block transaction
      Exit;
    end
    else
    begin
      ARiskLevel := 'HIGH - Unusual amount detected';
      // Continue checking other factors
    end;
  end;

  // Check 2: Transaction frequency
  TimeSinceLastTransaction := MinutesBetween(Now, FLastTransactionTime);
  FFrequencyDetector.AddValue(TimeSinceLastTransaction);
  FrequencyResult := FFrequencyDetector.Detect(TimeSinceLastTransaction);

  if FrequencyResult.IsAnomaly and (TimeSinceLastTransaction < 1) then
  begin
    // Transactions less than 1 minute apart
    if ARiskLevel.StartsWith('HIGH') then
      ARiskLevel := 'CRITICAL - Rapid transactions with unusual amounts'
    else
      ARiskLevel := 'HIGH - Unusually rapid transaction frequency';
    Result := False;
    Exit;
  end;

  // Check 3: Daily transaction count
  if Date <> DateOf(FLastTransactionTime) then
    FDailyTransactionCount := 0;
  Inc(FDailyTransactionCount);

  if FDailyTransactionCount > 50 then
  begin
    ARiskLevel := 'HIGH - Daily transaction limit concern';
    Result := False;
    Exit;
  end;

  // Update state
  FLastTransactionTime := Now;
  if Result then
    FAmountDetector.AddValue(AAmount); // Learn from normal transactions only
end;

// Usage in banking form
procedure TBankingForm.ProcessTransaction(AAmount: Double);
var
  RiskLevel: string;
  IsValid: Boolean;
begin
  IsValid := FValidator.ValidateTransaction(AAmount, RiskLevel);

  // Display risk level
  lblRisk.Caption := 'Risk Level: ' + RiskLevel;

  if RiskLevel.StartsWith('CRITICAL') then
    lblRisk.Font.Color := clRed
  else if RiskLevel.StartsWith('HIGH') then
    lblRisk.Font.Color := clOrange
  else
    lblRisk.Font.Color := clGreen;

  if not IsValid then
  begin
    // Require additional authentication
    if not RequireAdditionalAuth(RiskLevel) then
    begin
      ShowMessage('Transaction blocked due to suspicious pattern');
      Exit;
    end;
  end;

  // Process transaction...
  ExecuteTransaction(AAmount);
end;
```

These data entry examples demonstrate how the library can be integrated into business applications to provide real-time validation and fraud prevention during data entry operations.

### Running the Data Entry Demos

**Three separate, focused demo applications** are available in `Samples/DataEntrySample/`:

```bash
# Invoice validation - Per-supplier amount validation
Samples\DataEntrySample\InvoiceValidationDemo.exe

# Order validation - Multi-dimensional fraud detection
Samples\DataEntrySample\OrderValidationDemo.exe

# Timesheet validation - Adaptive employee hours
Samples\DataEntrySample\TimesheetValidationDemo.exe
```

Each demo is a standalone program with reusable validation classes:

**1. Invoice Validation Demo** (uses `InvoiceValidator.pas`)
   - Per-supplier amount validation using Sliding Window
   - Learns normal invoice ranges for each supplier independently
   - Catches data entry errors: typos, decimal point errors, wrong supplier
   - Example: "5000€ is normal for SUP002 but anomalous for SUP001"

**2. Order Validation Demo** (uses `OrderValidator.pas`)
   - Multi-dimensional fraud detection using Isolation Forest
   - Analyzes combinations of Amount, Quantity, and Discount%
   - Detects complex fraud patterns like "high amount + excessive discount"
   - Trains on 500 normal orders before activation

**3. Timesheet Validation Demo** (uses `TimesheetValidator.pas`)
   - Adaptive employee hours validation with learning
   - Per-employee baselines with 3-level validation (Normal/Warning/Error)
   - Learns from user confirmations (feedback loop)
   - Blocks physically impossible entries (>16 hours)

**Key Features Demonstrated:**
- ✓ Real-time validation during data entry
- ✓ Per-entity learning (per supplier, per employee)
- ✓ Multi-level validation (Normal, Warning, Error)
- ✓ User feedback integration (adaptive learning)
- ✓ Fraud prevention through pattern analysis
- ✓ Reusable validator classes ready for integration

## Testing and Validation

### Unit Testing
The library includes comprehensive unit tests (`AnomalyDetectionAlgorithmsTests.pas`) covering:
- Algorithm correctness
- Edge cases and error conditions
- Performance characteristics
- Thread safety
- State persistence

### Integration Testing
Run the test runner:
```bash
AnomalyDetectionTestRunner.exe
```

### Validation Metrics
- **Precision**: True Positives / (True Positives + False Positives)
- **Recall**: True Positives / (True Positives + False Negatives)
- **F1-Score**: 2 × (Precision × Recall) / (Precision + Recall)
- **False Positive Rate**: False Positives / (False Positives + True Negatives)

## Version History

### v2.0.0
- Added Isolation Forest algorithm for multi-dimensional detection
- Implemented comprehensive performance monitoring system
- Added Factory pattern for domain-optimized detectors
- Enhanced demo with interactive features and real-world scenarios
- Added CSV import/export capabilities
- Improved ASCII visualization
- Added comparative benchmarking suite
- Enhanced thread safety and error handling

### v1.0.0
- Initial release
- Five statistical anomaly detection algorithms implemented
- Comprehensive demo application
- Full documentation and examples

## System Requirements

- **Delphi**: 10.3 Rio or later (uses modern language features)
- **Platform**: Windows, macOS, Linux (via FMX), iOS, Android
- **Memory**: Minimal (algorithms are memory-efficient)
- **Dependencies**: None (pure Delphi implementation)

## Performance Tuning

### Memory Optimization
```pascal
// For memory-constrained environments
var Config: TAnomalyDetectionConfig;
Config := TAnomalyDetectionConfig.Default;
Config.MinStdDev := 0.1; // Higher threshold = less sensitive

// Use EMA for minimal memory footprint
Detector := TEMAAnomalyDetector.Create(0.05, Config);
```

### Speed Optimization
```pascal
// For high-throughput scenarios
Detector.PerformanceMonitor.Enabled := False; // Disable monitoring
// Use smaller window sizes for Sliding Window detector
// Use higher alpha values for EMA detector
```

## Troubleshooting

### Common Issues

**"Statistics not calculated" Error**
```pascal
// Ensure you call CalculateStatistics after setting data
Detector.SetHistoricalData(Data);
Detector.CalculateStatistics; // Don't forget this!
```

**High False Positive Rate**
```pascal
// Increase sigma multiplier or use confirmation system
Config.SigmaMultiplier := 4.0; // Less sensitive
ConfirmationSystem := TAnomalyConfirmationSystem.Create(5, 3, 0.05);
```

**Memory Usage Growing**
```pascal
// For streaming data, use fixed-window detectors
SlidingDetector := TSlidingWindowDetector.Create(100); // Fixed memory
// Avoid Three Sigma detector for continuous streams
```

## Performance Evaluation & Hyperparameter Tuning

The library includes a comprehensive evaluation framework for measuring detector performance and optimizing hyperparameters based on labeled datasets.

### Confusion Matrix & Classification Metrics

Evaluate your detector's performance using standard machine learning metrics:

```pascal
uses AnomalyDetection.Evaluation;

var
  Dataset: TLabeledDataset;
  Detector: IAnomalyDetector;
  Evaluator: TAnomalyDetectorEvaluator;
  Result: TEvaluationResult;
begin
  // Create labeled dataset (ground truth)
  Dataset := TLabeledDataset.Create('My Dataset');
  try
    // Add labeled data points
    Dataset.AddPoint(100, False, 'Normal');  // Value, IsAnomaly, Description
    Dataset.AddPoint(500, True, 'Anomaly');

    // Or generate synthetic data for testing
    Dataset.GenerateMixedDataset(1000, 50, 100.0, 10.0);  // 1000 normal, 50 anomalies

    // Evaluate detector
    Detector := Factory.CreateDetector(adtThreeSigma, 'Test');
    Evaluator := TAnomalyDetectorEvaluator.Create(Detector, Dataset);
    try
      Result := Evaluator.Evaluate;

      // View results
      WriteLn(Result.ConfusionMatrix.ToDetailedString);
      WriteLn('Accuracy:  ', Result.ConfusionMatrix.GetAccuracy:0:3);
      WriteLn('Precision: ', Result.ConfusionMatrix.GetPrecision:0:3);
      WriteLn('Recall:    ', Result.ConfusionMatrix.GetRecall:0:3);
      WriteLn('F1-Score:  ', Result.ConfusionMatrix.GetF1Score:0:3);
    finally
      Evaluator.Free;
    end;
  finally
    Dataset.Free;
  end;
end;
```

**Confusion Matrix Output Example:**
```
                 Predicted
               Anomaly  Normal
Actual Anomaly    45      5      (TP=45, FN=5)
       Normal     20    930      (FP=20, TN=930)

Metrics:
  Accuracy:  0.975 (97.5% of predictions correct)
  Precision: 0.692 (of detected anomalies, 69.2% were correct)
  Recall:    0.900 (detected 90.0% of actual anomalies)
  F1-Score:  0.783 (harmonic mean of precision and recall)
```

**Key Metrics Explained:**

- **True Positives (TP)**: Correctly identified anomalies
- **False Positives (FP)**: Normal data incorrectly marked as anomaly (false alarms)
- **True Negatives (TN)**: Correctly identified normal data
- **False Negatives (FN)**: Anomalies missed by detector (missed detections)

- **Accuracy**: Overall correctness = (TP + TN) / Total
- **Precision**: When detector says "anomaly", how often is it right? = TP / (TP + FP)
- **Recall**: Of all real anomalies, what % did we detect? = TP / (TP + FN)
- **F1-Score**: Harmonic mean of Precision and Recall = 2 × (P × R) / (P + R)

### Cross-Validation

Test detector robustness with K-Fold cross-validation:

```pascal
var
  Results: TArray<TEvaluationResult>;
begin
  Results := Evaluator.CrossValidate(5);  // 5-fold cross-validation

  WriteLn(Evaluator.GenerateCrossValidationReport(Results));
  // Shows average metrics across all folds
end;
```

### Train/Test Split

Evaluate on held-out test data:

```pascal
var
  Result: TEvaluationResult;
begin
  // Train on 70%, test on 30%
  Result := Evaluator.EvaluateWithTrainTestSplit(0.7);

  WriteLn('Tested on ', Result.DatasetSize, ' unseen examples');
  WriteLn('F1-Score: ', Result.ConfusionMatrix.GetF1Score:0:3);
end;
```

### Hyperparameter Tuning

Find optimal hyperparameters using Grid Search or Random Search:

#### Grid Search (Exhaustive)

```pascal
uses AnomalyDetection.Evaluation;

var
  Dataset: TLabeledDataset;
  Tuner: THyperparameterTuner;
  BestConfig: TTuningResult;
  SigmaValues: TArray<Double>;
  WindowSizes: TArray<Integer>;
begin
  // Create dataset
  Dataset := TLabeledDataset.Create('Training Data');
  Dataset.GenerateMixedDataset(1000, 100, 100.0, 10.0);

  // Create tuner
  Tuner := THyperparameterTuner.Create(adtSlidingWindow, Dataset);
  try
    Tuner.OptimizationMetric := 'F1';  // Can be 'Precision', 'Recall', 'F1', or 'Accuracy'
    Tuner.Verbose := True;

    // Define search space
    SigmaValues := [2.0, 2.5, 3.0, 3.5, 4.0];
    WindowSizes := [50, 100, 150, 200];

    // Perform grid search (tests all 20 combinations)
    BestConfig := Tuner.GridSearch(SigmaValues, nil, WindowSizes, nil);

    WriteLn('Best configuration found:');
    WriteLn('  Sigma: ', BestConfig.Config.SigmaMultiplier:0:2);
    WriteLn('  Window: ', BestConfig.Config.WindowSize);
    WriteLn('  F1-Score: ', BestConfig.Score:0:3);

    // View full report with top 5 configurations
    WriteLn(Tuner.GenerateTuningReport);
  finally
    Tuner.Free;
    Dataset.Free;
  end;
end;
```

#### Random Search (Faster)

```pascal
var
  BestConfig: TTuningResult;
begin
  Tuner := THyperparameterTuner.Create(adtEMA, Dataset);
  try
    Tuner.OptimizationMetric := 'Recall';  // Optimize for catching all anomalies

    // Test 50 random configurations (much faster than grid search)
    BestConfig := Tuner.RandomSearch(50);

    WriteLn('Best random config: ', BestConfig.ToString);
  finally
    Tuner.Free;
  end;
end;
```

### Optimization Metric Selection

Choose the metric based on business objectives:

**Optimize for PRECISION** (minimize false positives):
- **Use Case**: Alert systems where false alarms are costly (e.g., 24/7 monitoring, alert fatigue)
- **Goal**: When detector says "anomaly", you want high confidence it's real
- **Trade-off**: May miss some real anomalies (lower recall)

```pascal
Tuner.OptimizationMetric := 'Precision';
```

**Optimize for RECALL** (minimize false negatives):
- **Use Case**: Critical systems where missing anomalies is unacceptable (e.g., fraud detection, security)
- **Goal**: Catch every real anomaly, even if it means more false alarms
- **Trade-off**: More false positives (alert fatigue risk)

```pascal
Tuner.OptimizationMetric := 'Recall';
```

**Optimize for F1-SCORE** (balanced):
- **Use Case**: General-purpose applications requiring balance
- **Goal**: Good compromise between precision and recall
- **Trade-off**: May not excel at either extreme

```pascal
Tuner.OptimizationMetric := 'F1';
```

**Optimize for ACCURACY**:
- **Use Case**: Only when dataset is balanced (similar number of anomalies and normal points)
- **Caution**: Can be misleading with imbalanced data (e.g., 1% anomalies)

```pascal
Tuner.OptimizationMetric := 'Accuracy';
```

### Real-World Tuning Example

```pascal
// Example: Tuning for financial fraud detection
// Business requirement: Must catch 95%+ of fraud (high recall),
// acceptable to investigate some false positives

procedure OptimizeForFraudDetection;
var
  Dataset: TLabeledDataset;
  Tuner: THyperparameterTuner;
  BestConfig: TTuningResult;
begin
  // Load real fraud data with labels
  Dataset := TLabeledDataset.Create('Transaction History');
  Dataset.LoadFromCSV('fraud_data.csv', 0, 1, True);  // Value col 0, Label col 1

  WriteLn('Dataset: ', Dataset.Data.Count, ' transactions');
  WriteLn('Fraud rate: ', Dataset.GetAnomalyPercentage:0:2, '%');

  // Tune for maximum recall (catch all fraud)
  Tuner := THyperparameterTuner.Create(adtThreeSigma, Dataset);
  try
    Tuner.OptimizationMetric := 'Recall';

    // Lower sigma = more sensitive = higher recall
    BestConfig := Tuner.GridSearch([1.5, 2.0, 2.5, 3.0]);

    WriteLn('Optimal configuration:');
    WriteLn('  Recall:    ', BestConfig.EvaluationResult.ConfusionMatrix.GetRecall:0:3);
    WriteLn('  Precision: ', BestConfig.EvaluationResult.ConfusionMatrix.GetPrecision:0:3);
    WriteLn('  Will catch ', (BestConfig.EvaluationResult.ConfusionMatrix.GetRecall * 100):0:1, '% of fraud');
    WriteLn('  ', BestConfig.EvaluationResult.ConfusionMatrix.FalsePositives, ' false alarms per ',
            BestConfig.EvaluationResult.DatasetSize, ' transactions');
  finally
    Tuner.Free;
    Dataset.Free;
  end;
end;
```

### Loading Real Data from CSV

```pascal
Dataset.LoadFromCSV('sensor_data.csv',
  0,     // Value column index
  1,     // Label column index (0=normal, 1=anomaly)
  True   // Has header row
);
```

**CSV Format Example:**
```csv
temperature,is_anomaly,timestamp
98.2,0,2024-01-01 10:00
99.1,0,2024-01-01 10:01
150.5,1,2024-01-01 10:02
98.7,0,2024-01-01 10:03
```

### Demo Programs

The library includes two comprehensive demo programs:

**`01_EvaluationDemo.dpr`** - Performance Evaluation
- Basic detector evaluation with confusion matrix
- Comparing multiple detectors
- K-fold cross-validation
- Real-world scenario (server response times)

**`02_HyperparameterTuningDemo.dpr`** - Hyperparameter Optimization
- Grid search for optimal sigma multiplier
- 2D tuning (sigma + window size)
- EMA alpha parameter tuning
- Grid vs Random search comparison
- Optimizing for different business objectives

Run these demos to understand evaluation and tuning workflows:
```bash
Samples\01_EvaluationDemo.exe
Samples\02_HyperparameterTuningDemo.exe
```

## License

This library is commercial software.

## Contributing

Contributions are welcome! Areas for contribution:
- New detection algorithms (LSTM, Autoencoders, etc.)
- Performance optimizations
- Additional visualization features
- Platform-specific optimizations
- Documentation improvements

## Complete Professional Workflow

See **[PROFESSIONAL_CHECKLIST.md](PROFESSIONAL_CHECKLIST.md)** for a comprehensive end-to-end production pipeline example covering:

1. **Data Cleaning** - Remove outliers with percentile or IQR methods
2. **Dataset Preparation** - Load labeled data for validation
3. **Hyperparameter Tuning** - Grid/Random search for optimal configuration
4. **Detector Training** - Create production detector with clean data
5. **Final Validation** - Evaluate with confusion matrix and metrics
6. **Production Deployment** - Save detector state for production use

The checklist includes complete working code and explains when to use each tool and technique.

---

## Support

For issues, questions, or feature requests:
- Open an issue on the project repository
- Contact: d.teti@bittime.it
- Website: https://www.danieleteti.it
- Professional services: https://www.bittimeprofessionals.com

## Credits

**Author**: Daniele Teti  
**Company**: Bit Time Professionals  
**Framework**: Built with expertise from DelphiMVCFramework development

Developed for business applications requiring robust, practical anomaly detection solutions. Inspired by statistical process control, machine learning anomaly detection techniques, and real-world production requirements.

## References

- Statistical Process Control principles
- Isolation Forest: Liu, F. T., Ting, K. M., & Zhou, Z. H. (2008)
- Exponential Smoothing: Brown, R. G. (1959)
- Modern anomaly detection surveys and best practices
