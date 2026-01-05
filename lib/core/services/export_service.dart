import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../database/app_database.dart';

/// Export service for PDF and CSV generation
class ExportService {
  ExportService._();

  static final instance = ExportService._();

  /// Export injections to PDF (accepts Drift Injection type)
  Future<void> exportToPdf(List<dynamic> injections) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'it_IT');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'InjeCare Plan - Storico Iniezioni',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Generato il ${dateFormat.format(DateTime.now())}',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'InjeCare Plan',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
            pw.Text(
              'Pagina ${context.pageNumber} di ${context.pagesCount}',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.grey200,
            ),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellPadding: const pw.EdgeInsets.all(8),
            headerPadding: const pw.EdgeInsets.all(8),
            headers: ['Data', 'Punto', 'Stato', 'Note'],
            data: injections.map((inj) {
              if (inj is Injection) {
                final date = inj.completedAt ?? inj.scheduledAt;
                return [
                  dateFormat.format(date),
                  inj.pointLabel,
                  _statusLabel(inj.status),
                  inj.notes.isEmpty ? '-' : inj.notes,
                ];
              }
              return ['', '', '', ''];
            }).toList(),
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Riepilogo',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Totale iniezioni: ${injections.length}'),
          pw.Text(
            'Completate: ${_countByStatus(injections, 'completed')}',
          ),
          pw.Text(
            'Saltate: ${_countByStatus(injections, 'skipped')}',
          ),
        ],
      ),
    );

    // Save and share
    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/injecare_storico_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'InjeCare Plan - Storico Iniezioni',
      ),
    );
  }

  /// Export injections to CSV (formato semplice per import/export)
  /// Formato: data,zona,punto,stato
  Future<void> exportToCsv(List<dynamic> injections) async {
    final buffer = StringBuffer();

    // Header semplice
    buffer.writeln('data,zona,punto,stato');

    // Data rows - formato semplice
    for (final inj in injections) {
      if (inj is Injection) {
        final date = inj.completedAt ?? inj.scheduledAt;
        buffer.writeln([
          DateFormat('yyyy-MM-dd HH:mm').format(date),
          inj.pointCode.split('-').first, // Zone code (es. CD, CS, BD, BS, AD, AS, GD, GS)
          inj.pointNumber,
          inj.status,
        ].join(','));
      }
    }

    // Save and share
    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/injecare_storico_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    await file.writeAsString(buffer.toString());

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'InjeCare Plan - Storico Iniezioni',
      ),
    );
  }

  int _countByStatus(List<dynamic> injections, String status) {
    return injections.where((i) => i is Injection && i.status == status).length;
  }

  String _statusLabel(String status) => switch (status) {
    'completed' => 'Completata',
    'scheduled' => 'Programmata',
    'delayed' => 'In ritardo',
    'skipped' => 'Saltata',
    'missed' => 'Mancata',
    _ => status,
  };
}
