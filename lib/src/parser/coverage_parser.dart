part of '../gml4dart_base.dart';

const _coverageLocalNames = {
  'RectifiedGridCoverage',
  'GridCoverage',
  'ReferenceableGridCoverage',
  'MultiPointCoverage',
};

bool _isCoverageElement(String localName) =>
    _coverageLocalNames.contains(localName);

GmlCoverage? _parseCoverage(
  XmlElement element,
  List<GmlParseIssue> issues,
) =>
    switch (element.localName) {
      'RectifiedGridCoverage' =>
        _parseRectifiedGridCoverage(element, issues),
      'GridCoverage' =>
        _parseGridCoverage(element, issues),
      'ReferenceableGridCoverage' =>
        _parseReferenceableGridCoverage(
          element,
          issues,
        ),
      'MultiPointCoverage' =>
        _parseMultiPointCoverage(element, issues),
      _ => null,
    };

// --- RectifiedGridCoverage ---

GmlRectifiedGridCoverage
    _parseRectifiedGridCoverage(
  XmlElement element,
  List<GmlParseIssue> issues,
) {
  final id = _getFeatureId(element);
  final boundedBy = _parseBoundedBy(element, issues);
  final domainSet =
      _parseRectifiedGridDomain(element, issues);
  final rangeSet = _parseRangeSet(element, issues);
  final rangeType = _parseRangeType(element);

  return GmlRectifiedGridCoverage(
    id: id,
    boundedBy: boundedBy,
    domainSet: domainSet,
    rangeSet: rangeSet,
    rangeType: rangeType,
  );
}

// --- GridCoverage ---

GmlGridCoverage _parseGridCoverage(
  XmlElement element,
  List<GmlParseIssue> issues,
) =>
    GmlGridCoverage(
      id: _getFeatureId(element),
      boundedBy: _parseBoundedBy(element, issues),
      domainSet: _parseGridDomain(element, issues),
      rangeSet: _parseRangeSet(element, issues),
      rangeType: _parseRangeType(element),
    );

// --- ReferenceableGridCoverage ---

GmlReferenceableGridCoverage
    _parseReferenceableGridCoverage(
  XmlElement element,
  List<GmlParseIssue> issues,
) =>
        GmlReferenceableGridCoverage(
          id: _getFeatureId(element),
          boundedBy:
              _parseBoundedBy(element, issues),
          domainSet:
              _parseGridDomain(element, issues),
          rangeSet:
              _parseRangeSet(element, issues),
          rangeType: _parseRangeType(element),
        );

// --- MultiPointCoverage ---

GmlMultiPointCoverage _parseMultiPointCoverage(
  XmlElement element,
  List<GmlParseIssue> issues,
) {
  GmlMultiPoint? domainSet;

  final domainSetEl =
      _findGmlChild(element, 'domainSet');
  if (domainSetEl != null) {
    final mpEl =
        _findGmlChild(domainSetEl, 'MultiPoint');
    if (mpEl != null) {
      domainSet =
          _parseMultiPoint(mpEl, issues);
    }
  }

  return GmlMultiPointCoverage(
    id: _getFeatureId(element),
    boundedBy: _parseBoundedBy(element, issues),
    domainSet: domainSet,
    rangeSet: _parseRangeSet(element, issues),
    rangeType: _parseRangeType(element),
  );
}

// --- Shared helpers ---

GmlEnvelope? _parseBoundedBy(
  XmlElement element,
  List<GmlParseIssue> issues,
) {
  final boundedByEl =
      _findGmlChild(element, 'boundedBy');
  if (boundedByEl == null) return null;

  final envelope =
      _findGmlChild(boundedByEl, 'Envelope');
  if (envelope == null) return null;

  final geom = _parseGeometry(envelope, issues);
  return geom is GmlEnvelope ? geom : null;
}

GmlRectifiedGrid? _parseRectifiedGridDomain(
  XmlElement element,
  List<GmlParseIssue> issues,
) {
  final domainSetEl =
      _findGmlChild(element, 'domainSet');
  if (domainSetEl == null) return null;

  final gridEl =
      _findGmlChild(domainSetEl, 'RectifiedGrid');
  if (gridEl == null) return null;

  final dim = int.tryParse(
        gridEl.getAttribute('dimension') ?? '',
      ) ??
      2;
  final srsName = _getSrsName(gridEl);
  final id = _getFeatureId(gridEl);
  final limits = _parseGridLimits(gridEl, issues);
  final axisLabels = _parseAxisLabels(gridEl);

  // Origin
  final originEl = _findGmlChild(gridEl, 'origin');
  List<double>? origin;
  if (originEl != null) {
    final pointEl =
        _findGmlChild(originEl, 'Point');
    if (pointEl != null) {
      final coords =
          _parseCoordsFromElement(pointEl, issues);
      if (coords.isNotEmpty) {
        final c = coords.first;
        origin = [c.x, c.y, if (c.z != null) c.z!];
      }
    } else {
      // Origin may contain a <pos> directly
      final posEl = _findGmlChild(originEl, 'pos');
      if (posEl != null) {
        origin = posEl.innerText
            .trim()
            .split(RegExp(r'\s+'))
            .map(double.parse)
            .toList();
      }
    }
  }

  // Offset vectors
  final offsetVectors = _findGmlChildren(
    gridEl,
    'offsetVector',
  )
      .map(
        (el) => el.innerText
            .trim()
            .split(RegExp(r'\s+'))
            .map(double.parse)
            .toList(),
      )
      .toList();

  if (limits == null || origin == null) {
    issues.add(GmlParseIssue(
      severity: GmlIssueSeverity.warning,
      code: 'incomplete_rectified_grid',
      message: 'RectifiedGrid missing '
          'limits or origin',
      location: gridEl.name.qualified,
    ));
  }

  return GmlRectifiedGrid(
    id: id,
    dimension: dim,
    limits: limits ??
        const GmlGridEnvelope(low: [0], high: [0]),
    axisLabels: axisLabels,
    srsName: srsName,
    origin: origin ?? const [0, 0],
    offsetVectors: offsetVectors,
  );
}

