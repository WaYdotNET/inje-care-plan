import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<Uint8List> readPickedFileAsBytesImpl(PlatformFile file) async {
  final bytes = file.bytes;
  if (bytes == null) {
    throw Exception('File content not available (missing bytes).');
  }
  return Uint8List.fromList(bytes);
}
