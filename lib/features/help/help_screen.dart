import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

/// Help screen with user guide
class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guida'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HelpSection(
            icon: Icons.play_circle_outline,
            title: 'Come iniziare',
            isDark: isDark,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HelpStep(
                  number: 1,
                  title: 'Configura il piano terapeutico',
                  description: 'Vai in Impostazioni > Piano Iniezioni per impostare '
                      'i giorni della settimana e l\'orario delle iniezioni.',
                  isDark: isDark,
                ),
                _HelpStep(
                  number: 2,
                  title: 'Registra le iniezioni',
                  description: 'Tocca il pulsante + o vai su "Nuova" per registrare '
                      'una nuova iniezione. Seleziona la zona e il punto sul corpo.',
                  isDark: isDark,
                ),
                _HelpStep(
                  number: 3,
                  title: 'Segui i promemoria',
                  description: 'L\'app ti invierà promemoria prima di ogni iniezione '
                      'programmata. Puoi personalizzare l\'anticipo nelle impostazioni.',
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _HelpSection(
            icon: Icons.accessibility_new,
            title: 'Mappa del corpo',
            isDark: isDark,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'La mappa del corpo ti aiuta a ruotare i punti di iniezione '
                  'per evitare di usare sempre lo stesso punto.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                _InfoBox(
                  icon: Icons.lightbulb_outline,
                  text: 'L\'app suggerisce automaticamente il prossimo punto '
                      'basandosi sulla rotazione ottimale.',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                Text(
                  'Zone disponibili:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _ZoneList(isDark: isDark),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _HelpSection(
            icon: Icons.block,
            title: 'Escludere punti',
            isDark: isDark,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Puoi escludere dei punti dalla rotazione se:',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                _BulletPoint(text: 'Hai una cicatrice in quel punto', isDark: isDark),
                _BulletPoint(text: 'Hai avuto una reazione', isDark: isDark),
                _BulletPoint(text: 'È difficile da raggiungere', isDark: isDark),
                const SizedBox(height: 12),
                Text(
                  'Per escludere un punto: Impostazioni > Punti esclusi > Aggiungi',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _HelpSection(
            icon: Icons.calendar_month,
            title: 'Calendario',
            isDark: isDark,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Il calendario mostra tutte le iniezioni passate e programmate.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                _StatusLegend(isDark: isDark),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _HelpSection(
            icon: Icons.psychology,
            title: 'Pattern di rotazione',
            isDark: isDark,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'L\'app offre diversi pattern per suggerire la prossima zona:',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                _BulletPoint(text: 'Suggerimento AI: analizza lo storico per la scelta ottimale', isDark: isDark),
                _BulletPoint(text: 'Sequenza Zone: ruota tra le 8 zone in ordine', isDark: isDark),
                _BulletPoint(text: 'Alternanza Sx/Dx: alterna lato sinistro e destro', isDark: isDark),
                _BulletPoint(text: 'Rotazione Settimanale: una zona diversa ogni settimana', isDark: isDark),
                _BulletPoint(text: 'Orario/Antiorario: segue un percorso circolare sul corpo', isDark: isDark),
                _BulletPoint(text: 'Personalizzato: crea la tua sequenza', isDark: isDark),
                const SizedBox(height: 12),
                Text(
                  'Per cambiare: Impostazioni > Pattern di Rotazione',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _HelpSection(
            icon: Icons.home,
            title: 'Stili Home',
            isDark: isDark,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Puoi scegliere tra due stili di home page:',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                _ExportFormat(
                  icon: Icons.dashboard,
                  title: 'Classica',
                  description: 'Vista completa con panoramica settimanale, '
                      'suggerimenti e statistiche.',
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _ExportFormat(
                  icon: Icons.center_focus_strong,
                  title: 'Minimalista',
                  description: 'Solo la prossima iniezione con silhouette. '
                      'Tocca per registrare subito.',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                Text(
                  'Per cambiare: Impostazioni > Stile Home',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _HelpSection(
            icon: Icons.sync_alt,
            title: 'Import/Export dati',
            isDark: isDark,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestisci i tuoi dati in modo sicuro:',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Esporta:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _ExportFormat(
                  icon: Icons.picture_as_pdf,
                  title: 'PDF',
                  description: 'Formato leggibile, ideale per condividere '
                      'con il medico o stampare.',
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _ExportFormat(
                  icon: Icons.table_chart,
                  title: 'CSV',
                  description: 'Formato dati per backup o trasferimento '
                      'su altro dispositivo.',
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                Text(
                  'Importa:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _ExportFormat(
                  icon: Icons.file_upload_outlined,
                  title: 'CSV',
                  description: 'Ripristina dati da un backup CSV esportato '
                      'precedentemente.',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _InfoBox(
                  icon: Icons.security,
                  text: 'I tuoi dati restano sempre sul dispositivo. '
                      'Nessun dato viene inviato a server esterni.',
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _HelpSection(
            icon: Icons.help_outline,
            title: 'Domande frequenti',
            isDark: isDark,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FaqItem(
                  question: 'I miei dati sono sicuri?',
                  answer: 'Sì, tutti i dati sono salvati solo sul tuo dispositivo. '
                      'L\'app funziona completamente offline e non invia dati a server esterni.',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _FaqItem(
                  question: 'Come faccio backup dei dati?',
                  answer: 'Vai in Impostazioni > Esporta storico > CSV. '
                      'Il file può essere reimportato su un nuovo dispositivo.',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _FaqItem(
                  question: 'Come modifico un\'iniezione già registrata?',
                  answer: 'Vai nel Calendario, tocca l\'iniezione e seleziona '
                      '"Modifica punto" per cambiare la zona o il punto.',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _FaqItem(
                  question: 'Posso cambiare i giorni delle iniezioni?',
                  answer: 'Sì, vai in Impostazioni > Piano Iniezioni > '
                      'Giorni della settimana.',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _FaqItem(
                  question: 'Cosa succede se aggiorno l\'app?',
                  answer: 'I tuoi dati vengono preservati. L\'app è progettata '
                      'per aggiornamenti senza perdita di dati.',
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({
    required this.icon,
    required this.title,
    required this.isDark,
    required this.content,
  });

  final IconData icon;
  final String title;
  final bool isDark;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isDark ? AppColors.darkFoam : AppColors.dawnFoam,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }
}

class _HelpStep extends StatelessWidget {
  const _HelpStep({
    required this.number,
    required this.title,
    required this.description,
    required this.isDark,
  });

  final int number;
  final String title;
  final String description;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkFoam : AppColors.dawnFoam,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  color: isDark ? AppColors.darkBase : AppColors.dawnBase,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  final IconData icon;
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkFoam : AppColors.dawnFoam)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isDark ? AppColors.darkFoam : AppColors.dawnFoam)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? AppColors.darkFoam : AppColors.dawnFoam,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneList extends StatelessWidget {
  const _ZoneList({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final zones = [
      ('Coscia Destra', 'CD', 6),
      ('Coscia Sinistra', 'CS', 6),
      ('Braccio Destro', 'BD', 4),
      ('Braccio Sinistro', 'BS', 4),
      ('Addome Destro', 'AD', 4),
      ('Addome Sinistro', 'AS', 4),
      ('Gluteo Destro', 'GD', 4),
      ('Gluteo Sinistro', 'GS', 4),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: zones.map((zone) {
        return Chip(
          label: Text('${zone.$1} (${zone.$3} punti)'),
          avatar: CircleAvatar(
            backgroundColor: isDark ? AppColors.darkFoam : AppColors.dawnFoam,
            child: Text(
              zone.$2,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkBase : AppColors.dawnBase,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  const _BulletPoint({required this.text, required this.isDark});

  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: isDark ? AppColors.darkFoam : AppColors.dawnFoam,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _StatusLegend extends StatelessWidget {
  const _StatusLegend({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LegendItem(
          color: isDark ? AppColors.darkPine : AppColors.dawnPine,
          label: 'Completata',
          isDark: isDark,
        ),
        _LegendItem(
          color: isDark ? AppColors.darkGold : AppColors.dawnGold,
          label: 'Programmata',
          isDark: isDark,
        ),
        _LegendItem(
          color: isDark ? AppColors.darkLove : AppColors.dawnLove,
          label: 'Saltata',
          isDark: isDark,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.isDark,
  });

  final Color color;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ExportFormat extends StatelessWidget {
  const _ExportFormat({
    required this.icon,
    required this.title,
    required this.description,
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: isDark ? AppColors.darkFoam : AppColors.dawnFoam,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({
    required this.question,
    required this.answer,
    required this.isDark,
  });

  final String question;
  final String answer;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          answer,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
