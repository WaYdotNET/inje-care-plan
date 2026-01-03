import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:injecare_plan/core/widgets/shimmer_loading.dart';

void main() {
  group('ShimmerCard', () {
    testWidgets('should render with default height', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerCard(),
          ),
        ),
      );

      // Find the shimmer card container
      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);
    });

    testWidgets('should render with custom height', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerCard(height: 200),
          ),
        ),
      );

      expect(find.byType(ShimmerCard), findsOneWidget);
    });

    testWidgets('should render with custom width', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerCard(width: 150, height: 100),
          ),
        ),
      );

      expect(find.byType(ShimmerCard), findsOneWidget);
    });
  });

  group('ShimmerText', () {
    testWidgets('should render with default dimensions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerText(),
          ),
        ),
      );

      expect(find.byType(ShimmerText), findsOneWidget);
    });

    testWidgets('should render with custom dimensions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerText(width: 200, height: 24),
          ),
        ),
      );

      expect(find.byType(ShimmerText), findsOneWidget);
    });
  });

  group('ShimmerList', () {
    testWidgets('should render default number of items', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ShimmerList(),
            ),
          ),
        ),
      );

      expect(find.byType(ShimmerList), findsOneWidget);
    });

    testWidgets('should render custom number of items', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ShimmerList(itemCount: 3),
            ),
          ),
        ),
      );

      expect(find.byType(ShimmerList), findsOneWidget);
    });
  });

  group('ShimmerLoading', () {
    testWidgets('should show child when disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerLoading(
              enabled: false,
              child: Text('Test'),
            ),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('should wrap child with shimmer when enabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerLoading(
              enabled: true,
              child: Text('Test'),
            ),
          ),
        ),
      );

      expect(find.byType(ShimmerLoading), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
    });
  });

  group('ShimmerStats', () {
    testWidgets('should render all stat components', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ShimmerStats(),
            ),
          ),
        ),
      );

      expect(find.byType(ShimmerStats), findsOneWidget);
      expect(find.byType(ShimmerCard), findsWidgets);
    });
  });
}
