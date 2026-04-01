// ignore_for_file: avoid_print
import 'package:gml4dart/gml4dart.dart';

void main() {
  // --- Parse a GML Point ---
  final pointResult = GmlDocument.parseXmlString('''
<gml:Point xmlns:gml="http://www.opengis.net/gml/3.2">
  <gml:pos>9.0 48.0</gml:pos>
</gml:Point>
''');

  if (pointResult.hasErrors) {
    for (final issue in pointResult.issues) {
      print('${issue.severity}: ${issue.code} – ${issue.message}');
    }
    return;
  }

  final point = pointResult.document!.root as GmlPoint;
  print('Point: ${point.coordinate.x}, ${point.coordinate.y}');

  // --- Parse a FeatureCollection and convert to GeoJSON ---
  final fcResult = GmlDocument.parseXmlString('''
<wfs:FeatureCollection
    xmlns:wfs="http://www.opengis.net/wfs/2.0"
    xmlns:gml="http://www.opengis.net/gml/3.2"
    xmlns:app="http://example.com/app">
  <wfs:member>
    <app:Building gml:id="b1">
      <app:name>Town Hall</app:name>
      <app:geometry>
        <gml:Point>
          <gml:pos>9.18 48.78</gml:pos>
        </gml:Point>
      </app:geometry>
    </app:Building>
  </wfs:member>
</wfs:FeatureCollection>
''');

  if (!fcResult.hasErrors) {
    final fc = fcResult.document!.root as GmlFeatureCollection;
    print('Features: ${fc.features.length}');

    // Convert to GeoJSON map
    final geojson = GeoJsonBuilder.featureCollection(fc);
    print('GeoJSON type: ${geojson['type']}');
  }

  // --- Build a geometry and export as WKT ---
  const line = GmlLineString(
    coordinates: [
      GmlCoordinate(0, 0),
      GmlCoordinate(1, 1),
      GmlCoordinate(2, 0),
    ],
  );

  final wkt = WktBuilder.geometry(line);
  print('WKT: $wkt');
}
