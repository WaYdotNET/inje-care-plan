import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/database/app_database.dart' as db;

/// Rappresenta un punto posizionato sulla silhouette
class PositionedPoint {
  final int pointNumber;
  final String? customName;
  final double x; // 0.0 - 1.0 normalized
  final double y; // 0.0 - 1.0 normalized

  const PositionedPoint({
    required this.pointNumber,
    this.customName,
    required this.x,
    required this.y,
  });

  PositionedPoint copyWith({
    int? pointNumber,
    String? customName,
    double? x,
    double? y,
  }) =>
      PositionedPoint(
        pointNumber: pointNumber ?? this.pointNumber,
        customName: customName ?? this.customName,
        x: x ?? this.x,
        y: y ?? this.y,
      );
}

/// Vista del corpo (frontale o posteriore)
enum BodyView { front, back }

/// Editor visuale per posizionare punti di iniezione sulla silhouette del corpo
class BodySilhouetteEditor extends StatefulWidget {
  const BodySilhouetteEditor({
    super.key,
    required this.points,
    required this.onPointMoved,
    required this.onPointTapped,
    this.selectedPointNumber,
    this.initialView = BodyView.front,
    this.editable = true,
    this.zoneType,
  });

  /// Lista dei punti posizionati
  final List<PositionedPoint> points;

  /// Callback quando un punto viene spostato
  final void Function(int pointNumber, double x, double y, BodyView view)
      onPointMoved;

  /// Callback quando un punto viene toccato
  final void Function(int pointNumber) onPointTapped;

  /// Numero del punto selezionato
  final int? selectedPointNumber;

  /// Vista iniziale
  final BodyView initialView;

  /// Se l'editor è modificabile (drag-and-drop abilitato)
  final bool editable;

  /// Tipo di zona per evidenziare l'area appropriata
  final String? zoneType;

  @override
  State<BodySilhouetteEditor> createState() => _BodySilhouetteEditorState();
}

class _BodySilhouetteEditorState extends State<BodySilhouetteEditor> {
  late BodyView _currentView;
  int? _draggingPoint;

  @override
  void initState() {
    super.initState();
    _currentView = widget.initialView;
  }

  String get _svgAsset => _currentView == BodyView.front
      ? 'assets/images/body_silhouette_front.svg'
      : 'assets/images/body_silhouette_back.svg';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isDark ? AppColors.darkFoam : AppColors.dawnFoam;

