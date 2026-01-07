import 'dart:convert';

import 'package:file_picker/file_picker.dart';

Future<String> readPickedFileAsStringImpl(PlatformFile file) async {
  final bytes = file.bytes;
  if (bytes == null) {
    throw Exception('File content not available (missing bytes).');
  }
  return utf8.decode(bytes, allowMalformed: true);
}


