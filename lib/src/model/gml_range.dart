part of '../gml4dart_base.dart';

/// Range set holding the actual coverage data.
final class GmlRangeSet {
  const GmlRangeSet({this.data, this.file});

  /// Inline data (e.g. from DataBlock/tupleList).
  final String? data;

  /// External file reference.
  final GmlFileReference? file;
}

/// Reference to an external file in a range set.
final class GmlFileReference {
  const GmlFileReference({
    required this.fileName,
    this.fileStructure,
  });

  final String fileName;
  final String? fileStructure;
}

/// Range type describing the structure of range
/// values (bands/channels).
final class GmlRangeType {
  const GmlRangeType({this.fields = const []});

  final List<GmlRangeField> fields;
}

/// Single field (band) in a range type.
final class GmlRangeField {
  const GmlRangeField({
    required this.name,
    this.dataType,
    this.uom,
    this.description,
  });

  final String name;
  final String? dataType;
  final String? uom;
  final String? description;
}
