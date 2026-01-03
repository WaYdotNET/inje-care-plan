// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'InjeCare Plan';

  @override
  String get home => 'Accueil';

  @override
  String get calendar => 'Calendrier';

  @override
  String get history => 'Historique';

  @override
  String get settings => 'Paramètres';

  @override
  String get statistics => 'Statistiques';

  @override
  String get newInjection => 'Nouvelle injection';

  @override
  String hello(String name) {
    return 'Bonjour, $name';
  }

  @override
  String get adherence => 'Adhérence';

  @override
  String get adherenceLast30Days => 'Adhérence des 30 derniers jours';

  @override
  String get injections => 'injections';

  @override
  String get noInjections => 'Aucune injection';

  @override
  String get completed => 'Terminées';

  @override
  String get skipped => 'Sautées';

  @override
  String get scheduled => 'Programmées';

  @override
  String get streak => 'Série';

  @override
  String get currentStreak => 'Série actuelle';

  @override
  String get longestStreak => 'Record';

  @override
  String get consecutiveInjections => 'injections consécutives';

  @override
  String get weeklyEvents => 'Événements hebdomadaires';

  @override
  String get noEventsThisWeek => 'Aucun événement cette semaine';

  @override
  String get suggestion => 'Suggestion';

  @override
  String get aiSuggestion => 'Suggestion IA';

  @override
  String get viewProposals => 'Voir les propositions';

  @override
  String get selectZone => 'Sélectionner la zone';

  @override
  String get selectPoint => 'Sélectionner le point';

  @override
  String get zone => 'Zone';

  @override
  String get point => 'Point';

  @override
  String get blacklist => 'Exclure le point';

  @override
  String get blacklistReason => 'Raison d\'exclusion';

  @override
  String get skinReaction => 'Réaction cutanée';

  @override
  String get scar => 'Cicatrice / lésion';

  @override
  String get hardToReach => 'Difficile à atteindre';

  @override
  String get other => 'Autre';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get confirm => 'Confirmer';

  @override
  String get back => 'Retour';

  @override
  String get next => 'Suivant';

  @override
  String get skip => 'Passer';

  @override
  String get finish => 'Terminer';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String get tomorrow => 'Demain';

  @override
  String daysAgo(int count) {
    return 'Il y a $count jours';
  }

  @override
  String weeksAgo(int count) {
    return 'Il y a $count semaines';
  }

  @override
  String monthsAgo(int count) {
    return 'Il y a $count mois';
  }

  @override
  String inDays(int count) {
    return 'Dans $count jours';
  }

  @override
  String get lastWeek => 'Semaine dernière';

  @override
  String get lastMonth => 'Mois dernier';

  @override
  String get last3Months => '3 derniers mois';

  @override
  String get lastYear => 'Année dernière';

  @override
  String get all => 'Tout';

  @override
  String get period => 'Période';

  @override
  String get monthlyAdherence => 'Adhérence mensuelle';

  @override
  String get weeklyTrend => 'Tendance hebdomadaire';

  @override
  String get zoneUsage => 'Utilisation des zones';

  @override
  String get zoneDetails => 'Détails des zones';

  @override
  String get noDataAvailable => 'Aucune donnée disponible';

  @override
  String get loading => 'Chargement...';

  @override
  String get error => 'Erreur';

  @override
  String get errorLoadingData => 'Impossible de charger les données';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get therapyPlan => 'Plan thérapeutique';

  @override
  String get weeklyInjections => 'Injections hebdomadaires';

  @override
  String get reminderAdvance => 'Avance du rappel';

  @override
  String get minutes => 'minutes';

  @override
  String get hours => 'heures';

  @override
  String get hour => 'heure';

  @override
  String get theme => 'Thème';

  @override
  String get lightTheme => 'Clair';

  @override
  String get darkTheme => 'Sombre';

  @override
  String get systemTheme => 'Système';

  @override
  String get scheduledTheme => 'Programmé';

  @override
  String get darkModeStart => 'Début mode sombre';

  @override
  String get darkModeEnd => 'Fin mode sombre';

  @override
  String get biometricAuth => 'Authentification biométrique';

  @override
  String get enableBiometric => 'Activer le déverrouillage biométrique';

  @override
  String get googleAccount => 'Compte Google';

  @override
  String get connectGoogle => 'Connecter le compte Google';

  @override
  String get disconnectGoogle => 'Déconnecter';

  @override
  String get backup => 'Sauvegarde';

  @override
  String get restore => 'Restaurer';

  @override
  String get export => 'Exporter';

  @override
  String get exportPdf => 'Exporter en PDF';

  @override
  String get exportCsv => 'Exporter en CSV';

  @override
  String get about => 'À propos';

  @override
  String get version => 'Version';

  @override
  String get help => 'Aide';

  @override
  String get privacy => 'Confidentialité';

  @override
  String get termsOfService => 'Conditions d\'utilisation';

  @override
  String get welcomeTitle => 'Bienvenue dans InjeCare';

  @override
  String get welcomeSubtitle => 'Votre thérapie sous contrôle';

  @override
  String get onboardingStep1Title => 'Enregistrez les injections';

  @override
  String get onboardingStep1Desc => 'Suivez chaque injection en quelques clics';

  @override
  String get onboardingStep2Title => 'Rotation automatique';

  @override
  String get onboardingStep2Desc =>
      'L\'application suggère la meilleure zone pour votre prochaine injection';

  @override
  String get onboardingStep3Title => 'Statistiques et rapports';

  @override
  String get onboardingStep3Desc =>
      'Surveillez votre adhérence et partagez les rapports avec votre médecin';

  @override
  String get getStarted => 'Commencer';

  @override
  String get recordInjection => 'Enregistrer l\'injection';

  @override
  String get markAsCompleted => 'Marquer comme terminée';

  @override
  String get markAsSkipped => 'Marquer comme sautée';

  @override
  String get changePoint => 'Changer de point';

  @override
  String get deleteInjection => 'Supprimer l\'injection';

  @override
  String get confirmDelete => 'Confirmer la suppression';

  @override
  String get confirmDeleteMessage =>
      'Êtes-vous sûr de vouloir supprimer cette injection?';

  @override
  String get success => 'Succès';

  @override
  String get injectionRecorded => 'Injection enregistrée avec succès';

  @override
  String get injectionDeleted => 'Injection supprimée';

  @override
  String get injectionUpdated => 'Injection mise à jour';

  @override
  String get notificationTitle => 'Rappel d\'injection';

  @override
  String get notificationBody => 'C\'est l\'heure de votre injection';

  @override
  String get missedInjection => 'Injection oubliée?';

  @override
  String get missedInjectionBody =>
      'Vous n\'avez pas encore enregistré l\'injection d\'aujourd\'hui';

  @override
  String get zoneSuggestion => 'Suggestion de zone';

  @override
  String get neverUsed => 'Jamais utilisée';

  @override
  String notUsedFor(int days) {
    return 'Non utilisée depuis $days jours';
  }

  @override
  String get zoneManagement => 'Gestion des zones';

  @override
  String get editPoints => 'Modifier les points';

  @override
  String get pointsEditor => 'Éditeur de points';

  @override
  String get dragToPosition => 'Faites glisser les points pour les positionner';

  @override
  String get tapToAddPoint => 'Appuyez pour ajouter un point';

  @override
  String get resetPositions => 'Réinitialiser les positions';

  @override
  String get saveChanges => 'Enregistrer les modifications';

  @override
  String get unsavedChanges => 'Modifications non enregistrées';

  @override
  String get discardChanges => 'Voulez-vous abandonner les modifications?';

  @override
  String get discard => 'Abandonner';

  @override
  String get guide => 'Guide';

  @override
  String get info => 'Info';
}
