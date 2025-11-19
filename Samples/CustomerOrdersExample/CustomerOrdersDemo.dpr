program CustomerOrdersDemo;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Math,
  WinAPI.Windows,
  AnomalyDetection.Types,
  AnomalyDetection.ThreeSigma,
  AnomalyDetection.IsolationForest,
  AnomalyDetection.Utils;

const
  COLOR_HEADER = FOREGROUND_GREEN or FOREGROUND_INTENSITY;
  COLOR_INFO = FOREGROUND_BLUE or FOREGROUND_GREEN or FOREGROUND_INTENSITY;
  COLOR_SUCCESS = FOREGROUND_GREEN or FOREGROUND_INTENSITY;
  COLOR_WARNING = FOREGROUND_RED or FOREGROUND_GREEN or FOREGROUND_INTENSITY;
  COLOR_ERROR = FOREGROUND_RED or FOREGROUND_INTENSITY;
  COLOR_NORMAL = FOREGROUND_RED or FOREGROUND_GREEN or FOREGROUND_BLUE;

type
  TCustomerOrder = record
    CustomerID: string;
    OrderDate: TDateTime;
    Amount: Double;
    Quantity: Integer;
    DiscountPercent: Double;
    function IsValid: Boolean;
  end;

procedure SetConsoleColor(Color: Word);
var
  Handle: THandle;
begin
  Handle := GetStdHandle(STD_OUTPUT_HANDLE);
  SetConsoleTextAttribute(Handle, Color);
end;

procedure WriteColoredLine(const Text: string; Color: Word);
begin
  SetConsoleColor(Color);
  WriteLn(Text);
  SetConsoleColor(COLOR_NORMAL);
end;

procedure WriteSeparator;
begin
  WriteLn('═══════════════════════════════════════════════════════════');
end;

{ TCustomerOrder }

function TCustomerOrder.IsValid: Boolean;
begin
  Result := (Amount > 0) and (Quantity > 0) and
            (DiscountPercent >= 0) and (DiscountPercent <= 100);
end;


// Simulates loading orders from database
function LoadOrdersFromDatabase(const CustomerID: string): TArray<TCustomerOrder>;
var
  i: Integer;
  Order: TCustomerOrder;
  BaseAmount: Double;
begin
  SetLength(Result, 100);
  Randomize;

  // Simulates 100 "normal" orders + some hidden anomalies
  for i := 0 to 99 do
  begin
    Order.CustomerID := CustomerID;
    Order.OrderDate := EncodeDate(2024, 1, 1) + Random(365);

    // 90 normal orders (1000-3000€, 1-10 pieces, 0-15% discount)
    if i < 90 then
    begin
      BaseAmount := 1000 + Random(2000);
      Order.Amount := BaseAmount;
      Order.Quantity := 1 + Random(10);
      Order.DiscountPercent := Random(16);
    end
    // 5 orders with anomalous amounts (data entry errors or past frauds)
    else if i < 95 then
    begin
      // Hidden anomalies in historical data!
      case i mod 3 of
        0: Order.Amount := 50000;  // Amount too high
        1: Order.Amount := 10;     // Amount too low
        2: Order.Amount := 99999;  // Obvious error
      end;
      Order.Quantity := 1 + Random(5);
      Order.DiscountPercent := Random(20);
    end
    // 5 orders with anomalous discounts
    else
    begin
      Order.Amount := 1000 + Random(2000);
      Order.Quantity := 1 + Random(10);
      Order.DiscountPercent := 50 + Random(51); // 50-100% discount (suspicious!)
    end;

    Result[i] := Order;
  end;
end;

procedure DemoNaiveApproach;
var
  Orders: TArray<TCustomerOrder>;
  Amounts: TArray<Double>;
  Detector: TThreeSigmaDetector;
  i: Integer;
  TestOrder: TCustomerOrder;
  AnomalyResult: TAnomalyResult;
