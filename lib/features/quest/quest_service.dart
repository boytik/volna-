import '../../data/content/quests.dart';

/// Подбор квеста на сегодня — стабильный per-day выбор по дате.
/// Один и тот же квест в течение дня, разный — между днями.
/// Ротация: индекс = (year*1000 + day_of_year + slot_offset) % pool.length.
class QuestPicker {
  static Quest pickToday(QuestSlot slot, [DateTime? now]) {
    final today = now ?? DateTime.now();
    final pool = slot == QuestSlot.morning ? morningQuests : eveningQuests;

    final dayOfYear = today
        .difference(DateTime(today.year))
        .inDays;
    final slotOffset = slot == QuestSlot.morning ? 0 : 7;
    final seed = today.year * 1000 + dayOfYear + slotOffset;
    final index = seed % pool.length;

    return pool[index];
  }
}
