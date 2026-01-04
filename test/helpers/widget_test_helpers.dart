import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Creates a test wrapper with Material app, Riverpod, and optional router
Widget createTestWidget({
  required Widget child,
  // Uses dynamic list to avoid type issues with Override
  List<dynamic> overrides = const [],
  GoRouter? router,
  bool useMaterialApp = true,
}) {
  Widget widget = child;

  if (useMaterialApp) {
    if (router != null) {
      widget = MaterialApp.router(
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      );
    } else {
      widget = MaterialApp(
        home: Scaffold(body: child),
        debugShowCheckedModeBanner: false,
      );
    }
  }

  return ProviderScope(
    overrides: overrides.cast(),
    child: widget,
  );
}

/// Creates a simple test router that captures navigation
GoRouter createTestRouter({
  required Widget homeWidget,
  Map<String, Widget Function(GoRouterState)>? routes,
}) {
  final routeList = <GoRoute>[
    GoRoute(
      path: '/',
      builder: (context, state) => homeWidget,
    ),
  ];

  if (routes != null) {
    for (final entry in routes.entries) {
      routeList.add(GoRoute(
        path: entry.key,
        builder: (context, state) => entry.value(state),
      ));
    }
  }

  return GoRouter(
    initialLocation: '/',
    routes: routeList,
  );
}

/// Extension to make pumping widgets with Riverpod easier
extension WidgetTesterExtension on WidgetTester {
  /// Pump widget and settle with timeout
  Future<void> pumpAndSettleWithTimeout({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      timeout,
    );
  }

  /// Pump widget wrapped in test wrapper
  Future<void> pumpTestWidget(
    Widget widget, {
    List<dynamic> overrides = const [],
  }) async {
    await pumpWidget(createTestWidget(
      child: widget,
      overrides: overrides,
    ));
  }
}

/// A test navigator observer to track navigation events
class TestNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = [];
  final List<Route<dynamic>> poppedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    poppedRoutes.add(route);
  }
}
