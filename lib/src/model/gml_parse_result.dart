part of '../model.dart';

final class GmlParseResult {
  const GmlParseResult({
    this.document,
    this.issues = const [],
  });

  final GmlDocument? document;
  final List<GmlParseIssue> issues;

  bool get hasErrors =>
      issues.any((issue) => issue.severity == GmlIssueSeverity.error);
}
