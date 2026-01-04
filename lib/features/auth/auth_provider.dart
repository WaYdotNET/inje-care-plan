import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/database_provider.dart';
import 'auth_repository.dart';

/// Scopes per Google Drive (condivisi tra auth e backup)
const googleDriveScopes = [drive.DriveApi.driveFileScope];

/// Provider singleton per GoogleSignIn - condiviso tra AuthRepository e BackupService
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(scopes: googleDriveScopes);
});

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final googleSignIn = ref.watch(googleSignInProvider);
  return AuthRepository(googleSignIn: googleSignIn);
});

/// Chiave per salvare lo stato dell'onboarding
const _onboardingCompletedKey = 'onboarding_completed';

/// Stato di autenticazione
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
  /// (con o senza login Google)
  bool get canAccessApp => hasCompletedOnboarding;

  /// L'utente ha un account Google collegato (per backup)
  bool get hasGoogleAccount => user != null;

  // Manteniamo isAuthenticated per retrocompatibilità
  bool get isAuthenticated => hasCompletedOnboarding;
}

/// Notifier per gestire lo stato di autenticazione (Riverpod 3.x)
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Avvia l'inizializzazione automaticamente
    Future.microtask(() => initialize());
    return const AuthState(isLoading: true);
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// Inizializza lo stato di autenticazione
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);
    try {
      // Carica lo stato dell'onboarding
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

  /// Continua senza account Google (modalità offline)
  Future<void> continueWithoutAccount() async {
    state = state.copyWith(isLoading: true);
    try {
      // Salva che l'utente ha completato l'onboarding
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompletedKey, true);

      state = state.copyWith(isLoading: false, hasCompletedOnboarding: true);
    } catch (e) {
      state = AuthState(error: e.toString());
    }
  }

  /// Login con Google (opzionale, per backup)
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final db = ref.read(databaseProvider);
      final user = await _repository.signInWithGoogle(db);
      if (user != null) {
        // Segna anche l'onboarding come completato
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_onboardingCompletedKey, true);

        state = AuthState(user: user, hasCompletedOnboarding: true);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Login annullato');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Collega account Google (dopo aver iniziato in modalità offline)
  Future<bool> linkGoogleAccount() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final db = ref.read(databaseProvider);
      final user = await _repository.signInWithGoogle(db);
      if (user != null) {
        // Forza aggiornamento completo dello stato
        state = AuthState(
          user: user,
          isLoading: false,
          hasCompletedOnboarding: state.hasCompletedOnboarding,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Collegamento annullato',
        );
        return false;
      }
    } catch (e) {
      // Messaggio di errore più chiaro
      String errorMessage = e.toString();
      if (errorMessage.contains('PlatformException') || 
          errorMessage.contains('sign_in_failed') ||
          errorMessage.contains('ApiException')) {
        errorMessage = 'Google Sign-In non configurato. '
            'Verifica google-services.json e OAuth credentials.';
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  /// Scollega account Google
  Future<void> unlinkGoogleAccount() async {
    await _repository.signOut();
    state = state.copyWith(user: null);
  }

  /// Logout completo (reset onboarding)
  Future<void> signOut() async {
    await _repository.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingCompletedKey);
    state = const AuthState();
  }

  /// Autenticazione biometrica
  Future<bool> authenticateWithBiometrics() async {
    return _repository.authenticateWithBiometrics();
  }

  /// Reset onboarding (per rivederlo)
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
