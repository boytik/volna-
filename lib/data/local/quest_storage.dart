import 'package:shared_preferences/shared_preferences.dart';

import '../content/quests.dart';

/// Хранение состояния выполнения квестов.
/// Ключи `done_morning_2026-04-27` → bool, `drops` → int, `last_activity` → ISO date.
class QuestStorage {
  QuestStorage(this._prefs);

  final SharedPreferences _prefs;

  static Future<QuestStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return QuestStorage(prefs);
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _doneKey(QuestSlot slot, DateTime date) =>
      'done_${slot.name}_${_dateKey(date)}';

  bool isDoneToday(QuestSlot slot) =>
      _prefs.getBool(_doneKey(slot, DateTime.now())) ?? false;

  bool isDoneOn(QuestSlot slot, DateTime date) =>
      _prefs.getBool(_doneKey(slot, date)) ?? false;

  Future<void> markDoneToday(QuestSlot slot) async {
    final now = DateTime.now();
    await _prefs.setBool(_doneKey(slot, now), true);
    await _prefs.setInt('drops', drops + 1);
    await _prefs.setString('last_activity', _dateKey(now));
  }

  int get drops => _prefs.getInt('drops') ?? 0;

  /// Дата последней активности (любой завершённый квест).
  DateTime? get lastActivity {
    final s = _prefs.getString('last_activity');
    if (s == null) return null;
    final parts = s.split('-');
    if (parts.length != 3) return null;
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// Сколько дней прошло с последней активности (0 = сегодня).
  int get daysSinceActivity {
    final last = lastActivity;
    if (last == null) return 9999;
    final today = DateTime.now();
    return DateTime(today.year, today.month, today.day)
        .difference(DateTime(last.year, last.month, last.day))
        .inDays;
  }

  /// Список выполнений за последние [days] дней (для статистики).
  List<DayActivity> activityLastDays(int days) {
    final today = DateTime.now();
    return List.generate(days, (i) {
      final date = today.subtract(Duration(days: days - 1 - i));
      return DayActivity(
        date: date,
        morning: isDoneOn(QuestSlot.morning, date),
        evening: isDoneOn(QuestSlot.evening, date),
      );
    });
  }

  /// Только для отладки.
  Future<void> reset() async {
    final keys = _prefs.getKeys().toList();
    for (final k in keys) {
      await _prefs.remove(k);
    }
  }
}

class DayActivity {
  const DayActivity({
    required this.date,
    required this.morning,
    required this.evening,
  });

  final DateTime date;
  final bool morning;
  final bool evening;

  int get count => (morning ? 1 : 0) + (evening ? 1 : 0);
}
