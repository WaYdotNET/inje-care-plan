import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<Uint8List> readPickedFileAsBytesImpl(PlatformFile file) async {
  final path = file.path;
  if (path == null || path.isEmpty) {
    throw Exception('File path not available.');
  }
  return File(path).readAsBytes();
}
