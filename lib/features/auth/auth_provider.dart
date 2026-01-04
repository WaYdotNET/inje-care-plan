import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/database_provider.dart';
import 'auth_repository.dart';

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Chiave per salvare lo stato dell'onboarding
const _onboardingCompletedKey = 'onboarding_completed';

/// Stato di autenticazione (semplificato, senza Google)
class AuthState {
  final LocalUser? user;
  final bool isLoading;
  final String? error;
  final bool hasCompletedOnboarding;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.hasCompletedOnboarding = false,
  });

  AuthState copyWith({
    LocalUser? user,
    bool? isLoading,
    String? error,
    bool? hasCompletedOnboarding,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }

  /// L'utente può accedere all'app se ha completato l'onboarding
  bool get canAccessApp => hasCompletedOnboarding;

  /// Manteniamo isAuthenticated per retrocompatibilità
  bool get isAuthenticated => hasCompletedOnboarding;
}

/// Notifier per gestire lo stato di autenticazione
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(() => initialize());
    return const AuthState(isLoading: true);
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// Inizializza lo stato di autenticazione
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasCompletedOnboarding =
          prefs.getBool(_onboardingCompletedKey) ?? false;

      final db = ref.read(databaseProvider);
      await _repository.initialize(db);

      state = AuthState(
        user: _repository.currentUser,
        hasCompletedOnboarding: hasCompletedOnboarding,
      );
    } catch (e) {
      state = AuthState(error: e.toString());
    }
  }

  /// Continua (completa onboarding)
  Future<void> continueWithoutAccount() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompletedKey, true);

      state = state.copyWith(isLoading: false, hasCompletedOnboarding: true);
    } catch (e) {
      state = AuthState(error: e.toString());
    }
  }

  /// Salva profilo utente locale
  Future<void> saveUserProfile({
    required String displayName,
    String? email,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final db = ref.read(databaseProvider);
      final user = await _repository.saveLocalProfile(
        db,
        displayName: displayName,
        email: email,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompletedKey, true);

      state = AuthState(user: user, hasCompletedOnboarding: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Logout (reset onboarding)
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingCompletedKey);
    state = const AuthState();
  }

  /// Autenticazione biometrica
  Future<bool> authenticateWithBiometrics() async {
    return _repository.authenticateWithBiometrics();
  }

  /// Reset onboarding
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingCompletedKey);
    state = state.copyWith(hasCompletedOnboarding: false);
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
