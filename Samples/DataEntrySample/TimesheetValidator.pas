// ***************************************************************************
//
// Timesheet Validator Unit
// Validates employee working hours with adaptive learning
// Implements feedback loop for continuous improvement
//
// ***************************************************************************

unit TimesheetValidator;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  AnomalyDetection.Types,
  AnomalyDetection.Adaptive;

type
  /// <summary>
  /// Validation result levels
  /// </summary>
  TValidationLevel = (
    vlNormal,   // Accepted automatically
    vlWarning,  // Requires confirmation
    vlError     // Blocked, must be corrected
  );

  /// <summary>
  /// Timesheet hours validator with per-employee adaptive learning
  /// Uses Adaptive Detector that learns from user confirmations
  /// </summary>
  TTimesheetValidator = class
  private
    FDetectorsByEmployee: TDictionary<Integer, TAdaptiveAnomalyDetector>;
    FMaxPhysicalHours: Double;

    procedure InitializeEmployeeDetector(AEmployeeID: Integer);
  public
    constructor Create(AMaxPhysicalHours: Double = 16.0);
    destructor Destroy; override;

    /// <summary>
    /// Validates working hours for an employee
    /// </summary>
    /// <param name="AEmployeeID">Employee ID</param>
    /// <param name="AHours">Hours to validate</param>
    /// <param name="AMessage">Validation message</param>
    /// <returns>Validation level (Normal/Warning/Error)</returns>
    function ValidateHours(AEmployeeID: Integer; AHours: Double;
                          out AMessage: string): TValidationLevel;

    /// <summary>
    /// Confirms hours are correct - teaches the detector
    /// Call this when user confirms unusual hours are valid
    /// </summary>
    procedure ConfirmNormalHours(AEmployeeID: Integer; AHours: Double);

    /// <summary>
    /// Gets the number of employees being tracked
    /// </summary>
    function GetEmployeeCount: Integer;

    /// <summary>
    /// Maximum physical hours allowed (default: 16)
    /// </summary>
    property MaxPhysicalHours: Double read FMaxPhysicalHours write FMaxPhysicalHours;
  end;

implementation

{ TTimesheetValidator }

constructor TTimesheetValidator.Create(AMaxPhysicalHours: Double);
begin
  inherited Create;
  FDetectorsByEmployee := TDictionary<Integer, TAdaptiveAnomalyDetector>.Create;
  FMaxPhysicalHours := AMaxPhysicalHours;
end;

destructor TTimesheetValidator.Destroy;
var
  Detector: TAdaptiveAnomalyDetector;
begin
  for Detector in FDetectorsByEmployee.Values do
    Detector.Free;
  FDetectorsByEmployee.Free;
  inherited;
end;

procedure TTimesheetValidator.InitializeEmployeeDetector(AEmployeeID: Integer);
var
  Detector: TAdaptiveAnomalyDetector;
  HistoricalData: TArray<Double>;
  i: Integer;
begin
  Detector := TAdaptiveAnomalyDetector.Create(30, 0.05); // 30-day window, slow adaptation

  // Initialize with typical 8-hour workdays
  SetLength(HistoricalData, 20);
  for i := 0 to High(HistoricalData) do
    HistoricalData[i] := 7.5 + Random * 1.5; // 7.5-9 hours
  Detector.InitializeWithNormalData(HistoricalData);

  FDetectorsByEmployee.Add(AEmployeeID, Detector);
end;

function TTimesheetValidator.ValidateHours(AEmployeeID: Integer;
                                           AHours: Double;
                                           out AMessage: string): TValidationLevel;
var
  Detector: TAdaptiveAnomalyDetector;
  AnomalyResult: TAnomalyResult;
begin
  // Get or create detector for this employee
  if not FDetectorsByEmployee.TryGetValue(AEmployeeID, Detector) then
    InitializeEmployeeDetector(AEmployeeID);

  FDetectorsByEmployee.TryGetValue(AEmployeeID, Detector);

  AnomalyResult := Detector.Detect(AHours);

  if AnomalyResult.IsAnomaly then
  begin
    if AHours > AnomalyResult.UpperLimit then
    begin
      // Overtime or data entry error
      if AHours > FMaxPhysicalHours then
      begin
        AMessage := Format('ERROR: %.1f hours exceeds physical limit. ' +
                          'Expected max: %.1f hours',
                          [AHours, AnomalyResult.UpperLimit]);
        Result := vlError; // Block entry
      end
      else
      begin
        AMessage := Format('WARNING: %.1f hours is unusually high. ' +
                          'Typical range: %.1f - %.1f hours',
                          [AHours, AnomalyResult.LowerLimit, AnomalyResult.UpperLimit]);
        Result := vlWarning; // Require confirmation
      end;
    end
    else
    begin
      // Unusually low hours
      AMessage := Format('WARNING: %.1f hours is unusually low. ' +
                        'Typical minimum: %.1f hours',
                        [AHours, AnomalyResult.LowerLimit]);
      Result := vlWarning;
    end;
  end
  else
  begin
    AMessage := 'Normal working hours';
    Result := vlNormal;
  end;
end;

procedure TTimesheetValidator.ConfirmNormalHours(AEmployeeID: Integer; AHours: Double);
var
  Detector: TAdaptiveAnomalyDetector;
begin
  // User confirmed hours are correct - teach the detector
  if FDetectorsByEmployee.TryGetValue(AEmployeeID, Detector) then
    Detector.UpdateNormal(AHours); // Adapt to new normal pattern
end;

function TTimesheetValidator.GetEmployeeCount: Integer;
begin
  Result := FDetectorsByEmployee.Count;
end;

end.
