part of '../gml4dart_base.dart';

/// Converts GML model types to GeoJSON maps and
/// JSON strings.
class GeoJsonBuilder {
  GeoJsonBuilder._();

  /// Converts a [GmlGeometry] to a GeoJSON geometry
  /// map. Returns `null` for unsupported types.
  static Map<String, dynamic>? geometry(
    GmlGeometry geom,
  ) =>
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

  /// Converts a [GmlFeature] to a GeoJSON Feature.
  static Map<String, dynamic> feature(
    GmlFeature feat,
  ) {
    Map<String, dynamic>? geojsonGeom;
    final props = <String, dynamic>{};

    for (final entry in feat.properties.entries) {
      if (entry.value is GmlGeometryProperty) {
        geojsonGeom ??= geometry(
          (entry.value as GmlGeometryProperty)
              .geometry,
        );
      } else {
        props[entry.key] =
            _propertyToJson(entry.value);
      }
    }

    return {
      'type': 'Feature',
      if (feat.id != null) 'id': feat.id,
      'geometry': geojsonGeom,
      'properties': props,
    };
  }

  /// Converts a [GmlFeatureCollection] to a GeoJSON
  /// FeatureCollection.
  static Map<String, dynamic> featureCollection(
    GmlFeatureCollection fc,
  ) =>
      {
        'type': 'FeatureCollection',
        'features':
            fc.features.map(feature).toList(),
      };

  /// Converts a [GmlDocument] to GeoJSON.
  /// Returns `null` if the root type is not
  /// convertible.
  static Map<String, dynamic>? document(
    GmlDocument doc,
  ) =>
      switch (doc.root) {
        final GmlGeometry g => geometry(g),
        final GmlFeature f => feature(f),
        final GmlFeatureCollection fc =>
          featureCollection(fc),
        GmlCoverage() => null,
      };

  /// Converts a [GmlGeometry] to a GeoJSON JSON
  /// string.
  static String? geometryToJson(
    GmlGeometry geom,
  ) {
    final map = geometry(geom);
    return map != null ? json.encode(map) : null;
  }

  /// Converts a [GmlFeature] to a GeoJSON JSON
  /// string.
  static String featureToJson(GmlFeature feat) =>
      json.encode(feature(feat));

  /// Converts a [GmlFeatureCollection] to a GeoJSON
  /// JSON string.
  static String featureCollectionToJson(
    GmlFeatureCollection fc,
  ) =>
      json.encode(featureCollection(fc));

  // --- Geometry converters ---

  static Map<String, dynamic> _point(GmlPoint p) =>
      {
        'type': 'Point',
        'coordinates': _coord(p.coordinate),
      };

  static Map<String, dynamic> _lineString(
    GmlLineString ls,
  ) =>
      {
        'type': 'LineString',
        'coordinates':
            ls.coordinates.map(_coord).toList(),
      };

  static Map<String, dynamic> _linearRing(
    GmlLinearRing ring,
  ) =>
      {
        'type': 'LineString',
        'coordinates':
            ring.coordinates.map(_coord).toList(),
      };

  static Map<String, dynamic> _polygon(
    GmlPolygon poly,
  ) =>
      {
        'type': 'Polygon',
        'coordinates': [
          poly.exterior.coordinates
              .map(_coord)
              .toList(),
          ...poly.interiors.map(
            (r) =>
                r.coordinates.map(_coord).toList(),
          ),
        ],
      };

  static Map<String, dynamic> _multiPoint(
    GmlMultiPoint mp,
  ) =>
      {
        'type': 'MultiPoint',
        'coordinates': mp.points
            .map((p) => _coord(p.coordinate))
            .toList(),
      };

  static Map<String, dynamic> _multiLineString(
    GmlMultiLineString mls,
  ) =>
      {
        'type': 'MultiLineString',
        'coordinates': mls.lineStrings
            .map(
              (ls) =>
                  ls.coordinates.map(_coord).toList(),
            )
            .toList(),
      };

  static Map<String, dynamic> _multiPolygon(
    GmlMultiPolygon mp,
  ) =>
      {
        'type': 'MultiPolygon',
        'coordinates': mp.polygons
            .map(
              (poly) => [
                poly.exterior.coordinates
                    .map(_coord)
                    .toList(),
                ...poly.interiors.map(
                  (r) => r.coordinates
                      .map(_coord)
                      .toList(),
                ),
              ],
            )
            .toList(),
      };

  static Map<String, dynamic> _curve(GmlCurve c) =>
      {
        'type': 'LineString',
        'coordinates':
            c.coordinates.map(_coord).toList(),
      };

  static Map<String, dynamic> _surface(
    GmlSurface s,
  ) =>
      {
        'type': 'MultiPolygon',
        'coordinates': s.patches
            .map(
              (poly) => [
                poly.exterior.coordinates
                    .map(_coord)
                    .toList(),
                ...poly.interiors.map(
                  (r) => r.coordinates
                      .map(_coord)
                      .toList(),
                ),
              ],
            )
            .toList(),
      };

  static Map<String, dynamic> _envelope(
    GmlEnvelope env,
  ) =>
      _bboxToPolygon(env.lowerCorner, env.upperCorner);

  static Map<String, dynamic> _box(GmlBox box) =>
      _bboxToPolygon(box.lowerCorner, box.upperCorner);

  static Map<String, dynamic> _bboxToPolygon(
    GmlCoordinate lower,
    GmlCoordinate upper,
  ) =>
      {
        'type': 'Polygon',
        'coordinates': [
          [
            _coord(lower),
            [upper.x, lower.y],
            _coord(upper),
            [lower.x, upper.y],
            _coord(lower),
          ],
        ],
      };

  // --- Helpers ---

  static List<double> _coord(GmlCoordinate c) => [
        c.x,
        c.y,
        if (c.z != null) c.z!,
      ];

  static dynamic _propertyToJson(
    GmlPropertyValue value,
  ) =>
      switch (value) {
        GmlStringProperty() => value.value,
        GmlNumericProperty() => value.value,
        GmlGeometryProperty() =>
          geometry(value.geometry),
        GmlNestedProperty() => {
            for (final e in value.children.entries)
              e.key: _propertyToJson(e.value),
          },
        GmlRawXmlProperty() => value.xmlContent,
      };
}
