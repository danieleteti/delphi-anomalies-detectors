# Usage Examples - New Modular Structure

## Quick Start

```pascal
uses
  AnomalyDetection.Factory;

// Example 1: Create EMA detector
var
  Detector := TAnomalyDetectorFactory.CreateEMA(0.1);
try
  Detector.AddValue(100);
  var Result := Detector.Detect(150);
  if Result.IsAnomaly then
    WriteLn('Anomaly detected!');
finally
  Detector.Free;
end;

// Example 2: Create Three Sigma detector
var
  Detector := TAnomalyDetectorFactory.CreateThreeSigma;
try
  Detector.SetHistoricalData([100, 105, 98, 102, 107, 99, 103, 101, 104, 106]);
  Detector.CalculateStatistics;
  var Result := Detector.Detect(150);
  if Result.IsAnomaly then
    WriteLn('Anomaly: ' + Result.Description);
finally
  Detector.Free;
end;

// Example 3: Pre-configured for specific use case
var
  Detector := TAnomalyDetectorFactory.CreateForWebTrafficMonitoring;
try
  // Use detector
finally
  Detector.Free;
end;
```

## All Factory Methods

### By Name (Typed)
- `CreateThreeSigma()` / `CreateThreeSigma(Config)`
- `CreateSlidingWindow(WindowSize)` / `CreateSlidingWindow(WindowSize, Config)`
- `CreateEMA(Alpha)` / `CreateEMA(Alpha, Config)`
- `CreateAdaptive(WindowSize, AdaptationRate)` / `CreateAdaptive(WindowSize, AdaptationRate, Config)`
- `CreateIsolationForest(NumTrees, SampleSize, MaxDepth)` / `CreateIsolationForest(NumTrees, SampleSize, MaxDepth, Config)`

### Pre-configured
- `CreateForWebTrafficMonitoring()` → Sliding Window (sensitive)
- `CreateForFinancialData()` → EMA (standard financial)
- `CreateForIoTSensors()` → Adaptive (sensor failures)
- `CreateForHighDimensionalData()` → Isolation Forest (multi-dimensional)
- `CreateForHistoricalAnalysis()` → Three Sigma (batch analysis)
- `CreateForRealTimeStreaming(Alpha)` → EMA (real-time)

## Migration from Old Structure

### Old Code:
```pascal
uses
  AnomalyDetectionAlgorithms;

var Detector := TThreeSigmaDetector.Create;
```

### New Code:
```pascal
uses
  AnomalyDetection.Factory;

var Detector := TAnomalyDetectorFactory.CreateThreeSigma;
```
