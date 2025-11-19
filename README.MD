# Anomaly Detection Library for Delphi

A comprehensive Delphi library for detecting anomalies in business data using statistical and machine learning approaches. Designed for real-world applications including fraud detection, system monitoring, data validation, and quality control.

[![Delphi](https://img.shields.io/badge/Delphi-10.3%2B-red.svg)](https://www.embarcadero.com/products/delphi)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-100%25%20Passing-brightgreen.svg)](Tests/)
[![Professional Support](https://img.shields.io/badge/Professional%20Support-Available-blue.svg)](mailto:professionals@bittime.it)

## Features

- **6 Detection Algorithms** - From simple statistical methods to advanced ML techniques
- **Production Ready** - Thread-safe, memory-efficient, thoroughly tested
- **Real-time & Batch** - Supports both streaming data and historical analysis
- **Easy Integration** - Single unit, no external dependencies
- **Performance Monitoring** - Built-in metrics and benchmarking
- **Hyperparameter Tuning** - Grid/Random search with cross-validation
- **Factory Patterns** - Pre-configured detectors for common use cases

## Algorithms Overview

| Algorithm | Best For | Memory | Speed | Use Case |
|-----------|----------|--------|-------|----------|
| **Three Sigma** | Historical data analysis | O(n) | Fast | Quality control, baseline analysis |
| **Sliding Window** | Real-time monitoring | O(window) | Medium | System metrics, live dashboards |
| **EMA** | Fast adaptation | O(1) | Very Fast | Financial data, trending patterns |
| **Adaptive** | Learning systems | O(window) | Fast | Evolving patterns, long-term monitoring |
| **Isolation Forest** | Multi-dimensional data | O(trees×samples) | Medium | Fraud detection, cybersecurity |
| **DBSCAN** | Cluster-based anomalies | O(n²) | Slow | Spatial data, outlier clusters |
| **LOF** | Local density anomalies | O(n²) | Slow | Varying density patterns |

## Quick Start

### Installation

Add the source files to your Delphi project:

```delphi
uses
  AnomalyDetection.Types,
  AnomalyDetection.ThreeSigma,
  AnomalyDetection.SlidingWindow,
  AnomalyDetection.EMA,
  AnomalyDetection.Adaptive,
  AnomalyDetection.IsolationForest,
  AnomalyDetection.Factory;
```

### Basic Example

```delphi
var
  Detector: IAnomalyDetector;
  Result: TAnomalyResult;
begin
  // Create detector using factory
  Detector := Factory.CreateDetector(adtThreeSigma, 'QualityControl');

  // Add historical data
  Detector.AddValues([100, 105, 98, 102, 107, 99, 103, 101, 104, 106]);
  Detector.Build;

  // Detect anomaly
  Result := Detector.Detect(150);
  if Result.IsAnomaly then
    WriteLn(Format('Anomaly: %.2f (Z-score: %.2f)', [Result.Value, Result.ZScore]));
end;
```

## Detector Examples

### 1. Three Sigma Detector - Statistical Process Control

**When to use**: You have complete historical data and need to establish baseline thresholds.

```delphi
uses AnomalyDetection.ThreeSigma;

var
  Detector: TThreeSigmaDetector;
  Result: TAnomalyResult;
begin
  Detector := TThreeSigmaDetector.Create;
  try
    // Add historical data (manufacturing measurements)
    Detector.AddValues([100.2, 99.8, 100.5, 99.9, 100.1, 100.3, 99.7]);

    // Build statistical model (calculates mean and std dev)
    Detector.Build;

    WriteLn('Mean: ', Detector.Mean:0:2);
    WriteLn('StdDev: ', Detector.StdDev:0:2);
    WriteLn('Limits: ', Detector.LowerLimit:0:2, ' - ', Detector.UpperLimit:0:2);

    // Test new measurement
    Result := Detector.Detect(105.5);
    if Result.IsAnomaly then
      WriteLn('Quality issue detected!');
  finally
    Detector.Free;
  end;
end;
```

**Key Methods**:
- `AddValue(Value)` - Add single data point
- `AddValues(Array)` - Add multiple data points
- `Build` - Calculate statistics (required before detection)
- `Detect(Value)` - Check if value is anomalous

### 2. Sliding Window Detector - Real-time Monitoring

**When to use**: Continuous data streams where patterns change over time.

```delphi
uses AnomalyDetection.SlidingWindow;

var
  Detector: TSlidingWindowDetector;
  Result: TAnomalyResult;
  Value: Double;
begin
  // Create with 100-value window
  Detector := TSlidingWindowDetector.Create(100);
  try
    // Initialize with baseline data
    Detector.InitializeWindow([95, 98, 102, 97, 101, 99, 103]);

    // Process streaming data
    while HasIncomingData do
    begin
      Value := GetNextSensorReading;

      // Detect anomaly
      Result := Detector.Detect(Value);
      if Result.IsAnomaly then
        TriggerAlert(Format('Sensor spike: %.2f', [Value]));

      // Update window (adds new, removes oldest)
      Detector.AddValue(Value);
    end;
  finally
    Detector.Free;
  end;
end;
```

**Key Methods**:
- `Create(WindowSize)` - Set size of sliding window
- `InitializeWindow(Array)` - Fast initial setup
- `AddValue(Value)` - Update window with new data
- `CurrentMean`, `CurrentStdDev` - Get current statistics

### 3. EMA Detector - Fast Adaptation

**When to use**: Rapidly changing data where recent values matter most (stock prices, web traffic).

```delphi
uses AnomalyDetection.EMA;

var
  Detector: TEMAAnomalyDetector;
  Result: TAnomalyResult;
begin
  // Create with alpha=0.1 (higher = more responsive)
  Detector := TEMAAnomalyDetector.Create(0.1);
  try
    // Warm up with baseline
    Detector.WarmUp([50.2, 50.5, 49.8, 50.1, 50.3]);

    // Monitor stock price
    for var Price in StockPrices do
    begin
      Result := Detector.Detect(Price);
      if Result.IsAnomaly then
      begin
        if Price > Detector.CurrentMean then
          WriteLn('Spike detected: ', Price:0:2)
        else
          WriteLn('Drop detected: ', Price:0:2);
      end;

      Detector.AddValue(Price);
    end;
  finally
    Detector.Free;
  end;
end;
```

**Key Methods**:
- `Create(Alpha)` - Set adaptation rate (0.01-0.3 typical)
- `WarmUp(Array)` - Initialize with known normal data
- `AddValue(Value)` - Update EMA
- `Alpha` - Control responsiveness (higher = faster adaptation)

### 4. Adaptive Detector - Learning Systems

**When to use**: Systems where "normal" behavior evolves (seasonal patterns, user behavior).

```delphi
uses AnomalyDetection.Adaptive;

var
  Detector: TAdaptiveAnomalyDetector;
  Result: TAnomalyResult;
  Hours: Double;
begin
  // Create with 30-day window, 5% adaptation rate
  Detector := TAdaptiveAnomalyDetector.Create(30, 0.05);
  try
    // Initialize with typical server CPU usage
    Detector.InitializeWithNormalData([45, 52, 48, 55, 50, 47, 53]);

    // Monitor and learn
    for var Day := 1 to 365 do
    begin
      Hours := GetServerCPU;
      Result := Detector.Detect(Hours);

      if Result.IsAnomaly then
      begin
        if UserConfirms('High CPU: ' + Hours.ToString + '% - Normal?') then
          Detector.UpdateNormal(Hours) // Teach detector
        else
          InvestigateCPUSpike(Hours);
      end
      else
        Detector.UpdateNormal(Hours); // Learn from normal data
    end;
  finally
    Detector.Free;
  end;
end;
```

**Key Methods**:
- `Create(WindowSize, AdaptationRate)` - Configure learning
- `InitializeWithNormalData(Array)` - Set baseline
- `UpdateNormal(Value)` - Teach with confirmed normal value
- `Detect(Value)` - Check without learning

### 5. Isolation Forest - Multi-dimensional Fraud Detection

**When to use**: Multiple features per data point (transaction amount + time + location + ...).

```delphi
uses AnomalyDetection.IsolationForest;

var
  Detector: TIsolationForestDetector;
  Transaction: TArray<Double>;
  Result: TAnomalyResult;
begin
  // Create forest: 100 trees, 256 samples, 5 features
  Detector := TIsolationForestDetector.Create(100, 256, 5);
  try
    // Train on normal transactions
    for var i := 1 to 1000 do
    begin
      SetLength(Transaction, 5);
      Transaction[0] := 50 + Random(200);    // Amount
      Transaction[1] := 8 + Random(12);      // Hour of day
      Transaction[2] := 1 + Random(5);       // Day of week
      Transaction[3] := 1 + Random(10);      // Merchant category
      Transaction[4] := 25 + Random(40);     // Customer age

      Detector.AddTrainingData(Transaction);
    end;

    // Build the forest
    Detector.Train;

    // Detect suspicious transaction
    Transaction := [5000, 3, 2, 5, 35]; // Large amount at 3 AM
    Result := Detector.DetectMultiDimensional(Transaction);

    if Result.IsAnomaly then
      FlagForReview('Fraud score: ' + Result.ZScore.ToString);
  finally
    Detector.Free;
  end;
end;
```

**Key Methods**:
- `Create(NumTrees, SampleSize, Features)` - Configure forest
- `AddTrainingData(Array)` - Add multi-dimensional instance
- `Train` - Build isolation forest (required before detection)
- `DetectMultiDimensional(Array)` - Detect in feature space

### 6. Factory Pattern - Pre-configured Detectors

**When to use**: Quick setup for common domains.

```delphi
uses AnomalyDetection.Factory;

var
  WebDetector: IAnomalyDetector;
  FinanceDetector: IAnomalyDetector;
  IoTDetector: IAnomalyDetector;
begin
  // Web security monitoring (optimized for DDoS detection)
  WebDetector := Factory.CreateForWebTrafficMonitoring;

  // Financial data (higher precision, lower false positives)
  FinanceDetector := Factory.CreateForFinancialData;

  // IoT sensors (balanced for reliability)
  IoTDetector := Factory.CreateForIoTSensors;

  // Use like any detector
  if WebDetector.IsAnomaly(RequestsPerSecond) then
    BlockTraffic;
end;
```

**Available Factories**:
- `CreateForWebTrafficMonitoring` - DDoS and security
- `CreateForFinancialData` - Trading and market analysis
- `CreateForIoTSensors` - Equipment monitoring
- `CreateForHighDimensionalData` - ML-based fraud detection

## Real-World Use Cases

### Data Entry Validation

Prevent user errors and detect suspicious input patterns:

```delphi
type
  TInvoiceValidator = class
  private
    FDetectors: TDictionary<string, TSlidingWindowDetector>;
  public
    function ValidateAmount(SupplierCode: string; Amount: Double): Boolean;
  end;

function TInvoiceValidator.ValidateAmount(SupplierCode: string;
  Amount: Double): Boolean;
var
  Detector: TSlidingWindowDetector;
  Result: TAnomalyResult;
begin
  // One detector per supplier
  if not FDetectors.TryGetValue(SupplierCode, Detector) then
  begin
    Detector := TSlidingWindowDetector.Create(50);
    FDetectors.Add(SupplierCode, Detector);
  end;

  Result := Detector.Detect(Amount);
  if Result.IsAnomaly then
    ShowWarning('Unusual amount for ' + SupplierCode);

  Detector.AddValue(Amount); // Learn
  Result := not Result.IsAnomaly;
end;
```

### System Monitoring

Real-time performance anomaly detection:

```delphi
var
  CPUDetector: TEMAAnomalyDetector;
  MemoryDetector: TSlidingWindowDetector;
begin
  CPUDetector := TEMAAnomalyDetector.Create(0.15); // Fast response
  MemoryDetector := TSlidingWindowDetector.Create(60); // 1-hour window

  while ServiceRunning do
  begin
    if CPUDetector.IsAnomaly(GetCPUUsage) then
      LogAlert('CPU spike detected');

    if MemoryDetector.IsAnomaly(GetMemoryUsage) then
      LogAlert('Memory leak suspected');

    Sleep(1000);
  end;
end;
```

### Financial Market Surveillance

Detect abnormal trading patterns:

```delphi
var
  VolumeDetector: TAdaptiveAnomalyDetector;
  PriceDetector: TEMAAnomalyDetector;
begin
  VolumeDetector := TAdaptiveAnomalyDetector.Create(20, 0.1);
  PriceDetector := TEMAAnomalyDetector.Create(0.05);

  for var Tick in MarketData do
  begin
    if VolumeDetector.IsAnomaly(Tick.Volume) and
       PriceDetector.IsAnomaly(Tick.Price) then
      FlagMarketManipulation(Tick);

    VolumeDetector.UpdateNormal(Tick.Volume);
    PriceDetector.AddValue(Tick.Price);
  end;
end;
```

## Performance Evaluation

Measure detector accuracy with labeled data:

```delphi
uses AnomalyDetection.Evaluation;

var
  Dataset: TLabeledDataset;
  Detector: IAnomalyDetector;
  Evaluator: TAnomalyDetectorEvaluator;
  Result: TEvaluationResult;
begin
  // Create labeled dataset
  Dataset := TLabeledDataset.Create('Test Data');
  Dataset.LoadFromCSV('sensor_data.csv', 0, 1, True);

  // Evaluate detector
  Detector := Factory.CreateDetector(adtSlidingWindow, 'Test');
  Evaluator := TAnomalyDetectorEvaluator.Create(Detector, Dataset);
  try
    Result := Evaluator.Evaluate;

    WriteLn('Accuracy:  ', Result.ConfusionMatrix.GetAccuracy:0:3);
    WriteLn('Precision: ', Result.ConfusionMatrix.GetPrecision:0:3);
    WriteLn('Recall:    ', Result.ConfusionMatrix.GetRecall:0:3);
    WriteLn('F1-Score:  ', Result.ConfusionMatrix.GetF1Score:0:3);
  finally
    Evaluator.Free;
  end;
end;
```

## Hyperparameter Tuning

Find optimal configuration automatically:

```delphi
uses AnomalyDetection.Evaluation;

var
  Tuner: THyperparameterTuner;
  BestConfig: TTuningResult;
begin
  Tuner := THyperparameterTuner.Create(adtThreeSigma, Dataset);
  try
    Tuner.OptimizationMetric := 'F1'; // Maximize F1-Score

    // Grid search: test all combinations
    BestConfig := Tuner.GridSearch(
      [2.0, 2.5, 3.0, 3.5], // Sigma values
      nil,                   // Min StdDev (use defaults)
      nil,                   // Window sizes (not applicable)
      nil                    // Alpha values (not applicable)
    );

    WriteLn('Best sigma: ', BestConfig.Config.SigmaMultiplier:0:2);
    WriteLn('F1-Score: ', BestConfig.Score:0:3);
  finally
    Tuner.Free;
  end;
end;
```

## Architecture

```
src/
├── Core/
│   ├── AnomalyDetection.Types.pas          # Common types and interfaces
│   ├── AnomalyDetection.Base.pas           # Base detector class
│   ├── AnomalyDetection.Performance.pas    # Performance monitoring
│   ├── AnomalyDetection.Confirmation.pas   # False positive reduction
│   ├── AnomalyDetection.Utils.pas          # Statistical utilities
│   └── AnomalyDetection.Evaluation.pas     # Testing & tuning framework
│
├── Detectors/
│   ├── AnomalyDetection.ThreeSigma.pas     # Statistical detector
│   ├── AnomalyDetection.SlidingWindow.pas  # Streaming detector
│   ├── AnomalyDetection.EMA.pas            # Fast adaptation
│   ├── AnomalyDetection.Adaptive.pas       # Learning detector
│   ├── AnomalyDetection.IsolationForest.pas# ML detector
│   ├── AnomalyDetection.DBSCAN.pas         # Cluster-based
│   └── AnomalyDetection.LOF.pas            # Density-based
│
└── AnomalyDetection.Factory.pas            # Factory pattern
```

## Building & Testing

### Prerequisites

- Delphi 10.3 Rio or later
- No external dependencies

### Build

```bash
# Build all projects
msbuild AnomalyDetectionsGroup.groupproj

# Run tests
Tests\AnomalyDetectionTestRunner.exe
```

### Run Demos

```bash
# Comprehensive interactive demo
Samples\AnomalyDetectionDemo.exe

# Specific algorithm examples
Samples\ThreeSigmaDetectorSample\ThreeSigmaExample.exe
Samples\SlidingWindowSample\SlidingWindowExample.exe
Samples\EMASample\EMASample.exe
Samples\AdaptiveDetectorSample\AdaptiveSample.exe

# Evaluation & tuning demos
Samples\01_EvaluationDemo.exe
Samples\02_HyperparameterTuningDemo.exe
```

## Performance

Typical throughput on modern hardware (single-threaded):

| Algorithm | Detections/sec | Memory | Training Time |
|-----------|----------------|--------|---------------|
| EMA | ~100,000 | 1 KB | Instant |
| Three Sigma | ~80,000 | ~8n bytes | One-time |
| Sliding Window | ~50,000 | ~8×window bytes | Instant |
| Adaptive | ~70,000 | ~8×window bytes | Instant |
| Isolation Forest | ~20,000 | ~MB scale | Seconds-Minutes |

## Professional Support & Training

While this library is **open source and free to use**, [Bit Time Professionals](https://www.bittimeprofessionals.com) offers commercial support for teams integrating anomaly detection in production environments.

### 🎓 Training & Workshops
- **On-site or remote training** on anomaly detection algorithms and best practices
- **Custom workshops** tailored to your domain (finance, IoT, manufacturing, healthcare)
- **Code review sessions** for optimal integration and performance

### 🏗️ Consulting & Architecture
- **System design** for large-scale anomaly detection pipelines
- **Algorithm selection** and hyperparameter optimization for your specific use case
- **Performance tuning** for high-throughput environments

### 🔧 Custom Development
- **Domain-specific detectors** for specialized industries
- **Integration services** with existing Delphi/enterprise systems
- **Production deployment support** and monitoring strategies

### 📞 Contact

For inquiries about training, consulting, or custom development:

- **Email**: [professionals@bittime.it](mailto:professionals@bittime.it)
- **Web**: [www.bittimeprofessionals.com](https://www.bittimeprofessionals.com)
- **Author**: Daniele Teti ([d.teti@bittime.it](mailto:d.teti@bittime.it))
- **Languages**: Support available in Italian, English, and Spanish

*Bit Time Professionals has 20+ years of experience delivering mission-critical Delphi solutions and is the creator of [DelphiMVCFramework](https://github.com/danieleteti/delphimvcframework).*

## Algorithm Selection Guide

```
┌─────────────────────────────────────────────────┐
│          Do you have labeled data?              │
└────────────┬───────────────────┬────────────────┘
             │ YES               │ NO
             ▼                   ▼
    ┌────────────────┐  ┌─────────────────────┐
    │  Use Tuning    │  │  Multiple features? │
    │   Framework    │  └──────┬──────────────┘
    └────────────────┘         │ YES    │ NO
                               ▼        ▼
                      ┌──────────────┐  ┌──────────────┐
                      │  Isolation   │  │  Streaming?  │
                      │    Forest    │  └──────┬───────┘
                      └──────────────┘    YES  │ NO
                                          ▼    ▼
                                   ┌─────────────────┐
                                   │ EMA / Sliding   │
                                   │  Three Sigma    │
                                   └─────────────────┘
```

## Contributing

Contributions welcome! Areas of interest:
- New detection algorithms
- Performance optimizations
- Documentation improvements
- Platform-specific enhancements

## License

Apache 2.0

## About

This library is developed and maintained by **Daniele Teti** at [bit Time Professionals](https://www.bittimeprofessionals.com), a software consulting company specializing in Delphi enterprise solutions, real-time systems, and machine learning integration.

### Get Professional Help

- **Questions?** Open an [issue](https://github.com/danieleteti/delphi-anomalies-detectors/issues)
- **Commercial support?** Contact [professionals@bittime.it](mailto:professionals@bittime.it)
- **Training & consulting?** Visit [www.bittimeprofessionals.com](https://www.bittimeprofessionals.com)

---

*Built with expertise from DelphiMVCFramework development for real-world business applications.*
