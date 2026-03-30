# PortGML: `s-gml` nach Dart portieren

## Ziel

Dieses Dokument beschreibt die Portierungsstrategie für die TypeScript-Bibliothek
[`/Development/s-gml`](/Development/s-gml) in ein Dart-Package im aktuellen
Repository [`/Development/flutter/gml4dart`](/Development/flutter/gml4dart).

Die Zielarchitektur und alle verbindlichen Architekturentscheidungen sind in
[architecture.md](architecture.md) beschrieben. Dieses Dokument konzentriert
sich auf die Portierung: Mapping, Phasen, Risiken und Umsetzungsreihenfolge.

Ziel ist keine 1:1-Übersetzung auf Dateiebene, sondern eine Dart-native
Bibliothek mit denselben Kernfähigkeiten:

- GML 2.1.2 / 3.x parsen
- Geometrien, Features und FeatureCollections modellieren
- Coverage-Typen unterstützen
- Builder-/Adapter-Schicht für verschiedene Ausgabeformate anbieten
- Streaming für große XML-Dokumente ermöglichen
- WFS-/WCS-nahe Hilfsfunktionen und Parser abbilden

## Nicht-Ziel

- TypeScript-APIs oder Dateinamen blind nachbauen
- Node.js-spezifische Implementierungen direkt übernehmen
- alle Formate und Spezialmodule im ersten Schritt portieren
- Browser-/VM-Unterschiede früh mit Conditional Imports überfrachten
- GML-XML erzeugen (Schreiben) — die Bibliothek ist in v1 rein lesend

## Portierungsprinzipien

- Dart-first API statt TypeScript-first API
- Core ohne `dart:io`
- Parse, Validation, Interop und I/O trennen
- DOM-Parser und Streaming-Parser als getrennte Strategien behandeln
- zuerst stabiles Domain-Modell, dann Parser, dann Adapter/Builder
- Features in Phasen liefern, nicht als Big-Bang-Port
- öffentliche API früh festlegen und nicht parallel in zwei Richtungen planen

## Funktionsumfang von `s-gml`

Die TypeScript-Library exportiert heute unter anderem:

- `GmlParser`
- `StreamingGmlParser`
- GML-Domain-Typen
- Builder für GeoJSON, WKT, CSV, KML, FlatGeobuf, Shapefile, GeoPackage
- Coverage-Helfer und Coverage-Generator
- WCS Request Builder
- WCS Capabilities Parser
- OWS Exception Parsing
- Validator
- Performance-/Batch-Helfer

Siehe insbesondere:

- [README.md](/Development/s-gml/README.md)
- [src/index.ts](/Development/s-gml/src/index.ts)
- [src/types.ts](/Development/s-gml/src/types.ts)
- [src/streaming-parser.ts](/Development/s-gml/src/streaming-parser.ts)
- [docs/architecture/system-overview.md](/Development/s-gml/docs/architecture/system-overview.md)

## Empfohlene Zielarchitektur in Dart

Die vollständige Architektur ist in [architecture.md](architecture.md)
beschrieben. Hier die Kurzfassung für den Portierungskontext:

### Packages

- `gml4dart` — reiner Dart-Core (Domain, Parser, GeoJSON/WKT-Interop,
  OWS/WCS-Module)
- optional später: `gml4dart_io` — Datei-/HTTP-Helfer, VM-Hooks
- optional später: format-spezifische Zusatzpakete (CSV, FlatGeobuf, …)

Phase 1 startet in einem einzigen Package. Die Architektur bereitet die
spätere Trennung vor.

## API-Richtung und Parsing-Strategie

Die öffentliche Core-API ist dokumentzentriert (`GmlDocument.parse...`), nicht
parserzentriert. Alle Details zu API-Design, Fehlermodell, DOM- vs.
Streaming-Pfad und Streaming-Wiederverwendung sind in
[architecture.md](architecture.md) festgehalten.

Kurzfassung für den Portierungskontext:

- `GmlDocument.parseXmlString(xml)` / `GmlDocument.parseBytes(bytes)` als
  Kern-API
- kein generisches `parseAsyncStream` in v1
- separater `GmlFeatureStreamParser` für große WFS-/FeatureCollection-Dokumente
- Result-Typ `GmlParseResult` mit `GmlParseIssue` statt fachlicher Exceptions
- GeoJSON- und WKT-Builder konsumieren das Core-Modell

Die TypeScript-Library `s-gml` trennt diese beiden Wege bereits sauber:

- normaler Parser: [src/parser-base.ts](/Development/s-gml/src/parser-base.ts)
- Streaming-Parser: [src/streaming-parser.ts](/Development/s-gml/src/streaming-parser.ts)

## Modul-Mapping: TypeScript -> Dart

| TypeScript | Dart-Ziel |
|---|---|
| `src/types.ts` | `lib/src/model/` |
| `src/parser.ts`, `src/parser-base.ts` | `lib/src/parser/` |
| `src/streaming-parser.ts` | `lib/src/parser/streaming/` |
| `src/builders/` | `lib/src/builders/` oder `lib/src/interop/` |
| `src/ows-exception.ts` | `lib/src/ows/` |
| `src/wcs/request-builder.ts` | `lib/src/wcs/request_builder.dart` |
| `src/wcs/capabilities-parser.ts` | `lib/src/wcs/capabilities_parser.dart` |
| `src/generators/coverage-generator.ts` | `lib/src/generators/coverage_generator.dart` |
| `src/utils/geotiff-metadata.ts` | `lib/src/utils/geotiff_metadata.dart` |
| `src/validator.*.ts` | später `lib/src/validation/` bzw. optional `gml4dart_io` |
| `src/performance.ts` | nur portieren, wenn echter Bedarf entsteht |

