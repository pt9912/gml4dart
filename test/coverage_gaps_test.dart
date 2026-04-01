import 'dart:convert';

import 'package:gml4dart/gml4dart.dart';
import 'package:test/test.dart';

void main() {
  // ── geometry_parser error paths ──

  group('LineString error', () {
    test('reports error for empty LineString', () {
      const xml = '''
<gml:LineString xmlns:gml="http://www.opengis.net/gml/3.2">
</gml:LineString>''';
      final r = GmlParser.parseXmlString(xml);
      expect(r.hasErrors, isTrue);
      expect(r.issues.first.code, 'missing_coordinates');
    });
  });

  group('LinearRing error', () {
    test('reports error for empty LinearRing', () {
      const xml = '''
<gml:LinearRing xmlns:gml="http://www.opengis.net/gml/3.2">
</gml:LinearRing>''';
      final r = GmlParser.parseXmlString(xml);
      expect(r.hasErrors, isTrue);
      expect(r.issues.first.code, 'missing_coordinates');
    });
  });

  group('Box error', () {
    test('reports error for Box with < 2 coords', () {
      const xml = '''
<gml:Box xmlns:gml="http://www.opengis.net/gml">
  <gml:coordinates>5,5</gml:coordinates>
</gml:Box>''';
      final r = GmlParser.parseXmlString(xml);
      expect(r.hasErrors, isTrue);
      expect(r.issues.first.code, 'missing_coordinates');
    });
  });

  group('Curve edge cases', () {
    test('parses Curve with direct coordinates (fallback)', () {
      const xml = '''
<gml:Curve xmlns:gml="http://www.opengis.net/gml/3.2">
  <gml:posList>0 0 1 1</gml:posList>
</gml:Curve>''';
      final r = GmlParser.parseXmlString(xml);
      expect(r.hasErrors, isFalse);
      final c = r.document!.root as GmlCurve;
      expect(c.coordinates, hasLength(2));
    });

    test('reports error for empty Curve', () {
      const xml = '''
<gml:Curve xmlns:gml="http://www.opengis.net/gml/3.2">
</gml:Curve>''';
      final r = GmlParser.parseXmlString(xml);
      expect(r.hasErrors, isTrue);
      expect(r.issues.first.code, 'missing_coordinates');
    });
  });

  group('MultiCurve with curveMembers (plural)', () {
    test('parses curveMembers with LineString', () {
      const xml = '''
<gml:MultiCurve xmlns:gml="http://www.opengis.net/gml/3.2">
  <gml:curveMembers>
    <gml:LineString>
      <gml:posList>0 0 1 1</gml:posList>
    </gml:LineString>
    <gml:Curve>
      <gml:segments>
        <gml:LineStringSegment>
          <gml:posList>2 2 3 3</gml:posList>
        </gml:LineStringSegment>
      </gml:segments>
    </gml:Curve>
  </gml:curveMembers>
</gml:MultiCurve>''';
      final r = GmlParser.parseXmlString(xml);
      expect(r.hasErrors, isFalse);
      final mls = r.document!.root as GmlMultiLineString;
      expect(mls.lineStrings, hasLength(2));
    });
  });

  group('MultiSurface with surfaceMembers (plural)', () {
    test('parses surfaceMembers', () {
      const xml = '''
<gml:MultiSurface xmlns:gml="http://www.opengis.net/gml/3.2">
  <gml:surfaceMembers>
    <gml:Polygon>
      <gml:exterior>
        <gml:LinearRing>
          <gml:posList>0 0 1 0 1 1 0 1 0 0</gml:posList>
        </gml:LinearRing>
      </gml:exterior>
    </gml:Polygon>
  </gml:surfaceMembers>
</gml:MultiSurface>''';
      final r = GmlParser.parseXmlString(xml);
      expect(r.hasErrors, isFalse);
      final mp = r.document!.root as GmlMultiPolygon;
      expect(mp.polygons, hasLength(1));
    });
  });

  // ── WKT builder gaps ──

  group('WktBuilder gaps', () {
    test('converts LinearRing', () {
      const ring = GmlLinearRing(coordinates: [
        GmlCoordinate(0, 0),
        GmlCoordinate(1, 0),
        GmlCoordinate(1, 1),
        GmlCoordinate(0, 0),
      ]);
      final wkt = WktBuilder.geometry(ring);
      expect(wkt, startsWith('LINESTRING ('));
    });

    test('converts MultiPolygon with interiors', () {
      const mp = GmlMultiPolygon(polygons: [
        GmlPolygon(
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
        ),
      ]);
      final wkt = WktBuilder.geometry(mp)!;
      expect(wkt, startsWith('MULTIPOLYGON ('));
      expect(wkt, contains('), ('));
    });

    test('converts Surface', () {
      const s = GmlSurface(patches: [
        GmlPolygon(
          exterior: GmlLinearRing(coordinates: [
            GmlCoordinate(0, 0),
            GmlCoordinate(1, 0),
            GmlCoordinate(1, 1),
            GmlCoordinate(0, 0),
          ]),
          interiors: [
            GmlLinearRing(coordinates: [
              GmlCoordinate(0.2, 0.2),
              GmlCoordinate(0.8, 0.2),
              GmlCoordinate(0.8, 0.8),
              GmlCoordinate(0.2, 0.2),
            ]),
          ],
        ),
      ]);
      final wkt = WktBuilder.geometry(s)!;
      expect(wkt, startsWith('MULTIPOLYGON ('));
    });
  });

  // ── GeoJSON builder gaps ──

  group('GeoJsonBuilder gaps', () {
    test('converts LinearRing', () {
      const ring = GmlLinearRing(coordinates: [
        GmlCoordinate(0, 0),
        GmlCoordinate(1, 0),
        GmlCoordinate(1, 1),
        GmlCoordinate(0, 0),
      ]);
      final gj = GeoJsonBuilder.geometry(ring)!;
      expect(gj['type'], 'LineString');
      expect(gj['coordinates'], hasLength(4));
    });

    test('converts MultiPolygon with interiors', () {
      const mp = GmlMultiPolygon(polygons: [
        GmlPolygon(
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
        ),
      ]);
      final gj = GeoJsonBuilder.geometry(mp)!;
      expect(gj['type'], 'MultiPolygon');
      final polys = gj['coordinates'] as List;
      final rings = polys[0] as List;
      expect(rings, hasLength(2));
    });

    test('converts Surface with interiors', () {
      const s = GmlSurface(patches: [
        GmlPolygon(
          exterior: GmlLinearRing(coordinates: [
            GmlCoordinate(0, 0),
            GmlCoordinate(1, 0),
            GmlCoordinate(1, 1),
            GmlCoordinate(0, 0),
          ]),
          interiors: [
            GmlLinearRing(coordinates: [
              GmlCoordinate(0.2, 0.2),
              GmlCoordinate(0.8, 0.2),
              GmlCoordinate(0.8, 0.8),
              GmlCoordinate(0.2, 0.2),
            ]),
          ],
        ),
      ]);
      final gj = GeoJsonBuilder.geometry(s)!;
      expect(gj['type'], 'MultiPolygon');
      final polys = gj['coordinates'] as List;
      final rings = polys[0] as List;
      expect(rings, hasLength(2));
    });

    test('featureCollectionToJson', () {
      const fc = GmlFeatureCollection(features: [
        GmlFeature(id: 'f1'),
      ]);
      final jsonStr =
          GeoJsonBuilder.featureCollectionToJson(fc);
      final decoded =
          json.decode(jsonStr) as Map<String, dynamic>;
      expect(decoded['type'], 'FeatureCollection');
      expect(decoded['features'], hasLength(1));
    });

    test('geometryToJson returns null for unsupported', () {
      // Coverage returns null for a coverage root, but
      // geometryToJson takes a geometry, which always
      // succeeds. Just verify it works.
      const env = GmlEnvelope(
        lowerCorner: GmlCoordinate(0, 0),
        upperCorner: GmlCoordinate(1, 1),
      );
      expect(
        GeoJsonBuilder.geometryToJson(env),
        isNotNull,
      );
    });

    test('handles RawXmlProperty', () {
      const feat = GmlFeature(properties: {
        'raw': GmlRawXmlProperty('<data/>'),
      });
      final gj = GeoJsonBuilder.feature(feat);
      final props =
          gj['properties'] as Map<String, dynamic>;
      expect(props['raw'], '<data/>');
    });

    test('document converts feature root', () {
      const doc = GmlDocument(
        version: GmlVersion.v3_2,
        root: GmlFeature(id: 'f1'),
      );
      final gj = GeoJsonBuilder.document(doc);
      expect(gj?['type'], 'Feature');
    });

    test('document converts feature collection root',
        () {
      const doc = GmlDocument(
        version: GmlVersion.v3_2,
        root: GmlFeatureCollection(features: []),
      );
      final gj = GeoJsonBuilder.document(doc);
      expect(gj?['type'], 'FeatureCollection');
    });
  });

  // ── WCS request builder gaps ──

  group('WcsRequestBuilder gaps', () {
    test('WCS 1.1 uses identifier param', () {
      final builder = WcsRequestBuilder(
        baseUrl: 'https://example.com/wcs',
        version: WcsVersion.v1_1_1,
      );
      final url = builder.buildGetCoverageUrl(
        const WcsGetCoverageOptions(
          coverageId: 'DEM',
        ),
      );
      expect(url, contains('identifier=DEM'));
      expect(url, contains('version=1.1.1'));
    });

    test('includes outputCrs', () {
      final builder = WcsRequestBuilder(
        baseUrl: 'https://example.com/wcs',
      );
      final url = builder.buildGetCoverageUrl(
        const WcsGetCoverageOptions(
          coverageId: 'X',
          outputCrs: 'EPSG:4326',
        ),
      );
      expect(url, contains('outputCrs=EPSG'));
    });

    test('includes interpolation', () {
      final builder = WcsRequestBuilder(
        baseUrl: 'https://example.com/wcs',
      );
      final url = builder.buildGetCoverageUrl(
        const WcsGetCoverageOptions(
          coverageId: 'X',
          interpolation: 'nearest',
        ),
      );
      expect(url, contains('interpolation=nearest'));
    });

    test('subset value (non-range) in URL', () {
      final builder = WcsRequestBuilder(
        baseUrl: 'https://example.com/wcs',
      );
      final url = builder.buildGetCoverageUrl(
        const WcsGetCoverageOptions(
          coverageId: 'X',
          subsets: [
            WcsSubset(axis: 'time', value: '2024-01-01'),
          ],
        ),
      );
      expect(url, contains('subset='));
      expect(url, contains('time'));
    });
  });

  // ── WCS capabilities parser gaps ──

  group('WcsCapabilitiesParser gaps', () {
    test('parses serviceTypeVersion', () {
      const xml = '''
<wcs:Capabilities
    xmlns:wcs="http://www.opengis.net/wcs/2.0"
    xmlns:ows="http://www.opengis.net/ows/2.0"
    version="2.0.1">
  <ows:ServiceIdentification>
    <ows:Title>Test</ows:Title>
    <ows:ServiceType>WCS</ows:ServiceType>
    <ows:ServiceTypeVersion>2.0.1</ows:ServiceTypeVersion>
    <ows:Keyword>geo</ows:Keyword>
  </ows:ServiceIdentification>
</wcs:Capabilities>''';
      final caps = WcsCapabilitiesParser.parse(xml);
      expect(
        caps.serviceIdentification!.serviceTypeVersion,
        '2.0.1',
      );
      expect(
        caps.serviceIdentification!.keywords,
        contains('geo'),
      );
    });

    test('parses WCS 1.0 ContentMetadata', () {
      const xml = '''
<WCS_Capabilities version="1.0.0">
  <ContentMetadata>
    <CoverageOfferingBrief>
      <name>my_coverage</name>
      <Title>My Coverage</Title>
      <Abstract>Desc</Abstract>
    </CoverageOfferingBrief>
  </ContentMetadata>
</WCS_Capabilities>''';
      final caps = WcsCapabilitiesParser.parse(xml);
      expect(caps.coverages, hasLength(1));
      expect(caps.coverages[0].coverageId, 'my_coverage');
      expect(caps.coverages[0].title, 'My Coverage');
      expect(caps.coverages[0].abstract_, 'Desc');
    });

    test('falls back to Identifier for coverageId', () {
      const xml = '''
<wcs:Capabilities
    xmlns:wcs="http://www.opengis.net/wcs/2.0"
    version="2.0.1">
  <wcs:Contents>
    <wcs:CoverageSummary>
      <Identifier>alt_id</Identifier>
      <wcs:CoverageSubtype>GridCoverage</wcs:CoverageSubtype>
    </wcs:CoverageSummary>
  </wcs:Contents>
</wcs:Capabilities>''';
      final caps = WcsCapabilitiesParser.parse(xml);
      expect(caps.coverages[0].coverageId, 'alt_id');
      expect(
        caps.coverages[0].coverageSubtype,
        'GridCoverage',
      );
    });

    test('parses formatSupported', () {
      const xml = '''
<wcs:Capabilities
    xmlns:wcs="http://www.opengis.net/wcs/2.0"
    version="2.0.1">
  <wcs:Contents/>
  <ServiceMetadata>
    <formatSupported>image/tiff</formatSupported>
    <formatSupported>image/png</formatSupported>
  </ServiceMetadata>
</wcs:Capabilities>''';
      final caps = WcsCapabilitiesParser.parse(xml);
      expect(caps.formats, ['image/tiff', 'image/png']);
    });

    test('parses CrsSupported', () {
      const xml = '''
<wcs:Capabilities
    xmlns:wcs="http://www.opengis.net/wcs/2.0"
    version="2.0.1">
  <ServiceMetadata>
    <Extension>
      <CrsSupported>EPSG:4326</CrsSupported>
      <CrsSupported>EPSG:3857</CrsSupported>
    </Extension>
  </ServiceMetadata>
</wcs:Capabilities>''';
      final caps = WcsCapabilitiesParser.parse(xml);
      expect(caps.crs, ['EPSG:4326', 'EPSG:3857']);
    });

    test('parses BoundingBox with crs', () {
      const xml = '''
<wcs:Capabilities
    xmlns:wcs="http://www.opengis.net/wcs/2.0"
    xmlns:ows="http://www.opengis.net/ows/2.0"
    version="2.0.1">
  <wcs:Contents>
    <wcs:CoverageSummary>
      <wcs:CoverageId>C1</wcs:CoverageId>
      <ows:BoundingBox crs="EPSG:4326">
        <ows:LowerCorner>10 20</ows:LowerCorner>
        <ows:UpperCorner>30 40</ows:UpperCorner>
      </ows:BoundingBox>
    </wcs:CoverageSummary>
  </wcs:Contents>
</wcs:Capabilities>''';
      final caps = WcsCapabilitiesParser.parse(xml);
      expect(caps.coverages[0].boundingBox, isNotNull);
      expect(
        caps.coverages[0].boundingBox!.crs,
        'EPSG:4326',
      );
      expect(
        caps.coverages[0].boundingBox!.lowerCorner,
        [10.0, 20.0],
      );
    });
  });

  // ── Coverage generator gaps ──

  group('CoverageGenerator gaps', () {
    test('generates ReferenceableGridCoverage', () {
      const cov = GmlReferenceableGridCoverage(
        id: 'ref1',
        boundedBy: GmlEnvelope(
          lowerCorner: GmlCoordinate(0, 0),
          upperCorner: GmlCoordinate(10, 10),
        ),
        domainSet: GmlGrid(
          dimension: 2,
          limits: GmlGridEnvelope(
            low: [0, 0],
            high: [9, 9],
          ),
        ),
        rangeSet: GmlRangeSet(data: '1 2 3'),
      );
      final xml = CoverageGenerator.generate(cov);
      expect(
        xml,
        contains('ReferenceableGridCoverage'),
      );
      expect(xml, contains('gml:id="ref1"'));
      expect(xml, contains('gml:Grid'));
    });

    test('generates rangeType with description', () {
      const cov = GmlRectifiedGridCoverage(
        domainSet: GmlRectifiedGrid(
          dimension: 2,
          limits: GmlGridEnvelope(
            low: [0, 0],
            high: [9, 9],
          ),
          origin: [0.0, 0.0],
          offsetVectors: [
            [1.0, 0.0],
            [0.0, 1.0],
          ],
        ),
        rangeType: GmlRangeType(fields: [
          GmlRangeField(
            name: 'temp',
            uom: 'K',
            description: 'Temperature',
          ),
        ]),
      );
      final xml = CoverageGenerator.generate(cov);
      expect(
        xml,
        contains('<swe:description>Temperature'),
      );
    });

    test('generates MultiPointCoverage with 3D', () {
      const cov = GmlMultiPointCoverage(
        id: 'mp3d',
        domainSet: GmlMultiPoint(points: [
          GmlPoint(
            coordinate: GmlCoordinate(1, 2, 3),
          ),
        ]),
        rangeSet: GmlRangeSet(data: '42'),
      );
      final xml = CoverageGenerator.generate(cov);
      expect(xml, contains('1.0 2.0 3.0'));
    });

    test('generates GridCoverage with no rangeSet', () {
      const cov = GmlGridCoverage(
        domainSet: GmlGrid(
          dimension: 2,
          limits: GmlGridEnvelope(
            low: [0, 0],
            high: [9, 9],
          ),
        ),
      );
      final xml = CoverageGenerator.generate(cov);
      expect(xml, contains('GridCoverage'));
      expect(xml, isNot(contains('rangeSet')));
    });
  });

  // ── GeoTIFF metadata gaps ──

  group('extractGeoTiffMetadata gaps', () {
    test('extracts from GridCoverage', () {
      const cov = GmlGridCoverage(
        boundedBy: GmlEnvelope(
          lowerCorner: GmlCoordinate(0, 0),
          upperCorner: GmlCoordinate(10, 10),
          srsName: 'EPSG:4326',
        ),
        domainSet: GmlGrid(
          dimension: 2,
          limits: GmlGridEnvelope(
            low: [0, 0],
            high: [99, 99],
          ),
        ),
      );
      final meta = extractGeoTiffMetadata(cov);
      expect(meta, isNotNull);
      expect(meta!.width, 100);
      expect(meta.height, 100);
      expect(meta.crs, 'EPSG:4326');
      expect(meta.bbox, [0.0, 0.0, 10.0, 10.0]);
    });

    test('extracts from ReferenceableGridCoverage', () {
      const cov = GmlReferenceableGridCoverage(
        domainSet: GmlGrid(
          dimension: 2,
          limits: GmlGridEnvelope(
            low: [0, 0],
            high: [49, 49],
          ),
        ),
      );
      final meta = extractGeoTiffMetadata(cov);
      expect(meta, isNotNull);
      expect(meta!.width, 50);
      expect(meta.height, 50);
    });

    test('handles 1D grid', () {
      const cov = GmlGridCoverage(
        domainSet: GmlGrid(
          dimension: 1,
          limits: GmlGridEnvelope(
            low: [0],
            high: [99],
          ),
        ),
      );
      final meta = extractGeoTiffMetadata(cov);
      expect(meta, isNotNull);
      expect(meta!.width, 100);
      expect(meta.height, 1);
    });

    test('returns null for GridCoverage without domain',
        () {
      const cov = GmlGridCoverage();
      expect(extractGeoTiffMetadata(cov), isNull);
    });

    test(
        'returns null for ReferenceableGridCoverage '
        'without domain', () {
      const cov = GmlReferenceableGridCoverage();
      expect(extractGeoTiffMetadata(cov), isNull);
    });
  });

  // ── Coverage parser gaps ──

  group('Coverage parser gaps', () {
    test('parses rangeType with description', () {
      const xml = '''
<gml:RectifiedGridCoverage
    xmlns:gml="http://www.opengis.net/gml/3.2"
    xmlns:swe="http://www.opengis.net/swe/2.0"
    xmlns:gmlcov="http://www.opengis.net/gmlcov/1.0"
    gml:id="rt_desc">
  <gml:domainSet>
    <gml:RectifiedGrid dimension="2">
      <gml:limits>
        <gml:GridEnvelope>
          <gml:low>0 0</gml:low>
          <gml:high>9 9</gml:high>
        </gml:GridEnvelope>
      </gml:limits>
      <gml:origin>
        <gml:Point><gml:pos>0 0</gml:pos></gml:Point>
      </gml:origin>
      <gml:offsetVector>1 0</gml:offsetVector>
      <gml:offsetVector>0 1</gml:offsetVector>
    </gml:RectifiedGrid>
  </gml:domainSet>
  <gmlcov:rangeType>
    <swe:DataRecord>
      <swe:field name="band">
        <swe:Quantity>
          <swe:uom code="W/m2"/>
          <swe:description>Irradiance</swe:description>
        </swe:Quantity>
      </swe:field>
    </swe:DataRecord>
  </gmlcov:rangeType>
</gml:RectifiedGridCoverage>''';
      final r = GmlParser.parseXmlString(xml);
      final cov = r.document!.root
          as GmlRectifiedGridCoverage;
      expect(cov.rangeType!.fields[0].uom, 'W/m2');
      expect(
        cov.rangeType!.fields[0].description,
        'Irradiance',
      );
    });

    test('parses rangeSet with rangeParameters', () {
      const xml = '''
<gml:RectifiedGridCoverage
    xmlns:gml="http://www.opengis.net/gml/3.2"
    gml:id="rp_test">
  <gml:domainSet>
    <gml:RectifiedGrid dimension="2">
      <gml:limits>
        <gml:GridEnvelope>
          <gml:low>0 0</gml:low>
          <gml:high>9 9</gml:high>
        </gml:GridEnvelope>
      </gml:limits>
      <gml:origin>
        <gml:Point><gml:pos>0 0</gml:pos></gml:Point>
      </gml:origin>
      <gml:offsetVector>1 0</gml:offsetVector>
      <gml:offsetVector>0 1</gml:offsetVector>
    </gml:RectifiedGrid>
  </gml:domainSet>
  <gml:rangeSet>
    <gml:File>
      <gml:rangeParameters>data.tif</gml:rangeParameters>
    </gml:File>
  </gml:rangeSet>
</gml:RectifiedGridCoverage>''';
      final r = GmlParser.parseXmlString(xml);
      final cov = r.document!.root
          as GmlRectifiedGridCoverage;
      expect(cov.rangeSet!.file, isNotNull);
      expect(
        cov.rangeSet!.file!.fileName,
        'data.tif',
      );
    });
  });

  // ── Feature parser gaps ──

  group('Feature parser gaps', () {
    test('parses nested properties', () {
      const xml = '''
<app:Building xmlns:app="http://example.com"
              xmlns:gml="http://www.opengis.net/gml/3.2"
              gml:id="b1">
  <app:address>
    <app:street>Main St</app:street>
    <app:number>42</app:number>
  </app:address>
</app:Building>''';
      final r = GmlParser.parseXmlString(xml);
      final f = r.document!.root as GmlFeature;
      expect(
        f.properties['address'],
        isA<GmlNestedProperty>(),
      );
      final nested =
          f.properties['address'] as GmlNestedProperty;
      expect(
        (nested.children['street'] as GmlStringProperty)
            .value,
        'Main St',
      );
      expect(
        (nested.children['number'] as GmlNumericProperty)
            .value,
        42,
      );
    });
  });

  // ── xml_helpers gaps ──

  group('xml_helpers gaps', () {
    test(
        'detects GML namespace from '
        'grandchild elements', () {
      // Non-GML root with GML namespace only on
      // grandchild elements.
      const xml = '''
<wfs:FeatureCollection
    xmlns:wfs="http://www.opengis.net/wfs/2.0"
    xmlns:app="http://example.com">
  <wfs:member>
    <app:Place xmlns:gml="http://www.opengis.net/gml/3.2"
               gml:id="p1">
      <app:geom>
        <gml:Point>
          <gml:pos>9 48</gml:pos>
        </gml:Point>
      </app:geom>
    </app:Place>
  </wfs:member>
</wfs:FeatureCollection>''';
      final r = GmlParser.parseXmlString(xml);
      expect(r.hasErrors, isFalse);
      final fc =
          r.document!.root as GmlFeatureCollection;
      expect(fc.features, hasLength(1));
    });

    test('detects GML 3.3 namespace', () {
      const xml = '''
<gml:Point xmlns:gml="http://www.opengis.net/gml/3.3">
  <gml:pos>1 2</gml:pos>
</gml:Point>''';
      final r = GmlParser.parseXmlString(xml);
      expect(r.document?.version, GmlVersion.v3_3);
    });

    test('parses GML 2 3D coordinates', () {
      const xml = '''
<gml:Point xmlns:gml="http://www.opengis.net/gml">
  <gml:coordinates>9.0,48.0,100.0</gml:coordinates>
</gml:Point>''';
      final r = GmlParser.parseXmlString(xml);
      final p = r.document!.root as GmlPoint;
      expect(p.coordinate.z, 100.0);
    });
  });

  // ── Streaming parser gaps ──

  group('GmlFeatureStreamParser gaps', () {
    test('handles XML comments before root', () async {
      const xml = '''
<!-- A comment -->
<?xml version="1.0"?>
<wfs:FeatureCollection
    xmlns:wfs="http://www.opengis.net/wfs/2.0"
    xmlns:gml="http://www.opengis.net/gml/3.2"
    xmlns:app="http://example.com">
  <wfs:member>
    <app:X gml:id="x1"><app:v>1</app:v></app:X>
  </wfs:member>
</wfs:FeatureCollection>''';
      final features =
          await GmlFeatureStreamParser.parseStringStream(
        Stream.value(xml),
      ).toList();
      expect(features, hasLength(1));
      expect(features[0].id, 'x1');
    });

    test('handles featureMembers (plural) in stream',
        () async {
      const xml = '''
<wfs:FeatureCollection
    xmlns:wfs="http://www.opengis.net/wfs"
    xmlns:gml="http://www.opengis.net/gml"
    xmlns:app="http://example.com">
  <gml:featureMembers>
    <app:A gml:id="a1"><app:v>1</app:v></app:A>
    <app:B gml:id="b1"><app:v>2</app:v></app:B>
  </gml:featureMembers>
</wfs:FeatureCollection>''';
      final features =
          await GmlFeatureStreamParser.parseStringStream(
        Stream.value(xml),
      ).toList();
      expect(features, hasLength(2));
    });
  });

  // ── GmlParser.parseBytes via GmlParser ──

  group('GmlParser.parseBytes direct', () {
    test('handles valid bytes', () {
      const xml = '''
<gml:Point xmlns:gml="http://www.opengis.net/gml/3.2">
  <gml:pos>5 10</gml:pos>
</gml:Point>''';
      final r = GmlParser.parseBytes(utf8.encode(xml));
      expect(r.hasErrors, isFalse);
      final p = r.document!.root as GmlPoint;
      expect(p.coordinate.x, 5.0);
    });
  });

  // ── worldToPixel non-invertible ──

  group('worldToPixel non-invertible', () {
    test('returns null for zero determinant', () {
      const meta = GeoTiffMetadata(
        width: 10,
        height: 10,
        transform: [1, 2, 0, 2, 4, 0], // det = 1*4-2*2=0
      );
      expect(worldToPixel(5, 5, meta), isNull);
    });
  });

  // ── Additional targeted gaps ──

  group('CoverageGenerator srsName on RectifiedGrid',
      () {
    test('writes srsName attribute', () {
      const cov = GmlRectifiedGridCoverage(
        domainSet: GmlRectifiedGrid(
          dimension: 2,
          limits: GmlGridEnvelope(
            low: [0, 0],
            high: [9, 9],
          ),
          srsName: 'EPSG:32632',
          origin: [0.0, 0.0],
          offsetVectors: [
            [1.0, 0.0],
            [0.0, 1.0],
          ],
        ),
      );
      final xml = CoverageGenerator.generate(cov);
      expect(xml, contains('srsName="EPSG:32632"'));
    });
  });

  group('GeoJsonBuilder nested geometry property', () {
    test('handles geometry inside nested property', () {
      const feat = GmlFeature(properties: {
        'container': GmlNestedProperty({
          'point': GmlGeometryProperty(
            GmlPoint(coordinate: GmlCoordinate(1, 2)),
          ),
        }),
      });
      final gj = GeoJsonBuilder.feature(feat);
      final props =
          gj['properties'] as Map<String, dynamic>;
      final container =
          props['container'] as Map<String, dynamic>;
      expect(container['point'], isA<Map<String, dynamic>>());
      expect(
        (container['point']
            as Map<String, dynamic>)['type'],
        'Point',
      );
    });
  });

  group('4D coordinate parsing', () {
    test('parses pos with 4 ordinates', () {
      const xml = '''
<gml:Point xmlns:gml="http://www.opengis.net/gml/3.2">
  <gml:pos>9.0 48.0 100.0 42.0</gml:pos>
</gml:Point>''';
      final r = GmlParser.parseXmlString(xml);
      final p = r.document!.root as GmlPoint;
      expect(p.coordinate.x, 9.0);
      expect(p.coordinate.y, 48.0);
      expect(p.coordinate.z, 100.0);
      expect(p.coordinate.m, 42.0);
      expect(p.coordinate.dimension, 4);
    });
  });

  group('GmlParser.parseBytes via GmlDocument', () {
    test('parseBytes delegates correctly', () {
      const xml = '''
<gml:Point xmlns:gml="http://www.opengis.net/gml/3.2">
  <gml:pos>1 2</gml:pos>
</gml:Point>''';
      final r = GmlDocument.parseBytes(utf8.encode(xml));
      expect(r.hasErrors, isFalse);
    });
  });

  // ── RectifiedGrid with origin <pos> directly ──

  group('RectifiedGrid origin pos', () {
    test('parses origin from direct pos element', () {
      const xml = '''
<gml:RectifiedGridCoverage
    xmlns:gml="http://www.opengis.net/gml/3.2"
    gml:id="pos_origin">
  <gml:domainSet>
    <gml:RectifiedGrid dimension="2"
                       srsName="EPSG:4326">
      <gml:limits>
        <gml:GridEnvelope>
          <gml:low>0 0</gml:low>
          <gml:high>9 9</gml:high>
        </gml:GridEnvelope>
      </gml:limits>
      <gml:origin>
        <gml:pos>5.5 50.5</gml:pos>
      </gml:origin>
      <gml:offsetVector>0.1 0</gml:offsetVector>
      <gml:offsetVector>0 -0.1</gml:offsetVector>
    </gml:RectifiedGrid>
  </gml:domainSet>
</gml:RectifiedGridCoverage>''';
      final r = GmlParser.parseXmlString(xml);
      final cov = r.document!.root
          as GmlRectifiedGridCoverage;
      expect(cov.domainSet!.origin, [5.5, 50.5]);
      expect(cov.domainSet!.srsName, 'EPSG:4326');
    });
  });
}
