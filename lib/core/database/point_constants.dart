class BodyPoint {
  final double x;
  final double y;

  const BodyPoint(this.x, this.y);
}

class BodyZonePoints {
  // Coordinate normalizzate (0..1) sulla silhouette CC0 (viewBox 150x446,
  // nicubunu/OpenClipart). Calibrate sulla geometria reale del corpo:
  // braccia (B) sulla parte alta del braccio, addome (A) sul basso ventre,
  // cosce (C) sulla coscia anteriore, glutei (G) sul retro.
  // Convenzione lato: D = destra (schermo-destra, x maggiore),
  // S = sinistra (schermo-sinistra, x minore).
  static const Map<String, List<BodyPoint>> defaultPoints = {
    'CD': [
      BodyPoint(0.587, 0.601), // 1
      BodyPoint(0.693, 0.601), // 2
      BodyPoint(0.587, 0.673), // 3
      BodyPoint(0.693, 0.673), // 4
      BodyPoint(0.587, 0.744), // 5
      BodyPoint(0.693, 0.744), // 6
    ],
    'CS': [
      BodyPoint(0.353, 0.601), // 1
      BodyPoint(0.460, 0.601), // 2
      BodyPoint(0.353, 0.673), // 3
      BodyPoint(0.460, 0.673), // 4
      BodyPoint(0.353, 0.744), // 5
      BodyPoint(0.460, 0.744), // 6
    ],
    'BD': [
      BodyPoint(0.800, 0.250), // 1 — braccio alto
      BodyPoint(0.900, 0.250), // 2
      BodyPoint(0.800, 0.355), // 3 — braccio basso
      BodyPoint(0.900, 0.355), // 4
    ],
    'BS': [
      BodyPoint(0.080, 0.250), // 1 — braccio alto
      BodyPoint(0.180, 0.250), // 2
      BodyPoint(0.080, 0.355), // 3 — braccio basso
      BodyPoint(0.180, 0.355), // 4
    ],
    'AD': [
      BodyPoint(0.600, 0.404), // 1
      BodyPoint(0.720, 0.404), // 2
      BodyPoint(0.600, 0.466), // 3
      BodyPoint(0.720, 0.466), // 4
    ],
    'AS': [
      BodyPoint(0.387, 0.404), // 1
      BodyPoint(0.507, 0.404), // 2
      BodyPoint(0.387, 0.466), // 3
      BodyPoint(0.507, 0.466), // 4
    ],
    'GD': [
      BodyPoint(0.520, 0.511), // 1
      BodyPoint(0.640, 0.511), // 2
      BodyPoint(0.520, 0.565), // 3
      BodyPoint(0.640, 0.565), // 4
    ],
    'GS': [
      BodyPoint(0.267, 0.511), // 1
      BodyPoint(0.387, 0.511), // 2
      BodyPoint(0.267, 0.565), // 3
      BodyPoint(0.387, 0.565), // 4
    ],
  };
}
