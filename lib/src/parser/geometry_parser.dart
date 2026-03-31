part of '../gml4dart_base.dart';

GmlGeometry? _parseGeometry(
  XmlElement element,
  List<GmlParseIssue> issues,
) {
  if (!_isGmlNamespace(element.namespaceUri)) {
    return null;
  }

  return switch (element.localName) {
    'Point' => _parsePoint(element, issues),
    'LineString' =>
      _parseLineString(element, issues),
    'LinearRing' =>
      _parseLinearRing(element, issues),
    'Polygon' => _parsePolygon(element, issues),
    'Envelope' => _parseEnvelope(element, issues),
    'Box' => _parseBox(element, issues),
    _ => null,
  };
}

GmlPoint? _parsePoint(
  XmlElement element,
  List<GmlParseIssue> issues,
) {
  final coords =
      _parseCoordsFromElement(element, issues);
  if (coords.isEmpty) {
    issues.add(GmlParseIssue(
      severity: GmlIssueSeverity.error,
      code: 'missing_coordinates',
      message: 'Point element has no coordinates',
      location: element.name.qualified,
    ));
    return null;
  }
  return GmlPoint(
    coordinate: coords.first,
    srsName: _getSrsName(element),
  );
}

GmlLineString? _parseLineString(
  XmlElement element,
  List<GmlParseIssue> issues,
) {
  final coords =
      _parseCoordsFromElement(element, issues);
  if (coords.isEmpty) {
    issues.add(GmlParseIssue(
      severity: GmlIssueSeverity.error,
      code: 'missing_coordinates',
      message:
          'LineString element has no coordinates',
      location: element.name.qualified,
    ));
    return null;
  }
  return GmlLineString(
    coordinates: coords,
    srsName: _getSrsName(element),
  );
}

GmlLinearRing? _parseLinearRing(
  XmlElement element,
  List<GmlParseIssue> issues,
) {
  final coords =
      _parseCoordsFromElement(element, issues);
  if (coords.isEmpty) {
    issues.add(GmlParseIssue(
      severity: GmlIssueSeverity.error,
      code: 'missing_coordinates',
      message:
          'LinearRing element has no coordinates',
      location: element.name.qualified,
    ));
    return null;
  }
  return GmlLinearRing(
    coordinates: coords,
    srsName: _getSrsName(element),
  );
}

GmlPolygon? _parsePolygon(
  XmlElement element,
  List<GmlParseIssue> issues,
) {
  GmlLinearRing? exterior;
  final interiors = <GmlLinearRing>[];

  // GML 3: <exterior>
  final exteriorEl =
      _findGmlChild(element, 'exterior');
  if (exteriorEl != null) {
    final ring =
        _findGmlChild(exteriorEl, 'LinearRing');
    if (ring != null) {
      exterior = _parseLinearRing(ring, issues);
    }
  }

  // GML 2: <outerBoundaryIs>
  if (exterior == null) {
    final outerBoundary =
        _findGmlChild(element, 'outerBoundaryIs');
    if (outerBoundary != null) {
      final ring =
          _findGmlChild(outerBoundary, 'LinearRing');
      if (ring != null) {
        exterior = _parseLinearRing(ring, issues);
      }
    }
  }

  if (exterior == null) {
    issues.add(GmlParseIssue(
      severity: GmlIssueSeverity.error,
      code: 'missing_exterior',
      message: 'Polygon has no exterior ring',
      location: element.name.qualified,
    ));
    return null;
  }

  // GML 3: <interior>
  for (final interiorEl
      in _findGmlChildren(element, 'interior')) {
    final ring =
        _findGmlChild(interiorEl, 'LinearRing');
    if (ring != null) {
      final parsed =
          _parseLinearRing(ring, issues);
      if (parsed != null) interiors.add(parsed);
    }
  }

  // GML 2: <innerBoundaryIs>
  for (final innerBoundary
      in _findGmlChildren(element, 'innerBoundaryIs')) {
    final ring =
        _findGmlChild(innerBoundary, 'LinearRing');
    if (ring != null) {
      final parsed =
          _parseLinearRing(ring, issues);
      if (parsed != null) interiors.add(parsed);
    }
  }

  return GmlPolygon(
    exterior: exterior,
    interiors: interiors,
    srsName: _getSrsName(element),
  );
}

GmlEnvelope? _parseEnvelope(
  XmlElement element,
  List<GmlParseIssue> issues,
) {
  final lowerEl =
      _findGmlChild(element, 'lowerCorner');
  final upperEl =
      _findGmlChild(element, 'upperCorner');

  if (lowerEl == null || upperEl == null) {
    issues.add(GmlParseIssue(
      severity: GmlIssueSeverity.error,
      code: 'missing_corners',
      message:
          'Envelope missing lowerCorner or '
          'upperCorner',
      location: element.name.qualified,
    ));
    return null;
  }

  return GmlEnvelope(
    lowerCorner: _parsePos(lowerEl.innerText),
    upperCorner: _parsePos(upperEl.innerText),
    srsName: _getSrsName(element),
  );
}

GmlBox? _parseBox(
  XmlElement element,
  List<GmlParseIssue> issues,
) {
  final coords =
      _parseCoordsFromElement(element, issues);
  if (coords.length < 2) {
    issues.add(GmlParseIssue(
      severity: GmlIssueSeverity.error,
      code: 'missing_coordinates',
      message: 'Box needs at least 2 coordinates',
      location: element.name.qualified,
    ));
    return null;
  }
  return GmlBox(
    lowerCorner: coords[0],
    upperCorner: coords[1],
    srsName: _getSrsName(element),
  );
}