    return LayoutBuilder(
      builder: (context, outerConstraints) {
        // Calcola altezza disponibile per la silhouette
        const toggleHeight = 48.0; // SegmentedButton height
        const spacing = 16.0;
        final silhouetteHeight = outerConstraints.maxHeight - toggleHeight - spacing;
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // View toggle
            SegmentedButton<BodyView>(
              segments: const [
                ButtonSegment(
                  value: BodyView.front,
                  label: Text('Fronte'),
                  icon: Icon(Icons.person),
                ),
                ButtonSegment(
                  value: BodyView.back,
                  label: Text('Retro'),
                  icon: Icon(Icons.person_outline),
                ),
              ],
              selected: {_currentView},
              onSelectionChanged: (selection) {
                setState(() => _currentView = selection.first);
              },
            ),
            const SizedBox(height: spacing),

            // Silhouette with draggable points - constrained to available space
            SizedBox(
              height: silhouetteHeight > 0 ? silhouetteHeight : 300,
              child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // SVG background - fit within available space
                  Positioned.fill(
                    child: SvgPicture.asset(
                      _svgAsset,
                      fit: BoxFit.contain,
                      colorFilter: ColorFilter.mode(
                        color.withValues(alpha: 0.5),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),

                  // Highlight zone area based on type
                  if (widget.zoneType != null)
                    _buildZoneHighlight(constraints, isDark),

                  // Draggable points
                  ...widget.points.map((point) {
                    final isSelected =
                        point.pointNumber == widget.selectedPointNumber;
                    final isDragging = point.pointNumber == _draggingPoint;

                    return Positioned(
                      left: point.x * constraints.maxWidth - 16,
                      top: point.y * constraints.maxHeight - 16,
                      child: GestureDetector(
                        onTap: () => widget.onPointTapped(point.pointNumber),
                        onPanStart: widget.editable
                            ? (_) =>
                                setState(() => _draggingPoint = point.pointNumber)
                            : null,
                        onPanUpdate: widget.editable
                            ? (details) {
                                final newX = (point.x * constraints.maxWidth +
                                        details.delta.dx) /
                                    constraints.maxWidth;
                                final newY = (point.y * constraints.maxHeight +
                                        details.delta.dy) /
                                    constraints.maxHeight;
                                widget.onPointMoved(
                                  point.pointNumber,
                                  newX.clamp(0.05, 0.95),
                                  newY.clamp(0.05, 0.95),
                                  _currentView,
                                );
                              }
                            : null,
                        onPanEnd: widget.editable
                            ? (_) => setState(() => _draggingPoint = null)
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: isSelected || isDragging ? 36 : 32,
                          height: isSelected || isDragging ? 36 : 32,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                    ? AppColors.darkPine
                                    : AppColors.dawnPine)
                                : (isDark
                                    ? AppColors.darkFoam
                                    : AppColors.dawnFoam),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBase
                                  : AppColors.dawnBase,
                              width: 2,
                            ),
                            boxShadow: isDragging
                                ? [
                                    BoxShadow(
                                      color: (isDark
                                              ? AppColors.darkPine
                                              : AppColors.dawnPine)
                                          .withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '${point.pointNumber}',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkBase
                                    : AppColors.dawnBase,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  // Tap to add point hint (only in edit mode)
                  if (widget.editable && widget.points.isEmpty)
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: (isDark
                                    ? AppColors.darkSurface
                                    : AppColors.dawnSurface)
                                .withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Trascina i punti per posizionarli',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
          ],
        );
      },
    );
  }

  Widget _buildZoneHighlight(BoxConstraints constraints, bool isDark) {
    // Posizioni predefinite per ogni tipo di zona
    final zoneAreas = <String, ({double x, double y, double w, double h})>{
      'thigh': (x: 0.25, y: 0.55, w: 0.5, h: 0.2),
      'arm': (x: 0.1, y: 0.22, w: 0.8, h: 0.15),
      'abdomen': (x: 0.3, y: 0.32, w: 0.4, h: 0.15),
      'buttock': (x: 0.3, y: 0.5, w: 0.4, h: 0.12),
    };

    final area = zoneAreas[widget.zoneType];
    if (area == null) return const SizedBox();

    return Positioned(
      left: area.x * constraints.maxWidth,
      top: area.y * constraints.maxHeight,
      width: area.w * constraints.maxWidth,
      height: area.h * constraints.maxHeight,
      child: Container(
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkPine : AppColors.dawnPine)
              .withValues(alpha: 0.1),
          border: Border.all(
            color: (isDark ? AppColors.darkPine : AppColors.dawnPine)
                .withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Widget per modificare il nome di un singolo punto
class PointNameEditor extends StatefulWidget {
  const PointNameEditor({
    super.key,
    required this.pointNumber,
    required this.currentName,
    required this.onNameChanged,
  });

  final int pointNumber;
  final String currentName;
  final void Function(String name) onNameChanged;

  @override
  State<PointNameEditor> createState() => _PointNameEditorState();
}

class _PointNameEditorState extends State<PointNameEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void didUpdateWidget(PointNameEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentName != widget.currentName) {
      _controller.text = widget.currentName;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: 'Nome punto ${widget.pointNumber}',
        hintText: 'Es: Alto esterno',
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: widget.onNameChanged,
    );
  }
}

/// Helper per convertire PointConfig dal database a PositionedPoint
extension PointConfigToPositionedPoint on db.PointConfig {
  PositionedPoint toPositionedPoint() => PositionedPoint(
        pointNumber: pointNumber,
        customName: customName.isNotEmpty ? customName : null,
        x: positionX,
        y: positionY,
      );
}

/// Helper per generare posizioni predefinite per i punti in base al tipo di zona
List<PositionedPoint> generateDefaultPointPositions(
  int numberOfPoints,
  String zoneType,
  String side,
) {
  // Posizioni di base per ogni tipo di zona
  final basePositions = <String, ({double x, double y, double spacing})>{
    'thigh': (x: 0.35, y: 0.58, spacing: 0.08),
    'arm': (x: 0.2, y: 0.25, spacing: 0.06),
    'abdomen': (x: 0.4, y: 0.35, spacing: 0.07),
    'buttock': (x: 0.4, y: 0.52, spacing: 0.06),
  };

  final base = basePositions[zoneType] ?? (x: 0.5, y: 0.5, spacing: 0.08);

  // Offset per lato sinistro/destro
  final xOffset = side == 'left' ? -0.15 : (side == 'right' ? 0.15 : 0);

  final points = <PositionedPoint>[];
  final cols = (numberOfPoints / 2).ceil();

  for (var i = 0; i < numberOfPoints; i++) {
    final row = i ~/ cols;
    final col = i % cols;

    points.add(PositionedPoint(
      pointNumber: i + 1,
      x: (base.x + xOffset + col * base.spacing).clamp(0.1, 0.9),
      y: (base.y + row * base.spacing).clamp(0.1, 0.9),
    ));
  }

  return points;
}
