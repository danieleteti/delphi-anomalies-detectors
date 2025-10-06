// ***************************************************************************
//
// Invoice Validator Unit
// Validates invoice amounts per supplier using Sliding Window detector
//
// ***************************************************************************

unit InvoiceValidator;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  AnomalyDetection.Types,
  AnomalyDetection.SlidingWindow;

type
  /// <summary>
  /// Invoice amount validator with per-supplier learning
  /// Uses Sliding Window to track last N invoices per supplier
  /// </summary>
  TInvoiceValidator = class
  private
    FDetectors: TDictionary<string, TSlidingWindowDetector>;
    FSampleCounts: TDictionary<string, Integer>;
    FMinSamplesForValidation: Integer;

    function GetOrCreateDetector(const ASupplierCode: string): TSlidingWindowDetector;
    function GetSampleCount(const ASupplierCode: string): Integer;
    procedure IncrementSampleCount(const ASupplierCode: string);
  public
    constructor Create(AMinSamplesForValidation: Integer = 10);
    destructor Destroy; override;

    /// <summary>
    /// Adds an invoice to the historical data for learning
    /// Use this during the initial training phase or when importing historical data
    /// </summary>
    /// <param name="ASupplierCode">Supplier code (e.g., "SUP001")</param>
    /// <param name="AAmount">Invoice amount</param>
    procedure LearnInvoiceAmount(const ASupplierCode: string; AAmount: Double);

    /// <summary>
    /// Validates invoice amount for a specific supplier
    /// Returns false if validation cannot be performed (not enough samples)
    /// </summary>
    /// <param name="ASupplierCode">Supplier code (e.g., "SUP001")</param>
    /// <param name="AAmount">Invoice amount to validate</param>
    /// <param name="AWarning">Warning message if anomaly detected or not enough data</param>
    /// <returns>True if amount is normal, False if anomalous or cannot validate</returns>
    function ValidateInvoiceAmount(const ASupplierCode: string;
                                   AAmount: Double;
                                   out AWarning: string): Boolean;

    /// <summary>
    /// Confirms an invoice amount as valid after user review
    /// Use this to add the amount to the learning set after manual verification
    /// </summary>
    procedure ConfirmInvoiceAmount(const ASupplierCode: string; AAmount: Double);

    /// <summary>
    /// Checks if supplier has enough samples for validation
    /// </summary>
    function CanValidateSupplier(const ASupplierCode: string): Boolean;

    /// <summary>
    /// Gets the number of suppliers being tracked
    /// </summary>
    function GetSupplierCount: Integer;

    /// <summary>
    /// Minimum number of samples required before validation is active
    /// Default: 10 invoices per supplier
    /// </summary>
    property MinSamplesForValidation: Integer read FMinSamplesForValidation write FMinSamplesForValidation;
  end;

implementation

{ TInvoiceValidator }

constructor TInvoiceValidator.Create(AMinSamplesForValidation: Integer);
begin
  inherited Create;
  FDetectors := TDictionary<string, TSlidingWindowDetector>.Create;
  FSampleCounts := TDictionary<string, Integer>.Create;
  FMinSamplesForValidation := AMinSamplesForValidation;
end;

destructor TInvoiceValidator.Destroy;
var
  Detector: TSlidingWindowDetector;
begin
  for Detector in FDetectors.Values do
    Detector.Free;
  FDetectors.Free;
  FSampleCounts.Free;
  inherited;
end;

function TInvoiceValidator.GetOrCreateDetector(const ASupplierCode: string): TSlidingWindowDetector;
begin
  if not FDetectors.TryGetValue(ASupplierCode, Result) then
  begin
    Result := TSlidingWindowDetector.Create(50); // Track last 50 invoices
    FDetectors.Add(ASupplierCode, Result);
  end;
end;

function TInvoiceValidator.GetSampleCount(const ASupplierCode: string): Integer;
begin
  if not FSampleCounts.TryGetValue(ASupplierCode, Result) then
    Result := 0;
end;

procedure TInvoiceValidator.IncrementSampleCount(const ASupplierCode: string);
var
  CurrentCount: Integer;
begin
  if FSampleCounts.TryGetValue(ASupplierCode, CurrentCount) then
    FSampleCounts[ASupplierCode] := CurrentCount + 1
  else
    FSampleCounts.Add(ASupplierCode, 1);
end;

procedure TInvoiceValidator.LearnInvoiceAmount(const ASupplierCode: string; AAmount: Double);
var
  Detector: TSlidingWindowDetector;
begin
  Detector := GetOrCreateDetector(ASupplierCode);
  Detector.AddValue(AAmount);
  IncrementSampleCount(ASupplierCode);
end;

function TInvoiceValidator.ValidateInvoiceAmount(const ASupplierCode: string;
                                                  AAmount: Double;
                                                  out AWarning: string): Boolean;
var
  Detector: TSlidingWindowDetector;
  AnomalyResult: TAnomalyResult;
  SampleCount: Integer;
begin
  Detector := GetOrCreateDetector(ASupplierCode);
  SampleCount := GetSampleCount(ASupplierCode);

  // Check if we have enough samples for reliable validation
  if SampleCount < FMinSamplesForValidation then
  begin
    AWarning := Format('Cannot validate - only %d invoices for supplier %s (need %d for reliable validation)',
                       [SampleCount, ASupplierCode, FMinSamplesForValidation]);
    Result := False; // Cannot validate yet
    Exit;
  end;

  // Perform anomaly detection
  AnomalyResult := Detector.Detect(AAmount);

  if AnomalyResult.IsAnomaly then
  begin
    AWarning := Format('Unusual amount for supplier %s: %.2f € ' +
                       '(Expected range: %.2f - %.2f €, Z-score: %.2f)',
                       [ASupplierCode, AAmount,
                        AnomalyResult.LowerLimit, AnomalyResult.UpperLimit,
                        AnomalyResult.ZScore]);
    Result := False; // Requires verification
  end
  else
  begin
    AWarning := '';
    Result := True; // Normal amount
  end;

  // Note: Do NOT add to history here - use ConfirmInvoiceAmount after validation
end;

procedure TInvoiceValidator.ConfirmInvoiceAmount(const ASupplierCode: string; AAmount: Double);
var
  Detector: TSlidingWindowDetector;
begin
  Detector := GetOrCreateDetector(ASupplierCode);
  Detector.AddValue(AAmount);
  IncrementSampleCount(ASupplierCode);
end;

function TInvoiceValidator.CanValidateSupplier(const ASupplierCode: string): Boolean;
begin
  Result := GetSampleCount(ASupplierCode) >= FMinSamplesForValidation;
end;

function TInvoiceValidator.GetSupplierCount: Integer;
begin
  Result := FDetectors.Count;
end;

end.
