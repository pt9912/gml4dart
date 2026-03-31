part of '../gml4dart_base.dart';

/// Parsed WCS GetCapabilities response.
final class WcsCapabilities {
  const WcsCapabilities({
    required this.version,
    this.serviceIdentification,
    this.operations = const [],
    this.coverages = const [],
    this.formats = const [],
    this.crs = const [],
  });

  final String version;
  final WcsServiceIdentification?
      serviceIdentification;
  final List<WcsOperationMetadata> operations;
  final List<WcsCoverageSummary> coverages;
  final List<String> formats;
  final List<String> crs;
}

/// Service identification from Capabilities.
final class WcsServiceIdentification {
  const WcsServiceIdentification({
    this.title,
    this.abstract_,
    this.keywords = const [],
    this.serviceType,
    this.serviceTypeVersion,
  });

  final String? title;
  final String? abstract_;
  final List<String> keywords;
  final String? serviceType;
  final String? serviceTypeVersion;
}

/// A single advertised operation.
final class WcsOperationMetadata {
  const WcsOperationMetadata({
    required this.name,
    this.getUrl,
    this.postUrl,
  });

  final String name;
  final String? getUrl;
  final String? postUrl;
}

/// Summary of a single coverage.
final class WcsCoverageSummary {
  const WcsCoverageSummary({
    required this.coverageId,
    this.coverageSubtype,
    this.title,
    this.abstract_,
    this.boundingBox,
    this.wgs84BoundingBox,
  });

  final String coverageId;
  final String? coverageSubtype;
  final String? title;
  final String? abstract_;
  final WcsBoundingBox? boundingBox;
  final WcsBoundingBox? wgs84BoundingBox;
}

/// A bounding box from Capabilities.
final class WcsBoundingBox {
  const WcsBoundingBox({
    this.crs,
    required this.lowerCorner,
    required this.upperCorner,
  });

  final String? crs;
  final List<double> lowerCorner;
  final List<double> upperCorner;
}

/// Parses WCS GetCapabilities XML responses.
class WcsCapabilitiesParser {
  WcsCapabilitiesParser._();

  /// Parses a WCS Capabilities XML string.
  static WcsCapabilities parse(String xml) {
    final doc = XmlDocument.parse(xml);
    final root = doc.rootElement;

    final version =
        root.getAttribute('version') ?? '2.0.1';

    return WcsCapabilities(
      version: version,
      serviceIdentification:
          _parseServiceId(root),
      operations: _parseOperations(root),
      coverages: _parseCoverages(root),
      formats: _parseFormats(root),
      crs: _parseCrs(root),
    );
  }
}

WcsServiceIdentification? _parseServiceId(
  XmlElement root,
) {
  final si = _findChildByLocal(
    root,
    'ServiceIdentification',
  );
  if (si == null) return null;

  return WcsServiceIdentification(
    title:
        _findChildByLocal(si, 'Title')?.innerText,
    abstract_: _findChildByLocal(si, 'Abstract')
        ?.innerText,
    keywords: _findAllByLocal(si, 'Keyword')
        .map((e) => e.innerText.trim())
        .toList(),
    serviceType:
        _findChildByLocal(si, 'ServiceType')
            ?.innerText,
    serviceTypeVersion:
        _findChildByLocal(si, 'ServiceTypeVersion')
            ?.innerText,
  );
}

List<WcsOperationMetadata> _parseOperations(
  XmlElement root,
) {
  final omEl = _findChildByLocal(
    root,
    'OperationsMetadata',
  );
  if (omEl == null) return const [];

  return _findAllByLocal(omEl, 'Operation')
      .map((op) {
    final name = op.getAttribute('name') ?? '';

    String? getUrl;
    String? postUrl;
    final httpEl = _findDescendantByLocal(op, 'HTTP');
    if (httpEl != null) {
      final getEl =
          _findChildByLocal(httpEl, 'Get');
      final postEl =
          _findChildByLocal(httpEl, 'Post');
      getUrl = getEl?.getAttribute('href') ??
          getEl?.getAttribute('xlink:href');
      postUrl = postEl?.getAttribute('href') ??
          postEl?.getAttribute('xlink:href');
    }

    return WcsOperationMetadata(
      name: name,
      getUrl: getUrl,
      postUrl: postUrl,
    );
  }).toList();
}

