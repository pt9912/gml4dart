part of '../gml4dart_base.dart';

/// An ordered collection of [GmlFeature] elements with
/// an optional bounding envelope.
final class GmlFeatureCollection extends GmlNode implements GmlRootContent {
  /// Creates a [GmlFeatureCollection].
  const GmlFeatureCollection({
    this.features = const [],
    this.boundedBy,
  });

  /// The member features.
  final List<GmlFeature> features;

  /// Optional bounding envelope for all features in
  /// the collection.
  final GmlEnvelope? boundedBy;
}
