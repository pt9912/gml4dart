part of '../gml4dart_base.dart';

sealed class GmlCoverage extends GmlNode
    implements GmlRootContent {
  const GmlCoverage({
    this.id,
    this.boundedBy,
    this.rangeSet,
    this.rangeType,
  });

  final String? id;
  final GmlEnvelope? boundedBy;
  final GmlRangeSet? rangeSet;
  final GmlRangeType? rangeType;
}

final class GmlRectifiedGridCoverage
    extends GmlCoverage {
  const GmlRectifiedGridCoverage({
    super.id,
    super.boundedBy,
    super.rangeSet,
    super.rangeType,
    this.domainSet,
  });

  final GmlRectifiedGrid? domainSet;
}

final class GmlGridCoverage extends GmlCoverage {
  const GmlGridCoverage({
    super.id,
    super.boundedBy,
    super.rangeSet,
    super.rangeType,
    this.domainSet,
  });

  final GmlGrid? domainSet;
}

final class GmlReferenceableGridCoverage
    extends GmlCoverage {
  const GmlReferenceableGridCoverage({
    super.id,
    super.boundedBy,
    super.rangeSet,
    super.rangeType,
    this.domainSet,
  });

  final GmlGrid? domainSet;
}

final class GmlMultiPointCoverage
    extends GmlCoverage {
  const GmlMultiPointCoverage({
    super.id,
    super.boundedBy,
    super.rangeSet,
    super.rangeType,
    this.domainSet,
  });

  final GmlMultiPoint? domainSet;
}
