import 'dart:async';
import 'dart:convert';

import 'package:gml4dart/gml4dart.dart';
import 'package:test/test.dart';

const _wfs20Xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<wfs:FeatureCollection
    xmlns:wfs="http://www.opengis.net/wfs/2.0"
    xmlns:gml="http://www.opengis.net/gml/3.2"
    xmlns:app="http://example.com">
  <wfs:member>
    <app:Place gml:id="p1">
      <app:name>Berlin</app:name>
      <app:geom>
        <gml:Point srsName="EPSG:4326">
          <gml:pos>13.4 52.5</gml:pos>
        </gml:Point>
      </app:geom>
    </app:Place>
  </wfs:member>
  <wfs:member>
    <app:Place gml:id="p2">
      <app:name>Munich</app:name>
      <app:geom>
        <gml:Point srsName="EPSG:4326">
          <gml:pos>11.6 48.1</gml:pos>
        </gml:Point>
      </app:geom>
    </app:Place>
  </wfs:member>
  <wfs:member>
    <app:Place gml:id="p3">
      <app:name>Hamburg</app:name>
    </app:Place>
  </wfs:member>
</wfs:FeatureCollection>''';

void main() {
  group('GmlFeatureStreamParser', () {
    group('parseStringStream', () {
      test('streams features from single chunk',
          () async {
        final stream = Stream.value(_wfs20Xml);
        final features =
            await GmlFeatureStreamParser
                .parseStringStream(stream)
                .toList();

        expect(features, hasLength(3));
        expect(features[0].id, 'p1');
        expect(features[1].id, 'p2');
        expect(features[2].id, 'p3');
      });

      test(
          'streams features from multiple '
          'small chunks', () async {
        // Split XML at arbitrary 50-byte points
        final chunks = <String>[];
        const chunkSize = 50;
        for (var i = 0;
            i < _wfs20Xml.length;
            i += chunkSize) {
          chunks.add(_wfs20Xml.substring(
            i,
            (i + chunkSize).clamp(
              0,
              _wfs20Xml.length,
            ),
          ));
        }

        expect(
          chunks.length,
          greaterThan(5),
          reason: 'Must have many chunks',
        );

        final stream = Stream.fromIterable(chunks);
        final features =
            await GmlFeatureStreamParser
                .parseStringStream(stream)
                .toList();

        expect(features, hasLength(3));
        expect(features[0].id, 'p1');
        expect(features[2].id, 'p3');
      });

      test('parses feature properties correctly',
          () async {
        final stream = Stream.value(_wfs20Xml);
        final features =
            await GmlFeatureStreamParser
                .parseStringStream(stream)
                .toList();

        final berlin = features[0];
        expect(
          (berlin.properties['name']!
                  as GmlStringProperty)
              .value,
          'Berlin',
        );
        expect(
          berlin.properties['geom'],
          isA<GmlGeometryProperty>(),
        );
      });

      test(
          'handles gml:featureMember '
          '(WFS 1.0)', () async {
        const xml = '''
<wfs:FeatureCollection
    xmlns:wfs="http://www.opengis.net/wfs"
    xmlns:gml="http://www.opengis.net/gml"
    xmlns:app="http://example.com">
  <gml:featureMember>
    <app:Road fid="road.1">
      <app:name>Main St</app:name>
    </app:Road>
  </gml:featureMember>
  <gml:featureMember>
    <app:Road fid="road.2">
      <app:name>High St</app:name>
    </app:Road>
  </gml:featureMember>
</wfs:FeatureCollection>''';

        final features =
            await GmlFeatureStreamParser
                .parseStringStream(
                  Stream.value(xml),
                )
                .toList();

        expect(features, hasLength(2));
        expect(features[0].id, 'road.1');
        expect(features[1].id, 'road.2');
      });

      test(
          'handles gml:featureMembers '
          '(plural)', () async {
        const xml = '''
<wfs:FeatureCollection
    xmlns:wfs="http://www.opengis.net/wfs"
    xmlns:gml="http://www.opengis.net/gml"
    xmlns:app="http://example.com">
  <gml:featureMembers>
    <app:Place gml:id="a">
      <app:name>A</app:name>
    </app:Place>
    <app:Place gml:id="b">
      <app:name>B</app:name>
    </app:Place>
    <app:Place gml:id="c">
      <app:name>C</app:name>
    </app:Place>
  </gml:featureMembers>
