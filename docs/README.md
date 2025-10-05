# Documentation - Delphi Anomaly Detection Algorithms

Questa cartella contiene la documentazione completa per la libreria di algoritmi di rilevamento anomalie sviluppata in Delphi.

## Files Disponibili

### 📊 [ClassDiagram.svg](ClassDiagram.svg) ⭐ **CONSIGLIATO**
**Diagramma delle classi in formato SVG**

- Visualizzazione completa dell'architettura
- Relazioni tra classi, interfacce e componenti
- **Apribile direttamente in qualsiasi browser web**
- Zoom e navigazione nativi
- Formato vettoriale scalabile

**Come visualizzare:**
- **Browser**: Doppio clic sul file o trascina nel browser
- **Windows**: Anteprima integrata in Explorer
- **Qualsiasi editor**: Supporto nativo per SVG

### 📊 [ClassDiagram.puml](ClassDiagram.puml)
**Diagramma delle classi in formato PlantUML** (alternativo)

- Stesso contenuto in formato testuale
- Per sviluppatori che preferiscono PlantUML
- Modificabile facilmente

**Come visualizzare:**
- Online: [PlantUML Server](http://www.plantuml.com/plantuml/uml/)
- VS Code: Installa l'estensione "PlantUML"
- IntelliJ/Rider: Plugin PlantUML integration

### 📚 [ClassDiagram_Documentation.md](ClassDiagram_Documentation.md)
**Documentazione dettagliata dell'architettura**

- Spiegazione completa di ogni componente
- Design patterns utilizzati
- Use cases e best practices
- Esempi di utilizzo
- Guida alla scelta del detector appropriato

## Architettura Overview

### 🏗️ **Componenti Principali**
- **Base Classes**: `TBaseAnomalyDetector` (abstract), `TDetectorPerformanceMonitor`
- **Concrete Detectors**: 5 implementazioni specializzate
- **Support Classes**: Factory, Confirmation System, Tree structures
- **Data Structures**: Records per configurazione e risultati

### 🔍 **Algoritmi Implementati**
1. **3-Sigma Rule** - Per dati storici stabili
2. **Sliding Window** - Per flussi continui
3. **Exponential Moving Average** - Per dati con trend
4. **Adaptive Detection** - Con apprendimento continuo
5. **Isolation Forest** - ML per dati multi-dimensionali

### ⚡ **Caratteristiche Tecniche**
- Thread-safe design
- Performance monitoring integrato
- State persistence (save/load)
- Event notification system
- Factory pattern per creazione semplificata

## Quick Start

### 🚀 Visualizzazione Immediata

1. **Apri il Class Diagram**: Doppio clic su [`ClassDiagram.svg`](ClassDiagram.svg)
2. **Browser**: Il diagramma si aprirà automaticamente
3. **Zoom**: Usa Ctrl+Scroll per ingrandire/rimpicciolire
4. **Naviga**: Trascina per muoverti nel diagramma

### 📚 Documentazione Completa

Leggi [`ClassDiagram_Documentation.md`](ClassDiagram_Documentation.md) per:
- Spiegazione di ogni componente
- Guide all'utilizzo
- Best practices
- Esempi di codice

### 🛠️ Per Sviluppatori PlantUML

Se preferisci il formato PlantUML:

#### Visual Studio Code
1. Installa l'estensione "PlantUML"
2. Apri `ClassDiagram.puml`
3. Usa `Ctrl+Shift+P` → "PlantUML: Preview Current Diagram"

#### Online
Copia il contenuto di `ClassDiagram.puml` in: [PlantUML Server](http://www.plantuml.com/plantuml/uml/)

## Struttura del Progetto

```
delphi-anomalies-detectors/
├── AnomalyDetectionAlgorithms.pas  # Classi principali
├── Samples/                        # Esempi di utilizzo
│   ├── EMASample/
│   ├── SlidingWindowSample/
│   └── ThreeSigmaDetectorSample/
├── Tests/                          # Unit tests
└── docs/                          # 📁 Documentazione
    ├── README.md                  # 📄 Questo file
    ├── ClassDiagram.svg           # 📊 Diagramma UML (SVG)
    ├── ClassDiagram.puml          # 📊 Diagramma UML (PlantUML)
    └── ClassDiagram_Documentation.md # 📚 Documentazione dettagliata
```

## Contatti e Supporto

- **Autore**: Daniele Teti
- **Email**: d.teti@bittime.it
- **Website**: [bittimeprofessionals.com](https://www.bittimeprofessionals.com)
- **Blog**: [danieleteti.it](https://www.danieleteti.it)
- **GitHub**: [DelphiMVCFramework](https://github.com/danieleteti/delphimvcframework)

## Licenza

Per informazioni sulla licenza commerciale, contattare l'autore.

---

*Generato automaticamente - Delphi Anomaly Detection Algorithms v1.0*
