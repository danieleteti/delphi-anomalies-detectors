// ***************************************************************************
//
// Order Validation Demo
// Demonstrates multi-dimensional fraud detection using Isolation Forest
//
// ***************************************************************************

program OrderValidationDemo;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  {$IFDEF MSWINDOWS}
  WinAPI.Windows,
  {$ENDIF}
  OrderValidator;

const
  {$IFDEF MSWINDOWS}
  COLOR_NORMAL = 7;
  COLOR_ERROR = 12;    // Red
  COLOR_WARNING = 14;  // Yellow
  COLOR_SUCCESS = 10;  // Green
  COLOR_INFO = 11;     // Cyan
  {$ENDIF}

procedure SetConsoleColor(AColor: Word);
begin
  {$IFDEF MSWINDOWS}
  var lHandle := GetStdHandle(STD_OUTPUT_HANDLE);
  SetConsoleTextAttribute(lHandle, AColor);
  {$ENDIF}
end;

procedure WriteColoredLine(const AText: string; AColor: Word);
begin
  SetConsoleColor(AColor);
  WriteLn(AText);
  SetConsoleColor(COLOR_NORMAL);
end;

procedure SimulateOrderEntry;
var
  Validator: TOrderValidator;
  Suspicion: string;
  i: Integer;
  Amount, Qty, Disc: Double;
  IsValid: Boolean;
