// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'InjeCare Plan';

  @override
  String get home => 'Home';

  @override
  String get calendar => 'Calendar';

  @override
  String get history => 'History';

  @override
  String get settings => 'Settings';

  @override
  String get statistics => 'Statistics';

  @override
  String get newInjection => 'New injection';

  @override
  String hello(String name) {
    return 'Hello, $name';
  }

  @override
  String get adherence => 'Adherence';

  @override
  String get adherenceLast30Days => 'Adherence last 30 days';

  @override
  String get injections => 'injections';

  @override
  String get noInjections => 'No injections';

  @override
  String get completed => 'Completed';

  @override
  String get skipped => 'Skipped';

  @override
  String get scheduled => 'Scheduled';

  @override
  String get streak => 'Streak';

  @override
  String get currentStreak => 'Current streak';

  @override
  String get longestStreak => 'Record';

  @override
  String get consecutiveInjections => 'consecutive injections';

  @override
  String get weeklyEvents => 'Weekly events';

  @override
  String get noEventsThisWeek => 'No events this week';

  @override
  String get suggestion => 'Suggestion';

  @override
  String get aiSuggestion => 'AI Suggestion';

  @override
  String get viewProposals => 'View proposals';

  @override
  String get selectZone => 'Select zone';

  @override
  String get selectPoint => 'Select point';

  @override
  String get zone => 'Zone';

  @override
  String get point => 'Point';

  @override
  String get blacklist => 'Exclude point';

  @override
  String get blacklistReason => 'Exclusion reason';

  @override
  String get skinReaction => 'Skin reaction';

  @override
  String get scar => 'Scar / lesion';

  @override
  String get hardToReach => 'Hard to reach';

  @override
  String get other => 'Other';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get confirm => 'Confirm';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get finish => 'Done';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String weeksAgo(int count) {
    return '$count weeks ago';
  }

  @override
  String monthsAgo(int count) {
    return '$count months ago';
  }

  @override
  String inDays(int count) {
    return 'In $count days';
  }

  @override
  String get lastWeek => 'Last week';

  @override
  String get lastMonth => 'Last month';

  @override
  String get last3Months => 'Last 3 months';

  @override
  String get lastYear => 'Last year';

  @override
  String get all => 'All';

  @override
  String get period => 'Period';

  @override
  String get monthlyAdherence => 'Monthly Adherence';

  @override
  String get weeklyTrend => 'Weekly Trend';

  @override
  String get zoneUsage => 'Zone Usage';

  @override
  String get zoneDetails => 'Zone Details';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get errorLoadingData => 'Unable to load data';

  @override
  String get tryAgain => 'Try again';

  @override
  String get therapyPlan => 'Therapy plan';

  @override
  String get weeklyInjections => 'Weekly injections';

  @override
  String get reminderAdvance => 'Reminder advance';

  @override
  String get minutes => 'minutes';

  @override
  String get hours => 'hours';

  @override
  String get hour => 'hour';

  @override
  String get theme => 'Theme';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get systemTheme => 'System';

  @override
  String get scheduledTheme => 'Scheduled';

  @override
  String get darkModeStart => 'Dark mode start';

  @override
  String get darkModeEnd => 'Dark mode end';

  @override
  String get biometricAuth => 'Biometric authentication';

  @override
  String get enableBiometric => 'Enable biometric unlock';

  @override
  String get googleAccount => 'Google Account';

  @override
  String get connectGoogle => 'Connect Google account';

  @override
  String get disconnectGoogle => 'Disconnect';

  @override
  String get backup => 'Backup';

  @override
  String get restore => 'Restore';

  @override
  String get export => 'Export';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get help => 'Help';

  @override
  String get privacy => 'Privacy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get welcomeTitle => 'Welcome to InjeCare';

  @override
  String get welcomeSubtitle => 'Your therapy, under control';

  @override
  String get onboardingStep1Title => 'Record injections';

  @override
  String get onboardingStep1Desc =>
      'Track every injection with just a few taps';

  @override
  String get onboardingStep2Title => 'Automatic rotation';

  @override
  String get onboardingStep2Desc =>
      'The app suggests the best zone for your next injection';

  @override
  String get onboardingStep3Title => 'Statistics and reports';

  @override
  String get onboardingStep3Desc =>
      'Monitor your adherence and share reports with your doctor';

  @override
  String get getStarted => 'Get Started';

  @override
  String get recordInjection => 'Record injection';

  @override
  String get markAsCompleted => 'Mark as completed';

  @override
  String get markAsSkipped => 'Mark as skipped';

  @override
  String get changePoint => 'Change point';

  @override
  String get deleteInjection => 'Delete injection';

  @override
  String get confirmDelete => 'Confirm deletion';

  @override
  String get confirmDeleteMessage =>
      'Are you sure you want to delete this injection?';

  @override
  String get success => 'Success';

  @override
  String get injectionRecorded => 'Injection recorded successfully';

  @override
  String get injectionDeleted => 'Injection deleted';

  @override
  String get injectionUpdated => 'Injection updated';

  @override
  String get notificationTitle => 'Injection reminder';

  @override
  String get notificationBody => 'It\'s time for your injection';

  @override
  String get missedInjection => 'Forgot your injection?';

  @override
  String get missedInjectionBody =>
      'You haven\'t recorded today\'s injection yet';

  @override
  String get zoneSuggestion => 'Zone suggestion';

  @override
  String get neverUsed => 'Never used';

  @override
  String notUsedFor(int days) {
    return 'Not used for $days days';
  }

  @override
  String get zoneManagement => 'Zone management';

  @override
  String get editPoints => 'Edit points';

  @override
  String get pointsEditor => 'Points editor';

  @override
  String get dragToPosition => 'Drag points to position them';

  @override
  String get tapToAddPoint => 'Tap to add point';

  @override
  String get resetPositions => 'Reset positions';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get unsavedChanges => 'Unsaved changes';

  @override
  String get discardChanges => 'Do you want to discard changes?';

  @override
  String get discard => 'Discard';

  @override
  String get guide => 'Guide';

  @override
  String get info => 'Info';

  @override
  String get restoreAsScheduled => 'Restore as scheduled';
}
