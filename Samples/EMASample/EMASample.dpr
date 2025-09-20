// ***************************************************************************
//
// EMA Detector Example - Financial Market Price Monitoring
// Demonstrates exponential moving average for adaptive anomaly detection
//
// ***************************************************************************

program EMAExample;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Math,
  System.DateUtils,
  {$IFDEF MSWINDOWS}
  WinAPI.Windows,
  {$ENDIF}
  AnomalyDetectionAlgorithms;

type
  TMarketEvent = record
    Hour, Minute: Integer;
    EventType: string;
    Description: string;
    PriceMultiplier: Double;
  end;

const
  // Console colors
  {$IFDEF MSWINDOWS}
  COLOR_NORMAL = 7;
  COLOR_ANOMALY = 12;  // Light red
  COLOR_WARNING = 14;  // Yellow
  COLOR_INFO = 11;     // Light cyan
  COLOR_SUCCESS = 10;  // Light green
  COLOR_PRICE_UP = 10; // Green for price increases
  COLOR_PRICE_DOWN = 12; // Red for price decreases
  {$ENDIF}

procedure SetConsoleColor(Color: Word);
begin
  {$IFDEF MSWINDOWS}
  var Handle := GetStdHandle(STD_OUTPUT_HANDLE);
  SetConsoleTextAttribute(Handle, Color);
  {$ENDIF}
end;

procedure WriteColoredLine(const Text: string; Color: Word);
begin
  SetConsoleColor(Color);
  WriteLn(Text);
  SetConsoleColor(COLOR_NORMAL);
end;

function SimulateStockPrice(Hour, Minute: Integer; LastPrice: Double): Double;
var
  TotalMinutes: Integer;
  TrendFactor, VolatilityFactor, Noise: Double;
begin
  TotalMinutes := Hour * 60 + Minute;

  // Simulate intraday trend (general upward bias during trading day)
  if (Hour >= 9) and (Hour <= 16) then
  begin
    // Trading hours - more activity and slight upward bias
    TrendFactor := 1.0 + (Sin(TotalMinutes * Pi / 480) * 0.002); // 0.2% max trend
    VolatilityFactor := 0.015; // 1.5% volatility during trading
  end
  else
  begin
    // After hours - less volatility
    TrendFactor := 1.0;
    VolatilityFactor := 0.005; // 0.5% volatility after hours
  end;

  // Random market noise
  Noise := 1.0 + (Random - 0.5) * 2 * VolatilityFactor;

  Result := LastPrice * TrendFactor * Noise;
end;

procedure SimulateMarketEvent(var Price: Double; const Event: TMarketEvent);
begin
  Price := Price * Event.PriceMultiplier;
end;

procedure RunStockPriceMonitoring;
var
  FastDetector, SlowDetector: TEMAAnomalyDetector;
  Hour, Minute: Integer;
  CurrentPrice, InitialPrice: Double;
  Result: TAnomalyResult;
  TotalAnomalies, EventsDetected: Integer;
  MarketEvents: array[0..4] of TMarketEvent;
  i: Integer;
  EventTriggered: Boolean;
  BaselineData: TArray<Double>;
  PriceChangeVsEMA, PriceChangeDaily: Double;
