part of '../gml4dart_base.dart';

final class GmlFeature extends GmlNode implements GmlRootContent {
  const GmlFeature({
    this.id,
    this.properties = const {},
  });

  final String? id;
  final Map<String, GmlPropertyValue> properties;
}
