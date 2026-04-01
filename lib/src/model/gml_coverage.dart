part of '../gml4dart_base.dart';

/// Base class for GML coverage elements, which combine
/// a domain (spatial extent) with range data (values).
sealed class GmlCoverage extends GmlNode
    implements GmlRootContent {
  /// Creates a [GmlCoverage].
  const GmlCoverage({
    this.id,
    this.boundedBy,
    this.rangeSet,
    this.rangeType,
  });

  /// The `gml:id` attribute value, if present.
  final String? id;

  /// Optional bounding envelope.
  final GmlEnvelope? boundedBy;

  /// The range data (inline values or file reference).
  final GmlRangeSet? rangeSet;

  /// Schema describing the range fields/bands.
  final GmlRangeType? rangeType;
}

/// A coverage whose domain is a [GmlRectifiedGrid].
final class GmlRectifiedGridCoverage
    extends GmlCoverage {
  /// Creates a [GmlRectifiedGridCoverage].
  const GmlRectifiedGridCoverage({
    super.id,
    super.boundedBy,
    super.rangeSet,
    super.rangeType,
    this.domainSet,
  });

  /// The rectified grid that defines the spatial domain.
  final GmlRectifiedGrid? domainSet;
}

/// A coverage whose domain is a [GmlGrid].
final class GmlGridCoverage extends GmlCoverage {
  /// Creates a [GmlGridCoverage].
  const GmlGridCoverage({
    super.id,
    super.boundedBy,
    super.rangeSet,
    super.rangeType,
    this.domainSet,
  });

  /// The grid that defines the spatial domain.
  final GmlGrid? domainSet;
}

/// A coverage whose domain is a referenceable
/// (non-rectified) [GmlGrid].
final class GmlReferenceableGridCoverage
    extends GmlCoverage {
  /// Creates a [GmlReferenceableGridCoverage].
  const GmlReferenceableGridCoverage({
    super.id,
    super.boundedBy,
    super.rangeSet,
    super.rangeType,
    this.domainSet,
  });

  /// The referenceable grid that defines the spatial
  /// domain.
  final GmlGrid? domainSet;
}

/// A coverage whose domain is a set of discrete points.
final class GmlMultiPointCoverage
    extends GmlCoverage {
  /// Creates a [GmlMultiPointCoverage].
  const GmlMultiPointCoverage({
    super.id,
    super.boundedBy,
    super.rangeSet,
    super.rangeType,
    this.domainSet,
  });

  /// The multi-point geometry that defines the spatial
  /// domain.
  final GmlMultiPoint? domainSet;
}
