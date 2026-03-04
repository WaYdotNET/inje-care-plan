import 'package:flutter/material.dart';

/// Dialog riutilizzabile per registrare gli effetti collaterali di un'iniezione.
/// Mostra una checklist con effetti comuni e un campo note opzionale.
class SideEffectsDialog extends StatefulWidget {
  const SideEffectsDialog({
    super.key,
    required this.injectionId,
    required this.pointLabel,
  });

  final int injectionId;
  final String pointLabel;

  /// Mostra il dialog e restituisce la lista di effetti selezionati,
  /// oppure null se l'utente annulla.
  static Future<List<String>?> show(
    BuildContext context, {
    required int injectionId,
    required String pointLabel,
  }) {
    return showDialog<List<String>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SideEffectsDialog(
        injectionId: injectionId,
        pointLabel: pointLabel,
      ),
    );
  }

  @override
  State<SideEffectsDialog> createState() => _SideEffectsDialogState();
}

class _SideEffectsDialogState extends State<SideEffectsDialog> {
  final _selectedEffects = <String>{};
  final _notesController = TextEditingController();

  static const _effects = [
    'Rossore nel punto',
    'Dolore locale',
    'Stanchezza',
    'Sintomi influenzali',
    'Altro',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Come è andata l\'ultima iniezione?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.pointLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            ..._effects.map(
              (effect) => CheckboxListTile(
                title: Text(effect),
                value: _selectedEffects.contains(effect),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedEffects.add(effect);
                    } else {
                      _selectedEffects.remove(effect);
                    }
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Note aggiuntive (opzionale)',
                isDense: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(const <String>[]),
          child: const Text('Nessun effetto'),
        ),
        FilledButton(
          onPressed: () {
            final effects = _selectedEffects.toList();
            if (_notesController.text.isNotEmpty) {
              effects.add('Note: ${_notesController.text}');
            }
            Navigator.of(context).pop(effects);
          },
          child: const Text('Salva'),
        ),
      ],
    );
  }
}
