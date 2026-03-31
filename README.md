# gml4dart

Pure-Dart-Bibliothek zum Parsen und Weiterverarbeiten von GML 2.1.2 und 3.x.

`gml4dart` liefert ein typisiertes Domain-Modell für Geometrien, Features,
FeatureCollections und Coverage-Typen. Dazu kommen leichte Interop-Bausteine
für GeoJSON und WKT, WCS-/OWS-Helfer sowie ein spezialisierter Streaming-Pfad
für große FeatureCollections. Der Core bleibt `dart:io`-frei; Datei- und
URL-Helfer liegen im optionalen Einstieg `package:gml4dart/gml4dart_io.dart`.

## Features

- GML 2.1.2, 3.0, 3.1, 3.2 und 3.3
- Geometrien: `Point`, `LineString`, `LinearRing`, `Polygon`, `Envelope`,
  `Box`, `Curve`, `Surface`, `MultiPoint`, `MultiLineString`,
  `MultiPolygon`
- `Feature`- und `FeatureCollection`-Parsing
- Coverages: `RectifiedGridCoverage`, `GridCoverage`,
  `ReferenceableGridCoverage`, `MultiPointCoverage`
- GeoJSON- und WKT-Builder
- OWS Exception Parsing
- WCS GetCoverage Builder und Capabilities Parser
- Coverage-XML-Generator und GeoTIFF-Metadaten-Helfer
- Streaming-Parser für große WFS-/FeatureCollection-Dokumente
- Optionales I/O-API für Datei- und URL-Zugriff

## Installation

```bash
dart pub add gml4dart
```

SDK-Anforderung: Dart `^3.0.0`

## Nutzung

### GML parsen

```dart
import 'package:gml4dart/gml4dart.dart';

final result = GmlDocument.parseXmlString('''
<gml:Point xmlns:gml="http://www.opengis.net/gml/3.2">
  <gml:pos>9.0 48.0</gml:pos>
</gml:Point>
''');

if (result.hasErrors) {
  for (final issue in result.issues) {
    print('${issue.code}: ${issue.message}');
  }
  throw StateError('Invalid GML');
}

final point = result.document!.root as GmlPoint;
print(point.coordinate.x); // 9.0
print(point.coordinate.y); // 48.0
```

### Nach GeoJSON konvertieren

```dart
import 'package:gml4dart/gml4dart.dart';

final result = GmlDocument.parseXmlString('''
<gml:Polygon xmlns:gml="http://www.opengis.net/gml/3.2">
  <gml:exterior>
    <gml:LinearRing>
      <gml:posList>0 0 4 0 4 3 0 3 0 0</gml:posList>
    </gml:LinearRing>
  </gml:exterior>
</gml:Polygon>
''');

final geojson = GeoJsonBuilder.document(result.document!);
print(geojson);
```

### Geometrie als WKT ausgeben

```dart
import 'package:gml4dart/gml4dart.dart';

const line = GmlLineString(
  coordinates: [
    GmlCoordinate(0, 0),
    GmlCoordinate(1, 1),
  ],
);

print(WktBuilder.geometry(line)); // LINESTRING (0.0 0.0, 1.0 1.0)
```

### Optionales I/O-Package

```dart
import 'package:gml4dart/gml4dart_io.dart';

final result = await GmlIo.parseFile('data/example.gml');
final features = GmlIo.streamFeaturesFromFile('data/wfs.xml');

await for (final feature in features) {
  print(feature.id);
}
```

`gml4dart_io` nutzt `dart:io` und ist deshalb für VM/CLI gedacht, nicht für
Web-Builds.

## Architektur

Die Architektur und der Port-Plan sind in den Projekt-Dokumenten beschrieben:

- [docs/architecture.md](docs/architecture.md)
- [docs/releasing.md](docs/releasing.md)
- [PortGML.md](PortGML.md)

## Entwicklung

Kein lokales Dart SDK nötig; alle Standardbefehle können via Docker laufen:

```bash
docker build --target analyze -t gml4dart:analyze .
docker build --target test -t gml4dart:test .
docker build --target doc -t gml4dart:doc .
docker build --target publish-check -t gml4dart:publish-check .
```

Mit lokalem Dart SDK:

```bash
dart pub get
dart analyze
dart test
dart doc
dart pub publish --dry-run
```

## Nicht enthalten

- XSD-Validierung ist in v1 bewusst nicht enthalten. Strukturelle Parse-Fehler
  werden stattdessen über `GmlParseIssue` signalisiert.
