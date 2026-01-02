import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_provider.dart';
import 'auth_repository.dart';

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Stato di autenticazione
class AuthState {
  final LocalUser? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({LocalUser? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isAuthenticated => user != null;
}

/// Notifier per gestire lo stato di autenticazione (Riverpod 3.x)
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// Inizializza lo stato di autenticazione
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);
    try {
      final db = ref.read(databaseProvider);
      await _repository.initialize(db);
      state = AuthState(user: _repository.currentUser);
    } catch (e) {
      state = AuthState(error: e.toString());
    }
  }

  /// Login con Google
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final db = ref.read(databaseProvider);
      final user = await _repository.signInWithGoogle(db);
      if (user != null) {
        state = AuthState(user: user);
        return true;
      } else {
        state = const AuthState(error: 'Login annullato');
        return false;
      }
    } catch (e) {
      state = AuthState(error: e.toString());
      return false;
    }
  }

  /// Logout
  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthState();
  }

  /// Autenticazione biometrica
  Future<bool> authenticateWithBiometrics() async {
    return _repository.authenticateWithBiometrics();
  }
}

/// Provider per AuthNotifier
final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// Alias per compatibilità
final authStateProvider = authNotifierProvider;

/// Current user provider
final currentUserProvider = Provider<LocalUser?>((ref) {
  return ref.watch(authNotifierProvider).user;
});

/// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isAuthenticated;
});

/// Biometric available provider
final biometricAvailableProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(authRepositoryProvider);
  return repository.isBiometricAvailable();
});

/// Biometric enabled provider
final biometricEnabledProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(authRepositoryProvider);
  final db = ref.watch(databaseProvider);
  return repository.isBiometricEnabled(db);
});
