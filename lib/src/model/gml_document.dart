part of '../gml4dart_base.dart';

/// A parsed GML document.
///
/// Use [parseXmlString] or [parseBytes] to create an
/// instance from raw GML content.
final class GmlDocument {
  /// Creates a [GmlDocument].
  const GmlDocument({
    required this.version,
    required this.root,
    this.boundedBy,
  });

  /// The GML specification version of this document.
  final GmlVersion version;

  /// The root content element (a geometry, feature,
  /// feature collection, or coverage).
  final GmlRootContent root;

  /// Optional bounding envelope declared at the
  /// document level.
  final GmlEnvelope? boundedBy;

  /// Parses a GML XML string into a [GmlParseResult].
  static GmlParseResult parseXmlString(String xml) =>
      GmlParser.parseXmlString(xml);

  /// Parses GML from UTF-8 bytes into a [GmlParseResult].
  static GmlParseResult parseBytes(List<int> bytes) =>
      GmlParser.parseBytes(bytes);
}
