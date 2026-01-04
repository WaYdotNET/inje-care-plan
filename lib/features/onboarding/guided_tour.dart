import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';

/// Step del tour guidato
class TourStep {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final IconData? icon;
  final TooltipPosition position;

  const TourStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.icon,
    this.position = TooltipPosition.bottom,
  });
}

enum TooltipPosition { top, bottom, left, right }

/// Controller per il tour guidato
class GuidedTourController extends ChangeNotifier {
  static const String _completedKey = 'guided_tour_completed';

  List<TourStep> _steps = [];
  int _currentStep = 0;
  bool _isActive = false;
  OverlayEntry? _overlayEntry;

  bool get isActive => _isActive;
  int get currentStep => _currentStep;
  int get totalSteps => _steps.length;
  TourStep? get currentTourStep => _isActive && _currentStep < _steps.length
      ? _steps[_currentStep]
      : null;

  /// Avvia il tour
  Future<void> startTour(BuildContext context, List<TourStep> steps) async {
    if (steps.isEmpty) return;

    _steps = steps;
    _currentStep = 0;
    _isActive = true;
    notifyListeners();

    _showOverlay(context);
  }

  /// Verifica se il tour è già stato completato
  static Future<bool> hasCompletedTour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }

  /// Segna il tour come completato
  static Future<void> markTourCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
  }

  /// Reset del tour (per testing)
  static Future<void> resetTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_completedKey);
  }

  void _showOverlay(BuildContext context) {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => _TourOverlay(
        controller: this,
        onNext: () => _nextStep(context),
        onSkip: _skipTour,
        onComplete: _completeTour,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _nextStep(BuildContext context) {
    if (_currentStep < _steps.length - 1) {
      _currentStep++;
      notifyListeners();
      _removeOverlay();
      _showOverlay(context);
    } else {
      _completeTour();
    }
  }

  void _skipTour() {
    _isActive = false;
    _removeOverlay();
    notifyListeners();
  }

  void _completeTour() async {
    _isActive = false;
    _removeOverlay();
    await markTourCompleted();
    notifyListeners();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }
}

/// Overlay del tour
class _TourOverlay extends StatelessWidget {
  const _TourOverlay({
    required this.controller,
    required this.onNext,
    required this.onSkip,
    required this.onComplete,
  });

  final GuidedTourController controller;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final step = controller.currentTourStep;
    if (step == null) return const SizedBox.shrink();

    // Trova la posizione del target
    final renderBox = step.targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return const SizedBox.shrink();

    final targetPosition = renderBox.localToGlobal(Offset.zero);
    final targetSize = renderBox.size;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Background scuro con spotlight
        _SpotlightBackground(
          targetPosition: targetPosition,
          targetSize: targetSize,
        ),

        // Tooltip
        _TourTooltip(
          step: step,
          targetPosition: targetPosition,
          targetSize: targetSize,
          currentStep: controller.currentStep,
          totalSteps: controller.totalSteps,
          onNext: onNext,
          onSkip: onSkip,
          onComplete: onComplete,
          isDark: isDark,
        ),
      ],
    );
  }
}

/// Background con effetto spotlight
class _SpotlightBackground extends StatelessWidget {
  const _SpotlightBackground({
    required this.targetPosition,
    required this.targetSize,
  });

  final Offset targetPosition;
  final Size targetSize;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SpotlightPainter(
        targetPosition: targetPosition,
        targetSize: targetSize,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Offset targetPosition;
  final Size targetSize;

  _SpotlightPainter({
    required this.targetPosition,
    required this.targetSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background scuro
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7);

    // Rettangolo spotlight con padding
    const padding = 8.0;
    final spotlightRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        targetPosition.dx - padding,
        targetPosition.dy - padding,
        targetSize.width + padding * 2,
        targetSize.height + padding * 2,
      ),
      const Radius.circular(8),
    );

    // Disegna background con buco per spotlight
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(spotlightRect),
      ),
      backgroundPaint,
    );

    // Bordo spotlight
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(spotlightRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Tooltip del tour
class _TourTooltip extends StatelessWidget {
  const _TourTooltip({
    required this.step,
    required this.targetPosition,
    required this.targetSize,
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onSkip,
    required this.onComplete,
    required this.isDark,
  });

  final TourStep step;
  final Offset targetPosition;
  final Size targetSize;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onComplete;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calcola posizione tooltip
    double top = targetPosition.dy + targetSize.height + 20;
    double left = targetPosition.dx;

    // Se il tooltip va oltre lo schermo in basso, posizionalo sopra
    if (top + 200 > screenHeight) {
      top = targetPosition.dy - 200;
    }

    // Centra orizzontalmente se possibile
    if (left + 300 > screenWidth) {
      left = screenWidth - 320;
    }
    if (left < 20) left = 20;

    final isLastStep = currentStep == totalSteps - 1;

    return Positioned(
      top: top,
      left: left,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  if (step.icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkPine.withValues(alpha: 0.2)
                            : AppColors.dawnPine.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        step.icon,
                        size: 24,
                        color: isDark ? AppColors.darkPine : AppColors.dawnPine,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      step.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                step.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                ),
              ),

              const SizedBox(height: 20),

              // Progress indicator
              Row(
                children: List.generate(totalSteps, (index) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == currentStep
                          ? (isDark ? AppColors.darkPine : AppColors.dawnPine)
                          : (isDark ? AppColors.darkMuted : AppColors.dawnMuted)
                              .withValues(alpha: 0.3),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: onSkip,
                    child: Text(
                      'Salta',
                      style: TextStyle(
                        color: isDark ? AppColors.darkMuted : AppColors.dawnMuted,
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: isLastStep ? onComplete : onNext,
                    child: Text(isLastStep ? 'Fine' : 'Avanti'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tooltip contestuale (usabile ovunque)
class ContextualTooltip extends StatefulWidget {
  const ContextualTooltip({
    super.key,
    required this.message,
    required this.child,
    this.preferredDirection = TooltipPosition.bottom,
    this.showOnFirstView = true,
    this.storageKey,
  });

  final String message;
  final Widget child;
  final TooltipPosition preferredDirection;
  final bool showOnFirstView;
  final String? storageKey;

  @override
  State<ContextualTooltip> createState() => _ContextualTooltipState();
}

class _ContextualTooltipState extends State<ContextualTooltip> {
  bool _hasShown = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    if (widget.showOnFirstView && widget.storageKey != null) {
      _checkAndShow();
    }
  }

  Future<void> _checkAndShow() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'tooltip_${widget.storageKey}';
    final hasShown = prefs.getBool(key) ?? false;

    if (!hasShown && mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _showTooltip();
        await prefs.setBool(key, true);
      }
    }
  }

  void _showTooltip() {
    if (_hasShown) return;
    _hasShown = true;

    _overlayEntry = OverlayEntry(
      builder: (context) => _TooltipBubble(
        message: widget.message,
        onDismiss: _hideTooltip,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    // Auto-hide after 5 seconds
    Future.delayed(const Duration(seconds: 5), () => _hideTooltip());
  }

  void _hideTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hideTooltip();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _TooltipBubble extends StatelessWidget {
  const _TooltipBubble({
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: onDismiss,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.yellow, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                const Icon(Icons.close, color: Colors.white54, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
