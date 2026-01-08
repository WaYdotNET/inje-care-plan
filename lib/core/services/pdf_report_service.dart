import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/body_zone.dart' as models;
import '../database/app_database.dart';
import '../../features/statistics/statistics_provider.dart';

/// Servizio per generare PDF report avanzati per il medico
class PdfReportService {
  PdfReportService();

  /// Genera un report PDF completo
  Future<Uint8List> generateReport({
    required DateTime startDate,
    required DateTime endDate,
    required List<Injection> injections,
    required List<models.BodyZone> zones,
    required InjectionStats stats,
    String? patientName,
    String? patientEmail,
  }) async {
    final pdf = pw.Document(
      title: 'Report Iniezioni InjeCare',
      author: 'InjeCare Plan',
    );

    // Carica font
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final fontDataBold = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    final ttf = pw.Font.ttf(fontData);
    final ttfBold = pw.Font.ttf(fontDataBold);

    final dateFormat = DateFormat('dd/MM/yyyy', 'it');
    final timeFormat = DateFormat('HH:mm', 'it');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(
          context,
          ttfBold,
          patientName,
          patientEmail,
        ),
        footer: (context) => _buildFooter(context, ttf),
        build: (context) => [
          // Periodo report
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'Periodo: ${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                  style: pw.TextStyle(font: ttfBold, fontSize: 12),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          // Statistiche principali
          _buildStatsSection(stats, ttf, ttfBold),

          pw.SizedBox(height: 24),

          // Grafico aderenza (barre ASCII-style)
          _buildAdherenceChart(stats, ttf, ttfBold),

          pw.SizedBox(height: 24),

          // Utilizzo zone
          _buildZoneUsageSection(stats.zoneUsage, ttf, ttfBold),

          pw.SizedBox(height: 24),

          // Tabella storico
          _buildHistoryTable(injections, zones, dateFormat, timeFormat, ttf, ttfBold),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(
    pw.Context context,
    pw.Font ttfBold,
    String? patientName,
    String? patientEmail,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.blue, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'InjeCare Plan',
                style: pw.TextStyle(
                  font: ttfBold,
                  fontSize: 24,
                  color: PdfColors.blue800,
                ),
              ),
              pw.Text(
                'Report Terapia Iniettiva',
                style: pw.TextStyle(
                  font: ttfBold,
                  fontSize: 14,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          if (patientName != null || patientEmail != null)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (patientName != null)
                  pw.Text(
                    patientName,
                    style: pw.TextStyle(font: ttfBold, fontSize: 12),
                  ),
                if (patientEmail != null)
                  pw.Text(
                    patientEmail,
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context, pw.Font ttf) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generato il ${DateFormat('dd/MM/yyyy HH:mm', 'it').format(DateTime.now())}',
            style: pw.TextStyle(font: ttf, fontSize: 8, color: PdfColors.grey500),
          ),
          pw.Text(
            'Pagina ${context.pageNumber} di ${context.pagesCount}',
            style: pw.TextStyle(font: ttf, fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStatsSection(
    InjectionStats stats,
    pw.Font ttf,
    pw.Font ttfBold,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Riepilogo Statistiche',
            style: pw.TextStyle(font: ttfBold, fontSize: 16, color: PdfColors.blue800),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildStatBox('Aderenza', '${stats.adherenceRate.toStringAsFixed(1)}%', ttf, ttfBold, PdfColors.green),
              _buildStatBox('Completate', '${stats.completedCount}', ttf, ttfBold, PdfColors.blue),
              _buildStatBox('Saltate', '${stats.skippedCount}', ttf, ttfBold, PdfColors.red),
              _buildStatBox('Streak', '${stats.currentStreak}', ttf, ttfBold, PdfColors.orange),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStatBox(String label, String value, pw.Font ttf, pw.Font ttfBold, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: color.shade(0.9),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(font: ttfBold, fontSize: 20, color: color),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildAdherenceChart(
    InjectionStats stats,
    pw.Font ttf,
    pw.Font ttfBold,
  ) {
    if (stats.monthlyTrend.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Trend Aderenza Mensile',
            style: pw.TextStyle(font: ttfBold, fontSize: 16, color: PdfColors.blue800),
          ),
          pw.SizedBox(height: 12),
          ...stats.monthlyTrend.take(6).map((month) {
            final barWidth = (month.adherenceRate / 100) * 300;
            final color = month.adherenceRate >= 80
                ? PdfColors.green
                : (month.adherenceRate >= 60 ? PdfColors.orange : PdfColors.red);

            return pw.Container(
              margin: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Row(
                children: [
                  pw.SizedBox(
                    width: 50,
                    child: pw.Text(
                      DateFormat('MMM', 'it').format(month.month),
                      style: pw.TextStyle(font: ttf, fontSize: 10),
                    ),
                  ),
                  pw.Container(
                    width: barWidth.clamp(5, 300).toDouble(),
                    height: 16,
                    decoration: pw.BoxDecoration(
                      color: color,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Text(
                    '${month.adherenceRate.toStringAsFixed(0)}%',
                    style: pw.TextStyle(font: ttfBold, fontSize: 10),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  pw.Widget _buildZoneUsageSection(
    List<ZoneUsage> zoneUsage,
    pw.Font ttf,
    pw.Font ttfBold,
  ) {
    if (zoneUsage.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Utilizzo Zone Corporee',
            style: pw.TextStyle(font: ttfBold, fontSize: 16, color: PdfColors.blue800),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                children: [
                  _tableHeader('Zona', ttfBold),
                  _tableHeader('Iniezioni', ttfBold),
                  _tableHeader('%', ttfBold),
                ],
              ),
              ...zoneUsage.take(8).map((zone) => pw.TableRow(
                children: [
                  _tableCell('${zone.emoji} ${zone.zoneName}', ttf),
                  _tableCell('${zone.count}', ttf),
                  _tableCell('${zone.percentage.toStringAsFixed(1)}%', ttf),
                ],
              )),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildHistoryTable(
    List<Injection> injections,
    List<models.BodyZone> zones,
    DateFormat dateFormat,
    DateFormat timeFormat,
    pw.Font ttf,
    pw.Font ttfBold,
  ) {
    // Prendi le ultime 50 iniezioni
    final recentInjections = injections.take(50).toList();

    if (recentInjections.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        child: pw.Text(
          'Nessuna iniezione nel periodo selezionato',
          style: pw.TextStyle(font: ttf, fontSize: 12, color: PdfColors.grey600),
        ),
      );
    }

    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Storico Iniezioni (ultime 50)',
            style: pw.TextStyle(font: ttfBold, fontSize: 16, color: PdfColors.blue800),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                children: [
                  _tableHeader('Data', ttfBold),
                  _tableHeader('Zona', ttfBold),
                  _tableHeader('Punto', ttfBold),
                  _tableHeader('Stato', ttfBold),
                ],
              ),
              ...recentInjections.map((injection) {
                final zone = zones.where((z) => z.id == injection.zoneId).firstOrNull;
                final statusText = switch (injection.status) {
                  'completed' => '✓ Completata',
                  'skipped' => '✗ Saltata',
                  'scheduled' => '⏰ Programmata',
                  _ => injection.status,
                };
                final statusColor = switch (injection.status) {
                  'completed' => PdfColors.green,
                  'skipped' => PdfColors.red,
                  _ => PdfColors.grey,
                };

                return pw.TableRow(
                  children: [
                    _tableCell(
                      injection.completedAt != null
                          ? '${dateFormat.format(injection.completedAt!)} ${timeFormat.format(injection.completedAt!)}'
                          : dateFormat.format(injection.scheduledAt),
                      ttf,
                    ),
                    _tableCell(
                      zone != null ? '${zone.emoji} ${zone.displayName}' : 'Zona ${injection.zoneId}',
                      ttf,
                    ),
                    _tableCell('${injection.pointNumber}', ttf),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        statusText,
                        style: pw.TextStyle(font: ttf, fontSize: 9, color: statusColor),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _tableHeader(String text, pw.Font ttfBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: ttfBold, fontSize: 10),
      ),
    );
  }

  pw.Widget _tableCell(String text, pw.Font ttf) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: ttf, fontSize: 9),
      ),
    );
  }
}
