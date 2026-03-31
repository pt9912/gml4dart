part of '../gml4dart_base.dart';

/// Entry point for parsing GML documents.
///
/// Prefer [GmlDocument.parseXmlString] / [GmlDocument.parseBytes]
/// as the primary API. This class provides the same methods and
/// can be used as an alternative entry point.
class GmlParser {
  GmlParser._();

  /// Parses a GML XML string into a [GmlParseResult].
  static GmlParseResult parseXmlString(String xml) {
    final issues = <GmlParseIssue>[];

    final XmlDocument doc;
    try {
      doc = XmlDocument.parse(xml);
    } on XmlParserException catch (e) {
      return GmlParseResult(issues: [
        GmlParseIssue(
          severity: GmlIssueSeverity.error,
          code: 'invalid_xml',
          message:
              'Failed to parse XML: ${e.message}',
        ),
      ]);
    }

    final root = doc.rootElement;
    final version = _detectVersion(root);
    final rootContent =
        _parseRootElement(root, issues);

    if (rootContent == null) {
      return GmlParseResult(issues: issues);
    }

    GmlEnvelope? boundedBy;
    final boundedByEl =
        _findGmlChild(root, 'boundedBy');
    if (boundedByEl != null) {
      final envelope =
          _findGmlChild(boundedByEl, 'Envelope');
      if (envelope != null) {
        final geom =
            _parseGeometry(envelope, issues);
        if (geom is GmlEnvelope) boundedBy = geom;
      }
    }

    return GmlParseResult(
      document: GmlDocument(
        version: version,
        root: rootContent,
        boundedBy: boundedBy,
      ),
      issues: issues,
    );
  }

  /// Parses GML from UTF-8 bytes into a
  /// [GmlParseResult].
  static GmlParseResult parseBytes(List<int> bytes) {
    final String xml;
    try {
      xml = utf8.decode(bytes);
    } on FormatException catch (e) {
      return GmlParseResult(issues: [
        GmlParseIssue(
          severity: GmlIssueSeverity.error,
          code: 'invalid_encoding',
          message:
              'Failed to decode bytes as UTF-8: '
              '${e.message}',
        ),
      ]);
    }
    return parseXmlString(xml);
  }
}

GmlRootContent? _parseRootElement(
  XmlElement root,
  List<GmlParseIssue> issues,
) {
  final localName = root.localName;

  // FeatureCollection (GML or WFS namespace)
  if (localName == 'FeatureCollection') {
    return _parseFeatureCollection(root, issues);
  }

  // Coverage types
  if (_isCoverageElement(localName)) {
    return _parseCoverage(root, issues);
  }

  // Standalone geometry
  if (_isGmlNamespace(root.namespaceUri)) {
    final geom = _parseGeometry(root, issues);
    if (geom != null) return geom;
  }

  // Try as feature (has properties as children)
  if (root.childElements.isNotEmpty) {
    return _parseFeature(root, issues);
  }

  issues.add(GmlParseIssue(
    severity: GmlIssueSeverity.error,
    code: 'unknown_root',
    message:
        'Unrecognized root element: $localName',
  ));
  return null;
}
