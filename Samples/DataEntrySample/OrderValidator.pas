// ***************************************************************************
//
// Order Validator Unit
// Validates order patterns using multi-dimensional analysis
// Detects unusual combinations of amount, quantity, and discount
//
// ***************************************************************************

unit OrderValidator;

interface

uses
  System.SysUtils,
  AnomalyDetection.Types,
  AnomalyDetection.IsolationForest;

type
  /// <summary>
  /// Order pattern validator using Isolation Forest
  /// Analyzes combinations of Amount, Quantity, and Discount%
  /// </summary>
  TOrderValidator = class
  private
    FDetector: TIsolationForestDetector;
    FIsTraining: Boolean;
    FTrainingCount: Integer;
    FTrainingThreshold: Integer;
  public
    constructor Create(ATrainingThreshold: Integer = 500);
    destructor Destroy; override;

    /// <summary>
    /// Adds a training sample (normal order)
    /// </summary>
    procedure AddTrainingOrder(AAmount, AQuantity, ADiscount: Double);

    /// <summary>
    /// Completes training and activates the detector
    /// </summary>
    procedure FinishTraining;

    /// <summary>
    /// Validates an order pattern
    /// </summary>
    /// <param name="AAmount">Order amount in currency</param>
    /// <param name="AQuantity">Order quantity</param>
    /// <param name="ADiscount">Discount percentage (0-100)</param>
    /// <param name="ASuspicionLevel">Description of suspicion level</param>
    /// <returns>True if order is normal, False if suspicious</returns>
    function ValidateOrder(AAmount, AQuantity, ADiscount: Double;
                          out ASuspicionLevel: string): Boolean;

    /// <summary>
    /// Returns true if detector is still in training mode
    /// </summary>
    property IsTraining: Boolean read FIsTraining;

    /// <summary>
    /// Number of training samples collected
    /// </summary>
    property TrainingCount: Integer read FTrainingCount;

    /// <summary>
    /// Training threshold (number of samples needed)
    /// </summary>
    property TrainingThreshold: Integer read FTrainingThreshold;
  end;

implementation

{ TOrderValidator }

constructor TOrderValidator.Create(ATrainingThreshold: Integer);
begin
  inherited Create;
  // 3 dimensions: Amount, Quantity, Discount%
  FDetector := TIsolationForestDetector.Create(100, 256, 3);
  FIsTraining := True;
  FTrainingCount := 0;
  FTrainingThreshold := ATrainingThreshold;
end;

destructor TOrderValidator.Destroy;
begin
  FDetector.Free;
  inherited;
end;

procedure TOrderValidator.AddTrainingOrder(AAmount, AQuantity, ADiscount: Double);
begin
  if FIsTraining then
  begin
    FDetector.AddTrainingData([AAmount, AQuantity, ADiscount]);
    Inc(FTrainingCount);

    // Auto-train when threshold reached
    if FTrainingCount >= FTrainingThreshold then
      FinishTraining;
  end;
end;

procedure TOrderValidator.FinishTraining;
begin
  if FIsTraining and (FTrainingCount > 0) then
  begin
    FDetector.Train;
    FIsTraining := False;
  end;
end;

function TOrderValidator.ValidateOrder(AAmount, AQuantity, ADiscount: Double;
                                       out ASuspicionLevel: string): Boolean;
var
  AnomalyResult: TAnomalyResult;
  OrderData: TArray<Double>;
begin
  // Cannot validate during training phase
  if FIsTraining then
  begin
    ASuspicionLevel := Format('Cannot validate - still in training mode (%d/%d samples collected)',
                              [FTrainingCount, FTrainingThreshold]);
    Result := False; // Cannot validate yet
    Exit;
  end;

  OrderData := [AAmount, AQuantity, ADiscount];
  AnomalyResult := FDetector.DetectMultiDimensional(OrderData);

  if AnomalyResult.IsAnomaly then
  begin
    // Classify suspicion level based on anomaly score
    if AnomalyResult.ZScore > 0.7 then
      ASuspicionLevel := 'HIGH - Highly unusual order pattern detected'
    else if AnomalyResult.ZScore > 0.5 then
      ASuspicionLevel := 'MEDIUM - Uncommon order combination'
    else
      ASuspicionLevel := 'LOW - Slightly unusual order';

    Result := False;
  end
  else
  begin
    ASuspicionLevel := 'Normal order pattern';
    Result := True;
  end;
end;

end.
