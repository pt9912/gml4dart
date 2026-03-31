part of '../gml4dart_base.dart';

enum GmlIssueSeverity {
  info,
  warning,
  error,
}

final class GmlParseIssue {
  const GmlParseIssue({
    required this.severity,
    required this.code,
    required this.message,
    this.location,
  });

  final GmlIssueSeverity severity;
  final String code;
  final String message;
  final String? location;
}
