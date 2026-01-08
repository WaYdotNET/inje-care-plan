// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web implementation of saveAndShareFile that triggers a browser download.
Future<void> saveAndShareFile({
  required List<int> bytes,
  required String fileName,
  required String mimeType,
  required String shareSubject,
}) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