begin
  WriteColoredLine('=== APPROACH 1: NAIVE (WRONG) ===', COLOR_HEADER);
  WriteLn;
  WriteLn('Uses ALL historical data for learning, without cleaning.');
  WriteLn('Problem: if there are anomalies in the data, the detector learns them as "normal"!');
  WriteLn;

  // Load orders from "database"
  WriteColoredLine('→ Loading orders from database...', COLOR_INFO);
  Orders := LoadOrdersFromDatabase('CUST001');
  WriteLn(Format('  Loaded %d historical orders', [Length(Orders)]));
  WriteLn;

  // Extract all amounts (including hidden anomalies!)
  SetLength(Amounts, Length(Orders));
  for i := 0 to High(Orders) do
    Amounts[i] := Orders[i].Amount;

  // Create detector and use ALL data
  Detector := TThreeSigmaDetector.Create;
  try
    WriteColoredLine('→ Learning from ALL historical data...', COLOR_INFO);
    Detector.AddValues(Amounts);
    Detector.Build;

    WriteLn;
    WriteColoredLine('Statistics calculated:', COLOR_WARNING);
    WriteLn(Format('  Mean: %.2f€', [Detector.Mean]));
    WriteLn(Format('  Standard deviation: %.2f€', [Detector.StdDev]));
    WriteLn(Format('  Normal range: %.2f€ - %.2f€',
           [Detector.LowerLimit, Detector.UpperLimit]));
    WriteLn;
    WriteLn('⚠ PROBLEM: Mean and stddev are affected by present anomalies!');
    WriteLn('   Thresholds are too wide and won't detect similar new anomalies.');
    WriteLn;

    // Test with a suspicious order
    WriteSeparator;
    TestOrder.Amount := 45000;
    WriteColoredLine('→ Test: new order of 45,000€', COLOR_INFO);
    AnomalyResult := Detector.Detect(TestOrder.Amount);

    if AnomalyResult.IsAnomaly then
      WriteColoredLine(Format('  ❌ ANOMALY detected (Z-score: %.2f)',
                     [Abs(AnomalyResult.ZScore)]), COLOR_ERROR)
    else
      WriteColoredLine(Format('  ✓ NORMAL order (Z-score: %.2f)',
                     [Abs(AnomalyResult.ZScore)]), COLOR_SUCCESS);

    WriteLn;
    if not AnomalyResult.IsAnomaly then
      WriteColoredLine('  ⚠ FALSE NEGATIVE: The order should be anomalous!', COLOR_WARNING);

  finally
    Detector.Free;
  end;

  WriteLn;
  WriteLn('Press ENTER to continue...');
  ReadLn;
end;

procedure DemoRobustApproach;
var
  Orders: TArray<TCustomerOrder>;
  Amounts: TArray<Double>;
  CleaningResult: TCleaningResult;
  Detector: TThreeSigmaDetector;
  i: Integer;
  TestOrder: TCustomerOrder;
  AnomalyResult: TAnomalyResult;
begin
  WriteColoredLine('=== APPROACH 2: ROBUST WITH PERCENTILES (CORRECT) ===', COLOR_HEADER);
  WriteLn;
  WriteLn('Cleans data using percentiles before learning.');
  WriteLn('Only data in the 5th-95th percentile range are used for training.');
  WriteLn;

  // Load orders from "database"
  WriteColoredLine('→ Loading orders from database...', COLOR_INFO);
  Orders := LoadOrdersFromDatabase('CUST001');
  WriteLn(Format('  Loaded %d historical orders', [Length(Orders)]));
  WriteLn;

  // Estrai tutti gli importi
  SetLength(Amounts, Length(Orders));
  for i := 0 to High(Orders) do
    Amounts[i] := Orders[i].Amount;

  // CLEANING: use only data in 5-95 percentile range
  WriteColoredLine('→ Cleaning data with percentiles (5th - 95th)...', COLOR_INFO);
  CleaningResult := AnomalyDetection.Utils.CleanDataWithPercentiles(Amounts, 5, 95);
  WriteLn(Format('  Cleaning range: %.2f - %.2f',
         [CleaningResult.LowerBound, CleaningResult.UpperBound]));
  WriteLn(Format('  Original data: %d → Clean data: %d (removed: %d outliers)',
         [CleaningResult.OriginalCount, CleaningResult.CleanCount,
          CleaningResult.RemovedCount]));
  WriteLn;

  // Create detector and use ONLY clean data
  Detector := TThreeSigmaDetector.Create;
  try
    WriteColoredLine('→ Learning from CLEAN data...', COLOR_INFO);
    Detector.AddValues(CleaningResult.CleanData);
    Detector.Build;

    WriteLn;
    WriteColoredLine('Statistics calculated:', COLOR_SUCCESS);
    WriteLn(Format('  Mean: %.2f€', [Detector.Mean]));
    WriteLn(Format('  Standard deviation: %.2f€', [Detector.StdDev]));
    WriteLn(Format('  Normal range: %.2f€ - %.2f€',
           [Detector.LowerLimit, Detector.UpperLimit]));
    WriteLn;
    WriteLn('✓ Statistics now reflect only "normal" orders!');
    WriteLn('  Thresholds are tighter and more accurate.');
    WriteLn;

    // Test with the same suspicious order
    WriteSeparator;
    TestOrder.Amount := 45000;
    WriteColoredLine('→ Test: new order of 45,000€', COLOR_INFO);
    AnomalyResult := Detector.Detect(TestOrder.Amount);

    if AnomalyResult.IsAnomaly then
      WriteColoredLine(Format('  ❌ ANOMALY detected (Z-score: %.2f)',
                     [Abs(AnomalyResult.ZScore)]), COLOR_ERROR)
    else
      WriteColoredLine(Format('  ✓ NORMAL order (Z-score: %.2f)',
                     [Abs(AnomalyResult.ZScore)]), COLOR_SUCCESS);

    WriteLn;
    if AnomalyResult.IsAnomaly then
      WriteColoredLine('  ✓ CORRECT: The anomaly was detected!', COLOR_SUCCESS);

  finally
    Detector.Free;
  end;

  WriteLn;
  WriteLn('Press ENTER to continue...');
  ReadLn;
end;

procedure DemoIsolationForest;
var
  Orders: TArray<TCustomerOrder>;
  Detector: TIsolationForestDetector;
  i: Integer;
  TestCases: array[0..2] of TCustomerOrder;
  AnomalyResult: TAnomalyResult;
  TestData: TArray<Double>;
begin
  WriteColoredLine('=== APPROACH 3: ISOLATION FOREST (MULTI-DIMENSIONAL) ===', COLOR_HEADER);
  WriteLn;
  WriteLn('Isolation Forest is robust to anomalies in training data.');
  WriteLn('Analyzes MULTIPLE dimensions: amount, quantity, discount.');
  WriteLn;

  // Load orders from "database"
  WriteColoredLine('→ Loading orders from database...', COLOR_INFO);
  Orders := LoadOrdersFromDatabase('CUST001');
  WriteLn(Format('  Loaded %d historical orders', [Length(Orders)]));
  WriteLn;

  // Create multi-dimensional detector
  Detector := TIsolationForestDetector.Create(100, 256, 10);
  try
    WriteColoredLine('→ Training with multi-dimensional data...', COLOR_INFO);
    WriteLn('  (Amount, Quantity, Discount%)');

    // Add all data (even with anomalies, IF is robust)
    for i := 0 to High(Orders) do
    begin
      Detector.AddTrainingData([
        Orders[i].Amount,
        Orders[i].Quantity,
        Orders[i].DiscountPercent
      ]);
    end;

    Detector.Train;
    WriteColoredLine('  ✓ Training completed!', COLOR_SUCCESS);
    WriteLn;
    WriteLn('  Isolation Forest builds trees that isolate anomalous values.');
    WriteLn('  Anomalies present in the data have minimal impact on the model.');
    WriteLn;

    // Prepare test cases
    TestCases[0].Amount := 2000;
    TestCases[0].Quantity := 5;
    TestCases[0].DiscountPercent := 10;

    TestCases[1].Amount := 50000;  // Anomalous amount
    TestCases[1].Quantity := 1;
    TestCases[1].DiscountPercent := 5;

    TestCases[2].Amount := 1500;
    TestCases[2].Quantity := 2;
    TestCases[2].DiscountPercent := 85;  // Anomalous discount

    WriteSeparator;
    WriteColoredLine('→ Testing with multi-dimensional orders:', COLOR_INFO);
    WriteLn;

    for i := 0 to High(TestCases) do
    begin
      WriteLn(Format('Test %d: Amount=%.2f€, Quantity=%d, Discount=%.1f%%',
             [i + 1, TestCases[i].Amount, TestCases[i].Quantity,
              TestCases[i].DiscountPercent]));

      SetLength(TestData, 3);
      TestData[0] := TestCases[i].Amount;
      TestData[1] := TestCases[i].Quantity;
      TestData[2] := TestCases[i].DiscountPercent;

      AnomalyResult := Detector.DetectMultiDimensional(TestData);

      if AnomalyResult.IsAnomaly then
        WriteColoredLine(Format('  ❌ ANOMALY (Score: %.3f)',
                       [AnomalyResult.ZScore]), COLOR_ERROR)
      else
        WriteColoredLine(Format('  ✓ NORMAL (Score: %.3f)',
                       [AnomalyResult.ZScore]), COLOR_SUCCESS);
      WriteLn;
    end;

    WriteLn('✓ Isolation Forest detects anomalies on MULTIPLE dimensions simultaneously!');
    WriteLn('  An order can be anomalous by amount, quantity, discount, or combination.');

  finally
    Detector.Free;
  end;

  WriteLn;
  WriteLn('Press ENTER to continue...');
  ReadLn;
end;

begin
  try
    WriteSeparator;
    WriteColoredLine('  CUSTOMER ORDERS - Anomaly Detection Demo', COLOR_HEADER);
    WriteSeparator;
    WriteLn;
    WriteLn('This demo shows how to handle historical data that might');
    WriteLn('contain anomalies (errors, frauds, past bugs).');
    WriteLn;
    WriteLn('We will see 3 approaches:');
    WriteLn('  1. NAIVE - Uses all data (WRONG if there are anomalies)');
    WriteLn('  2. ROBUST - Cleans with percentiles before training');
    WriteLn('  3. ISOLATION FOREST - Robust multi-dimensional algorithm');
    WriteLn;
    WriteLn('Press ENTER to start...');
    ReadLn;
    WriteLn;

    // Demo 1: Naive approach (wrong)
    DemoNaiveApproach;
    WriteLn;

    // Demo 2: Robust approach with percentiles
    DemoRobustApproach;
    WriteLn;

    // Demo 3: Multi-dimensional Isolation Forest
    DemoIsolationForest;

    WriteSeparator;
    WriteColoredLine('Demo completed!', COLOR_HEADER);
    WriteSeparator;
    WriteLn;
    WriteColoredLine('CONCLUSIONS:', COLOR_SUCCESS);
    WriteLn;
    WriteLn('1. If you use ThreeSigma/SlidingWindow/EMA:');
    WriteLn('   → You MUST clean data with percentiles (5th-95th)');
    WriteLn('   → Or use only "certified normal" data');
    WriteLn;
    WriteLn('2. If you use Isolation Forest:');
    WriteLn('   → More robust, tolerates anomalies in data');
    WriteLn('   → Analyzes multiple dimensions together');
    WriteLn('   → Ideal for detecting frauds and complex patterns');
    WriteLn;
    WriteLn('3. Practical approach:');
    WriteLn('   → Analyze historical data with descriptive statistics');
    WriteLn('   → Use percentiles to identify outliers');
    WriteLn('   → Consider manual review for validation');
    WriteLn;

  except
    on E: Exception do
    begin
      WriteColoredLine('ERROR: ' + E.Message, COLOR_ERROR);
      ExitCode := 1;
    end;
  end;
end.