List<WcsCoverageSummary> _parseCoverages(
  XmlElement root,
) {
  // WCS 2.0: Contents/CoverageSummary
  final contents =
      _findChildByLocal(root, 'Contents');
  if (contents != null) {
    return _findAllByLocal(
      contents,
      'CoverageSummary',
    ).map(_parseSummary).toList();
  }

  // WCS 1.0: ContentMetadata/CoverageOfferingBrief
  final cm = _findChildByLocal(
    root,
    'ContentMetadata',
  );
  if (cm != null) {
    return _findAllByLocal(
      cm,
      'CoverageOfferingBrief',
    ).map(_parseSummary).toList();
  }

  return const [];
}

WcsCoverageSummary _parseSummary(
  XmlElement el,
) {
  final id =
      _findChildByLocal(el, 'CoverageId')
              ?.innerText
              .trim() ??
          _findChildByLocal(el, 'Identifier')
              ?.innerText
              .trim() ??
          _findChildByLocal(el, 'name')
              ?.innerText
              .trim() ??
          '';

  final subtype =
      _findChildByLocal(el, 'CoverageSubtype')
          ?.innerText
          .trim();

  final bbox =
      _parseBBox(_findChildByLocal(el, 'BoundingBox'));
  final wgs84 = _parseBBox(
    _findChildByLocal(el, 'WGS84BoundingBox'),
  );

  return WcsCoverageSummary(
    coverageId: id,
    coverageSubtype: subtype,
    title: _findChildByLocal(el, 'Title')
        ?.innerText
        .trim(),
    abstract_: _findChildByLocal(el, 'Abstract')
        ?.innerText
        .trim(),
    boundingBox: bbox,
    wgs84BoundingBox: wgs84,
  );
}

WcsBoundingBox? _parseBBox(XmlElement? el) {
  if (el == null) return null;

  final lower =
      _findChildByLocal(el, 'LowerCorner');
  final upper =
      _findChildByLocal(el, 'UpperCorner');
  if (lower == null || upper == null) return null;

  return WcsBoundingBox(
    crs: el.getAttribute('crs'),
    lowerCorner: lower.innerText
        .trim()
        .split(RegExp(r'\s+'))
        .map(double.parse)
        .toList(),
    upperCorner: upper.innerText
        .trim()
        .split(RegExp(r'\s+'))
        .map(double.parse)
        .toList(),
  );
}

List<String> _parseFormats(XmlElement root) {
  final contents =
      _findChildByLocal(root, 'Contents');
  if (contents == null) return const [];

  // WCS 2.0: ServiceMetadata/formatSupported
  final sm = _findChildByLocal(
    root,
    'ServiceMetadata',
  );
  if (sm != null) {
    return _findAllByLocal(sm, 'formatSupported')
        .map((e) => e.innerText.trim())
        .toList();
  }

  return const [];
}

List<String> _parseCrs(XmlElement root) {
  final sm = _findChildByLocal(
    root,
    'ServiceMetadata',
  );
  if (sm == null) return const [];

  final ext =
      _findChildByLocal(sm, 'Extension');
  if (ext == null) return const [];

  return _findAllByLocal(ext, 'CrsSupported')
      .map((e) => e.innerText.trim())
      .toList();
}

// --- XML helpers (namespace-agnostic) ---

XmlElement? _findChildByLocal(
  XmlElement parent,
  String localName,
) =>
    parent.childElements
        .where((e) => e.localName == localName)
        .firstOrNull;

List<XmlElement> _findAllByLocal(
  XmlElement parent,
  String localName,
) =>
    parent.childElements
        .where((e) => e.localName == localName)
        .toList();

XmlElement? _findDescendantByLocal(
  XmlElement parent,
  String localName,
) {
  for (final child in parent.childElements) {
    if (child.localName == localName) return child;
    final found =
        _findDescendantByLocal(child, localName);
    if (found != null) return found;
  }
  return null;
}
