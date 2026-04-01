part of '../gml4dart_base.dart';

/// A coordinate with two to four ordinate values.
final class GmlCoordinate {
  /// Creates a coordinate with [x] and [y], and
  /// optionally [z] (altitude) and [m] (measure).
  const GmlCoordinate(this.x, this.y, [this.z, this.m]);

  /// First ordinate (easting / longitude).
  final double x;

  /// Second ordinate (northing / latitude).
  final double y;

  /// Optional third ordinate (altitude).
  final double? z;

  /// Optional fourth ordinate (linear measure).
  final double? m;

  /// The number of ordinates: 2, 3, or 4.
  int get dimension => switch ((z, m)) {
        (null, null) => 2,
        (_, null) || (null, _) => 3,
        _ => 4,
      };
}