begin
  WriteColoredLine('=== REAL-TIME STOCK PRICE MONITORING ===', COLOR_INFO);
  WriteLn('Using EMA Detector (α=0.05) for adaptive price anomaly detection');
  WriteLn('Stock: TECH Corp (Simulated)');
  WriteLn;

  FastDetector := TEMAAnomalyDetector.Create(0.05);
  SlowDetector := TEMAAnomalyDetector.Create(0.01);
  try
    TotalAnomalies := 0;
    EventsDetected := 0;
    InitialPrice := 150.0;

    // Schedule market events
    MarketEvents[0].Hour := 9; MarketEvents[0].Minute := 30;
    MarketEvents[0].EventType := 'earnings'; MarketEvents[0].Description := 'Positive Earnings Beat';
    MarketEvents[0].PriceMultiplier := 1.08;

    MarketEvents[1].Hour := 11; MarketEvents[1].Minute := 15;
    MarketEvents[1].EventType := 'news'; MarketEvents[1].Description := 'FDA Approval News';
    MarketEvents[1].PriceMultiplier := 1.12;

    MarketEvents[2].Hour := 13; MarketEvents[2].Minute := 45;
    MarketEvents[2].EventType := 'selloff'; MarketEvents[2].Description := 'Large Block Sale';
    MarketEvents[2].PriceMultiplier := 0.92;

    MarketEvents[3].Hour := 15; MarketEvents[3].Minute := 20;
    MarketEvents[3].EventType := 'rumor'; MarketEvents[3].Description := 'Acquisition Rumor';
    MarketEvents[3].PriceMultiplier := 1.15;

    MarketEvents[4].Hour := 16; MarketEvents[4].Minute := 30;
    MarketEvents[4].EventType := 'correction'; MarketEvents[4].Description := 'Market Correction';
    MarketEvents[4].PriceMultiplier := 0.88;

    WriteColoredLine('Step 1: Initializing with pre-market baseline (30 minutes)...', COLOR_INFO);

    SetLength(BaselineData, 30);
    CurrentPrice := InitialPrice;
    for i := 0 to 29 do
    begin
      BaselineData[i] := SimulateStockPrice(8, 30 + i, CurrentPrice);
      CurrentPrice := BaselineData[i];
    end;

    FastDetector.WarmUp(BaselineData);
    SlowDetector.WarmUp(BaselineData);

    WriteColoredLine(Format('✓ Baseline established at $%.2f', [CurrentPrice]), COLOR_SUCCESS);
    WriteLn(Format('  Fast EMA range: $%.2f - $%.2f', [FastDetector.LowerLimit, FastDetector.UpperLimit]));
    WriteLn(Format('  Slow EMA range: $%.2f - $%.2f', [SlowDetector.LowerLimit, SlowDetector.UpperLimit]));
    WriteLn;

    WriteColoredLine('Step 2: Monitoring trading session (9:00 AM - 5:00 PM)...', COLOR_INFO);
    WriteLn;

    for Hour := 9 to 16 do
    begin
      for Minute := 0 to 59 do
      begin
        CurrentPrice := SimulateStockPrice(Hour, Minute, CurrentPrice);
        EventTriggered := False;

        // Check for market events
        for i := 0 to High(MarketEvents) do
        begin
          if (MarketEvents[i].Hour = Hour) and (MarketEvents[i].Minute = Minute) then
          begin
            WriteColoredLine(Format('[%02d:%02d] 📰 %s', [Hour, Minute, MarketEvents[i].Description]), COLOR_WARNING);
            SimulateMarketEvent(CurrentPrice, MarketEvents[i]);
            EventTriggered := True;
          end;
        end;

        FastDetector.AddValue(CurrentPrice);
        SlowDetector.AddValue(CurrentPrice);
        Result := FastDetector.Detect(CurrentPrice);

        if Result.IsAnomaly then
        begin
          Inc(TotalAnomalies);
          if EventTriggered then Inc(EventsDetected);

          PriceChangeVsEMA := ((CurrentPrice - FastDetector.CurrentMean) / FastDetector.CurrentMean) * 100;

          if CurrentPrice > FastDetector.CurrentMean then
          begin
            WriteColoredLine(Format('[%02d:%02d] 🚨 PRICE SPIKE: $%.2f (+%.1f%% vs EMA) Z-score: %.2f',
              [Hour, Minute, CurrentPrice, Abs(PriceChangeVsEMA), Result.ZScore]), COLOR_PRICE_UP);
            WriteLn('   → Possible: Positive news, earnings beat, or acquisition rumors');
          end
          else
          begin
            WriteColoredLine(Format('[%02d:%02d] 🚨 PRICE DROP: $%.2f (%.1f%% vs EMA) Z-score: %.2f',
              [Hour, Minute, CurrentPrice, PriceChangeVsEMA, Result.ZScore]), COLOR_PRICE_DOWN);
            WriteLn('   → Possible: Negative news, selloff, or market correction');
          end;
        end
        else if (Minute mod 30) = 0 then
        begin
          PriceChangeDaily := ((CurrentPrice - InitialPrice) / InitialPrice) * 100;
          if PriceChangeDaily >= 0 then
            WriteLn(Format('[%02d:%02d] ✓ Normal: $%.2f (+%.1f%% daily) EMA: $%.2f',
              [Hour, Minute, CurrentPrice, PriceChangeDaily, FastDetector.CurrentMean]))
          else
            WriteLn(Format('[%02d:%02d] ✓ Normal: $%.2f (%.1f%% daily) EMA: $%.2f',
              [Hour, Minute, CurrentPrice, PriceChangeDaily, FastDetector.CurrentMean]));
        end;

        if (Hour mod 2 = 0) and (Minute = 0) and (Hour >= 10) then
        begin
          WriteLn;
          WriteColoredLine(Format('--- %02d:00 EMA Update ---', [Hour]), COLOR_INFO);
          WriteLn(Format('Fast EMA (α=0.05): $%.2f ± $%.2f', [FastDetector.CurrentMean, FastDetector.CurrentStdDev]));
          WriteLn(Format('Slow EMA (α=0.01): $%.2f ± $%.2f', [SlowDetector.CurrentMean, SlowDetector.CurrentStdDev]));
          WriteLn(Format('Price volatility: %.1f%%', [FastDetector.CurrentStdDev / FastDetector.CurrentMean * 100]));
          WriteLn(Format('Current price: $%.2f', [CurrentPrice]));
          WriteLn;
        end;
      end;
    end;

    WriteLn;
    WriteColoredLine('=== TRADING SESSION SUMMARY ===', COLOR_SUCCESS);
    WriteLn(Format('• Total price anomalies detected: %d', [TotalAnomalies]));
    WriteLn(Format('• Market events simulated: %d', [Length(MarketEvents)]));
    WriteLn(Format('• Market events detected: %d', [EventsDetected]));
    if Length(MarketEvents) > 0 then
      WriteLn(Format('• Event detection rate: %.1f%% (%d/%d)',
        [(EventsDetected / Length(MarketEvents)) * 100, EventsDetected, Length(MarketEvents)]));
    WriteLn(Format('• Final price: $%.2f', [CurrentPrice]));
    PriceChangeDaily := ((CurrentPrice - InitialPrice) / InitialPrice) * 100;
    WriteLn(Format('• Price change from open: %.1f%%', [PriceChangeDaily]));
    WriteLn(Format('• Fast EMA range: $%.2f - $%.2f', [Max(0.0, FastDetector.LowerLimit), FastDetector.UpperLimit]));

  finally
    SlowDetector.Free;
    FastDetector.Free;
  end;
