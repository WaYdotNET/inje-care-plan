import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _onboardingCompletedKey = 'onboarding_completed';
const _biometricEnabledKey = 'biometric_enabled';

/// Stato dell'app (onboarding + biometria)
class AppState {
  final bool isLoading;
  final bool hasCompletedOnboarding;
  final bool biometricEnabled;
  final bool biometricUnlocked;
  final String? error;

  const AppState({
    this.isLoading = false,
    this.hasCompletedOnboarding = false,
    this.biometricEnabled = false,
    this.biometricUnlocked = true, // Default: unlocked if biometric disabled
    this.error,
  });

  AppState copyWith({
    bool? isLoading,
    bool? hasCompletedOnboarding,
    bool? biometricEnabled,
    bool? biometricUnlocked,
    String? error,
  }) {
    return AppState(
      isLoading: isLoading ?? this.isLoading,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      biometricUnlocked: biometricUnlocked ?? this.biometricUnlocked,
      error: error,
    );
  }

  /// L'utente è autenticato se ha completato l'onboarding E (biometria disattivata O sbloccato)
  bool get isAuthenticated => hasCompletedOnboarding && (!biometricEnabled || biometricUnlocked);

  /// Deve mostrare la schermata di sblocco biometrico
  bool get requiresBiometricUnlock => hasCompletedOnboarding && biometricEnabled && !biometricUnlocked;
}

/// Notifier per gestire l'onboarding e la biometria
class AppStateNotifier extends Notifier<AppState> {
  @override
  AppState build() {
    Future.microtask(() => initialize());
    return const AppState(isLoading: true);
  }

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasCompleted = prefs.getBool(_onboardingCompletedKey) ?? false;
      final biometricEnabled = prefs.getBool(_biometricEnabledKey) ?? false;

      state = AppState(
        hasCompletedOnboarding: hasCompleted,
        biometricEnabled: biometricEnabled,
        biometricUnlocked: !biometricEnabled, // Se biometria disattivata, già sbloccato
      );
    } catch (e) {
      state = AppState(error: e.toString());
    }
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompletedKey, true);
      state = state.copyWith(isLoading: false, hasCompletedOnboarding: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingCompletedKey);
    await prefs.remove(_biometricEnabledKey);
    state = const AppState();
  }

  /// Attiva/disattiva lo sblocco biometrico
  Future<bool> setBiometricEnabled(bool enabled) async {
    try {
      // Se si vuole attivare, verifica prima che la biometria sia disponibile
      if (enabled) {
        final canAuth = await _localAuth.canCheckBiometrics &&
                        await _localAuth.isDeviceSupported();
        if (!canAuth) {
          return false;
        }

        // Verifica l'autenticazione prima di attivare
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Verifica la tua identità per attivare lo sblocco biometrico',
        );
        if (!authenticated) {
          return false;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, enabled);
      state = state.copyWith(
        biometricEnabled: enabled,
        biometricUnlocked: true, // Se appena attivato/disattivato, è sbloccato
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Sblocca con biometria
  Future<bool> unlockWithBiometrics() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Sblocca InjeCare Plan',
      );

      if (authenticated) {
        state = state.copyWith(biometricUnlocked: true);
      }
      return authenticated;
    } catch (e) {
      return false;
    }
  }

  /// Blocca l'app (per quando va in background)
  void lockApp() {
    if (state.biometricEnabled) {
      state = state.copyWith(biometricUnlocked: false);
    }
  }
}

// === Provider ===

final authNotifierProvider = NotifierProvider<AppStateNotifier, AppState>(
  AppStateNotifier.new,
);

/// Alias per compatibilità
final authStateProvider = authNotifierProvider;

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isAuthenticated;
});

/// Provider per verificare se serve lo sblocco biometrico
final requiresBiometricUnlockProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).requiresBiometricUnlock;
});

/// Provider per verificare se la biometria è attiva
final biometricEnabledProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).biometricEnabled;
});

// === Biometria ===

final _localAuth = LocalAuthentication();

final biometricAvailableProvider = FutureProvider<bool>((ref) async {
  try {
    return await _localAuth.canCheckBiometrics && await _localAuth.isDeviceSupported();
  } catch (e) {
    return false;
  }
});

/// Funzione legacy per compatibilità
Future<bool> authenticateWithBiometrics() async {
  try {
    return await _localAuth.authenticate(localizedReason: 'Sblocca InjeCare Plan');
  } catch (e) {
    return false;
  }
}
