# Class Diagram - Delphi Anomaly Detection Algorithms

## Overview

Questo diagramma delle classi rappresenta l'architettura completa della libreria di algoritmi per il rilevamento di anomalie sviluppata in Delphi da **Daniele Teti**. La libreria implementa vari algoritmi statistici e di machine learning per identificare anomalie in flussi di dati in tempo reale.

## Componenti Principali

### 1. **Base Architecture**

#### `TBaseAnomalyDetector` (Abstract)
- **Ruolo**: Classe base astratta che definisce l'interfaccia comune per tutti i detector
- **Responsabilità**:
  - Gestione della configurazione (`TAnomalyDetectionConfig`)
  - Monitoraggio delle performance (`TDetectorPerformanceMonitor`)
  - Sistema di notifica eventi (`TAnomalyDetectedEvent`)
  - Persistenza dello stato (Save/Load)
  - Thread safety tramite `TCriticalSection`

#### `TDetectorPerformanceMonitor`
- **Ruolo**: Sistema di monitoraggio delle prestazioni
- **Metriche raccolte**:
  - Throughput (detections/second)
  - Tempi di elaborazione (min/max/avg)
  - Accuratezza, Precisione, Recall, F1-Score
  - Utilizzo memoria
  - Confusion matrix (TP, FP, TN, FN)

### 2. **Concrete Detector Implementations**

#### `TThreeSigmaDetector`
- **Algoritmo**: Regola tradizionale 3-sigma basata su dati storici
- **Uso ideale**: Dati con distribuzione normale e baseline stabile
- **Caratteristiche**:
  - Calcolo di media e deviazione standard su dati storici
  - Limiti fissi: μ ± 3σ
  - Ottimo per dati batch o con pattern prevedibili

#### `TSlidingWindowDetector`
- **Algoritmo**: Finestra scorrevole con calcolo incrementale delle statistiche
- **Uso ideale**: Flussi di dati continui con pattern che cambiano lentamente
- **Caratteristiche**:
  - Aggiornamento incrementale di media e varianza
  - Dimensione finestra configurabile
  - Bilanciamento tra reattività e stabilità

#### `TEMAAnomalyDetector`
- **Algoritmo**: Exponential Moving Average per rilevamento adattivo
- **Uso ideale**: Dati con trend che cambiano nel tempo
- **Caratteristiche**:
  - Fattore di adattamento α configurabile
  - Maggiore peso ai valori recenti
  - Ottimo per dati finanziari o metriche business

#### `TAdaptiveAnomalyDetector`
- **Algoritmo**: Detector che apprende da valori confermati come normali
- **Uso ideale**: Sistemi che cambiano comportamento nel tempo
- **Caratteristiche**:
  - Auto-adattamento basato su feedback
  - Apprendimento continuo
  - Gestione di concept drift

#### `TIsolationForestDetector`
- **Algoritmo**: Ensemble di alberi di isolamento (Machine Learning)
- **Uso ideale**: Dati multi-dimensionali, detection non supervisionato
- **Caratteristiche**:
  - Gestione di dati ad alta dimensionalità
  - Training automatico o manuale
  - Supporto per CSV training
  - Configurazioni specializzate (fraud detection, sensor data)

### 3. **Support Classes**

#### `TIsolationTree` e `TIsolationTreeNode`
- **Ruolo**: Implementazione dell'albero di isolamento per l'Isolation Forest
- **Struttura**: Albero binario con split casuali
- **Metrica**: Calcolo del path length per determinare l'anomalia

#### `TAnomalyConfirmationSystem`
- **Ruolo**: Sistema per ridurre i falsi positivi
- **Meccanismo**: Conferma anomalie solo se ricorrenti in una finestra temporale
- **Parametri**: Soglia di conferma, tolleranza, dimensione finestra

#### `TAnomalyDetectorFactory`
- **Pattern**: Factory Method per la creazione semplificata di detector
- **Configurazioni predefinite**:
  - Web Traffic Monitoring (σ=2.5, SlidingWindow)
  - Financial Data (σ=3.0, EMA)
  - IoT Sensors (σ=2.0, Adaptive)
  - High Dimensional Data (Isolation Forest)

### 4. **Data Structures**

#### Records e Configuration
- **`TAnomalyDetectionConfig`**: Configurazione globale (sigma multiplier, min std dev)
- **`TAnomalyResult`**: Risultato di una detection (anomaly flag, z-score, limits, description)
- **`TAnomalyEventArgs`**: Dati per eventi di notifica
- **`TDetectorMetrics`**: Metriche complete di performance

#### Enumerations
- **`TAnomalyEvent`**: Tipi di eventi (detected, resumed, threshold exceeded)
- **`TAnomalyDetectorType`**: Tipi di detector per il factory

## Design Patterns Utilizzati

### 1. **Template Method Pattern**
`TBaseAnomalyDetector` definisce il template per il rilevamento con metodi astratti implementati dalle classi concrete.

### 2. **Factory Pattern**
`TAnomalyDetectorFactory` fornisce metodi statici per creare detector con configurazioni ottimizzate.

### 3. **Observer Pattern**
Sistema di eventi (`TAnomalyDetectedEvent`) per notificare anomalie rilevate.

### 4. **Strategy Pattern**
Diversi algoritmi di detection intercambiabili tramite l'interfaccia comune.

## Caratteristiche Architetturali

### Thread Safety
- Utilizzo di `TCriticalSection` in tutte le classi
- Accesso thread-safe a statistiche e configurazioni
- Supporto per applicazioni multi-threaded

### Performance Monitoring
- Metriche in tempo reale per ogni detector
- Supporto per ground truth validation
- Report dettagliati di performance

### State Persistence
- Salvataggio/caricamento dello stato su stream/file
- Possibilità di ripristino dopo interruzioni
- Serializzazione completa della configurazione

### Event System
- Notifiche in tempo reale per anomalie
- Eventi tipizzati con informazioni dettagliate
- Integrazione facilitata con sistemi di alerting

## Use Cases per Detector Type

| Detector | Best For | Características |
|----------|----------|-----------------|
| **3-Sigma** | Dati storici stabili, controllo qualità | Limiti fissi, baseline stabile |
| **Sliding Window** | Monitoring continuo, metriche di sistema | Adattamento graduale, window size |
| **EMA** | Dati finanziari, trend analysis | Peso ai valori recenti, α configurabile |
| **Adaptive** | Sistemi evolutivi, IoT | Auto-learning, concept drift handling |
| **Isolation Forest** | Fraud detection, dati multivariati | ML-based, alta dimensionalità |

## Esempio di Utilizzo

```pascal
// Factory pattern per creazione semplificata
var Detector := TAnomalyDetectorFactory.CreateForFinancialData;

// Configurazione eventi
Detector.OnAnomalyDetected := OnAnomalyHandler;

// Detection
var Result := Detector.Detect(NewValue);
if Result.IsAnomaly then
  ShowMessage(Result.Description);

// Performance monitoring
WriteLn(Detector.GetPerformanceReport);
```

---

**Autore**: Daniele Teti  
**Repository**: [DelphiMVCFramework](https://github.com/danieleteti/delphimvcframework)  
**Blog**: [danieleteti.it](https://www.danieleteti.it)  
**Generato**: {data di generazione}
