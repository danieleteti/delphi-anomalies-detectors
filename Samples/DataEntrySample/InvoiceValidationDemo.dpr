// ***************************************************************************
//
// Invoice Validation Demo
// Demonstrates per-supplier invoice amount validation using Sliding Window
//
// ***************************************************************************

program InvoiceValidationDemo;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  {$IFDEF MSWINDOWS}
  WinAPI.Windows,
  {$ENDIF}
  InvoiceValidator;

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

procedure SimulateInvoiceEntry;
var
  Validator: TInvoiceValidator;
  Warning: string;
  i: Integer;
  IsValid: Boolean;
begin
  WriteColoredLine('=== INVOICE VALIDATION DEMO ===', COLOR_INFO);
  WriteLn('Per-supplier invoice amount validation using Sliding Window Detector');
  WriteLn;

  Validator := TInvoiceValidator.Create(10); // Need 10 samples before validation
  try
    // Phase 1: Learn from historical invoices
    WriteColoredLine('Phase 1: Learning from historical invoice data...', COLOR_INFO);
    WriteLn;

    WriteLn('Loading historical invoices (training phase):');
    for i := 1 to 20 do
    begin
      Validator.LearnInvoiceAmount('SUP001', 1000 + Random(200));
      Validator.LearnInvoiceAmount('SUP002', 5000 + Random(1000));
      Validator.LearnInvoiceAmount('SUP003', 500 + Random(100));
    end;

    WriteColoredLine(Format('✓ Training completed for %d suppliers (20 invoices each)',
                            [Validator.GetSupplierCount]), COLOR_SUCCESS);
    WriteLn('  - SUP001: Learned range ~1000 €');
    WriteLn('  - SUP002: Learned range ~5000 €');
    WriteLn('  - SUP003: Learned range ~500 €');
    WriteLn;

    // Phase 2: Test validation with normal and anomalous invoices
    WriteColoredLine('Phase 2: Real-time invoice validation...', COLOR_INFO);
    WriteLn;

    // Normal invoice for SUP001
    WriteLn('User enters invoice: SUP001 - 1150 €');
    IsValid := Validator.ValidateInvoiceAmount('SUP001', 1150, Warning);
    if IsValid then
    begin
      WriteColoredLine('  ✓ ACCEPTED - Amount is within normal range', COLOR_SUCCESS);
      Validator.ConfirmInvoiceAmount('SUP001', 1150); // Add to learning set
    end
    else
      WriteColoredLine('  ❌ REJECTED - ' + Warning, COLOR_ERROR);
    WriteLn;

    // Anomalous invoice - too high for SUP001
    WriteLn('User enters invoice: SUP001 - 5000 €');
    IsValid := Validator.ValidateInvoiceAmount('SUP001', 5000, Warning);
    if IsValid then
      WriteColoredLine('  ✓ ACCEPTED', COLOR_SUCCESS)
    else
    begin
      WriteColoredLine('  ❌ ANOMALY DETECTED', COLOR_ERROR);
      WriteLn('  ' + Warning);
      WriteLn('  → Action: Requires manager approval');
    end;
    WriteLn;

    // Same amount is normal for SUP002
    WriteLn('User enters invoice: SUP002 - 5500 €');
    IsValid := Validator.ValidateInvoiceAmount('SUP002', 5500, Warning);
    if IsValid then
    begin
      WriteColoredLine('  ✓ ACCEPTED - Normal for this supplier', COLOR_SUCCESS);
      Validator.ConfirmInvoiceAmount('SUP002', 5500);
    end
    else
      WriteColoredLine('  ❌ REJECTED - ' + Warning, COLOR_ERROR);
    WriteLn;

    // Too low for SUP002
    WriteLn('User enters invoice: SUP002 - 1000 €');
    IsValid := Validator.ValidateInvoiceAmount('SUP002', 1000, Warning);
    if IsValid then
    begin
      WriteColoredLine('  ✓ ACCEPTED', COLOR_SUCCESS);
      Validator.ConfirmInvoiceAmount('SUP002', 1000);
    end
    else
    begin
      WriteColoredLine('  ❌ ANOMALY DETECTED', COLOR_ERROR);
      WriteLn('  ' + Warning);
      WriteLn('  → Action: Verify not a data entry error (missing digit?)');
      WriteLn('  → Invoice NOT added to learning set (requires review)');
    end;
    WriteLn;

    // Normal for SUP003
    WriteLn('User enters invoice: SUP003 - 550 €');
    IsValid := Validator.ValidateInvoiceAmount('SUP003', 550, Warning);
    if IsValid then
    begin
      WriteColoredLine('  ✓ ACCEPTED - Normal for this supplier', COLOR_SUCCESS);
      Validator.ConfirmInvoiceAmount('SUP003', 550);
    end
    else
      WriteColoredLine('  ❌ REJECTED - ' + Warning, COLOR_ERROR);
    WriteLn;

    // Too high for SUP003 (possible typo: 5500 instead of 550)
    WriteLn('User enters invoice: SUP003 - 5500 € (typo: extra zero?)');
    IsValid := Validator.ValidateInvoiceAmount('SUP003', 5500, Warning);
    if IsValid then
    begin
      WriteColoredLine('  ✓ ACCEPTED', COLOR_SUCCESS);
      Validator.ConfirmInvoiceAmount('SUP003', 5500);
    end
    else
    begin
      WriteColoredLine('  ❌ ANOMALY DETECTED - Possible typo!', COLOR_ERROR);
      WriteLn('  ' + Warning);
      WriteLn('  → Action: Alert user - did you mean 550 €?');
      WriteLn('  → Invoice NOT added to learning set (requires correction)');
    end;
    WriteLn;

    // Test with new supplier (not enough data)
    WriteLn('User enters invoice: SUP999 - 750 € (new supplier, first invoice)');
    IsValid := Validator.ValidateInvoiceAmount('SUP999', 750, Warning);
    if IsValid then
    begin
      WriteColoredLine('  ✓ ACCEPTED', COLOR_SUCCESS);
      Validator.ConfirmInvoiceAmount('SUP999', 750);
    end
    else
    begin
      WriteColoredLine('  ⚠ LEARNING MODE', COLOR_WARNING);
      WriteLn('  ' + Warning);
      WriteLn('  → Action: Accepted, but building baseline (need 9 more invoices)');
      Validator.LearnInvoiceAmount('SUP999', 750); // Add to learning
    end;
    WriteLn;

    WriteLn(StringOfChar('=', 70));
    WriteColoredLine('KEY INSIGHTS:', COLOR_INFO);
    WriteLn;
    WriteLn('✓ Each supplier has its own learned pattern');
    WriteLn('✓ 5000 € is NORMAL for SUP002 but ANOMALOUS for SUP001');
    WriteLn('✓ System catches likely data entry errors (typos, missing/extra digits)');
    WriteLn('✓ Adapts continuously as new invoices are processed');
    WriteLn;
    WriteColoredLine('PREVENTED ERRORS:', COLOR_SUCCESS);
    WriteLn('  • Invoices entered for wrong supplier');
    WriteLn('  • Decimal point errors (55.00 → 5500.00)');
    WriteLn('  • Missing or extra digits');
    WriteLn('  • Fraudulent amounts outside normal patterns');

  finally
    Validator.Free;
  end;
end;

begin
  try
    Randomize;

    WriteLn('Invoice Amount Validation - Data Entry Example');
    WriteLn('Demonstrating real-time anomaly detection for invoice processing');
    WriteLn(StringOfChar('=', 70));
    WriteLn;

    SimulateInvoiceEntry;

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
