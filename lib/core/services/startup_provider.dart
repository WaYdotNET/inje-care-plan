import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'backup_provider.dart';
import 'startup_service.dart';

/// Provider per StartupService
final startupServiceProvider = Provider<StartupService>((ref) {
  final backupService = ref.watch(backupServiceProvider);
  return StartupService(backupService: backupService);
});

/// Provider per lo stato iniziale dell'app
final startupStateProvider = FutureProvider<StartupInfo>((ref) async {
  final startupService = ref.watch(startupServiceProvider);
  return startupService.checkStartupState();
});
