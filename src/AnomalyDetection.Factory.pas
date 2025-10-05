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
  AnomalyDetection.IsolationForest;

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
    class function CreateThreeSigma: TThreeSigmaDetector; overload;

    /// <summary>
    /// Create Three Sigma detector with custom config
    /// </summary>
    class function CreateThreeSigma(const AConfig: TAnomalyDetectionConfig): TThreeSigmaDetector; overload;

    /// <summary>
    /// Create Sliding Window detector
    /// </summary>
    class function CreateSlidingWindow(AWindowSize: Integer = 100): TSlidingWindowDetector; overload;

    /// <summary>
    /// Create Sliding Window detector with custom config
    /// </summary>
    class function CreateSlidingWindow(AWindowSize: Integer; const AConfig: TAnomalyDetectionConfig): TSlidingWindowDetector; overload;

    /// <summary>
    /// Create EMA detector
    /// </summary>
    class function CreateEMA(AAlpha: Double = 0.1): TEMAAnomalyDetector; overload;

    /// <summary>
    /// Create EMA detector with custom config
    /// </summary>
    class function CreateEMA(AAlpha: Double; const AConfig: TAnomalyDetectionConfig): TEMAAnomalyDetector; overload;

    /// <summary>
    /// Create Adaptive detector
    /// </summary>
    class function CreateAdaptive(AWindowSize: Integer = 1000; AAdaptationRate: Double = 0.01): TAdaptiveAnomalyDetector; overload;

    /// <summary>
    /// Create Adaptive detector with custom config
    /// </summary>
    class function CreateAdaptive(AWindowSize: Integer; AAdaptationRate: Double; const AConfig: TAnomalyDetectionConfig): TAdaptiveAnomalyDetector; overload;

    /// <summary>
    /// Create Isolation Forest detector
    /// </summary>
    class function CreateIsolationForest(ANumTrees: Integer = 100; ASubSampleSize: Integer = 256; AMaxDepth: Integer = 10): TIsolationForestDetector; overload;

    /// <summary>
    /// Create Isolation Forest detector with custom config
    /// </summary>
    class function CreateIsolationForest(ANumTrees: Integer; ASubSampleSize: Integer; AMaxDepth: Integer; const AConfig: TAnomalyDetectionConfig): TIsolationForestDetector; overload;

    // ========================================================================
    // PRE-CONFIGURED DETECTORS - For common use cases
    // ========================================================================

    /// <summary>
    /// Create detector optimized for web traffic monitoring
    /// Uses Sliding Window with sensitive thresholds
    /// </summary>
    class function CreateForWebTrafficMonitoring: TBaseAnomalyDetector;

    /// <summary>
    /// Create detector optimized for financial data
    /// Uses EMA with standard financial thresholds
    /// </summary>
    class function CreateForFinancialData: TBaseAnomalyDetector;

    /// <summary>
    /// Create detector optimized for IoT sensors
    /// Uses Adaptive detector for evolving patterns
    /// </summary>
    class function CreateForIoTSensors: TBaseAnomalyDetector;

    /// <summary>
    /// Create detector for high-dimensional data
    /// Uses Isolation Forest for multi-dimensional patterns
    /// </summary>
    class function CreateForHighDimensionalData: TBaseAnomalyDetector;

    /// <summary>
    /// Create detector for batch historical analysis
    /// Uses Three Sigma for one-time analysis
    /// </summary>
    class function CreateForHistoricalAnalysis: TBaseAnomalyDetector;

    /// <summary>
    /// Create detector for real-time streaming
    /// Uses EMA for immediate response
    /// </summary>
    class function CreateForRealTimeStreaming(AAlpha: Double = 0.1): TBaseAnomalyDetector;
  end;

implementation

{ TAnomalyDetectorFactory }

// ============================================================================
// CREATE BY NAME - IMPLEMENTATIONS
// ============================================================================

class function TAnomalyDetectorFactory.CreateThreeSigma: TThreeSigmaDetector;
begin
  Result := TThreeSigmaDetector.Create;
end;

class function TAnomalyDetectorFactory.CreateThreeSigma(const AConfig: TAnomalyDetectionConfig): TThreeSigmaDetector;
begin
  Result := TThreeSigmaDetector.Create(AConfig);
end;

class function TAnomalyDetectorFactory.CreateSlidingWindow(AWindowSize: Integer): TSlidingWindowDetector;
begin
  Result := TSlidingWindowDetector.Create(AWindowSize);
