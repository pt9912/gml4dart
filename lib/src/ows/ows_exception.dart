part of '../gml4dart_base.dart';

/// A single OWS exception.
final class OwsException {
  const OwsException({
    required this.exceptionCode,
    this.locator,
    this.exceptionTexts = const [],
  });

  final String exceptionCode;
  final String? locator;
  final List<String> exceptionTexts;
}

/// An OWS ExceptionReport containing one or more
/// exceptions.
final class OwsExceptionReport {
  const OwsExceptionReport({
    required this.version,
    this.exceptions = const [],
  });

  final String version;
  final List<OwsException> exceptions;

  /// Returns all exception messages formatted as
  /// `[code] message` or `[code@locator] message`.
  List<String> get allMessages => exceptions
      .expand(
        (e) => e.exceptionTexts.map(
          (t) => e.locator != null
              ? '[${e.exceptionCode}'
                  '@${e.locator}] $t'
              : '[${e.exceptionCode}] $t',
        ),
      )
      .toList();
}

/// Returns `true` if the XML looks like an OWS
/// ExceptionReport.
bool isOwsExceptionReport(String xml) =>
    xml.contains('ExceptionReport');

/// Parses an OWS ExceptionReport from XML.
///
/// Returns `null` if the XML is not an
/// ExceptionReport.
OwsExceptionReport? parseOwsExceptionReport(
  String xml,
) {
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(xml);
  } on XmlParserException {
    return null;
  }

  final root = doc.rootElement;
  if (root.localName != 'ExceptionReport') {
    return null;
  }

  final version =
      root.getAttribute('version') ?? '1.1.0';

  final exceptions = <OwsException>[];
  for (final el in root.childElements) {
    if (el.localName != 'Exception') continue;

    final code =
        el.getAttribute('exceptionCode') ?? '';
    final locator = el.getAttribute('locator');
    final texts = el.childElements
        .where(
          (t) => t.localName == 'ExceptionText',
        )
        .map((t) => t.innerText.trim())
        .toList();

    exceptions.add(OwsException(
      exceptionCode: code,
      locator: locator,
      exceptionTexts: texts,
    ));
  }

  return OwsExceptionReport(
    version: version,
    exceptions: exceptions,
  );
}
