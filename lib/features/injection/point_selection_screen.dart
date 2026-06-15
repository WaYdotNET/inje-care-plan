import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/services/diagnostic_log_service.dart';
import '../../core/theme/app_tokens.dart';
import '../../models/body_zone.dart';
import '../../models/therapy_plan.dart';
import 'zone_provider.dart';
import 'injection_provider.dart' hide blacklistedPointsProvider;
import 'point_selection_classic.dart';
import 'point_selection_mode.dart';
import 'point_selection_style_provider.dart';
import 'widgets/body_point_map.dart';

export 'point_selection_mode.dart';

/// Dispatcher: in base allo stile scelto (Impostazioni) mostra la nuova mappa
/// del corpo oppure la versione classica a step/scroll. Default: mappa.
class PointSelectionScreen extends ConsumerWidget {
  const PointSelectionScreen({
    super.key,
    required this.mode,
    this.initialZoneId,
    this.scheduledDate,
    this.existingInjectionId,
  });

  final PointSelectionMode mode;
  final int? initialZoneId;
  final DateTime? scheduledDate;
  final int? existingInjectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(pointSelectionStyleProvider);
    if (style == PointSelectionStyle.classic) {
      return PointSelectionClassicScreen(
        mode: mode,
        initialZoneId: initialZoneId,
        scheduledDate: scheduledDate,
        existingInjectionId: existingInjectionId,
      );
    }
    return PointSelectionMapScreen(
      mode: mode,
      initialZoneId: initialZoneId,
      scheduledDate: scheduledDate,
      existingInjectionId: existingInjectionId,
    );
  }
}

// Emoji used from zone.emoji property

/// Nuova selezione punto: mappa unica del corpo con tutti i punti colorati.
class PointSelectionMapScreen extends ConsumerStatefulWidget {
  const PointSelectionMapScreen({
    super.key,
    required this.mode,
    this.initialZoneId,
    this.scheduledDate,
    this.existingInjectionId,
  });

  final PointSelectionMode mode;
  final int? initialZoneId;
  final DateTime? scheduledDate;
  final int? existingInjectionId;

  @override
  ConsumerState<PointSelectionMapScreen> createState() =>
      _PointSelectionMapScreenState();
}

