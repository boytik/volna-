import 'package:shared_preferences/shared_preferences.dart';

import '../content/quests.dart';

/// Микро-чек-ин: настроение и сон, утром и вечером.
/// Mood: 0 = плохо, 1 = средне, 2 = хорошо. Sleep: 0 = плохо, 1 = нормально, 2 = отлично.
/// Хранится по ключам `mood_morning_2026-04-27`, `sleep_morning_2026-04-27` и т.п.

enum MoodValue { bad, neutral, good }

extension MoodValueExt on MoodValue {
  int get index_ => MoodValue.values.indexOf(this);
  static MoodValue? fromInt(int? i) {
    if (i == null) return null;
    if (i < 0 || i >= MoodValue.values.length) return null;
    return MoodValue.values[i];
  }
}

enum SleepValue { bad, normal, great }

extension SleepValueExt on SleepValue {
  int get index_ => SleepValue.values.indexOf(this);
  static SleepValue? fromInt(int? i) {
    if (i == null) return null;
    if (i < 0 || i >= SleepValue.values.length) return null;
    return SleepValue.values[i];
  }
}

class CheckIn {
  const CheckIn({this.mood, this.sleep});
  final MoodValue? mood;
  final SleepValue? sleep;

  bool get isEmpty => mood == null && sleep == null;
}

class CheckInStorage {
  CheckInStorage(this._prefs);
  final SharedPreferences _prefs;

  static Future<CheckInStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return CheckInStorage(prefs);
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _moodKey(QuestSlot slot, DateTime date) =>
      'mood_${slot.name}_${_dateKey(date)}';
  String _sleepKey(QuestSlot slot, DateTime date) =>
      'sleep_${slot.name}_${_dateKey(date)}';

  CheckIn getCheckIn(QuestSlot slot, DateTime date) => CheckIn(
        mood: MoodValueExt.fromInt(_prefs.getInt(_moodKey(slot, date))),
        sleep: SleepValueExt.fromInt(_prefs.getInt(_sleepKey(slot, date))),
      );

  Future<void> save(QuestSlot slot, {MoodValue? mood, SleepValue? sleep}) async {
    final now = DateTime.now();
    if (mood != null) {
      await _prefs.setInt(_moodKey(slot, now), mood.index_);
    }
    if (sleep != null) {
      await _prefs.setInt(_sleepKey(slot, now), sleep.index_);
    }
  }

  /// Усреднённое настроение дня (среднее между утренним и вечерним, если есть оба).
  /// Возвращает null если за день ни одного чек-ина.
  double? averageMood(DateTime date) {
    final morning = MoodValueExt.fromInt(
      _prefs.getInt(_moodKey(QuestSlot.morning, date)),
    );
    final evening = MoodValueExt.fromInt(
      _prefs.getInt(_moodKey(QuestSlot.evening, date)),
    );
    if (morning == null && evening == null) return null;
    if (morning != null && evening != null) {
      return (morning.index_ + evening.index_) / 2;
    }
    return (morning ?? evening!).index_.toDouble();
  }
}
