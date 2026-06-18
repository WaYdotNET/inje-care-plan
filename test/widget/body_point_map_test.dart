import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/features/injection/injection_provider.dart';
import 'package:injecare_plan/features/injection/widgets/body_point_map.dart';
import 'package:injecare_plan/features/injection/widgets/body_silhouette_editor.dart';
import 'package:injecare_plan/features/injection/point_usage_level.dart';

BodyMapPoint _p(int zid, int n, BodyView v, {String? customName}) =>
    BodyMapPoint(
      zoneId: zid,
      zoneName: 'Z$zid',
      zoneEmoji: '•',
      pointNumber: n,
      x: 0.5,
      y: 0.5,
      bodyView: v,
      usageLevel: PointUsageLevel.neverUsed,
      isBlacklisted: false,
      isSuggested: false,
      customName: customName,
    );

Future<void> _pumpSingle(WidgetTester tester, BodyMapPoint point) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: BodyPointMap(
        points: [point],
        selectedZoneId: null,
        selectedPointNumber: null,
        onTap: (_) {},
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tap su un punto invoca onTap col punto giusto', (tester) async {
    BodyMapPoint? tapped;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BodyPointMap(
          points: [_p(1, 1, BodyView.front)],
          selectedZoneId: null,
          selectedPointNumber: null,
          onTap: (p) => tapped = p,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1'));
    expect(tapped?.zoneId, 1);
    expect(tapped?.pointNumber, 1);
  });

  testWidgets('mostra solo i punti della vista corrente (fronte di default)',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BodyPointMap(
          points: [_p(1, 1, BodyView.front), _p(2, 1, BodyView.back)],
          selectedZoneId: null,
          selectedPointNumber: null,
          onTap: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();
    // Vista fronte: vede il punto front (zona 1), non quello back.
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('il marker mostra il nome custom del punto invece del numero',
      (tester) async {
    await _pumpSingle(tester, _p(1, 2, BodyView.front, customName: '27'));
    expect(find.text('27'), findsOneWidget);
    expect(find.text('2'), findsNothing);
  });

  testWidgets('nome custom lungo troncato a 3 caratteri sul marker',
      (tester) async {
    await _pumpSingle(tester, _p(1, 1, BodyView.front, customName: 'Spalla'));
    expect(find.text('Spa'), findsOneWidget);
  });

  testWidgets('senza nome custom il marker mostra il numero del punto',
      (tester) async {
    await _pumpSingle(tester, _p(1, 3, BodyView.front));
    expect(find.text('3'), findsOneWidget);
  });
}
