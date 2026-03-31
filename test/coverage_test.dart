import 'package:gml4dart/gml4dart.dart';
import 'package:test/test.dart';

void main() {
  group('RectifiedGridCoverage', () {
    test('parses complete coverage', () {
      const xml = '''
<gml:RectifiedGridCoverage
    xmlns:gml="http://www.opengis.net/gml/3.2"
    gml:id="cov1">
  <gml:boundedBy>
    <gml:Envelope srsName="EPSG:4326">
      <gml:lowerCorner>0 0</gml:lowerCorner>
      <gml:upperCorner>10 10</gml:upperCorner>
    </gml:Envelope>
  </gml:boundedBy>
  <gml:domainSet>
    <gml:RectifiedGrid dimension="2">
      <gml:limits>
        <gml:GridEnvelope>
          <gml:low>0 0</gml:low>
          <gml:high>99 99</gml:high>
        </gml:GridEnvelope>
      </gml:limits>
      <gml:axisLabels>x y</gml:axisLabels>
      <gml:origin>
        <gml:Point>
          <gml:pos>0 0</gml:pos>
        </gml:Point>
      </gml:origin>
      <gml:offsetVector>0.1 0</gml:offsetVector>
      <gml:offsetVector>0 0.1</gml:offsetVector>
    </gml:RectifiedGrid>
  </gml:domainSet>
  <gml:rangeSet>
    <gml:DataBlock>
      <gml:rangeParameters/>
      <gml:tupleList>1 2 3 4</gml:tupleList>
    </gml:DataBlock>
  </gml:rangeSet>
</gml:RectifiedGridCoverage>''';

      final result = GmlParser.parseXmlString(xml);
      expect(result.hasErrors, isFalse);
      expect(
        result.document!.root,
        isA<GmlRectifiedGridCoverage>(),
      );

      final cov = result.document!.root
          as GmlRectifiedGridCoverage;
      expect(cov.id, 'cov1');
      expect(cov.boundedBy, isNotNull);
      expect(cov.boundedBy!.srsName, 'EPSG:4326');

      // Domain set
      final grid = cov.domainSet!;
      expect(grid.dimension, 2);
      expect(grid.limits.low, [0, 0]);
      expect(grid.limits.high, [99, 99]);
      expect(grid.axisLabels, ['x', 'y']);
      expect(grid.origin, [0.0, 0.0]);
      expect(grid.offsetVectors, hasLength(2));
      expect(grid.offsetVectors[0], [0.1, 0.0]);
      expect(grid.offsetVectors[1], [0.0, 0.1]);

      // Range set
      expect(cov.rangeSet, isNotNull);
      expect(cov.rangeSet!.data, '1 2 3 4');
    });

    test('parses with file reference', () {
      const xml = '''
<gml:RectifiedGridCoverage
    xmlns:gml="http://www.opengis.net/gml/3.2"
    gml:id="cov2">
  <gml:domainSet>
    <gml:RectifiedGrid dimension="2">
      <gml:limits>
        <gml:GridEnvelope>
          <gml:low>0 0</gml:low>
          <gml:high>255 255</gml:high>
        </gml:GridEnvelope>
      </gml:limits>
      <gml:origin>
        <gml:Point>
          <gml:pos>10 50</gml:pos>
        </gml:Point>
      </gml:origin>
      <gml:offsetVector>0.01 0</gml:offsetVector>
      <gml:offsetVector>0 -0.01</gml:offsetVector>
    </gml:RectifiedGrid>
  </gml:domainSet>
  <gml:rangeSet>
    <gml:File>
      <gml:fileName>data.tif</gml:fileName>
      <gml:fileStructure>Record Interleaved</gml:fileStructure>
    </gml:File>
  </gml:rangeSet>
</gml:RectifiedGridCoverage>''';

      final result = GmlParser.parseXmlString(xml);
      final cov = result.document!.root
          as GmlRectifiedGridCoverage;
      expect(cov.rangeSet!.file, isNotNull);
      expect(
        cov.rangeSet!.file!.fileName,
        'data.tif',
      );
      expect(
        cov.rangeSet!.file!.fileStructure,
        'Record Interleaved',
      );
    });
  });

  group('GridCoverage', () {
    test('parses GridCoverage', () {
      const xml = '''
<gml:GridCoverage
    xmlns:gml="http://www.opengis.net/gml/3.2"
    gml:id="grid1">
  <gml:domainSet>
    <gml:Grid dimension="2">
      <gml:limits>
        <gml:GridEnvelope>
          <gml:low>0 0</gml:low>
          <gml:high>49 49</gml:high>
        </gml:GridEnvelope>
      </gml:limits>
      <gml:axisLabels>i j</gml:axisLabels>
    </gml:Grid>
  </gml:domainSet>
  <gml:rangeSet>
    <gml:DataBlock>
      <gml:tupleList>10 20</gml:tupleList>
    </gml:DataBlock>
  </gml:rangeSet>
</gml:GridCoverage>''';

      final result = GmlParser.parseXmlString(xml);
      expect(result.hasErrors, isFalse);
      final cov =
          result.document!.root as GmlGridCoverage;
      expect(cov.id, 'grid1');
      expect(cov.domainSet!.dimension, 2);
      expect(cov.domainSet!.limits.high, [49, 49]);
      expect(cov.domainSet!.axisLabels, ['i', 'j']);
      expect(cov.rangeSet!.data, '10 20');
    });
  });

  group('ReferenceableGridCoverage', () {
    test('parses as GridCoverage variant', () {
      const xml = '''
<gml:ReferenceableGridCoverage
    xmlns:gml="http://www.opengis.net/gml/3.2"
    gml:id="ref1">
  <gml:domainSet>
    <gml:Grid dimension="2">
      <gml:limits>
        <gml:GridEnvelope>
          <gml:low>0 0</gml:low>
          <gml:high>9 9</gml:high>
        </gml:GridEnvelope>
      </gml:limits>
    </gml:Grid>
  </gml:domainSet>
</gml:ReferenceableGridCoverage>''';

      final result = GmlParser.parseXmlString(xml);
      expect(result.hasErrors, isFalse);
      final cov = result.document!.root
          as GmlReferenceableGridCoverage;
      expect(cov.id, 'ref1');
      expect(cov.domainSet!.limits.high, [9, 9]);
    });
  });

  group('MultiPointCoverage', () {
    test('parses with MultiPoint domainSet', () {
      const xml = '''
<gml:MultiPointCoverage
    xmlns:gml="http://www.opengis.net/gml/3.2"
    gml:id="mpc1">
  <gml:domainSet>
    <gml:MultiPoint>
      <gml:pointMember>
        <gml:Point><gml:pos>1 2</gml:pos></gml:Point>
      </gml:pointMember>
      <gml:pointMember>
        <gml:Point><gml:pos>3 4</gml:pos></gml:Point>
      </gml:pointMember>
    </gml:MultiPoint>
  </gml:domainSet>
  <gml:rangeSet>
    <gml:DataBlock>
      <gml:tupleList>100 200</gml:tupleList>
    </gml:DataBlock>
  </gml:rangeSet>
</gml:MultiPointCoverage>''';

      final result = GmlParser.parseXmlString(xml);
      expect(result.hasErrors, isFalse);
      final cov = result.document!.root
          as GmlMultiPointCoverage;
      expect(cov.id, 'mpc1');
      expect(cov.domainSet!.points, hasLength(2));
      expect(cov.rangeSet!.data, '100 200');
    });
  });

  group('rangeType', () {
    test('parses SWE DataRecord fields', () {
      const xml = '''
<gml:RectifiedGridCoverage
    xmlns:gml="http://www.opengis.net/gml/3.2"
    xmlns:swe="http://www.opengis.net/swe/2.0"
    xmlns:gmlcov="http://www.opengis.net/gmlcov/1.0"
    gml:id="cov_rt">
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
      <swe:field name="temperature">
        <swe:Quantity>
          <swe:uom code="Kelvin"/>
        </swe:Quantity>
      </swe:field>
      <swe:field name="pressure">
        <swe:Quantity>
          <swe:uom code="Pa"/>
        </swe:Quantity>
      </swe:field>
    </swe:DataRecord>
  </gmlcov:rangeType>
</gml:RectifiedGridCoverage>''';

      final result = GmlParser.parseXmlString(xml);
      final cov = result.document!.root
          as GmlRectifiedGridCoverage;
      expect(cov.rangeType, isNotNull);
      expect(cov.rangeType!.fields, hasLength(2));
      expect(
        cov.rangeType!.fields[0].name,
        'temperature',
      );
      expect(cov.rangeType!.fields[0].uom, 'Kelvin');
      expect(
        cov.rangeType!.fields[1].name,
        'pressure',
      );
      expect(cov.rangeType!.fields[1].uom, 'Pa');
    });
  });

  group('extractGeoTiffMetadata', () {
    test(
        'extracts metadata from '
        'RectifiedGridCoverage', () {
      const cov = GmlRectifiedGridCoverage(
        id: 'test',
        boundedBy: GmlEnvelope(
          lowerCorner: GmlCoordinate(10, 50),
          upperCorner: GmlCoordinate(12, 52),
          srsName: 'EPSG:4326',
        ),
        domainSet: GmlRectifiedGrid(
          dimension: 2,
          limits: GmlGridEnvelope(
            low: [0, 0],
            high: [199, 199],
          ),
          origin: [10.0, 52.0],
          offsetVectors: [
            [0.01, 0.0],
            [0.0, -0.01],
          ],
        ),
        rangeType: GmlRangeType(fields: [
          GmlRangeField(name: 'band1', uom: 'm'),
        ]),
      );

      final meta = extractGeoTiffMetadata(cov);
      expect(meta, isNotNull);
      expect(meta!.width, 200);
      expect(meta.height, 200);
      expect(meta.origin, [10.0, 52.0]);
      expect(meta.crs, 'EPSG:4326');
      expect(meta.resolution, isNotNull);
      expect(meta.resolution![0], closeTo(0.01, 1e-9));
      expect(meta.transform, hasLength(6));
      expect(meta.bands, 1);
      expect(meta.bandInfo![0].name, 'band1');
    });

    test('returns null for MultiPointCoverage', () {
      const cov = GmlMultiPointCoverage();
      expect(extractGeoTiffMetadata(cov), isNull);
    });

    test(
        'returns null for coverage '
        'without domainSet', () {
      const cov = GmlRectifiedGridCoverage();
      expect(extractGeoTiffMetadata(cov), isNull);
    });
  });

  group('pixelToWorld / worldToPixel', () {
    test('round-trips pixel ↔ world', () {
      const meta = GeoTiffMetadata(
        width: 100,
        height: 100,
        transform: [0.1, 0.0, 10.0, 0.0, -0.1, 52.0],
      );

      final world = pixelToWorld(50, 25, meta);
      expect(world, isNotNull);
      expect(world![0], closeTo(15.0, 1e-9));
      expect(world[1], closeTo(49.5, 1e-9));

      final pixel = worldToPixel(15.0, 49.5, meta);
      expect(pixel, isNotNull);
      expect(pixel![0], closeTo(50.0, 1e-9));
      expect(pixel[1], closeTo(25.0, 1e-9));
    });

    test(
        'returns null without '
        'transform', () {
      const meta = GeoTiffMetadata(
        width: 100,
        height: 100,
      );
      expect(pixelToWorld(0, 0, meta), isNull);
      expect(worldToPixel(0, 0, meta), isNull);
    });
  });
}
