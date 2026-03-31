part of '../gml4dart_base.dart';

sealed class GmlGeometry extends GmlNode implements GmlRootContent {
  const GmlGeometry({this.version, this.srsName});

  final GmlVersion? version;
  final String? srsName;
}

final class GmlPoint extends GmlGeometry {
  const GmlPoint({required this.coordinate, super.version, super.srsName});

  final GmlCoordinate coordinate;
}

final class GmlLineString extends GmlGeometry {
  const GmlLineString({
    required this.coordinates,
    super.version,
    super.srsName,
  });

  final List<GmlCoordinate> coordinates;
}

final class GmlLinearRing extends GmlGeometry {
  const GmlLinearRing({
    required this.coordinates,
    super.version,
    super.srsName,
  });

  final List<GmlCoordinate> coordinates;
}

final class GmlPolygon extends GmlGeometry {
  const GmlPolygon({
    required this.exterior,
    this.interiors = const [],
    super.version,
    super.srsName,
  });

  final GmlLinearRing exterior;
  final List<GmlLinearRing> interiors;
}

final class GmlEnvelope extends GmlGeometry {
  const GmlEnvelope({
    required this.lowerCorner,
    required this.upperCorner,
    super.version,
    super.srsName,
  });

  final GmlCoordinate lowerCorner;
  final GmlCoordinate upperCorner;
}

final class GmlBox extends GmlGeometry {
  const GmlBox({
    required this.lowerCorner,
    required this.upperCorner,
    super.version,
    super.srsName,
  });

  final GmlCoordinate lowerCorner;
  final GmlCoordinate upperCorner;
}

final class GmlCurve extends GmlGeometry {
  const GmlCurve({required this.coordinates, super.version, super.srsName});

  final List<GmlCoordinate> coordinates;
}

final class GmlSurface extends GmlGeometry {
  const GmlSurface({required this.patches, super.version, super.srsName});

  final List<GmlPolygon> patches;
}

final class GmlMultiPoint extends GmlGeometry {
  const GmlMultiPoint({required this.points, super.version, super.srsName});

  final List<GmlPoint> points;
}

final class GmlMultiLineString extends GmlGeometry {
  const GmlMultiLineString({
    required this.lineStrings,
    super.version,
    super.srsName,
  });

  final List<GmlLineString> lineStrings;
}

final class GmlMultiPolygon extends GmlGeometry {
  const GmlMultiPolygon({
    required this.polygons,
    super.version,
    super.srsName,
  });

  final List<GmlPolygon> polygons;
}