end;

class function TAnomalyDetectorFactory.CreateSlidingWindow(AWindowSize: Integer; const AConfig: TAnomalyDetectionConfig): TSlidingWindowDetector;
begin
  Result := TSlidingWindowDetector.Create(AWindowSize, AConfig);
end;

class function TAnomalyDetectorFactory.CreateEMA(AAlpha: Double): TEMAAnomalyDetector;
begin
  Result := TEMAAnomalyDetector.Create(AAlpha);
end;

class function TAnomalyDetectorFactory.CreateEMA(AAlpha: Double; const AConfig: TAnomalyDetectionConfig): TEMAAnomalyDetector;
begin
  Result := TEMAAnomalyDetector.Create(AAlpha, AConfig);
end;

class function TAnomalyDetectorFactory.CreateAdaptive(AWindowSize: Integer; AAdaptationRate: Double): TAdaptiveAnomalyDetector;
begin
  Result := TAdaptiveAnomalyDetector.Create(AWindowSize, AAdaptationRate);
end;

class function TAnomalyDetectorFactory.CreateAdaptive(AWindowSize: Integer; AAdaptationRate: Double; const AConfig: TAnomalyDetectionConfig): TAdaptiveAnomalyDetector;
begin
  Result := TAdaptiveAnomalyDetector.Create(AWindowSize, AAdaptationRate, AConfig);
end;

class function TAnomalyDetectorFactory.CreateIsolationForest(ANumTrees: Integer; ASubSampleSize: Integer; AMaxDepth: Integer): TIsolationForestDetector;
begin
  Result := TIsolationForestDetector.Create(ANumTrees, ASubSampleSize, AMaxDepth);
end;

class function TAnomalyDetectorFactory.CreateIsolationForest(ANumTrees: Integer; ASubSampleSize: Integer; AMaxDepth: Integer; const AConfig: TAnomalyDetectionConfig): TIsolationForestDetector;
begin
  Result := TIsolationForestDetector.Create(ANumTrees, ASubSampleSize, AMaxDepth, AConfig);
end;

// ============================================================================
// PRE-CONFIGURED DETECTORS - IMPLEMENTATIONS
// ============================================================================

class function TAnomalyDetectorFactory.CreateForWebTrafficMonitoring: TBaseAnomalyDetector;
var
  Config: TAnomalyDetectionConfig;
begin
  Config := TAnomalyDetectionConfig.Default;
  Config.SigmaMultiplier := 2.5; // More sensitive for security
  Result := CreateSlidingWindow(100, Config);
end;

class function TAnomalyDetectorFactory.CreateForFinancialData: TBaseAnomalyDetector;
var
  Config: TAnomalyDetectionConfig;
begin
  Config := TAnomalyDetectionConfig.Default;
  Config.SigmaMultiplier := 3.0; // Standard for financial data
  Config.MinStdDev := 0.01; // Higher precision
  Result := CreateEMA(0.1, Config);
end;

class function TAnomalyDetectorFactory.CreateForIoTSensors: TBaseAnomalyDetector;
var
  Config: TAnomalyDetectionConfig;
begin
  Config := TAnomalyDetectionConfig.Default;
  Config.SigmaMultiplier := 2.0; // Sensitive to sensor failures
  Result := CreateAdaptive(1000, 0.01, Config);
end;

class function TAnomalyDetectorFactory.CreateForHighDimensionalData: TBaseAnomalyDetector;
var
  Config: TAnomalyDetectionConfig;
begin
  Config := TAnomalyDetectionConfig.Default;
  Config.SigmaMultiplier := 2.5;
  Result := CreateIsolationForest(100, 256, 10, Config);
end;

class function TAnomalyDetectorFactory.CreateForHistoricalAnalysis: TBaseAnomalyDetector;
var
  Config: TAnomalyDetectionConfig;
begin
  Config := TAnomalyDetectionConfig.Default;
  Config.SigmaMultiplier := 3.0; // Standard statistical threshold
  Result := CreateThreeSigma(Config);
end;

class function TAnomalyDetectorFactory.CreateForRealTimeStreaming(AAlpha: Double): TBaseAnomalyDetector;
var
  Config: TAnomalyDetectionConfig;
begin
  Config := TAnomalyDetectionConfig.Default;
  Config.SigmaMultiplier := 2.5; // Balanced sensitivity
  Result := CreateEMA(AAlpha, Config);
end;

end.