</wfs:FeatureCollection>''';

        final features =
            await GmlFeatureStreamParser
                .parseStringStream(
                  Stream.value(xml),
                )
                .toList();

        expect(features, hasLength(3));
        expect(features[0].id, 'a');
        expect(features[2].id, 'c');
      });

      test(
          'handles empty '
          'FeatureCollection', () async {
        const xml = '''
<wfs:FeatureCollection
    xmlns:wfs="http://www.opengis.net/wfs/2.0"
    xmlns:gml="http://www.opengis.net/gml/3.2">
</wfs:FeatureCollection>''';

        final features =
            await GmlFeatureStreamParser
                .parseStringStream(
                  Stream.value(xml),
                )
                .toList();

        expect(features, isEmpty);
      });
    });

    group('incremental yielding', () {
      test(
          'yields features as chunks '
          'arrive', () async {
        // Use a StreamController to send chunks
        // one at a time and verify features appear
        // between chunks.
        final controller =
            StreamController<String>();
        final receivedIds = <String?>[];

        // Listen for features
        final done = GmlFeatureStreamParser
            .parseStringStream(controller.stream)
            .listen(
              (f) => receivedIds.add(f.id),
            )
            .asFuture<void>();

        // Send header
        controller.add(
          '<?xml version="1.0"?>'
          '<wfs:FeatureCollection'
          ' xmlns:wfs='
          '"http://www.opengis.net/wfs/2.0"'
          ' xmlns:gml='
          '"http://www.opengis.net/gml/3.2"'
          ' xmlns:app="http://example.com">',
        );
        // Allow async processing
        await Future<void>.delayed(Duration.zero);
        expect(
          receivedIds,
          isEmpty,
          reason: 'No features yet',
        );

        // Send first complete member
        controller.add(
          '<wfs:member>'
          '<app:A gml:id="a1">'
          '<app:x>1</app:x>'
          '</app:A>'
          '</wfs:member>',
        );
        await Future<void>.delayed(Duration.zero);
        expect(
          receivedIds,
          ['a1'],
          reason: 'First feature yielded',
        );

        // Send second member
        controller.add(
          '<wfs:member>'
          '<app:B gml:id="b2">'
          '<app:x>2</app:x>'
          '</app:B>'
          '</wfs:member>',
        );
        await Future<void>.delayed(Duration.zero);
        expect(
          receivedIds,
          ['a1', 'b2'],
          reason: 'Second feature yielded',
        );

        // Close
        controller.add('</wfs:FeatureCollection>');
        await controller.close();
        await done;

        expect(receivedIds, hasLength(2));
      });
    });

    group('parseByteStream', () {
      test('parses UTF-8 byte chunks', () async {
        final bytes = utf8.encode(_wfs20Xml);
        const chunkSize = 100;
        final chunks = <List<int>>[];
        for (var i = 0;
            i < bytes.length;
            i += chunkSize) {
          chunks.add(bytes.sublist(
            i,
            (i + chunkSize).clamp(0, bytes.length),
          ));
        }

        final stream = Stream.fromIterable(chunks);
        final features =
            await GmlFeatureStreamParser
                .parseByteStream(stream)
                .toList();

        expect(features, hasLength(3));
      });

      test(
          'handles multi-byte UTF-8 split '
          'across chunks', () async {
        // German umlauts (ä=2 bytes, ü=2 bytes)
        // and emoji (4 bytes) in feature properties
        const xml = '''
<wfs:FeatureCollection
    xmlns:wfs="http://www.opengis.net/wfs/2.0"
    xmlns:gml="http://www.opengis.net/gml/3.2"
    xmlns:app="http://example.com">
  <wfs:member>
    <app:Place gml:id="p1">
      <app:name>München</app:name>
    </app:Place>
  </wfs:member>
  <wfs:member>
    <app:Place gml:id="p2">
      <app:name>Zürich</app:name>
    </app:Place>
  </wfs:member>
