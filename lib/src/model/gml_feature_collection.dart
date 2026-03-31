part of '../gml4dart_base.dart';

final class GmlFeatureCollection extends GmlNode implements GmlRootContent {
  const GmlFeatureCollection({
    this.features = const [],
    this.boundedBy,
  });

  final List<GmlFeature> features;
  final GmlEnvelope? boundedBy;
}
