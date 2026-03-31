part of '../gml4dart_base.dart';

// GML namespace URIs
const _gmlNs2 = 'http://www.opengis.net/gml';
const _gmlNs32 = 'http://www.opengis.net/gml/3.2';
const _gmlNs33 = 'http://www.opengis.net/gml/3.3';

// WFS namespace URIs
const _wfsNs1 = 'http://www.opengis.net/wfs';
const _wfsNs2 = 'http://www.opengis.net/wfs/2.0';

const _gmlNamespaces = {_gmlNs2, _gmlNs32, _gmlNs33};
const _wfsNamespaces = {_wfsNs1, _wfsNs2};

bool _isGmlNamespace(String? ns) =>
    _gmlNamespaces.contains(ns);

bool _isWfsNamespace(String? ns) =>
    _wfsNamespaces.contains(ns);

// --- Version detection ---

GmlVersion _detectVersion(XmlElement root) {
  final ns = _findGmlNamespaceUri(root);
  if (ns == _gmlNs33) return GmlVersion.v3_3;
  if (ns == _gmlNs32) return GmlVersion.v3_2;
  if (ns == _gmlNs2 && _hasGml2Indicators(root)) {
    return GmlVersion.v2_1_2;
  }
  if (ns == _gmlNs2) return GmlVersion.v3_1;
  return GmlVersion.v3_2;
}

String? _findGmlNamespaceUri(XmlElement root) {
  if (_isGmlNamespace(root.namespaceUri)) {
    return root.namespaceUri;
  }

  for (final attr in root.attributes) {
    if (_gmlNamespaces.contains(attr.value)) {
      return attr.value;
    }
  }

  for (final child in root.childElements) {
    if (_isGmlNamespace(child.namespaceUri)) {
      return child.namespaceUri;
    }
    for (final grandchild in child.childElements) {
      if (_isGmlNamespace(grandchild.namespaceUri)) {
        return grandchild.namespaceUri;
      }
    }
  }
  return null;
}

bool _hasGml2Indicators(XmlElement root) =>
    _anyDescendant(root, (e) {
      final n = e.localName;
      return n == 'coordinates' ||
          n == 'Box' ||
          n == 'outerBoundaryIs';
    });

bool _anyDescendant(
  XmlElement element,
  bool Function(XmlElement) test, {
  int depth = 0,
  int maxDepth = 5,
}) {
  if (depth > maxDepth) return false;
  for (final child in element.childElements) {
    if (test(child)) return true;
    if (_anyDescendant(child, test,
        depth: depth + 1, maxDepth: maxDepth)) {
      return true;
    }
  }
  return false;
}

// --- Element finders ---

XmlElement? _findGmlChild(
  XmlElement parent,
  String localName,
) =>
    parent.childElements
        .where(
          (e) =>
              e.localName == localName &&
              _isGmlNamespace(e.namespaceUri),
        )
        .firstOrNull;

List<XmlElement> _findGmlChildren(
  XmlElement parent,
  String localName,
) =>
    parent.childElements
        .where(
          (e) =>
              e.localName == localName &&
              _isGmlNamespace(e.namespaceUri),
        )
        .toList();

List<XmlElement> _findWfsChildren(
  XmlElement parent,
  String localName,
) =>
    parent.childElements
        .where(
          (e) =>
              e.localName == localName &&
              _isWfsNamespace(e.namespaceUri),
        )
        .toList();

// --- Attribute helpers ---

String? _getSrsName(XmlElement element) =>
    element.getAttribute('srsName');

int _getSrsDimension(XmlElement element) {
  final dim = element.getAttribute('srsDimension');
  if (dim != null) return int.parse(dim);
  return 2;
}

String? _getFeatureId(XmlElement element) {
  for (final ns in _gmlNamespaces) {
    final id =
        element.getAttribute('id', namespace: ns);
    if (id != null) return id;
  }
  return element.getAttribute('fid');
}

// --- Coordinate parsing ---

GmlCoordinate _parsePos(
  String text, {
  int? srsDimension,
}) {
  final parts = text.trim().split(RegExp(r'\s+'));
  final dim = srsDimension ?? parts.length;
  return GmlCoordinate(
    double.parse(parts[0]),
    double.parse(parts[1]),
    dim >= 3 && parts.length >= 3
        ? double.parse(parts[2])
        : null,
    dim >= 4 && parts.length >= 4
        ? double.parse(parts[3])
        : null,
  );
}

List<GmlCoordinate> _parsePosList(
  String text, {
  int srsDimension = 2,
}) {
  final values = text
      .trim()
      .split(RegExp(r'\s+'))
      .map(double.parse)
      .toList();
  final coords = <GmlCoordinate>[];
  for (var i = 0;
      i + srsDimension <= values.length;
      i += srsDimension) {
    coords.add(GmlCoordinate(
      values[i],
      values[i + 1],
      srsDimension >= 3 ? values[i + 2] : null,
      srsDimension >= 4 ? values[i + 3] : null,
    ));
  }
  return coords;
}

List<GmlCoordinate> _parseGml2Coordinates(
  String text,
) {
  final tuples = text.trim().split(RegExp(r'\s+'));
  return tuples.where((t) => t.isNotEmpty).map((t) {
    final parts = t.split(',');
    return GmlCoordinate(
      double.parse(parts[0]),
      double.parse(parts[1]),
      parts.length > 2
          ? double.parse(parts[2])
          : null,
    );
  }).toList();
}

List<GmlCoordinate> _parseCoordsFromElement(
  XmlElement element,
  List<GmlParseIssue> issues,
) {
  // GML 3: <posList>
  final posList = _findGmlChild(element, 'posList');
  if (posList != null) {
    final dim = _getSrsDimension(posList);
    return _parsePosList(
      posList.innerText,
      srsDimension: dim,
    );
  }

  // GML 3: multiple <pos> elements
  final posElements =
      _findGmlChildren(element, 'pos');
  if (posElements.isNotEmpty) {
    return posElements
        .map((e) => _parsePos(e.innerText))
        .toList();
  }

  // GML 2: <coordinates>
  final coordinates =
      _findGmlChild(element, 'coordinates');
  if (coordinates != null) {
    return _parseGml2Coordinates(
      coordinates.innerText,
    );
  }

  return [];
}
