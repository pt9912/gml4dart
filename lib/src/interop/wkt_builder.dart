part of '../gml4dart_base.dart';

/// Converts GML geometries to Well-Known Text (WKT).
class WktBuilder {
  WktBuilder._();

  /// Converts a [GmlGeometry] to a WKT string.
  /// Returns `null` for unsupported types.
  static String? geometry(GmlGeometry geom) =>
      switch (geom) {
        GmlPoint() => _point(geom),
        GmlLineString() => _lineString(geom),
        GmlLinearRing() => _linearRing(geom),
        GmlPolygon() => _polygon(geom),
        GmlMultiPoint() => _multiPoint(geom),
        GmlMultiLineString() =>
          _multiLineString(geom),
        GmlMultiPolygon() => _multiPolygon(geom),
        GmlCurve() => _curve(geom),
        GmlSurface() => _surface(geom),
        GmlEnvelope() => _envelope(geom),
        GmlBox() => _box(geom),
      };

  // --- Geometry converters ---

  static String _point(GmlPoint p) =>
      'POINT (${_coord(p.coordinate)})';

  static String _lineString(GmlLineString ls) =>
      'LINESTRING (${_coordList(ls.coordinates)})';

  static String _linearRing(GmlLinearRing ring) =>
      'LINESTRING (${_coordList(ring.coordinates)})';

  static String _polygon(GmlPolygon poly) {
    final rings = <String>[
      '(${_coordList(poly.exterior.coordinates)})',
      ...poly.interiors.map(
        (r) => '(${_coordList(r.coordinates)})',
      ),
    ];
    return 'POLYGON (${rings.join(', ')})';
  }

  static String _multiPoint(GmlMultiPoint mp) {
    final pts = mp.points
        .map((p) => '(${_coord(p.coordinate)})')
        .join(', ');
    return 'MULTIPOINT ($pts)';
  }

  static String _multiLineString(
    GmlMultiLineString mls,
  ) {
    final lines = mls.lineStrings
        .map(
          (ls) => '(${_coordList(ls.coordinates)})',
        )
        .join(', ');
    return 'MULTILINESTRING ($lines)';
  }

  static String _multiPolygon(GmlMultiPolygon mp) {
    final polys = mp.polygons.map((poly) {
      final rings = <String>[
        '(${_coordList(poly.exterior.coordinates)})',
        ...poly.interiors.map(
          (r) => '(${_coordList(r.coordinates)})',
        ),
      ];
      return '(${rings.join(', ')})';
    }).join(', ');
    return 'MULTIPOLYGON ($polys)';
  }

  static String _curve(GmlCurve c) =>
      'LINESTRING (${_coordList(c.coordinates)})';

  static String _surface(GmlSurface s) {
    final polys = s.patches.map((poly) {
      final rings = <String>[
        '(${_coordList(poly.exterior.coordinates)})',
        ...poly.interiors.map(
          (r) => '(${_coordList(r.coordinates)})',
        ),
      ];
      return '(${rings.join(', ')})';
    }).join(', ');
    return 'MULTIPOLYGON ($polys)';
  }

  static String _envelope(GmlEnvelope env) =>
      _bboxWkt(env.lowerCorner, env.upperCorner);

  static String _box(GmlBox box) =>
      _bboxWkt(box.lowerCorner, box.upperCorner);

  static String _bboxWkt(
    GmlCoordinate lower,
    GmlCoordinate upper,
  ) {
    const c = _coord;
    return 'POLYGON ((${c(lower)}, '
        '${upper.x} ${lower.y}, '
        '${c(upper)}, '
        '${lower.x} ${upper.y}, '
        '${c(lower)}))';
  }

  // --- Helpers ---

  static String _coord(GmlCoordinate c) => c.z != null
      ? '${c.x} ${c.y} ${c.z}'
      : '${c.x} ${c.y}';

  static String _coordList(
    List<GmlCoordinate> coords,
  ) =>
      coords.map(_coord).join(', ');
}
