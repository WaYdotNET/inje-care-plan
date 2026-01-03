import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:injecare_plan/core/widgets/animated_counter.dart';

void main() {
  group('AnimatedCounter', () {
    testWidgets('should render with value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedCounter(value: 100),
          ),
        ),
      );

      expect(find.byType(AnimatedCounter), findsOneWidget);
    });

    testWidgets('should animate to final value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedCounter(
              value: 50,
              duration: Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      // Initially shows 0
      expect(find.text('0'), findsOneWidget);

      // After animation completes
      await tester.pumpAndSettle();
      expect(find.text('50'), findsOneWidget);
    });

    testWidgets('should show prefix and suffix', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedCounter(
              value: 75,
              prefix: '\$',
              suffix: '%',
              duration: Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('\$75%'), findsOneWidget);
    });

    testWidgets('should show decimals', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedCounter(
              value: 99.5,
              decimals: 1,
              duration: Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('99.5'), findsOneWidget);
    });
  });

  group('AnimatedCircularProgress', () {
    testWidgets('should render with value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedCircularProgress(value: 0.75),
          ),
        ),
      );

      expect(find.byType(AnimatedCircularProgress), findsOneWidget);
    });

    testWidgets('should render with child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedCircularProgress(
              value: 0.5,
              child: Text('50%'),
            ),
          ),
        ),
      );

      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('should render with custom size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedCircularProgress(
              value: 0.5,
              size: 150,
              strokeWidth: 12,
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 150);
      expect(sizedBox.height, 150);
    });
  });

  group('FadeInWidget', () {
    testWidgets('should render child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FadeInWidget(
              child: Text('Hello'),
            ),
          ),
        ),
      );

      expect(find.byType(FadeInWidget), findsOneWidget);
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('should animate with delay', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FadeInWidget(
              delay: Duration(milliseconds: 100),
              duration: Duration(milliseconds: 100),
              child: Text('Delayed'),
            ),
          ),
        ),
      );

      // Wait for delay and animation
      await tester.pumpAndSettle();
      expect(find.text('Delayed'), findsOneWidget);
    });
  });

  group('StaggeredList', () {
    testWidgets('should render all children', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StaggeredList(
              children: [
                Text('Item 1'),
                Text('Item 2'),
                Text('Item 3'),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
    });
  });

  group('BounceAnimation', () {
    testWidgets('should render child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BounceAnimation(
              animate: false,
              child: Text('Bounce'),
            ),
          ),
        ),
      );

      expect(find.text('Bounce'), findsOneWidget);
    });

    testWidgets('should animate when enabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BounceAnimation(
              animate: true,
              duration: Duration(milliseconds: 100),
              child: Text('Bounce'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Bounce'), findsOneWidget);
    });
  });

  group('PulseAnimation', () {
    testWidgets('should render child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PulseAnimation(
              enabled: false,
              child: Text('Pulse'),
            ),
          ),
        ),
      );

      expect(find.text('Pulse'), findsOneWidget);
    });
  });
}
