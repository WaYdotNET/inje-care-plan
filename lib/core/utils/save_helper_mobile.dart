import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Mobile/Desktop implementation of saveAndShareFile.
Future<void> saveAndShareFile({
  required List<int> bytes,
  required String fileName,
  required String mimeType,
  required String shareSubject,
}) async {
  final output = await getTemporaryDirectory();
  final file = File('${output.path}/$fileName');
  await file.writeAsBytes(bytes);

  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path)],
      subject: shareSubject,
    ),
  );
}
