part of '../gml4dart_base.dart';

/// The result of parsing a GML document, containing the
/// parsed [document] (if successful) and any [issues]
/// encountered during parsing.
final class GmlParseResult {
  /// Creates a [GmlParseResult].
  const GmlParseResult({
    this.document,
    this.issues = const [],
  });

  /// The parsed document, or `null` if parsing failed.
  final GmlDocument? document;

  /// Diagnostics collected during parsing.
  final List<GmlParseIssue> issues;

  /// Whether any issue has [GmlIssueSeverity.error] severity.
  bool get hasErrors =>
      issues.any((issue) => issue.severity == GmlIssueSeverity.error);
}
