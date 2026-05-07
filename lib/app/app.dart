import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/services/notification_service.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_provider.dart';
import '../core/widgets/responsive_wrapper.dart';
import 'router.dart';

/// Main application widget
class InjeCareApp extends ConsumerStatefulWidget {
  const InjeCareApp({super.key});

  @override
  ConsumerState<InjeCareApp> createState() => _InjeCareAppState();
}

class _InjeCareAppState extends ConsumerState<InjeCareApp> {
  StreamSubscription<dynamic>? _notificationSub;

  @override
  void initState() {
    super.initState();
    _notificationSub = NotificationService.instance.onNotificationTapped.listen(
      _handleNotificationTap,
    );
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    super.dispose();
  }

  /// Routes the user to the injection detail screen when a notification is
  /// tapped. Supports two payload prefixes:
  ///   - `injection:<id>` — pre-injection reminders (Bug C deep-link target)
  ///   - `side_effects:<id>` — post-injection follow-up reminder
  /// Both lead to the same detail screen, which exposes notes + side-effects.
  Future<void> _handleNotificationTap(dynamic response) async {
    final payload = response.payload as String?;
    if (payload == null) return;

    int? injectionId;
    for (final prefix in const ['injection:', 'side_effects:']) {
      if (payload.startsWith(prefix)) {
        injectionId = int.tryParse(payload.substring(prefix.length));
        break;
      }
    }
    if (injectionId == null) return;

    // Attendi che il router sia pronto (cold-start: navigatorKey può non avere
    // ancora un context montato).
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final router = ref.read(routerProvider);
    router.go(AppRoutes.injectionDetailPath(injectionId));
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'InjeCare Plan',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,

      // Router
      routerConfig: router,

      // Responsive wrapper for all screens
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return ResponsiveWrapper(child: child);
      },

      // Localization
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('it', 'IT'),
        Locale('en', 'US'),
      ],
      locale: const Locale('it', 'IT'),
    );
  }
}
