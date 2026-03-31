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
    'Curve' => _parseCurve(element, issues),
    'Surface' => _parseSurface(element, issues),
    'MultiPoint' =>
      _parseMultiPoint(element, issues),
    'MultiLineString' =>
      _parseMultiLineString(element, issues),
    'MultiCurve' =>
      _parseMultiCurve(element, issues),
    'MultiPolygon' =>
      _parseMultiPolygon(element, issues),
    'MultiSurface' =>
      _parseMultiSurface(element, issues),
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

// --- Phase 3: Extended geometries ---

GmlCurve? _parseCurve(
  XmlElement element,
  List<GmlParseIssue> issues,
) {
  final coords = <GmlCoordinate>[];

  // <gml:segments><gml:LineStringSegment>
  final segments =
      _findGmlChild(element, 'segments');
  if (segments != null) {
    for (final seg in segments.childElements) {
      if (_isGmlNamespace(seg.namespaceUri)) {
        coords.addAll(
          _parseCoordsFromElement(seg, issues),
        );
      }
    }
  }

  if (coords.isEmpty) {
    // Fallback: direct coordinates on Curve
    coords.addAll(
      _parseCoordsFromElement(element, issues),
    );
  }

  if (coords.isEmpty) {
    issues.add(GmlParseIssue(
      severity: GmlIssueSeverity.error,
      code: 'missing_coordinates',
      message: 'Curve element has no coordinates',
      location: element.name.qualified,
    ));
    return null;
  }

  return GmlCurve(
    coordinates: coords,
    srsName: _getSrsName(element),
  );
}

GmlSurface? _parseSurface(
  XmlElement element,
  List<GmlParseIssue> issues,
) {
  final patches = <GmlPolygon>[];

  // <gml:patches><gml:PolygonPatch>
  final patchesEl =
      _findGmlChild(element, 'patches');
  if (patchesEl != null) {
    for (final patch in patchesEl.childElements) {
      if (_isGmlNamespace(patch.namespaceUri)) {
        // PolygonPatch has same structure as Polygon
        final poly = _parsePolygon(patch, issues);
        if (poly != null) patches.add(poly);
      }
    }
  }

  if (patches.isEmpty) {
    issues.add(GmlParseIssue(
      severity: GmlIssueSeverity.error,
      code: 'missing_patches',
      message: 'Surface element has no patches',
      location: element.name.qualified,
    ));
    return null;
  }

  return GmlSurface(
    patches: patches,
    srsName: _getSrsName(element),
  );
}

GmlMultiPoint? _parseMultiPoint(
  XmlElement element,
  List<GmlParseIssue> issues,
) {
  final points = <GmlPoint>[];

  // <gml:pointMember><gml:Point>
  for (final member
      in _findGmlChildren(element, 'pointMember')) {
    final pointEl = _findGmlChild(member, 'Point');
    if (pointEl != null) {
      final p = _parsePoint(pointEl, issues);
      if (p != null) points.add(p);
    }
  }

  // <gml:pointMembers> (plural)
  final membersEl =
      _findGmlChild(element, 'pointMembers');
  if (membersEl != null) {
    for (final child in membersEl.childElements) {
      if (_isGmlNamespace(child.namespaceUri) &&
          child.localName == 'Point') {
        final p = _parsePoint(child, issues);
        if (p != null) points.add(p);
      }
    }
  }

  return GmlMultiPoint(
    points: points,
    srsName: _getSrsName(element),
  );
}

// GML 2: <gml:MultiLineString>
GmlMultiLineString? _parseMultiLineString(
  XmlElement element,
  List<GmlParseIssue> issues,
) {
  final lineStrings = <GmlLineString>[];

  // <gml:lineStringMember><gml:LineString>
  for (final member in _findGmlChildren(
    element,
    'lineStringMember',
  )) {
    final lsEl =
        _findGmlChild(member, 'LineString');
    if (lsEl != null) {
      final ls = _parseLineString(lsEl, issues);
      if (ls != null) lineStrings.add(ls);
    }
  }

  return GmlMultiLineString(
    lineStrings: lineStrings,
    srsName: _getSrsName(element),
  );
}

// GML 3: <gml:MultiCurve> → GmlMultiLineString
GmlMultiLineString? _parseMultiCurve(
  XmlElement element,
  List<GmlParseIssue> issues,
) {
  final lineStrings = <GmlLineString>[];

  // <gml:curveMember>
  for (final member
      in _findGmlChildren(element, 'curveMember')) {
    final child = member.childElements.firstOrNull;
    if (child != null &&
        _isGmlNamespace(child.namespaceUri)) {
      if (child.localName == 'LineString') {
        final ls = _parseLineString(child, issues);
        if (ls != null) lineStrings.add(ls);
      } else if (child.localName == 'Curve') {
        // Flatten Curve segments into a LineString
        final curve = _parseCurve(child, issues);
        if (curve != null) {
          lineStrings.add(GmlLineString(
            coordinates: curve.coordinates,
            srsName: curve.srsName,
          ));
        }
      }
    }
  }

  // <gml:curveMembers> (plural)
  final membersEl =
      _findGmlChild(element, 'curveMembers');
  if (membersEl != null) {
    for (final child in membersEl.childElements) {
      if (!_isGmlNamespace(child.namespaceUri)) {
        continue;
      }
      if (child.localName == 'LineString') {
        final ls = _parseLineString(child, issues);
        if (ls != null) lineStrings.add(ls);
      } else if (child.localName == 'Curve') {
        final curve = _parseCurve(child, issues);
        if (curve != null) {
          lineStrings.add(GmlLineString(
            coordinates: curve.coordinates,
            srsName: curve.srsName,
          ));
        }
      }
    }
  }

  return GmlMultiLineString(
    lineStrings: lineStrings,
    srsName: _getSrsName(element),
  );
}

// GML 2: <gml:MultiPolygon>
GmlMultiPolygon? _parseMultiPolygon(
  XmlElement element,
  List<GmlParseIssue> issues,
) {
  final polygons = <GmlPolygon>[];

  // <gml:polygonMember><gml:Polygon>
  for (final member
      in _findGmlChildren(element, 'polygonMember')) {
    final polyEl = _findGmlChild(member, 'Polygon');
    if (polyEl != null) {
      final poly = _parsePolygon(polyEl, issues);
      if (poly != null) polygons.add(poly);
    }
  }

  return GmlMultiPolygon(
    polygons: polygons,
    srsName: _getSrsName(element),
  );
}

// GML 3: <gml:MultiSurface> → GmlMultiPolygon
GmlMultiPolygon? _parseMultiSurface(
  XmlElement element,
  List<GmlParseIssue> issues,
) {
  final polygons = <GmlPolygon>[];

  // <gml:surfaceMember>
  for (final member in _findGmlChildren(
    element,
    'surfaceMember',
  )) {
    final child = member.childElements.firstOrNull;
    if (child != null &&
        _isGmlNamespace(child.namespaceUri) &&
        child.localName == 'Polygon') {
      final poly = _parsePolygon(child, issues);
      if (poly != null) polygons.add(poly);
    }
  }

  // <gml:surfaceMembers> (plural)
  final membersEl =
      _findGmlChild(element, 'surfaceMembers');
  if (membersEl != null) {
    for (final child in membersEl.childElements) {
      if (_isGmlNamespace(child.namespaceUri) &&
          child.localName == 'Polygon') {
        final poly = _parsePolygon(child, issues);
        if (poly != null) polygons.add(poly);
      }
    }
  }

  return GmlMultiPolygon(
    polygons: polygons,
    srsName: _getSrsName(element),
  );
}
