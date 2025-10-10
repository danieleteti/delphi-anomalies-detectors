# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a comprehensive Delphi library for detecting anomalies in business data using statistical and machine learning approaches. The library implements 6 different anomaly detection algorithms suitable for various use cases, from historical data analysis to real-time streaming data monitoring.

**Core Library**: `AnomalyDetectionAlgorithms.pas` - Single unit containing all detector implementations
**Author**: Daniele Teti (d.teti@bittime.it)
**License**: Commercial software - proprietary and confidential

## Build Commands

### Building All Projects
```bash
# Build entire project group (demo + tests)
msbuild AnomalyDetectionsGroup.groupproj

# Clean all projects
msbuild AnomalyDetectionsGroup.groupproj /t:Clean

# Make all projects
msbuild AnomalyDetectionsGroup.groupproj /t:Make
```

### Building Individual Projects
```bash
# Build demo application
msbuild Samples/AnomalyDetectionDemo.dproj

# Build test runner
msbuild Tests/AnomalyDetectionTestRunner.dproj

# Build specific sample
msbuild Samples/ThreeSigmaDetectorSample/ThreeSigmaExample.dproj
msbuild Samples/SlidingWindowSample/SlidingWindowExample.dproj
msbuild Samples/EMASample/EMASample.dproj
msbuild Samples/AdaptiveDetectorSample/AdaptiveSample.dproj
```

### Running Tests
```bash
# Run all unit tests (uses DUnitX framework)
Tests/AnomalyDetectionTestRunner.exe

# The test runner generates XML output in dunitx-results.xml for CI/CD integration
```

### Running Demo
```bash
# Run comprehensive interactive demo
Samples/AnomalyDetectionDemo.exe
```

## Architecture

### Core Hierarchy

```
TBaseAnomalyDetector (abstract base class)
├── Detect(AValue: Double): TAnomalyResult - Main detection method
├── IsAnomaly(AValue: Double): Boolean - Simple check
├── SaveState/LoadState - Persistence support
├── PerformanceMonitor - Built-in metrics
└── Thread-safe via TCriticalSection

Detector Implementations:
├── TThreeSigmaDetector - Historical data, batch processing
├── TSlidingWindowDetector - Streaming data, fixed memory
├── TEMAAnomalyDetector - Fast adaptation, trending data
├── TAdaptiveAnomalyDetector - Learning systems, gradual changes
└── TIsolationForestDetector - High-dimensional, ML-based
```

### Key Design Patterns

1. **Factory Pattern**: `TAnomalyDetectorFactory` creates pre-configured detectors
   - `CreateForWebTrafficMonitoring()` - DDoS detection
   - `CreateForFinancialData()` - Market analysis
   - `CreateForIoTSensors()` - Equipment monitoring
   - `CreateForHighDimensionalData()` - Fraud detection

2. **State Persistence**: All detectors support `SaveState(TStream)` / `LoadState(TStream)` for production deployment

3. **Performance Monitoring**: Built-in `TDetectorPerformanceMonitor` tracks:
   - Throughput (detections/sec)
   - Processing time (min/max/avg)
   - Accuracy metrics (when ground truth available)
   - Memory usage

4. **Confirmation System**: `TAnomalyConfirmationSystem` reduces false positives by requiring multiple similar anomalies

### Algorithm Selection Guide

- **TThreeSigmaDetector**: Complete historical dataset, stable conditions, one-time analysis
- **TSlidingWindowDetector**: Continuous data streams, memory constraints, balanced sensitivity
- **TEMAAnomalyDetector**: Immediate response needed, minimal memory, trending data
- **TAdaptiveAnomalyDetector**: Evolving patterns, feedback available, long-term monitoring
- **TIsolationForestDetector**: Multi-dimensional data, complex patterns, unsupervised learning
- **TAnomalyConfirmationSystem**: Critical alerts, false positives costly, confirmation required

## Important Implementation Details

### Initialization Patterns

Each detector has different initialization requirements:

