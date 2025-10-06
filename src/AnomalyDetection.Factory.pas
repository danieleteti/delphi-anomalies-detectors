// ***************************************************************************
//
// Copyright (c) 2025 Daniele Teti - All Rights Reserved
//
// Anomaly Detection Factory
// Factory pattern for creating detector instances
//
// ***************************************************************************

unit AnomalyDetection.Factory;

interface

uses
  System.SysUtils,
  AnomalyDetection.Types,
  AnomalyDetection.Base,
  AnomalyDetection.ThreeSigma,
  AnomalyDetection.SlidingWindow,
  AnomalyDetection.EMA,
  AnomalyDetection.Adaptive,
  AnomalyDetection.IsolationForest,
  AnomalyDetection.DBSCAN,
  AnomalyDetection.LOF;

type
  /// <summary>
  /// Factory for creating anomaly detectors with typed methods
  /// </summary>
  TAnomalyDetectorFactory = class
  public
    // ========================================================================
    // CREATE BY NAME - Typed methods for each detector
    // ========================================================================

    /// <summary>
    /// Create Three Sigma detector with default config
    /// </summary>
    class function CreateThreeSigma: IStatisticalAnomalyDetector; overload;

    /// <summary>
    /// Create Three Sigma detector with custom config
    /// </summary>
    class function CreateThreeSigma(const AConfig: TAnomalyDetectionConfig): IStatisticalAnomalyDetector; overload;

    /// <summary>
    /// Create Sliding Window detector
    /// </summary>
    class function CreateSlidingWindow(AWindowSize: Integer = 100): IStatisticalAnomalyDetector; overload;

    /// <summary>
    /// Create Sliding Window detector with custom config
    /// </summary>
    class function CreateSlidingWindow(AWindowSize: Integer; const AConfig: TAnomalyDetectionConfig): IStatisticalAnomalyDetector; overload;

    /// <summary>
    /// Create EMA detector
    /// </summary>
    class function CreateEMA(AAlpha: Double = 0.1): IStatisticalAnomalyDetector; overload;

    /// <summary>
    /// Create EMA detector with custom config
    /// </summary>
    class function CreateEMA(AAlpha: Double; const AConfig: TAnomalyDetectionConfig): IStatisticalAnomalyDetector; overload;

    /// <summary>
    /// Create Adaptive detector
    /// </summary>
    class function CreateAdaptive(AWindowSize: Integer = 1000; AAdaptationRate: Double = 0.01): IStatisticalAnomalyDetector; overload;

    /// <summary>
    /// Create Adaptive detector with custom config
    /// </summary>
    class function CreateAdaptive(AWindowSize: Integer; AAdaptationRate: Double; const AConfig: TAnomalyDetectionConfig): IStatisticalAnomalyDetector; overload;

    /// <summary>
    /// Create Isolation Forest detector
    /// </summary>
    class function CreateIsolationForest(ANumTrees: Integer = 100; ASubSampleSize: Integer = 256; AMaxDepth: Integer = 10): IDensityAnomalyDetector; overload;

    /// <summary>
    /// Create Isolation Forest detector with custom config
    /// </summary>
    class function CreateIsolationForest(ANumTrees: Integer; ASubSampleSize: Integer; AMaxDepth: Integer; const AConfig: TAnomalyDetectionConfig): IDensityAnomalyDetector; overload;

    /// <summary>
    /// Create DBSCAN detector (Density-Based Spatial Clustering)
    /// </summary>
    class function CreateDBSCAN(AEpsilon: Double = 0.5; AMinPoints: Integer = 5; ADimensions: Integer = 1): IDensityAnomalyDetector; overload;

    /// <summary>
    /// Create DBSCAN detector with custom config
    /// </summary>
    class function CreateDBSCAN(AEpsilon: Double; AMinPoints: Integer; ADimensions: Integer; const AConfig: TAnomalyDetectionConfig): IDensityAnomalyDetector; overload;

    /// <summary>
    /// Create LOF (Local Outlier Factor) detector
    /// </summary>
    class function CreateLOF(AKNeighbors: Integer = 20; ADimensions: Integer = 1): IDensityAnomalyDetector; overload;

    /// <summary>
    /// Create LOF detector with custom config
    /// </summary>
    class function CreateLOF(AKNeighbors: Integer; ADimensions: Integer; const AConfig: TAnomalyDetectionConfig): IDensityAnomalyDetector; overload;

    // ========================================================================
    // PRE-CONFIGURED DETECTORS - For common use cases
    // ========================================================================

    /// <summary>
    /// Create detector optimized for web traffic monitoring
    /// Uses Sliding Window with sensitive thresholds
    /// </summary>
    class function CreateForWebTrafficMonitoring: IStatisticalAnomalyDetector;

    /// <summary>
    /// Create detector optimized for financial data
    /// Uses EMA with standard financial thresholds
    /// </summary>
    class function CreateForFinancialData: IStatisticalAnomalyDetector;

    /// <summary>
    /// Create detector optimized for IoT sensors
    /// Uses Adaptive detector for evolving patterns
    /// </summary>
    class function CreateForIoTSensors: IStatisticalAnomalyDetector;

    /// <summary>
    /// Create detector for high-dimensional data
    /// Uses Isolation Forest for multi-dimensional patterns
    /// </summary>
    class function CreateForHighDimensionalData: IDensityAnomalyDetector;

    /// <summary>
    /// Create detector for batch historical analysis
    /// Uses Three Sigma for one-time analysis
    /// </summary>
    class function CreateForHistoricalAnalysis: IStatisticalAnomalyDetector;

    /// <summary>
    /// Create detector for real-time streaming
    /// Uses EMA for immediate response
    /// </summary>
    class function CreateForRealTimeStreaming(AAlpha: Double = 0.1): IStatisticalAnomalyDetector;

    /// <summary>
    /// Create detector for spatial/geographical anomalies
    /// Uses DBSCAN for density-based detection
    /// </summary>
    class function CreateForSpatialData(ADimensions: Integer = 2): IDensityAnomalyDetector;
  end;

