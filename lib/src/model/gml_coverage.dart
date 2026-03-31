part of '../gml4dart_base.dart';

sealed class GmlCoverage extends GmlNode implements GmlRootContent {
  const GmlCoverage();
}

final class GmlRectifiedGridCoverage extends GmlCoverage {
  const GmlRectifiedGridCoverage();
}

final class GmlGridCoverage extends GmlCoverage {
  const GmlGridCoverage();
}

final class GmlReferenceableGridCoverage extends GmlCoverage {
  const GmlReferenceableGridCoverage();
}

final class GmlMultiPointCoverage extends GmlCoverage {
  const GmlMultiPointCoverage();
}
