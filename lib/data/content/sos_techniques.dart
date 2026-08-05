import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

/// Триггерные состояния — по ним группируем техники в меню SOS.
enum SosTrigger { panic, rage, freeze, shame, anxiety }

extension SosTriggerExt on SosTrigger {
  String get label {
    switch (this) {
      case SosTrigger.panic:
        return 'Острая паника';
      case SosTrigger.rage:
        return 'Хочется накричать';
      case SosTrigger.freeze:
        return 'Замерла, не чувствую';
      case SosTrigger.shame:
        return '«Я плохая мать»';
      case SosTrigger.anxiety:
        return 'Тревожусь';
    }
  }

  String get sub {
    switch (this) {
      case SosTrigger.panic:
        return 'Сердце колотится, не хватает воздуха';
      case SosTrigger.rage:
        return 'Гнев поднимается, рука сжалась в кулак';
      case SosTrigger.freeze:
        return 'Окаменела, всё далеко, тело тяжёлое';
      case SosTrigger.shame:
        return 'Внутренний голос говорит «я не справляюсь»';
      case SosTrigger.anxiety:
        return 'Мысли несутся, «а что если…»';
    }
  }
}

class TechniqueStep {
  const TechniqueStep({required this.heading, required this.body});
  final String heading;
  final String body;
}

class SosTechnique {
  const SosTechnique({
    required this.id,
    required this.title,
    required this.triggers,
    required this.whenToUse,
    required this.duration,
    required this.steps,
    required this.afterPhrase,
    required this.icon,
    required this.accent,
    this.contraindication,
    this.routeOverride,
    this.breath,
  });

  final String id;
  final String title;
  final List<SosTrigger> triggers;
  final String whenToUse;
  final String duration;
  final List<TechniqueStep> steps;
  final String afterPhrase;
  final IconData icon;
  final Color accent;
  final String? contraindication;
  /// Если техника имеет специальный экран (например, дыхание «Квадрат»),
  /// сюда кладём маршрут вместо генерируемых шагов.
  final String? routeOverride;

  /// Темп дыхания в секундах для техник, где дыхание и есть упражнение.
  /// Экран техники рисует по нему цветок, чтобы человеку было за чем
  /// следить, а не только считать про себя. Темп берём из самой техники:
  /// у удлинённого выдоха выдох вдвое длиннее вдоха, и картинка обязана
  /// показывать именно это, иначе она спорит с текстом инструкции.
  final ({int inhale, int exhale})? breath;
}

const _existingBreathing = SosTechnique(
  id: 'breathing_box',
  title: 'Дыхание «Квадрат»',
  triggers: [SosTrigger.panic, SosTrigger.anxiety],
  whenToUse: 'Когда нарастает паника или гнев. '
      'Самый универсальный способ переключить нервную систему.',
  duration: '1 минута',
  steps: [],
  afterPhrase: 'Ты вернулась к дыханию — это уже регуляция.',
  icon: Icons.air_rounded,
  accent: AppColors.sage,
  routeOverride: '/sos/breathing',
);

const _existingGrounding = SosTechnique(
  id: 'grounding_54321',
  title: 'Заземление 5-4-3-2-1',
  triggers: [SosTrigger.freeze, SosTrigger.anxiety],
  whenToUse: 'Когда мысли уносит в будущее или ты «отключилась» от тела. '
      'Возвращает в «здесь и сейчас».',
  duration: '2 минуты',
  steps: [],
  afterPhrase: 'Ты — здесь, на земле, в своём теле.',
  icon: Icons.touch_app_rounded,
  accent: AppColors.saffron,
  routeOverride: '/sos/grounding',
);

const _existingSelfCompassion = SosTechnique(
  id: 'self_compassion',
  title: 'Ладонь на сердце',
  triggers: [SosTrigger.shame],
  whenToUse: 'Когда чувствуешь вину или стыд. Самосострадание по К. Нефф.',
  duration: '1 минута',
  steps: [],
  afterPhrase: 'Твоя любовь уже достаточна.',
  icon: Icons.favorite_rounded,
  accent: AppColors.peach,
  routeOverride: '/sos/self-compassion',
);

// ──────────────── Из ТЗ ────────────────

const physiologicalSigh = SosTechnique(
  breath: (inhale: 3, exhale: 6),
  id: 'physiological_sigh',
  title: 'Двойной вдох',
  triggers: [SosTrigger.panic, SosTrigger.anxiety],
  whenToUse: 'Когда поднимается паника, сжимается грудь. '
      'Самый быстрый способ, исследованный учёными.',
  duration: '1 минута',
  steps: [
    TechniqueStep(
      heading: 'Шаг 1',
      body: 'Сделай обычный вдох носом. Не глубокий — обычный.',
    ),
    TechniqueStep(
      heading: 'Шаг 2',
      body: 'На самом верху — добери ещё один короткий вдох носом, '
          'как будто заполняешь до конца.',
    ),
    TechniqueStep(
      heading: 'Шаг 3',
      body: 'Долго и медленно выдыхай ртом — '
          'выдох должен быть длиннее обоих вдохов вместе.',
    ),
    TechniqueStep(
      heading: 'Шаг 4',
      body: 'Повтори 4-6 раз. Уже после первых двух циклов '
          'станет легче дышать.',
    ),
  ],
  afterPhrase: 'Ты сделала самое исследованное упражнение от паники в мире. '
      'И оно работает.',
  icon: Icons.air_outlined,
  accent: AppColors.sage,
);

