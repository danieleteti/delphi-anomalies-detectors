# Delphi Anomaly Detection Library

[![Delphi](https://img.shields.io/badge/Delphi-10.3%2B-red.svg)](https://www.embarcadero.com/products/delphi)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-100%25%20Passing-brightgreen.svg)](Tests/)

A comprehensive library for detecting anomalies in business data using statistical and machine learning approaches. Designed for fraud detection, system monitoring, data validation, and quality control.

**For complete documentation, examples, and API reference, visit: [danieleteti.it/delphianomalydetection](https://www.danieleteti.it/delphianomalydetection)**

## Features

- **6 Detection Algorithms** - Three Sigma, Sliding Window, EMA, Adaptive, Isolation Forest, DBSCAN
- **Production Ready** - Thread-safe, memory-efficient, thoroughly tested
- **Real-time & Batch** - Streaming data and historical analysis
- **Easy Integration** - Single unit, no external dependencies
- **Performance Monitoring** - Built-in metrics and benchmarking
- **Hyperparameter Tuning** - Grid/Random search with cross-validation

## Algorithms

| Algorithm | Best For | Speed |
|-----------|----------|-------|
| **Three Sigma** | Quality control, baseline analysis | Fast |
| **Sliding Window** | Real-time monitoring, dashboards | Medium |
| **EMA** | Financial data, trending patterns | Very Fast |
| **Adaptive** | Evolving patterns, learning systems | Fast |
| **Isolation Forest** | Fraud detection, multi-dimensional | Medium |
| **DBSCAN/LOF** | Cluster-based anomalies | Slow |

## Quick Start

```delphi
uses
  AnomalyDetection.Types,
  AnomalyDetection.ThreeSigma,
  AnomalyDetection.Factory;

var
  Detector: IAnomalyDetector;
  Result: TAnomalyResult;
begin
  // Create detector
  Detector := Factory.CreateDetector(adtThreeSigma, 'QualityControl');

  // Add data and build
  Detector.AddValues([100, 105, 98, 102, 107, 99, 103, 101]);
  Detector.Build;

  // Detect anomaly
  Result := Detector.Detect(150);
  if Result.IsAnomaly then
    WriteLn('Anomaly detected! Z-score: ', Result.ZScore:0:2);
end;
```

## Real-time Monitoring

```delphi
uses AnomalyDetection.SlidingWindow;

var
  Detector: TSlidingWindowDetector;
begin
  Detector := TSlidingWindowDetector.Create(100);  // 100-value window
  try
    while HasIncomingData do
    begin
      Value := GetNextReading;
      if Detector.IsAnomaly(Value) then
        TriggerAlert('Spike detected: ' + Value.ToString);
      Detector.AddValue(Value);
    end;
  finally
    Detector.Free;
  end;
end;
```

## Fraud Detection (Multi-dimensional)

```delphi
uses AnomalyDetection.IsolationForest;

var
  Detector: TIsolationForestDetector;
begin
  Detector := TIsolationForestDetector.Create(100, 256, 5);  // 100 trees, 5 features
  try
    // Train on normal transactions
    for Transaction in NormalTransactions do
      Detector.AddTrainingData([Amount, Hour, Day, Category, Age]);
    Detector.Train;

    // Detect fraud
    Result := Detector.DetectMultiDimensional([5000, 3, 2, 5, 35]);
    if Result.IsAnomaly then
      FlagForReview('Suspicious transaction');
  finally
    Detector.Free;
  end;
end;
```

## Factory Pattern

```delphi
uses AnomalyDetection.Factory;

// Pre-configured detectors for common use cases
WebDetector := Factory.CreateForWebTrafficMonitoring;
FinanceDetector := Factory.CreateForFinancialData;
IoTDetector := Factory.CreateForIoTSensors;
FraudDetector := Factory.CreateForHighDimensionalData;
```

## Documentation

**Full documentation with all algorithms, examples, and tuning guide:**

**[danieleteti.it/delphianomalydetection](https://www.danieleteti.it/delphianomalydetection)**

## Installation

1. Download or clone from GitHub
2. Add the `src` folder to your Library Path
3. Add the appropriate units to your project

## Requirements

- Delphi 10.3 Rio or later
- No external dependencies

## License

Apache 2.0 - Free for commercial and personal use.

## Professional Support

- **Training & Consulting**: [Bit Time Professionals](https://www.bittimeprofessionals.com)
- **Email**: [professionals@bittime.it](mailto:professionals@bittime.it)

## Support

- **Documentation**: [danieleteti.it/delphianomalydetection](https://www.danieleteti.it/delphianomalydetection)
- **Issues**: [GitHub Issues](https://github.com/danieleteti/delphi-anomalies-detectors/issues)
- **Community**: [Facebook Group](https://www.facebook.com/groups/delphimvcframework)
