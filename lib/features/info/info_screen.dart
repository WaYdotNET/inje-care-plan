import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';

/// Info screen showing project information
class InfoScreen extends ConsumerWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Informazioni'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App logo
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/images/logo.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),

            // App name
            Text(
              'InjeCare Plan',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Version
            Text(
              'Versione 1.0.0',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
              ),
            ),
            const SizedBox(height: 32),

            // Description card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: isDark ? AppColors.darkFoam : AppColors.dawnFoam,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Cos\'è InjeCare Plan?',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'InjeCare Plan è un\'applicazione progettata per aiutare i pazienti '
                      'che seguono terapie con iniezioni sottocutanee a gestire in modo '
                      'semplice e sicuro il proprio piano di trattamento.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Caratteristiche principali:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _FeatureItem(
                      icon: Icons.calendar_month,
                      text: 'Calendario iniezioni programmato',
                      isDark: isDark,
                    ),
                    _FeatureItem(
                      icon: Icons.accessibility_new,
                      text: 'Mappa del corpo per rotazione punti',
                      isDark: isDark,
                    ),
                    _FeatureItem(
                      icon: Icons.notifications_active,
                      text: 'Promemoria intelligenti',
                      isDark: isDark,
                    ),
                    _FeatureItem(
                      icon: Icons.history,
                      text: 'Storico completo con esportazione',
                      isDark: isDark,
                    ),
                    _FeatureItem(
                      icon: Icons.lock_outline,
                      text: 'Privacy-first: dati solo sul tuo dispositivo',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Privacy card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: isDark ? AppColors.darkPine : AppColors.dawnPine,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Privacy e Sicurezza',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '• I tuoi dati sono salvati localmente sul dispositivo\n'
                      '• Nessun dato viene inviato a server esterni\n'
                      '• Backup opzionale e crittografato su Google Drive\n'
                      '• Sblocco biometrico disponibile\n'
                      '• Nessun riferimento esplicito a condizioni mediche nell\'interfaccia',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Author card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          color: isDark ? AppColors.darkIris : AppColors.dawnIris,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Autore',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sviluppato da Carlo Bertini (WaYdotNET)',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _launchUrl('https://waydotnet.com'),
                      icon: const Icon(Icons.language),
                      label: const Text('waydotnet.com'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _launchUrl(
                        'https://github.com/WaYdotNET/inje-care-plan',
                      ),
                      icon: const Icon(Icons.code),
                      label: const Text('GitHub Repository'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // License card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.gavel,
                          color: isDark ? AppColors.darkGold : AppColors.dawnGold,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Licenza',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Questo software è rilasciato con licenza GPL-3.0.\n'
                      'È software libero: puoi usarlo, studiarlo, '
                      'modificarlo e ridistribuirlo.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '© 2024-2026 Carlo Bertini (WaYdotNET)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  final IconData icon;
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? AppColors.darkFoam : AppColors.dawnFoam,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
