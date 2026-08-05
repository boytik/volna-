import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../data/local/checkin_storage.dart';
import '../../data/local/diary_storage.dart';
import '../../data/local/quest_storage.dart';
import '../../data/local/toolbox_storage.dart';
import '../content/quests.dart';

/// Значки — мягкая позитивная обратная связь.
/// Принципы (из ресёрча по burnout-приложениям):
/// — никогда не отнимаются («ты потеряла значок»),
/// — не сравниваются с другими,
/// — формулировки про присутствие, не про достижение,
/// — открываются неожиданно, без счётчиков «осталось до значка».

class Badge {
  const Badge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.unlock,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  /// Функция-предикат: проверяет, выполнено ли условие открытия.
  final bool Function(BadgeContext) unlock;
}

/// Контекст для проверки условий — все стораджи одним пакетом.
class BadgeContext {
  const BadgeContext({
    required this.questStorage,
    required this.checkInStorage,
    required this.diaryStorage,
    required this.toolBoxStorage,
  });

  final QuestStorage questStorage;
  final CheckInStorage checkInStorage;
  final DiaryStorage diaryStorage;
  final ToolBoxStorage toolBoxStorage;
}

const allBadges = <Badge>[
  Badge(
    id: 'first_step',
    title: 'Первый шаг',
    description: 'Ты сделала первый утренний или вечерний квест.',
    icon: Icons.eco_rounded,
    color: AppColors.sageDeep,
    unlock: _firstStep,
  ),
  Badge(
    id: 'first_sos',
    title: 'Я выбрала действие',
    description: 'Ты впервые отметила, что SOS-техника помогла. '
        'Теперь она в твоём наборе.',
    icon: Icons.favorite_rounded,
    color: AppColors.terracotta,
    unlock: _firstSos,
  ),
  Badge(
    id: 'first_envelope',
    title: 'Запечатано',
    description: 'Ты написала свою первую тревогу в конверт. '
        'Иногда отложить — лучше, чем решать сейчас.',
    icon: Icons.mail_rounded,
    color: AppColors.coral,
    unlock: _firstEnvelope,
  ),
  Badge(
    id: 'three_in_a_row',
    title: 'Три дня подряд',
    description: 'Три дня — каждый со своим маленьким шагом. '
        'Это уже привычка, не подвиг.',
    icon: Icons.trending_up_rounded,
    color: AppColors.saffron,
    unlock: _threeInRow,
  ),
  Badge(
    id: 'week_with_me',
    title: 'Неделя со мной',
    description: 'Семь дней ты возвращалась. Не каждый день идеально — '
        'но ты приходила.',
    icon: Icons.spa_rounded,
    color: AppColors.sage,
    unlock: _weekWithMe,
  ),
  Badge(
    id: 'self_friend',
    title: 'Я говорю себе доброе',
    description: 'Три записи «Подруга на твоём месте». '
        'Ты учишься быть для себя такой же — как для лучшей подруги.',
    icon: Icons.handshake_rounded,
    color: AppColors.peach,
    unlock: _selfFriend,
  ),
  Badge(
    id: 'three_good_starter',
    title: 'Три хороших',
    description: 'Ты заметила три хороших события за день. '
        'Внимание к маленьким радостям — это тренировка.',
    icon: Icons.auto_awesome_rounded,
    color: AppColors.saffron,
    unlock: _threeGoodStarter,
  ),
  Badge(
    id: 'discarded',
    title: 'Я отпустила',
    description: 'Ты выбросила конверт тревоги. '
        'Большинство мыслей через сутки звучат иначе — '
        'ты убедилась в этом сама.',
    icon: Icons.delete_outline_rounded,
    color: AppColors.sage,
    unlock: _discarded,
  ),
  Badge(
    id: 'roots_deeper',
    title: 'Корни глубже',
    description: 'Десять капель — древо стало саженцем. '
        'Это значит: ты не один день случайно зашла, ты выбираешь приходить.',
    icon: Icons.park_rounded,
    color: AppColors.sageDeep,
    unlock: _rootsDeeper,
  ),
  Badge(
    id: 'i_seek_help',
    title: 'Я ищу помощь',
    description: 'Ты открыла раздел связи со специалистом. '
        'Просить помощи — это сила, не слабость.',
    icon: Icons.support_agent_rounded,
    color: AppColors.terracotta,
    unlock: _seeksHelp,
  ),
  Badge(
    id: 'mirror',
    title: 'Зеркало',
    description: 'Ты прошла первый опросник. '
        'Видеть себя со стороны — отдельная смелость.',
    icon: Icons.assignment_turned_in_rounded,
    color: AppColors.peach,
    unlock: _mirror,
  ),
  Badge(
    id: 'tree_blossoms',
    title: 'Цветение',
    description: 'Пятьдесят капель. Древо в цвету. '
        'Ты пришла сюда тысячу раз — и это видно.',
    icon: Icons.local_florist_rounded,
    color: AppColors.peach,
    unlock: _blossoms,
  ),
];

bool _firstStep(BadgeContext c) => c.questStorage.drops >= 1;

bool _firstSos(BadgeContext c) => c.toolBoxStorage.hasAny;

bool _firstEnvelope(BadgeContext c) =>
    c.diaryStorage.ofKind(DiaryKind.envelope).isNotEmpty;

bool _threeInRow(BadgeContext c) {
  final today = DateTime.now();
  for (var i = 0; i < 3; i++) {
    final d = today.subtract(Duration(days: i));
    final any = c.questStorage.isDoneOn(QuestSlot.morning, d) ||
        c.questStorage.isDoneOn(QuestSlot.evening, d);
    if (!any) return false;
  }
  return true;
}

bool _weekWithMe(BadgeContext c) {
  final today = DateTime.now();
  var days = 0;
  for (var i = 0; i < 7; i++) {
    final d = today.subtract(Duration(days: i));
    final any = c.questStorage.isDoneOn(QuestSlot.morning, d) ||
        c.questStorage.isDoneOn(QuestSlot.evening, d);
    if (any) days++;
  }
  return days >= 5; // 5 из 7 — мягкое условие
}

bool _selfFriend(BadgeContext c) =>
    c.diaryStorage.ofKind(DiaryKind.friendOnYourPlace).length >= 3;

bool _threeGoodStarter(BadgeContext c) =>
    c.diaryStorage.ofKind(DiaryKind.threeGood).isNotEmpty;

bool _discarded(BadgeContext c) {
  return c.diaryStorage
      .ofKind(DiaryKind.envelope)
      .any((e) => e.envelopeStatus == 'discarded');
}

bool _rootsDeeper(BadgeContext c) => c.questStorage.drops >= 10;

bool _seeksHelp(BadgeContext c) =>
    c.toolBoxStorage.helpScreenOpened;

bool _mirror(BadgeContext c) => c.toolBoxStorage.questionnaireCompleted;

bool _blossoms(BadgeContext c) => c.questStorage.drops >= 50;
