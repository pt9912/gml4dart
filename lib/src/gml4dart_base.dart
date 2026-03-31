library;

import 'dart:convert';

import 'package:xml/xml.dart';

// Model
part 'model/gml_coordinate.dart';
part 'model/gml_coverage.dart';
part 'model/gml_document.dart';
part 'model/gml_feature.dart';
part 'model/gml_feature_collection.dart';
part 'model/gml_geometry.dart';
part 'model/gml_grid.dart';
part 'model/gml_node.dart';
part 'model/gml_parse_issue.dart';
part 'model/gml_parse_result.dart';
part 'model/gml_property_value.dart';
part 'model/gml_range.dart';
part 'model/gml_root_content.dart';
part 'model/gml_unsupported_node.dart';
part 'model/gml_version.dart';

// Parser
part 'parser/gml_parser.dart';
part 'parser/geometry_parser.dart';
part 'parser/feature_parser.dart';
part 'parser/coverage_parser.dart';
part 'parser/xml_helpers.dart';

// Interop
part 'interop/geojson_builder.dart';
part 'interop/wkt_builder.dart';

// OWS
part 'ows/ows_exception.dart';

// WCS
part 'wcs/request_builder.dart';
part 'wcs/capabilities_parser.dart';

// Generators
part 'generators/coverage_generator.dart';

// Streaming
part 'parser/streaming/gml_feature_stream_parser.dart';

// Utils
part 'utils/geotiff_metadata.dart';
