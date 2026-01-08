import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/point_constants.dart';

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
    this.onDragEnd,
    this.selectedPointNumber,
    this.initialView = BodyView.front,
    this.editable = true,
    this.zoneType,
    this.showGrid = false,
    this.currentView,
    this.onViewChanged,
    this.enableZoom = false,
    this.pointScale = 1.0,
  });

  /// Lista dei punti posizionati
  final List<PositionedPoint> points;

  /// Callback quando un punto viene spostato
  final void Function(int pointNumber, double x, double y, BodyView view)
      onPointMoved;

  /// Callback quando un punto viene toccato
  final void Function(int pointNumber) onPointTapped;

  /// Callback quando il drag termina
  final VoidCallback? onDragEnd;

  /// Numero del punto selezionato
  final int? selectedPointNumber;

  /// Vista iniziale
  final BodyView initialView;

  /// Se l'editor è modificabile (drag-and-drop abilitato)
  final bool editable;

  /// Tipo di zona per evidenziare l'area appropriata
  final String? zoneType;

  /// Mostra la griglia di riferimento
  final bool showGrid;

  /// Vista corrente (controllata esternamente)
  final BodyView? currentView;

  /// Callback quando la vista cambia
  final void Function(BodyView)? onViewChanged;

  /// Abilita zoom e pan con InteractiveViewer
  final bool enableZoom;

  /// Scala per i punti (0.5 = metà dimensione, 1.0 = normale)
  final double pointScale;

  @override
  State<BodySilhouetteEditor> createState() => _BodySilhouetteEditorState();
}

