import 'package:gml4dart/gml4dart.dart';
import 'package:test/test.dart';

void main() {
  group('WktBuilder.geometry', () {
    test('converts Point', () {
      const p = GmlPoint(
        coordinate: GmlCoordinate(9.0, 48.0),
      );
      expect(
        WktBuilder.geometry(p),
        'POINT (9.0 48.0)',
      );
    });

    test('converts 3D Point', () {
      const p = GmlPoint(
        coordinate: GmlCoordinate(9.0, 48.0, 100.0),
      );
      expect(
        WktBuilder.geometry(p),
        'POINT (9.0 48.0 100.0)',
      );
    });

    test('converts LineString', () {
      const ls = GmlLineString(coordinates: [
        GmlCoordinate(0, 0),
        GmlCoordinate(1, 1),
        GmlCoordinate(2, 2),
      ]);
      expect(
        WktBuilder.geometry(ls),
        'LINESTRING (0.0 0.0, 1.0 1.0, 2.0 2.0)',
      );
    });

    test('converts Polygon', () {
      const poly = GmlPolygon(
        exterior: GmlLinearRing(coordinates: [
          GmlCoordinate(0, 0),
          GmlCoordinate(1, 0),
          GmlCoordinate(1, 1),
          GmlCoordinate(0, 0),
        ]),
      );
      expect(
        WktBuilder.geometry(poly),
        'POLYGON ((0.0 0.0, 1.0 0.0, '
        '1.0 1.0, 0.0 0.0))',
      );
    });

    test('converts Polygon with hole', () {
      const poly = GmlPolygon(
        exterior: GmlLinearRing(coordinates: [
          GmlCoordinate(0, 0),
          GmlCoordinate(10, 0),
          GmlCoordinate(10, 10),
          GmlCoordinate(0, 0),
        ]),
        interiors: [
          GmlLinearRing(coordinates: [
            GmlCoordinate(2, 2),
            GmlCoordinate(8, 2),
            GmlCoordinate(8, 8),
            GmlCoordinate(2, 2),
          ]),
        ],
      );
      final wkt = WktBuilder.geometry(poly)!;
      expect(wkt, startsWith('POLYGON ('));
      expect(wkt, contains('), ('));
    });

    test('converts MultiPoint', () {
      const mp = GmlMultiPoint(points: [
        GmlPoint(coordinate: GmlCoordinate(1, 2)),
        GmlPoint(coordinate: GmlCoordinate(3, 4)),
      ]);
      expect(
        WktBuilder.geometry(mp),
        'MULTIPOINT ((1.0 2.0), (3.0 4.0))',
      );
    });

    test('converts MultiLineString', () {
      const mls = GmlMultiLineString(lineStrings: [
        GmlLineString(coordinates: [
          GmlCoordinate(0, 0),
          GmlCoordinate(1, 1),
        ]),
        GmlLineString(coordinates: [
          GmlCoordinate(2, 2),
          GmlCoordinate(3, 3),
        ]),
      ]);
      expect(
        WktBuilder.geometry(mls),
        'MULTILINESTRING ('
        '(0.0 0.0, 1.0 1.0), '
        '(2.0 2.0, 3.0 3.0))',
      );
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
      final wkt = WktBuilder.geometry(mp)!;
      expect(wkt, startsWith('MULTIPOLYGON ('));
    });

    test('converts Curve as LineString', () {
      const c = GmlCurve(coordinates: [
        GmlCoordinate(0, 0),
        GmlCoordinate(1, 1),
      ]);
      expect(
        WktBuilder.geometry(c),
        'LINESTRING (0.0 0.0, 1.0 1.0)',
      );
    });

    test('converts Envelope as Polygon', () {
      const env = GmlEnvelope(
        lowerCorner: GmlCoordinate(0, 0),
        upperCorner: GmlCoordinate(10, 10),
      );
      final wkt = WktBuilder.geometry(env)!;
      expect(wkt, startsWith('POLYGON (('));
      expect(wkt, contains('0.0 0.0'));
      expect(wkt, contains('10.0 10.0'));
    });

    test('converts Box as Polygon', () {
      const box = GmlBox(
        lowerCorner: GmlCoordinate(5, 5),
        upperCorner: GmlCoordinate(15, 15),
      );
      final wkt = WktBuilder.geometry(box)!;
      expect(wkt, startsWith('POLYGON (('));
    });
  });

  group('WktBuilder end-to-end', () {
    test('parsed GML to WKT', () {
      const xml = '''
<gml:Point xmlns:gml="http://www.opengis.net/gml/3.2"
           srsName="EPSG:4326">
  <gml:pos>9.0 48.0</gml:pos>
</gml:Point>''';
      final result = GmlParser.parseXmlString(xml);
      final geom =
          result.document!.root as GmlGeometry;
      expect(
        WktBuilder.geometry(geom),
        'POINT (9.0 48.0)',
      );
    });
  });
}
