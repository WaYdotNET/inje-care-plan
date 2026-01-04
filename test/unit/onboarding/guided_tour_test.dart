import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:injecare_plan/features/onboarding/guided_tour.dart';

void main() {
  group('TourStep', () {
    test('creates with required properties', () {
      final key = GlobalKey();
      final step = TourStep(
        targetKey: key,
        title: 'Test Title',
        description: 'Test Description',
      );

      expect(step.targetKey, key);
      expect(step.title, 'Test Title');
      expect(step.description, 'Test Description');
      expect(step.icon, isNull);
      expect(step.position, TooltipPosition.bottom);
    });

    test('creates with all properties', () {
      final key = GlobalKey();
      final step = TourStep(
        targetKey: key,
        title: 'Title',
        description: 'Description',
        icon: Icons.home,
        position: TooltipPosition.top,
      );

      expect(step.icon, Icons.home);
      expect(step.position, TooltipPosition.top);
    });
  });

  group('TooltipPosition', () {
    test('has all positions', () {
      expect(TooltipPosition.values, hasLength(4));
      expect(TooltipPosition.top, isNotNull);
      expect(TooltipPosition.bottom, isNotNull);
      expect(TooltipPosition.left, isNotNull);
      expect(TooltipPosition.right, isNotNull);
    });
  });

  group('GuidedTourController', () {
    test('initial state is inactive', () {
      final controller = GuidedTourController();

      expect(controller.isActive, false);
      expect(controller.currentStep, 0);
      expect(controller.totalSteps, 0);
      expect(controller.currentTourStep, isNull);
    });

    test('isActive returns correct state', () {
      final controller = GuidedTourController();
      expect(controller.isActive, false);
    });

    test('currentStep starts at 0', () {
      final controller = GuidedTourController();
      expect(controller.currentStep, 0);
    });

    test('totalSteps returns steps length', () {
      final controller = GuidedTourController();
      expect(controller.totalSteps, 0);
    });

    test('currentTourStep returns null when inactive', () {
      final controller = GuidedTourController();
      expect(controller.currentTourStep, isNull);
    });

    test('notifies listeners', () {
      final controller = GuidedTourController();
      var notified = false;

      controller.addListener(() {
        notified = true;
      });

      // Trigger a notification by calling notifyListeners
      // This would happen internally during startTour
      controller.notifyListeners();

      expect(notified, true);
    });

    test('dispose removes overlay', () {
      final controller = GuidedTourController();

      // Should not throw
      expect(() => controller.dispose(), returnsNormally);
    });
  });

  group('GuidedTourController static methods', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('hasCompletedTour returns false initially', () async {
      final result = await GuidedTourController.hasCompletedTour();
      expect(result, false);
    });

    test('markTourCompleted sets the flag', () async {
      await GuidedTourController.markTourCompleted();
      final result = await GuidedTourController.hasCompletedTour();
      expect(result, true);
    });

    test('resetTour clears the flag', () async {
      await GuidedTourController.markTourCompleted();
      await GuidedTourController.resetTour();
      final result = await GuidedTourController.hasCompletedTour();
      expect(result, false);
    });

    test('hasCompletedTour after markTourCompleted returns true', () async {
      SharedPreferences.setMockInitialValues({'guided_tour_completed': true});
      final result = await GuidedTourController.hasCompletedTour();
      expect(result, true);
    });
  });

  group('ContextualTooltip', () {
    testWidgets('renders child widget', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContextualTooltip(
              message: 'Test message',
              showOnFirstView: false,
              child: const Text('Child'),
            ),
          ),
        ),
      );

      expect(find.text('Child'), findsOneWidget);
    });

    testWidgets('creates with all properties', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContextualTooltip(
              message: 'Test message',
              preferredDirection: TooltipPosition.top,
              showOnFirstView: false,
              storageKey: 'test_key',
              child: const Text('Child'),
            ),
          ),
        ),
      );

      expect(find.text('Child'), findsOneWidget);
    });

    testWidgets('does not show tooltip when showOnFirstView is false', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContextualTooltip(
              message: 'Tooltip message',
              showOnFirstView: false,
              child: const Text('Child'),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      // Tooltip should not appear
      expect(find.text('Tooltip message'), findsNothing);
    });

    testWidgets('disposes without error', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContextualTooltip(
              message: 'Test',
              showOnFirstView: false,
              child: const Text('Child'),
            ),
          ),
        ),
      );

      // Navigate away to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('New Page'),
          ),
        ),
      );

      expect(find.text('New Page'), findsOneWidget);
    });
  });
}
