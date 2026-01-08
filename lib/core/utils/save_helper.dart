import 'dart:async';

/// Cross-platform helper for saving and sharing files.
///
/// This is the stub implementation that will be overridden by platform-specific
/// implementations during conditional imports.
Future<void> saveAndShareFile({
  required List<int> bytes,
  required String fileName,
  required String mimeType,
  required String shareSubject,
}) {
  throw UnsupportedError('Cannot save and share file without dart:html or dart:io');
}
