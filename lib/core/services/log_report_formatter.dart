import 'package:intl/intl.dart';
import '../database/app_database.dart';

/// Genera il testo leggibile del report diagnostico (puro, testabile).
String formatLogReport(List<AppLog> logs, {required String header}) {
  final buffer = StringBuffer()
    ..writeln('=== $header — Report diagnostico ===');
  if (logs.isNotEmpty) {
    buffer.writeln(
      'App: ${logs.first.appVersion}  ·  Piattaforma: ${logs.first.platform}',
    );
  }
  buffer.writeln('Voci: ${logs.length}');
  buffer.writeln('');
  if (logs.isEmpty) {
    buffer.writeln('Nessun evento registrato.');
    return buffer.toString();
  }
  final time = DateFormat('HH:mm:ss');
  final date = DateFormat('dd/MM');
  for (final l in logs) {
    buffer.writeln(
      '[${date.format(l.createdAt)} ${time.format(l.createdAt)}] '
      '${l.level.toUpperCase()} ${l.tag} — ${l.message}',
    );
    if (l.details.trim().isNotEmpty) {
      for (final line in l.details.trimRight().split('\n')) {
        buffer.writeln('    $line');
      }
    }
  }
  return buffer.toString();
}
