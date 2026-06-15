// lib/models/reminder_rule.dart

/// Una regola di promemoria: "quanti minuti prima" + se è attiva.
/// Sorgente unica condivisa da allarmi del calendario e (in seguito) notifiche.
class ReminderRule {
  const ReminderRule({required this.minutesBefore, required this.enabled});

  final int minutesBefore; // 0 = all'orario dell'iniezione
  final bool enabled;

  /// Anticipi proposti in UI (minuti). 720=12h, 1440=24h, 2880=48h.
  static const List<int> presetMinutes = [0, 15, 30, 60, 120, 720, 1440, 2880];

  /// Set iniziale: all'orario, 30 minuti prima, 24h prima (≈ "la sera prima").
  static const List<ReminderRule> defaults = [
    ReminderRule(minutesBefore: 0, enabled: true),
    ReminderRule(minutesBefore: 30, enabled: true),
    ReminderRule(minutesBefore: 1440, enabled: true),
  ];

  ReminderRule copyWith({int? minutesBefore, bool? enabled}) => ReminderRule(
        minutesBefore: minutesBefore ?? this.minutesBefore,
        enabled: enabled ?? this.enabled,
      );

  Map<String, dynamic> toJson() => {
        'minutesBefore': minutesBefore,
        'enabled': enabled,
      };

  factory ReminderRule.fromJson(Map<String, dynamic> json) => ReminderRule(
        minutesBefore: (json['minutesBefore'] as num).toInt(),
        enabled: json['enabled'] as bool? ?? true,
      );
}

/// Dove "suona" il promemoria. Non decide il quando (quello sono le regole).
enum ReminderChannel {
  appNotifications,
  calendar,
  both;

  static ReminderChannel fromName(String name) =>
      ReminderChannel.values.firstWhere(
        (c) => c.name == name,
        orElse: () => ReminderChannel.appNotifications,
      );
}

/// Cosa fare con l'evento del calendario quando l'iniezione è completata.
enum CompletionBehavior {
  markDone,
  remove;

  static CompletionBehavior fromName(String name) =>
      CompletionBehavior.values.firstWhere(
        (b) => b.name == name,
        orElse: () => CompletionBehavior.markDone,
      );
}
