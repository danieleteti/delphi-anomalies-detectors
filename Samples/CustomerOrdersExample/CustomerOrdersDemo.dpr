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


// Simula il caricamento di ordini da database
function LoadOrdersFromDatabase(const CustomerID: string): TArray<TCustomerOrder>;
var
  i: Integer;
  Order: TCustomerOrder;
  BaseAmount: Double;
begin
  SetLength(Result, 100);
  Randomize;

  // Simula 100 ordini "normali" + alcune anomalie nascoste
  for i := 0 to 99 do
  begin
    Order.CustomerID := CustomerID;
    Order.OrderDate := EncodeDate(2024, 1, 1) + Random(365);

    // 90 ordini normali (1000-3000€, 1-10 pezzi, 0-15% sconto)
    if i < 90 then
    begin
      BaseAmount := 1000 + Random(2000);
      Order.Amount := BaseAmount;
      Order.Quantity := 1 + Random(10);
      Order.DiscountPercent := Random(16);
    end
    // 5 ordini con importi anomali (errori di data entry o frodi passate)
    else if i < 95 then
    begin
      // Anomalie nascoste nei dati storici!
      case i mod 3 of
        0: Order.Amount := 50000;  // Importo troppo alto
        1: Order.Amount := 10;     // Importo troppo basso
        2: Order.Amount := 99999;  // Errore evidente
      end;
      Order.Quantity := 1 + Random(5);
      Order.DiscountPercent := Random(20);
    end
    // 5 ordini con sconti anomali
    else
    begin
      Order.Amount := 1000 + Random(2000);
      Order.Quantity := 1 + Random(10);
      Order.DiscountPercent := 50 + Random(51); // 50-100% sconto (sospetto!)
    end;

    Result[i] := Order;
  end;
end;

procedure DemoApproccioNaive;
var
  Orders: TArray<TCustomerOrder>;
  Amounts: TArray<Double>;
  Detector: TThreeSigmaDetector;
  i: Integer;
  TestOrder: TCustomerOrder;
  AnomalyResult: TAnomalyResult;
begin
  WriteColoredLine('═══ APPROCCIO 1: NAIVE (SBAGLIATO) ═══', COLOR_HEADER);
  WriteLn;
  WriteLn('Usa TUTTI i dati storici per l''apprendimento, senza pulizia.');
  WriteLn('Problema: se ci sono anomalie nei dati, il detector le impara come "normali"!');
  WriteLn;

  // Carica ordini dal "database"
  WriteColoredLine('→ Caricamento ordini dal database...', COLOR_INFO);
  Orders := LoadOrdersFromDatabase('CUST001');
  WriteLn(Format('  Caricati %d ordini storici', [Length(Orders)]));
  WriteLn;

  // Estrai tutti gli importi (incluse le anomalie nascoste!)
  SetLength(Amounts, Length(Orders));
  for i := 0 to High(Orders) do
    Amounts[i] := Orders[i].Amount;

  // Crea detector e usa TUTTI i dati
  Detector := TThreeSigmaDetector.Create;
  try
    WriteColoredLine('→ Apprendimento da TUTTI i dati storici...', COLOR_INFO);
    Detector.AddValues(Amounts);
    Detector.Build;

    WriteLn;
    WriteColoredLine('Statistiche calcolate:', COLOR_WARNING);
    WriteLn(Format('  Media: %.2f€', [Detector.Mean]));
    WriteLn(Format('  Deviazione standard: %.2f€', [Detector.StdDev]));
    WriteLn(Format('  Range normale: %.2f€ - %.2f€',
           [Detector.LowerLimit, Detector.UpperLimit]));
    WriteLn;
    WriteLn('⚠ PROBLEMA: La media e lo stddev sono influenzati dalle anomalie presenti!');
    WriteLn('   Le soglie sono troppo larghe e non rileveranno nuove anomalie simili.');
    WriteLn;

    // Test con un ordine sospetto
    WriteSeparator;
    TestOrder.Amount := 45000;
    WriteColoredLine('→ Test: nuovo ordine da 45.000€', COLOR_INFO);
    AnomalyResult := Detector.Detect(TestOrder.Amount);

    if AnomalyResult.IsAnomaly then
      WriteColoredLine(Format('  ❌ ANOMALIA rilevata (Z-score: %.2f)',
                     [Abs(AnomalyResult.ZScore)]), COLOR_ERROR)
    else
      WriteColoredLine(Format('  ✓ Ordine NORMALE (Z-score: %.2f)',
                     [Abs(AnomalyResult.ZScore)]), COLOR_SUCCESS);

    WriteLn;
    if not AnomalyResult.IsAnomaly then
      WriteColoredLine('  ⚠ FALSO NEGATIVO: L''ordine dovrebbe essere anomalo!', COLOR_WARNING);

  finally
    Detector.Free;
  end;

  WriteLn;
  WriteLn('Press ENTER to continue...');
  ReadLn;
