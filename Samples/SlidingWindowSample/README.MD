# Sliding Window Detector Example

## Overview

This example demonstrates the **Sliding Window Anomaly Detector** for **real-time web traffic monitoring**. Unlike the 3-Sigma detector which uses fixed historical data, the sliding window maintains a **moving window** of recent observations, making it perfect for **streaming data** with changing patterns.

## How Sliding Window Works

The detector maintains a **fixed-size window** of the most recent N values:

```
Window (size=5): [100, 105, 98, 102, 107]
New value arrives: 95
Updated window: [105, 98, 102, 107, 95]  // oldest value (100) removed
```

### Key Mechanism:
1. **Add new value** to the window
2. **Remove oldest value** if window is full
3. **Recalculate statistics** (mean, std dev) on current window
4. **Detect anomalies** using updated baseline
5. **Repeat** for next value

This creates an **adaptive baseline** that follows trends and seasonal patterns.

## Example Scenario: Web Traffic Monitoring

This implementation monitors HTTP requests per minute where:

- **Window Size**: 240 minutes (4 hours) for faster adaptation
- **Traffic Patterns**: Daily cycles (low at night, peaks during business hours)
- **Events Detected**: DDoS attacks, viral content, service outages, bot traffic

### Sample Output:
```
[09:15] 🎯 Viral Content Spike
[09:15] 🚨 ANOMALY: 5,530 req/min (Z-score: 12.73)
   → Possible: DDoS attack, viral content, or bot traffic

[14:45] 🎯 Service Outage
[14:45] 🚨 ANOMALY: 147 req/min (Z-score: -6.11)
   → Possible: Service outage or network issues

=== MONITORING SUMMARY ===
• Total anomalies detected: 23
• Scheduled events detected: 5/5
• Event detection rate: 100.0%
```

## When to Use Sliding Window Detection

### ✅ **Ideal Scenarios:**
- **Streaming Data**: Real-time monitoring systems, IoT sensor feeds
- **Trending Data**: Website traffic, sales metrics, user activity
- **Cyclical Patterns**: Daily/weekly patterns, seasonal variations
- **Dynamic Environments**: Cloud auto-scaling, network monitoring
- **Financial Markets**: Stock prices, trading volumes, exchange rates
- **System Metrics**: CPU usage, memory consumption, response times

### ✅ **Key Advantages:**
- **Adaptive**: Automatically follows trends and pattern changes
- **Real-time**: Immediate detection without retraining
- **Memory Efficient**: Fixed window size regardless of data history
- **Pattern Aware**: Handles cyclical and seasonal variations
- **No Historical Data**: Works immediately without training period

### ❌ **Not Suitable For:**
- **Stable Processes**: Manufacturing quality control, calibrated instruments
- **Regulatory Compliance**: When you need fixed statistical baselines
- **Long-term Analysis**: Multi-year trend analysis, strategic planning
- **Highly Variable Windows**: When window size affects detection quality

## Sliding Window vs 3-Sigma Comparison

| Aspect | Sliding Window | 3-Sigma |
|--------|----------------|---------|
| **Data Type** | Streaming, trending | Historical, stable |
| **Adaptation** | Continuous | Fixed baseline |
| **Training** | None required | Requires historical data |
| **Memory** | Fixed window size | Stores all historical data |
| **Pattern Changes** | Adapts automatically | Requires retraining |
| **Use Case** | Real-time monitoring | Quality control |

## Technical Implementation

### Key Features Demonstrated:
1. **Window Initialization**: `InitializeWindow()` for faster startup
2. **Incremental Updates**: `AddValue()` for efficient stream processing
3. **Adaptive Statistics**: Mean/StdDev recalculated for current window
4. **Pattern Recognition**: Distinguishes different anomaly types

### Code Architecture:
```pascal
// 1. Create detector with window size (4-hour window for web traffic)
Detector := TSlidingWindowDetector.Create(240); // 240 minutes = 4 hours

// 2. Optional: Initialize with baseline data
Detector.InitializeWindow(BaselineData);

// 3. Stream processing loop
while HasNewData do
begin
  Detector.AddValue(NewValue);           // Add to window
  Result := Detector.Detect(NewValue);   // Detect anomalies
  if Result.IsAnomaly then
    HandleAnomaly(Result);
end;
```

## Window Size Selection Guidelines

### Small Windows (10-100 values):
- **Pros**: Fast adaptation, sensitive to recent changes
- **Cons**: More false positives, sensitive to noise
- **Use**: High-frequency trading, real-time alerts

### Medium Windows (100-1000 values):
- **Pros**: Balanced sensitivity and stability
- **Cons**: Moderate adaptation speed
- **Use**: System monitoring, web analytics, **web traffic monitoring (4-hour windows)**

### Large Windows (1000+ values):
- **Pros**: Stable baselines, fewer false positives
- **Cons**: Slower adaptation to genuine changes
- **Use**: Infrastructure monitoring, long-term trends

### Web Traffic Example (4-Hour Window):
Our example uses **240 minutes (4 hours)** because:
- **Fast enough** to adapt to daily traffic patterns (morning surge, lunch peak, evening rush)
- **Stable enough** to avoid false positives during normal transitions
- **Practical balance** between sensitivity and stability for web monitoring
- **Captures business cycles** without being too reactive to short-term fluctuations

## Real-World Applications

### Web Services:
- HTTP request rate monitoring
- API response time anomalies
- User session anomaly detection

### Infrastructure:
- Server CPU/memory usage
- Network bandwidth monitoring
- Database performance metrics

### IoT & Sensors:
- Environmental sensor readings
- Industrial equipment monitoring
- Smart city data streams

### Business Metrics:
- Sales transaction monitoring
- User engagement tracking
- Revenue stream analysis

## Mathematical Foundation

The sliding window maintains **dynamic statistics**:

```
Current Mean = Σ(values in window) / window_size
Current StdDev = √(Σ(value - mean)² / (window_size - 1))
Z-Score = (new_value - current_mean) / current_stddev
```

### Incremental Updates:
For efficiency, statistics can be updated incrementally:
- **Add new value**: Update sum and sum of squares
- **Remove old value**: Subtract from sum and sum of squares
- **Recalculate**: Mean and variance from updated sums

This approach achieves **O(1)** complexity per update instead of **O(n)** recalculation.

