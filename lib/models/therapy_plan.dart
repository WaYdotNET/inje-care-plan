import 'package:cloud_firestore/cloud_firestore.dart';

/// Therapy plan model
class TherapyPlan {
  const TherapyPlan({
    required this.injectionsPerWeek,
    required this.weekDays,
    required this.preferredTime,
    required this.startDate,
    this.notificationMinutesBefore = 30,
    this.missedDoseReminderEnabled = true,
  });

  final int injectionsPerWeek;
  final List<int> weekDays; // 1 = Monday, 7 = Sunday
  final String preferredTime; // "HH:mm" format
  final DateTime startDate;
  final int notificationMinutesBefore;
  final bool missedDoseReminderEnabled;

  /// Get weekday names
  List<String> get weekDayNames => weekDays.map((day) => switch (day) {
    1 => 'Lun',
    2 => 'Mar',
    3 => 'Mer',
    4 => 'Gio',
    5 => 'Ven',
    6 => 'Sab',
    7 => 'Dom',
    _ => '?',
  }).toList();

  /// Get weekday names as string
  String get weekDaysString => weekDayNames.join(', ');

  /// Default therapy plan (3x week: Mon, Wed, Fri at 20:00)
  static TherapyPlan get defaults => TherapyPlan(
    injectionsPerWeek: 3,
    weekDays: [1, 3, 5], // Mon, Wed, Fri
    preferredTime: '20:00',
    startDate: DateTime.now(),
  );

  /// Create from Firestore document
  factory TherapyPlan.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return TherapyPlan(
      injectionsPerWeek: data['injectionsPerWeek'] as int,
      weekDays: (data['weekDays'] as List<dynamic>).cast<int>(),
      preferredTime: data['preferredTime'] as String,
      startDate: (data['startDate'] as Timestamp).toDate(),
      notificationMinutesBefore: data['notificationMinutesBefore'] as int? ?? 30,
      missedDoseReminderEnabled: data['missedDoseReminderEnabled'] as bool? ?? true,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() => {
    'injectionsPerWeek': injectionsPerWeek,
    'weekDays': weekDays,
    'preferredTime': preferredTime,
    'startDate': Timestamp.fromDate(startDate),
    'notificationMinutesBefore': notificationMinutesBefore,
    'missedDoseReminderEnabled': missedDoseReminderEnabled,
  };

  /// Copy with modifications
  TherapyPlan copyWith({
    int? injectionsPerWeek,
    List<int>? weekDays,
    String? preferredTime,
    DateTime? startDate,
    int? notificationMinutesBefore,
    bool? missedDoseReminderEnabled,
  }) => TherapyPlan(
    injectionsPerWeek: injectionsPerWeek ?? this.injectionsPerWeek,
    weekDays: weekDays ?? this.weekDays,
    preferredTime: preferredTime ?? this.preferredTime,
    startDate: startDate ?? this.startDate,
    notificationMinutesBefore: notificationMinutesBefore ?? this.notificationMinutesBefore,
    missedDoseReminderEnabled: missedDoseReminderEnabled ?? this.missedDoseReminderEnabled,
  );

  /// Get next scheduled injection date from a given date
  DateTime getNextInjectionDate(DateTime from) {
    final timeParts = preferredTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    var date = DateTime(from.year, from.month, from.day, hour, minute);

    // If today's injection time has passed, start from tomorrow
    if (date.isBefore(from)) {
      date = date.add(const Duration(days: 1));
    }

    // Find next valid weekday
    while (!weekDays.contains(date.weekday)) {
      date = date.add(const Duration(days: 1));
    }

    return date;
  }

  /// Generate scheduled injections for a date range
  List<DateTime> generateSchedule(DateTime from, DateTime to) {
    final schedule = <DateTime>[];
    final timeParts = preferredTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    var date = DateTime(from.year, from.month, from.day, hour, minute);

    while (date.isBefore(to)) {
      if (weekDays.contains(date.weekday)) {
        schedule.add(date);
      }
      date = date.add(const Duration(days: 1));
    }

    return schedule;
  }
}