end;

procedure DemonstrateAlphaParameter;
var
  FastEMA, MediumEMA, SlowEMA: TEMAAnomalyDetector;
  i: Integer;
  Price: Double;
begin
  WriteColoredLine('=== EMA ALPHA PARAMETER DEMONSTRATION ===', COLOR_INFO);
  WriteLn('Comparing different adaptation speeds for market volatility');
  WriteLn;

  FastEMA := TEMAAnomalyDetector.Create(0.3);
  MediumEMA := TEMAAnomalyDetector.Create(0.1);
  SlowEMA := TEMAAnomalyDetector.Create(0.03);
  try
    WriteColoredLine('Phase 1: Stable trading around $100', COLOR_INFO);

    for i := 1 to 20 do
    begin
      Price := 100 + Random(4) - 2; // $98-$102 range
      FastEMA.AddValue(Price);
      MediumEMA.AddValue(Price);
      SlowEMA.AddValue(Price);
    end;

    WriteLn(Format('  Fast EMA (α=0.3): $%.2f', [FastEMA.CurrentMean]));
    WriteLn(Format('  Medium EMA (α=0.1): $%.2f', [MediumEMA.CurrentMean]));
    WriteLn(Format('  Slow EMA (α=0.03): $%.2f', [SlowEMA.CurrentMean]));
    WriteLn;

    WriteColoredLine('Phase 2: Sudden price jump to $130 (market shock)', COLOR_WARNING);

    for i := 1 to 10 do
    begin
      Price := 130 + Random(6) - 3; // $127-$133 range
      FastEMA.AddValue(Price);
      MediumEMA.AddValue(Price);
      SlowEMA.AddValue(Price);
    end;

    WriteLn(Format('  Fast EMA (α=0.3): $%.2f (adapted quickly)', [FastEMA.CurrentMean]));
    WriteLn(Format('  Medium EMA (α=0.1): $%.2f (moderate adaptation)', [MediumEMA.CurrentMean]));
    WriteLn(Format('  Slow EMA (α=0.03): $%.2f (slow adaptation)', [SlowEMA.CurrentMean]));
    WriteLn;

    WriteColoredLine('Key Insights:', COLOR_SUCCESS);
    WriteLn('• Higher α (0.3): Fast adaptation, sensitive to recent changes');
    WriteLn('• Medium α (0.1): Balanced approach, standard for most applications');
    WriteLn('• Lower α (0.03): Stable baseline, resistant to temporary volatility');
    WriteLn('• Choice depends on: market type, volatility tolerance, false positive acceptance');

  finally
    SlowEMA.Free;
    MediumEMA.Free;
    FastEMA.Free;
  end;
end;

// Main program
begin
  try
    Randomize;

    WriteLn('EMA Anomaly Detection - Financial Markets Example');
    WriteLn('Scenario: Real-time stock price monitoring for unusual movements');
    WriteLn(StringOfChar('=', 70));
    WriteLn;

    RunStockPriceMonitoring;

    WriteLn;
    WriteLn(StringOfChar('-', 70));
    WriteLn;

    DemonstrateAlphaParameter;

    WriteLn;
    WriteColoredLine('=== EMA DETECTOR ADVANTAGES ===', COLOR_INFO);
    WriteLn('✓ Rapid adaptation to changing market conditions');
    WriteLn('✓ Weighted focus on recent price movements');
    WriteLn('✓ Excellent for trending financial data');
    WriteLn('✓ Configurable sensitivity via alpha parameter');
    WriteLn('✓ Memory efficient - no historical data storage');
    WriteLn('✓ Real-time processing with minimal computational overhead');

    WriteLn;
    WriteColoredLine('Demo completed successfully!', COLOR_SUCCESS);
    WriteLn('Press ENTER to exit...');
    ReadLn;

  except
    on E: Exception do
    begin
      WriteColoredLine('ERROR: ' + E.Message, COLOR_ANOMALY);
      WriteLn('Press ENTER to exit...');
      ReadLn;
      ExitCode := 1;
    end;
  end;
end.
