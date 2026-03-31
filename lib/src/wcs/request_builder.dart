part of '../gml4dart_base.dart';

/// Supported WCS versions.
enum WcsVersion {
  v1_0_0('1.0.0'),
  v1_1_0('1.1.0'),
  v1_1_1('1.1.1'),
  v1_1_2('1.1.2'),
  v2_0_0('2.0.0'),
  v2_0_1('2.0.1');

  const WcsVersion(this.value);
  final String value;
}

/// A spatial or temporal subset for WCS requests.
final class WcsSubset {
  const WcsSubset({
    required this.axis,
    this.min,
    this.max,
    this.value,
  });

  final String axis;
  final String? min;
  final String? max;
  final String? value;
}

/// Options for a WCS GetCoverage request.
final class WcsGetCoverageOptions {
  const WcsGetCoverageOptions({
    required this.coverageId,
    this.format,
    this.subsets = const [],
    this.outputCrs,
    this.rangeSubset,
    this.interpolation,
  });

  final String coverageId;
  final String? format;
  final List<WcsSubset> subsets;
  final String? outputCrs;
  final List<String>? rangeSubset;
  final String? interpolation;
}

/// Builds WCS GetCoverage request URLs and XML.
class WcsRequestBuilder {
  WcsRequestBuilder({
    required this.baseUrl,
    this.version = WcsVersion.v2_0_1,
  });

  final String baseUrl;
  final WcsVersion version;

  /// Builds a GetCoverage GET request URL.
  String buildGetCoverageUrl(
    WcsGetCoverageOptions options,
  ) {
    final params = <String, String>{
      'service': 'WCS',
      'version': version.value,
      'request': 'GetCoverage',
    };

    // Coverage identifier varies by version
    switch (version) {
      case WcsVersion.v2_0_0:
      case WcsVersion.v2_0_1:
        params['coverageId'] = options.coverageId;
      case WcsVersion.v1_1_0:
      case WcsVersion.v1_1_1:
      case WcsVersion.v1_1_2:
        params['identifier'] = options.coverageId;
      case WcsVersion.v1_0_0:
        params['coverage'] = options.coverageId;
    }

    if (options.format != null) {
      params['format'] = options.format!;
    }

    if (options.outputCrs != null) {
      params['outputCrs'] = options.outputCrs!;
    }

    if (options.interpolation != null) {
      params['interpolation'] =
          options.interpolation!;
    }

    // Build base URL with params
    final sep = baseUrl.contains('?') ? '&' : '?';
    final paramStr = params.entries
        .map(
          (e) => '${Uri.encodeComponent(e.key)}='
              '${Uri.encodeComponent(e.value)}',
        )
        .join('&');

    final buf = StringBuffer('$baseUrl$sep$paramStr');

    // Subsets as repeated params
    for (final s in options.subsets) {
      final val = s.value != null
          ? '${s.axis}(${s.value})'
          : '${s.axis}(${s.min},${s.max})';
      buf.write(
        '&subset=${Uri.encodeComponent(val)}',
      );
    }

    // Range subset
    final rs = options.rangeSubset;
    if (rs != null && rs.isNotEmpty) {
      buf.write(
        '&rangeSubset='
        '${Uri.encodeComponent(rs.join(','))}',
      );
    }

    return buf.toString();
  }

  /// Builds a WCS 2.0 GetCoverage POST XML body.
  ///
  /// Only supported for WCS 2.0+.
  String buildGetCoverageXml(
    WcsGetCoverageOptions options,
  ) {
    if (version != WcsVersion.v2_0_0 &&
        version != WcsVersion.v2_0_1) {
      throw UnsupportedError(
        'XML POST only supported for WCS 2.0+',
      );
    }

    final buf = StringBuffer()
      ..writeln('<?xml version="1.0" '
          'encoding="UTF-8"?>')
      ..writeln('<wcs:GetCoverage')
      ..writeln(
        '    xmlns:wcs='
        '"http://www.opengis.net/wcs/2.0"',
      )
      ..writeln(
        '    xmlns:gml='
        '"http://www.opengis.net/gml/3.2"',
      )
      ..writeln('    service="WCS"')
      ..writeln('    version="${version.value}">')
      ..writeln(
        '  <wcs:CoverageId>'
        '${_xmlEscape(options.coverageId)}'
        '</wcs:CoverageId>',
      );

    if (options.format != null) {
      buf.writeln(
        '  <wcs:format>'
        '${_xmlEscape(options.format!)}'
        '</wcs:format>',
      );
    }

    for (final s in options.subsets) {
      buf
        ..writeln('  <wcs:DimensionTrim>')
        ..writeln(
          '    <wcs:Dimension>'
          '${_xmlEscape(s.axis)}'
          '</wcs:Dimension>',
        );
      if (s.value != null) {
        buf.writeln(
          '    <wcs:SlicePoint>'
          '${s.value}'
          '</wcs:SlicePoint>',
        );
      } else {
        if (s.min != null) {
          buf.writeln(
            '    <wcs:TrimLow>'
            '${s.min}'
            '</wcs:TrimLow>',
          );
        }
        if (s.max != null) {
          buf.writeln(
            '    <wcs:TrimHigh>'
            '${s.max}'
            '</wcs:TrimHigh>',
          );
        }
      }
      buf.writeln('  </wcs:DimensionTrim>');
    }

    buf.writeln('</wcs:GetCoverage>');
    return buf.toString();
  }
}

String _xmlEscape(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');
