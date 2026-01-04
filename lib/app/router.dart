import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/auth_provider.dart';
import '../features/home/home_screen.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/injection/zone_detail_screen.dart';
import '../features/injection/record_screen.dart';
import '../features/history/history_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/info/info_screen.dart';
import '../features/help/help_screen.dart';
import '../features/injection/point_selection_screen.dart';
import '../features/settings/zone_management_screen.dart';
import '../features/settings/zone_points_editor_screen.dart';
import '../features/settings/custom_pattern_screen.dart';
import '../features/home/weekly_proposals_screen.dart';
import '../features/statistics/statistics_screen.dart';

/// App routes
sealed class AppRoutes {
  static const login = '/login';
  static const home = '/';
  static const calendar = '/calendar';
  static const bodyMap = '/body-map';
  static const zoneDetail = '/zone/:zoneId';
  static const recordInjection = '/record';
  static const history = '/history';
  static const settings = '/settings';
  static const info = '/info';
  static const help = '/help';
  static const blacklist = '/blacklist';
  static const selectPoint = '/select-point';
  static const zoneManagement = '/zone-management';
  static const zonePointsEditor = '/zone-points-editor/:zoneId';
  static const weeklyProposals = '/weekly-proposals';
  static const statistics = '/statistics';
  static const customPattern = '/custom-pattern';
}

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // Se sta ancora caricando lo stato, non fare redirect
      if (authState.isLoading) {
        return null;
      }

      final hasCompletedOnboarding = authState.hasCompletedOnboarding;
      final isLoginRoute = state.matchedLocation == AppRoutes.login;

      // Se non ha completato l'onboarding, vai alla schermata di login/onboarding
      if (!hasCompletedOnboarding && !isLoginRoute) {
        return AppRoutes.login;
      }

      // Se ha completato l'onboarding ed è sulla schermata di login, vai alla home
      if (hasCompletedOnboarding && isLoginRoute) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => _MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.calendar,
            name: 'calendar',
            builder: (context, state) => const CalendarScreen(),
          ),
          GoRoute(
            path: AppRoutes.history,
            name: 'history',
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.bodyMap,
        name: 'bodyMap',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final scheduledDate = extra?['scheduledDate'] as DateTime?;
          final initialZoneId = extra?['zoneId'] as int?;
          final existingInjectionId = extra?['existingInjectionId'] as int?;
          return PointSelectionScreen(
            mode: PointSelectionMode.injection,
            initialZoneId: initialZoneId,
            scheduledDate: scheduledDate,
            existingInjectionId: existingInjectionId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.zoneDetail,
        name: 'zoneDetail',
        builder: (context, state) {
          final zoneId = int.parse(state.pathParameters['zoneId'] ?? '1');
          return ZoneDetailScreen(zoneId: zoneId);
        },
      ),
      GoRoute(
        path: AppRoutes.recordInjection,
        name: 'recordInjection',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return RecordInjectionScreen(
            zoneId: extra?['zoneId'] as int? ?? 1,
            pointNumber: extra?['pointNumber'] as int? ?? 1,
            scheduledDate: extra?['scheduledDate'] as DateTime?,
            existingInjectionId: extra?['existingInjectionId'] as int?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.info,
        name: 'info',
        builder: (context, state) => const InfoScreen(),
      ),
      GoRoute(
        path: AppRoutes.help,
        name: 'help',
        builder: (context, state) => const HelpScreen(),
      ),
      GoRoute(
        path: AppRoutes.blacklist,
        name: 'blacklist',
        builder: (context, state) => const PointSelectionScreen(
          mode: PointSelectionMode.blacklist,
        ),
      ),
      GoRoute(
        path: AppRoutes.selectPoint,
        name: 'select-point',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final mode = extra?['mode'] as PointSelectionMode? ??
              PointSelectionMode.injection;
          final initialZoneId = extra?['zoneId'] as int?;
          return PointSelectionScreen(
            mode: mode,
            initialZoneId: initialZoneId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.zoneManagement,
        name: 'zoneManagement',
        builder: (context, state) => const ZoneManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.zonePointsEditor,
        name: 'zonePointsEditor',
        builder: (context, state) {
          final zoneId = int.parse(state.pathParameters['zoneId'] ?? '1');
          return ZonePointsEditorScreen(zoneId: zoneId);
        },
      ),
      GoRoute(
        path: AppRoutes.weeklyProposals,
        name: 'weeklyProposals',
        builder: (context, state) => const WeeklyProposalsScreen(),
      ),
      GoRoute(
        path: AppRoutes.statistics,
        name: 'statistics',
        builder: (context, state) => const StatisticsScreen(),
      ),
      GoRoute(
        path: AppRoutes.customPattern,
        name: 'customPattern',
        builder: (context, state) => const CustomPatternScreen(),
      ),
    ],
  );
});

/// Main shell with bottom navigation
class _MainShell extends StatelessWidget {
  const _MainShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendario',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Nuova',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Impostazioni',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == AppRoutes.home) return 0;
    if (location == AppRoutes.calendar) return 1;
    if (location == AppRoutes.settings) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
      case 1:
        context.go(AppRoutes.calendar);
      case 2:
        context.push(AppRoutes.bodyMap);
      case 3:
        context.go(AppRoutes.settings);
    }
  }
}
