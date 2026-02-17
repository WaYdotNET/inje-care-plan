class BodyPoint {
  final double x;
  final double y;

  const BodyPoint(this.x, this.y);
}

class BodyZonePoints {
  // Spacing minimo 0.14 orizzontale per evitare sovrapposizione punti
  // con pointScale 0.6 su schermi mobili (~180px larghezza silhouette)
  static const Map<String, List<BodyPoint>> defaultPoints = {
    'CD': [
      BodyPoint(0.53, 0.57), // 1
      BodyPoint(0.67, 0.57), // 2
      BodyPoint(0.53, 0.65), // 3
      BodyPoint(0.67, 0.65), // 4
      BodyPoint(0.53, 0.73), // 5
      BodyPoint(0.67, 0.73), // 6
    ],
    'CS': [
      BodyPoint(0.33, 0.57), // 1
      BodyPoint(0.47, 0.57), // 2
      BodyPoint(0.33, 0.65), // 3
      BodyPoint(0.47, 0.65), // 4
      BodyPoint(0.33, 0.73), // 5
      BodyPoint(0.47, 0.73), // 6
    ],
    'BD': [
      BodyPoint(0.61, 0.21), // 1
      BodyPoint(0.75, 0.21), // 2
      BodyPoint(0.61, 0.29), // 3
      BodyPoint(0.75, 0.29), // 4
    ],
    'BS': [
      BodyPoint(0.25, 0.21), // 1
      BodyPoint(0.39, 0.21), // 2
      BodyPoint(0.25, 0.29), // 3
      BodyPoint(0.39, 0.29), // 4
    ],
    'AD': [
      BodyPoint(0.50, 0.34), // 1
      BodyPoint(0.64, 0.34), // 2
      BodyPoint(0.50, 0.43), // 3
      BodyPoint(0.64, 0.43), // 4
    ],
    'AS': [
      BodyPoint(0.36, 0.34), // 1
      BodyPoint(0.50, 0.34), // 2
      BodyPoint(0.36, 0.43), // 3
      BodyPoint(0.50, 0.43), // 4
    ],
    'GD': [
      BodyPoint(0.56, 0.50), // 1
      BodyPoint(0.70, 0.50), // 2
      BodyPoint(0.56, 0.57), // 3
      BodyPoint(0.70, 0.57), // 4
    ],
    'GS': [
      BodyPoint(0.30, 0.50), // 1
      BodyPoint(0.44, 0.50), // 2
      BodyPoint(0.30, 0.57), // 3
      BodyPoint(0.44, 0.57), // 4
    ],
  };
}
