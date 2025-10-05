// ***************************************************************************
//
// Copyright (c) 2025 Daniele Teti - All Rights Reserved
//
// Anomaly Confirmation System
// Reduces false positives by requiring multiple similar detections
//
// ***************************************************************************

unit AnomalyDetection.Confirmation;

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs, System.Generics.Collections, System.Math,
  AnomalyDetection.Types;

type
  /// <summary>
  /// Confirmation system to reduce false positives
  /// </summary>
  TAnomalyConfirmationSystem = class
  private
    FRecentAnomalies: TList<Double>;
    FConfirmationThreshold: Integer;
    FWindowSize: Integer;
    FTolerance: Double;
    FLock: TCriticalSection;
  public
    constructor Create(AWindowSize: Integer = 10; AConfirmationThreshold: Integer = 3; ATolerance: Double = 0.1);
    destructor Destroy; override;
    function IsConfirmedAnomaly(const AValue: Double): Boolean;
    procedure AddPotentialAnomaly(const AValue: Double);
    procedure SaveState(const AStream: TStream);
    procedure LoadState(const AStream: TStream);
    procedure SaveToFile(const AFileName: string);
    procedure LoadFromFile(const AFileName: string);
    property ConfirmationThreshold: Integer read FConfirmationThreshold;
    property WindowSize: Integer read FWindowSize;
    property Tolerance: Double read FTolerance write FTolerance;
  end;

implementation

{ TAnomalyConfirmationSystem }

constructor TAnomalyConfirmationSystem.Create(AWindowSize: Integer; AConfirmationThreshold: Integer; ATolerance: Double);
begin
  inherited Create;
  FWindowSize := AWindowSize;
  FConfirmationThreshold := AConfirmationThreshold;
  FTolerance := ATolerance;
  FRecentAnomalies := TList<Double>.Create;
  FLock := TCriticalSection.Create;
end;

destructor TAnomalyConfirmationSystem.Destroy;
begin
  FLock.Free;
  FRecentAnomalies.Free;
  inherited Destroy;
end;

procedure TAnomalyConfirmationSystem.AddPotentialAnomaly(const AValue: Double);
begin
  FLock.Enter;
  try
    FRecentAnomalies.Add(AValue);

    // Keep only recent anomalies
    while FRecentAnomalies.Count > FWindowSize do
      FRecentAnomalies.Delete(0);
  finally
    FLock.Leave;
  end;
end;

function TAnomalyConfirmationSystem.IsConfirmedAnomaly(const AValue: Double): Boolean;
var
  AnomalyCount: Integer;
  i: Integer;
  ToleranceValue: Double;
begin
  FLock.Enter;
  try
    AnomalyCount := 0;
    ToleranceValue := Max(Abs(AValue), 1) * FTolerance;

    // Count how many similar anomalies occurred recently
    for i := 0 to FRecentAnomalies.Count - 1 do
    begin
      if Abs(FRecentAnomalies[i] - AValue) < ToleranceValue then
        Inc(AnomalyCount);
    end;

    Result := AnomalyCount >= FConfirmationThreshold;
  finally
    FLock.Leave;
  end;
end;

procedure TAnomalyConfirmationSystem.SaveState(const AStream: TStream);
var
  Count, i: Integer;
begin
  FLock.Enter;
  try
    // Save parameters
    AStream.WriteData(FWindowSize);
    AStream.WriteData(FConfirmationThreshold);
    AStream.WriteData(FTolerance);

    // Save recent anomalies
    Count := FRecentAnomalies.Count;
    AStream.WriteData(Count);
    for i := 0 to Count - 1 do
      AStream.WriteData(FRecentAnomalies[i]);
  finally
    FLock.Leave;
  end;
end;

procedure TAnomalyConfirmationSystem.LoadState(const AStream: TStream);
var
  Count, i: Integer;
  Value: Double;
begin
  FLock.Enter;
  try
    // Load parameters
    AStream.ReadData(FWindowSize);
    AStream.ReadData(FConfirmationThreshold);
    AStream.ReadData(FTolerance);

    // Load recent anomalies
    FRecentAnomalies.Clear;
    AStream.ReadData(Count);
    for i := 0 to Count - 1 do
    begin
      AStream.ReadData(Value);
      FRecentAnomalies.Add(Value);
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TAnomalyConfirmationSystem.SaveToFile(const AFileName: string);
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

procedure TAnomalyConfirmationSystem.LoadFromFile(const AFileName: string);
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