end;

procedure DemoApproccioRobusto;
var
  Orders: TArray<TCustomerOrder>;
  Amounts: TArray<Double>;
  CleaningResult: TCleaningResult;
  Detector: TThreeSigmaDetector;
  i: Integer;
  TestOrder: TCustomerOrder;
  AnomalyResult: TAnomalyResult;
begin
  WriteColoredLine('═══ APPROCCIO 2: ROBUSTO CON PERCENTILI (CORRETTO) ═══', COLOR_HEADER);
  WriteLn;
  WriteLn('Pulisce i dati usando i percentili prima dell''apprendimento.');
  WriteLn('Solo i dati nel range 5°-95° percentile vengono usati per il training.');
  WriteLn;

  // Carica ordini dal "database"
  WriteColoredLine('→ Caricamento ordini dal database...', COLOR_INFO);
  Orders := LoadOrdersFromDatabase('CUST001');
  WriteLn(Format('  Caricati %d ordini storici', [Length(Orders)]));
  WriteLn;

  // Estrai tutti gli importi
  SetLength(Amounts, Length(Orders));
  for i := 0 to High(Orders) do
    Amounts[i] := Orders[i].Amount;

  // PULIZIA: usa solo dati nel range 5-95 percentile
  WriteColoredLine('→ Pulizia dati con percentili (5° - 95°)...', COLOR_INFO);
  CleaningResult := AnomalyDetection.Utils.CleanDataWithPercentiles(Amounts, 5, 95);
  WriteLn(Format('  Range di pulizia: %.2f - %.2f',
         [CleaningResult.LowerBound, CleaningResult.UpperBound]));
  WriteLn(Format('  Dati originali: %d → Dati puliti: %d (rimossi: %d outliers)',
         [CleaningResult.OriginalCount, CleaningResult.CleanCount,
          CleaningResult.RemovedCount]));
  WriteLn;

  // Crea detector e usa SOLO i dati puliti
  Detector := TThreeSigmaDetector.Create;
  try
    WriteColoredLine('→ Apprendimento dai dati PULITI...', COLOR_INFO);
    Detector.AddValues(CleaningResult.CleanData);
    Detector.Build;

    WriteLn;
    WriteColoredLine('Statistiche calcolate:', COLOR_SUCCESS);
    WriteLn(Format('  Media: %.2f€', [Detector.Mean]));
    WriteLn(Format('  Deviazione standard: %.2f€', [Detector.StdDev]));
    WriteLn(Format('  Range normale: %.2f€ - %.2f€',
           [Detector.LowerLimit, Detector.UpperLimit]));
    WriteLn;
    WriteLn('✓ Le statistiche ora riflettono solo gli ordini "normali"!');
    WriteLn('  Le soglie sono più strette e accurate.');
    WriteLn;

    // Test con lo stesso ordine sospetto
    WriteSeparator;
    TestOrder.Amount := 45000;
    WriteColoredLine('→ Test: nuovo ordine da 45.000€', COLOR_INFO);
    AnomalyResult := Detector.Detect(TestOrder.Amount);

    if AnomalyResult.IsAnomaly then
      WriteColoredLine(Format('  ❌ ANOMALIA rilevata (Z-score: %.2f)',
                     [Abs(AnomalyResult.ZScore)]), COLOR_ERROR)
    else
      WriteColoredLine(Format('  ✓ Ordine NORMALE (Z-score: %.2f)',
                     [Abs(AnomalyResult.ZScore)]), COLOR_SUCCESS);

    WriteLn;
    if AnomalyResult.IsAnomaly then
      WriteColoredLine('  ✓ CORRETTO: L''anomalia è stata rilevata!', COLOR_SUCCESS);

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
  WriteColoredLine('═══ APPROCCIO 3: ISOLATION FOREST (MULTI-DIMENSIONALE) ═══', COLOR_HEADER);
  WriteLn;
  WriteLn('Isolation Forest è robusto alle anomalie nei dati di training.');
  WriteLn('Analizza MULTIPLE dimensioni: importo, quantità, sconto.');
  WriteLn;

  // Carica ordini dal "database"
  WriteColoredLine('→ Caricamento ordini dal database...', COLOR_INFO);
  Orders := LoadOrdersFromDatabase('CUST001');
  WriteLn(Format('  Caricati %d ordini storici', [Length(Orders)]));
  WriteLn;

  // Crea detector multi-dimensionale
  Detector := TIsolationForestDetector.Create(100, 256, 10);
  try
    WriteColoredLine('→ Training con dati multi-dimensionali...', COLOR_INFO);
    WriteLn('  (Importo, Quantità, Sconto%)');

    // Aggiungi tutti i dati (anche con anomalie, IF è robusto)
    for i := 0 to High(Orders) do
    begin
      Detector.AddTrainingData([
        Orders[i].Amount,
        Orders[i].Quantity,
        Orders[i].DiscountPercent
      ]);
    end;

    Detector.Train;
    WriteColoredLine('  ✓ Training completato!', COLOR_SUCCESS);
    WriteLn;
    WriteLn('  Isolation Forest costruisce alberi che isolano i valori anomali.');
    WriteLn('  Le anomalie presenti nei dati hanno impatto minimo sul modello.');
    WriteLn;

    // Prepara casi di test
    TestCases[0].Amount := 2000;
    TestCases[0].Quantity := 5;
    TestCases[0].DiscountPercent := 10;

    TestCases[1].Amount := 50000;  // Importo anomalo
    TestCases[1].Quantity := 1;
    TestCases[1].DiscountPercent := 5;

    TestCases[2].Amount := 1500;
    TestCases[2].Quantity := 2;
    TestCases[2].DiscountPercent := 85;  // Sconto anomalo

    WriteSeparator;
    WriteColoredLine('→ Test con ordini multi-dimensionali:', COLOR_INFO);
    WriteLn;

    for i := 0 to High(TestCases) do
    begin
      WriteLn(Format('Test %d: Importo=%.2f€, Quantità=%d, Sconto=%.1f%%',
             [i + 1, TestCases[i].Amount, TestCases[i].Quantity,
              TestCases[i].DiscountPercent]));

      SetLength(TestData, 3);
      TestData[0] := TestCases[i].Amount;
      TestData[1] := TestCases[i].Quantity;
      TestData[2] := TestCases[i].DiscountPercent;

      AnomalyResult := Detector.DetectMultiDimensional(TestData);

      if AnomalyResult.IsAnomaly then
        WriteColoredLine(Format('  ❌ ANOMALIA (Score: %.3f)',
                       [AnomalyResult.ZScore]), COLOR_ERROR)
      else
        WriteColoredLine(Format('  ✓ NORMALE (Score: %.3f)',
                       [AnomalyResult.ZScore]), COLOR_SUCCESS);
      WriteLn;
    end;

    WriteLn('✓ Isolation Forest rileva anomalie su MULTIPLE dimensioni contemporaneamente!');
    WriteLn('  Un ordine può essere anomalo per importo, quantità, sconto, o combinazione.');

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
    WriteLn('Questo demo mostra come gestire dati storici che potrebbero');
    WriteLn('contenere anomalie (errori, frodi, bug passati).');
    WriteLn;
    WriteLn('Vedremo 3 approcci:');
    WriteLn('  1. NAIVE - Usa tutti i dati (SBAGLIATO se ci sono anomalie)');
    WriteLn('  2. ROBUSTO - Pulisce con percentili prima del training');
    WriteLn('  3. ISOLATION FOREST - Algoritmo robusto multi-dimensionale');
    WriteLn;
    WriteLn('Press ENTER to start...');
    ReadLn;
    WriteLn;

    // Demo 1: Approccio naive (sbagliato)
    DemoApproccioNaive;
    WriteLn;

    // Demo 2: Approccio robusto con percentili
    DemoApproccioRobusto;
    WriteLn;

    // Demo 3: Isolation Forest multi-dimensionale
    DemoIsolationForest;

    WriteSeparator;
    WriteColoredLine('Demo completato!', COLOR_HEADER);
    WriteSeparator;
    WriteLn;
    WriteColoredLine('CONCLUSIONI:', COLOR_SUCCESS);
    WriteLn;
    WriteLn('1. Se usi ThreeSigma/SlidingWindow/EMA:');
    WriteLn('   → DEVI pulire i dati con percentili (5°-95°)');
    WriteLn('   → Oppure usa solo dati "certificati normali"');
    WriteLn;
    WriteLn('2. Se usi Isolation Forest:');
    WriteLn('   → Più robusto, tollera anomalie nei dati');
    WriteLn('   → Analizza multiple dimensioni insieme');
    WriteLn('   → Ideale per rilevare frodi e pattern complessi');
    WriteLn;
    WriteLn('3. Approccio pratico:');
    WriteLn('   → Analizza i dati storici con statistiche descrittive');
    WriteLn('   → Usa percentili per identificare outliers');
    WriteLn('   → Considera review manuale per validazione');
    WriteLn;

  except
    on E: Exception do
    begin
      WriteColoredLine('ERROR: ' + E.Message, COLOR_ERROR);
      ExitCode := 1;
    end;
  end;
end.
