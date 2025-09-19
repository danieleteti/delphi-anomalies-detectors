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
    // Set historical data
    Data := [100, 105, 98, 102, 107, 99, 103, 101, 104, 106];
    Detector.SetHistoricalData(Data);
    Detector.CalculateStatistics;
    
    // Check for anomalies with detailed results
    Result := Detector.Detect(150);
    if Result.IsAnomaly then
      WriteLn(Format('Anomaly detected: %.2f (Z-score: %.2f)', [Result.Value, Result.ZScore]));
  finally
    Detector.Free;
  end;
end;
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

## Running the Demo

### Basic Demo
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

## License

This library is commercial software.

## Contributing

Contributions are welcome! Areas for contribution:
- New detection algorithms (LSTM, Autoencoders, etc.)
- Performance optimizations
- Additional visualization features
- Platform-specific optimizations
- Documentation improvements

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
