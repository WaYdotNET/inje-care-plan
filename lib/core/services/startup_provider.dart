import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'backup_provider.dart';
import 'crypto_provider.dart';
import 'startup_service.dart';

/// Provider per StartupService
final startupServiceProvider = Provider<StartupService>((ref) {
  final backupService = ref.watch(backupServiceProvider);
  final cryptoService = ref.watch(cryptoServiceProvider);
  return StartupService(
    backupService: backupService,
    cryptoService: cryptoService,
  );
});

/// Provider per lo stato iniziale dell'app
final startupStateProvider = FutureProvider<StartupInfo>((ref) async {
  final startupService = ref.watch(startupServiceProvider);
  return startupService.checkStartupState();
});

/// Provider per inizializzare la chiave di cifratura
final ensureEncryptionKeyProvider = FutureProvider<void>((ref) async {
  final startupService = ref.watch(startupServiceProvider);
  await startupService.ensureEncryptionKey();
});

