import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/features/home/home_layout_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeLayoutNotifier', () {
    test(
      'A: default is HomeLayout.week when no stored value',
      () async {
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Trigger provider creation, then pump microtasks to let
        // _loadFromPrefs complete (mirrors ThemeModeNotifier test pattern).
        container.read(homeLayoutProvider);
        await Future<void>.delayed(Duration.zero);

        expect(container.read(homeLayoutProvider), HomeLayout.week);
      },
    );

    test(
      'B: setLayout(silhouette) persists "silhouette" under key "home_layout"',
      () async {
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container
            .read(homeLayoutProvider.notifier)
            .setLayout(HomeLayout.silhouette);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('home_layout'), 'silhouette');
      },
    );

    test(
      'C: pre-stored "silhouette" is loaded as HomeLayout.silhouette',
      () async {
        SharedPreferences.setMockInitialValues({'home_layout': 'silhouette'});
        final container = ProviderContainer();

        // Trigger provider creation, then pump microtasks to let
        // _loadFromPrefs complete (mirrors ThemeModeNotifier test pattern).
        container.read(homeLayoutProvider);
        await Future<void>.delayed(Duration.zero);

        expect(container.read(homeLayoutProvider), HomeLayout.silhouette);
        container.dispose();
      },
    );
  });
}
