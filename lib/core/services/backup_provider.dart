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

/// Notifier per gestire le operazioni di backup
class BackupNotifier extends StateNotifier<BackupState> {
  final BackupService _backupService;

  BackupNotifier(this._backupService) : super(const BackupState());

  Future<void> checkBackup() async {
    state = state.copyWith(isLoading: true);
    final info = await _backupService.checkForBackup();
    state = state.copyWith(isLoading: false, backupInfo: info);
  }

  Future<BackupResult> backup() async {
    state = state.copyWith(isLoading: true);
    final result = await _backupService.backup();
    state = state.copyWith(isLoading: false, lastResult: result);
    if (result.success) {
      await checkBackup();
    }
    return result;
  }

  Future<BackupResult> restore() async {
    state = state.copyWith(isLoading: true);
    final result = await _backupService.restore();
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
    StateNotifierProvider<BackupNotifier, BackupState>((ref) {
  final backupService = ref.watch(backupServiceProvider);
  return BackupNotifier(backupService);
});