```pascal
// Three Sigma - Add data, then Build
for Value in HistoricalData do
  Detector.AddValue(Value);
Detector.Build;  // Calculate statistics
// OR (bulk method)
Detector.AddValues(Data);
Detector.Build;

// Sliding Window - can start immediately but needs warm-up
Detector.AddValue(Value);  // Build window first
// OR
Detector.InitializeWindow(InitialData);  // Bulk initialization

// EMA - auto-initializes on first value
Detector.AddValue(Value);  // First value sets baseline
// OR
Detector.WarmUp(BaselineData);  // Better: warm up with known normal data

// Adaptive - requires normal data for learning
Detector.InitializeWithNormalData(NormalData);
// OR
Detector.UpdateNormal(Value);  // Incremental learning from confirmed normal values

// Isolation Forest - requires training before detection
Detector.AddTrainingData(Instance);  // Add multi-dimensional instances
Detector.Train;  // Build the forest
// OR
Detector.TrainFromDataset(Dataset);  // Bulk training
Detector.TrainFromCSV('data.csv', True);  // From CSV file
```

**Consistent API Pattern:**
All detectors follow a similar pattern:
- **Training Phase**: `AddValue()` / `AddValues()` / `AddTrainingData()`
- **Build Phase**: `Build()` / `Train()` to finalize the model
- **Detection Phase**: `Detect()` for pure detection (doesn't modify state)

### Critical: Detect vs. AddValue

Understanding the difference between `Detect()` and state-updating methods is crucial:

- **Detect()**: Pure detection - does NOT update detector state
- **AddValue()**: Updates internal state AND recalculates statistics
- **UpdateNormal()**: Adaptive learning - updates model with confirmed normal value

Typical streaming pattern:
```pascal
// CORRECT: Update state, then detect
Detector.AddValue(NewValue);
Result := Detector.Detect(NewValue);

// WRONG: Detect without state update
Result := Detector.Detect(NewValue);  // State not updated!
```

### Multi-Dimensional Detection (Isolation Forest)

```pascal
// Training with multi-dimensional instances
var Transaction: TArray<Double>;
SetLength(Transaction, 5);  // 5 features
Transaction[0] := Amount;
Transaction[1] := Hour;
Transaction[2] := DayOfWeek;
Transaction[3] := Category;
Transaction[4] := Age;

Detector.AddTrainingData(Transaction);
// After sufficient data...
Detector.Train;

// Detection
Result := Detector.DetectMultiDimensional(Transaction);
```

### Thread Safety

All detectors use `TCriticalSection` for thread safety. Multiple threads can share a single detector instance:

```pascal
// Production-safe pattern
FLock.Enter;
try
  Result := Detector.Detect(Value);
finally
  FLock.Leave;
end;
```

### Performance Monitoring

```pascal
// Enable monitoring
Detector.PerformanceMonitor.Enabled := True;

// Wrap detection
Detector.PerformanceMonitor.StartMeasurement;
Result := Detector.Detect(Value);
Detector.PerformanceMonitor.StopMeasurement(Result.IsAnomaly);

// Get metrics
WriteLn(Detector.GetPerformanceReport);
Metrics := Detector.PerformanceMonitor.GetCurrentMetrics;
WriteLn('Throughput: ', Metrics.ThroughputPerSecond:0:1, ' ops/sec');
```

## Testing

The library uses **DUnitX** testing framework.

Test file: `Tests/AnomalyDetectionAlgorithmsTests.pas`
Test coverage includes:
- Algorithm correctness and edge cases
- Thread safety verification
- State persistence (save/load)
- Performance characteristics
- Numerical stability (NaN, Infinity handling)

Adding new tests:
```pascal
[Test]
procedure TestNewFeature;
begin
  // Test implementation
  Assert.IsTrue(Condition, 'Message');
end;
```

## File Organization

```
/
├── AnomalyDetectionAlgorithms.pas     # Core library (single unit)
├── AnomalyDetectionsGroup.groupproj   # Main project group
├── README.MD                          # User documentation
├── Samples/                           # Demo applications
│   ├── AnomalyDetectionDemo.dpr       # Comprehensive interactive demo
│   ├── ThreeSigmaDetectorSample/      # Individual algorithm samples
│   ├── SlidingWindowSample/
│   ├── EMASample/
│   └── AdaptiveDetectorSample/
├── Tests/                             # DUnitX test suite
│   ├── AnomalyDetectionTestRunner.dpr
│   └── AnomalyDetectionAlgorithmsTests.pas
└── docs/                              # Documentation
    ├── ClassDiagram.puml              # PlantUML diagram
    └── ClassDiagram_Documentation.md
```

## Code Conventions

1. **Naming**: All detector classes start with `T`, end with `Detector` or `AnomalyDetector`
2. **Properties**: Public read-only properties for statistics (Mean, StdDev, LowerLimit, UpperLimit)
3. **Configuration**: `TAnomalyDetectionConfig` for sensitivity tuning (SigmaMultiplier, MinStdDev)
4. **Results**: `TAnomalyResult` record contains full detection details (IsAnomaly, ZScore, Limits, Description)
5. **Events**: `OnAnomalyDetected` event for real-time notifications
6. **Exceptions**: `EAnomalyDetectionException` for all library errors

## Common Pitfalls to Avoid

1. **Forgetting to Build**: Three Sigma detector requires `Build()` after adding data with `AddValue()` / `AddValues()`
2. **Uninitialized detection**: Check `IsInitialized` before using detector, or handle the exception
3. **Memory growth**: For streaming data, use fixed-window detectors (Sliding Window, EMA) not Three Sigma
4. **Division by zero**: Library handles zero/near-zero standard deviation via `MinStdDev` config
5. **Isolation Forest single-dimensional**: Use `DetectMultiDimensional()` not `Detect()` for proper results
6. **Forgetting to Train**: Isolation Forest must call `Train()` before detection
7. **Dirty training data**: Use `CleanDataWithPercentiles()` before training statistical detectors (ThreeSigma, SlidingWindow, EMA)

## Sample Workflows

### Simple Anomaly Detection
```pascal
Detector := TThreeSigmaDetector.Create;
try
  Detector.AddValues([100, 105, 98, 102, 107, 99, 103, 101, 104, 106]);
  Detector.Build;

  Result := Detector.Detect(150);
  if Result.IsAnomaly then
    WriteLn('Anomaly: ', Result.Description);
finally
  Detector.Free;
end;
```

### Real-time Monitoring
```pascal
Detector := TSlidingWindowDetector.Create(100);
try
  while HasData do
  begin
    NewValue := GetNextValue;
    Detector.AddValue(NewValue);

    Result := Detector.Detect(NewValue);
    if Result.IsAnomaly then
      TriggerAlert(Result);
  end;
finally
  Detector.Free;
end;
```

### Fraud Detection (Multi-dimensional)
```pascal
Detector := TIsolationForestDetector.Create(100, 256, 10);
try
  // Train on normal transactions
  for i := 1 to 1000 do
    Detector.AddTrainingData([Amount, Hour, Day, Category, Age]);

  Detector.Train;

  // Detect suspicious transaction
  Result := Detector.DetectMultiDimensional([5000, 3, 2, 5, 35]);
  if Result.IsAnomaly then
    FlagTransaction;
finally
  Detector.Free;
end;
```

## Requirements

- **Delphi**: 10.3 Rio or later (uses modern language features like inline variables)
- **Platform**: Windows (primary), macOS/Linux/iOS/Android via FMX
- **Dependencies**: None - pure Delphi implementation
- **Test Framework**: DUnitX

## Performance Characteristics

Typical single-threaded throughput on modern hardware:
- EMA: ~100,000 detections/sec
- Sliding Window: ~50,000 detections/sec
- Three Sigma: ~80,000 detections/sec (after initial calculation)
- Adaptive: ~70,000 detections/sec
- Isolation Forest: ~20,000 detections/sec (multi-dimensional)

Memory usage:
- Three Sigma: O(n) where n = historical data size
- Sliding Window: O(window_size) - constant after initialization
- EMA: O(1) - minimal constant memory
- Adaptive: O(window_size)
- Isolation Forest: O(trees × sample_size) during training

## Extending the Library

To add a new detector:

1. Inherit from `TBaseAnomalyDetector`
2. Implement abstract methods: `Detect()`, `SaveState()`, `LoadState()`, `IsInitialized()`
3. Add to `TAnomalyDetectorType` enum
4. Update `TAnomalyDetectorFactory.CreateDetector()`
5. Add tests in `AnomalyDetectionAlgorithmsTests.pas`
6. Update documentation

Follow existing patterns for thread safety (use `FLock`), event notifications (`CheckAndNotifyAnomaly`), and performance monitoring (`FPerformanceMonitor`).
