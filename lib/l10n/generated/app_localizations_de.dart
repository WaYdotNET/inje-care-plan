// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'InjeCare Plan';

  @override
  String get home => 'Startseite';

  @override
  String get calendar => 'Kalender';

  @override
  String get history => 'Verlauf';

  @override
  String get settings => 'Einstellungen';

  @override
  String get statistics => 'Statistiken';

  @override
  String get newInjection => 'Neue Injektion';

  @override
  String hello(String name) {
    return 'Hallo, $name';
  }

  @override
  String get adherence => 'Adhärenz';

  @override
  String get adherenceLast30Days => 'Adhärenz letzte 30 Tage';

  @override
  String get injections => 'Injektionen';

  @override
  String get noInjections => 'Keine Injektionen';

  @override
  String get completed => 'Abgeschlossen';

  @override
  String get skipped => 'Übersprungen';

  @override
  String get scheduled => 'Geplant';

  @override
  String get streak => 'Serie';

  @override
  String get currentStreak => 'Aktuelle Serie';

  @override
  String get longestStreak => 'Rekord';

  @override
  String get consecutiveInjections => 'aufeinanderfolgende Injektionen';

  @override
  String get weeklyEvents => 'Wöchentliche Ereignisse';

  @override
  String get noEventsThisWeek => 'Keine Ereignisse diese Woche';

  @override
  String get suggestion => 'Vorschlag';

  @override
  String get aiSuggestion => 'KI-Vorschlag';

  @override
  String get viewProposals => 'Vorschläge anzeigen';

  @override
  String get selectZone => 'Zone auswählen';

  @override
  String get selectPoint => 'Punkt auswählen';

  @override
  String get zone => 'Zone';

  @override
  String get point => 'Punkt';

  @override
  String get blacklist => 'Punkt ausschließen';

  @override
  String get blacklistReason => 'Ausschlussgrund';

  @override
  String get skinReaction => 'Hautreaktion';

  @override
  String get scar => 'Narbe / Verletzung';

  @override
  String get hardToReach => 'Schwer erreichbar';

  @override
  String get other => 'Andere';

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get back => 'Zurück';

  @override
  String get next => 'Weiter';

  @override
  String get skip => 'Überspringen';

  @override
  String get finish => 'Fertig';

  @override
  String get today => 'Heute';

  @override
  String get yesterday => 'Gestern';

  @override
  String get tomorrow => 'Morgen';

  @override
  String daysAgo(int count) {
    return 'Vor $count Tagen';
  }

  @override
  String weeksAgo(int count) {
    return 'Vor $count Wochen';
  }

  @override
  String monthsAgo(int count) {
    return 'Vor $count Monaten';
  }

  @override
  String inDays(int count) {
    return 'In $count Tagen';
  }

  @override
  String get lastWeek => 'Letzte Woche';

  @override
  String get lastMonth => 'Letzter Monat';

  @override
  String get last3Months => 'Letzte 3 Monate';

  @override
  String get lastYear => 'Letztes Jahr';

  @override
  String get all => 'Alles';

  @override
  String get period => 'Zeitraum';

  @override
  String get monthlyAdherence => 'Monatliche Adhärenz';

  @override
  String get weeklyTrend => 'Wochentrend';

  @override
  String get zoneUsage => 'Zonennutzung';

  @override
  String get zoneDetails => 'Zonendetails';

  @override
  String get noDataAvailable => 'Keine Daten verfügbar';

  @override
  String get loading => 'Laden...';

  @override
  String get error => 'Fehler';

  @override
  String get errorLoadingData => 'Daten konnten nicht geladen werden';

  @override
  String get tryAgain => 'Erneut versuchen';

  @override
  String get therapyPlan => 'Therapieplan';

  @override
  String get weeklyInjections => 'Wöchentliche Injektionen';

  @override
  String get reminderAdvance => 'Erinnerungsvorlauf';

  @override
  String get minutes => 'Minuten';

  @override
  String get hours => 'Stunden';

  @override
  String get hour => 'Stunde';

  @override
  String get theme => 'Thema';

  @override
  String get lightTheme => 'Hell';

  @override
  String get darkTheme => 'Dunkel';

  @override
  String get systemTheme => 'System';

  @override
  String get scheduledTheme => 'Geplant';

  @override
  String get darkModeStart => 'Dunkelmodus-Start';

  @override
  String get darkModeEnd => 'Dunkelmodus-Ende';

  @override
  String get biometricAuth => 'Biometrische Authentifizierung';

  @override
  String get enableBiometric => 'Biometrische Entsperrung aktivieren';

  @override
  String get googleAccount => 'Google-Konto';

  @override
  String get connectGoogle => 'Google-Konto verbinden';

  @override
  String get disconnectGoogle => 'Trennen';

  @override
  String get backup => 'Backup';

  @override
  String get restore => 'Wiederherstellen';

  @override
  String get export => 'Exportieren';

  @override
  String get exportPdf => 'PDF exportieren';

  @override
  String get exportCsv => 'CSV exportieren';

  @override
  String get about => 'Über';

  @override
  String get version => 'Version';

  @override
  String get help => 'Hilfe';

  @override
  String get privacy => 'Datenschutz';

  @override
  String get termsOfService => 'Nutzungsbedingungen';

  @override
  String get welcomeTitle => 'Willkommen bei InjeCare';

  @override
  String get welcomeSubtitle => 'Ihre Therapie unter Kontrolle';

  @override
  String get onboardingStep1Title => 'Injektionen aufzeichnen';

  @override
  String get onboardingStep1Desc =>
      'Verfolgen Sie jede Injektion mit nur wenigen Klicks';

  @override
  String get onboardingStep2Title => 'Automatische Rotation';

  @override
  String get onboardingStep2Desc =>
      'Die App schlägt die beste Zone für Ihre nächste Injektion vor';

  @override
  String get onboardingStep3Title => 'Statistiken und Berichte';

  @override
  String get onboardingStep3Desc =>
      'Überwachen Sie Ihre Adhärenz und teilen Sie Berichte mit Ihrem Arzt';

  @override
  String get getStarted => 'Loslegen';

  @override
  String get recordInjection => 'Injektion aufzeichnen';

  @override
  String get markAsCompleted => 'Als abgeschlossen markieren';

  @override
  String get markAsSkipped => 'Als übersprungen markieren';

  @override
  String get changePoint => 'Punkt ändern';

  @override
  String get deleteInjection => 'Injektion löschen';

  @override
  String get confirmDelete => 'Löschen bestätigen';

  @override
  String get confirmDeleteMessage =>
      'Möchten Sie diese Injektion wirklich löschen?';

  @override
  String get success => 'Erfolg';

  @override
  String get injectionRecorded => 'Injektion erfolgreich aufgezeichnet';

  @override
  String get injectionDeleted => 'Injektion gelöscht';

  @override
  String get injectionUpdated => 'Injektion aktualisiert';

  @override
  String get notificationTitle => 'Injektions-Erinnerung';

  @override
  String get notificationBody => 'Es ist Zeit für Ihre Injektion';

  @override
  String get missedInjection => 'Injektion vergessen?';

  @override
  String get missedInjectionBody =>
      'Sie haben die heutige Injektion noch nicht aufgezeichnet';

  @override
  String get zoneSuggestion => 'Zonenvorschlag';

  @override
  String get neverUsed => 'Nie verwendet';

  @override
  String notUsedFor(int days) {
    return 'Seit $days Tagen nicht verwendet';
  }

  @override
  String get zoneManagement => 'Zonenverwaltung';

  @override
  String get editPoints => 'Punkte bearbeiten';

  @override
  String get pointsEditor => 'Punkte-Editor';

  @override
  String get dragToPosition => 'Punkte ziehen zum Positionieren';

  @override
  String get tapToAddPoint => 'Tippen zum Hinzufügen';

  @override
  String get resetPositions => 'Positionen zurücksetzen';

  @override
  String get saveChanges => 'Änderungen speichern';

  @override
  String get unsavedChanges => 'Nicht gespeicherte Änderungen';

  @override
  String get discardChanges => 'Möchten Sie die Änderungen verwerfen?';

  @override
  String get discard => 'Verwerfen';

  @override
  String get guide => 'Anleitung';

  @override
  String get info => 'Info';

  @override
  String get restoreAsScheduled => 'Als geplant wiederherstellen';
}
