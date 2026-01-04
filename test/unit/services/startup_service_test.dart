import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:injecare_plan/core/services/startup_service.dart';
import 'package:injecare_plan/core/services/startup_provider.dart';

void main() {
  group('StartupCheckResult', () {
    test('has normalStart value', () {
      expect(StartupCheckResult.normalStart, isNotNull);
    });

    test('has firstRun value', () {
      expect(StartupCheckResult.firstRun, isNotNull);
    });

    test('has error value', () {
      expect(StartupCheckResult.error, isNotNull);
    });

    test('all values are distinct', () {
      final values = StartupCheckResult.values;
      expect(values.length, 3);
      expect(values.toSet().length, 3);
    });
  });

  group('StartupInfo', () {
    test('creates with required result', () {
      final info = StartupInfo(result: StartupCheckResult.normalStart);
      
      expect(info.result, StartupCheckResult.normalStart);
      expect(info.errorMessage, isNull);
    });

    test('creates with result and error message', () {
      final info = StartupInfo(
        result: StartupCheckResult.error,
        errorMessage: 'Test error',
      );
      
      expect(info.result, StartupCheckResult.error);
      expect(info.errorMessage, 'Test error');
    });

    test('creates with firstRun result', () {
      final info = StartupInfo(result: StartupCheckResult.firstRun);
      
      expect(info.result, StartupCheckResult.firstRun);
    });
  });

  group('StartupService', () {
    test('creates instance', () {
      final service = StartupService();
      expect(service, isA<StartupService>());
    });

    // Note: checkStartupState tests web behavior differently
    // On web (kIsWeb), it always returns normalStart
    // On native platforms, it checks for database file existence
    // These tests are limited because they depend on platform
  });

  group('startupServiceProvider', () {
    test('provides StartupService instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      final service = container.read(startupServiceProvider);
      
      expect(service, isA<StartupService>());
    });

    test('provides same instance on multiple reads', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      final first = container.read(startupServiceProvider);
      final second = container.read(startupServiceProvider);
      
      expect(identical(first, second), true);
    });
  });

  group('startupStateProvider', () {
    test('is a FutureProvider', () {
      expect(startupStateProvider, isA<FutureProvider<StartupInfo>>());
    });

    // Note: Full async tests for startupStateProvider require
    // mocking the file system or running on web platform
  });
}

