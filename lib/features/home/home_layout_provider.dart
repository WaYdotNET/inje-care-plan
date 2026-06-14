import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Layout selezionabile per la schermata Home.
enum HomeLayout { week, silhouette }

/// Provider per il layout della Home, persistito su SharedPreferences.
/// Default: [HomeLayout.week] (agenda settimanale).
final homeLayoutProvider =
    NotifierProvider<HomeLayoutNotifier, HomeLayout>(HomeLayoutNotifier.new);

class HomeLayoutNotifier extends Notifier<HomeLayout> {
  static const _key = 'home_layout';

  @override
  HomeLayout build() {
    _loadFromPrefs();
    return HomeLayout.week;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    final value = prefs.getString(_key);
    if (value != null) {
      state = _fromString(value);
    }
  }

  Future<void> setLayout(HomeLayout layout) async {
    state = layout;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, layout.name);
  }

  HomeLayout _fromString(String value) => switch (value) {
        'silhouette' => HomeLayout.silhouette,
        _ => HomeLayout.week,
      };
}
