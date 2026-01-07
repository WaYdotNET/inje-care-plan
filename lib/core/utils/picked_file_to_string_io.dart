import 'dart:io';

import 'package:file_picker/file_picker.dart';

Future<String> readPickedFileAsStringImpl(PlatformFile file) async {
  final path = file.path;
  if (path == null || path.isEmpty) {
    throw Exception('File path not available.');
  }
  return File(path).readAsString();
}


