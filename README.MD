# Anomaly Detection Algorithms Library

A comprehensive Delphi library for detecting anomalies in business data using various statistical approaches. This library provides multiple anomaly detection algorithms suitable for different scenarios, from historical data analysis to real-time streaming data monitoring.

## Features

- **Multiple Detection Algorithms**: Implements 4 different approaches for various use cases
- **Memory Safe**: No memory leaks, proper object lifetime management
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

### 5. Anomaly Confirmation System (`TAnomalyConfirmationSystem`)

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
begin
  Detector := TThreeSigmaDetector.Create;
  try
    // Set historical data
    Data := [100, 105, 98, 102, 107, 99, 103, 101, 104, 106];
    Detector.SetHistoricalData(Data);
    Detector.CalculateStatistics;
    
    // Check for anomalies
    if Detector.IsAnomaly(150) then
      WriteLn(Detector.GetAnomalyInfo(150));
  finally
    Detector.Free;
  end;
end;
```

### Real-time Monitoring - Sliding Window
```pascal
var
  Detector: TSlidingWindowDetector;
begin
  Detector := TSlidingWindowDetector.Create(100); // 100-value window
  try
    // Process streaming data
    while HasNewData do
    begin
      var NewValue := GetNextDataPoint;
      Detector.AddValue(NewValue);
      
      if Detector.IsAnomaly(NewValue) then
        TriggerAlert(Detector.GetAnomalyInfo(NewValue));
    end;
  finally
    Detector.Free;
  end;
end;
```

### Fast Adaptation - EMA Detector
```pascal
var
  Detector: TEMAAnomalyDetector;
begin
  Detector := TEMAAnomalyDetector.Create(0.1); // Fast adaptation
  try
    // Process real-time data stream
    for var Value in DataStream do
    begin
      Detector.AddValue(Value);
      if Detector.IsAnomaly(Value) then
        HandleAnomaly(Value);
    end;
  finally
    Detector.Free;
  end;
end;
```

## API Reference

### Base Class Methods (All Detectors)
- `IsAnomaly(const AValue: Double): Boolean` - Check if value is anomalous
- `GetAnomalyInfo(const AValue: Double): string` - Get detailed anomaly information
- `Name: string` - Readable name of the detector

### TThreeSigmaDetector
- `SetHistoricalData(const AData: TArray<Double>)` - Set historical data
- `CalculateStatistics` - Calculate mean, std dev, and limits
- `Mean: Double` - Calculated mean
- `StdDev: Double` - Calculated standard deviation
- `LowerLimit: Double` - Lower 3-sigma limit
- `UpperLimit: Double` - Upper 3-sigma limit

### TSlidingWindowDetector
- `AddValue(const AValue: Double)` - Add new value and recalculate
- `RecalculateStatistics` - Manually trigger statistics recalculation
- `CurrentMean: Double` - Current window mean
- `CurrentStdDev: Double` - Current window standard deviation
- `WindowSize: Integer` - Size of the sliding window

### TEMAAnomalyDetector
- `AddValue(const AValue: Double)` - Add new value and update EMA
- `CurrentMean: Double` - Current exponential moving average
- `CurrentStdDev: Double` - Current standard deviation estimate
- `Alpha: Double` - Adaptation rate parameter

### TAdaptiveAnomalyDetector
- `ProcessValue(const AValue: Double)` - Process new value
- `UpdateNormal(const AValue: Double)` - Confirm value as normal (for learning)
- `CurrentMean: Double` - Current adaptive mean
- `CurrentStdDev: Double` - Current adaptive standard deviation

### TAnomalyConfirmationSystem
- `AddPotentialAnomaly(const AValue: Double)` - Register potential anomaly
- `IsConfirmedAnomaly(const AValue: Double): Boolean` - Check if anomaly is confirmed
- `ConfirmationThreshold: Integer` - Number of similar anomalies needed
- `WindowSize: Integer` - Size of confirmation window

## Performance Considerations

### Memory Usage
- **Three Sigma**: O(n) where n is historical data size
- **Sliding Window**: O(window_size) - constant memory after initialization
- **EMA**: O(1) - minimal constant memory
- **Adaptive**: O(window_size) - depends on configured window
- **Confirmation**: O(window_size) - depends on configured window

### Processing Speed
- **Three Sigma**: Fast calculation but requires full dataset
- **Sliding Window**: Moderate - recalculates on each new value
- **EMA**: Very fast - simple mathematical operations
- **Adaptive**: Fast - minimal calculations per value
- **Confirmation**: Very fast - queue operations only

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

### For Critical Alerts
Use **Anomaly Confirmation System** when:
- False positives are very costly
- You can afford slight delay in detection
- Multiple detection sources are available
- You need high confidence in alerts

## Best Practices

### 1. Combine Multiple Detectors
For critical applications, use multiple detectors together:
```pascal
// Alert only when multiple detectors agree
if SlidingDetector.IsAnomaly(Value) and 
   EMADetector.IsAnomaly(Value) and 
   AdaptiveDetector.IsAnomaly(Value) then
  TriggerConfirmedAlert(Value);
```

### 2. Tune Parameters
- **Window Size**: Larger windows = more stable, smaller windows = more responsive
- **Alpha**: Lower values = slower adaptation, higher values = faster adaptation
- **Adaptation Rate**: Balance between learning speed and stability

### 3. Handle Edge Cases
- Initialize detectors properly before use
- Handle insufficient data gracefully
- Consider data preprocessing (normalization, filtering)

### 4. Monitor Detector Health
- Log detector parameters over time
- Monitor false positive rates
- Track adaptation behavior

## Common Business Applications

### E-commerce
- Fraud detection in transactions
- Abnormal order pattern identification
- Inventory level anomaly monitoring
- Customer behavior change detection

### Manufacturing
- Quality control in production lines
- Equipment performance monitoring
- Maintenance scheduling based on anomalies
- Supply chain disruption detection

### Finance
- Suspicious transaction detection
- Market volatility monitoring
- Portfolio performance anomaly tracking
- Regulatory compliance monitoring

### IT Operations
- System performance monitoring
- Network traffic anomaly detection
- Security incident identification
- Application error rate monitoring

## Version History

### v1.0.0
- Initial release
- Five anomaly detection algorithms implemented
- Comprehensive demo application
- Full documentation and examples

## License

This library is released as open source software. You are free to use, modify, and distribute it in your projects.

## Contributing

Contributions are welcome! Please feel free to submit pull requests for:
- New detection algorithms
- Performance improvements
- Additional documentation
- Bug fixes
- Feature enhancements

## Support

For issues, questions, or feature requests, please open an issue on the project repository or contact the maintainers.

## Credits

Developed for business applications requiring robust, practical anomaly detection solutions. Inspired by statistical process control and machine learning anomaly detection techniques.
