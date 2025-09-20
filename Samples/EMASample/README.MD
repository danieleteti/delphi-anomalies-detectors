# EMA Anomaly Detector Example

## Overview

This example demonstrates the **Exponential Moving Average (EMA) Anomaly Detector** for **financial market price monitoring**. Unlike sliding windows that treat all recent values equally, EMA gives **exponentially decreasing weight** to older values, making it ideal for **trending data** where recent observations are most important.

## How EMA Works

The **Exponential Moving Average** updates statistics using a **smoothing factor (α - alpha)**:

```
EMA_new = α × new_value + (1-α) × EMA_old
Variance_new = α × (new_value - EMA_new)² + (1-α) × Variance_old
```

### Key Concepts:
- **α (Alpha)**: Controls adaptation speed (0 < α < 1)
- **High α (0.3-0.5)**: Fast adaptation, sensitive to recent changes
- **Medium α (0.1-0.2)**: Balanced approach, standard for most applications
- **Low α (0.01-0.05)**: Slow adaptation, resistant to noise
- **Exponential Decay**: Older values have exponentially less influence

### Weight Distribution:
```
Current value:    100% × α
1 step ago:       100% × (1-α) × α
2 steps ago:      100% × (1-α)² × α
3 steps ago:      100% × (1-α)³ × α
...and so on
```

## Example Scenario: Stock Price Monitoring

This implementation monitors stock prices for unusual movements:

- **Stock**: TECH Corp (simulated)
- **Alpha Parameter**: 0.1 (standard adaptation)
- **Trading Hours**: 9:00 AM - 5:00 PM
- **Events Detected**: Earnings beats, FDA approvals, selloffs, acquisition rumors

### Sample Output:
```
[09:30] 📰 Positive Earnings Beat
[09:30] 🚨 PRICE SPIKE: $162.40 (+8.3%) Z-score: 4.15
   → Possible: Positive news, earnings beat, or acquisition rumors

[13:45] 📰 Large Block Sale
[13:45] 🚨 PRICE DROP: $148.20 (-7.2%) Z-score: -3.84
   → Possible: Negative news, selloff, or market correction

=== TRADING SESSION SUMMARY ===
• Total price anomalies detected: 12
• Market events detected: 5/5
• Event detection rate: 100.0%
• Final price: $156.75
```

## When to Use EMA Detection

### ✅ **Ideal Scenarios:**
- **Financial Markets**: Stock prices, forex rates, cryptocurrency, commodity prices
- **Trending Data**: Any data with underlying trends or momentum
- **Real-time Streams**: IoT sensors, network metrics, user activity
- **Adaptive Systems**: Where recent data is more important than historical
- **Memory Constraints**: When you can't store large historical datasets
- **Fast Response Needed**: High-frequency trading, real-time alerts

### ✅ **Key Advantages:**
- **Trend Following**: Naturally adapts to upward/downward trends
- **Recent Bias**: Emphasizes recent observations over old ones
- **Memory Efficient**: Only stores current mean and variance
- **Fast Adaptation**: Responds quickly to regime changes
- **Configurable**: Alpha parameter allows tuning sensitivity
- **Computational Efficiency**: O(1) update complexity

### ❌ **Not Suitable For:**
- **Stable Processes**: Manufacturing quality control, scientific measurements
- **Regulatory Compliance**: When fixed statistical baselines are required
- **Stationary Data**: Data without trends or where all history is equally important
- **Noisy Environments**: High-frequency noise can cause false positives
- **Long-term Analysis**: When you need influence from distant historical data

## EMA vs Other Detectors Comparison

| Aspect | EMA | Sliding Window | 3-Sigma |
|--------|-----|----------------|---------|
| **Adaptation** | Exponential decay | Recent N values | Fixed historical |
| **Memory Usage** | O(1) - constant | O(N) - window size | O(H) - all history |
| **Trend Handling** | Excellent | Good | Poor |
| **Sensitivity** | Configurable (α) | Window size | Sigma multiplier |
| **Best For** | Financial data | Streaming data | Quality control |
| **Initialization** | First value or warm-up | Requires window fill | Requires full dataset |

## Alpha Parameter Selection Guide

### Financial Markets:
- **Day Trading (α=0.2-0.5)**: Fast response to price movements
- **Swing Trading (α=0.1-0.2)**: Balanced sensitivity and stability
- **Long-term Investing (α=0.01-0.05)**: Filters out market noise

### System Monitoring:
- **High-frequency Metrics (α=0.3)**: CPU, memory, network in real-time
- **Business Metrics (α=0.1)**: Daily sales, user registrations
- **Infrastructure (α=0.05)**: Monthly capacity, quarterly growth

### Rule of Thumb:
```
α = 2 / (N + 1)

Where N is the equivalent "period" you want to approximate:
- α=0.1 ≈ 19-period moving average
- α=0.2 ≈ 9-period moving average
- α=0.33 ≈ 5-period moving average
```

## Technical Implementation

### Key Features Demonstrated:
1. **WarmUp Method**: `WarmUp(BaselineData)` for better initialization
2. **Alpha Comparison**: Different detectors with varying sensitivity
3. **Financial Events**: Realistic market scenarios (earnings, news, selloffs)
4. **Trend Analysis**: Price direction and volatility assessment

### Code Architecture:
```pascal
// 1. Create EMA detector with alpha parameter
Detector := TEMAAnomalyDetector.Create(0.1); // α = 0.1

// 2. Optional: Warm up with baseline data
Detector.WarmUp(HistoricalPrices);

// 3. Real-time processing
while MarketOpen do
begin
  Detector.AddValue(CurrentPrice);        // Update EMA
  Result := Detector.Detect(CurrentPrice); // Check for anomalies
  if Result.IsAnomaly then
    ProcessPriceAlert(Result);
end;
```

## Mathematical Foundation

### EMA Formula Derivation:
The EMA can be expressed recursively:
```
EMA₀ = X₀ (first observation)
EMA₁ = α×X₁ + (1-α)×EMA₀
EMA₂ = α×X₂ + (1-α)×EMA₁
      = α×X₂ + (1-α)×[α×X₁ + (1-α)×EMA₀]
      = α×X₂ + α×(1-α)×X₁ + (1-α)²×EMA₀
```

### Variance Update:
```
Var₀ = 0 (or small initial value)
Var₁ = α×(X₁ - EMA₁)² + (1-α)×Var₀
```

This creates a **bias toward recent observations** while maintaining **statistical validity** for anomaly detection.

## Real-World Applications

### Algorithmic Trading:
- Price breakout detection
- Volatility spike alerts
- Market regime change identification

### Risk Management:
- Portfolio value anomalies
- Currency exposure monitoring
- Credit risk early warning

### Cryptocurrency:
- Flash crash detection
- Pump-and-dump scheme identification
- Trading volume anomalies

### Business Intelligence:
- Revenue trend monitoring
- Customer behavior changes
- KPI anomaly detection

### IoT & Sensors:
- Temperature trending in data centers
- Network latency monitoring
- Energy consumption patterns

## Performance Characteristics

### Computational Complexity:
- **Update**: O(1) - constant time per observation
- **Detection**: O(1) - constant time per check
- **Memory**: O(1) - only current statistics stored

### Response Time:
- **63% adaptation** after 1/α observations
- **95% adaptation** after 3/α observations
- **99% adaptation** after 5/α observations

Example: With α=0.1, the detector adapts 95% to a new level after ~30 observations.

---

**Next Example**: [Adaptive Detector](../Adaptive/) for self-learning systems with confirmed normal data.