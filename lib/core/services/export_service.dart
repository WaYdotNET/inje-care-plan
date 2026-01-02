import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../../models/injection_record.dart';

/// Export service for PDF and CSV generation
class ExportService {
  ExportService._();

  static final instance = ExportService._();

  /// Export injections to PDF
  Future<void> exportToPdf(List<InjectionRecord> injections) async {
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
              final date = inj.completedAt ?? inj.scheduledAt;
              return [
                dateFormat.format(date),
                inj.pointLabel,
                _statusLabel(inj.status),
                inj.notes ?? '-',
              ];
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
            'Completate: ${injections.where((i) => i.status == InjectionStatus.completed).length}',
          ),
          pw.Text(
            'Saltate: ${injections.where((i) => i.status == InjectionStatus.skipped).length}',
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

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'InjeCare Plan - Storico Iniezioni',
    );
  }

  /// Export injections to CSV
  Future<void> exportToCsv(List<InjectionRecord> injections) async {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('Data,Ora,Zona,Punto,Codice,Stato,Note,Effetti Collaterali');

    // Data rows
    for (final inj in injections) {
      final date = inj.completedAt ?? inj.scheduledAt;
      buffer.writeln([
        DateFormat('dd/MM/yyyy').format(date),
        DateFormat('HH:mm').format(date),
        inj.zoneName,
        inj.pointNumber,
        inj.pointCode,
        _statusLabel(inj.status),
        '"${inj.notes?.replaceAll('"', '""') ?? ''}"',
        '"${inj.sideEffects.join(', ')}"',
      ].join(','));
    }

    // Save and share
    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/injecare_storico_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'InjeCare Plan - Storico Iniezioni',
    );
  }

  String _statusLabel(InjectionStatus status) => switch (status) {
    InjectionStatus.completed => 'Completata',
    InjectionStatus.scheduled => 'Programmata',
    InjectionStatus.delayed => 'In ritardo',
    InjectionStatus.skipped => 'Saltata',
  };
}
