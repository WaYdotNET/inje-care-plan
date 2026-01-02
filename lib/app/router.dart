import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/auth_provider.dart';
import '../features/home/home_screen.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/injection/body_map_screen.dart';
import '../features/injection/zone_detail_screen.dart';
import '../features/injection/record_screen.dart';
import '../features/history/history_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/info/info_screen.dart';
import '../features/help/help_screen.dart';

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
}

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoginRoute = state.matchedLocation == AppRoutes.login;

      if (!isAuthenticated && !isLoginRoute) {
        return AppRoutes.login;
      }

      if (isAuthenticated && isLoginRoute) {
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
        builder: (context, state) => const BodyMapScreen(),
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
