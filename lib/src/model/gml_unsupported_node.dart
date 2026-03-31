part of '../model.dart';

final class GmlUnsupportedNode extends GmlNode {
  const GmlUnsupportedNode({
    this.namespaceUri,
    required this.localName,
    this.rawXml,
  });

  final String? namespaceUri;
  final String localName;
  final String? rawXml;
}
