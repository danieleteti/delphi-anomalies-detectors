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
  /// Base class for all anomaly detection algorithms
  /// </summary>
  TBaseAnomalyDetector = class
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
  public
    constructor Create(const AName: string); overload;
    constructor Create(const AName: string; const AConfig: TAnomalyDetectionConfig); overload;
    destructor Destroy; override;
    function Detect(const AValue: Double): TAnomalyResult; virtual; abstract;
    function IsAnomaly(const AValue: Double): Boolean; virtual;
    function GetAnomalyInfo(const AValue: Double): string; virtual;
    procedure SaveState(const AStream: TStream); virtual; abstract;
    procedure LoadState(const AStream: TStream); virtual; abstract;
    procedure SaveToFile(const AFileName: string);
    procedure LoadFromFile(const AFileName: string);
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

end.
