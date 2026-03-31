/// GML I/O helpers for file and URL access.
///
/// This library requires `dart:io` and is not
/// available in web contexts. For the pure-Dart
/// core, use `package:gml4dart/gml4dart.dart`.
///
/// ```dart
/// import 'package:gml4dart/gml4dart_io.dart';
///
/// final result = await GmlIo.parseFile('data.gml');
/// final features = GmlIo.streamFeaturesFromFile('wfs.xml');
/// ```
library;

export 'src/io/gml_io.dart';
