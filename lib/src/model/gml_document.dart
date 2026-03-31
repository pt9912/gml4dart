part of '../gml4dart_base.dart';

final class GmlDocument {
  const GmlDocument({
    required this.version,
    required this.root,
    this.boundedBy,
  });

  final GmlVersion version;
  final GmlRootContent root;
  final GmlEnvelope? boundedBy;

  /// Parses a GML XML string into a [GmlParseResult].
  static GmlParseResult parseXmlString(String xml) =>
      GmlParser.parseXmlString(xml);

  /// Parses GML from UTF-8 bytes into a [GmlParseResult].
  static GmlParseResult parseBytes(List<int> bytes) =>
      GmlParser.parseBytes(bytes);
}
