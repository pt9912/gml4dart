part of '../model.dart';

final class GmlCoordinate {
  const GmlCoordinate(this.x, this.y, [this.z, this.m]);

  final double x;
  final double y;
  final double? z;
  final double? m;

  int get dimension => switch ((z, m)) {
        (null, null) => 2,
        (_, null) || (null, _) => 3,
        _ => 4,
      };
}
