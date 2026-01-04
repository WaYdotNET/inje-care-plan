import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:injecare_plan/core/database/app_database.dart';

/// Creates an in-memory database for testing
AppDatabase createTestDatabase() {
  return AppDatabase.forTesting(NativeDatabase.memory());
}

/// Creates a ProviderContainer for testing with optional overrides
/// Uses dynamic list to avoid type issues with Override in different Riverpod versions
ProviderContainer createContainer({
  List<dynamic> overrides = const [],
}) {
  return ProviderContainer(overrides: overrides.cast());
}

/// Wraps a widget with MaterialApp for testing
Widget testableWidget(Widget widget) {
  return MaterialApp(
    home: widget,
  );
}

/// Wraps a widget with MaterialApp and ProviderScope
/// Uses dynamic list to avoid type issues with Override in different Riverpod versions
Widget testableScopedWidget(
  Widget widget, {
  List<dynamic> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp(
      home: widget,
    ),
  );
}

/// Extension for easier async testing
extension FutureExtensions<T> on Future<T> {
  Future<T> get asTest async {
    await Future<void>.delayed(Duration.zero);
    return this;
  }
}

/// Helper to pump and settle with timeout
extension WidgetTesterExtensions on WidgetTester {
  Future<void> pumpAndSettleWithTimeout([
    Duration timeout = const Duration(seconds: 10),
  ]) async {
    await pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      timeout,
    );
  }
}
