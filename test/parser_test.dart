import 'dart:convert';

import 'package:gml4dart/gml4dart.dart';
import 'package:test/test.dart';

void main() {
  group('GmlDocument.parseXmlString', () {
    test('delegates to GmlParser', () {
      const xml = '''
<gml:Point xmlns:gml="http://www.opengis.net/gml/3.2">
  <gml:pos>9.0 48.0</gml:pos>
</gml:Point>''';
      final result =
          GmlDocument.parseXmlString(xml);
      expect(result.hasErrors, isFalse);
      expect(result.document!.root, isA<GmlPoint>());
    });
  });

  group('GmlDocument.parseBytes', () {
    test('delegates to GmlParser', () {
      const xml = '''
<gml:Point xmlns:gml="http://www.opengis.net/gml/3.2">
  <gml:pos>1.0 2.0</gml:pos>
</gml:Point>''';
      final result =
          GmlDocument.parseBytes(utf8.encode(xml));
      expect(result.hasErrors, isFalse);
    });
  });

  group('GmlParser.parseXmlString', () {
    group('invalid input', () {
      test('returns error for invalid XML', () {
        final result =
            GmlParser.parseXmlString('<not-xml');
        expect(result.hasErrors, isTrue);
        expect(result.document, isNull);
        expect(result.issues.first.code, 'invalid_xml');
      });
    });

    group('version detection', () {
      test('detects GML 3.2 from namespace', () {
        const xml = '''
<gml:Point xmlns:gml="http://www.opengis.net/gml/3.2">
  <gml:pos>9.0 48.0</gml:pos>
</gml:Point>''';
        final result = GmlParser.parseXmlString(xml);
        expect(result.document?.version, GmlVersion.v3_2);
      });

      test('detects GML 2 from coordinates element', () {
        const xml = '''
<gml:Point xmlns:gml="http://www.opengis.net/gml">
  <gml:coordinates>9.0,48.0</gml:coordinates>
</gml:Point>''';
        final result = GmlParser.parseXmlString(xml);
        expect(
          result.document?.version,
          GmlVersion.v2_1_2,
        );
      });

      test('detects GML 3.1 from old namespace '
          'without GML 2 indicators', () {
        const xml = '''
<gml:Point xmlns:gml="http://www.opengis.net/gml">
  <gml:pos>9.0 48.0</gml:pos>
</gml:Point>''';
        final result = GmlParser.parseXmlString(xml);
        expect(result.document?.version, GmlVersion.v3_1);
      });
    });

    group('Point', () {
      test('parses GML 3 Point with <pos>', () {
        const xml = '''
<gml:Point xmlns:gml="http://www.opengis.net/gml/3.2"
           srsName="EPSG:4326">
  <gml:pos>9.0 48.0</gml:pos>
</gml:Point>''';
        final result = GmlParser.parseXmlString(xml);
        expect(result.hasErrors, isFalse);

        final point = result.document!.root as GmlPoint;
        expect(point.coordinate.x, 9.0);
        expect(point.coordinate.y, 48.0);
        expect(point.srsName, 'EPSG:4326');
      });

      test('parses GML 3 Point with 3D <pos>', () {
        const xml = '''
<gml:Point xmlns:gml="http://www.opengis.net/gml/3.2">
  <gml:pos>9.0 48.0 100.5</gml:pos>
</gml:Point>''';
        final result = GmlParser.parseXmlString(xml);
        final point = result.document!.root as GmlPoint;
        expect(point.coordinate.z, 100.5);
        expect(point.coordinate.dimension, 3);
      });

      test('parses GML 2 Point with <coordinates>',
          () {
        const xml = '''
<gml:Point xmlns:gml="http://www.opengis.net/gml"
           srsName="EPSG:4326">
  <gml:coordinates>9.0,48.0</gml:coordinates>
</gml:Point>''';
        final result = GmlParser.parseXmlString(xml);
        expect(result.hasErrors, isFalse);

        final point = result.document!.root as GmlPoint;
        expect(point.coordinate.x, 9.0);
        expect(point.coordinate.y, 48.0);
      });

      test('reports error for Point without coords',
          () {
        const xml = '''
<gml:Point xmlns:gml="http://www.opengis.net/gml/3.2">
</gml:Point>''';
        final result = GmlParser.parseXmlString(xml);
        expect(result.hasErrors, isTrue);
        expect(
          result.issues.first.code,
          'missing_coordinates',
        );
      });
    });

    group('LineString', () {
      test('parses GML 3 LineString with <posList>',
          () {
        const xml = '''
<gml:LineString xmlns:gml="http://www.opengis.net/gml/3.2">
  <gml:posList>0 0 1 1 2 2</gml:posList>
</gml:LineString>''';
        final result = GmlParser.parseXmlString(xml);
        final ls =
            result.document!.root as GmlLineString;
        expect(ls.coordinates, hasLength(3));
        expect(ls.coordinates[1].x, 1.0);
        expect(ls.coordinates[1].y, 1.0);
      });

      test('parses GML 2 LineString with <coordinates>',
          () {
        const xml = '''
<gml:LineString xmlns:gml="http://www.opengis.net/gml">
  <gml:coordinates>0,0 1,1 2,2</gml:coordinates>
</gml:LineString>''';
        final result = GmlParser.parseXmlString(xml);
        final ls =
            result.document!.root as GmlLineString;
        expect(ls.coordinates, hasLength(3));
      });

      test('parses 3D posList with srsDimension', () {
        const xml = '''
<gml:LineString xmlns:gml="http://www.opengis.net/gml/3.2">
  <gml:posList srsDimension="3">0 0 10 1 1 20 2 2 30</gml:posList>
</gml:LineString>''';
        final result = GmlParser.parseXmlString(xml);
        final ls =
            result.document!.root as GmlLineString;
        expect(ls.coordinates, hasLength(3));
        expect(ls.coordinates[0].z, 10.0);
        expect(ls.coordinates[2].z, 30.0);
      });
    });

    group('LinearRing', () {
      test('parses LinearRing', () {
        const xml = '''
<gml:LinearRing xmlns:gml="http://www.opengis.net/gml/3.2">
  <gml:posList>0 0 10 0 10 10 0 10 0 0</gml:posList>
</gml:LinearRing>''';
        final result = GmlParser.parseXmlString(xml);
        final ring =
            result.document!.root as GmlLinearRing;
        expect(ring.coordinates, hasLength(5));
      });
    });

    group('Polygon', () {
      test('parses GML 3 Polygon with exterior', () {
        const xml = '''
<gml:Polygon xmlns:gml="http://www.opengis.net/gml/3.2"
             srsName="EPSG:4326">
  <gml:exterior>
    <gml:LinearRing>
      <gml:posList>0 0 10 0 10 10 0 10 0 0</gml:posList>
    </gml:LinearRing>
  </gml:exterior>
</gml:Polygon>''';
        final result = GmlParser.parseXmlString(xml);
        final poly =
            result.document!.root as GmlPolygon;
        expect(
          poly.exterior.coordinates,
          hasLength(5),
        );
        expect(poly.interiors, isEmpty);
        expect(poly.srsName, 'EPSG:4326');
      });

      test('parses GML 3 Polygon with hole', () {
        const xml = '''
<gml:Polygon xmlns:gml="http://www.opengis.net/gml/3.2">
  <gml:exterior>
    <gml:LinearRing>
      <gml:posList>0 0 10 0 10 10 0 10 0 0</gml:posList>
    </gml:LinearRing>
  </gml:exterior>
  <gml:interior>
    <gml:LinearRing>
      <gml:posList>2 2 8 2 8 8 2 8 2 2</gml:posList>
    </gml:LinearRing>
  </gml:interior>
</gml:Polygon>''';
        final result = GmlParser.parseXmlString(xml);
        final poly =
            result.document!.root as GmlPolygon;
        expect(poly.interiors, hasLength(1));
      });

      test(
          'parses GML 2 Polygon with '
          'outerBoundaryIs', () {
        const xml = '''
<gml:Polygon xmlns:gml="http://www.opengis.net/gml">
  <gml:outerBoundaryIs>
    <gml:LinearRing>
      <gml:coordinates>0,0 10,0 10,10 0,10 0,0</gml:coordinates>
    </gml:LinearRing>
  </gml:outerBoundaryIs>
  <gml:innerBoundaryIs>
    <gml:LinearRing>
      <gml:coordinates>2,2 8,2 8,8 2,8 2,2</gml:coordinates>
    </gml:LinearRing>
  </gml:innerBoundaryIs>
</gml:Polygon>''';
        final result = GmlParser.parseXmlString(xml);
        final poly =
            result.document!.root as GmlPolygon;
        expect(
          poly.exterior.coordinates,
          hasLength(5),
        );
        expect(poly.interiors, hasLength(1));
      });

      test(
          'reports error for Polygon '
          'without exterior', () {
        const xml = '''
<gml:Polygon xmlns:gml="http://www.opengis.net/gml/3.2">
</gml:Polygon>''';
        final result = GmlParser.parseXmlString(xml);
        expect(result.hasErrors, isTrue);
        expect(
          result.issues.first.code,
          'missing_exterior',
        );
      });
    });

    group('Envelope', () {
      test('parses GML 3 Envelope', () {
        const xml = '''
<gml:Envelope xmlns:gml="http://www.opengis.net/gml/3.2"
              srsName="EPSG:4326">
  <gml:lowerCorner>0 0</gml:lowerCorner>
  <gml:upperCorner>10 10</gml:upperCorner>
</gml:Envelope>''';
        final result = GmlParser.parseXmlString(xml);
        final env =
            result.document!.root as GmlEnvelope;
        expect(env.lowerCorner.x, 0.0);
        expect(env.upperCorner.x, 10.0);
        expect(env.srsName, 'EPSG:4326');
      });

      test(
          'reports error for Envelope '
          'without corners', () {
        const xml = '''
<gml:Envelope xmlns:gml="http://www.opengis.net/gml/3.2">
  <gml:lowerCorner>0 0</gml:lowerCorner>
</gml:Envelope>''';
        final result = GmlParser.parseXmlString(xml);
        expect(result.hasErrors, isTrue);
        expect(
          result.issues.first.code,
          'missing_corners',
        );
      });
    });

    group('Box', () {
      test('parses GML 2 Box', () {
        const xml = '''
<gml:Box xmlns:gml="http://www.opengis.net/gml"
         srsName="EPSG:4326">
  <gml:coordinates>0,0 10,10</gml:coordinates>
</gml:Box>''';
        final result = GmlParser.parseXmlString(xml);
        final box = result.document!.root as GmlBox;
        expect(box.lowerCorner.x, 0.0);
        expect(box.upperCorner.y, 10.0);
        expect(box.srsName, 'EPSG:4326');
      });
    });

    group('Feature', () {
      test('parses standalone feature', () {
        const xml = '''
<app:Building xmlns:app="http://example.com"
              xmlns:gml="http://www.opengis.net/gml/3.2"
              gml:id="building.1">
  <app:name>City Hall</app:name>
  <app:height>25.5</app:height>
  <app:geom>
    <gml:Point srsName="EPSG:4326">
      <gml:pos>9.0 48.0</gml:pos>
    </gml:Point>
  </app:geom>
</app:Building>''';
        final result = GmlParser.parseXmlString(xml);
        expect(result.hasErrors, isFalse);

        final feature =
            result.document!.root as GmlFeature;
        expect(feature.id, 'building.1');
        expect(
          feature.properties['name'],
          isA<GmlStringProperty>(),
        );
        expect(
          (feature.properties['name']!
                  as GmlStringProperty)
              .value,
          'City Hall',
        );
        expect(
          feature.properties['height'],
          isA<GmlNumericProperty>(),
        );
        expect(
          (feature.properties['height']!
                  as GmlNumericProperty)
              .value,
          25.5,
        );
        expect(
          feature.properties['geom'],
          isA<GmlGeometryProperty>(),
        );
      });
    });

    group('FeatureCollection', () {
      test('parses WFS 2.0 with wfs:member', () {
        const xml = '''
<wfs:FeatureCollection
    xmlns:wfs="http://www.opengis.net/wfs/2.0"
    xmlns:gml="http://www.opengis.net/gml/3.2"
    xmlns:app="http://example.com">
  <wfs:member>
    <app:Place gml:id="place.1">
      <app:name>Berlin</app:name>
      <app:geom>
        <gml:Point srsName="EPSG:4326">
          <gml:pos>13.4 52.5</gml:pos>
        </gml:Point>
      </app:geom>
    </app:Place>
  </wfs:member>
  <wfs:member>
    <app:Place gml:id="place.2">
      <app:name>Munich</app:name>
      <app:geom>
        <gml:Point srsName="EPSG:4326">
          <gml:pos>11.6 48.1</gml:pos>
        </gml:Point>
      </app:geom>
    </app:Place>
  </wfs:member>
</wfs:FeatureCollection>''';
        final result = GmlParser.parseXmlString(xml);
        expect(result.hasErrors, isFalse);
        expect(
          result.document?.version,
          GmlVersion.v3_2,
        );

        final fc = result.document!.root
            as GmlFeatureCollection;
        expect(fc.features, hasLength(2));
        expect(fc.features[0].id, 'place.1');
        expect(fc.features[1].id, 'place.2');
      });

      test(
          'parses WFS 1.0 with '
          'gml:featureMember and fid', () {
        const xml = '''
<wfs:FeatureCollection
    xmlns:wfs="http://www.opengis.net/wfs"
    xmlns:gml="http://www.opengis.net/gml"
    xmlns:app="http://example.com">
  <gml:featureMember>
    <app:Road fid="road.1">
      <app:name>Main Street</app:name>
      <app:geom>
        <gml:LineString srsName="EPSG:4326">
          <gml:coordinates>0,0 1,1 2,2</gml:coordinates>
        </gml:LineString>
      </app:geom>
    </app:Road>
  </gml:featureMember>
</wfs:FeatureCollection>''';
        final result = GmlParser.parseXmlString(xml);
        expect(result.hasErrors, isFalse);

        final fc = result.document!.root
            as GmlFeatureCollection;
        expect(fc.features, hasLength(1));
        expect(fc.features[0].id, 'road.1');
      });

      test(
          'parses WFS 1.1 with '
          'gml:featureMembers (plural)', () {
        const xml = '''
<wfs:FeatureCollection
    xmlns:wfs="http://www.opengis.net/wfs"
    xmlns:gml="http://www.opengis.net/gml"
    xmlns:app="http://example.com">
  <gml:featureMembers>
    <app:Place gml:id="p1">
      <app:name>A</app:name>
    </app:Place>
    <app:Place gml:id="p2">
      <app:name>B</app:name>
    </app:Place>
  </gml:featureMembers>
</wfs:FeatureCollection>''';
        final result = GmlParser.parseXmlString(xml);
        expect(result.hasErrors, isFalse);

        final fc = result.document!.root
            as GmlFeatureCollection;
        expect(fc.features, hasLength(2));
      });

      test('parses boundedBy on FeatureCollection',
          () {
        const xml = '''
<wfs:FeatureCollection
    xmlns:wfs="http://www.opengis.net/wfs/2.0"
    xmlns:gml="http://www.opengis.net/gml/3.2"
    xmlns:app="http://example.com">
  <gml:boundedBy>
    <gml:Envelope srsName="EPSG:4326">
      <gml:lowerCorner>0 0</gml:lowerCorner>
      <gml:upperCorner>10 10</gml:upperCorner>
    </gml:Envelope>
  </gml:boundedBy>
  <wfs:member>
    <app:Place gml:id="p1">
      <app:name>X</app:name>
    </app:Place>
  </wfs:member>
</wfs:FeatureCollection>''';
        final result = GmlParser.parseXmlString(xml);
        final fc = result.document!.root
            as GmlFeatureCollection;
        expect(fc.boundedBy, isNotNull);
        expect(fc.boundedBy!.lowerCorner.x, 0.0);
        expect(fc.boundedBy!.upperCorner.x, 10.0);
      });
    });

    group('parseBytes', () {
      test('parses UTF-8 bytes', () {
        const xml = '''
<gml:Point xmlns:gml="http://www.opengis.net/gml/3.2">
  <gml:pos>9.0 48.0</gml:pos>
</gml:Point>''';
        final result =
            GmlParser.parseBytes(utf8.encode(xml));
        expect(result.hasErrors, isFalse);
        final point =
            result.document!.root as GmlPoint;
        expect(point.coordinate.x, 9.0);
      });

      test('returns error for invalid UTF-8', () {
        final result = GmlParser.parseBytes(
          [0xFF, 0xFE, 0x80, 0x81],
        );
        expect(result.hasErrors, isTrue);
        expect(result.document, isNull);
        expect(
          result.issues.first.code,
          'invalid_encoding',
        );
      });
    });

    // --- Phase 3: Extended geometries ---

    group('Curve', () {
      test('parses Curve with LineStringSegment', () {
        const xml = '''
<gml:Curve xmlns:gml="http://www.opengis.net/gml/3.2">
  <gml:segments>
    <gml:LineStringSegment>
      <gml:posList>0 0 1 1 2 2</gml:posList>
    </gml:LineStringSegment>
  </gml:segments>
</gml:Curve>''';
        final result = GmlParser.parseXmlString(xml);
        expect(result.hasErrors, isFalse);
        final curve =
            result.document!.root as GmlCurve;
        expect(curve.coordinates, hasLength(3));
      });

      test(
          'parses Curve with multiple '
          'segments', () {
        const xml = '''
<gml:Curve xmlns:gml="http://www.opengis.net/gml/3.2">
  <gml:segments>
    <gml:LineStringSegment>
      <gml:posList>0 0 1 1</gml:posList>
    </gml:LineStringSegment>
    <gml:LineStringSegment>
      <gml:posList>1 1 2 2 3 3</gml:posList>
    </gml:LineStringSegment>
  </gml:segments>
</gml:Curve>''';
        final result = GmlParser.parseXmlString(xml);
        final curve =
            result.document!.root as GmlCurve;
        expect(curve.coordinates, hasLength(5));
      });
    });

    group('Surface', () {
      test('parses Surface with PolygonPatch', () {
        const xml = '''
<gml:Surface xmlns:gml="http://www.opengis.net/gml/3.2">
  <gml:patches>
    <gml:PolygonPatch>
      <gml:exterior>
        <gml:LinearRing>
          <gml:posList>0 0 10 0 10 10 0 10 0 0</gml:posList>
        </gml:LinearRing>
      </gml:exterior>
    </gml:PolygonPatch>
  </gml:patches>
</gml:Surface>''';
        final result = GmlParser.parseXmlString(xml);
        expect(result.hasErrors, isFalse);
        final surface =
            result.document!.root as GmlSurface;
        expect(surface.patches, hasLength(1));
        expect(
          surface.patches[0].exterior.coordinates,
          hasLength(5),
        );
      });

      test(
          'reports error for Surface '
          'without patches', () {
        const xml = '''
<gml:Surface xmlns:gml="http://www.opengis.net/gml/3.2">
</gml:Surface>''';
        final result = GmlParser.parseXmlString(xml);
        expect(result.hasErrors, isTrue);
        expect(
          result.issues.first.code,
          'missing_patches',
        );
      });
    });

    group('MultiPoint', () {
      test('parses with pointMember', () {
        const xml = '''
<gml:MultiPoint xmlns:gml="http://www.opengis.net/gml/3.2">
  <gml:pointMember>
    <gml:Point><gml:pos>1 2</gml:pos></gml:Point>
  </gml:pointMember>
  <gml:pointMember>
    <gml:Point><gml:pos>3 4</gml:pos></gml:Point>
  </gml:pointMember>
</gml:MultiPoint>''';
        final result = GmlParser.parseXmlString(xml);
        expect(result.hasErrors, isFalse);
        final mp =
            result.document!.root as GmlMultiPoint;
        expect(mp.points, hasLength(2));
        expect(mp.points[0].coordinate.x, 1.0);
        expect(mp.points[1].coordinate.x, 3.0);
      });

      test('parses with pointMembers (plural)', () {
        const xml = '''
<gml:MultiPoint xmlns:gml="http://www.opengis.net/gml/3.2">
  <gml:pointMembers>
    <gml:Point><gml:pos>5 6</gml:pos></gml:Point>
    <gml:Point><gml:pos>7 8</gml:pos></gml:Point>
  </gml:pointMembers>
</gml:MultiPoint>''';
        final result = GmlParser.parseXmlString(xml);
        final mp =
            result.document!.root as GmlMultiPoint;
        expect(mp.points, hasLength(2));
      });
    });

    group('MultiLineString', () {
      test(
          'parses GML 2 with '
          'lineStringMember', () {
        const xml = '''
<gml:MultiLineString xmlns:gml="http://www.opengis.net/gml">
  <gml:lineStringMember>
    <gml:LineString>
      <gml:coordinates>0,0 1,1</gml:coordinates>
    </gml:LineString>
  </gml:lineStringMember>
  <gml:lineStringMember>
    <gml:LineString>
      <gml:coordinates>2,2 3,3</gml:coordinates>
    </gml:LineString>
  </gml:lineStringMember>
</gml:MultiLineString>''';
        final result = GmlParser.parseXmlString(xml);
        expect(result.hasErrors, isFalse);
        final mls = result.document!.root
            as GmlMultiLineString;
        expect(mls.lineStrings, hasLength(2));
      });
    });

    group('MultiCurve', () {
      test(
          'parses GML 3 MultiCurve with '
          'LineString members', () {
        const xml = '''
<gml:MultiCurve xmlns:gml="http://www.opengis.net/gml/3.2">
  <gml:curveMember>
    <gml:LineString>
      <gml:posList>0 0 1 1</gml:posList>
    </gml:LineString>
  </gml:curveMember>
  <gml:curveMember>
    <gml:LineString>
      <gml:posList>2 2 3 3</gml:posList>
    </gml:LineString>
  </gml:curveMember>
</gml:MultiCurve>''';
        final result = GmlParser.parseXmlString(xml);
        expect(result.hasErrors, isFalse);
        final mls = result.document!.root
            as GmlMultiLineString;
        expect(mls.lineStrings, hasLength(2));
      });

      test(
          'parses MultiCurve with '
          'Curve members', () {
        const xml = '''
<gml:MultiCurve xmlns:gml="http://www.opengis.net/gml/3.2">
  <gml:curveMember>
    <gml:Curve>
      <gml:segments>
        <gml:LineStringSegment>
          <gml:posList>0 0 1 1 2 2</gml:posList>
        </gml:LineStringSegment>
      </gml:segments>
    </gml:Curve>
  </gml:curveMember>
</gml:MultiCurve>''';
        final result = GmlParser.parseXmlString(xml);
        final mls = result.document!.root
            as GmlMultiLineString;
        expect(mls.lineStrings, hasLength(1));
        expect(
          mls.lineStrings[0].coordinates,
          hasLength(3),
        );
      });
    });

    group('MultiPolygon', () {
      test(
          'parses GML 2 with '
          'polygonMember', () {
        const xml = '''
<gml:MultiPolygon xmlns:gml="http://www.opengis.net/gml"
                  srsName="EPSG:4326">
  <gml:polygonMember>
    <gml:Polygon>
      <gml:outerBoundaryIs>
        <gml:LinearRing>
          <gml:coordinates>0,0 10,0 10,10 0,10 0,0</gml:coordinates>
        </gml:LinearRing>
      </gml:outerBoundaryIs>
    </gml:Polygon>
  </gml:polygonMember>
</gml:MultiPolygon>''';
        final result = GmlParser.parseXmlString(xml);
        expect(result.hasErrors, isFalse);
        final mp = result.document!.root
            as GmlMultiPolygon;
        expect(mp.polygons, hasLength(1));
        expect(mp.srsName, 'EPSG:4326');
      });
    });

    group('MultiSurface', () {
      test(
          'parses GML 3 MultiSurface with '
          'surfaceMember', () {
        const xml = '''
<gml:MultiSurface xmlns:gml="http://www.opengis.net/gml/3.2"
                  srsName="EPSG:4326" srsDimension="2">
  <gml:surfaceMember>
    <gml:Polygon>
      <gml:exterior>
        <gml:LinearRing>
          <gml:posList>0 0 10 0 10 10 0 10 0 0</gml:posList>
        </gml:LinearRing>
      </gml:exterior>
    </gml:Polygon>
  </gml:surfaceMember>
  <gml:surfaceMember>
    <gml:Polygon>
      <gml:exterior>
        <gml:LinearRing>
          <gml:posList>20 20 30 20 30 30 20 30 20 20</gml:posList>
        </gml:LinearRing>
      </gml:exterior>
    </gml:Polygon>
  </gml:surfaceMember>
</gml:MultiSurface>''';
        final result = GmlParser.parseXmlString(xml);
        expect(result.hasErrors, isFalse);
        final mp = result.document!.root
            as GmlMultiPolygon;
        expect(mp.polygons, hasLength(2));
        expect(mp.srsName, 'EPSG:4326');
      });

      test('parses in FeatureCollection context',
          () {
        const xml = '''
<wfs:FeatureCollection
    xmlns:wfs="http://www.opengis.net/wfs/2.0"
    xmlns:gml="http://www.opengis.net/gml/3.2"
    xmlns:app="http://example.com">
  <wfs:member>
    <app:Lake gml:id="lake.1">
      <app:geom>
        <gml:MultiSurface srsName="EPSG:4326" srsDimension="2">
          <gml:surfaceMember>
            <gml:Polygon>
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList>0 0 1 0 1 1 0 1 0 0</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
            </gml:Polygon>
          </gml:surfaceMember>
        </gml:MultiSurface>
      </app:geom>
      <app:name>Test Lake</app:name>
    </app:Lake>
  </wfs:member>
</wfs:FeatureCollection>''';
        final result = GmlParser.parseXmlString(xml);
        expect(result.hasErrors, isFalse);
        final fc = result.document!.root
            as GmlFeatureCollection;
        expect(fc.features, hasLength(1));
        final geomProp = fc.features[0]
            .properties['geom'] as GmlGeometryProperty;
        expect(
          geomProp.geometry,
          isA<GmlMultiPolygon>(),
        );
      });
    });
  });
}
