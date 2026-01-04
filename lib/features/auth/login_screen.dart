import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/services/notification_settings_provider.dart';
import '../../app/router.dart';
import 'auth_provider.dart';

/// Onboarding screen
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  int _currentPage = 0;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Watch auth state to navigate when authenticated
    ref.listen(authStateProvider, (previous, next) {
      if (next.isAuthenticated && !(previous?.isAuthenticated ?? false)) {
        context.go(AppRoutes.home);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              if (_currentPage < 2)
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: () => setState(() => _currentPage = 2),
                    child: const Text('Salta'),
                  ),
                )
              else
                const SizedBox(height: 48),

              const Spacer(),

              // Page content
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildPageContent(isDark),
              ),

              const Spacer(),

              // Page indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIndicator(0, isDark),
                  const SizedBox(width: 8),
                  _buildIndicator(1, isDark),
                  const SizedBox(width: 8),
                  _buildIndicator(2, isDark),
                ],
              ),

              const SizedBox(height: 48),

              // Action button
              SizedBox(
                width: double.infinity,
                child: _currentPage < 2
                    ? ElevatedButton(
                        onPressed: () => setState(() => _currentPage++),
                        child: const Text('Continua'),
                      )
                    : ElevatedButton.icon(
                        onPressed: _isLoading ? null : _continueToApp,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.arrow_forward),
                        label: const Text('Inizia'),
                      ),
              ),

              const SizedBox(height: 16),

              // Info text
              Text(
                _currentPage < 2
                    ? 'Continuando, accetti i Termini di Servizio\ne la Privacy Policy'
                    : 'I tuoi dati sono salvati localmente\nsul tuo dispositivo',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent(bool isDark) {
    return switch (_currentPage) {
      0 => _OnboardingPage(
          key: const ValueKey(0),
          icon: Icons.favorite,
          title: 'InjeCare Plan',
          description: 'La tua terapia, sotto controllo.\nGestisci le iniezioni con cura e semplicità.',
          isDark: isDark,
          showLogo: true,
        ),
      1 => _OnboardingPage(
          key: const ValueKey(1),
          icon: Icons.accessibility_new,
          title: 'Alterna i siti',
          description: 'Suggerimenti automatici per la rotazione ottimale dei punti di iniezione',
          isDark: isDark,
        ),
      _ => _OnboardingPage(
          key: const ValueKey(2),
          icon: Icons.notifications_active,
          title: 'Mai più una dose dimenticata',
          description: 'Ricevi notifiche personalizzate per ogni iniezione programmata',
          isDark: isDark,
        ),
    };
  }

  Widget _buildIndicator(int page, bool isDark) {
    final isActive = _currentPage == page;
    return GestureDetector(
      onTap: () => setState(() => _currentPage = page),
      child: Container(
        width: isActive ? 24 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? AppColors.darkPine : AppColors.dawnPine)
              : (isDark ? AppColors.darkMuted : AppColors.dawnMuted),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  /// Continua all'app
  Future<void> _continueToApp() async {
    setState(() => _isLoading = true);

    try {
      // Request notification permissions
      await _requestNotificationPermissions();

      final notifier = ref.read(authNotifierProvider.notifier);
      await notifier.completeOnboarding();

      if (mounted) {
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Request notification permissions
  Future<void> _requestNotificationPermissions() async {
    final notificationNotifier = ref.read(notificationSettingsProvider.notifier);
    final shouldRequest = await notificationNotifier.shouldRequestPermissions();

    if (shouldRequest) {
      await notificationNotifier.requestPermissions();
    }
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.isDark,
    this.showLogo = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isDark;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLogo)
          Image.asset(
            'assets/images/logo.png',
            width: 160,
            height: 160,
          )
        else
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkOverlay : AppColors.dawnOverlay,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              icon,
              size: 64,
              color: isDark ? AppColors.darkPine : AppColors.dawnPine,
            ),
          ),

        const SizedBox(height: 32),

        Text(
          title,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        Text(
          description,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isDark ? AppColors.darkSubtle : AppColors.dawnSubtle,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
