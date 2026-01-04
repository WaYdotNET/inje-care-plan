import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/services/notification_settings_provider.dart';
import '../../core/services/demo_data_service.dart';
import '../../core/database/database_provider.dart';
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
  bool _insertDemoData = false;

  static const int _totalPages = 4;

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
              if (_currentPage < _totalPages - 1)
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: () => setState(() => _currentPage = _totalPages - 1),
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
                children: List.generate(
                  _totalPages,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildIndicator(index, isDark),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Action button
              SizedBox(
                width: double.infinity,
                child: _currentPage < _totalPages - 1
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
                _currentPage < _totalPages - 1
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
      2 => _OnboardingPage(
          key: const ValueKey(2),
          icon: Icons.notifications_active,
          title: 'Mai più una dose dimenticata',
          description: 'Ricevi notifiche personalizzate per ogni iniezione programmata',
          isDark: isDark,
        ),
      _ => _DemoDataPage(
          key: const ValueKey(3),
          isDark: isDark,
          insertDemoData: _insertDemoData,
          onChanged: (value) => setState(() => _insertDemoData = value),
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

      // Insert demo data if requested
      if (_insertDemoData) {
        final db = ref.read(databaseProvider);
        await DemoDataService.generateDemoData(db);
      }

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

/// Pagina per scegliere se inserire dati demo
class _DemoDataPage extends StatelessWidget {
  const _DemoDataPage({
    super.key,
    required this.isDark,
    required this.insertDemoData,
    required this.onChanged,
  });

  final bool isDark;
  final bool insertDemoData;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkOverlay : AppColors.dawnOverlay,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            Icons.science_outlined,
            size: 64,
            color: isDark ? AppColors.darkFoam : AppColors.dawnFoam,
          ),
        ),

        const SizedBox(height: 32),

        Text(
          'Dati di prova',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        Text(
          'Vuoi inserire alcuni dati demo per\nprovare le funzionalità dell\'app?',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isDark ? AppColors.darkSubtle : AppColors.dawnSubtle,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),

        // Option cards
        _OptionCard(
          isDark: isDark,
          isSelected: !insertDemoData,
          icon: Icons.start,
          title: 'Inizia da zero',
          description: 'Storico vuoto, inserisci le tue iniezioni',
          onTap: () => onChanged(false),
        ),

        const SizedBox(height: 12),

        _OptionCard(
          isDark: isDark,
          isSelected: insertDemoData,
          icon: Icons.auto_awesome,
          title: 'Inserisci dati demo',
          description: '~12 iniezioni nell\'ultimo mese',
          onTap: () => onChanged(true),
        ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.isDark,
    required this.isSelected,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final bool isDark;
  final bool isSelected;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = isDark ? AppColors.darkPine : AppColors.dawnPine;
    final borderColor = isSelected
        ? selectedColor
        : (isDark ? AppColors.darkMuted : AppColors.dawnMuted);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? (isDark ? AppColors.darkOverlay : AppColors.dawnOverlay)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? selectedColor : borderColor,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isSelected ? selectedColor : null,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.darkSubtle : AppColors.dawnSubtle,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: selectedColor),
          ],
        ),
      ),
    );
  }
}