const extendedExhale = SosTechnique(
  breath: (inhale: 4, exhale: 8),
  id: 'extended_exhale',
  title: 'Удлинённый выдох «ффф»',
  triggers: [SosTrigger.anxiety, SosTrigger.panic],
  whenToUse: 'Когда проснулась от плача, чувствуешь раздражение, '
      'или перед сложным разговором.',
  duration: '1 минута',
  steps: [
    TechniqueStep(
      heading: 'Шаг 1',
      body: 'Вдохни носом — 2-3 секунды.',
    ),
    TechniqueStep(
      heading: 'Шаг 2',
      body: 'Выдохни ртом со звуком «фффф» — 6-8 секунд. '
          'Звук должен ощущаться вибрацией.',
    ),
    TechniqueStep(
      heading: 'Шаг 3',
      body: 'Повтори 5-8 раз. Выдох всегда длиннее вдоха.',
    ),
  ],
  afterPhrase: 'Это самый безопасный способ снизить кортизол. Без побочных.',
  icon: Icons.waves_rounded,
  accent: AppColors.sageDeep,
);

const microMovements = SosTechnique(
  id: 'micro_movements',
  title: 'Микродвижения',
  triggers: [SosTrigger.freeze],
  whenToUse: 'Когда ступор, нет сил даже на дыхание. Тело замерло.',
  duration: '1 минута',
  steps: [
    TechniqueStep(
      heading: 'Сядь',
      body: 'Поставь стопы на пол. Прислонись к спинке.',
    ),
    TechniqueStep(
      heading: 'Мизинец правой руки',
      body: 'Согни и разогни мизинец правой руки 5 раз, очень медленно.',
    ),
    TechniqueStep(
      heading: 'Левая бровь',
      body: 'Подними и опусти левую бровь 5 раз.',
    ),
    TechniqueStep(
      heading: 'Кончик носа',
      body: 'Поморщи нос как кролик — 5 раз.',
    ),
    TechniqueStep(
      heading: 'Готово',
      body: 'Ты вернула контроль через крошечное добровольное движение. '
          'Этого достаточно, чтобы выйти из ступора.',
    ),
  ],
  afterPhrase: 'Самое маленькое движение — это уже движение.',
  icon: Icons.pan_tool_rounded,
  accent: AppColors.peach,
);

const nameAndFact = SosTechnique(
  id: 'name_and_fact',
  title: 'Имя + факт',
  triggers: [SosTrigger.rage, SosTrigger.shame],
  whenToUse: 'Когда вот-вот накричишь или ударишь — за секунду до срыва. '
      'Прерывает автоматическую реакцию.',
  duration: '30 секунд',
  steps: [
    TechniqueStep(
      heading: 'Скажи вслух (или шёпотом)',
      body: '«Я — [твоё имя]. Сейчас [время] на [место]».\n\n'
          'Например: «Я — Оксана. Сейчас 15:20, я на кухне, на столе красная чашка».',
    ),
    TechniqueStep(
      heading: 'Один шаг назад',
      body: 'Сразу — один физический шаг назад или в сторону. '
          'Тело должно сдвинуться.',
    ),
    TechniqueStep(
      heading: 'Теперь — ответь',
      body: 'Теперь можешь реагировать. Между триггером и реакцией '
          'появилась пауза, в которой ты выбираешь.',
    ),
  ],
  afterPhrase: 'Ты не сдержала боль — ты выбрала, как с ней быть.',
  icon: Icons.record_voice_over_rounded,
  accent: AppColors.coral,
);

const detective = SosTechnique(
  id: 'detective',
  title: 'Детектив',
  triggers: [SosTrigger.anxiety, SosTrigger.freeze],
  whenToUse: 'Когда зацикливаешься на диагнозе, неудачах терапии, '
      'бесконечных «а если…».',
  duration: '1 минута',
  steps: [
    TechniqueStep(
      heading: 'Выбери предмет',
      body: 'Выбери любой объект в комнате. Кружка, лампа, цветок.',
    ),
    TechniqueStep(
      heading: 'Найди 5 деталей',
      body: 'В течение минуты найди в нём 5 необычных деталей: '
          'скол на ободке, отражение окна, следы пальцев, блик, трещинку.',
    ),
    TechniqueStep(
      heading: 'Если мысль возвращается',
      body: 'Возвращай внимание к объекту со словами: '
          '«Это потом, сейчас — скол на кружке».',
    ),
  ],
  afterPhrase: 'Ты загрузила зрительную кору — тревожная петля прервалась.',
  icon: Icons.search_rounded,
  accent: AppColors.saffron,
);

// ──────────────── Из ресёрча клинических источников ────────────────

