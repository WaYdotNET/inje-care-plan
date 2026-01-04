import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'startup_service.dart';

/// Provider per StartupService
final startupServiceProvider = Provider<StartupService>((ref) {
  return StartupService();
});

/// Provider per lo stato iniziale dell'app
final startupStateProvider = FutureProvider<StartupInfo>((ref) async {
  final startupService = ref.watch(startupServiceProvider);
  return startupService.checkStartupState();
});
