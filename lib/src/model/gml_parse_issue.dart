part of '../gml4dart_base.dart';

/// Severity level of a [GmlParseIssue].
enum GmlIssueSeverity {
  /// Informational notice that does not affect parsing.
  info,

  /// Non-fatal warning; the document was parsed but may
  /// be incomplete or ambiguous.
  warning,

  /// Fatal error that prevented successful parsing.
  error,
}

/// A diagnostic produced while parsing a GML document.
final class GmlParseIssue {
  /// Creates a [GmlParseIssue].
  const GmlParseIssue({
    required this.severity,
    required this.code,
    required this.message,
    this.location,
  });

  /// Severity of this issue.
  final GmlIssueSeverity severity;

  /// Machine-readable code such as `'unsupported_element'`.
  final String code;

  /// Human-readable description of the issue.
  final String message;

  /// Optional XPath or element name indicating where the
  /// issue occurred.
  final String? location;
}
