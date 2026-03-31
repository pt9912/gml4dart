part of '../../gml4dart_base.dart';

/// Streaming parser for large WFS/FeatureCollection
/// documents.
///
/// Processes XML incrementally — features are
/// yielded as soon as their member element is
/// complete. The buffer only holds unprocessed
/// tail content, not the entire document.
///
/// Scope is limited to documents with
/// `featureMember`, `wfs:member`, or
/// `featureMembers` children.
class GmlFeatureStreamParser {
  GmlFeatureStreamParser._();

  /// Parses features from a stream of XML string
  /// chunks, yielding each [GmlFeature] as soon as
  /// its member element is complete.
  static Stream<GmlFeature> parseStringStream(
    Stream<String> source,
  ) async* {
    var buffer = '';
    String? nsDecls;
    final issues = <GmlParseIssue>[];

    await for (final chunk in source) {
      buffer += chunk;

      nsDecls ??= _extractStreamRootNs(buffer);
      if (nsDecls == null) continue;

      // Yield complete features from buffer
      var advanced = true;
      while (advanced) {
        advanced = false;

        // Singular: featureMember / member
        final sing =
            _extractSingularMember(buffer);
        if (sing != null) {
          final f = _parseMemberXml(
            sing.innerXml,
            nsDecls,
            issues,
          );
          if (f != null) yield f;
          buffer = buffer.substring(sing.endOffset);
          advanced = true;
          continue;
        }

        // Plural: featureMembers
        final plural =
            _extractPluralMembers(buffer);
        if (plural != null) {
          yield* _parsePluralMembersXml(
            plural.innerXml,
            nsDecls,
            issues,
          );
          buffer =
              buffer.substring(plural.endOffset);
          advanced = true;
        }
      }
    }
  }

  /// Parses features from a stream of UTF-8 byte
  /// chunks.
  static Stream<GmlFeature> parseByteStream(
    Stream<List<int>> source,
  ) =>
      parseStringStream(
        source.map(utf8.decode),
      );

  /// Processes features via a callback, returning
  /// the total count.
  static Future<int> processFeatures(
    Stream<String> source, {
    required void Function(GmlFeature feature)
        onFeature,
  }) async {
    var count = 0;
    await for (final feature
        in parseStringStream(source)) {
      onFeature(feature);
      count++;
    }
    return count;
  }
}

// --- Root namespace extraction ---

final _nsPattern = RegExp(r'xmlns[:\w]*="[^"]*"');

String? _extractStreamRootNs(String buffer) {
  var i = 0;
  while (i < buffer.length) {
    final tagStart = buffer.indexOf('<', i);
    if (tagStart < 0) return null;

    // Skip processing instructions / comments
    if (buffer.startsWith('<?', tagStart)) {
      final end = buffer.indexOf('?>', tagStart);
      if (end < 0) return null;
      i = end + 2;
      continue;
    }
    if (buffer.startsWith('<!--', tagStart)) {
      final end = buffer.indexOf('-->', tagStart);
      if (end < 0) return null;
      i = end + 3;
      continue;
    }

    // Root element
    final tagEnd = buffer.indexOf('>', tagStart);
    if (tagEnd < 0) return null;

    final tag =
        buffer.substring(tagStart, tagEnd + 1);
    return _nsPattern
        .allMatches(tag)
        .map((m) => m.group(0)!)
        .join(' ');
  }
  return null;
}

// --- Singular member extraction ---

final _memberOpenRe = RegExp(
  r'<(\w+:)?(featureMember|member)\b[^/>]*>',
);

class _MemberSlice {
  const _MemberSlice(this.innerXml, this.endOffset);
  final String innerXml;
  final int endOffset;
}

_MemberSlice? _extractSingularMember(
  String buffer,
) {
  final openMatch = _memberOpenRe.firstMatch(buffer);
  if (openMatch == null) return null;

  final localName = openMatch.group(2)!;
  final closeRe = RegExp(
    '</(\\w+:)?$localName\\s*>',
  );
  final tail = buffer.substring(openMatch.end);
  final closeMatch = closeRe.firstMatch(tail);
  if (closeMatch == null) return null;

  return _MemberSlice(
    tail.substring(0, closeMatch.start),
    openMatch.end + closeMatch.end,
  );
}

// --- Plural featureMembers extraction ---

final _membersOpenRe = RegExp(
  r'<(\w+:)?featureMembers\b[^/>]*>',
);

_MemberSlice? _extractPluralMembers(
  String buffer,
) {
  final openMatch =
      _membersOpenRe.firstMatch(buffer);
  if (openMatch == null) return null;

  final closeRe = RegExp(
    r'</(\w+:)?featureMembers\s*>',
  );
  final tail = buffer.substring(openMatch.end);
  final closeMatch = closeRe.firstMatch(tail);
  if (closeMatch == null) return null;

  return _MemberSlice(
    tail.substring(0, closeMatch.start),
    openMatch.end + closeMatch.end,
  );
}

// --- Feature XML parsing ---

GmlFeature? _parseMemberXml(
  String innerXml,
  String nsDecls,
  List<GmlParseIssue> issues,
) {
  final wrapped = '<_r $nsDecls>$innerXml</_r>';
  try {
    final doc = XmlDocument.parse(wrapped);
    final el =
        doc.rootElement.childElements.firstOrNull;
    if (el != null) return _parseFeature(el, issues);
  } on XmlParserException {
    // skip malformed
  }
  return null;
}

Stream<GmlFeature> _parsePluralMembersXml(
  String innerXml,
  String nsDecls,
  List<GmlParseIssue> issues,
) async* {
  final wrapped = '<_r $nsDecls>$innerXml</_r>';
  try {
    final doc = XmlDocument.parse(wrapped);
    for (final el
        in doc.rootElement.childElements) {
      yield _parseFeature(el, issues);
    }
  } on XmlParserException {
    // skip malformed
  }
}
