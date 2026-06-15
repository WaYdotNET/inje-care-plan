import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stile della schermata di selezione punto.
/// - [map]: nuova mappa unica del corpo con tutti i punti.
/// - [classic]: versione classica a step/scroll (griglia zone + silhouette).
enum PointSelectionStyle { map, classic }

/// Provider per lo stile di selezione punto, persistito su SharedPreferences.
/// Default: [PointSelectionStyle.map]. Serve a confrontare le due UI e
/// raccogliere feedback dagli utenti.
final pointSelectionStyleProvider =
    NotifierProvider<PointSelectionStyleNotifier, PointSelectionStyle>(
  PointSelectionStyleNotifier.new,
);

class PointSelectionStyleNotifier extends Notifier<PointSelectionStyle> {
  static const _key = 'point_selection_style';

  @override
  PointSelectionStyle build() {
    _loadFromPrefs();
    return PointSelectionStyle.map;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    final value = prefs.getString(_key);
    if (value != null) {
      state = _fromString(value);
    }
  }

  Future<void> setStyle(PointSelectionStyle style) async {
    state = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, style.name);
  }

  PointSelectionStyle _fromString(String value) => switch (value) {
        'classic' => PointSelectionStyle.classic,
        _ => PointSelectionStyle.map,
      };
}
