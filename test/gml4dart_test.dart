import 'package:gml4dart/gml4dart.dart';
import 'package:test/test.dart';

void main() {
  group('GmlVersion', () {
    test('has all expected versions', () {
      expect(GmlVersion.values, hasLength(5));
      expect(GmlVersion.values, contains(GmlVersion.v2_1_2));
      expect(GmlVersion.values, contains(GmlVersion.v3_0));
      expect(GmlVersion.values, contains(GmlVersion.v3_1));
      expect(GmlVersion.values, contains(GmlVersion.v3_2));
      expect(GmlVersion.values, contains(GmlVersion.v3_3));
    });
  });

  group('GmlCoordinate', () {
    test('2D coordinate', () {
      const coord = GmlCoordinate(1.0, 2.0);
      expect(coord.x, 1.0);
      expect(coord.y, 2.0);
      expect(coord.z, isNull);
      expect(coord.m, isNull);
      expect(coord.dimension, 2);
    });

    test('3D coordinate', () {
      const coord = GmlCoordinate(1.0, 2.0, 3.0);
      expect(coord.x, 1.0);
      expect(coord.y, 2.0);
      expect(coord.z, 3.0);
      expect(coord.m, isNull);
      expect(coord.dimension, 3);
    });

    test('4D coordinate', () {
      const coord = GmlCoordinate(1.0, 2.0, 3.0, 4.0);
      expect(coord.dimension, 4);
    });
  });

  group('GmlPoint', () {
    test('creates point with coordinate and srsName', () {
      const point = GmlPoint(
        coordinate: GmlCoordinate(9.0, 48.0),
        srsName: 'EPSG:4326',
      );
      expect(point.coordinate.x, 9.0);
      expect(point.coordinate.y, 48.0);
      expect(point.srsName, 'EPSG:4326');
    });

    test('is a GmlGeometry and GmlNode', () {
      const point = GmlPoint(coordinate: GmlCoordinate(0, 0));
      expect(point, isA<GmlGeometry>());
      expect(point, isA<GmlNode>());
      expect(point, isA<GmlRootContent>());
    });
  });

  group('GmlLineString', () {
    test('creates linestring with coordinates', () {
      const ls = GmlLineString(coordinates: [
        GmlCoordinate(0, 0),
        GmlCoordinate(1, 1),
      ]);
      expect(ls.coordinates, hasLength(2));
    });
  });

  group('GmlPolygon', () {
    test('creates polygon with exterior and interior rings', () {
      const exterior = GmlLinearRing(coordinates: [
        GmlCoordinate(0, 0),
        GmlCoordinate(10, 0),
        GmlCoordinate(10, 10),
        GmlCoordinate(0, 10),
        GmlCoordinate(0, 0),
      ]);
      const hole = GmlLinearRing(coordinates: [
        GmlCoordinate(2, 2),
        GmlCoordinate(8, 2),
        GmlCoordinate(8, 8),
        GmlCoordinate(2, 8),
        GmlCoordinate(2, 2),
      ]);
      const polygon = GmlPolygon(exterior: exterior, interiors: [hole]);
      expect(polygon.exterior.coordinates, hasLength(5));
      expect(polygon.interiors, hasLength(1));
    });

    test('defaults to empty interiors', () {
      const polygon = GmlPolygon(
        exterior: GmlLinearRing(coordinates: []),
      );
      expect(polygon.interiors, isEmpty);
    });
  });

  group('GmlEnvelope', () {
    test('creates envelope with corners', () {
      const env = GmlEnvelope(
        lowerCorner: GmlCoordinate(0, 0),
        upperCorner: GmlCoordinate(10, 10),
        srsName: 'EPSG:4326',
      );
      expect(env.lowerCorner.x, 0);
      expect(env.upperCorner.x, 10);
      expect(env.srsName, 'EPSG:4326');
    });
  });

  group('GmlBox', () {
    test('creates GML 2 bounding box', () {
      const box = GmlBox(
        lowerCorner: GmlCoordinate(5, 5),
        upperCorner: GmlCoordinate(15, 15),
      );
      expect(box.lowerCorner.y, 5);
      expect(box.upperCorner.y, 15);
    });
  });

  group('GmlMultiPoint', () {
    test('creates multi point', () {
      const mp = GmlMultiPoint(points: [
        GmlPoint(coordinate: GmlCoordinate(1, 2)),
        GmlPoint(coordinate: GmlCoordinate(3, 4)),
      ]);
      expect(mp.points, hasLength(2));
    });
  });

  group('GmlFeature', () {
    test('creates feature with properties', () {
      const feature = GmlFeature(
        id: 'feature.1',
        properties: {
          'name': GmlStringProperty('Test'),
          'value': GmlNumericProperty(42),
          'geom': GmlGeometryProperty(
            GmlPoint(coordinate: GmlCoordinate(9, 48)),
          ),
        },
      );
      expect(feature.id, 'feature.1');
      expect(feature.properties, hasLength(3));
      expect(feature.properties['name'], isA<GmlStringProperty>());
      expect(feature.properties['geom'], isA<GmlGeometryProperty>());
    });

    test('defaults to empty properties', () {
      const feature = GmlFeature();
      expect(feature.id, isNull);
      expect(feature.properties, isEmpty);
    });
  });

  group('GmlFeatureCollection', () {
    test('creates collection with features', () {
      const collection = GmlFeatureCollection(
        features: [
          GmlFeature(id: 'f1'),
          GmlFeature(id: 'f2'),
        ],
        boundedBy: GmlEnvelope(
          lowerCorner: GmlCoordinate(0, 0),
          upperCorner: GmlCoordinate(10, 10),
        ),
      );
      expect(collection.features, hasLength(2));
      expect(collection.boundedBy, isNotNull);
    });

    test('defaults to empty', () {
      const collection = GmlFeatureCollection();
      expect(collection.features, isEmpty);
      expect(collection.boundedBy, isNull);
    });

    test('is a GmlRootContent', () {
      const collection = GmlFeatureCollection();
      expect(collection, isA<GmlRootContent>());
    });
  });

  group('GmlPropertyValue', () {
    test('GmlNestedProperty supports nested structures', () {
      const nested = GmlNestedProperty({
        'street': GmlStringProperty('Main St'),
        'number': GmlNumericProperty(42),
        'sub': GmlNestedProperty({
          'zip': GmlStringProperty('12345'),
        }),
      });
      expect(nested.children, hasLength(3));
      expect(nested.children['sub'], isA<GmlNestedProperty>());
    });

    test('GmlRawXmlProperty preserves raw content', () {
      const raw = GmlRawXmlProperty('<custom attr="val">content</custom>');
      expect(raw.xmlContent, contains('custom'));
    });
  });

  group('GmlParseIssue', () {
    test('creates issue with all fields', () {
      const issue = GmlParseIssue(
        severity: GmlIssueSeverity.warning,
        code: 'unknown_element',
        message: 'Unknown element encountered',
        location: '/root/child',
      );
      expect(issue.severity, GmlIssueSeverity.warning);
      expect(issue.code, 'unknown_element');
      expect(issue.location, '/root/child');
    });
  });

  group('GmlParseResult', () {
    test('hasErrors is false when no issues', () {
      const result = GmlParseResult();
      expect(result.hasErrors, isFalse);
      expect(result.document, isNull);
    });

    test('hasErrors is false for warnings only', () {
      const result = GmlParseResult(
        issues: [
          GmlParseIssue(
            severity: GmlIssueSeverity.warning,
            code: 'warn',
            message: 'A warning',
          ),
        ],
      );
      expect(result.hasErrors, isFalse);
    });

    test('hasErrors is true with error issue', () {
      const result = GmlParseResult(
        issues: [
          GmlParseIssue(
            severity: GmlIssueSeverity.error,
            code: 'invalid_xml',
            message: 'Invalid XML',
          ),
        ],
      );
      expect(result.hasErrors, isTrue);
    });
  });

  group('GmlDocument', () {
    test('creates document with geometry root', () {
      const doc = GmlDocument(
        version: GmlVersion.v3_2,
        root: GmlPoint(coordinate: GmlCoordinate(9.0, 48.0)),
      );
      expect(doc.version, GmlVersion.v3_2);
      expect(doc.root, isA<GmlPoint>());
      expect(doc.boundedBy, isNull);
    });

    test('creates document with feature collection root', () {
      const doc = GmlDocument(
        version: GmlVersion.v2_1_2,
        root: GmlFeatureCollection(),
        boundedBy: GmlEnvelope(
          lowerCorner: GmlCoordinate(0, 0),
          upperCorner: GmlCoordinate(10, 10),
        ),
      );
      expect(doc.root, isA<GmlFeatureCollection>());
      expect(doc.boundedBy, isNotNull);
    });

    test('creates document with coverage root', () {
      const doc = GmlDocument(
        version: GmlVersion.v3_2,
        root: GmlRectifiedGridCoverage(),
      );
      expect(doc.root, isA<GmlCoverage>());
    });
  });

  group('GmlUnsupportedNode', () {
    test('stores namespace and local name', () {
      const node = GmlUnsupportedNode(
        namespaceUri: 'http://example.com',
        localName: 'CustomElement',
        rawXml: '<ex:CustomElement/>',
      );
      expect(node.namespaceUri, 'http://example.com');
      expect(node.localName, 'CustomElement');
      expect(node.rawXml, '<ex:CustomElement/>');
    });

    test('namespace is optional', () {
      const node = GmlUnsupportedNode(localName: 'Unknown');
      expect(node.namespaceUri, isNull);
      expect(node.rawXml, isNull);
    });
  });
}
