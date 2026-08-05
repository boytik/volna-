import '../data/content/badges.dart';
import '../data/local/badges_storage.dart';
import '../data/local/checkin_storage.dart';
import '../data/local/diary_storage.dart';
import '../data/local/quest_storage.dart';
import '../data/local/toolbox_storage.dart';

/// Проверяет, открылись ли новые значки. Возвращает их (для показа модалки).
class BadgesService {
  BadgesService({
    required this.badgesStorage,
    required this.questStorage,
    required this.checkInStorage,
    required this.diaryStorage,
    required this.toolBoxStorage,
  });

  final BadgesStorage badgesStorage;
  final QuestStorage questStorage;
  final CheckInStorage checkInStorage;
  final DiaryStorage diaryStorage;
  final ToolBoxStorage toolBoxStorage;

  /// Проверить условия всех значков. Сохранить новые. Вернуть только новые.
  Future<List<Badge>> checkUnlocks() async {
    final ctx = BadgeContext(
      questStorage: questStorage,
      checkInStorage: checkInStorage,
      diaryStorage: diaryStorage,
      toolBoxStorage: toolBoxStorage,
    );

    final unlocked = badgesStorage.all();
    final newly = <Badge>[];

    for (final b in allBadges) {
      if (unlocked.contains(b.id)) continue;
      if (b.unlock(ctx)) {
        await badgesStorage.add(b.id);
        newly.add(b);
      }
    }

    return newly;
  }
}
