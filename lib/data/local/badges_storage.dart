import 'package:shared_preferences/shared_preferences.dart';

/// Хранение открытых значков. Простой `Set<String>` в одном ключе.
class BadgesStorage {
  BadgesStorage(this._prefs);
  final SharedPreferences _prefs;

  static const _key = 'unlocked_badges';

  static Future<BadgesStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return BadgesStorage(prefs);
  }

  Set<String> all() {
    final list = _prefs.getStringList(_key) ?? <String>[];
    return list.toSet();
  }

  Future<void> add(String id) async {
    final s = all()..add(id);
    await _prefs.setStringList(_key, s.toList());
  }

  bool isUnlocked(String id) => all().contains(id);
}
