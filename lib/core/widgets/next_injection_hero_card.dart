import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_tokens.dart';

/// Card hero a gradiente "Prossima iniezione" per la Home.
class NextInjectionHeroCard extends StatelessWidget {
  const NextInjectionHeroCard({
    super.key,
    required this.pointLabel,
    required this.scheduledAt,
    required this.ctaLabel,
    required this.onCta,
    this.relative,
  });

  final String pointLabel;
  final DateTime scheduledAt;
  final String ctaLabel;
  final VoidCallback onCta;
  final String? relative;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(scheduledAt);
    final dateLong = DateFormat('EEEE d MMM', 'it').format(scheduledAt);
    final sub = relative == null ? dateLong : '$dateLong · $relative';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTokens.accentGradient,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppTokens.softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              'PROSSIMA · $time',
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            pointLabel,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Semantics(
            button: true,
            label: ctaLabel,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.button),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.button),
                onTap: onCta,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  alignment: Alignment.center,
                  child: Text(
                    ctaLabel,
                    style: const TextStyle(color: AppTokens.accent, fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