class _PointSelectionMapScreenState
    extends ConsumerState<PointSelectionMapScreen> {
  int? _selectedZoneId;
  int? _selectedPoint;
  final _reasonController = TextEditingController();
  late DateTime _scheduledDateTime;
  late TimeOfDay _scheduledTime;
  bool _userChangedTime = false;
  bool _usedFallbackPreferredTime = false;

  bool get _canConfirm => _selectedZoneId != null && _selectedPoint != null;

  @override
  void initState() {
    super.initState();
    _selectedZoneId = widget.initialZoneId;
    // Inizializza data/ora. Se arriva una "date-only" (00:00), applica l'orario di default.
    final base = widget.scheduledDate ?? DateTime.now();
    if (widget.scheduledDate == null || _isDateOnly(base)) {
      final fallback = TherapyPlan.defaults.preferredTime; // es. 20:00
      _scheduledDateTime = _combineDateWithPreferredTime(base, fallback);
      _scheduledTime = TimeOfDay.fromDateTime(_scheduledDateTime);
      _usedFallbackPreferredTime = true;
    } else {
      _scheduledDateTime = base;
      _scheduledTime = TimeOfDay.fromDateTime(_scheduledDateTime);
    }
    DiagnosticLogService.instance.logEvent('add-date', 'PointSelection init widget.scheduledDate=${widget.scheduledDate} -> _scheduledDateTime=$_scheduledDateTime');
  }

  bool _isDateOnly(DateTime dt) =>
      dt.hour == 0 &&
      dt.minute == 0 &&
      dt.second == 0 &&
      dt.millisecond == 0 &&
      dt.microsecond == 0;

  DateTime _combineDateWithPreferredTime(DateTime date, String preferredTime) {
    final parts = preferredTime.split(':');
    final hour = parts.length >= 2 ? int.tryParse(parts[0]) ?? 20 : 20;
    final minute = parts.length >= 2 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  void _applyPreferredTime(String preferredTime) {
    final nextDt = _combineDateWithPreferredTime(_scheduledDateTime, preferredTime);
    setState(() {
      _scheduledDateTime = nextDt;
      _scheduledTime = TimeOfDay.fromDateTime(nextDt);
      _usedFallbackPreferredTime = false;
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  /// Aggiorna l'orario schedulato
  void _updateScheduledTime(TimeOfDay newTime) {
    setState(() {
      _userChangedTime = true;
      _usedFallbackPreferredTime = false;
      _scheduledTime = newTime;
      _scheduledDateTime = DateTime(
        _scheduledDateTime.year,
        _scheduledDateTime.month,
        _scheduledDateTime.day,
        newTime.hour,
        newTime.minute,
      );
    });
  }

  Future<void> _showTimePickerDialog() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _updateScheduledTime(picked);
    }
  }

  /// Banner in cima al corpo che mostra la data/ora dell'iniezione.
  /// La data è sola lettura (dal "+" = oggi, dal calendario = giorno scelto);
  /// l'orario è modificabile col chip a destra.
  Widget _buildDateTimeBanner(ThemeData theme, bool isDark) {
    final now = DateTime.now();
    final isToday = _scheduledDateTime.year == now.year &&
        _scheduledDateTime.month == now.month &&
        _scheduledDateTime.day == now.day;
    final dateRaw = isToday
        ? 'Oggi, ${DateFormat('d MMMM', 'it_IT').format(_scheduledDateTime)}'
        : DateFormat('EEEE d MMMM', 'it_IT').format(_scheduledDateTime);
    final dateLabel =
        dateRaw.isEmpty ? dateRaw : '${dateRaw[0].toUpperCase()}${dateRaw.substring(1)}';
    final timeLabel = DateFormat('HH:mm', 'it_IT').format(_scheduledDateTime);
    final muted = isDark ? AppTokens.darkMuted : AppTokens.lightMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTokens.accentEnd.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(PhosphorIconsDuotone.calendarBlank, color: AppTokens.accentEnd),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data iniezione',
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
                Text(
                  dateLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ActionChip(
            avatar: const Icon(
              PhosphorIconsDuotone.clock,
              size: 18,
              color: AppTokens.accentEnd,
            ),
            label: Text(
              timeLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: _showTimePickerDialog,
          ),
        ],
      ),
    );
  }

  String get _title => switch (widget.mode) {
    PointSelectionMode.injection => 'Seleziona punto iniezione',
    PointSelectionMode.blacklist => 'Escludi un punto',
  };

  String get _actionLabel => switch (widget.mode) {
    PointSelectionMode.injection => 'Registra iniezione',
    PointSelectionMode.blacklist => 'Escludi questo punto',
  };

  IconData get _actionIcon => switch (widget.mode) {
    PointSelectionMode.injection => PhosphorIconsDuotone.plusCircle,
    PointSelectionMode.blacklist => PhosphorIconsDuotone.prohibit,
  };

  @override
  Widget build(BuildContext context) {
    // Se il piano terapeutico è configurato e diverso dal fallback, aggiorna (solo se utente non ha cambiato manualmente).
    ref.listen<AsyncValue<TherapyPlan?>>(
      therapyPlanProvider,
      (prev, next) {
        final preferred = next.asData?.value?.preferredTime;
        if (preferred == null) return;
        if (_userChangedTime) return;
        if (!_usedFallbackPreferredTime) return;
        _applyPreferredTime(preferred);
      },
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final zonesAsync = ref.watch(enabledZonesProvider);
    final mapAsync = ref.watch(bodyMapPointsProvider((
      scheduledAt: _scheduledDateTime,
      ignoreInjectionId: widget.existingInjectionId,
    )));

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        leading: IconButton(
          icon: const Icon(PhosphorIconsDuotone.x),
          onPressed: () => context.pop(),
        ),
      ),
      bottomNavigationBar:
          _buildStickyCta(zonesAsync.asData?.value ?? const <BodyZone>[], isDark),
      body: Column(
        children: [
          // Banner data/ora (solo injection): mostra QUANDO verrà salvata.
          if (widget.mode == PointSelectionMode.injection)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _buildDateTimeBanner(theme, isDark),
            ),
          // Mappa unica del corpo: tutti i punti di tutte le zone, colorati
          // per stato; un tap = zona+punto.
          Expanded(
            child: mapAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Errore: $e')),
              data: (points) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: BodyPointMap(
                  points: points,
                  selectedZoneId: _selectedZoneId,
                  selectedPointNumber: _selectedPoint,
                  onTap: (p) {
                    // I punti esclusi (grigi) non sono selezionabili.
                    if (p.isBlacklisted) return;
                    setState(() {
                      _selectedZoneId = p.zoneId;
                      _selectedPoint = p.pointNumber;
                    });
                  },
                ),
              ),
            ),
          ),
          // Motivo (blacklist): solo dopo aver scelto il punto.
          if (widget.mode == PointSelectionMode.blacklist &&
              _selectedPoint != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: 'Motivo (opzionale)',
                  hintText: 'Es: cicatrice, reazione, difficile da raggiungere',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor:
                      isDark ? AppTokens.darkSurface : AppTokens.lightSurface,
                ),
                maxLines: 2,
              ),
            ),
          _buildLegend(isDark),
        ],
      ),
    );
  }

  /// Legenda sempre visibile dei colori di stato dei punti.
  Widget _buildLegend(bool isDark) {
    Widget item(Color c, String t) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(t, style: const TextStyle(fontSize: 11)),
          ],
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 14,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: [
          item(isDark ? AppTokens.successDark : AppTokens.successLight,
              'disponibile'),
          item(isDark ? AppTokens.warnDark : AppTokens.warnLight, 'recente'),
          item(isDark ? AppTokens.dangerDark : AppTokens.dangerLight, 'evita'),
          item(isDark ? AppTokens.darkMuted : AppTokens.lightMuted, 'escluso'),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('◯ ', style: TextStyle(color: AppTokens.accent)),
              Text('consigliato', style: TextStyle(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  /// Barra d'azione fissa in basso con recap + pulsante primario.
  Widget _buildStickyCta(List<BodyZone> zones, bool isDark) {
    final muted = isDark ? AppTokens.darkMuted : AppTokens.lightMuted;
    final zone = _selectedZoneId == null
        ? null
        : zones.where((z) => z.id == _selectedZoneId).firstOrNull;
    final pointLabel = (zone != null && _selectedPoint != null)
        ? zone.pointLabel(_selectedPoint!)
        : null;
    final recap = pointLabel == null
        ? 'Seleziona zona e punto'
        : (widget.mode == PointSelectionMode.injection
            ? '$pointLabel · ${DateFormat('EEE d MMM · HH:mm', 'it_IT').format(_scheduledDateTime)}'
            : pointLabel);
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: isDark ? AppTokens.darkSurface : AppTokens.lightSurface,
          border: Border(
            top: BorderSide(
              color: isDark ? AppTokens.darkBorder : AppTokens.lightBorder,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              recap,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _canConfirm ? null : muted,
                  ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _canConfirm ? () => _performAction(zones) : null,
                icon: Icon(_actionIcon),
                label: Text(_actionLabel),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: widget.mode == PointSelectionMode.blacklist
                      ? (isDark ? AppTokens.dangerDark : AppTokens.dangerLight)
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performAction(List<BodyZone> zones) async {
    if (_selectedZoneId == null || _selectedPoint == null) return;

    final zone = zones.firstWhere((z) => z.id == _selectedZoneId);

    if (widget.mode == PointSelectionMode.injection) {
      DiagnosticLogService.instance.logEvent('add-date', 'PointSelection save scheduledAt=$_scheduledDateTime');
      // Navigate to record screen with selected point and updated datetime
      context.push(
        '/record',
        extra: {
          'zoneId': _selectedZoneId,
          'pointNumber': _selectedPoint,
          'scheduledDate': _scheduledDateTime, // Usa la data/ora aggiornata
          if (widget.existingInjectionId != null) 'existingInjectionId': widget.existingInjectionId,
        },
      );
    } else {
      // Blacklist the point
      final reason = _reasonController.text.isNotEmpty
          ? _reasonController.text
          : 'Non specificato';

      final actions = ref.read(zoneActionsProvider);
      await actions.blacklistPoint(
        pointCode: zone.pointCode(_selectedPoint!),
        pointLabel: zone.pointLabel(_selectedPoint!),
        zoneId: zone.id,
        pointNumber: _selectedPoint!,
        reason: reason,
      );

      ref.invalidate(blacklistedPointsProvider);

      if (mounted) {
        final label = zone.pointLabel(_selectedPoint!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Punto $label escluso'),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? AppTokens.accent
                : AppTokens.accent,
          ),
        );
        context.pop();
      }
    }
  }
}
