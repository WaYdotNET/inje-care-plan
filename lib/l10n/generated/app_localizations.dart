import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
  ];

  /// Nome dell'applicazione
  ///
  /// In it, this message translates to:
  /// **'InjeCare Plan'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In it, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @calendar.
  ///
  /// In it, this message translates to:
  /// **'Calendario'**
  String get calendar;

  /// No description provided for @history.
  ///
  /// In it, this message translates to:
  /// **'Storico'**
  String get history;

  /// No description provided for @settings.
  ///
  /// In it, this message translates to:
  /// **'Impostazioni'**
  String get settings;

  /// No description provided for @statistics.
  ///
  /// In it, this message translates to:
  /// **'Statistiche'**
  String get statistics;

  /// No description provided for @newInjection.
  ///
  /// In it, this message translates to:
  /// **'Nuova iniezione'**
  String get newInjection;

  /// No description provided for @hello.
  ///
  /// In it, this message translates to:
  /// **'Ciao, {name}'**
  String hello(String name);

  /// No description provided for @adherence.
  ///
  /// In it, this message translates to:
  /// **'Aderenza'**
  String get adherence;

  /// No description provided for @adherenceLast30Days.
  ///
  /// In it, this message translates to:
  /// **'Aderenza ultimi 30 giorni'**
  String get adherenceLast30Days;

  /// No description provided for @injections.
  ///
  /// In it, this message translates to:
  /// **'iniezioni'**
  String get injections;

  /// No description provided for @noInjections.
  ///
  /// In it, this message translates to:
  /// **'Nessuna iniezione'**
  String get noInjections;

  /// No description provided for @completed.
  ///
  /// In it, this message translates to:
  /// **'Completate'**
  String get completed;

  /// No description provided for @skipped.
  ///
  /// In it, this message translates to:
  /// **'Saltate'**
  String get skipped;

  /// No description provided for @scheduled.
  ///
  /// In it, this message translates to:
  /// **'Programmate'**
  String get scheduled;

  /// No description provided for @streak.
  ///
  /// In it, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @currentStreak.
  ///
  /// In it, this message translates to:
  /// **'Streak attuale'**
  String get currentStreak;

  /// No description provided for @longestStreak.
  ///
  /// In it, this message translates to:
  /// **'Record'**
  String get longestStreak;

  /// No description provided for @consecutiveInjections.
  ///
  /// In it, this message translates to:
  /// **'iniezioni consecutive'**
  String get consecutiveInjections;

  /// No description provided for @weeklyEvents.
  ///
  /// In it, this message translates to:
  /// **'Eventi settimanali'**
  String get weeklyEvents;

  /// No description provided for @noEventsThisWeek.
  ///
  /// In it, this message translates to:
  /// **'Nessun evento questa settimana'**
  String get noEventsThisWeek;

  /// No description provided for @suggestion.
  ///
  /// In it, this message translates to:
  /// **'Suggerimento'**
  String get suggestion;

  /// No description provided for @aiSuggestion.
  ///
  /// In it, this message translates to:
  /// **'Suggerimento AI'**
  String get aiSuggestion;

  /// No description provided for @viewProposals.
  ///
  /// In it, this message translates to:
  /// **'Vedi proposte'**
  String get viewProposals;

  /// No description provided for @selectZone.
  ///
  /// In it, this message translates to:
  /// **'Seleziona zona'**
  String get selectZone;

  /// No description provided for @selectPoint.
  ///
  /// In it, this message translates to:
  /// **'Seleziona punto'**
  String get selectPoint;

  /// No description provided for @zone.
  ///
  /// In it, this message translates to:
  /// **'Zona'**
  String get zone;

  /// No description provided for @point.
  ///
  /// In it, this message translates to:
  /// **'Punto'**
  String get point;

  /// No description provided for @blacklist.
  ///
  /// In it, this message translates to:
  /// **'Escludi punto'**
  String get blacklist;

  /// No description provided for @blacklistReason.
  ///
  /// In it, this message translates to:
  /// **'Motivo esclusione'**
  String get blacklistReason;

  /// No description provided for @skinReaction.
  ///
  /// In it, this message translates to:
  /// **'Reazione cutanea'**
  String get skinReaction;

  /// No description provided for @scar.
  ///
  /// In it, this message translates to:
  /// **'Cicatrice / lesione'**
  String get scar;

  /// No description provided for @hardToReach.
  ///
  /// In it, this message translates to:
  /// **'Difficile da raggiungere'**
  String get hardToReach;

  /// No description provided for @other.
  ///
  /// In it, this message translates to:
  /// **'Altro'**
  String get other;

  /// No description provided for @save.
  ///
  /// In it, this message translates to:
  /// **'Salva'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In it, this message translates to:
  /// **'Annulla'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In it, this message translates to:
  /// **'Elimina'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In it, this message translates to:
  /// **'Modifica'**
  String get edit;

  /// No description provided for @confirm.
  ///
  /// In it, this message translates to:
  /// **'Conferma'**
  String get confirm;

  /// No description provided for @back.
  ///
  /// In it, this message translates to:
  /// **'Indietro'**
  String get back;

  /// No description provided for @next.
  ///
  /// In it, this message translates to:
  /// **'Avanti'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In it, this message translates to:
  /// **'Salta'**
  String get skip;

  /// No description provided for @finish.
  ///
  /// In it, this message translates to:
  /// **'Fine'**
  String get finish;

  /// No description provided for @today.
  ///
  /// In it, this message translates to:
  /// **'Oggi'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In it, this message translates to:
  /// **'Ieri'**
  String get yesterday;

  /// No description provided for @tomorrow.
  ///
  /// In it, this message translates to:
  /// **'Domani'**
  String get tomorrow;

  /// No description provided for @daysAgo.
  ///
  /// In it, this message translates to:
  /// **'{count} giorni fa'**
  String daysAgo(int count);

  /// No description provided for @weeksAgo.
  ///
  /// In it, this message translates to:
  /// **'{count} settimane fa'**
  String weeksAgo(int count);

  /// No description provided for @monthsAgo.
  ///
  /// In it, this message translates to:
  /// **'{count} mesi fa'**
  String monthsAgo(int count);

  /// No description provided for @inDays.
  ///
  /// In it, this message translates to:
  /// **'Tra {count} giorni'**
  String inDays(int count);

  /// No description provided for @lastWeek.
  ///
  /// In it, this message translates to:
  /// **'Ultima settimana'**
  String get lastWeek;

  /// No description provided for @lastMonth.
  ///
  /// In it, this message translates to:
  /// **'Ultimo mese'**
  String get lastMonth;

  /// No description provided for @last3Months.
  ///
  /// In it, this message translates to:
  /// **'Ultimi 3 mesi'**
  String get last3Months;

  /// No description provided for @lastYear.
  ///
  /// In it, this message translates to:
  /// **'Ultimo anno'**
  String get lastYear;

  /// No description provided for @all.
  ///
  /// In it, this message translates to:
  /// **'Tutto'**
  String get all;

  /// No description provided for @period.
  ///
  /// In it, this message translates to:
  /// **'Periodo'**
  String get period;

  /// No description provided for @monthlyAdherence.
  ///
  /// In it, this message translates to:
  /// **'Aderenza Mensile'**
  String get monthlyAdherence;

  /// No description provided for @weeklyTrend.
  ///
  /// In it, this message translates to:
  /// **'Trend Settimanale'**
  String get weeklyTrend;

  /// No description provided for @zoneUsage.
  ///
  /// In it, this message translates to:
  /// **'Utilizzo Zone'**
  String get zoneUsage;

  /// No description provided for @zoneDetails.
  ///
  /// In it, this message translates to:
  /// **'Dettaglio Zone'**
  String get zoneDetails;

  /// No description provided for @noDataAvailable.
  ///
  /// In it, this message translates to:
  /// **'Nessun dato disponibile'**
  String get noDataAvailable;

  /// No description provided for @loading.
  ///
  /// In it, this message translates to:
  /// **'Caricamento...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In it, this message translates to:
  /// **'Errore'**
  String get error;

  /// No description provided for @errorLoadingData.
  ///
  /// In it, this message translates to:
  /// **'Impossibile caricare i dati'**
  String get errorLoadingData;

  /// No description provided for @tryAgain.
  ///
  /// In it, this message translates to:
  /// **'Riprova'**
  String get tryAgain;

  /// No description provided for @therapyPlan.
  ///
  /// In it, this message translates to:
  /// **'Piano terapia'**
  String get therapyPlan;

  /// No description provided for @weeklyInjections.
  ///
  /// In it, this message translates to:
  /// **'Iniezioni settimanali'**
  String get weeklyInjections;

  /// No description provided for @reminderAdvance.
  ///
  /// In it, this message translates to:
  /// **'Anticipo promemoria'**
  String get reminderAdvance;

  /// No description provided for @minutes.
  ///
  /// In it, this message translates to:
  /// **'minuti'**
  String get minutes;

  /// No description provided for @hours.
  ///
  /// In it, this message translates to:
  /// **'ore'**
  String get hours;

  /// No description provided for @hour.
  ///
  /// In it, this message translates to:
  /// **'ora'**
  String get hour;

  /// No description provided for @theme.
  ///
  /// In it, this message translates to:
  /// **'Tema'**
  String get theme;

  /// No description provided for @lightTheme.
  ///
  /// In it, this message translates to:
  /// **'Chiaro'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In it, this message translates to:
  /// **'Scuro'**
  String get darkTheme;

  /// No description provided for @systemTheme.
  ///
  /// In it, this message translates to:
  /// **'Sistema'**
  String get systemTheme;

  /// No description provided for @scheduledTheme.
  ///
  /// In it, this message translates to:
  /// **'Programmato'**
  String get scheduledTheme;

  /// No description provided for @darkModeStart.
  ///
  /// In it, this message translates to:
  /// **'Inizio dark mode'**
  String get darkModeStart;

  /// No description provided for @darkModeEnd.
  ///
  /// In it, this message translates to:
  /// **'Fine dark mode'**
  String get darkModeEnd;

  /// No description provided for @biometricAuth.
  ///
  /// In it, this message translates to:
  /// **'Autenticazione biometrica'**
  String get biometricAuth;

  /// No description provided for @enableBiometric.
  ///
  /// In it, this message translates to:
  /// **'Abilita sblocco biometrico'**
  String get enableBiometric;

  /// No description provided for @googleAccount.
  ///
  /// In it, this message translates to:
  /// **'Account Google'**
  String get googleAccount;

  /// No description provided for @connectGoogle.
  ///
  /// In it, this message translates to:
  /// **'Collega account Google'**
  String get connectGoogle;

  /// No description provided for @disconnectGoogle.
  ///
  /// In it, this message translates to:
  /// **'Scollega'**
  String get disconnectGoogle;

  /// No description provided for @backup.
  ///
  /// In it, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @restore.
  ///
  /// In it, this message translates to:
  /// **'Ripristina'**
  String get restore;

  /// No description provided for @export.
  ///
  /// In it, this message translates to:
  /// **'Esporta'**
  String get export;

  /// No description provided for @exportPdf.
  ///
  /// In it, this message translates to:
  /// **'Esporta PDF'**
  String get exportPdf;

  /// No description provided for @exportCsv.
  ///
  /// In it, this message translates to:
  /// **'Esporta CSV'**
  String get exportCsv;

  /// No description provided for @about.
  ///
  /// In it, this message translates to:
  /// **'Informazioni'**
  String get about;

  /// No description provided for @version.
  ///
  /// In it, this message translates to:
  /// **'Versione'**
  String get version;

  /// No description provided for @help.
  ///
  /// In it, this message translates to:
  /// **'Guida'**
  String get help;

  /// No description provided for @privacy.
  ///
  /// In it, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @termsOfService.
  ///
  /// In it, this message translates to:
  /// **'Termini di servizio'**
  String get termsOfService;

  /// No description provided for @welcomeTitle.
  ///
  /// In it, this message translates to:
  /// **'Benvenuto in InjeCare'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In it, this message translates to:
  /// **'La tua terapia, sotto controllo'**
  String get welcomeSubtitle;

  /// No description provided for @onboardingStep1Title.
  ///
  /// In it, this message translates to:
  /// **'Registra le iniezioni'**
  String get onboardingStep1Title;

  /// No description provided for @onboardingStep1Desc.
  ///
  /// In it, this message translates to:
  /// **'Tieni traccia di ogni iniezione con pochi tap'**
  String get onboardingStep1Desc;

  /// No description provided for @onboardingStep2Title.
  ///
  /// In it, this message translates to:
  /// **'Rotazione automatica'**
  String get onboardingStep2Title;

  /// No description provided for @onboardingStep2Desc.
  ///
  /// In it, this message translates to:
  /// **'L\'app suggerisce la zona migliore per la prossima iniezione'**
  String get onboardingStep2Desc;

  /// No description provided for @onboardingStep3Title.
  ///
  /// In it, this message translates to:
  /// **'Statistiche e report'**
  String get onboardingStep3Title;

  /// No description provided for @onboardingStep3Desc.
  ///
  /// In it, this message translates to:
  /// **'Monitora la tua aderenza e condividi i report con il medico'**
  String get onboardingStep3Desc;

  /// No description provided for @getStarted.
  ///
  /// In it, this message translates to:
  /// **'Inizia'**
  String get getStarted;

  /// No description provided for @recordInjection.
  ///
  /// In it, this message translates to:
  /// **'Registra iniezione'**
  String get recordInjection;

  /// No description provided for @markAsCompleted.
  ///
  /// In it, this message translates to:
  /// **'Segna come completata'**
  String get markAsCompleted;

  /// No description provided for @markAsSkipped.
  ///
  /// In it, this message translates to:
  /// **'Segna come saltata'**
  String get markAsSkipped;

  /// No description provided for @changePoint.
  ///
  /// In it, this message translates to:
  /// **'Cambia punto'**
  String get changePoint;

  /// No description provided for @deleteInjection.
  ///
  /// In it, this message translates to:
  /// **'Elimina iniezione'**
  String get deleteInjection;

  /// No description provided for @confirmDelete.
  ///
  /// In it, this message translates to:
  /// **'Conferma eliminazione'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteMessage.
  ///
  /// In it, this message translates to:
  /// **'Sei sicuro di voler eliminare questa iniezione?'**
  String get confirmDeleteMessage;

  /// No description provided for @success.
  ///
  /// In it, this message translates to:
  /// **'Successo'**
  String get success;

  /// No description provided for @injectionRecorded.
  ///
  /// In it, this message translates to:
  /// **'Iniezione registrata con successo'**
  String get injectionRecorded;

  /// No description provided for @injectionDeleted.
  ///
  /// In it, this message translates to:
  /// **'Iniezione eliminata'**
  String get injectionDeleted;

  /// No description provided for @injectionUpdated.
  ///
  /// In it, this message translates to:
  /// **'Iniezione aggiornata'**
  String get injectionUpdated;

  /// No description provided for @notificationTitle.
  ///
  /// In it, this message translates to:
  /// **'Promemoria iniezione'**
  String get notificationTitle;

  /// No description provided for @notificationBody.
  ///
  /// In it, this message translates to:
  /// **'È ora della tua iniezione'**
  String get notificationBody;

  /// No description provided for @missedInjection.
  ///
  /// In it, this message translates to:
  /// **'Iniezione dimenticata?'**
  String get missedInjection;

  /// No description provided for @missedInjectionBody.
  ///
  /// In it, this message translates to:
  /// **'Non hai ancora registrato l\'iniezione di oggi'**
  String get missedInjectionBody;

  /// No description provided for @zoneSuggestion.
  ///
  /// In it, this message translates to:
  /// **'Suggerimento zona'**
  String get zoneSuggestion;

  /// No description provided for @neverUsed.
  ///
  /// In it, this message translates to:
  /// **'Mai utilizzata'**
  String get neverUsed;

  /// No description provided for @notUsedFor.
  ///
  /// In it, this message translates to:
  /// **'Non utilizzata da {days} giorni'**
  String notUsedFor(int days);

  /// No description provided for @zoneManagement.
  ///
  /// In it, this message translates to:
  /// **'Gestione zone'**
  String get zoneManagement;

  /// No description provided for @editPoints.
  ///
  /// In it, this message translates to:
  /// **'Modifica punti'**
  String get editPoints;

  /// No description provided for @pointsEditor.
  ///
  /// In it, this message translates to:
  /// **'Editor punti'**
  String get pointsEditor;

  /// No description provided for @dragToPosition.
  ///
  /// In it, this message translates to:
  /// **'Trascina i punti per posizionarli'**
  String get dragToPosition;

  /// No description provided for @tapToAddPoint.
  ///
  /// In it, this message translates to:
  /// **'Tap per aggiungere punto'**
  String get tapToAddPoint;

  /// No description provided for @resetPositions.
  ///
  /// In it, this message translates to:
  /// **'Reset posizioni'**
  String get resetPositions;

  /// No description provided for @saveChanges.
  ///
  /// In it, this message translates to:
  /// **'Salva modifiche'**
  String get saveChanges;

  /// No description provided for @unsavedChanges.
  ///
  /// In it, this message translates to:
  /// **'Modifiche non salvate'**
  String get unsavedChanges;

  /// No description provided for @discardChanges.
  ///
  /// In it, this message translates to:
  /// **'Vuoi scartare le modifiche?'**
  String get discardChanges;

  /// No description provided for @discard.
  ///
  /// In it, this message translates to:
  /// **'Scarta'**
  String get discard;

  /// No description provided for @guide.
  ///
  /// In it, this message translates to:
  /// **'Guida'**
  String get guide;

  /// No description provided for @info.
  ///
  /// In it, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @restoreAsScheduled.
  ///
  /// In it, this message translates to:
  /// **'Ripristina come pianificata'**
  String get restoreAsScheduled;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
