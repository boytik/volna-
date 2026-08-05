import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volna/data/content/badges.dart' as badge_data;
import 'package:volna/data/local/checkin_storage.dart';
import 'package:volna/data/local/diary_storage.dart';
import 'package:volna/data/local/quest_storage.dart';
import 'package:volna/data/local/toolbox_storage.dart';

/// Сторожит правила DESIGN.md «меня здесь не будут заставлять».
/// Это не стилистика: если тест падает, продукт начал давить на человека.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<badge_data.BadgeContext> context() async => badge_data.BadgeContext(
        questStorage: await QuestStorage.create(),
        checkInStorage: await CheckInStorage.create(),
        diaryStorage: await DiaryStorage.create(),
        toolBoxStorage: await ToolBoxStorage.create(),
      );

  String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Отмечает утренний квест выполненным N дней назад.
  void markDaysAgo(List<int> ages) {
    final today = DateTime.now();
    final values = <String, Object>{};
    for (final age in ages) {
      final d = today.subtract(Duration(days: age));
      values['flutter.done_morning_${dateKey(d)}'] = true;
    }
    SharedPreferences.setMockInitialValues(values);
  }

  group('Ни одного знака за регулярность', () {
    test('знака за дни подряд больше не существует', () {
      final byId = {for (final b in badge_data.allBadges) b.id};
      expect(byId.contains('three_in_a_row'), isFalse);

      for (final b in badge_data.allBadges) {
        expect(
          b.title.toLowerCase(),
          isNot(contains('подряд')),
          reason: 'знак «${b.title}» награждает за стрик',
        );
      }
    });

    test('«Пропустила и вернулась» есть в наборе', () {
      final ids = {for (final b in badge_data.allBadges) b.id};
      expect(ids, contains('came_back'));
    });
  });

  group('«Пропустила и вернулась»', () {
    final badge =
        badge_data.allBadges.firstWhere((b) => b.id == 'came_back');

    test('не даётся тому, кто ходил без перерыва', () async {
      markDaysAgo([0, 1, 2, 3, 4]);
      expect(badge.unlock(await context()), isFalse);
    });

    test('не даётся за один пропущенный день', () async {
      // Пробел в один день: 0 и 2 — разница 2, этого мало.
      markDaysAgo([0, 2, 3]);
      expect(badge.unlock(await context()), isFalse);
    });

    test('даётся после перерыва в два дня и возвращения', () async {
      // Ходила 5 и 6 дней назад, пропустила 4, 3, 2, вернулась сегодня.
      markDaysAgo([0, 5, 6]);
      expect(badge.unlock(await context()), isTrue);
    });

    test('его невозможно получить, ни разу не пропустив', () async {
      markDaysAgo(List<int>.generate(20, (i) => i));
      expect(
        badge.unlock(await context()),
        isFalse,
        reason: 'знак должен требовать пропуска, а не выдержки',
      );
    });
  });

  group('Кольца древа растут от времени, а не от дисциплины', () {
    test('неактивная неделя всё равно даёт кольцо', () async {
      final first = DateTime.now().subtract(const Duration(days: 21));
      SharedPreferences.setMockInitialValues({
        'flutter.first_seen': dateKey(first),
        // Ни одной отметки о выполнении: человек не приходил ни разу.
      });
      final quest = await QuestStorage.create();
      expect(quest.weeksLived, 3);
    });

    test('кольца не уменьшаются от бездействия', () async {
      final first = DateTime.now().subtract(const Duration(days: 70));
      SharedPreferences.setMockInitialValues({
        'flutter.first_seen': dateKey(first),
      });
      final quest = await QuestStorage.create();
      expect(quest.weeksLived, 10);
      expect(quest.daysSinceActivity, greaterThan(60));
    });

    test('первый запуск не уходит в минус', () async {
      SharedPreferences.setMockInitialValues({
        'flutter.first_seen': dateKey(DateTime.now()),
      });
      final quest = await QuestStorage.create();
      expect(quest.weeksLived, 0);
    });
  });

  group('Следы практик гаснут, но ничего не отваливается', () {
    test('в окно попадают только последние десять дней', () async {
      markDaysAgo([0, 3, 9, 12, 40]);
      final quest = await QuestStorage.create();
      expect(quest.recentActivityAges(), [0, 3, 9]);
    });

    test('без активности следов просто нет', () async {
      final quest = await QuestStorage.create();
      expect(quest.recentActivityAges(), isEmpty);
    });
  });
}