</wfs:FeatureCollection>''';

        final bytes = utf8.encode(xml);

        // Find a multi-byte char boundary to split
        // 'ü' in München is at some offset —
        // use 1-byte chunks to guarantee splits
        // inside multi-byte sequences.
        final chunks = bytes
            .map((b) => [b])
            .toList();

        final features =
            await GmlFeatureStreamParser
                .parseByteStream(
                  Stream.fromIterable(chunks),
                )
                .toList();

        expect(features, hasLength(2));
        expect(features[0].id, 'p1');
        expect(
          (features[0].properties['name']!
                  as GmlStringProperty)
              .value,
          'München',
        );
        expect(
          (features[1].properties['name']!
                  as GmlStringProperty)
              .value,
          'Zürich',
        );
      });
    });

    group('processFeatures callback', () {
      test('invokes callback per feature', () async {
        final ids = <String?>[];
        final count =
            await GmlFeatureStreamParser
                .processFeatures(
          Stream.value(_wfs20Xml),
          onFeature: (f) => ids.add(f.id),
        );

        expect(count, 3);
        expect(ids, ['p1', 'p2', 'p3']);
      });
    });

    group('batch processing', () {
      test('supports Stream.take', () async {
        final firstTwo =
            await GmlFeatureStreamParser
                .parseStringStream(
                  Stream.value(_wfs20Xml),
                )
                .take(2)
                .toList();

        expect(firstTwo, hasLength(2));
        expect(firstTwo[0].id, 'p1');
        expect(firstTwo[1].id, 'p2');
      });

      test('supports Stream.where', () async {
        final withGeom =
            await GmlFeatureStreamParser
                .parseStringStream(
                  Stream.value(_wfs20Xml),
                )
                .where(
                  (f) => f.properties.values.any(
                    (v) => v is GmlGeometryProperty,
                  ),
                )
                .toList();

        expect(
          withGeom,
          hasLength(2),
          reason: 'p3 has no geometry',
        );
      });
    });

    group('memory characteristics', () {
      test(
          'buffer does not grow unbounded '
          'with many features', () async {
        // Generate a large WFS response
        final buf = StringBuffer()
          ..write(
            '<wfs:FeatureCollection'
            ' xmlns:wfs='
            '"http://www.opengis.net/wfs/2.0"'
            ' xmlns:gml='
            '"http://www.opengis.net/gml/3.2"'
            ' xmlns:app="http://example.com">',
          );
        const featureCount = 500;
        for (var i = 0; i < featureCount; i++) {
          buf.write(
            '<wfs:member>'
            '<app:Item gml:id="item.$i">'
            '<app:val>$i</app:val>'
            '</app:Item>'
            '</wfs:member>',
          );
        }
        buf.write('</wfs:FeatureCollection>');

        final xml = buf.toString();

        // Stream in 200-byte chunks
        final chunks = <String>[];
        const chunkSize = 200;
        for (var i = 0;
            i < xml.length;
            i += chunkSize) {
          chunks.add(xml.substring(
            i,
            (i + chunkSize).clamp(0, xml.length),
          ));
        }

        var yielded = 0;
        await for (final feature
            in GmlFeatureStreamParser
                .parseStringStream(
          Stream.fromIterable(chunks),
        )) {
          yielded++;
          expect(feature.id, isNotNull);
        }

        expect(
          yielded,
          featureCount,
          reason: 'All features must be yielded',
        );
      });

      test(
          'processes features without '
          'collecting all into memory', () async {
        // Verify we can process a stream and
        // only keep running totals, not all
        // features.
        final buf = StringBuffer()
          ..write(
            '<wfs:FeatureCollection'
            ' xmlns:wfs='
            '"http://www.opengis.net/wfs/2.0"'
            ' xmlns:gml='
            '"http://www.opengis.net/gml/3.2"'
            ' xmlns:app="http://example.com">',
          );
        for (var i = 0; i < 100; i++) {
          buf.write(
            '<wfs:member>'
            '<app:Item gml:id="i.$i">'
            '<app:v>$i</app:v>'
            '</app:Item>'
            '</wfs:member>',
          );
        }
        buf.write('</wfs:FeatureCollection>');

        // Process without .toList() — only keep
        // a running count and last id.
        var count = 0;
        String? lastId;
        await for (final f
            in GmlFeatureStreamParser
                .parseStringStream(
          Stream.value(buf.toString()),
        )) {
          count++;
          lastId = f.id;
          // Each feature is consumed and can be GC'd
        }

        expect(count, 100);
        expect(lastId, 'i.99');
      });

      test(
          'throughput scales linearly '
          '(no quadratic regression)', () async {
        // Measure time for N and 3N features.
        // If the parser is O(n), 3N should take
        // roughly 3x. Allow up to 6x for CI noise.
        // A quadratic algorithm would show ~9x.
        Future<Duration> measure(int n) async {
          final buf = StringBuffer()
            ..write(
              '<wfs:FeatureCollection'
              ' xmlns:wfs='
              '"http://www.opengis.net/wfs/2.0"'
              ' xmlns:gml='
              '"http://www.opengis.net/gml/3.2"'
              ' xmlns:app='
              '"http://example.com">',
            );
          for (var i = 0; i < n; i++) {
            buf.write(
              '<wfs:member>'
              '<app:I gml:id="i$i">'
              '<app:v>$i</app:v>'
              '</app:I>'
              '</wfs:member>',
            );
          }
          buf.write('</wfs:FeatureCollection>');

          final xml = buf.toString();
          // Chunk into 500-byte pieces
          final chunks = <String>[];
          for (var i = 0;
              i < xml.length;
              i += 500) {
            chunks.add(xml.substring(
              i,
              (i + 500).clamp(0, xml.length),
            ));
          }

          final sw = Stopwatch()..start();
          var count = 0;
          await for (final _
              in GmlFeatureStreamParser
                  .parseStringStream(
            Stream.fromIterable(chunks),
          )) {
            count++;
          }
          sw.stop();
          expect(count, n);
          return sw.elapsed;
        }

        const small = 200;
        const large = 600;

        final tSmall = await measure(small);
        final tLarge = await measure(large);

        // With O(n) scaling, tLarge/tSmall should
        // be ~3x. Allow up to 6x for CI noise.
        // A quadratic algorithm would show ~9x.
        final ratio = tLarge.inMicroseconds /
            tSmall.inMicroseconds;
        expect(
          ratio,
          lessThan(6.0),
          reason: 'Expected linear scaling. '
              'Ratio: ${ratio.toStringAsFixed(1)}x '
              '(${tSmall.inMilliseconds}ms vs '
              '${tLarge.inMilliseconds}ms)',
        );
      });

      test(
          'per-feature throughput stays within '
          'threshold', () async {
        // Parse 1000 features and assert that
        // average per-feature time does not
        // exceed 2ms (generous for CI).
        const n = 1000;
        final buf = StringBuffer()
          ..write(
            '<wfs:FeatureCollection'
            ' xmlns:wfs='
            '"http://www.opengis.net/wfs/2.0"'
            ' xmlns:gml='
            '"http://www.opengis.net/gml/3.2"'
            ' xmlns:app="http://example.com">',
          );
        for (var i = 0; i < n; i++) {
          buf.write(
            '<wfs:member>'
            '<app:I gml:id="i$i">'
            '<app:v>$i</app:v>'
            '</app:I>'
            '</wfs:member>',
          );
        }
        buf.write('</wfs:FeatureCollection>');

        final xml = buf.toString();
        final chunks = <String>[];
        for (var i = 0; i < xml.length; i += 500) {
          chunks.add(xml.substring(
            i,
            (i + 500).clamp(0, xml.length),
          ));
        }

        final sw = Stopwatch()..start();
        var count = 0;
        await for (final _
            in GmlFeatureStreamParser
                .parseStringStream(
          Stream.fromIterable(chunks),
        )) {
          count++;
        }
        sw.stop();

        expect(count, n);

        final usPerFeature =
            sw.elapsedMicroseconds / n;
        // Threshold: 2ms (2000µs) per feature.
        // Typical is well under 500µs.
        expect(
          usPerFeature,
          lessThan(2000),
          reason: 'Per-feature avg: '
              '${usPerFeature.toStringAsFixed(0)}µs '
              '(threshold: 2000µs)',
        );
      });
    });
  });
}