const butterflyHug = SosTechnique(
  id: 'butterfly_hug',
  title: 'Крылья бабочки',
  triggers: [SosTrigger.shame, SosTrigger.freeze],
  whenToUse: 'После того как накричала на ребёнка. Когда внутренний голос '
      'говорит «я плохая мать». Можно делать рядом с ребёнком — '
      'выглядит как самообъятие.',
  duration: '1-2 минуты',
  steps: [
    TechniqueStep(
      heading: 'Скрести руки',
      body: 'Скрести руки на груди — ладони на противоположных плечах. '
          'Получится самообъятие.',
    ),
    TechniqueStep(
      heading: 'Закрой глаза или смягчи взгляд',
      body: 'Если рядом ребёнок — можно просто опустить взгляд.',
    ),
    TechniqueStep(
      heading: 'Постукивай по очереди',
      body: 'Медленно, по очереди — левой ладонью, потом правой, '
          'потом левой… Примерно один раз в секунду.',
    ),
    TechniqueStep(
      heading: 'Скажи себе',
      body: 'Можно про себя или вслух: «Я с собой. Это пройдёт». '
          'Продолжай 30-60 секунд.',
    ),
  ],
  afterPhrase: 'Это техника из EMDR-терапии. Она снижает заряд тяжёлых мыслей. '
      'Ты только что обняла себя — буквально.',
  icon: Icons.front_hand_rounded,
  accent: AppColors.peach,
);

const coldWater = SosTechnique(
  id: 'cold_water',
  title: 'Холод на лицо',
  triggers: [SosTrigger.panic, SosTrigger.rage],
  whenToUse: 'На самом пике паники или гнева. Когда «вот-вот сорвусь» '
      'или «не могу дышать». Включает «нырковый рефлекс» — мощное '
      'физиологическое торможение.',
  duration: '30-60 секунд',
  steps: [
    TechniqueStep(
      heading: 'Подготовь холод',
      body: 'Налей в миску холодную воду или возьми лёд из морозилки, '
          'обернутый в полотенце.',
    ),
    TechniqueStep(
      heading: 'Выдох до конца',
      body: 'Сделай длинный полный выдох. Задержи дыхание.',
    ),
    TechniqueStep(
      heading: 'Холод к лицу',
      body: 'На 30 секунд: либо опусти лицо в воду, '
          'либо приложи холодный компресс ко лбу, глазам и щекам. '
          'Особенно важно — область вокруг глаз.',
    ),
    TechniqueStep(
      heading: 'Дыши обычно',
      body: 'Через 30 секунд убери холод и дыши спокойно. '
          'При необходимости повтори ещё один раз.',
    ),
  ],
  afterPhrase: 'Это «нырковый рефлекс» — твоё тело замедляет сердце автоматически. '
      'Это не «успокоиться» — это физиология.',
  icon: Icons.ac_unit_rounded,
  accent: AppColors.sage,
  contraindication: 'Не используй при сердечных аритмиях, '
      'если есть проблемы с сердечно-сосудистой системой, '
      'или при истории расстройств пищевого поведения. '
      'Если сомневаешься — выбери другую технику.',
);

const intenseMovement = SosTechnique(
  id: 'intense_movement',
  title: 'Разрядка движением',
  triggers: [SosTrigger.rage, SosTrigger.panic],
  whenToUse: 'Когда хочется кричать, ударить, что-то швырнуть. '
      'Тело требует сжечь адреналин.',
  duration: '30-60 секунд',
  steps: [
    TechniqueStep(
      heading: 'Назови импульс',
      body: 'Скажи себе или вслух: «Я хочу кричать» или «Я хочу ударить». '
          'Не борись — признай.',
    ),
    TechniqueStep(
      heading: '20-30 секунд резкого движения',
      body: 'Выбери одно:\n\n'
          '— прыжки\n— быстрые приседания\n— упор в стену\n'
          '— бег на месте\n— сильно тряси кистями и руками',
    ),
    TechniqueStep(
      heading: 'Длинный выдох',
      body: 'Остановись. Один длинный выдох — и снова дышишь обычно.',
    ),
    TechniqueStep(
      heading: 'Стакан воды',
      body: 'Выпей стакан воды — медленно. Это закроет цикл.',
    ),
  ],
  afterPhrase: 'Ты сожгла адреналин. Это не «избавилась от чувств» — '
      'это завершила цикл стресса (Нагоски). Тело может теперь восстановиться.',
  icon: Icons.directions_run_rounded,
  accent: AppColors.coral,
);

/// Все техники в одном списке.
const allTechniques = <SosTechnique>[
  _existingBreathing,
  physiologicalSigh,
  extendedExhale,
  _existingGrounding,
  microMovements,
  detective,
  _existingSelfCompassion,
  butterflyHug,
  nameAndFact,
  intenseMovement,
  coldWater,
];

/// Группировка по триггеру (для меню SOS).
List<SosTechnique> techniquesForTrigger(SosTrigger t) =>
    allTechniques.where((tech) => tech.triggers.contains(t)).toList();

SosTechnique? techniqueById(String id) {
  for (final t in allTechniques) {
    if (t.id == id) return t;
  }
  return null;
}
