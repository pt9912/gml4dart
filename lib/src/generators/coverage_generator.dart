part of '../gml4dart_base.dart';

/// Generates GML 3.2 XML from coverage model
/// objects.
class CoverageGenerator {
  CoverageGenerator._();

  /// Generates GML XML for a [GmlCoverage].
  static String generate(GmlCoverage coverage) =>
      switch (coverage) {
        GmlRectifiedGridCoverage() =>
          _genRectifiedGridCoverage(coverage),
        GmlGridCoverage() =>
          _genGridCoverage(coverage),
        GmlReferenceableGridCoverage() =>
          _genReferenceableGridCoverage(coverage),
        GmlMultiPointCoverage() =>
          _genMultiPointCoverage(coverage),
      };
}

String _genRectifiedGridCoverage(
  GmlRectifiedGridCoverage cov,
) {
  final buf = StringBuffer()
    ..writeln('<?xml version="1.0" '
        'encoding="UTF-8"?>')
    ..write('<gml:RectifiedGridCoverage')
    ..write(' xmlns:gml='
        '"http://www.opengis.net/gml/3.2"')
    ..write(' xmlns:gmlcov='
        '"http://www.opengis.net/gmlcov/1.0"')
    ..write(' xmlns:swe='
        '"http://www.opengis.net/swe/2.0"');
  if (cov.id != null) {
    buf.write(' gml:id="${_xmlEscape(cov.id!)}"');
  }
  buf.writeln('>');
  _writeBoundedBy(buf, cov.boundedBy);
  _writeRectifiedGridDomain(buf, cov.domainSet);
  _writeRangeSet(buf, cov.rangeSet);
  _writeRangeType(buf, cov.rangeType);
  buf.writeln('</gml:RectifiedGridCoverage>');
  return buf.toString();
}

String _genGridCoverage(GmlGridCoverage cov) {
  final buf = StringBuffer()
    ..writeln('<?xml version="1.0" '
        'encoding="UTF-8"?>')
    ..write('<gml:GridCoverage')
    ..write(' xmlns:gml='
        '"http://www.opengis.net/gml/3.2"');
  if (cov.id != null) {
    buf.write(' gml:id="${_xmlEscape(cov.id!)}"');
  }
  buf.writeln('>');
  _writeBoundedBy(buf, cov.boundedBy);
  _writeGridDomain(buf, cov.domainSet);
  _writeRangeSet(buf, cov.rangeSet);
  buf.writeln('</gml:GridCoverage>');
  return buf.toString();
}

String _genReferenceableGridCoverage(
  GmlReferenceableGridCoverage cov,
) {
  final buf = StringBuffer()
    ..writeln('<?xml version="1.0" '
        'encoding="UTF-8"?>')
    ..write('<gml:ReferenceableGridCoverage')
    ..write(' xmlns:gml='
        '"http://www.opengis.net/gml/3.2"');
  if (cov.id != null) {
    buf.write(' gml:id="${_xmlEscape(cov.id!)}"');
  }
  buf.writeln('>');
  _writeBoundedBy(buf, cov.boundedBy);
  _writeGridDomain(buf, cov.domainSet);
  _writeRangeSet(buf, cov.rangeSet);
  buf.writeln('</gml:ReferenceableGridCoverage>');
  return buf.toString();
}

String _genMultiPointCoverage(
  GmlMultiPointCoverage cov,
) {
  final buf = StringBuffer()
    ..writeln('<?xml version="1.0" '
        'encoding="UTF-8"?>')
    ..write('<gml:MultiPointCoverage')
    ..write(' xmlns:gml='
        '"http://www.opengis.net/gml/3.2"');
  if (cov.id != null) {
    buf.write(' gml:id="${_xmlEscape(cov.id!)}"');
  }
  buf.writeln('>');
  _writeBoundedBy(buf, cov.boundedBy);

  if (cov.domainSet != null) {
    buf
      ..writeln('  <gml:domainSet>')
      ..writeln('    <gml:MultiPoint>');
    for (final p in cov.domainSet!.points) {
      final z = p.coordinate.z;
      buf
        ..writeln('      <gml:pointMember>')
        ..writeln(
          '        <gml:Point><gml:pos>'
          '${p.coordinate.x} ${p.coordinate.y}'
          '${z != null ? ' $z' : ''}'
          '</gml:pos></gml:Point>',
        )
        ..writeln('      </gml:pointMember>');
    }
    buf
      ..writeln('    </gml:MultiPoint>')
      ..writeln('  </gml:domainSet>');
  }

  _writeRangeSet(buf, cov.rangeSet);
  buf.writeln('</gml:MultiPointCoverage>');
  return buf.toString();
}

// --- Shared writers ---

