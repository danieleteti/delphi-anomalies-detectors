// ***************************************************************************
//
// Copyright (c) 2025 Daniele Teti - All Rights Reserved
//
// Base Anomaly Detector Class
// Abstract base class for all detector implementations
//
// ***************************************************************************

unit AnomalyDetection.Base;

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs,
  AnomalyDetection.Types,
  AnomalyDetection.Performance;

type
  /// <summary>
  /// Base interface for all anomaly detectors
  /// </summary>
  IAnomalyDetector = interface
    ['{D7F8E9A1-4B2C-4D3E-8F9A-1B2C3D4E5F6A}']
    // Training phase
    procedure AddValue(const AValue: Double);
    procedure AddValues(const AValues: TArray<Double>);
    procedure Build;

    // Detection phase
    function Detect(const AValue: Double): TAnomalyResult;
    function IsAnomaly(const AValue: Double): Boolean;
    function GetAnomalyInfo(const AValue: Double): string;

    // Persistence
    procedure SaveState(const AStream: TStream);
    procedure LoadState(const AStream: TStream);
    procedure SaveToFile(const AFileName: string);
    procedure LoadFromFile(const AFileName: string);

    // Utilities
    function GetPerformanceReport: string;
    function IsInitialized: Boolean;

    // Properties
    function GetName: string;
    function GetConfig: TAnomalyDetectionConfig;
    procedure SetConfig(const AConfig: TAnomalyDetectionConfig);
    function GetOnAnomalyDetected: TAnomalyDetectedEvent;
    procedure SetOnAnomalyDetected(const AEvent: TAnomalyDetectedEvent);
    function GetPerformanceMonitor: TDetectorPerformanceMonitor;

    property Name: string read GetName;
    property Config: TAnomalyDetectionConfig read GetConfig write SetConfig;
    property OnAnomalyDetected: TAnomalyDetectedEvent read GetOnAnomalyDetected write SetOnAnomalyDetected;
    property PerformanceMonitor: TDetectorPerformanceMonitor read GetPerformanceMonitor;
  end;

  /// <summary>
  /// Interface for statistical anomaly detectors
  /// Extends base interface with statistical properties
  /// </summary>
  IStatisticalAnomalyDetector = interface(IAnomalyDetector)
    ['{0B3CAE45-6428-4E31-9A22-611C8D269A16}']
    function GetMean: Double;
    function GetStdDev: Double;
    function GetLowerLimit: Double;
    function GetUpperLimit: Double;

    property Mean: Double read GetMean;
    property StdDev: Double read GetStdDev;
    property LowerLimit: Double read GetLowerLimit;
    property UpperLimit: Double read GetUpperLimit;
  end;

  /// <summary>
  /// Interface for density-based anomaly detectors
  /// Extends base interface with multi-dimensional support
  /// </summary>
  IDensityAnomalyDetector = interface(IAnomalyDetector)
    ['{E63A0189-D7B3-4DC3-BFE2-C80815F30762}']
    procedure AddTrainingData(const AInstance: TArray<Double>);
    procedure Train;
    function DetectMultiDimensional(const AInstance: TArray<Double>): TAnomalyResult;

    function GetDimensions: Integer;
    property Dimensions: Integer read GetDimensions;
  end;

  /// <summary>
  /// Base class for all anomaly detection algorithms
  /// </summary>
  TBaseAnomalyDetector = class(TInterfacedObject, IAnomalyDetector)
  protected
    FName: string;
    FConfig: TAnomalyDetectionConfig;
    FLock: TCriticalSection;
    FOnAnomalyDetected: TAnomalyDetectedEvent;
    FLastAnomalyState: Boolean;
    FPerformanceMonitor: TDetectorPerformanceMonitor;
    procedure SaveConfigToStream(const AStream: TStream);
    procedure LoadConfigFromStream(const AStream: TStream);
    procedure NotifyAnomalyEvent(const AEventType: TAnomalyEvent; const AResult: TAnomalyResult);

    // Interface implementation
    function GetName: string;
    function GetConfig: TAnomalyDetectionConfig;
    procedure SetConfig(const AConfig: TAnomalyDetectionConfig);
    function GetOnAnomalyDetected: TAnomalyDetectedEvent;
    procedure SetOnAnomalyDetected(const AEvent: TAnomalyDetectedEvent);
    function GetPerformanceMonitor: TDetectorPerformanceMonitor;
  public
    constructor Create(const AName: string); overload;
    constructor Create(const AName: string; const AConfig: TAnomalyDetectionConfig); overload;
    destructor Destroy; override;

    // Training phase - unified interface for all detectors
    procedure AddValue(const AValue: Double); virtual;
    procedure AddValues(const AValues: TArray<Double>); virtual;

    // Build/finalize phase - prepare detector for use
    procedure Build; virtual;

    // Detection phase
    function Detect(const AValue: Double): TAnomalyResult; virtual; abstract;
    function IsAnomaly(const AValue: Double): Boolean; virtual;
    function GetAnomalyInfo(const AValue: Double): string; virtual;

    // Persistence
    procedure SaveState(const AStream: TStream); virtual; abstract;
    procedure LoadState(const AStream: TStream); virtual; abstract;
    procedure SaveToFile(const AFileName: string);
    procedure LoadFromFile(const AFileName: string);

    // Utilities
    function GetPerformanceReport: string;
    function IsInitialized: Boolean; virtual; abstract;

    property Name: string read FName;
    property Config: TAnomalyDetectionConfig read FConfig write FConfig;
    property OnAnomalyDetected: TAnomalyDetectedEvent read FOnAnomalyDetected write FOnAnomalyDetected;
    property PerformanceMonitor: TDetectorPerformanceMonitor read FPerformanceMonitor;
  end;

