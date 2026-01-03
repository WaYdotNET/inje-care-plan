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

class _BodySilhouetteEditorState extends State<BodySilhouetteEditor>
    with SingleTickerProviderStateMixin {
  late BodyView _currentView;
  int? _draggingPoint;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _currentView = widget.initialView;
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String get _svgAsset => _currentView == BodyView.front
      ? 'assets/images/body_silhouette_front.svg'
      : 'assets/images/body_silhouette_back.svg';

  /// Restituisce l'etichetta da mostrare nel punto: nome personalizzato o numero
  String _getPointLabel(PositionedPoint point) {
    if (point.customName != null && point.customName!.isNotEmpty) {
      // Limita a 3 caratteri per stare nel cerchio
      return point.customName!.length > 3
          ? point.customName!.substring(0, 3)
          : point.customName!;
    }
    return '${point.pointNumber}';
  }

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
                        color.withValues(alpha: 0.7),
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
                    
                    // Colori per i pallini
                    final primaryColor = isDark
                        ? AppColors.darkPine
                        : AppColors.dawnPine;
                    final secondaryColor = isDark
                        ? AppColors.darkFoam
                        : AppColors.dawnFoam;
                    final textColor = isDark
                        ? AppColors.darkBase
                        : AppColors.dawnBase;

                    return AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        final scale = isSelected && !widget.editable
                            ? _pulseAnimation.value
                            : 1.0;
                        
                        return Positioned(
                          left: point.x * constraints.maxWidth - 20,
                          top: point.y * constraints.maxHeight - 20,
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
                            child: Transform.scale(
                              scale: scale,
                              child: Container(
                                width: isSelected || isDragging ? 44 : 40,
                                height: isSelected || isDragging ? 44 : 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isSelected
                                        ? [
                                            primaryColor,
                                            primaryColor.withValues(alpha: 0.8),
                                          ]
                                        : [
                                            secondaryColor,
                                            secondaryColor.withValues(alpha: 0.7),
                                          ],
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : textColor.withValues(alpha: 0.5),
                                    width: isSelected ? 3 : 2,
                                  ),
                                  boxShadow: [
                                    // Ombra esterna principale
                                    BoxShadow(
                                      color: isSelected
                                          ? primaryColor.withValues(alpha: 0.5)
                                          : Colors.black.withValues(alpha: 0.2),
                                      blurRadius: isSelected || isDragging ? 12 : 6,
                                      spreadRadius: isSelected || isDragging ? 2 : 1,
                                      offset: const Offset(0, 2),
                                    ),
                                    // Glow interno per effetto 3D
                                    if (isSelected)
                                      BoxShadow(
                                        color: Colors.white.withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        spreadRadius: -2,
                                        offset: const Offset(-2, -2),
                                      ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _getPointLabel(point),
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: point.customName != null && 
                                              point.customName!.isNotEmpty
                                          ? 12
                                          : 14,
                                      shadows: isSelected
                                          ? [
                                              Shadow(
                                                color: Colors.black.withValues(alpha: 0.3),
                                                blurRadius: 2,
                                                offset: const Offset(0, 1),
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
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
      'thigh': (x: 0.22, y: 0.52, w: 0.56, h: 0.25),
      'arm': (x: 0.08, y: 0.20, w: 0.84, h: 0.18),
      'abdomen': (x: 0.28, y: 0.30, w: 0.44, h: 0.18),
      'buttock': (x: 0.28, y: 0.48, w: 0.44, h: 0.15),
    };

    final area = zoneAreas[widget.zoneType];
    if (area == null) return const SizedBox();

    final highlightColor = isDark ? AppColors.darkPine : AppColors.dawnPine;

    return Positioned(
      left: area.x * constraints.maxWidth,
      top: area.y * constraints.maxHeight,
      width: area.w * constraints.maxWidth,
      height: area.h * constraints.maxHeight,
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              highlightColor.withValues(alpha: 0.15),
              highlightColor.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(
            color: highlightColor.withValues(alpha: 0.4),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: highlightColor.withValues(alpha: 0.2),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget per modificare il nome di un singolo punto (max 3 caratteri, univoco)
class PointNameEditor extends StatefulWidget {
  const PointNameEditor({
    super.key,
    required this.pointNumber,
    required this.currentName,
    required this.onNameChanged,
    this.existingNames = const [],
  });

  final int pointNumber;
  final String currentName;
  final void Function(String name) onNameChanged;
  /// Lista di nomi già usati da altri punti (per validazione unicità)
  final List<String> existingNames;

  @override
  State<PointNameEditor> createState() => _PointNameEditorState();
}

class _PointNameEditorState extends State<PointNameEditor> {
  late final TextEditingController _controller;
  String? _errorText;

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

  void _validateAndUpdate(String value) {
    // Limita a 3 caratteri e uppercase
    final trimmed = value.toUpperCase().substring(0, value.length > 3 ? 3 : value.length);

    // Controlla unicità (ignora se vuoto o uguale al nome corrente)
    if (trimmed.isNotEmpty &&
        trimmed != widget.currentName.toUpperCase() &&
        widget.existingNames.map((n) => n.toUpperCase()).contains(trimmed)) {
      setState(() => _errorText = 'Nome già usato');
    } else {
      setState(() => _errorText = null);
      widget.onNameChanged(trimmed);
    }

    // Aggiorna il controller se il testo è stato troncato
    if (trimmed != value) {
      _controller.text = trimmed;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: trimmed.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLength: 3,
      textCapitalization: TextCapitalization.characters,
      decoration: InputDecoration(
        labelText: 'Codice punto ${widget.pointNumber}',
        hintText: 'Es: CD1',
        helperText: 'Max 3 caratteri, univoco',
        errorText: _errorText,
        border: const OutlineInputBorder(),
        isDense: true,
        counterText: '', // Nasconde il contatore
      ),
      onChanged: _validateAndUpdate,
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
