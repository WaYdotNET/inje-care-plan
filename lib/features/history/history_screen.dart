import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/export_service.dart';
import '../../core/database/app_database.dart' as db;
import '../injection/injection_provider.dart';
import 'widgets/injection_history_list.dart';

/// Injection history screen
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final injectionsAsync = ref.watch(injectionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Storico'),
        actions: [
          injectionsAsync.maybeWhen(
            data: (injections) => IconButton(
              icon: const Icon(Icons.file_download_outlined),
              onPressed: injections.isNotEmpty
                  ? () => _showExportOptions(context, injections)
                  : null,
              tooltip: 'Esporta',
            ),
            orElse: () => const SizedBox(),
          ),
        ],
      ),
      body: injectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Errore: $error')),
        data: (injections) => InjectionHistoryList(injections: injections),
      ),
    );
  }

  void _showExportOptions(BuildContext context, List<db.Injection> injections) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text('Esporta PDF'),
            onTap: () async {
              Navigator.pop(context);
              try {
                await ExportService.instance.exportToPdf(injections);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Errore: $e')),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.table_chart),
            title: const Text('Esporta CSV'),
            onTap: () async {
              Navigator.pop(context);
              try {
                await ExportService.instance.exportToCsv(injections);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Errore: $e')),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
