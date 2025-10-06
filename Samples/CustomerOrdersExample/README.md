# Customer Orders - Anomaly Detection Demo

## Overview

This demo addresses a critical real-world problem: **How to use anomaly detection when your historical data might already contain anomalies** (errors, fraud, bugs from the past).

## The Problem

When you have a database table with customer orders, you cannot blindly assume all historical data is "normal":
- Past data entry errors
- Previous fraud that went undetected
- System bugs that generated invalid values
- Database corruption or migration issues

If you train an anomaly detector on "dirty" data, **it will learn anomalies as normal**, making it ineffective.

## Three Approaches Demonstrated

### 1. NAIVE Approach ❌ (WRONG)

**Method**: Use ALL historical data without cleaning

**Code**:
```pascal
Detector.SetHistoricalData(AllOrderAmounts);  // Includes anomalies!
Detector.CalculateStatistics;
```

**Problem**:
- Mean and standard deviation are skewed by outliers
- Thresholds become too wide
- New anomalies similar to old ones won't be detected
- False negatives are common

**Example Result**:
```
Mean: 3,921€ (inflated by outliers of 50,000€ and 99,999€)
StdDev: 11,842€ (enormous!)
Range: -31,604€ to 39,448€ (includes negative values - nonsensical!)

Test: 45,000€ order → Barely detected (Z-score: 3.47)
```

### 2. ROBUST Approach with Percentiles ✅ (CORRECT)

**Method**: Clean data using percentile filtering before training

**Code**:
```pascal
uses AnomalyDetection.Utils;

var
  CleaningResult: TCleaningResult;
begin
  // Remove top/bottom 5% (outliers)
  CleaningResult := CleanDataWithPercentiles(AllOrderAmounts, 5, 95);

  WriteLn(Format('Removed %d outliers', [CleaningResult.RemovedCount]));

  // Train on clean data only
  Detector.SetHistoricalData(CleaningResult.CleanData);
  Detector.CalculateStatistics;
end;
```

**Benefits**:
- Mean and StdDev reflect true "normal" values
- Tight, accurate thresholds
- High sensitivity to real anomalies
- Removes extreme outliers automatically

**Example Result**:
```
Original: 100 orders → Clean: 90 orders (removed 10 outliers)
Mean: 1,911€ (realistic)
StdDev: 517€ (reasonable)
Range: 357€ to 3,465€ (sensible business range)

Test: 45,000€ order → CORRECTLY detected as severe anomaly (Z-score: 83.19)
```

### 3. Isolation Forest ✅ (MULTI-DIMENSIONAL)

**Method**: Use algorithm that is inherently robust to outliers

**Code**:
```pascal
Detector := TIsolationForestDetector.Create(100, 256, 10);

// Add all data - Isolation Forest is robust to anomalies in training
for Order in AllOrders do
  Detector.AddTrainingData([Order.Amount, Order.Quantity, Order.Discount]);

Detector.Train;

// Detect using multiple dimensions
Result := Detector.DetectMultiDimensional([Amount, Quantity, Discount]);
```

**Benefits**:
- Robust to contaminated training data
- Analyzes MULTIPLE features simultaneously
- Detects complex patterns (e.g., normal amount but suspicious discount)
- No preprocessing needed
- Best for fraud detection

**Example Results**:
```
Test 1: Amount=2,000€, Qty=5, Discount=10% → ✓ NORMAL
Test 2: Amount=50,000€, Qty=1, Discount=5% → ❌ ANOMALY (high amount)
Test 3: Amount=1,500€, Qty=2, Discount=85% → ❌ ANOMALY (suspicious discount)
```

## How to Run

### Compilation

```bash
"C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\dcc32.exe" -B ^
  -U"..\..\src\Core;..\..\src\Detectors;..\..\src" ^
  -I"..\..\src\Core;..\..\src" ^
  -R"..\..\src" ^
  CustomerOrdersDemo.dpr
```

From project root:
```bash
"C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\dcc32.exe" -B ^
  -U"src\Core;src\Detectors;src" ^
  -I"src\Core;src" ^
  -R"src" ^
  Samples\CustomerOrdersExample\CustomerOrdersDemo.dpr
```

### Execution

```bash
Samples\CustomerOrdersExample\CustomerOrdersDemo.exe
```

The demo runs interactively - press ENTER to advance through each approach.

## Key Takeaways

### When to Clean Data

| Detector | Cleaning Required? | Reason |
|----------|-------------------|---------|
| ThreeSigma | ✅ YES | Mean/StdDev sensitive to outliers |
| SlidingWindow | ✅ YES | Statistics skewed by contaminated data |
| EMA | ✅ YES | Initial baseline can be polluted |
| Adaptive | ✅ YES | Learning from bad data perpetuates errors |
| Isolation Forest | ❌ NO | Algorithm is inherently robust |

### Recommended Percentile Ranges

- **Conservative** (5th-95th): Removes extreme outliers only (10% of data)
- **Standard** (10th-90th): Balanced cleaning (20% of data)
- **Aggressive** (25th-75th): Keeps only middle 50% (IQR method)

### Practical Workflow

1. **Explore your data first**:
   ```pascal
   Stats := CalculateStatistics(RawData);
   WriteLn('Min: ', Stats.Min, ' Max: ', Stats.Max);
   WriteLn('Mean: ', Stats.Mean, ' Median: ', Stats.Median);
   ```

2. **Check for obvious outliers**:
   - Are Min/Max realistic?
   - Is Mean >> Median (indicates outliers)?
   - Are there impossible values (negative amounts, zero quantities)?

3. **Clean if needed**:
   ```pascal
   CleaningResult := CleanDataWithPercentiles(RawData, 5, 95);
   if CleaningResult.RemovalPercent > 20 then
     WriteLn('WARNING: Removed more than 20% - investigate data quality');
   ```

4. **Consider manual review**:
   - For critical applications (fraud detection, compliance)
   - When removal rate is high (>15%)
   - First time analyzing a dataset

## Files

- `CustomerOrdersDemo.dpr` - Main demonstration program
- `README.md` - This documentation

## Dependencies

- `AnomalyDetection.Types` - Core types
- `AnomalyDetection.ThreeSigma` - Statistical detector
- `AnomalyDetection.IsolationForest` - ML-based detector
- `AnomalyDetection.Utils` - Data cleaning utilities

## See Also

- [Main Library Documentation](../../README.MD)
- [Data Entry Validation Examples](../DataEntrySample/)
- [Basic Anomaly Detection Demo](../BasicExample/)
- [Algorithm-Specific Samples](../ThreeSigmaDetectorSample/)

## Real-World Applications

This demo's techniques are directly applicable to:

- **E-commerce**: Order amount validation, fraud detection
- **Finance**: Transaction monitoring, unusual trading patterns
- **Manufacturing**: Quality control with historical defect data
- **IT Operations**: Server metrics from unstable periods
- **Healthcare**: Patient data with measurement errors
- **Logistics**: Delivery time analysis with incomplete records

The key insight: **Real-world data is messy. Clean it first, or use robust algorithms.**