implementation

{ TAnomalyDetectorFactory }

// ============================================================================
// CREATE BY NAME - IMPLEMENTATIONS
// ============================================================================

class function TAnomalyDetectorFactory.CreateThreeSigma: IStatisticalAnomalyDetector;
begin
  Result := TThreeSigmaDetector.Create;
end;

class function TAnomalyDetectorFactory.CreateThreeSigma(const AConfig: TAnomalyDetectionConfig): IStatisticalAnomalyDetector;
begin
  Result := TThreeSigmaDetector.Create(AConfig);
end;

class function TAnomalyDetectorFactory.CreateSlidingWindow(AWindowSize: Integer): IStatisticalAnomalyDetector;
begin
  Result := TSlidingWindowDetector.Create(AWindowSize);
end;

class function TAnomalyDetectorFactory.CreateSlidingWindow(AWindowSize: Integer; const AConfig: TAnomalyDetectionConfig): IStatisticalAnomalyDetector;
begin
  Result := TSlidingWindowDetector.Create(AWindowSize, AConfig);
end;

class function TAnomalyDetectorFactory.CreateEMA(AAlpha: Double): IStatisticalAnomalyDetector;
begin
  Result := TEMAAnomalyDetector.Create(AAlpha);
end;

class function TAnomalyDetectorFactory.CreateEMA(AAlpha: Double; const AConfig: TAnomalyDetectionConfig): IStatisticalAnomalyDetector;
begin
  Result := TEMAAnomalyDetector.Create(AAlpha, AConfig);
end;

class function TAnomalyDetectorFactory.CreateAdaptive(AWindowSize: Integer; AAdaptationRate: Double): IStatisticalAnomalyDetector;
begin
  Result := TAdaptiveAnomalyDetector.Create(AWindowSize, AAdaptationRate);
end;

class function TAnomalyDetectorFactory.CreateAdaptive(AWindowSize: Integer; AAdaptationRate: Double; const AConfig: TAnomalyDetectionConfig): IStatisticalAnomalyDetector;
begin
  Result := TAdaptiveAnomalyDetector.Create(AWindowSize, AAdaptationRate, AConfig);
end;

class function TAnomalyDetectorFactory.CreateIsolationForest(ANumTrees: Integer; ASubSampleSize: Integer; AMaxDepth: Integer): IDensityAnomalyDetector;
begin
  Result := TIsolationForestDetector.Create(ANumTrees, ASubSampleSize, AMaxDepth);
end;

