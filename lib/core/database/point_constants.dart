class BodyPoint {
  final double x;
  final double y;

  const BodyPoint(this.x, this.y);
}

class BodyZonePoints {
  static const Map<String, List<BodyPoint>> defaultPoints = {
    'CD': [
      BodyPoint(0.55, 0.58), // 1
      BodyPoint(0.65, 0.58), // 2
      BodyPoint(0.55, 0.65), // 3
      BodyPoint(0.65, 0.65), // 4
      BodyPoint(0.55, 0.72), // 5
      BodyPoint(0.65, 0.72), // 6
    ],
    'CS': [
      BodyPoint(0.35, 0.58), // 1
      BodyPoint(0.55, 0.58), // 2
      BodyPoint(0.35, 0.65), // 3
      BodyPoint(0.55, 0.65), // 4
      BodyPoint(0.35, 0.72), // 5
      BodyPoint(0.55, 0.72), // 6
    ],
    'BD': [
      BodyPoint(0.64, 0.22), // 1
      BodyPoint(0.71, 0.22), // 2
      BodyPoint(0.64, 0.28), // 3
      BodyPoint(0.71, 0.28), // 4
    ],
    'BS': [
      BodyPoint(0.27, 0.22), // 1
      BodyPoint(0.36, 0.22), // 2
      BodyPoint(0.27, 0.28), // 3
      BodyPoint(0.36, 0.28), // 4
    ],
    'AD': [
      BodyPoint(0.52, 0.35), // 1
      BodyPoint(0.62, 0.35), // 2
      BodyPoint(0.52, 0.42), // 3
      BodyPoint(0.62, 0.42), // 4
    ],
    'AS': [
      BodyPoint(0.38, 0.35), // 1 (Mirrored from AD-2)
      BodyPoint(0.48, 0.35), // 2 (Mirrored from AD-1)
      BodyPoint(0.38, 0.42), // 3 (Mirrored from AD-4)
      BodyPoint(0.48, 0.42), // 4 (Mirrored from AD-3)
    ],
    'GD': [
      BodyPoint(0.60, 0.50), // 1
      BodyPoint(0.66, 0.50), // 2
      BodyPoint(0.60, 0.55), // 3
      BodyPoint(0.66, 0.55), // 4
    ],
    'GS': [
      BodyPoint(0.40, 0.50), // 1
      BodyPoint(0.46, 0.50), // 2
      BodyPoint(0.40, 0.55), // 3
      BodyPoint(0.46, 0.55), // 4
    ],
  };
}
