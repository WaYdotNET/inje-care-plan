import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _onboardingCompletedKey = 'onboarding_completed';

/// Stato dell'app (solo onboarding)
class AppState {
  final bool isLoading;
  final bool hasCompletedOnboarding;
  final String? error;

  const AppState({
    this.isLoading = false,
    this.hasCompletedOnboarding = false,
    this.error,
  });

  AppState copyWith({
    bool? isLoading,
    bool? hasCompletedOnboarding,
    String? error,
  }) {
    return AppState(
      isLoading: isLoading ?? this.isLoading,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      error: error,
    );
  }

  /// L'utente è autenticato se ha completato l'onboarding
  bool get isAuthenticated => hasCompletedOnboarding;
}

/// Notifier per gestire l'onboarding
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

      state = AppState(
        hasCompletedOnboarding: hasCompleted,
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
    state = const AppState();
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
