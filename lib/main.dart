import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/app.dart';
import 'core/database/app_database.dart';
import 'core/database/database_provider.dart';
import 'core/services/diagnostic_log_service.dart';
import 'core/services/notification_service.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // GitHub Pages friendly routing: always use hash URLs on web (/#/route)
    if (kIsWeb) {
      setUrlStrategy(const HashUrlStrategy());
    }

    final db = AppDatabase();
    await DiagnosticLogService.instance.attach(db);

    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      DiagnosticLogService.instance
          .logError('flutter', details.exception, details.stack);
      previousOnError?.call(details);
    };
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      DiagnosticLogService.instance.logError('platform', error, stack);
      return false;
    };

    // Initialize notifications
    await NotificationService.instance.initialize();
    DiagnosticLogService.instance.logEvent('app', 'avvio');

    runApp(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const InjeCareApp(),
      ),
    );
  }, (error, stack) {
    DiagnosticLogService.instance.logError('uncaught', error, stack);
  });
}
