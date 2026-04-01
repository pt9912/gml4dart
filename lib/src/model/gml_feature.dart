part of '../gml4dart_base.dart';

/// A GML feature with an optional [id] and a set of
/// named [properties].
final class GmlFeature extends GmlNode implements GmlRootContent {
  /// Creates a [GmlFeature].
  const GmlFeature({
    this.id,
    this.properties = const {},
  });

  /// The `gml:id` attribute value, if present.
  final String? id;

  /// Named properties of this feature, keyed by the
  /// property element name.
  final Map<String, GmlPropertyValue> properties;
}
