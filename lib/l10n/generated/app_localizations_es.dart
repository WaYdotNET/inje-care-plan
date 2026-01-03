// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'InjeCare Plan';

  @override
  String get home => 'Inicio';

  @override
  String get calendar => 'Calendario';

  @override
  String get history => 'Historial';

  @override
  String get settings => 'Configuración';

  @override
  String get statistics => 'Estadísticas';

  @override
  String get newInjection => 'Nueva inyección';

  @override
  String hello(String name) {
    return 'Hola, $name';
  }

  @override
  String get adherence => 'Adherencia';

  @override
  String get adherenceLast30Days => 'Adherencia últimos 30 días';

  @override
  String get injections => 'inyecciones';

  @override
  String get noInjections => 'Sin inyecciones';

  @override
  String get completed => 'Completadas';

  @override
  String get skipped => 'Omitidas';

  @override
  String get scheduled => 'Programadas';

  @override
  String get streak => 'Racha';

  @override
  String get currentStreak => 'Racha actual';

  @override
  String get longestStreak => 'Récord';

  @override
  String get consecutiveInjections => 'inyecciones consecutivas';

  @override
  String get weeklyEvents => 'Eventos semanales';

  @override
  String get noEventsThisWeek => 'Sin eventos esta semana';

  @override
  String get suggestion => 'Sugerencia';

  @override
  String get aiSuggestion => 'Sugerencia IA';

  @override
  String get viewProposals => 'Ver propuestas';

  @override
  String get selectZone => 'Seleccionar zona';

  @override
  String get selectPoint => 'Seleccionar punto';

  @override
  String get zone => 'Zona';

  @override
  String get point => 'Punto';

  @override
  String get blacklist => 'Excluir punto';

  @override
  String get blacklistReason => 'Motivo de exclusión';

  @override
  String get skinReaction => 'Reacción cutánea';

  @override
  String get scar => 'Cicatriz / lesión';

  @override
  String get hardToReach => 'Difícil de alcanzar';

  @override
  String get other => 'Otro';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get edit => 'Editar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get back => 'Atrás';

  @override
  String get next => 'Siguiente';

  @override
  String get skip => 'Omitir';

  @override
  String get finish => 'Finalizar';

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String get tomorrow => 'Mañana';

  @override
  String daysAgo(int count) {
    return 'Hace $count días';
  }

  @override
  String weeksAgo(int count) {
    return 'Hace $count semanas';
  }

  @override
  String monthsAgo(int count) {
    return 'Hace $count meses';
  }

  @override
  String inDays(int count) {
    return 'En $count días';
  }

  @override
  String get lastWeek => 'Última semana';

  @override
  String get lastMonth => 'Último mes';

  @override
  String get last3Months => 'Últimos 3 meses';

  @override
  String get lastYear => 'Último año';

  @override
  String get all => 'Todo';

  @override
  String get period => 'Período';

  @override
  String get monthlyAdherence => 'Adherencia mensual';

  @override
  String get weeklyTrend => 'Tendencia semanal';

  @override
  String get zoneUsage => 'Uso de zonas';

  @override
  String get zoneDetails => 'Detalles de zonas';

  @override
  String get noDataAvailable => 'Sin datos disponibles';

  @override
  String get loading => 'Cargando...';

  @override
  String get error => 'Error';

  @override
  String get errorLoadingData => 'No se pudieron cargar los datos';

  @override
  String get tryAgain => 'Reintentar';

  @override
  String get therapyPlan => 'Plan de terapia';

  @override
  String get weeklyInjections => 'Inyecciones semanales';

  @override
  String get reminderAdvance => 'Adelanto del recordatorio';

  @override
  String get minutes => 'minutos';

  @override
  String get hours => 'horas';

  @override
  String get hour => 'hora';

  @override
  String get theme => 'Tema';

  @override
  String get lightTheme => 'Claro';

  @override
  String get darkTheme => 'Oscuro';

  @override
  String get systemTheme => 'Sistema';

  @override
  String get scheduledTheme => 'Programado';

  @override
  String get darkModeStart => 'Inicio modo oscuro';

  @override
  String get darkModeEnd => 'Fin modo oscuro';

  @override
  String get biometricAuth => 'Autenticación biométrica';

  @override
  String get enableBiometric => 'Habilitar desbloqueo biométrico';

  @override
  String get googleAccount => 'Cuenta Google';

  @override
  String get connectGoogle => 'Conectar cuenta Google';

  @override
  String get disconnectGoogle => 'Desconectar';

  @override
  String get backup => 'Copia de seguridad';

  @override
  String get restore => 'Restaurar';

  @override
  String get export => 'Exportar';

  @override
  String get exportPdf => 'Exportar PDF';

  @override
  String get exportCsv => 'Exportar CSV';

  @override
  String get about => 'Acerca de';

  @override
  String get version => 'Versión';

  @override
  String get help => 'Ayuda';

  @override
  String get privacy => 'Privacidad';

  @override
  String get termsOfService => 'Términos de servicio';

  @override
  String get welcomeTitle => 'Bienvenido a InjeCare';

  @override
  String get welcomeSubtitle => 'Tu terapia bajo control';

  @override
  String get onboardingStep1Title => 'Registra las inyecciones';

  @override
  String get onboardingStep1Desc =>
      'Realiza el seguimiento de cada inyección con unos pocos toques';

  @override
  String get onboardingStep2Title => 'Rotación automática';

  @override
  String get onboardingStep2Desc =>
      'La aplicación sugiere la mejor zona para tu próxima inyección';

  @override
  String get onboardingStep3Title => 'Estadísticas e informes';

  @override
  String get onboardingStep3Desc =>
      'Monitorea tu adherencia y comparte informes con tu médico';

  @override
  String get getStarted => 'Comenzar';

  @override
  String get recordInjection => 'Registrar inyección';

  @override
  String get markAsCompleted => 'Marcar como completada';

  @override
  String get markAsSkipped => 'Marcar como omitida';

  @override
  String get changePoint => 'Cambiar punto';

  @override
  String get deleteInjection => 'Eliminar inyección';

  @override
  String get confirmDelete => 'Confirmar eliminación';

  @override
  String get confirmDeleteMessage =>
      '¿Estás seguro de que deseas eliminar esta inyección?';

  @override
  String get success => 'Éxito';

  @override
  String get injectionRecorded => 'Inyección registrada con éxito';

  @override
  String get injectionDeleted => 'Inyección eliminada';

  @override
  String get injectionUpdated => 'Inyección actualizada';

  @override
  String get notificationTitle => 'Recordatorio de inyección';

  @override
  String get notificationBody => 'Es hora de tu inyección';

  @override
  String get missedInjection => '¿Olvidaste tu inyección?';

  @override
  String get missedInjectionBody => 'Aún no has registrado la inyección de hoy';

  @override
  String get zoneSuggestion => 'Sugerencia de zona';

  @override
  String get neverUsed => 'Nunca usada';

  @override
  String notUsedFor(int days) {
    return 'Sin usar hace $days días';
  }

  @override
  String get zoneManagement => 'Gestión de zonas';

  @override
  String get editPoints => 'Editar puntos';

  @override
  String get pointsEditor => 'Editor de puntos';

  @override
  String get dragToPosition => 'Arrastra los puntos para posicionarlos';

  @override
  String get tapToAddPoint => 'Toca para agregar punto';

  @override
  String get resetPositions => 'Restablecer posiciones';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get unsavedChanges => 'Cambios no guardados';

  @override
  String get discardChanges => '¿Deseas descartar los cambios?';

  @override
  String get discard => 'Descartar';

  @override
  String get guide => 'Guía';

  @override
  String get info => 'Info';
}
