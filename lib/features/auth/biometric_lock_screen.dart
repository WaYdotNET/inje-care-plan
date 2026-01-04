import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import 'auth_provider.dart';

/// Schermata di sblocco biometrico
class BiometricLockScreen extends ConsumerStatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  ConsumerState<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends ConsumerState<BiometricLockScreen> {
  bool _isAuthenticating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Avvia automaticamente l'autenticazione biometrica
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _error = null;
    });

    try {
      final success = await ref.read(authNotifierProvider.notifier).unlockWithBiometrics();
      
      if (!success && mounted) {
        setState(() {
          _error = 'Autenticazione non riuscita';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Errore: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkOverlay : AppColors.dawnOverlay,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: isDark ? AppColors.darkPine : AppColors.dawnPine,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'InjeCare Plan',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'App bloccata',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark ? AppColors.darkSubtle : AppColors.dawnSubtle,
                ),
              ),

              const SizedBox(height: 48),

              // Error message
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.darkLove : AppColors.dawnLove,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Unlock button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isAuthenticating ? null : _authenticate,
                  icon: _isAuthenticating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.fingerprint),
                  label: Text(
                    _isAuthenticating ? 'Verifica in corso...' : 'Sblocca con biometria',
                  ),
                ),
              ),

              const Spacer(),

              // Info text
              Text(
                'Usa Face ID o Touch ID per sbloccare l\'app',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

