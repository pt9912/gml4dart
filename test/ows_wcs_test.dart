import 'package:gml4dart/gml4dart.dart';
import 'package:test/test.dart';

void main() {
  group('OWS Exception', () {
    test('detects exception report', () {
      const xml =
          '<ows:ExceptionReport/>';
      expect(isOwsExceptionReport(xml), isTrue);
      expect(
        isOwsExceptionReport('<gml:Point/>'),
        isFalse,
      );
    });

    test('parses exception report', () {
      const xml = '''
<ows:ExceptionReport
    xmlns:ows="http://www.opengis.net/ows/1.1"
    version="1.1.0">
  <ows:Exception exceptionCode="InvalidParameterValue"
                 locator="coverageId">
    <ows:ExceptionText>Coverage not found</ows:ExceptionText>
  </ows:Exception>
  <ows:Exception exceptionCode="NoApplicableCode">
    <ows:ExceptionText>Internal error</ows:ExceptionText>
    <ows:ExceptionText>Contact admin</ows:ExceptionText>
  </ows:Exception>
</ows:ExceptionReport>''';

      final report = parseOwsExceptionReport(xml);
      expect(report, isNotNull);
      expect(report!.version, '1.1.0');
      expect(report.exceptions, hasLength(2));

      expect(
        report.exceptions[0].exceptionCode,
        'InvalidParameterValue',
      );
      expect(
        report.exceptions[0].locator,
        'coverageId',
      );
      expect(
        report.exceptions[0].exceptionTexts,
        ['Coverage not found'],
      );

      expect(
        report.exceptions[1].exceptionTexts,
        hasLength(2),
      );
    });

    test('allMessages formats correctly', () {
      const report = OwsExceptionReport(
        version: '1.1.0',
        exceptions: [
          OwsException(
            exceptionCode: 'Error',
            locator: 'param',
            exceptionTexts: ['msg1'],
          ),
          OwsException(
            exceptionCode: 'NoCode',
            exceptionTexts: ['msg2'],
          ),
        ],
      );

      final msgs = report.allMessages;
      expect(msgs[0], '[Error@param] msg1');
      expect(msgs[1], '[NoCode] msg2');
    });

    test('returns null for non-exception XML', () {
      const xml = '<gml:Point/>';
      expect(parseOwsExceptionReport(xml), isNull);
    });

    test('returns null for invalid XML', () {
      expect(
        parseOwsExceptionReport('<broken'),
        isNull,
      );
    });
  });

  group('WCS Request Builder', () {
    test('builds WCS 2.0 GET URL', () {
      final builder = WcsRequestBuilder(
        baseUrl: 'https://example.com/wcs',
      );
      final url = builder.buildGetCoverageUrl(
        const WcsGetCoverageOptions(
          coverageId: 'LANDSAT8',
          format: 'image/tiff',
          subsets: [
            WcsSubset(
              axis: 'Lat',
              min: '-34',
              max: '-33',
            ),
            WcsSubset(
              axis: 'Long',
              min: '18',
              max: '19',
            ),
          ],
        ),
      );

      expect(url, contains('service=WCS'));
      expect(url, contains('version=2.0.1'));
      expect(url, contains('request=GetCoverage'));
      expect(url, contains('coverageId=LANDSAT8'));
      expect(
        url,
        contains('format=image%2Ftiff'),
      );
      expect(url, contains('subset='));
    });

    test('builds WCS 1.0 URL with coverage param',
        () {
      final builder = WcsRequestBuilder(
        baseUrl: 'https://example.com/wcs',
        version: WcsVersion.v1_0_0,
      );
      final url = builder.buildGetCoverageUrl(
        const WcsGetCoverageOptions(
          coverageId: 'DEM',
        ),
      );

      expect(url, contains('coverage=DEM'));
      expect(url, contains('version=1.0.0'));
    });

    test('builds WCS 2.0 POST XML', () {
      final builder = WcsRequestBuilder(
        baseUrl: 'https://example.com/wcs',
      );
      final xml = builder.buildGetCoverageXml(
        const WcsGetCoverageOptions(
          coverageId: 'TEST',
          format: 'image/tiff',
          subsets: [
            WcsSubset(axis: 'time', value: '2024-01-01'),
            WcsSubset(axis: 'Lat', min: '10', max: '20'),
          ],
        ),
      );

      expect(xml, contains('<wcs:GetCoverage'));
      expect(xml, contains('<wcs:CoverageId>TEST'));
      expect(
        xml,
        contains('<wcs:format>image/tiff'),
      );
      expect(xml, contains('<wcs:DimensionTrim>'));
      expect(xml, contains('<wcs:SlicePoint>'));
      expect(xml, contains('<wcs:TrimLow>'));
    });

    test(
        'throws for XML POST with '
        'WCS 1.0', () {
      final builder = WcsRequestBuilder(
        baseUrl: 'https://example.com/wcs',
        version: WcsVersion.v1_0_0,
      );
      expect(
        () => builder.buildGetCoverageXml(
          const WcsGetCoverageOptions(
            coverageId: 'X',
          ),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('includes range subset', () {
      final builder = WcsRequestBuilder(
        baseUrl: 'https://example.com/wcs',
      );
      final url = builder.buildGetCoverageUrl(
        const WcsGetCoverageOptions(
          coverageId: 'IMG',
          rangeSubset: ['red', 'green', 'blue'],
        ),
      );
      expect(
        url,
        contains('rangeSubset=red%2Cgreen%2Cblue'),
      );
    });
  });

  group('WCS Capabilities Parser', () {
    test('parses WCS 2.0 capabilities', () {
      const xml = '''
<wcs:Capabilities
    xmlns:wcs="http://www.opengis.net/wcs/2.0"
    xmlns:ows="http://www.opengis.net/ows/2.0"
    version="2.0.1">
  <ows:ServiceIdentification>
    <ows:Title>Test WCS</ows:Title>
    <ows:Abstract>A test service</ows:Abstract>
    <ows:ServiceType>WCS</ows:ServiceType>
  </ows:ServiceIdentification>
  <ows:OperationsMetadata>
    <ows:Operation name="GetCapabilities">
      <ows:DCP>
        <ows:HTTP>
          <ows:Get xlink:href="https://example.com/wcs"
                   xmlns:xlink="http://www.w3.org/1999/xlink"/>
        </ows:HTTP>
      </ows:DCP>
    </ows:Operation>
    <ows:Operation name="GetCoverage">
      <ows:DCP>
        <ows:HTTP>
          <ows:Get xlink:href="https://example.com/wcs"
                   xmlns:xlink="http://www.w3.org/1999/xlink"/>
          <ows:Post xlink:href="https://example.com/wcs"
                    xmlns:xlink="http://www.w3.org/1999/xlink"/>
        </ows:HTTP>
      </ows:DCP>
    </ows:Operation>
  </ows:OperationsMetadata>
  <wcs:Contents>
    <wcs:CoverageSummary>
      <wcs:CoverageId>LANDSAT8</wcs:CoverageId>
      <wcs:CoverageSubtype>RectifiedGridCoverage</wcs:CoverageSubtype>
      <ows:Title>Landsat 8</ows:Title>
      <ows:WGS84BoundingBox>
        <ows:LowerCorner>-180 -90</ows:LowerCorner>
        <ows:UpperCorner>180 90</ows:UpperCorner>
      </ows:WGS84BoundingBox>
    </wcs:CoverageSummary>
    <wcs:CoverageSummary>
      <wcs:CoverageId>DEM</wcs:CoverageId>
      <wcs:CoverageSubtype>RectifiedGridCoverage</wcs:CoverageSubtype>
    </wcs:CoverageSummary>
  </wcs:Contents>
</wcs:Capabilities>''';

      final caps = WcsCapabilitiesParser.parse(xml);

      expect(caps.version, '2.0.1');
      expect(caps.serviceIdentification, isNotNull);
      expect(
        caps.serviceIdentification!.title,
        'Test WCS',
      );

      expect(caps.operations, hasLength(2));
      expect(
        caps.operations[1].name,
        'GetCoverage',
      );
      expect(
        caps.operations[1].getUrl,
        'https://example.com/wcs',
      );
      expect(
        caps.operations[1].postUrl,
        'https://example.com/wcs',
      );

      expect(caps.coverages, hasLength(2));
      expect(
        caps.coverages[0].coverageId,
        'LANDSAT8',
      );
      expect(
        caps.coverages[0].coverageSubtype,
        'RectifiedGridCoverage',
      );
      expect(caps.coverages[0].title, 'Landsat 8');
      expect(
        caps.coverages[0].wgs84BoundingBox,
        isNotNull,
      );
      expect(
        caps.coverages[0]
            .wgs84BoundingBox!
            .lowerCorner,
        [-180.0, -90.0],
      );
    });
  });

  group('Coverage Generator', () {
    test('generates RectifiedGridCoverage XML', () {
      const cov = GmlRectifiedGridCoverage(
        id: 'test_cov',
        boundedBy: GmlEnvelope(
          lowerCorner: GmlCoordinate(0, 0),
          upperCorner: GmlCoordinate(10, 10),
          srsName: 'EPSG:4326',
        ),
        domainSet: GmlRectifiedGrid(
          dimension: 2,
          limits: GmlGridEnvelope(
            low: [0, 0],
            high: [99, 99],
          ),
          axisLabels: ['x', 'y'],
          origin: [0.0, 0.0],
          offsetVectors: [
            [0.1, 0.0],
            [0.0, 0.1],
          ],
        ),
        rangeSet: GmlRangeSet(data: '1 2 3'),
        rangeType: GmlRangeType(fields: [
          GmlRangeField(
            name: 'elevation',
            uom: 'm',
          ),
        ]),
      );

      final xml = CoverageGenerator.generate(cov);

      expect(
        xml,
        contains('RectifiedGridCoverage'),
      );
      expect(xml, contains('gml:id="test_cov"'));
      expect(xml, contains('EPSG:4326'));
      expect(xml, contains('<gml:low>0 0</gml:low>'));
      expect(
        xml,
        contains('<gml:high>99 99</gml:high>'),
      );
      expect(xml, contains('axisLabels'));
      expect(xml, contains('offsetVector'));
      expect(xml, contains('tupleList'));
      expect(
        xml,
        contains('swe:field name="elevation"'),
      );
      expect(xml, contains('swe:uom code="m"'));
    });

    test(
        'round-trips: generate → parse '
        '→ generate', () {
      const cov = GmlRectifiedGridCoverage(
        id: 'rt_test',
        domainSet: GmlRectifiedGrid(
          dimension: 2,
          limits: GmlGridEnvelope(
            low: [0, 0],
            high: [9, 9],
          ),
          origin: [5.0, 50.0],
          offsetVectors: [
            [0.01, 0.0],
            [0.0, -0.01],
          ],
        ),
        rangeSet: GmlRangeSet(data: '42'),
      );

      final xml1 = CoverageGenerator.generate(cov);
      final parsed = GmlParser.parseXmlString(xml1);
      expect(parsed.hasErrors, isFalse);
      expect(
        parsed.document!.root,
        isA<GmlRectifiedGridCoverage>(),
      );

      final cov2 = parsed.document!.root
          as GmlRectifiedGridCoverage;
      expect(cov2.id, 'rt_test');
      expect(cov2.domainSet!.origin, [5.0, 50.0]);
    });

    test('generates MultiPointCoverage XML', () {
      const cov = GmlMultiPointCoverage(
        id: 'mp1',
        domainSet: GmlMultiPoint(points: [
          GmlPoint(coordinate: GmlCoordinate(1, 2)),
          GmlPoint(coordinate: GmlCoordinate(3, 4)),
        ]),
        rangeSet: GmlRangeSet(data: '100 200'),
      );

      final xml = CoverageGenerator.generate(cov);
      expect(
        xml,
        contains('MultiPointCoverage'),
      );
      expect(xml, contains('pointMember'));
      expect(xml, contains('1.0 2.0'));
      expect(xml, contains('3.0 4.0'));
    });

    test('generates with file reference', () {
      const cov = GmlGridCoverage(
        id: 'gc1',
        domainSet: GmlGrid(
          dimension: 2,
          limits: GmlGridEnvelope(
            low: [0, 0],
            high: [49, 49],
          ),
        ),
        rangeSet: GmlRangeSet(
          file: GmlFileReference(
            fileName: 'data.tif',
            fileStructure: 'Record Interleaved',
          ),
        ),
      );

      final xml = CoverageGenerator.generate(cov);
      expect(xml, contains('GridCoverage'));
      expect(
        xml,
        contains('<gml:fileName>data.tif'),
      );
      expect(
        xml,
        contains('Record Interleaved'),
      );
    });
  });
}
