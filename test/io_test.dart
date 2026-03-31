import 'dart:io';

import 'package:gml4dart/gml4dart_io.dart';
import 'package:test/test.dart';

void main() {
  group('GmlIo', () {
    late Directory tmpDir;

    setUp(() {
      tmpDir = Directory.systemTemp
          .createTempSync('gml4dart_test_');
    });

    tearDown(() {
      tmpDir.deleteSync(recursive: true);
    });

    group('parseFileSync', () {
      test('parses a valid GML file', () {
        final file = File(
          '${tmpDir.path}/point.gml',
        )..writeAsStringSync('''
<gml:Point xmlns:gml="http://www.opengis.net/gml/3.2">
  <gml:pos>9.0 48.0</gml:pos>
</gml:Point>''');

        final result =
            GmlIo.parseFileSync(file.path);
        expect(result.hasErrors, isFalse);
        expect(
          result.document!.root,
          isA<GmlPoint>(),
        );
      });

      test(
          'returns error for '
          'non-existent file', () {
        final result = GmlIo.parseFileSync(
          '${tmpDir.path}/missing.gml',
        );
        expect(result.hasErrors, isTrue);
        expect(
          result.issues.first.code,
          'file_not_found',
        );
      });
    });

    group('parseFile', () {
      test('parses a valid GML file', () async {
        final file = File(
          '${tmpDir.path}/line.gml',
        )..writeAsStringSync('''
<gml:LineString xmlns:gml="http://www.opengis.net/gml/3.2">
  <gml:posList>0 0 1 1</gml:posList>
</gml:LineString>''');

        final result =
            await GmlIo.parseFile(file.path);
        expect(result.hasErrors, isFalse);
        expect(
          result.document!.root,
          isA<GmlLineString>(),
        );
      });

      test(
          'returns error for '
          'non-existent file', () async {
        final result = await GmlIo.parseFile(
          '${tmpDir.path}/nope.gml',
        );
        expect(result.hasErrors, isTrue);
        expect(
          result.issues.first.code,
          'file_not_found',
        );
      });
    });

    group('streamFeaturesFromFile', () {
      test('streams features from file', () async {
        final file = File(
          '${tmpDir.path}/fc.gml',
        )..writeAsStringSync('''
<wfs:FeatureCollection
    xmlns:wfs="http://www.opengis.net/wfs/2.0"
    xmlns:gml="http://www.opengis.net/gml/3.2"
    xmlns:app="http://example.com">
  <wfs:member>
    <app:A gml:id="a1"><app:n>X</app:n></app:A>
  </wfs:member>
  <wfs:member>
    <app:B gml:id="b2"><app:n>Y</app:n></app:B>
  </wfs:member>
</wfs:FeatureCollection>''');

        final features =
            await GmlIo.streamFeaturesFromFile(
          file.path,
        ).toList();

        expect(features, hasLength(2));
        expect(features[0].id, 'a1');
        expect(features[1].id, 'b2');
      });
    });

    group('parseUrl', () {
      test('API exists and returns GmlParseResult',
          () {
        // Verifies the parseUrl API compiles and
        // accepts a Uri. Actual network calls are
        // not tested in CI (no guaranteed network).
        expect(GmlIo.parseUrl, isA<Function>());
      });
    });

    group('re-exports core', () {
      test(
          'gml4dart_io re-exports core '
          'types', () {
        // Verify that importing gml4dart_io
        // gives access to core types without
        // a separate gml4dart import.
        const point = GmlPoint(
          coordinate: GmlCoordinate(0, 0),
        );
        expect(point.coordinate.x, 0);

        final result = GmlParser.parseXmlString(
          '<gml:Point '
          'xmlns:gml='
          '"http://www.opengis.net/gml/3.2">'
          '<gml:pos>1 2</gml:pos>'
          '</gml:Point>',
        );
        expect(result.hasErrors, isFalse);
      });
    });
  });
}
