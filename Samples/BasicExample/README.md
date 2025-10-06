# Basic Anomaly Detection - Interactive Demo

## Overview

This is a beginner-friendly, educational demo that demonstrates the fundamentals of anomaly detection in a simple, interactive way.

## Concept

The demo simulates a website traffic monitoring scenario where:
- **Normal data**: 30 days of historical visitor counts (around 500 visitors/day with natural variation)
- **Learning phase**: The detector learns what "normal" looks like
- **Detection phase**: New values are classified as normal or anomalous

## Features

### Three Interactive Phases

1. **Phase 1: Learning from Historical Data**
   - Shows 30 days of "normal" visitor counts
   - Detector calculates mean, standard deviation, and normal range (±3σ)
   - Educational explanations of the learning process

2. **Phase 2: Testing with Examples**
   - 5 predefined test cases showing progression from normal to severe anomalies
   - Each example explains the Z-score and severity level
   - Demonstrates different anomaly types (high/low, mild/moderate/severe)

3. **Phase 3: Interactive Testing**
   - User can enter custom visitor counts
   - Real-time classification and explanation
   - Educational feedback for each input

### Anomaly Severity Levels

The demo classifies values into 4 levels based on Z-score:

- **✓ NORMAL** - Within ±3σ (standard deviations)
  - Value is within expected range
  - Z-score: -3 to +3

- **⚠ MILD ANOMALY** - Between 3σ and 4σ
  - Value is slightly unusual but not critical
  - Z-score: 3 to 4 (or -3 to -4)

- **⚠ MODERATE ANOMALY** - Between 4σ and 6σ
  - Value is quite unusual and deserves attention
  - Z-score: 4 to 6 (or -4 to -6)

- **❌ SEVERE ANOMALY** - More than 6σ
  - Value is extremely unusual - likely an error or critical event
  - Z-score: > 6 (or < -6)

## How to Run

### Compilation

```bash
"C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\dcc32.exe" -B ^
  -U"..\..\src\Core;..\..\src\Detectors;..\..\src" ^
  -I"..\..\src\Core;..\..\src" ^
  -R"..\..\src" ^
  BasicAnomalyDemo.dpr
```

Or from project root:

```bash
"C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\dcc32.exe" -B ^
  -U"src\Core;src\Detectors;src" ^
  -I"src\Core;src" ^
  -R"src" ^
  Samples\BasicExample\BasicAnomalyDemo.dpr
```

### Execution

Simply run the executable:

```bash
Samples\BasicExample\BasicAnomalyDemo.exe
```

### Interactive Usage

1. Press ENTER to advance through Phase 1 (learning)
2. Press ENTER to see each test example in Phase 2
3. In Phase 3:
   - Enter numbers to test (e.g., `500`, `600`, `1000`)
   - Enter `q` to quit

## Example Output

```
═══════════════════════════════════════════════════════════
  BASIC ANOMALY DETECTION - Interactive Demo
═══════════════════════════════════════════════════════════

This demo shows how anomaly detection works in 3 simple steps:
  1. Learn from historical "normal" data
  2. Calculate statistical thresholds
  3. Detect anomalies in new data

Press ENTER to start...

═══ PHASE 1: LEARNING FROM HISTORICAL DATA ═══

Imagine you are monitoring daily website visitors.
Here are the visitor counts from the last 30 days:

Data: 493, 492, 490, 488, 503, 500, 510, 504, ...

→ Loading this data into the detector...
✓ Learning completed!

Statistical analysis results:
  • Average (Mean): 501.33 visitors per day
  • Standard Deviation: 11.29
  • Normal range (Mean ± 3σ): 467.47 - 535.20 visitors

...
```

## Educational Goals

This demo helps you understand:

1. **Learning Phase**: How detectors establish baselines from historical data
2. **Z-Score**: A measure of how many standard deviations a value is from the mean
3. **Thresholds**: The ±3σ rule (99.7% of normal data falls within this range)
4. **Severity**: How distance from the mean indicates anomaly severity
5. **Practical Application**: Real-world use case (website traffic monitoring)

## Algorithm Used

- **TThreeSigmaDetector**: Statistical anomaly detection using the Three Sigma Rule
- **Method**: Assumes normal distribution of data
- **Threshold**: ±3 standard deviations from mean

## Key Concepts Explained

### What is a Z-Score?

The Z-score tells you how many standard deviations a value is from the mean:
- Z-score of 0 = exactly at the mean
- Z-score of +2 = two standard deviations above the mean
- Z-score of -3 = three standard deviations below the mean

### Why ±3 Standard Deviations?

In a normal distribution:
- 68% of data falls within ±1σ
- 95% of data falls within ±2σ
- 99.7% of data falls within ±3σ

Values beyond ±3σ are statistically rare (0.3% probability), making them good anomaly candidates.

## Files

- `BasicAnomalyDemo.dpr` - Main program source
- `BasicAnomalyDemo.exe` - Compiled executable

## Dependencies

- `AnomalyDetection.Types` - Core types (TAnomalyResult)
- `AnomalyDetection.ThreeSigma` - Three Sigma detector implementation
- WinAPI.Windows - Console color support (Windows only)

## Platform

- **Primary**: Windows console application
- **Colors**: Windows-specific (gracefully degrades on other platforms)

## See Also

- [ThreeSigma Sample](../ThreeSigmaDetectorSample/) - More advanced Three Sigma examples
- [Main README](../../README.MD) - Complete library documentation
- [Data Entry Examples](../DataEntrySample/) - Real-world business use cases
