import 'dart:math' as math;

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
                    // none: le etichette delle zone possono "uscire" sul fianco
                    // del corpo, nei margini laterali della silhouette.
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: SvgPicture.asset(
                          _asset,
                          fit: BoxFit.fill,
                          theme: SvgTheme(currentColor: bodyColor),
                        ),
                      ),
                      // Blocchi tenui che raggruppano i punti per ZONA reale
                      // (es. Gluteo Dx e Gluteo Sx separati, e funziona anche
                      // con zone nuove). Dietro ai marker, non intercettano tap.
                      ..._zoneBlocks(visible, c, isDark),
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

  /// Palette di colori (on-brand, distinti dai colori di stato verde/ambra/
  /// rosso dei punti) assegnati ciclicamente alle zone per distinguerle.
  static const _zonePalette = <Color>[
    AppTokens.accent, // viola
    AppTokens.pink, // rosa
    Color(0xFF3D9BF0), // blu
    AppTokens.accentEnd, // magenta
    Color(0xFF21B8C4), // ciano
    Color(0xFF9B7CF0), // lilla
  ];

  /// Disegna un blocco tenue attorno ai punti di ogni ZONA presente nella vista
  /// corrente (raggruppati per zoneId). Il riquadro è il bounding box dei punti
  /// della zona, con un piccolo margine; l'etichetta è il nome della zona
  /// (displayName, che include "Dx/Sx"). Generico: funziona anche con zone
  /// personalizzate create dall'utente.
  List<Widget> _zoneBlocks(
    List<BodyMapPoint> visible,
    BoxConstraints c,
    bool isDark,
  ) {
    final byZone = <int, List<BodyMapPoint>>{};
    for (final p in visible) {
      byZone.putIfAbsent(p.zoneId, () => []).add(p);
    }
    final zoneIds = byZone.keys.toList()..sort();
    return [
      for (var i = 0; i < zoneIds.length; i++)
        _zoneBlock(byZone[zoneIds[i]]!, c, isDark, i),
    ];
  }

  /// Blocco tenue per una singola zona. Volutamente più leggero
  /// dell'evidenziazione dell'editor (niente ombra, bordo sottile, riempimento
  /// appena percettibile) per non competere con i colori di stato dei punti.
  Widget _zoneBlock(
    List<BodyMapPoint> pts,
    BoxConstraints c,
    bool isDark,
    int colorIndex,
  ) {
    var minX = 1.0, minY = 1.0, maxX = 0.0, maxY = 0.0;
    for (final p in pts) {
      minX = math.min(minX, p.x);
      maxX = math.max(maxX, p.x);
      minY = math.min(minY, p.y);
      maxY = math.max(maxY, p.y);
    }
    // Margine attorno ai marker (raggio marker + respiro).
    const pad = 18.0;
    final left = minX * c.maxWidth - pad;
    final top = minY * c.maxHeight - pad;
    final width = (maxX - minX) * c.maxWidth + pad * 2;
    final height = (maxY - minY) * c.maxHeight + pad * 2;

    final color = _zonePalette[colorIndex % _zonePalette.length];
    final chipBg = (isDark ? AppTokens.darkSurface : AppTokens.lightSurface)
        .withValues(alpha: 0.92);

    // Etichetta sul FIANCO esterno del blocco (non sopra): le zone nella metà
    // sinistra hanno il chip a sinistra, quelle a destra a destra. Così le
    // coppie Dx/Sx adiacenti (addome, cosce) finiscono su lati opposti e non si
    // sovrappongono. Il chip "esce" dal blocco verso il margine laterale.
    final onLeftHalf = (minX + maxX) / 2 <= 0.5;
    final label = Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        pts.first.zoneName,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color.withValues(alpha: isDark ? 0.95 : 0.75),
        ),
      ),
    );

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: IgnorePointer(
        // clipBehavior none: l'etichetta "appoggia" sul bordo superiore (in
        // stile legenda) anziché stare dentro dove ci sono i punti.
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.10 : 0.06),
                  border: Border.all(
                    color: color.withValues(alpha: 0.25),
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            // Chip ancorato al bordo esterno, centrato in verticale e su una
            // sola riga (OverflowBox → larghezza non vincolata dal blocco).
            Positioned(
              top: 0,
              bottom: 0,
              width: 0,
              left: onLeftHalf ? 0 : null,
              right: onLeftHalf ? null : 0,
              child: OverflowBox(
                maxWidth: double.infinity,
                alignment:
                    onLeftHalf ? Alignment.centerRight : Alignment.centerLeft,
                child: label,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Etichetta del marker: nome custom del punto (troncato a 3 caratteri per
  /// stare nel cerchio, come nell'editor silhouette) altrimenti il numero.
  String _markerLabel(BodyMapPoint p) {
    final name = p.customName;
    if (name != null && name.isNotEmpty) {
      return name.length > 3 ? name.substring(0, 3) : name;
    }
    return '${p.pointNumber}';
  }

  Widget _marker(BodyMapPoint p, BoxConstraints c, bool isDark) {
    final selected = p.zoneId == widget.selectedZoneId &&
        p.pointNumber == widget.selectedPointNumber;
    final mutedColor = isDark ? AppTokens.darkMuted : AppTokens.lightMuted;
    final color =
        p.isBlacklisted ? mutedColor : p.usageLevel.getColor(isDark);
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
                _markerLabel(p),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  // Nome custom (anche corto) leggermente più piccolo del numero.
                  fontSize: p.hasCustomName ? 8 : 10,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
