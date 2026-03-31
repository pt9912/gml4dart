part of '../model.dart';

sealed class GmlPropertyValue {
  const GmlPropertyValue();
}

final class GmlStringProperty extends GmlPropertyValue {
  const GmlStringProperty(this.value);

  final String value;
}

final class GmlNumericProperty extends GmlPropertyValue {
  const GmlNumericProperty(this.value);

  final num value;
}

final class GmlGeometryProperty extends GmlPropertyValue {
  const GmlGeometryProperty(this.geometry);

  final GmlGeometry geometry;
}

final class GmlNestedProperty extends GmlPropertyValue {
  const GmlNestedProperty(this.children);

  final Map<String, GmlPropertyValue> children;
}

final class GmlRawXmlProperty extends GmlPropertyValue {
  const GmlRawXmlProperty(this.xmlContent);

  final String xmlContent;
}
