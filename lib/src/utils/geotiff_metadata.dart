part of '../gml4dart_base.dart';

/// GeoTIFF-compatible metadata extracted from a
/// grid-based GML coverage.
final class GeoTiffMetadata {
  /// Creates a [GeoTiffMetadata].
  const GeoTiffMetadata({
    required this.width,
    required this.height,
    this.bbox,
    this.crs,
    this.transform,
    this.resolution,
    this.origin,
    this.bands,
    this.bandInfo,
  });

  /// Image width in pixels.
  final int width;

  /// Image height in pixels.
  final int height;

  /// Geographic bounds [minX, minY, maxX, maxY].
  final List<double>? bbox;

  /// Coordinate Reference System (e.g. EPSG code).
  final String? crs;

  /// Affine transform [a, b, c, d, e, f].
  /// x_geo = a*col + b*row + c
  /// y_geo = d*col + e*row + f
  final List<double>? transform;

  /// Pixel resolution [xRes, yRes].
  final List<double>? resolution;

  /// Origin in world coordinates.
  final List<double>? origin;

  /// Number of bands/channels.
  final int? bands;

  /// Per-band metadata.
  final List<GmlRangeField>? bandInfo;
}

/// Extracts GeoTIFF-compatible metadata from a
/// grid-based [GmlCoverage].
///
/// Returns `null` for [GmlMultiPointCoverage] or
/// coverages without a grid domain.
GeoTiffMetadata? extractGeoTiffMetadata(
  GmlCoverage coverage,
) {
  if (coverage is GmlMultiPointCoverage) return null;

  // Extract grid info
  int? width;
  int? height;
  List<double>? origin;
  List<List<double>>? offsetVectors;
  String? crs;

  if (coverage is GmlRectifiedGridCoverage) {
    final grid = coverage.domainSet;
    if (grid == null) return null;

    final limits = grid.limits;
    width = limits.high[0] - limits.low[0] + 1;
    height = limits.high.length > 1
        ? limits.high[1] - limits.low[1] + 1
        : 1;
    origin = grid.origin;
    offsetVectors = grid.offsetVectors;
    crs = grid.srsName;
  } else if (coverage is GmlGridCoverage) {
    final grid = coverage.domainSet;
    if (grid == null) return null;

    final limits = grid.limits;
    width = limits.high[0] - limits.low[0] + 1;
    height = limits.high.length > 1
        ? limits.high[1] - limits.low[1] + 1
        : 1;
  } else if (coverage
      is GmlReferenceableGridCoverage) {
    final grid = coverage.domainSet;
    if (grid == null) return null;

    final limits = grid.limits;
    width = limits.high[0] - limits.low[0] + 1;
    height = limits.high.length > 1
        ? limits.high[1] - limits.low[1] + 1
        : 1;
  }

  if (width == null || height == null) return null;

  // Build affine transform
  List<double>? transform;
  List<double>? resolution;
  if (offsetVectors != null &&
      offsetVectors.length >= 2 &&
      origin != null) {
    // a=xScale, b=xSkew, c=xOrigin,
    // d=ySkew, e=yScale, f=yOrigin
    transform = [
      offsetVectors[0][0],
      if (offsetVectors[0].length > 1)
        offsetVectors[1][0]
      else
        0.0,
      origin[0],
      if (offsetVectors.length > 1 &&
          offsetVectors[0].length > 1)
        offsetVectors[0][1]
      else
        0.0,
      if (offsetVectors.length > 1)
        offsetVectors[1].length > 1
            ? offsetVectors[1][1]
            : offsetVectors[1][0]
      else
        0.0,
      origin.length > 1 ? origin[1] : 0.0,
    ];
    resolution = [
      offsetVectors[0][0].abs(),
      if (offsetVectors.length > 1 &&
          offsetVectors[1].length > 1)
        offsetVectors[1][1].abs()
      else if (offsetVectors.length > 1)
        offsetVectors[1][0].abs()
      else
        0.0,
    ];
  }

  // Bounding box from envelope
  List<double>? bbox;
  crs ??= coverage.boundedBy?.srsName;
  if (coverage.boundedBy != null) {
    final env = coverage.boundedBy!;
    bbox = [
      env.lowerCorner.x,
      env.lowerCorner.y,
      env.upperCorner.x,
      env.upperCorner.y,
    ];
  }

  // Band info
  final rangeType = coverage.rangeType;
  final bandInfo = rangeType?.fields;
  final bands = bandInfo?.length;

  return GeoTiffMetadata(
    width: width,
    height: height,
    bbox: bbox,
    crs: crs,
    transform: transform,
    resolution: resolution,
    origin: origin,
    bands: bands,
    bandInfo: bandInfo,
  );
}

/// Converts pixel coordinates to world coordinates
/// using the affine transform.
///
/// Returns `[x_world, y_world]` or `null` if
/// transform is missing or invalid.
List<double>? pixelToWorld(
  double col,
  double row,
  GeoTiffMetadata metadata,
) {
  final t = metadata.transform;
  if (t == null || t.length < 6) return null;
  return [
    t[0] * col + t[1] * row + t[2],
    t[3] * col + t[4] * row + t[5],
  ];
}

/// Converts world coordinates to pixel coordinates
/// using the affine transform.
///
/// Returns `[col, row]` or `null` if transform is
/// missing or non-invertible.
List<double>? worldToPixel(
  double x,
  double y,
  GeoTiffMetadata metadata,
) {
  final t = metadata.transform;
  if (t == null || t.length < 6) return null;

  final det = t[0] * t[4] - t[1] * t[3];
  if (det == 0) return null;

  final dx = x - t[2];
  final dy = y - t[5];
  return [
    (t[4] * dx - t[1] * dy) / det,
    (-t[3] * dx + t[0] * dy) / det,
  ];
}
