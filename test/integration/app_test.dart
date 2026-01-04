import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:injecare_plan/features/auth/auth_provider.dart';

/// Integration tests for app flows
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppState', () {
    test('default state has correct values', () {
      const state = AppState();

      expect(state.isLoading, false);
      expect(state.hasCompletedOnboarding, false);
      expect(state.error, null);
      expect(state.isAuthenticated, false);
    });

    test('isAuthenticated returns true when onboarding completed', () {
      const state = AppState(hasCompletedOnboarding: true);
      expect(state.isAuthenticated, true);
    });

    test('copyWith updates values correctly', () {
      const original = AppState();

      final updated = original.copyWith(
        isLoading: true,
        hasCompletedOnboarding: true,
        error: 'test error',
      );

      expect(updated.isLoading, true);
      expect(updated.hasCompletedOnboarding, true);
      expect(updated.error, 'test error');
    });

    test('copyWith preserves values when not specified', () {
      const original = AppState(
        hasCompletedOnboarding: true,
        isLoading: true,
      );

      final updated = original.copyWith(isLoading: false);

      expect(updated.isLoading, false);
      expect(updated.hasCompletedOnboarding, true);
    });
  });

  group('AppStateNotifier - SharedPreferences Sync', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('completeOnboarding saves to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});

      final container = ProviderContainer();

      // Wait for initial state to settle
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.completeOnboarding();

      // Verify in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_completed'), true);

      container.dispose();
    });

    test('resetOnboarding removes from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'onboarding_completed': true,
      });

      final container = ProviderContainer();

      // Wait for initial state to settle
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.resetOnboarding();

      // Verify in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_completed'), null);

      container.dispose();
    });
  });
}
