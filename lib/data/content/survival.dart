/// Контент для режима выживания. Один и тот же квест каждый день —
/// родителю в кризисе нужен ритуал, а не выбор.
/// Цель: 30 секунд, никаких таймеров, никаких счётчиков «прогресса».
library;

import '../../data/content/quests.dart';

class SurvivalQuest {
  const SurvivalQuest({
    required this.title,
    required this.action,
    required this.afterPhrase,
  });

  final String title;
  final String action;
  final String afterPhrase;
}

const survivalMorning = SurvivalQuest(
  title: 'Один длинный выдох',
  action: 'Сделай один медленный выдох. Прямо сейчас. '
      'Не считай, не думай — просто выдохни до конца.',
  afterPhrase: 'Ты сделала. Этого достаточно для сегодня.',
);

const survivalEvening = SurvivalQuest(
  title: 'Ладонь на сердце',
  action: 'Положи тёплую ладонь на грудь. Один вдох. Один выдох. '
      'Скажи про себя: «Сегодня было трудно. Я здесь».',
  afterPhrase: 'Ты выдержала этот день. Завтра будет ровно столько же сил, сколько нужно.',
);

SurvivalQuest survivalFor(QuestSlot slot) =>
    slot == QuestSlot.morning ? survivalMorning : survivalEvening;
