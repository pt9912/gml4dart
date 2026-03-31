part of '../gml4dart_base.dart';

/// Grid envelope defining pixel extent via low/high
/// integer coordinates.
final class GmlGridEnvelope {
  const GmlGridEnvelope({
    required this.low,
    required this.high,
  });

  final List<int> low;
  final List<int> high;
}

/// Non-georeferenced grid with dimension and limits.
final class GmlGrid {
  const GmlGrid({
    this.id,
    required this.dimension,
    required this.limits,
    this.axisLabels,
  });

  final String? id;
  final int dimension;
  final GmlGridEnvelope limits;
  final List<String>? axisLabels;
}

/// Georeferenced grid with origin and offset vectors
/// (affine transformation).
final class GmlRectifiedGrid {
  const GmlRectifiedGrid({
    this.id,
    required this.dimension,
    required this.limits,
    this.axisLabels,
    this.srsName,
    required this.origin,
    required this.offsetVectors,
  });

  final String? id;
  final int dimension;
  final GmlGridEnvelope limits;
  final List<String>? axisLabels;
  final String? srsName;
  final List<double> origin;
  final List<List<double>> offsetVectors;
}