GmlGrid? _parseGridDomain(
  XmlElement element,
  List<GmlParseIssue> issues,
) {
  final domainSetEl =
      _findGmlChild(element, 'domainSet');
  if (domainSetEl == null) return null;

  final gridEl =
      _findGmlChild(domainSetEl, 'Grid');
  if (gridEl == null) return null;

  final dim = int.tryParse(
        gridEl.getAttribute('dimension') ?? '',
      ) ??
      2;
  final id = _getFeatureId(gridEl);
  final limits = _parseGridLimits(gridEl, issues);
  final axisLabels = _parseAxisLabels(gridEl);

  return GmlGrid(
    id: id,
    dimension: dim,
    limits: limits ??
        const GmlGridEnvelope(low: [0], high: [0]),
    axisLabels: axisLabels,
  );
}

GmlGridEnvelope? _parseGridLimits(
  XmlElement gridEl,
  List<GmlParseIssue> issues,
) {
  final limitsEl =
      _findGmlChild(gridEl, 'limits');
  if (limitsEl == null) return null;

  final envEl =
      _findGmlChild(limitsEl, 'GridEnvelope');
  if (envEl == null) return null;

  final lowEl = _findGmlChild(envEl, 'low');
  final highEl = _findGmlChild(envEl, 'high');

  if (lowEl == null || highEl == null) return null;

  return GmlGridEnvelope(
    low: lowEl.innerText
        .trim()
        .split(RegExp(r'\s+'))
        .map(int.parse)
        .toList(),
    high: highEl.innerText
        .trim()
        .split(RegExp(r'\s+'))
        .map(int.parse)
        .toList(),
  );
}

List<String>? _parseAxisLabels(XmlElement gridEl) {
  final labelsEl =
      _findGmlChild(gridEl, 'axisLabels');
  if (labelsEl == null) return null;

  final text = labelsEl.innerText.trim();
  if (text.isEmpty) return null;
  return text.split(RegExp(r'\s+'));
}

GmlRangeSet? _parseRangeSet(
  XmlElement element,
  List<GmlParseIssue> issues,
) {
  final rangeSetEl =
      _findGmlChild(element, 'rangeSet');
  if (rangeSetEl == null) return null;

  // DataBlock → tupleList
  final dataBlock =
      _findGmlChild(rangeSetEl, 'DataBlock');
  if (dataBlock != null) {
    final tupleList =
        _findGmlChild(dataBlock, 'tupleList');
    return GmlRangeSet(
      data: tupleList?.innerText.trim(),
    );
  }

  // File reference
  final fileEl = _findGmlChild(rangeSetEl, 'File');
  if (fileEl != null) {
    final fileName =
        _findGmlChild(fileEl, 'fileName') ??
            _findGmlChild(fileEl, 'rangeParameters');
    final fileStructure =
        _findGmlChild(fileEl, 'fileStructure');
    if (fileName != null) {
      return GmlRangeSet(
        file: GmlFileReference(
          fileName: fileName.innerText.trim(),
          fileStructure:
              fileStructure?.innerText.trim(),
        ),
      );
    }
  }

  return const GmlRangeSet();
}

GmlRangeType? _parseRangeType(XmlElement element) {
  // rangeType lives in gmlcov or swe namespace
  // — search any child named 'rangeType'
  final rangeTypeEl = element.childElements
      .where((e) => e.localName == 'rangeType')
      .firstOrNull;
  if (rangeTypeEl == null) return null;

  // Look for DataRecord → field elements
  final dataRecord = rangeTypeEl.childElements
      .where((e) => e.localName == 'DataRecord')
      .firstOrNull;
  if (dataRecord == null) return null;

  final fields = <GmlRangeField>[];
  for (final fieldEl in dataRecord.childElements
      .where((e) => e.localName == 'field')) {
    final name = fieldEl.getAttribute('name') ?? '';

    String? uom;
    String? description;
    // Look for Quantity child
    final quantity = fieldEl.childElements
        .where((e) => e.localName == 'Quantity')
        .firstOrNull;
    if (quantity != null) {
      final uomEl = quantity.childElements
          .where((e) => e.localName == 'uom')
          .firstOrNull;
      uom = uomEl?.getAttribute('code');

      final descEl = quantity.childElements
          .where(
            (e) => e.localName == 'description',
          )
          .firstOrNull;
      description = descEl?.innerText.trim();
    }

    fields.add(GmlRangeField(
      name: name,
      uom: uom,
      description: description,
    ));
  }

  return GmlRangeType(fields: fields);
}
