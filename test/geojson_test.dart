import 'dart:convert';

import 'package:gml4dart/gml4dart.dart';
import 'package:test/test.dart';

void main() {
  group('GeoJsonBuilder.geometry', () {
    test('converts Point', () {
      const p = GmlPoint(
        coordinate: GmlCoordinate(9.0, 48.0),
      );
      final gj = GeoJsonBuilder.geometry(p)!;
      expect(gj['type'], 'Point');
      expect(gj['coordinates'], [9.0, 48.0]);
    });

    test('converts 3D Point', () {
      const p = GmlPoint(
        coordinate: GmlCoordinate(9.0, 48.0, 100.0),
      );
      final gj = GeoJsonBuilder.geometry(p)!;
      expect(gj['coordinates'], [9.0, 48.0, 100.0]);
    });

    test('converts LineString', () {
      const ls = GmlLineString(coordinates: [
        GmlCoordinate(0, 0),
        GmlCoordinate(1, 1),
        GmlCoordinate(2, 2),
      ]);
      final gj = GeoJsonBuilder.geometry(ls)!;
      expect(gj['type'], 'LineString');
      expect(gj['coordinates'], hasLength(3));
    });

    test('converts Polygon', () {
      const poly = GmlPolygon(
        exterior: GmlLinearRing(coordinates: [
          GmlCoordinate(0, 0),
          GmlCoordinate(10, 0),
          GmlCoordinate(10, 10),
          GmlCoordinate(0, 10),
          GmlCoordinate(0, 0),
        ]),
        interiors: [
          GmlLinearRing(coordinates: [
            GmlCoordinate(2, 2),
            GmlCoordinate(8, 2),
            GmlCoordinate(8, 8),
            GmlCoordinate(2, 8),
            GmlCoordinate(2, 2),
          ]),
        ],
      );
      final gj = GeoJsonBuilder.geometry(poly)!;
      expect(gj['type'], 'Polygon');
      final coords =
          gj['coordinates'] as List<dynamic>;
      expect(coords, hasLength(2)); // exterior + hole
    });

    test('converts MultiPoint', () {
      const mp = GmlMultiPoint(points: [
        GmlPoint(coordinate: GmlCoordinate(1, 2)),
        GmlPoint(coordinate: GmlCoordinate(3, 4)),
      ]);
      final gj = GeoJsonBuilder.geometry(mp)!;
      expect(gj['type'], 'MultiPoint');
      expect(gj['coordinates'], [
        [1.0, 2.0],
        [3.0, 4.0],
      ]);
    });

    test('converts MultiLineString', () {
      const mls = GmlMultiLineString(lineStrings: [
        GmlLineString(coordinates: [
          GmlCoordinate(0, 0),
          GmlCoordinate(1, 1),
        ]),
      ]);
      final gj = GeoJsonBuilder.geometry(mls)!;
      expect(gj['type'], 'MultiLineString');
    });

    test('converts MultiPolygon', () {
      const mp = GmlMultiPolygon(polygons: [
        GmlPolygon(
          exterior: GmlLinearRing(coordinates: [
            GmlCoordinate(0, 0),
            GmlCoordinate(1, 0),
            GmlCoordinate(1, 1),
            GmlCoordinate(0, 0),
          ]),
        ),
      ]);
      final gj = GeoJsonBuilder.geometry(mp)!;
      expect(gj['type'], 'MultiPolygon');
    });

    test('converts Curve as LineString', () {
      const c = GmlCurve(coordinates: [
        GmlCoordinate(0, 0),
        GmlCoordinate(1, 1),
      ]);
      final gj = GeoJsonBuilder.geometry(c)!;
      expect(gj['type'], 'LineString');
    });

    test('converts Surface as MultiPolygon', () {
      const s = GmlSurface(patches: [
        GmlPolygon(
          exterior: GmlLinearRing(coordinates: [
            GmlCoordinate(0, 0),
            GmlCoordinate(1, 0),
            GmlCoordinate(1, 1),
            GmlCoordinate(0, 0),
          ]),
        ),
      ]);
      final gj = GeoJsonBuilder.geometry(s)!;
      expect(gj['type'], 'MultiPolygon');
    });

    test('converts Envelope as Polygon', () {
      const env = GmlEnvelope(
        lowerCorner: GmlCoordinate(0, 0),
        upperCorner: GmlCoordinate(10, 10),
      );
      final gj = GeoJsonBuilder.geometry(env)!;
      expect(gj['type'], 'Polygon');
      final ring = (gj['coordinates']
          as List<dynamic>)[0] as List<dynamic>;
      expect(ring, hasLength(5)); // closed ring
    });

    test('converts Box as Polygon', () {
      const box = GmlBox(
        lowerCorner: GmlCoordinate(5, 5),
        upperCorner: GmlCoordinate(15, 15),
      );
      final gj = GeoJsonBuilder.geometry(box)!;
      expect(gj['type'], 'Polygon');
    });
  });

  group('GeoJsonBuilder.feature', () {
    test('converts feature with properties', () {
      const feat = GmlFeature(
        id: 'f1',
        properties: {
          'name': GmlStringProperty('Test'),
          'value': GmlNumericProperty(42),
          'geom': GmlGeometryProperty(
            GmlPoint(
              coordinate: GmlCoordinate(9, 48),
            ),
          ),
        },
      );
      final gj = GeoJsonBuilder.feature(feat);
      expect(gj['type'], 'Feature');
      expect(gj['id'], 'f1');
      expect(gj['geometry'], isNotNull);
      expect(
        (gj['geometry']
            as Map<String, dynamic>)['type'],
        'Point',
      );
      final props =
          gj['properties'] as Map<String, dynamic>;
      expect(props['name'], 'Test');
      expect(props['value'], 42);
      expect(props.containsKey('geom'), isFalse);
    });

    test('handles nested properties', () {
      const feat = GmlFeature(
        properties: {
          'address': GmlNestedProperty({
            'street': GmlStringProperty('Main St'),
            'number': GmlNumericProperty(1),
          }),
        },
      );
      final gj = GeoJsonBuilder.feature(feat);
      final props =
          gj['properties'] as Map<String, dynamic>;
      expect(props['address'], isA<Map<String, dynamic>>());
      expect(
        (props['address']
            as Map<String, dynamic>)['street'],
        'Main St',
      );
    });
  });

  group('GeoJsonBuilder.featureCollection', () {
    test('converts collection', () {
      const fc = GmlFeatureCollection(features: [
        GmlFeature(id: 'f1'),
        GmlFeature(id: 'f2'),
      ]);
      final gj =
          GeoJsonBuilder.featureCollection(fc);
      expect(gj['type'], 'FeatureCollection');
      expect(gj['features'], hasLength(2));
    });
  });

  group('GeoJsonBuilder.document', () {
    test('converts geometry root', () {
      const doc = GmlDocument(
        version: GmlVersion.v3_2,
        root: GmlPoint(
          coordinate: GmlCoordinate(9, 48),
        ),
      );
      final gj = GeoJsonBuilder.document(doc);
      expect(gj?['type'], 'Point');
    });

    test('returns null for coverage root', () {
      const doc = GmlDocument(
        version: GmlVersion.v3_2,
        root: GmlRectifiedGridCoverage(),
      );
      expect(GeoJsonBuilder.document(doc), isNull);
    });
  });

  group('GeoJsonBuilder JSON strings', () {
    test('geometryToJson produces valid JSON', () {
      const p = GmlPoint(
        coordinate: GmlCoordinate(9, 48),
      );
      final jsonStr = GeoJsonBuilder.geometryToJson(p);
      expect(jsonStr, isNotNull);
      final decoded = json.decode(jsonStr!)
          as Map<String, dynamic>;
      expect(decoded['type'], 'Point');
    });

    test('featureToJson produces valid JSON', () {
      const feat = GmlFeature(id: 'x');
      final jsonStr =
          GeoJsonBuilder.featureToJson(feat);
      final decoded = json.decode(jsonStr)
          as Map<String, dynamic>;
      expect(decoded['type'], 'Feature');
      expect(decoded['id'], 'x');
    });
  });
}
