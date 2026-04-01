part of '../gml4dart_base.dart';

/// Base type for values found inside a [GmlFeature]
/// property map.
sealed class GmlPropertyValue {
  /// Creates a [GmlPropertyValue].
  const GmlPropertyValue();
}

/// A property whose value is a [String].
final class GmlStringProperty extends GmlPropertyValue {
  /// Creates a [GmlStringProperty].
  const GmlStringProperty(this.value);

  /// The string value.
  final String value;
}

/// A property whose value is a [num] (integer or double).
final class GmlNumericProperty extends GmlPropertyValue {
  /// Creates a [GmlNumericProperty].
  const GmlNumericProperty(this.value);

  /// The numeric value.
  final num value;
}

/// A property whose value is a [GmlGeometry].
final class GmlGeometryProperty extends GmlPropertyValue {
  /// Creates a [GmlGeometryProperty].
  const GmlGeometryProperty(this.geometry);

  /// The geometry value.
  final GmlGeometry geometry;
}

/// A property containing nested child properties.
final class GmlNestedProperty extends GmlPropertyValue {
  /// Creates a [GmlNestedProperty].
  const GmlNestedProperty(this.children);

  /// Child properties keyed by element name.
  final Map<String, GmlPropertyValue> children;
}

/// A property whose content was not parsed and is
/// preserved as raw XML.
final class GmlRawXmlProperty extends GmlPropertyValue {
  /// Creates a [GmlRawXmlProperty].
  const GmlRawXmlProperty(this.xmlContent);

  /// The raw XML fragment.
  final String xmlContent;
}
