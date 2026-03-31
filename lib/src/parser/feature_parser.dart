part of '../gml4dart_base.dart';

GmlFeatureCollection _parseFeatureCollection(
  XmlElement element,
  List<GmlParseIssue> issues,
) {
  final features = <GmlFeature>[];
  GmlEnvelope? boundedBy;

  // Parse boundedBy
  final boundedByEl =
      _findGmlChild(element, 'boundedBy');
  if (boundedByEl != null) {
    final envelope =
        _findGmlChild(boundedByEl, 'Envelope');
    if (envelope != null) {
      final geom = _parseGeometry(envelope, issues);
      if (geom is GmlEnvelope) boundedBy = geom;
    }
  }

  // GML 2 / WFS 1.0-1.1: <gml:featureMember>
  for (final member
      in _findGmlChildren(element, 'featureMember')) {
    final featureEl = member.childElements.firstOrNull;
    if (featureEl != null) {
      features.add(_parseFeature(featureEl, issues));
    }
  }

  // WFS 2.0: <wfs:member>
  for (final member
      in _findWfsChildren(element, 'member')) {
    final featureEl = member.childElements.firstOrNull;
    if (featureEl != null) {
      features.add(_parseFeature(featureEl, issues));
    }
  }

  // GML 3.1: <gml:featureMembers> (plural)
  final membersEl =
      _findGmlChild(element, 'featureMembers');
  if (membersEl != null) {
    for (final featureEl in membersEl.childElements) {
      features.add(_parseFeature(featureEl, issues));
    }
  }

  return GmlFeatureCollection(
    features: features,
    boundedBy: boundedBy,
  );
}

GmlFeature _parseFeature(
  XmlElement element,
  List<GmlParseIssue> issues,
) {
  final id = _getFeatureId(element);
  final properties = <String, GmlPropertyValue>{};

  for (final child in element.childElements) {
    // Skip boundedBy
    if (_isGmlNamespace(child.namespaceUri) &&
        child.localName == 'boundedBy') {
      continue;
    }

    properties[child.localName] =
        _parsePropertyValue(child, issues);
  }

  return GmlFeature(id: id, properties: properties);
}

GmlPropertyValue _parsePropertyValue(
  XmlElement element,
  List<GmlParseIssue> issues,
) {
  // Check for geometry child
  for (final child in element.childElements) {
    if (_isGmlNamespace(child.namespaceUri)) {
      final geom = _parseGeometry(child, issues);
      if (geom != null) {
        return GmlGeometryProperty(geom);
      }
    }
  }

  // Check for nested elements
  final childElements = element.childElements.toList();
  if (childElements.isNotEmpty) {
    final nested = <String, GmlPropertyValue>{};
    for (final child in childElements) {
      nested[child.localName] =
          _parsePropertyValue(child, issues);
    }
    return GmlNestedProperty(nested);
  }

  // Simple text content
  final text = element.innerText.trim();

  // Try numeric
  final numValue = num.tryParse(text);
  if (numValue != null) {
    return GmlNumericProperty(numValue);
  }

  return GmlStringProperty(text);
}
