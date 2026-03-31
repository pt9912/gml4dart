import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../gml4dart_base.dart';

export '../gml4dart_base.dart';

/// File- and URL-based helpers for loading GML
/// documents. Requires `dart:io` — import via
/// `package:gml4dart/gml4dart_io.dart`.
class GmlIo {
  GmlIo._();

  /// Parses a GML file synchronously.
  static GmlParseResult parseFileSync(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return GmlParseResult(issues: [
        GmlParseIssue(
          severity: GmlIssueSeverity.error,
          code: 'file_not_found',
          message: 'File not found: $path',
        ),
      ]);
    }
    try {
      final bytes = file.readAsBytesSync();
      return GmlParser.parseBytes(bytes);
    } on FileSystemException catch (e) {
      return GmlParseResult(issues: [
        GmlParseIssue(
          severity: GmlIssueSeverity.error,
          code: 'file_read_error',
          message: 'Failed to read file: '
              '${e.message}',
        ),
      ]);
    }
  }

  /// Parses a GML file asynchronously.
  static Future<GmlParseResult> parseFile(
    String path,
  ) async {
    final file = File(path);
    if (!await file.exists()) {
      return GmlParseResult(issues: [
        GmlParseIssue(
          severity: GmlIssueSeverity.error,
          code: 'file_not_found',
          message: 'File not found: $path',
        ),
      ]);
    }
    try {
      final bytes = await file.readAsBytes();
      return GmlParser.parseBytes(bytes);
    } on FileSystemException catch (e) {
      return GmlParseResult(issues: [
        GmlParseIssue(
          severity: GmlIssueSeverity.error,
          code: 'file_read_error',
          message: 'Failed to read file: '
              '${e.message}',
        ),
      ]);
    }
  }

  /// Fetches and parses GML from a URL.
  ///
  /// Uses [HttpClient] from `dart:io`. For custom
  /// HTTP clients or headers, fetch the XML
  /// yourself and use [GmlParser.parseXmlString].
  static Future<GmlParseResult> parseUrl(
    Uri url,
  ) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(url);
      final response = await request.close();

      if (response.statusCode != 200) {
        return GmlParseResult(issues: [
          GmlParseIssue(
            severity: GmlIssueSeverity.error,
            code: 'http_error',
            message: 'HTTP ${response.statusCode} '
                'for $url',
          ),
        ]);
      }

      final body =
          await response.transform(utf8.decoder).join();

      // Check for OWS exception
      if (isOwsExceptionReport(body)) {
        final report =
            parseOwsExceptionReport(body);
        if (report != null) {
          return GmlParseResult(
            issues: report.exceptions
                .expand(
                  (e) => e.exceptionTexts.map(
                    (t) => GmlParseIssue(
                      severity:
                          GmlIssueSeverity.error,
                      code: e.exceptionCode,
                      message: t,
                      location: e.locator,
                    ),
                  ),
                )
                .toList(),
          );
        }
      }

      return GmlParser.parseXmlString(body);
    } on SocketException catch (e) {
      return GmlParseResult(issues: [
        GmlParseIssue(
          severity: GmlIssueSeverity.error,
          code: 'network_error',
          message:
              'Network error for $url: ${e.message}',
        ),
      ]);
    } on HttpException catch (e) {
      return GmlParseResult(issues: [
        GmlParseIssue(
          severity: GmlIssueSeverity.error,
          code: 'http_error',
          message:
              'HTTP error for $url: ${e.message}',
        ),
      ]);
    } finally {
      client.close();
    }
  }

  /// Streams features from a GML file.
  static Stream<GmlFeature> streamFeaturesFromFile(
    String path,
  ) {
    final file = File(path);
    return GmlFeatureStreamParser.parseByteStream(
      file.openRead(),
    );
  }

  /// Streams features from a URL.
  static Stream<GmlFeature> streamFeaturesFromUrl(
    Uri url,
  ) async* {
    final client = HttpClient();
    try {
      final request = await client.getUrl(url);
      final response = await request.close();

      if (response.statusCode != 200) return;

      yield* GmlFeatureStreamParser
          .parseStringStream(
        response.transform(utf8.decoder),
      );
    } finally {
      client.close();
    }
  }
}
