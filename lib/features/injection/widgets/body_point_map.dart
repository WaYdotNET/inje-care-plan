import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_tokens.dart';
import '../injection_provider.dart' show BodyMapPoint;
import '../point_usage_level.dart';
import 'body_silhouette_editor.dart' show BodyView;

/// Mappa del corpo (sola lettura) con tutti i punti delle zone abilitate,
/// colorati per stato. Toggle Fronte/Retro, marker toccabili, punto suggerito
/// con anello viola.
class BodyPointMap extends StatefulWidget {
  const BodyPointMap({
    required this.points,
    required this.selectedZoneId,
    required this.selectedPointNumber,
    required this.onTap,
    super.key,
  });

  final List<BodyMapPoint> points;
  final int? selectedZoneId;
  final int? selectedPointNumber;
  final void Function(BodyMapPoint point) onTap;

  @override
  State<BodyPointMap> createState() => _BodyPointMapState();
}

class _BodyPointMapState extends State<BodyPointMap> {
  BodyView _view = BodyView.front;

  @override
  void initState() {
    super.initState();
    // Apri sul lato che contiene il suggerito, altrimenti fronte.
    final suggested = widget.points.where((p) => p.isSuggested);
    if (suggested.isNotEmpty) _view = suggested.first.bodyView;
  }

  String get _asset => _view == BodyView.front
      ? 'assets/images/body_silhouette_front.svg'
      : 'assets/images/body_silhouette_back.svg';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bodyColor = AppTokens.accentEnd.withValues(alpha: 0.7);
    final visible = widget.points.where((p) => p.bodyView == _view).toList();

    return Column(
      children: [
        SegmentedButton<BodyView>(
          segments: const [
            ButtonSegment(
              value: BodyView.front,
              label: Text('Fronte'),
              icon: Icon(PhosphorIconsDuotone.user),
            ),
            ButtonSegment(
              value: BodyView.back,
              label: Text('Retro'),
              icon: Icon(PhosphorIconsDuotone.userCircle),
            ),
          ],
          selected: {_view},
          onSelectionChanged: (s) => setState(() => _view = s.first),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 150 / 446,
              child: LayoutBuilder(
                builder: (context, c) {
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: SvgPicture.asset(
                          _asset,
                          fit: BoxFit.fill,
                          theme: SvgTheme(currentColor: bodyColor),
                        ),
                      ),
                      if (visible.isEmpty)
                        const Center(
                          child: Text('Nessun punto in questa vista'),
                        ),
                      ...visible.map((p) => _marker(p, c, isDark)),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _marker(BodyMapPoint p, BoxConstraints c, bool isDark) {
    final selected = p.zoneId == widget.selectedZoneId &&
        p.pointNumber == widget.selectedPointNumber;
    final color = p.isBlacklisted ? Colors.grey : p.usageLevel.getColor(isDark);
    final size = selected ? 28.0 : 22.0;
    // Area di tocco attorno al marker. Bilanciata: il corpo è stretto (~150px)
    // e i punti ravvicinati, quindi una hit-area troppo ampia farebbe "rubare"
    // il tap ai vicini. 32px è il compromesso tra facilità di tocco e precisione.
    const hit = 32.0;
    return Positioned(
      left: p.x * c.maxWidth - hit / 2,
      top: p.y * c.maxHeight - hit / 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onTap(p),
        child: SizedBox(
          width: hit,
          height: hit,
          child: Center(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.85),
                  width: selected ? 3 : 2,
                ),
                boxShadow: p.isSuggested
                    ? const [
                        BoxShadow(
                          color: AppTokens.accent,
                          blurRadius: 0,
                          spreadRadius: 3,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                '${p.pointNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
