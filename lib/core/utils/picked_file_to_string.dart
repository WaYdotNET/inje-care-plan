import 'package:file_picker/file_picker.dart';

import 'picked_file_to_string_stub.dart'
    if (dart.library.io) 'picked_file_to_string_io.dart';

/// Reads a picked file (from `file_picker`) as UTF-8 text.
///
/// - On Web: reads from `PlatformFile.bytes`
/// - On mobile/desktop: reads from `PlatformFile.path`
Future<String> readPickedFileAsString(PlatformFile file) =>
    readPickedFileAsStringImpl(file);


