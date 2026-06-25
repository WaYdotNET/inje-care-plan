import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'picked_file_to_bytes_stub.dart'
    if (dart.library.io) 'picked_file_to_bytes_io.dart';

/// Legge un file scelto (da `file_picker`) come byte grezzi.
///
/// - Su Web: da `PlatformFile.bytes`
/// - Su mobile/desktop: da `PlatformFile.path`
Future<Uint8List> readPickedFileAsBytes(PlatformFile file) =>
    readPickedFileAsBytesImpl(file);
