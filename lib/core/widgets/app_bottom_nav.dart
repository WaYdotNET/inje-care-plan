import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_tokens.dart';

/// Bottom navigation bar con 4 tab e pulsante ＋ centrale per registrare
/// un'iniezione.
///
/// Indice delle tab: 0=Home, 1=Calendario, 2=Statistiche, 3=Impostazioni.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.onAdd,
    super.key,
  });

  final int currentIndex;
  final void Function(int) onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final muted = isDark ? AppTokens.darkMuted : AppTokens.lightMuted;

    return Material(
      color: surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _TabItem(
                icon: PhosphorIconsDuotone.house,
                label: 'Home',
                selected: currentIndex == 0,
                muted: muted,
                onTap: () => onTap(0),
              ),
              _TabItem(
                icon: PhosphorIconsDuotone.calendarBlank,
                label: 'Calendario',
                selected: currentIndex == 1,
                muted: muted,
                onTap: () => onTap(1),
              ),
              // Pulsante centrale ＋
              _AddButton(onAdd: onAdd),
              _TabItem(
                icon: PhosphorIconsDuotone.chartBar,
                label: 'Statistiche',
                selected: currentIndex == 2,
                muted: muted,
                onTap: () => onTap(2),
              ),
              _TabItem(
                icon: PhosphorIconsDuotone.gear,
                label: 'Impostazioni',
                selected: currentIndex == 3,
                muted: muted,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.muted,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTokens.accent : muted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        customBorder: const RoundedRectangleBorder(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(
              icon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 64,
      child: Center(
        child: GestureDetector(
          key: const Key('app_bottom_nav_add'),
          onTap: onAdd,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppTokens.accentGradient,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: AppTokens.softShadow(dark: isDark),
            ),
            child: const Icon(
              PhosphorIconsDuotone.plus,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