implementation

{ TBaseAnomalyDetector }

constructor TBaseAnomalyDetector.Create(const AName: string);
begin
  Create(AName, TAnomalyDetectionConfig.Default);
end;

constructor TBaseAnomalyDetector.Create(const AName: string; const AConfig: TAnomalyDetectionConfig);
begin
  inherited Create;
  FName := AName;
  FConfig := AConfig;
  FLock := TCriticalSection.Create;
  FLastAnomalyState := False;
  FPerformanceMonitor := TDetectorPerformanceMonitor.Create;
end;

destructor TBaseAnomalyDetector.Destroy;
begin
  FPerformanceMonitor.Free;
  FLock.Free;
  inherited;
end;

procedure TBaseAnomalyDetector.NotifyAnomalyEvent(const AEventType: TAnomalyEvent; const AResult: TAnomalyResult);
var
  EventArgs: TAnomalyEventArgs;
begin
  if Assigned(FOnAnomalyDetected) then
  begin
    EventArgs.EventType := AEventType;
    EventArgs.Timestamp := Now;
    EventArgs.Result := AResult;
    EventArgs.DetectorName := FName;

    case AEventType of
      aeAnomalyDetected: EventArgs.AdditionalInfo := 'Anomaly detected: ' + AResult.Description;
      aeNormalResumed: EventArgs.AdditionalInfo := 'Normal state resumed';
      aeThresholdExceeded: EventArgs.AdditionalInfo := Format('Threshold exceeded: Z-score %.2f', [AResult.ZScore]);
    end;

    FOnAnomalyDetected(Self, EventArgs);
  end;
end;

function TBaseAnomalyDetector.IsAnomaly(const AValue: Double): Boolean;
begin
  Result := Detect(AValue).IsAnomaly;
end;

function TBaseAnomalyDetector.GetAnomalyInfo(const AValue: Double): string;
begin
  Result := Detect(AValue).Description;
end;

function TBaseAnomalyDetector.GetPerformanceReport: string;
begin
  Result := FPerformanceMonitor.GetReport;
end;

procedure TBaseAnomalyDetector.SaveConfigToStream(const AStream: TStream);
begin
  AStream.WriteData(FConfig.SigmaMultiplier);
  AStream.WriteData(FConfig.MinStdDev);
end;

procedure TBaseAnomalyDetector.LoadConfigFromStream(const AStream: TStream);
begin
  AStream.ReadData(FConfig.SigmaMultiplier);
  AStream.ReadData(FConfig.MinStdDev);
end;

procedure TBaseAnomalyDetector.SaveToFile(const AFileName: string);
var
  FileStream: TFileStream;
begin
  FileStream := TFileStream.Create(AFileName, fmCreate);
  try
    SaveState(FileStream);
  finally
    FileStream.Free;
  end;
end;

procedure TBaseAnomalyDetector.LoadFromFile(const AFileName: string);
var
  FileStream: TFileStream;
begin
  FileStream := TFileStream.Create(AFileName, fmOpenRead);
  try
    LoadState(FileStream);
  finally
    FileStream.Free;
  end;
end;

procedure TBaseAnomalyDetector.AddValue(const AValue: Double);
begin
  // Default implementation: do nothing
  // Detectors that support incremental training should override this
end;

procedure TBaseAnomalyDetector.AddValues(const AValues: TArray<Double>);
var
  Value: Double;
begin
  // Default implementation: call AddValue for each value
  for Value in AValues do
    AddValue(Value);
end;

procedure TBaseAnomalyDetector.Build;
begin
  // Default implementation: do nothing
  // Detectors that require explicit build step should override this
end;

// Interface implementation methods

function TBaseAnomalyDetector.GetName: string;
begin
  Result := FName;
end;

function TBaseAnomalyDetector.GetConfig: TAnomalyDetectionConfig;
begin
  Result := FConfig;
end;

procedure TBaseAnomalyDetector.SetConfig(const AConfig: TAnomalyDetectionConfig);
begin
  FConfig := AConfig;
end;

function TBaseAnomalyDetector.GetOnAnomalyDetected: TAnomalyDetectedEvent;
begin
  Result := FOnAnomalyDetected;
end;

procedure TBaseAnomalyDetector.SetOnAnomalyDetected(const AEvent: TAnomalyDetectedEvent);
begin
  FOnAnomalyDetected := AEvent;
end;

function TBaseAnomalyDetector.GetPerformanceMonitor: TDetectorPerformanceMonitor;
begin
  Result := FPerformanceMonitor;
end;

end.