## Domain-Modell

Das vollständige Domain-Modell mit Typhierarchie, Koordinaten-Modell und
Feature-Properties ist in [architecture.md](architecture.md) definiert.

Portierungsrelevante Kurzfassung:

- `GmlNode` als gemeinsame sealed Basisklasse
- `GmlCoordinate`-Record statt `List<double>` (2D/3D/4D)
- `GmlVersion`-Enum: `v2_1_2`, `v3_0`, `v3_1`, `v3_2`, `v3_3`
- Feature-Properties als `Map<String, GmlPropertyValue>`
- `GmlBox` (GML 2) und `GmlEnvelope` (GML 3) als separate Typen
- `GmlUnsupportedNode` für nicht-typisierbare XML-Knoten

## Builder-/Interop-Reihenfolge

1. GeoJSON
2. WKT
3. CSV als optionales Folge-Modul
4. CoverageJSON / CIS JSON
5. FlatGeobuf
6. KML
7. GeoPackage / Shapefile nur bei echtem Bedarf

GeoJSON und WKT bleiben im Core. Binäre GIS-Formate erhöhen Komplexität und
Abhängigkeiten stark und gehören in Zusatzpakete.

## Empfohlene Lieferphasen

### Phase 0: Bootstrap

- `pubspec.yaml`
- `analysis_options.yaml`
- `lib/gml4dart.dart`
- Test-Setup
- CI-Basis

### Phase 1: Domain-Modell

- Versionen
- Geometrien
- Features
- FeatureCollections
- Coverage-Kernmodelle

### Phase 2: DOM-Parser MVP

- `parseXmlString`
- `parseBytes`
- `GmlParseResult`
- GML-Version erkennen
- Namespaces behandeln
- Point, LineString, LinearRing, Polygon, Envelope, Box
- Feature und FeatureCollection

Hinweis: LinearRing wird hier mitgezogen, weil Polygon es für Exterior-/
Interior-Ringe zwingend benötigt.

### Phase 3: Erweiterte Geometrien

- Curve
- Surface
- MultiPoint
- MultiLineString
- MultiPolygon

### Phase 4: Coverage

- GridEnvelope
- RectifiedGrid
- Grid
- RangeSet
- RangeType
- RectifiedGridCoverage
- GridCoverage
- ReferenceableGridCoverage
- MultiPointCoverage
- GeoTIFF-Metadaten-Helfer

### Phase 5: Interop

- GeoJSON Builder
- WKT Builder
- CSV als optionales Folge-Modul prüfen

### Phase 6: WCS / OWS

- OWS Exception Parser
- WCS Request Builder
- WCS Capabilities Parser
- Coverage XML Generator

### Phase 7: Streaming

- `GmlFeatureStreamParser`
- Scope explizit auf große WFS-/FeatureCollection-Dokumente begrenzen
- Feature-Callback / Batch-API
- Tests mit chunked input
- Speichertests / Performance-Regressionen

### Phase 8: Validierung und I/O

- optionales I/O-Package
- Datei-/URL-Helfer
- XSD-Validierung nur bei klarer Anforderung

## Teststrategie

Ausführliche Teststrategie in [architecture.md → Teststrategie](architecture.md#teststrategie).

Portierungsspezifisch:

- Fixtures aus `/Development/s-gml/test/gml/` übernehmen
- TypeScript-Testergebnisse als Referenz für erwartete Dart-Ergebnisse nutzen
- pro portiertem Modul mindestens die bestehenden TS-Testfälle abdecken

## Risiken

- GML ist deutlich breiter als GeoJSON; vollständige Abdeckung ist teuer
- Coverage-Modelle erhöhen die Komplexität stark
- echtes Streaming ist erheblich schwerer als DOM-Parsing
- GeoPackage/Shapefile haben in Dart höhere Implementierungskosten
- XSD-Validierung ist plattform- und toolabhängig

## Empfohlene erste Umsetzung

Nicht mit Streaming starten. Die Reihenfolge folgt den Lieferphasen oben:

1. Core-Package und Domain-Modell (Phase 0 + 1)
2. DOM-Parser MVP inkl. LinearRing (Phase 2)
3. GeoJSON- und WKT-Builder (Phase 5 parallel zu Phase 3)
4. Coverage-Typen und OWS/WCS (Phase 4 + 6)
5. Streaming erst danach (Phase 7)

## Festgelegte Architekturentscheidungen

Vollständige Liste in [architecture.md → Architekturentscheidungen für v1](architecture.md#architekturentscheidungen-für-v1).

## Nächster sinnvoller Schritt

1. `pubspec.yaml` und `analysis_options.yaml` anlegen
2. `lib/gml4dart.dart` als öffentlichen Entry anlegen
3. `model/` mit `GmlDocument`, `GmlGeometry`, `GmlFeature`,
   `GmlParseResult`, `GmlParseIssue` aufbauen
4. DOM-Parser für `Point`, `LineString`, `LinearRing`, `Polygon`, `Envelope`,
   `FeatureCollection` aufbauen
5. erste GeoJSON- und WKT-Builder ergänzen
6. Fixtures aus `s-gml` übernehmen und Tests schreiben
