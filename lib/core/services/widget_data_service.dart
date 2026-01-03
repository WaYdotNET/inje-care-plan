import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/body_zone.dart' as models;
import '../database/app_database.dart';

/// Servizio per fornire dati ai widget home screen (Android/iOS)
class WidgetDataService {
  final AppDatabase _db;

  WidgetDataService(this._db);

  // Chiavi per SharedPreferences (usate dai widget nativi)
  static const String _nextInjectionKey = 'widget_next_injection';
  static const String _weeklyAdherenceKey = 'widget_weekly_adherence';
  static const String _lastUpdateKey = 'widget_last_update';

  /// Aggiorna i dati per i widget
  Future<void> updateWidgetData() async {
    final prefs = await SharedPreferences.getInstance();

    // Prossima iniezione
    final nextInjection = await _getNextScheduledInjection();
    if (nextInjection != null) {
      await prefs.setString(_nextInjectionKey, jsonEncode(nextInjection));
    } else {
      await prefs.remove(_nextInjectionKey);
    }

    // Aderenza settimanale
    final weeklyAdherence = await _calculateWeeklyAdherence();
    await prefs.setDouble(_weeklyAdherenceKey, weeklyAdherence);

    // Timestamp ultimo aggiornamento
    await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
  }

  /// Ottiene i dati della prossima iniezione
  Future<Map<String, dynamic>?> _getNextScheduledInjection() async {
    final now = DateTime.now();
    final endDate = now.add(const Duration(days: 7));

    final injections = await _db.getInjectionsByDateRange(now, endDate);
    final scheduled = injections
        .where((i) => i.status == 'scheduled')
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    if (scheduled.isEmpty) return null;

    final next = scheduled.first;
    final zones = await _db.getAllZones();
    final dbZone = zones.where((z) => z.id == next.zoneId).firstOrNull;
    final zone = dbZone != null ? models.BodyZone.fromDatabase(dbZone) : null;

    return {
      'date': next.scheduledAt.toIso8601String(),
      'zoneId': next.zoneId,
      'zoneName': zone?.displayName ?? 'Zona ${next.zoneId}',
      'zoneEmoji': zone?.emoji ?? '💉',
      'pointNumber': next.pointNumber,
    };
  }

  /// Calcola l'aderenza settimanale
  Future<double> _calculateWeeklyAdherence() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);

    final injections = await _db.getInjectionsByDateRange(
      weekStartDate,
      now.add(const Duration(days: 1)),
    );

    final completed = injections.where((i) => i.status == 'completed').length;
    final total = injections.where((i) =>
      i.status == 'completed' || i.status == 'skipped'
    ).length;

    return total > 0 ? (completed / total) * 100 : 0;
  }

  /// Dati formattati per il widget
  Future<WidgetData> getWidgetData() async {
    final prefs = await SharedPreferences.getInstance();

    // Prossima iniezione
    final nextJson = prefs.getString(_nextInjectionKey);
    NextInjectionData? nextInjection;
    if (nextJson != null) {
      final map = jsonDecode(nextJson) as Map<String, dynamic>;
      nextInjection = NextInjectionData(
        date: DateTime.parse(map['date'] as String),
        zoneId: map['zoneId'] as int,
        zoneName: map['zoneName'] as String,
        zoneEmoji: map['zoneEmoji'] as String,
        pointNumber: map['pointNumber'] as int,
      );
    }

    // Aderenza
    final adherence = prefs.getDouble(_weeklyAdherenceKey) ?? 0;

    // Ultimo aggiornamento
    final lastUpdateStr = prefs.getString(_lastUpdateKey);
    final lastUpdate = lastUpdateStr != null
        ? DateTime.parse(lastUpdateStr)
        : null;

    return WidgetData(
      nextInjection: nextInjection,
      weeklyAdherence: adherence,
      lastUpdate: lastUpdate,
    );
  }
}

/// Dati per il widget
class WidgetData {
  final NextInjectionData? nextInjection;
  final double weeklyAdherence;
  final DateTime? lastUpdate;

  const WidgetData({
    this.nextInjection,
    required this.weeklyAdherence,
    this.lastUpdate,
  });
}

/// Dati della prossima iniezione
class NextInjectionData {
  final DateTime date;
  final int zoneId;
  final String zoneName;
  final String zoneEmoji;
  final int pointNumber;

  const NextInjectionData({
    required this.date,
    required this.zoneId,
    required this.zoneName,
    required this.zoneEmoji,
    required this.pointNumber,
  });

  String get formattedDate {
    final now = DateTime.now();
    final diff = date.difference(now);

    if (diff.inDays == 0) {
      return 'Oggi';
    } else if (diff.inDays == 1) {
      return 'Domani';
    } else if (diff.inDays < 7) {
      return 'Tra ${diff.inDays} giorni';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}