class _BodySilhouetteEditorState extends State<BodySilhouetteEditor>
    with SingleTickerProviderStateMixin {
  late BodyView _internalView;
  int? _draggingPoint;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final TransformationController _transformationController =
      TransformationController();

  // Per ottimizzare il drag: posizione locale durante il trascinamento
  Offset? _dragOffset;
  DateTime? _lastDragUpdate;
  static const _dragThrottleMs = 16; // ~60fps

  BodyView get _currentView => widget.currentView ?? _internalView;

  @override
  void initState() {
    super.initState();
    _internalView = widget.initialView;
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
    _transformationController.dispose();
    super.dispose();
  }

  String get _svgAsset => _currentView == BodyView.front
      ? 'assets/images/body_silhouette_front.svg'
      : 'assets/images/body_silhouette_back.svg';

  /// Restituisce l'etichetta da mostrare nel punto: nome personalizzato o numero
  String _getPointLabel(PositionedPoint point) {
    if (point.customName != null && point.customName!.isNotEmpty) {
      return point.customName!.length > 3
          ? point.customName!.substring(0, 3)
          : point.customName!;
    }
    return '${point.pointNumber}';
  }

  void _setView(BodyView view) {
    if (widget.onViewChanged != null) {
      widget.onViewChanged!(view);
    } else {
      setState(() => _internalView = view);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isDark ? AppColors.darkFoam : AppColors.dawnFoam;

    // Se la vista è controllata esternamente, non mostrare il toggle
    final showViewToggle = widget.onViewChanged == null;

    return LayoutBuilder(
      builder: (context, outerConstraints) {
        final toggleHeight = showViewToggle ? 48.0 : 0.0;
        final spacing = showViewToggle ? 16.0 : 0.0;
        final silhouetteHeight =
            outerConstraints.maxHeight - toggleHeight - spacing;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // View toggle (solo se non controllato esternamente)
            if (showViewToggle)
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
                onSelectionChanged: (selection) => _setView(selection.first),
              ),
            if (showViewToggle) const SizedBox(height: 16),

            // Silhouette with draggable points
            Expanded(
              child: SizedBox(
                height: silhouetteHeight > 0 ? silhouetteHeight : 300,
                child: widget.enableZoom
                    ? InteractiveViewer(
                        transformationController: _transformationController,
                        minScale: 1.0,
                        maxScale: 3.0,
                        boundaryMargin: const EdgeInsets.all(80),
                        child: _buildSilhouetteStack(color, isDark),
                      )
                    : _buildSilhouetteStack(color, isDark),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSilhouetteStack(Color color, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Griglia di riferimento (opzionale)
            if (widget.showGrid) _buildGrid(constraints, isDark),

            // SVG background
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

            // Highlight zone area (only in edit mode)
            if (widget.zoneType != null && widget.editable)
              _buildZoneHighlight(constraints, isDark),

            // Draggable points
            ...widget.points.map((point) => _buildDraggablePoint(
                  point,
                  constraints,
                  isDark,
                )),

            // Empty hint
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
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildGrid(BoxConstraints constraints, bool isDark) {
    final gridColor = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1);
    const divisions = 10;

    return CustomPaint(
      size: Size(constraints.maxWidth, constraints.maxHeight),
      painter: _GridPainter(
        color: gridColor,
        divisions: divisions,
      ),
    );
  }

  Widget _buildDraggablePoint(
    PositionedPoint point,
    BoxConstraints constraints,
    bool isDark,
  ) {
    final isSelected = point.pointNumber == widget.selectedPointNumber;
    final isDragging = point.pointNumber == _draggingPoint;

    final primaryColor = isDark ? AppColors.darkPine : AppColors.dawnPine;
    final secondaryColor = isDark ? AppColors.darkFoam : AppColors.dawnFoam;
    final textColor = isDark ? AppColors.darkBase : AppColors.dawnBase;

    // Calcola posizione: usa offset locale durante drag per fluidità
    double effectiveX = point.x;
    double effectiveY = point.y;
    if (isDragging && _dragOffset != null) {
      effectiveX = (_dragOffset!.dx / constraints.maxWidth).clamp(0.05, 0.95);
      effectiveY = (_dragOffset!.dy / constraints.maxHeight).clamp(0.05, 0.95);
    }

    // Dimensione punto con area di hit estesa per migliore UX
    // Usa pointScale per adattare alle dimensioni della silhouette
    final pointSize = 40.0 * widget.pointScale;
    final hitAreaSize = 56.0 * widget.pointScale;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale =
            isSelected && !widget.editable ? _pulseAnimation.value : 1.0;

        return Positioned(
          left: effectiveX * constraints.maxWidth - hitAreaSize / 2,
          top: effectiveY * constraints.maxHeight - hitAreaSize / 2,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onPointTapped(point.pointNumber),
            onPanStart: widget.editable
                ? (details) {
                    setState(() {
                      _draggingPoint = point.pointNumber;
                      _dragOffset = Offset(
                        point.x * constraints.maxWidth,
                        point.y * constraints.maxHeight,
                      );
                    });
                  }
                : null,
            onPanUpdate: widget.editable
                ? (details) {
                    // Throttle updates per performance
                    final now = DateTime.now();
                    if (_lastDragUpdate != null &&
                        now.difference(_lastDragUpdate!).inMilliseconds < _dragThrottleMs) {
                      // Aggiorna solo offset locale senza rebuild
                      _dragOffset = Offset(
                        (_dragOffset?.dx ?? 0) + details.delta.dx,
                        (_dragOffset?.dy ?? 0) + details.delta.dy,
                      );
                      return;
                    }
                    _lastDragUpdate = now;

                    final newOffset = Offset(
                      (_dragOffset?.dx ?? point.x * constraints.maxWidth) + details.delta.dx,
                      (_dragOffset?.dy ?? point.y * constraints.maxHeight) + details.delta.dy,
                    );
                    setState(() => _dragOffset = newOffset);

                    // Notifica posizione al parent (throttled)
                    widget.onPointMoved(
                      point.pointNumber,
                      (newOffset.dx / constraints.maxWidth).clamp(0.05, 0.95),
                      (newOffset.dy / constraints.maxHeight).clamp(0.05, 0.95),
                      _currentView,
                    );
                  }
                : null,
            onPanEnd: widget.editable
                ? (_) {
                    // Commit finale della posizione
                    if (_dragOffset != null) {
                      widget.onPointMoved(
                        point.pointNumber,
                        (_dragOffset!.dx / constraints.maxWidth).clamp(0.05, 0.95),
                        (_dragOffset!.dy / constraints.maxHeight).clamp(0.05, 0.95),
                        _currentView,
                      );
                    }
                    setState(() {
                      _draggingPoint = null;
                      _dragOffset = null;
                      _lastDragUpdate = null;
                    });
                    widget.onDragEnd?.call();
                  }
                : null,
            // Container esteso per hit area maggiore
            child: SizedBox(
              width: hitAreaSize,
              height: hitAreaSize,
              child: Center(
                child: Transform.scale(
                  scale: isDragging ? 1.1 : scale,
                  child: Container(
                    width: isSelected || isDragging ? 48 * widget.pointScale : pointSize,
                    height: isSelected || isDragging ? 48 * widget.pointScale : pointSize,
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
                            ? Colors.white.withValues(alpha: 0.9)
                            : textColor.withValues(alpha: 0.5),
                        width: isSelected ? 3 : 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? primaryColor.withValues(alpha: 0.5)
                              : Colors.black.withValues(alpha: 0.2),
                          blurRadius: isSelected || isDragging ? 16 : 8,
                          spreadRadius: isSelected || isDragging ? 3 : 1,
                          offset: const Offset(0, 2),
                        ),
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
                          color: isSelected ? Colors.white : textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: (point.customName != null &&
                                  point.customName!.isNotEmpty
                              ? 12
                              : 14) * widget.pointScale,
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildZoneHighlight(BoxConstraints constraints, bool isDark) {
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

/// Painter per la griglia di riferimento
class _GridPainter extends CustomPainter {
  _GridPainter({
    required this.color,
    required this.divisions,
  });

  final Color color;
  final int divisions;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    // Linee verticali
    for (var i = 0; i <= divisions; i++) {
      final x = size.width * i / divisions;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Linee orizzontali
    for (var i = 0; i <= divisions; i++) {
      final y = size.height * i / divisions;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Linee centrali più evidenti
    final centerPaint = Paint()
      ..color = color.withValues(alpha: (color.a * 2).clamp(0, 1))
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      centerPaint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) =>
      color != oldDelegate.color || divisions != oldDelegate.divisions;
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
    final trimmed = value.toUpperCase().substring(
          0,
          value.length > 3 ? 3 : value.length,
        );

    if (trimmed.isNotEmpty &&
        trimmed != widget.currentName.toUpperCase() &&
        widget.existingNames.map((n) => n.toUpperCase()).contains(trimmed)) {
      setState(() => _errorText = 'Nome già usato');
    } else {
      setState(() => _errorText = null);
      widget.onNameChanged(trimmed);
    }

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
        counterText: '',
        prefixIcon: const Icon(Icons.label_outline),
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
/// Coordinate calibrate secondo l'immagine posizione_punti.png
List<PositionedPoint> generateDefaultPointPositions(
  int numberOfPoints,
  String zoneType,
  String side,
) {
  // Mappa zoneType + side -> zoneCode
  final typeMap = {
    'thigh': 'C',
    'arm': 'B',
    'abdomen': 'A',
    'buttock': 'G',
  };

  final sideMap = {
    'right': 'D',
    'left': 'S',
  };

  final prefix = typeMap[zoneType];
  final suffix = sideMap[side];

  if (prefix != null && suffix != null) {
    final code = '$prefix$suffix';
    final defaultPoints = BodyZonePoints.defaultPoints[code];

    if (defaultPoints != null) {
      return defaultPoints
          .take(numberOfPoints)
          .map((p) => PositionedPoint(
                pointNumber: defaultPoints.indexOf(p) + 1,
                x: p.x,
                y: p.y,
              ))
          .toList();
    }
  }

  // Fallback generico per zone personalizzate se non trovate nelle costanti
  final baseX = side == 'left' ? 0.3 : (side == 'right' ? 0.6 : 0.45);
  final points = <PositionedPoint>[];
  final cols = (numberOfPoints / 2).ceil();
  const spacing = 0.08;

  for (var i = 0; i < numberOfPoints; i++) {
    final row = i ~/ cols;
    final col = i % cols;
    points.add(PositionedPoint(
      pointNumber: i + 1,
      x: (baseX + col * spacing).clamp(0.1, 0.9),
      y: (0.4 + row * spacing).clamp(0.1, 0.9),
    ));
  }
  return points;
}
