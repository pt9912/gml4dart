part of '../model.dart';

final class GmlDocument {
  const GmlDocument({
    required this.version,
    required this.root,
    this.boundedBy,
  });

  final GmlVersion version;
  final GmlRootContent root;
  final GmlEnvelope? boundedBy;
}
