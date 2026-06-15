import 'package:intl/intl.dart';

import '../database/app_database.dart';

String buildEventTitle(Injection injection) => '💉 ${injection.pointLabel}';

/// Note dell'evento. Include il feedback dell'iniezione precedente completata,
/// se presente e non vuoto.
String buildEventNotes(Injection current, Injection? previousCompleted) {
  final buffer = StringBuffer()
    ..write('Iniezione programmata — ${current.pointLabel}');

  final prev = previousCompleted;
  if (prev != null) {
    final effects = _cleanCsv(prev.sideEffects);
    final note = prev.notes.trim();
    if (effects.isNotEmpty || note.isNotEmpty) {
      final when = DateFormat('EEE d MMM', 'it').format(prev.scheduledAt);
      buffer.write('\n\nUltima volta ($when · ${prev.pointLabel}):');
      if (effects.isNotEmpty) buffer.write('\n• Effetti: $effects');
      if (note.isNotEmpty) buffer.write('\n• Note: $note');
    }
  }
  return buffer.toString();
}

/// "a,b , c" -> "a, b, c"; vuoto -> "".
String _cleanCsv(String csv) => csv
    .split(',')
    .map((s) => s.trim())
    .where((s) => s.isNotEmpty)
    .join(', ');
