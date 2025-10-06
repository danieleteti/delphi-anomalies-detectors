# Data Entry Validation Examples

This folder contains **three separate demo applications** that demonstrate how to use the Anomaly Detection library for real-time data entry validation in business applications.

## Demo Applications

Each demo is a standalone executable with its own focused scenario:

1. **InvoiceValidationDemo.exe** - Per-supplier invoice validation using Sliding Window
2. **OrderValidationDemo.exe** - Multi-dimensional fraud detection using Isolation Forest
3. **TimesheetValidationDemo.exe** - Adaptive employee hours validation with learning

## Running the Demos

```bash
# Invoice validation demo
InvoiceValidationDemo.exe

# Order validation demo
OrderValidationDemo.exe

# Timesheet validation demo
TimesheetValidationDemo.exe
```

## What You'll See

### 1. Invoice Validation (Sliding Window Detector)

The system learns normal invoice amounts for each supplier independently:

```
[SUP001] Amount 1150 €: ✓ ACCEPTED (normal range)
[SUP001] Amount 5000 €: ❌ REJECTED - Expected range: 931-1268 €
[SUP002] Amount 5500 €: ✓ ACCEPTED (normal for this supplier)
[SUP002] Amount 1000 €: ❌ REJECTED - Expected range: 4490-6377 €
```

**Key Insight**: Same amount can be normal for one supplier but anomalous for another.

### 2. Order Validation (Isolation Forest)

Detects unusual combinations of multiple fields:

```
[Order 1] Amount: 500€, Qty: 25, Disc: 5% → ✓ VALID
[Order 2] Amount: 5000€, Qty: 2, Disc: 50% → ❌ SUSPICIOUS (high amount + high discount)
[Order 3] Amount: 100€, Qty: 500, Disc: 0% → ⚠ UNUSUAL (low price, huge quantity)
```

**Key Insight**: Isolation Forest detects unusual COMBINATIONS, not just individual anomalies.

### 3. Timesheet Validation (Adaptive Detector)

Validates hours with learning from user feedback:

```
[Employee 101] 8.0 hours: ✓ Normal working hours
[Employee 101] 12.0 hours: ⚠ WARNING (requires approval)
  → User confirms: "Yes, I worked overtime"
  → System learned: 12 hours can be normal
[Employee 101] 18.0 hours: ❌ ERROR (exceeds physical limit)
```

**Key Insight**: Adaptive detector learns from confirmations and evolves patterns.

## Validation Levels

The demo implements three validation levels:

- **✓ Normal (Green)**: Value accepted automatically
- **⚠ Warning (Yellow)**: Requires user confirmation
- **❌ Error (Red)**: Entry blocked, must be corrected

## Practical Applications

This pattern can be applied to:

### E-commerce
- Order fraud detection
- Pricing anomaly alerts
- Inventory discrepancy warnings
- Customer behavior validation

### Finance
- Transaction amount validation
- Expense report anomalies
- Budget deviation alerts
- Payment pattern analysis

### HR/Payroll
- Timesheet validation
- Overtime detection
- Leave pattern anomalies
- Salary change validation

### Manufacturing
- Quality control measurements
- Production quantity validation
- Material usage anomalies
- Maintenance schedule validation

## Implementation Details

### TInvoiceValidator
```pascal
// Uses Sliding Window (50 invoices) per supplier
// Maintains separate detector for each supplier code
// Learns as invoices are processed
```

### TOrderValidator
```pascal
// Uses Isolation Forest (3 dimensions: amount, qty, discount)
// Requires 500 training samples before activation
// Detects multi-dimensional pattern anomalies
```

### TTimesheetValidator
```pascal
// Uses Adaptive Detector per employee
// Adapts based on user confirmations
// Implements 3-level validation (Normal/Warning/Error)
```

## Key Takeaways

1. **Per-Entity Learning**: Different baselines for different entities (suppliers, employees)
2. **Multi-Level Validation**: Normal → Warning → Error escalation
3. **User Feedback Loop**: System learns from confirmations
4. **Multi-Dimensional Analysis**: Detect unusual combinations, not just values
5. **Real-Time Processing**: Immediate feedback during data entry

## Project Structure

```
DataEntrySample/
├── InvoiceValidator.pas          - Reusable invoice validation class
├── OrderValidator.pas            - Reusable order validation class
├── TimesheetValidator.pas        - Reusable timesheet validation class
├── InvoiceValidationDemo.dpr     - Invoice demo program
├── OrderValidationDemo.dpr       - Order demo program
└── TimesheetValidationDemo.dpr   - Timesheet demo program
```

## Compilation

Each demo can be compiled independently:

```bash
# Invoice demo
dcc32 -B -U..\..\src\Core;..\..\src\Detectors;..\..\src;. InvoiceValidationDemo.dpr

# Order demo
dcc32 -B -U..\..\src\Core;..\..\src\Detectors;..\..\src;. OrderValidationDemo.dpr

# Timesheet demo
dcc32 -B -U..\..\src\Core;..\..\src\Detectors;..\..\src;. TimesheetValidationDemo.dpr
```

## Dependencies

**Shared Units (reusable in your projects):**
- `InvoiceValidator.pas` - Uses `AnomalyDetection.SlidingWindow`
- `OrderValidator.pas` - Uses `AnomalyDetection.IsolationForest`
- `TimesheetValidator.pas` - Uses `AnomalyDetection.Adaptive`

**Framework Dependencies:**
- AnomalyDetection.Types
- System.Generics.Collections

## Integration Tips

1. **Start Small**: Begin with one validation (e.g., invoice amounts)
2. **Collect Data**: Run in learning mode for 2-4 weeks
3. **Tune Thresholds**: Adjust based on false positive rate
4. **Add Feedback**: Let users confirm/reject anomalies
5. **Expand Gradually**: Add more fields and validations

## Author

Daniele Teti (d.teti@bittime.it)
Part of Anomaly Detection Algorithms Library
