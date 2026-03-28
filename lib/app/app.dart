import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/services/notification_service.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_provider.dart';
import '../core/widgets/responsive_wrapper.dart';
import '../core/widgets/side_effects_dialog.dart';
import '../features/injection/injection_provider.dart';
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

  Future<void> _handleNotificationTap(dynamic response) async {
    final payload = response.payload as String?;
    if (payload == null || !payload.startsWith('side_effects:')) return;

    final idStr = payload.substring('side_effects:'.length);
    final injectionId = int.tryParse(idStr);
    if (injectionId == null) return;

    // Attendi che il router sia pronto
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final router = ref.read(routerProvider);
    final navContext = router.routerDelegate.navigatorKey.currentContext;
    if (navContext == null) return;

    final repository = ref.read(injectionRepositoryProvider);
    final injection = await repository.getInjectionById(injectionId);
    if (injection == null || !mounted) return;

    final effects = await SideEffectsDialog.show(
      navContext,
      injectionId: injectionId,
      pointLabel: injection.pointLabel,
    );
    if (effects != null) {
      await repository.updateSideEffects(injectionId, effects);
    }
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
