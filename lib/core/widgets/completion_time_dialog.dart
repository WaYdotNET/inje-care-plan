import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Mostra un dialog di conferma completamento iniezione con scelta dell'ora
/// effettiva (default: adesso, l'ora del momento). Ritorna il DateTime scelto,
/// oppure null se l'utente annulla.
Future<DateTime?> showCompletionTimeDialog(
  BuildContext context, {
  required String pointLabel,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (ctx) => _CompletionTimeDialog(pointLabel: pointLabel),
  );
}

class _CompletionTimeDialog extends StatefulWidget {
  const _CompletionTimeDialog({required this.pointLabel});
  final String pointLabel;

  @override
  State<_CompletionTimeDialog> createState() => _CompletionTimeDialogState();
}

class _CompletionTimeDialogState extends State<_CompletionTimeDialog> {
  late DateTime _when = DateTime.now();

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (picked != null) {
      setState(() {
        _when = DateTime(
          _when.year,
          _when.month,
          _when.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Conferma iniezione'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Segnare ${widget.pointLabel} come completata?'),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.access_time, size: 18),
              const SizedBox(width: 8),
              Text('Ora: ${DateFormat('HH:mm').format(_when)}'),
              const Spacer(),
              TextButton(onPressed: _pickTime, child: const Text('Cambia')),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _when),
          child: const Text('Completata'),
        ),
      ],
    );
  }
}