void _writeBoundedBy(
  StringBuffer buf,
  GmlEnvelope? env,
) {
  if (env == null) return;
  buf
    ..writeln('  <gml:boundedBy>')
    ..write('    <gml:Envelope');
  if (env.srsName != null) {
    buf.write(
      ' srsName="${_xmlEscape(env.srsName!)}"',
    );
  }
  buf
    ..writeln('>')
    ..writeln(
      '      <gml:lowerCorner>'
      '${env.lowerCorner.x} ${env.lowerCorner.y}'
      '</gml:lowerCorner>',
    )
    ..writeln(
      '      <gml:upperCorner>'
      '${env.upperCorner.x} ${env.upperCorner.y}'
      '</gml:upperCorner>',
    )
    ..writeln('    </gml:Envelope>')
    ..writeln('  </gml:boundedBy>');
}

void _writeRectifiedGridDomain(
  StringBuffer buf,
  GmlRectifiedGrid? grid,
) {
  if (grid == null) return;
  buf
    ..writeln('  <gml:domainSet>')
    ..write('    <gml:RectifiedGrid'
        ' dimension="${grid.dimension}"');
  if (grid.srsName != null) {
    buf.write(
      ' srsName="${_xmlEscape(grid.srsName!)}"',
    );
  }
  buf
    ..writeln('>')
    ..writeln('      <gml:limits>')
    ..writeln('        <gml:GridEnvelope>')
    ..writeln(
      '          <gml:low>'
      '${grid.limits.low.join(' ')}'
      '</gml:low>',
    )
    ..writeln(
      '          <gml:high>'
      '${grid.limits.high.join(' ')}'
      '</gml:high>',
    )
    ..writeln('        </gml:GridEnvelope>')
    ..writeln('      </gml:limits>');

  if (grid.axisLabels != null) {
    buf.writeln(
      '      <gml:axisLabels>'
      '${grid.axisLabels!.join(' ')}'
      '</gml:axisLabels>',
    );
  }

  buf.writeln(
    '      <gml:origin>'
    '<gml:Point><gml:pos>'
    '${grid.origin.join(' ')}'
    '</gml:pos></gml:Point>'
    '</gml:origin>',
  );

  for (final ov in grid.offsetVectors) {
    buf.writeln(
      '      <gml:offsetVector>'
      '${ov.join(' ')}'
      '</gml:offsetVector>',
    );
  }

  buf
    ..writeln('    </gml:RectifiedGrid>')
    ..writeln('  </gml:domainSet>');
}

void _writeGridDomain(
  StringBuffer buf,
  GmlGrid? grid,
) {
  if (grid == null) return;
  buf
    ..writeln('  <gml:domainSet>')
    ..writeln(
      '    <gml:Grid'
      ' dimension="${grid.dimension}">',
    )
    ..writeln('      <gml:limits>')
    ..writeln('        <gml:GridEnvelope>')
    ..writeln(
      '          <gml:low>'
      '${grid.limits.low.join(' ')}'
      '</gml:low>',
    )
    ..writeln(
      '          <gml:high>'
      '${grid.limits.high.join(' ')}'
      '</gml:high>',
    )
    ..writeln('        </gml:GridEnvelope>')
    ..writeln('      </gml:limits>')
    ..writeln('    </gml:Grid>')
    ..writeln('  </gml:domainSet>');
}

void _writeRangeSet(
  StringBuffer buf,
  GmlRangeSet? rs,
) {
  if (rs == null) return;
  buf.writeln('  <gml:rangeSet>');
  if (rs.file != null) {
    buf
      ..writeln('    <gml:File>')
      ..writeln(
      '      <gml:fileName>'
      '${_xmlEscape(rs.file!.fileName)}'
      '</gml:fileName>',
    );
    if (rs.file!.fileStructure != null) {
      buf.writeln(
        '      <gml:fileStructure>'
        '${_xmlEscape(rs.file!.fileStructure!)}'
        '</gml:fileStructure>',
      );
    }
    buf.writeln('    </gml:File>');
  } else if (rs.data != null) {
    buf
      ..writeln('    <gml:DataBlock>')
      ..writeln(
        '      <gml:tupleList>'
        '${_xmlEscape(rs.data!)}'
        '</gml:tupleList>',
      )
      ..writeln('    </gml:DataBlock>');
  }
  buf.writeln('  </gml:rangeSet>');
}

void _writeRangeType(
  StringBuffer buf,
  GmlRangeType? rt,
) {
  if (rt == null || rt.fields.isEmpty) return;
  buf
    ..writeln('  <gmlcov:rangeType>')
    ..writeln('    <swe:DataRecord>');
  for (final f in rt.fields) {
    buf
      ..writeln(
        '      <swe:field name='
        '"${_xmlEscape(f.name)}">',
      )
      ..writeln('        <swe:Quantity>');
    if (f.uom != null) {
      buf.writeln(
        '          <swe:uom code='
        '"${_xmlEscape(f.uom!)}"/>',
      );
    }
    if (f.description != null) {
      buf.writeln(
        '          <swe:description>'
        '${_xmlEscape(f.description!)}'
        '</swe:description>',
      );
    }
    buf
      ..writeln('        </swe:Quantity>')
      ..writeln('      </swe:field>');
  }
  buf
    ..writeln('    </swe:DataRecord>')
    ..writeln('  </gmlcov:rangeType>');
}
