part of '../gml4dart_base.dart';

/// A GML element that was recognized but not mapped to a
/// typed model class.
///
/// The original XML is preserved in [rawXml] so callers
/// can inspect or re-parse it.
final class GmlUnsupportedNode extends GmlNode {
  /// Creates a [GmlUnsupportedNode].
  const GmlUnsupportedNode({
    this.namespaceUri,
    required this.localName,
    this.rawXml,
  });

  /// XML namespace URI of the element, if present.
  final String? namespaceUri;

  /// Local (unqualified) element name.
  final String localName;

  /// The raw XML fragment, if captured.
  final String? rawXml;
}
