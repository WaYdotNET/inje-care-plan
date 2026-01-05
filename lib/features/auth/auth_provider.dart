import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _onboardingCompletedKey = 'onboarding_completed';
const _homeStyleKey = 'home_style';

/// Stile della home screen
enum HomeStyle {
  classic,
  minimal;

  String get displayName => switch (this) {
    HomeStyle.classic => 'Classica',
    HomeStyle.minimal => 'Minimalista',
  };

  String get description => switch (this) {
    HomeStyle.classic => 'Vista completa con tutte le informazioni',
    HomeStyle.minimal => 'Solo prossima iniezione con silhouette',
  };
}

/// Stato dell'app (solo onboarding)
class AppState {
  final bool isLoading;
  final bool hasCompletedOnboarding;
  final HomeStyle homeStyle;
  final String? error;

  const AppState({
    this.isLoading = false,
    this.hasCompletedOnboarding = false,
    this.homeStyle = HomeStyle.minimal,
    this.error,
  });

  AppState copyWith({
    bool? isLoading,
    bool? hasCompletedOnboarding,
    HomeStyle? homeStyle,
    String? error,
  }) {
    return AppState(
      isLoading: isLoading ?? this.isLoading,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      homeStyle: homeStyle ?? this.homeStyle,
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
      final homeStyleStr = prefs.getString(_homeStyleKey) ?? 'classic';
      final homeStyle = HomeStyle.values.firstWhere(
        (s) => s.name == homeStyleStr,
        orElse: () => HomeStyle.minimal,
      );

      state = AppState(
        hasCompletedOnboarding: hasCompleted,
        homeStyle: homeStyle,
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

  Future<void> setHomeStyle(HomeStyle style) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_homeStyleKey, style.name);
      state = state.copyWith(homeStyle: style);
    } catch (e) {
      state = state.copyWith(error: e.toString());
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

/// Provider per lo stile della home
final homeStyleProvider = Provider<HomeStyle>((ref) {
  return ref.watch(authNotifierProvider).homeStyle;
});
