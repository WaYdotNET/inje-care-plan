import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/features/injection/widgets/body_silhouette_editor.dart';

void main() {
  group('pickInitialBodyView (Bug 2 — view iniziale dipende dai punti)', () {
    PositionedPoint p(int n, BodyView v) =>
        PositionedPoint(pointNumber: n, x: 0.5, y: 0.5, bodyView: v);

    test('punti vuoti → fallback al default per zoneType', () {
      expect(pickInitialBodyView(const [], 'arm'), BodyView.front);
      expect(pickInitialBodyView(const [], 'buttock'), BodyView.back);
    });

    test('tutti i punti su front → front', () {
      final points = [p(1, BodyView.front), p(2, BodyView.front)];
      // Anche se il tipo zona è buttock (default back), prevalgono i punti.
      expect(pickInitialBodyView(points, 'buttock'), BodyView.front);
    });

    test('tutti i punti su back → back', () {
      final points = [p(1, BodyView.back), p(2, BodyView.back)];
      expect(pickInitialBodyView(points, 'arm'), BodyView.back);
    });

    test('mix di front + back → fallback al default per zoneType', () {
      final points = [p(1, BodyView.front), p(2, BodyView.back)];
      expect(pickInitialBodyView(points, 'arm'), BodyView.front);
      expect(pickInitialBodyView(points, 'buttock'), BodyView.back);
    });
  });
}