class function TAnomalyDetectorFactory.CreateIsolationForest(ANumTrees: Integer; ASubSampleSize: Integer; AMaxDepth: Integer; const AConfig: TAnomalyDetectionConfig): IDensityAnomalyDetector;
begin
  Result := TIsolationForestDetector.Create(ANumTrees, ASubSampleSize, AMaxDepth, AConfig);
end;

// ============================================================================
// PRE-CONFIGURED DETECTORS - IMPLEMENTATIONS
// ============================================================================

class function TAnomalyDetectorFactory.CreateForWebTrafficMonitoring: IStatisticalAnomalyDetector;
var
  Config: TAnomalyDetectionConfig;
begin
  Config := TAnomalyDetectionConfig.Default;
  Config.SigmaMultiplier := 2.5; // More sensitive for security
  Result := CreateSlidingWindow(100, Config);
end;

class function TAnomalyDetectorFactory.CreateForFinancialData: IStatisticalAnomalyDetector;
var
  Config: TAnomalyDetectionConfig;
begin
  Config := TAnomalyDetectionConfig.Default;
  Config.SigmaMultiplier := 3.0; // Standard for financial data
  Config.MinStdDev := 0.01; // Higher precision
  Result := CreateEMA(0.1, Config);
end;

class function TAnomalyDetectorFactory.CreateForIoTSensors: IStatisticalAnomalyDetector;
var
  Config: TAnomalyDetectionConfig;
begin
  Config := TAnomalyDetectionConfig.Default;
  Config.SigmaMultiplier := 2.0; // Sensitive to sensor failures
  Result := CreateAdaptive(1000, 0.01, Config);
end;

class function TAnomalyDetectorFactory.CreateForHighDimensionalData: IDensityAnomalyDetector;
var
  Config: TAnomalyDetectionConfig;
begin
  Config := TAnomalyDetectionConfig.Default;
  Config.SigmaMultiplier := 2.5;
  Result := CreateIsolationForest(100, 256, 10, Config);
end;

class function TAnomalyDetectorFactory.CreateForHistoricalAnalysis: IStatisticalAnomalyDetector;
var
  Config: TAnomalyDetectionConfig;
begin
  Config := TAnomalyDetectionConfig.Default;
  Config.SigmaMultiplier := 3.0; // Standard statistical threshold
  Result := CreateThreeSigma(Config);
end;

class function TAnomalyDetectorFactory.CreateForRealTimeStreaming(AAlpha: Double): IStatisticalAnomalyDetector;
var
  lConfig: TAnomalyDetectionConfig;
begin
  lConfig := TAnomalyDetectionConfig.Default;
  lConfig.SigmaMultiplier := 2.5; // Balanced sensitivity
  Result := CreateEMA(AAlpha, lConfig);
end;

class function TAnomalyDetectorFactory.CreateDBSCAN(AEpsilon: Double; AMinPoints: Integer; ADimensions: Integer): IDensityAnomalyDetector;
begin
  Result := TDBSCANDetector.Create(AEpsilon, AMinPoints, ADimensions);
end;

class function TAnomalyDetectorFactory.CreateDBSCAN(AEpsilon: Double; AMinPoints: Integer; ADimensions: Integer; const AConfig: TAnomalyDetectionConfig): IDensityAnomalyDetector;
var
  Detector: TDBSCANDetector;
begin
  Detector := TDBSCANDetector.Create(AEpsilon, AMinPoints, ADimensions);
  Detector.Config := AConfig;
  Result := Detector;
end;

class function TAnomalyDetectorFactory.CreateLOF(AKNeighbors: Integer = 20; ADimensions: Integer = 1): IDensityAnomalyDetector;
begin
  Result := TLOFDetector.Create(AKNeighbors, ADimensions);
end;

class function TAnomalyDetectorFactory.CreateLOF(AKNeighbors: Integer; ADimensions: Integer; const AConfig: TAnomalyDetectionConfig): IDensityAnomalyDetector;
begin
  Result := TLOFDetector.Create(AKNeighbors, ADimensions, AConfig);
end;

class function TAnomalyDetectorFactory.CreateForSpatialData(ADimensions: Integer): IDensityAnomalyDetector;
var
  lConfig: TAnomalyDetectionConfig;
begin
  lConfig := TAnomalyDetectionConfig.Default;
  lConfig.SigmaMultiplier := 2.0; // Sensitive to outliers
  Result := CreateDBSCAN(0.5, 10, ADimensions, lConfig);
end;

end.
