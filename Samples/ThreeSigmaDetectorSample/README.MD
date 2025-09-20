# Three Sigma Detector Example

## Overview

This example demonstrates the **Three Sigma (3σ) Rule** for anomaly detection applied to **data center temperature monitoring**. It's a practical implementation showing how to detect equipment malfunctions and environmental anomalies using statistical analysis.

## What is the Z-Score?

The **Z-Score** (also called standard score) measures how many standard deviations a data point is from the mean:

```
Z-Score = (Value - Mean) / Standard Deviation
```

### Z-Score Interpretation:
- **Z = 0**: Value is exactly at the mean
- **Z = ±1**: Value is 1 standard deviation from mean (~68% of data falls here)
- **Z = ±2**: Value is 2 standard deviations from mean (~95% of data falls here)
- **Z = ±3**: Value is 3 standard deviations from mean (~99.7% of data falls here)

**The 3-Sigma Rule**: Any value with |Z-Score| > 3 is considered an anomaly, as it occurs in less than 0.3% of normal cases.

## Example Scenario: Data Center Temperature Monitoring

This implementation monitors server room temperatures where:

- **Normal Range**: 18-22°C with daily variations
- **Historical Data**: 30 days of temperature readings (720 data points)
- **Detection Goal**: Identify overheating or cooling system failures

### Sample Output:
```
[Reading 1] 20.5°C: ✓ Normal (Z-score: 0.45)
[Reading 5] 28.5°C: 🚨 ANOMALY DETECTED! (Z-score: 4.12)
   → Action: Check cooling system, possible overheating
```

## When to Use Three Sigma Detection

### ✅ **Ideal Scenarios:**
- **Quality Control**: Manufacturing tolerances, product specifications
- **Infrastructure Monitoring**: Server temperatures, network latency, power consumption
- **Financial Analytics**: Budget variance analysis, cost monitoring
- **Scientific Measurements**: Laboratory equipment, sensor calibration
- **Stable Processes**: Any system with consistent operating conditions

### ✅ **Key Advantages:**
- **Statistically Sound**: Based on normal distribution properties
- **Low False Positives**: Only 0.3% chance of false alarms
- **Simple Implementation**: Easy to understand and explain
- **Historical Baseline**: Uses proven historical data for reference
- **Regulatory Compliance**: Widely accepted in quality standards (ISO, Six Sigma)

### ❌ **Not Suitable For:**
- **Trending Data**: Stock prices, growing user bases, seasonal data
- **Streaming Data**: Real-time social media feeds, IoT sensor streams
- **Adaptive Systems**: Machine learning models, dynamic environments
- **Non-Normal Distributions**: Highly skewed or multi-modal data

## Technical Requirements

### Dependencies:
- **AnomalyDetectionAlgorithms.pas**: Main detection library
- **Delphi/Free Pascal**: Compatible with modern Object Pascal compilers

### Key Features Demonstrated:
1. **Historical Learning**: `LearnFromHistoricalData()` method
2. **Statistical Analysis**: Mean, standard deviation, confidence intervals
3. **Real-time Detection**: `Detect()` method with detailed results
4. **Practical Interpretation**: Actionable insights for operators

## Usage Instructions

1. **Compile**: Build the `ThreeSigmaExample.dpr` project
2. **Run**: Execute to see temperature monitoring simulation
3. **Observe**: Watch how the detector identifies temperature anomalies
4. **Experiment**: Modify test values to see different detection scenarios

## Code Architecture

```pascal
// 1. Create detector
Detector := TThreeSigmaDetector.Create;

// 2. Learn from historical data (single call)
Detector.LearnFromHistoricalData(HistoricalTemperatures);

// 3. Detect anomalies in real-time
Result := Detector.Detect(CurrentTemperature);

// 4. Interpret results
if Result.IsAnomaly then
  HandleAnomalyAlert(Result);
```

## Real-World Applications

### Data Centers:
- Server temperature monitoring
- Power consumption analysis
- Network latency detection

### Manufacturing:
- Product dimension quality control
- Machine vibration monitoring
- Chemical process parameters

### Finance:
- Expense anomaly detection
- Budget variance analysis
- Trading volume monitoring

### Healthcare:
- Patient vital signs monitoring
- Medical equipment calibration
- Laboratory test result validation

## Mathematical Foundation

The Three Sigma Rule is based on the **Empirical Rule** for normal distributions:

- **68%** of data falls within ±1σ
- **95%** of data falls within ±2σ
- **99.7%** of data falls within ±3σ

This makes it extremely reliable for detecting true outliers while minimizing false positives in stable systems.

