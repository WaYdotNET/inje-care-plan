import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'backup_service.dart';
import 'crypto_provider.dart';

/// Provider singleton per BackupService
final backupServiceProvider = Provider<BackupService>((ref) {
  final cryptoService = ref.watch(cryptoServiceProvider);
  return BackupService(cryptoService: cryptoService);
});

/// Provider per verificare se esiste un backup su Google Drive
final remoteBackupInfoProvider = FutureProvider<BackupInfo?>((ref) async {
  final backupService = ref.watch(backupServiceProvider);
  return backupService.checkForBackup();
});

/// Provider per lo stato di autenticazione Google Drive
final isDriveAuthenticatedProvider = FutureProvider<bool>((ref) async {
  final backupService = ref.watch(backupServiceProvider);
  return backupService.isAuthenticated();
});

/// Stato per operazioni di backup in corso
class BackupState {
  final bool isLoading;
  final BackupResult? lastResult;
  final BackupInfo? backupInfo;

  const BackupState({
    this.isLoading = false,
    this.lastResult,
    this.backupInfo,
  });

  BackupState copyWith({
    bool? isLoading,
    BackupResult? lastResult,
    BackupInfo? backupInfo,
  }) {
    return BackupState(
      isLoading: isLoading ?? this.isLoading,
      lastResult: lastResult ?? this.lastResult,
      backupInfo: backupInfo ?? this.backupInfo,
    );
  }
}

/// Notifier per gestire le operazioni di backup (Riverpod 3.x)
class BackupNotifier extends Notifier<BackupState> {
  @override
  BackupState build() => const BackupState();

  BackupService get _backupService => ref.read(backupServiceProvider);

  Future<void> checkBackup() async {
    state = state.copyWith(isLoading: true);
    final info = await _backupService.checkForBackup();
    state = state.copyWith(isLoading: false, backupInfo: info);
  }

  /// Esegue il backup con password
  Future<BackupResult> backup(String password) async {
    state = state.copyWith(isLoading: true);
    final result = await _backupService.backup(password);
    state = state.copyWith(isLoading: false, lastResult: result);
    if (result.success) {
      await checkBackup();
    }
    return result;
  }

  /// Ripristina il backup con password
  Future<BackupResult> restore(String password) async {
    state = state.copyWith(isLoading: true);
    final result = await _backupService.restore(password);
    state = state.copyWith(isLoading: false, lastResult: result);
    return result;
  }

  Future<bool> signIn() async {
    return _backupService.signIn();
  }

  Future<void> signOut() async {
    await _backupService.signOut();
    state = const BackupState();
  }
}

/// Provider per BackupNotifier
final backupNotifierProvider =
    NotifierProvider<BackupNotifier, BackupState>(BackupNotifier.new);
