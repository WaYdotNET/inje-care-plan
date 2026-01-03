// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appName => 'InjeCare Plan';

  @override
  String get home => 'Home';

  @override
  String get calendar => 'Calendario';

  @override
  String get history => 'Storico';

  @override
  String get settings => 'Impostazioni';

  @override
  String get statistics => 'Statistiche';

  @override
  String get newInjection => 'Nuova iniezione';

  @override
  String hello(String name) {
    return 'Ciao, $name';
  }

  @override
  String get adherence => 'Aderenza';

  @override
  String get adherenceLast30Days => 'Aderenza ultimi 30 giorni';

  @override
  String get injections => 'iniezioni';

  @override
  String get noInjections => 'Nessuna iniezione';

  @override
  String get completed => 'Completate';

  @override
  String get skipped => 'Saltate';

  @override
  String get scheduled => 'Programmate';

  @override
  String get streak => 'Streak';

  @override
  String get currentStreak => 'Streak attuale';

  @override
  String get longestStreak => 'Record';

  @override
  String get consecutiveInjections => 'iniezioni consecutive';

  @override
  String get weeklyEvents => 'Eventi settimanali';

  @override
  String get noEventsThisWeek => 'Nessun evento questa settimana';

  @override
  String get suggestion => 'Suggerimento';

  @override
  String get aiSuggestion => 'Suggerimento AI';

  @override
  String get viewProposals => 'Vedi proposte';

  @override
  String get selectZone => 'Seleziona zona';

  @override
  String get selectPoint => 'Seleziona punto';

  @override
  String get zone => 'Zona';

  @override
  String get point => 'Punto';

  @override
  String get blacklist => 'Escludi punto';

  @override
  String get blacklistReason => 'Motivo esclusione';

  @override
  String get skinReaction => 'Reazione cutanea';

  @override
  String get scar => 'Cicatrice / lesione';

  @override
  String get hardToReach => 'Difficile da raggiungere';

  @override
  String get other => 'Altro';

  @override
  String get save => 'Salva';

  @override
  String get cancel => 'Annulla';

  @override
  String get delete => 'Elimina';

  @override
  String get edit => 'Modifica';

  @override
  String get confirm => 'Conferma';

  @override
  String get back => 'Indietro';

  @override
  String get next => 'Avanti';

  @override
  String get skip => 'Salta';

  @override
  String get finish => 'Fine';

  @override
  String get today => 'Oggi';

  @override
  String get yesterday => 'Ieri';

  @override
  String get tomorrow => 'Domani';

  @override
  String daysAgo(int count) {
    return '$count giorni fa';
  }

  @override
  String weeksAgo(int count) {
    return '$count settimane fa';
  }

  @override
  String monthsAgo(int count) {
    return '$count mesi fa';
  }

  @override
  String inDays(int count) {
    return 'Tra $count giorni';
  }

  @override
  String get lastWeek => 'Ultima settimana';

  @override
  String get lastMonth => 'Ultimo mese';

  @override
  String get last3Months => 'Ultimi 3 mesi';

  @override
  String get lastYear => 'Ultimo anno';

  @override
  String get all => 'Tutto';

  @override
  String get period => 'Periodo';

  @override
  String get monthlyAdherence => 'Aderenza Mensile';

  @override
  String get weeklyTrend => 'Trend Settimanale';

  @override
  String get zoneUsage => 'Utilizzo Zone';

  @override
  String get zoneDetails => 'Dettaglio Zone';

  @override
  String get noDataAvailable => 'Nessun dato disponibile';

  @override
  String get loading => 'Caricamento...';

  @override
  String get error => 'Errore';

  @override
  String get errorLoadingData => 'Impossibile caricare i dati';

  @override
  String get tryAgain => 'Riprova';

  @override
  String get therapyPlan => 'Piano terapia';

  @override
  String get weeklyInjections => 'Iniezioni settimanali';

  @override
  String get reminderAdvance => 'Anticipo promemoria';

  @override
  String get minutes => 'minuti';

  @override
  String get hours => 'ore';

  @override
  String get hour => 'ora';

  @override
  String get theme => 'Tema';

  @override
  String get lightTheme => 'Chiaro';

  @override
  String get darkTheme => 'Scuro';

  @override
  String get systemTheme => 'Sistema';

  @override
  String get scheduledTheme => 'Programmato';

  @override
  String get darkModeStart => 'Inizio dark mode';

  @override
  String get darkModeEnd => 'Fine dark mode';

  @override
  String get biometricAuth => 'Autenticazione biometrica';

  @override
  String get enableBiometric => 'Abilita sblocco biometrico';

  @override
  String get googleAccount => 'Account Google';

  @override
  String get connectGoogle => 'Collega account Google';

  @override
  String get disconnectGoogle => 'Scollega';

  @override
  String get backup => 'Backup';

  @override
  String get restore => 'Ripristina';

  @override
  String get export => 'Esporta';

  @override
  String get exportPdf => 'Esporta PDF';

  @override
  String get exportCsv => 'Esporta CSV';

  @override
  String get about => 'Informazioni';

  @override
  String get version => 'Versione';

  @override
  String get help => 'Guida';

  @override
  String get privacy => 'Privacy';

  @override
  String get termsOfService => 'Termini di servizio';

  @override
  String get welcomeTitle => 'Benvenuto in InjeCare';

  @override
  String get welcomeSubtitle => 'La tua terapia, sotto controllo';

  @override
  String get onboardingStep1Title => 'Registra le iniezioni';

  @override
  String get onboardingStep1Desc =>
      'Tieni traccia di ogni iniezione con pochi tap';

  @override
  String get onboardingStep2Title => 'Rotazione automatica';

  @override
  String get onboardingStep2Desc =>
      'L\'app suggerisce la zona migliore per la prossima iniezione';

  @override
  String get onboardingStep3Title => 'Statistiche e report';

  @override
  String get onboardingStep3Desc =>
      'Monitora la tua aderenza e condividi i report con il medico';

  @override
  String get getStarted => 'Inizia';

  @override
  String get recordInjection => 'Registra iniezione';

  @override
  String get markAsCompleted => 'Segna come completata';

  @override
  String get markAsSkipped => 'Segna come saltata';

  @override
  String get changePoint => 'Cambia punto';

  @override
  String get deleteInjection => 'Elimina iniezione';

  @override
  String get confirmDelete => 'Conferma eliminazione';

  @override
  String get confirmDeleteMessage =>
      'Sei sicuro di voler eliminare questa iniezione?';

  @override
  String get success => 'Successo';

  @override
  String get injectionRecorded => 'Iniezione registrata con successo';

  @override
  String get injectionDeleted => 'Iniezione eliminata';

  @override
  String get injectionUpdated => 'Iniezione aggiornata';

  @override
  String get notificationTitle => 'Promemoria iniezione';

  @override
  String get notificationBody => 'È ora della tua iniezione';

  @override
  String get missedInjection => 'Iniezione dimenticata?';

  @override
  String get missedInjectionBody =>
      'Non hai ancora registrato l\'iniezione di oggi';

  @override
  String get zoneSuggestion => 'Suggerimento zona';

  @override
  String get neverUsed => 'Mai utilizzata';

  @override
  String notUsedFor(int days) {
    return 'Non utilizzata da $days giorni';
  }

  @override
  String get zoneManagement => 'Gestione zone';

  @override
  String get editPoints => 'Modifica punti';

  @override
  String get pointsEditor => 'Editor punti';

  @override
  String get dragToPosition => 'Trascina i punti per posizionarli';

  @override
  String get tapToAddPoint => 'Tap per aggiungere punto';

  @override
  String get resetPositions => 'Reset posizioni';

  @override
  String get saveChanges => 'Salva modifiche';

  @override
  String get unsavedChanges => 'Modifiche non salvate';

  @override
  String get discardChanges => 'Vuoi scartare le modifiche?';

  @override
  String get discard => 'Scarta';

  @override
  String get guide => 'Guida';

  @override
  String get info => 'Info';
}
