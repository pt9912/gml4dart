part of '../gml4dart_base.dart';

/// Base class for all GML geometry types.
sealed class GmlGeometry extends GmlNode implements GmlRootContent {
  /// Creates a [GmlGeometry].
  const GmlGeometry({this.version, this.srsName});

  /// The GML version this geometry was parsed from.
  final GmlVersion? version;

  /// Spatial Reference System identifier
  /// (e.g. `'EPSG:4326'`).
  final String? srsName;
}

/// A zero-dimensional geometry representing a single
/// position.
final class GmlPoint extends GmlGeometry {
  /// Creates a [GmlPoint].
  const GmlPoint({required this.coordinate, super.version, super.srsName});

  /// The position of this point.
  final GmlCoordinate coordinate;
}

/// A one-dimensional geometry defined by a sequence of
/// connected [coordinates].
final class GmlLineString extends GmlGeometry {
  /// Creates a [GmlLineString].
  const GmlLineString({
    required this.coordinates,
    super.version,
    super.srsName,
  });

  /// Ordered vertices of the line string.
  final List<GmlCoordinate> coordinates;
}

/// A closed ring used as the boundary of a [GmlPolygon].
final class GmlLinearRing extends GmlGeometry {
  /// Creates a [GmlLinearRing].
  const GmlLinearRing({
    required this.coordinates,
    super.version,
    super.srsName,
  });

  /// Ordered vertices of the ring; the first and last
  /// coordinate should be identical.
  final List<GmlCoordinate> coordinates;
}

/// A two-dimensional surface bounded by an [exterior]
/// ring and zero or more [interiors] (holes).
final class GmlPolygon extends GmlGeometry {
  /// Creates a [GmlPolygon].
  const GmlPolygon({
    required this.exterior,
    this.interiors = const [],
    super.version,
    super.srsName,
  });

  /// The outer boundary ring.
  final GmlLinearRing exterior;

  /// Interior rings representing holes.
  final List<GmlLinearRing> interiors;
}

/// An axis-aligned bounding rectangle defined by two
/// corner coordinates (GML 3.x `gml:Envelope`).
final class GmlEnvelope extends GmlGeometry {
  /// Creates a [GmlEnvelope].
  const GmlEnvelope({
    required this.lowerCorner,
    required this.upperCorner,
    super.version,
    super.srsName,
  });

  /// The minimum-ordinate corner.
  final GmlCoordinate lowerCorner;

  /// The maximum-ordinate corner.
  final GmlCoordinate upperCorner;
}

/// An axis-aligned bounding rectangle
/// (GML 2.x `gml:Box`).
final class GmlBox extends GmlGeometry {
  /// Creates a [GmlBox].
  const GmlBox({
    required this.lowerCorner,
    required this.upperCorner,
    super.version,
    super.srsName,
  });

  /// The minimum-ordinate corner.
  final GmlCoordinate lowerCorner;

  /// The maximum-ordinate corner.
  final GmlCoordinate upperCorner;
}

/// A one-dimensional geometry consisting of curve
/// segments flattened into a coordinate list.
final class GmlCurve extends GmlGeometry {
  /// Creates a [GmlCurve].
  const GmlCurve({required this.coordinates, super.version, super.srsName});

  /// Ordered vertices of the curve.
  final List<GmlCoordinate> coordinates;
}

/// A two-dimensional surface composed of polygon
/// [patches].
final class GmlSurface extends GmlGeometry {
  /// Creates a [GmlSurface].
  const GmlSurface({required this.patches, super.version, super.srsName});

  /// The polygon patches that make up this surface.
  final List<GmlPolygon> patches;
}

/// A collection of [GmlPoint] geometries.
final class GmlMultiPoint extends GmlGeometry {
  /// Creates a [GmlMultiPoint].
  const GmlMultiPoint({required this.points, super.version, super.srsName});

  /// The member points.
  final List<GmlPoint> points;
}

/// A collection of [GmlLineString] geometries.
final class GmlMultiLineString extends GmlGeometry {
  /// Creates a [GmlMultiLineString].
  const GmlMultiLineString({
    required this.lineStrings,
    super.version,
    super.srsName,
  });

  /// The member line strings.
  final List<GmlLineString> lineStrings;
}

/// A collection of [GmlPolygon] geometries.
final class GmlMultiPolygon extends GmlGeometry {
  /// Creates a [GmlMultiPolygon].
  const GmlMultiPolygon({
    required this.polygons,
    super.version,
    super.srsName,
  });

  /// The member polygons.
  final List<GmlPolygon> polygons;
}