begin
  WriteColoredLine('=== ORDER VALIDATION DEMO ===', COLOR_INFO);
  WriteLn('Multi-dimensional fraud detection using Isolation Forest');
  WriteLn('Analyzes combinations of Amount, Quantity, and Discount%');
  WriteLn;

  Validator := TOrderValidator.Create(500); // Requires 500 training samples
  try
    // Phase 1: Training with normal orders
    WriteColoredLine('Phase 1: Training with normal orders...', COLOR_INFO);
    WriteLn('Collecting patterns of legitimate orders...');
    WriteLn;

    // Generate normal orders for training
    for i := 1 to 500 do
    begin
      Amount := 100 + Random(900);      // 100-1000 €
      Qty := 1 + Random(50);            // 1-50 units
      Disc := Random * 10;              // 0-10% discount

      Validator.AddTrainingOrder(Amount, Qty, Disc);

      if (i mod 100) = 0 then
        WriteLn(Format('  %d/%d samples collected...', [i, Validator.TrainingThreshold]));
    end;

    WriteColoredLine('✓ Training completed - Fraud detection active', COLOR_SUCCESS);
    WriteLn;

    // Phase 2: Test order patterns
    WriteColoredLine('Phase 2: Testing order data entry...', COLOR_INFO);
    WriteLn;

    // Test 1: Normal order
    WriteLn('User enters order:');
    WriteLn('  Amount: 500 €, Quantity: 25, Discount: 5%');
    IsValid := Validator.ValidateOrder(500, 25, 5, Suspicion);
    if IsValid then
      WriteColoredLine('  ✓ VALID - ' + Suspicion, COLOR_SUCCESS)
    else
      WriteColoredLine('  ⚠ ' + Suspicion, COLOR_WARNING);
    WriteLn;

    // Test 2: High amount + High discount (possible fraud)
    WriteLn('User enters order:');
    WriteLn('  Amount: 5000 €, Quantity: 2, Discount: 50%');
    IsValid := Validator.ValidateOrder(5000, 2, 50, Suspicion);
    if IsValid then
      WriteColoredLine('  ✓ VALID', COLOR_SUCCESS)
    else
    begin
      WriteColoredLine('  ❌ FRAUD ALERT - ' + Suspicion, COLOR_ERROR);
      WriteLn('  → Red flags:');
      WriteLn('    • Unusually high order amount');
      WriteLn('    • Excessive discount (50%)');
      WriteLn('    • Low quantity for high amount');
      WriteLn('  → Action: Require manager approval + audit log');
    end;
    WriteLn;

    // Test 3: Very high quantity with low amount (possible error/fraud)
    WriteLn('User enters order:');
    WriteLn('  Amount: 100 €, Quantity: 500, Discount: 0%');
    IsValid := Validator.ValidateOrder(100, 500, 0, Suspicion);
    if IsValid then
      WriteColoredLine('  ✓ VALID', COLOR_SUCCESS)
    else
    begin
      WriteColoredLine('  ⚠ SUSPICIOUS - ' + Suspicion, COLOR_WARNING);
      WriteLn('  → Red flags:');
      WriteLn('    • Huge quantity (500 units) for tiny amount');
      WriteLn('    • Price per unit = 0.20 € (very low)');
      WriteLn('  → Action: Verify pricing is correct');
    end;
    WriteLn;

    // Test 4: Normal order (different values)
    WriteLn('User enters order:');
    WriteLn('  Amount: 800 €, Quantity: 40, Discount: 8%');
    IsValid := Validator.ValidateOrder(800, 40, 8, Suspicion);
    if IsValid then
      WriteColoredLine('  ✓ VALID - ' + Suspicion, COLOR_SUCCESS)
    else
      WriteColoredLine('  ⚠ ' + Suspicion, COLOR_WARNING);
    WriteLn;

    // Test 5: Medium amount with excessive discount
    WriteLn('User enters order:');
    WriteLn('  Amount: 1500 €, Quantity: 10, Discount: 75%');
    IsValid := Validator.ValidateOrder(1500, 10, 75, Suspicion);
    if IsValid then
      WriteColoredLine('  ✓ VALID', COLOR_SUCCESS)
    else
    begin
      WriteColoredLine('  ❌ FRAUD ALERT - ' + Suspicion, COLOR_ERROR);
      WriteLn('  → Red flag: Discount exceeds policy limit (75% > 10%)');
      WriteLn('  → Action: Block order, escalate to management');
    end;
    WriteLn;

    // Test 6: Unusual combination that might be legitimate special case
    WriteLn('User enters order:');
    WriteLn('  Amount: 200 €, Quantity: 1, Discount: 15%');
    IsValid := Validator.ValidateOrder(200, 1, 15, Suspicion);
    if IsValid then
      WriteColoredLine('  ✓ VALID - ' + Suspicion, COLOR_SUCCESS)
    else
    begin
      WriteColoredLine('  ⚠ REVIEW NEEDED - ' + Suspicion, COLOR_WARNING);
      WriteLn('  → Unusual but might be legitimate (special promotion?)');
      WriteLn('  → Action: Require comment/reason from user');
    end;
    WriteLn;

    WriteLn(StringOfChar('=', 70));
    WriteColoredLine('KEY INSIGHTS:', COLOR_INFO);
    WriteLn;
    WriteLn('✓ Detects unusual COMBINATIONS, not just individual thresholds');
    WriteLn('✓ Can identify complex fraud patterns:');
    WriteLn('  • Employee giving unauthorized discounts to friends');
    WriteLn('  • Pricing errors that would cause major losses');
    WriteLn('  • Bulk order frauds with fake low prices');
    WriteLn('✓ Learns from legitimate orders, no manual rule configuration');
    WriteLn;
    WriteColoredLine('FRAUD PREVENTION:', COLOR_SUCCESS);
    WriteLn('  • Excessive discount schemes');
    WriteLn('  • Pricing manipulation');
    WriteLn('  • Bulk order fraud');
    WriteLn('  • Revenue leakage from unusual deals');

  finally
    Validator.Free;
  end;
end;

begin
  try
    Randomize;

    WriteLn('Order Pattern Validation - Fraud Detection Example');
    WriteLn('Multi-dimensional analysis of Amount, Quantity, Discount');
    WriteLn(StringOfChar('=', 70));
    WriteLn;

    SimulateOrderEntry;

    WriteLn;
    WriteLn(StringOfChar('=', 70));
    WriteColoredLine('Demo completed successfully!', COLOR_SUCCESS);
    WriteLn;
    WriteLn('Press ENTER to exit...');
    ReadLn;

  except
    on E: Exception do
    begin
      WriteColoredLine('ERROR: ' + E.Message, COLOR_ERROR);
      WriteLn('Press ENTER to exit...');
      ReadLn;
      ExitCode := 1;
    end;
  end;
end.
