/// Профессиональные опросники из ТЗ.
/// PSS — Шкала родительского стресса (16 пунктов, шкала 1–5).
/// PBI — Опросник родительского выгорания (22 пункта, шкала 1–7).
/// CSI — Индекс нагрузки на опекуна (13 пунктов, да/нет).
///
/// ВАЖНО: эти инструменты могут быть триггером.
/// На основании ресёрча: показываем только по явному выбору пользователя,
/// результат в 3 зонах (зелёная/жёлтая/красная), красная зона ВСЕГДА
/// сопровождается кнопками реальной помощи.
library;

enum QuestionnaireKind { pss, pbi, csi }

extension QuestionnaireKindExt on QuestionnaireKind {
  String get title {
    switch (this) {
      case QuestionnaireKind.pss:
        return 'Шкала родительского стресса';
      case QuestionnaireKind.pbi:
        return 'Родительское выгорание';
      case QuestionnaireKind.csi:
        return 'Нагрузка опекуна';
    }
  }

  String get shortTitle {
    switch (this) {
      case QuestionnaireKind.pss:
        return 'PSS';
      case QuestionnaireKind.pbi:
        return 'PBI';
      case QuestionnaireKind.csi:
        return 'CSI';
    }
  }

  String get duration {
    switch (this) {
      case QuestionnaireKind.pss:
        return '5 минут';
      case QuestionnaireKind.pbi:
        return '7 минут';
      case QuestionnaireKind.csi:
        return '3 минуты';
    }
  }

  String get description {
    switch (this) {
      case QuestionnaireKind.pss:
        return 'Помогает увидеть, где напрягает родительская роль. '
            '16 коротких утверждений.';
      case QuestionnaireKind.pbi:
        return 'Покажет, насколько силён родительский синдром выгорания. '
            '22 утверждения.';
      case QuestionnaireKind.csi:
        return 'Быстрый чек на физическую и эмоциональную нагрузку от ухода. '
            '13 вопросов да/нет.';
    }
  }
}

class Questionnaire {
  const Questionnaire({
    required this.kind,
    required this.items,
    required this.scaleType,
  });

  final QuestionnaireKind kind;
  final List<QuestionnaireItem> items;
  final QuestionnaireScale scaleType;
}

enum QuestionnaireScale {
  /// 1-5 (PSS)
  agreeFive,
  /// 1-7 (PBI)
  frequencySeven,
  /// yes/no (CSI)
  yesNo,
}

class QuestionnaireItem {
  const QuestionnaireItem({
    required this.id,
    required this.text,
    this.reverse = false,
  });

  final int id;
  final String text;
  /// Если true — балл инвертируется при подсчёте.
  final bool reverse;
}

const pssQuestionnaire = Questionnaire(
  kind: QuestionnaireKind.pss,
  scaleType: QuestionnaireScale.agreeFive,
  items: [
    QuestionnaireItem(id: 1, text: 'Я чувствую напряжение и подавленность из-за ответственности быть родителем'),
    QuestionnaireItem(id: 2, text: 'Рождение детей привело к ограничению выбора и контроля над моей жизнью'),
    QuestionnaireItem(id: 3, text: 'Мне сложно совмещать разные обязанности из-за ребёнка'),
    QuestionnaireItem(id: 4, text: 'Рождение ребёнка отрицательно сказалось на моём финансовом благосостоянии'),
    QuestionnaireItem(id: 5, text: 'Если бы мне пришлось пройти через это снова, возможно, я бы решила не заводить детей'),
    QuestionnaireItem(id: 6, text: 'Я часто смущаюсь или нервничаю из-за поведения ребёнка'),
    QuestionnaireItem(id: 7, text: 'Наличие ребёнка ограничило личное время и свободу в моей жизни'),
    QuestionnaireItem(id: 8, text: 'Мой ребёнок — основной источник стресса в моей жизни'),
    QuestionnaireItem(id: 9, text: 'Мне нравится проводить время со своим ребёнком', reverse: true),
    QuestionnaireItem(id: 10, text: 'Мне нравится быть родителем', reverse: true),
    QuestionnaireItem(id: 11, text: 'Я чувствую сильную привязанность к своему ребёнку', reverse: true),
    QuestionnaireItem(id: 12, text: 'Я считаю своего ребёнка замечательным', reverse: true),
    QuestionnaireItem(id: 13, text: 'Я сделаю всё ради своего ребёнка, если это необходимо', reverse: true),
    QuestionnaireItem(id: 14, text: 'У нас близкие, доверительные отношения с ребёнком', reverse: true),
    QuestionnaireItem(id: 15, text: 'Я более уверенно и оптимистично смотрю в будущее, потому что у меня есть ребёнок', reverse: true),
    QuestionnaireItem(id: 16, text: 'Я довольна собой в качестве родителя', reverse: true),
  ],
);

const pbiQuestionnaire = Questionnaire(
  kind: QuestionnaireKind.pbi,
  scaleType: QuestionnaireScale.frequencySeven,
  items: [
    QuestionnaireItem(id: 1, text: 'К концу дня с ребёнком я чувствую себя эмоционально опустошённой'),
    QuestionnaireItem(id: 2, text: 'К концу дня я как выжатый лимон'),
    QuestionnaireItem(id: 3, text: 'Я чувствую усталость, когда встаю утром и должна провести весь день с ребёнком'),
    QuestionnaireItem(id: 4, text: 'Я хорошо понимаю, что чувствует мой ребёнок, и это помогает мне', reverse: true),
    QuestionnaireItem(id: 5, text: 'Я общаюсь с ребёнком формально, без эмоций, и стремлюсь свести общение к минимуму'),
    QuestionnaireItem(id: 6, text: 'Я чувствую себя энергичной и эмоционально воодушевлённой', reverse: true),
    QuestionnaireItem(id: 7, text: 'Я умею находить правильное решение в конфликтах с ребёнком', reverse: true),
    QuestionnaireItem(id: 8, text: 'Я чувствую угнетённость и апатию'),
    QuestionnaireItem(id: 9, text: 'Я могу продуктивно влиять на развитие и успехи ребёнка', reverse: true),
    QuestionnaireItem(id: 10, text: 'Я стала более отстранённой и бесчувственной к ребёнку'),
    QuestionnaireItem(id: 11, text: 'Мой ребёнок стал мне неинтересен. Он скорее утомляет, чем радует'),
    QuestionnaireItem(id: 12, text: 'У меня много планов на будущее в связи с развитием детей, и я верю в них', reverse: true),
    QuestionnaireItem(id: 13, text: 'У меня всё больше жизненных разочарований в сфере семьи'),
    QuestionnaireItem(id: 14, text: 'Я чувствую равнодушие и потерю интереса ко многому'),
    QuestionnaireItem(id: 15, text: 'Мне безразлично, что думает и чувствует мой ребёнок'),
    QuestionnaireItem(id: 16, text: 'Мне хочется уединиться и отдохнуть от всего и всех'),
    QuestionnaireItem(id: 17, text: 'Я легко создаю атмосферу доброжелательности при общении с ребёнком', reverse: true),
    QuestionnaireItem(id: 18, text: 'Я без напряжения общаюсь с ребёнком, независимо от ситуации', reverse: true),
    QuestionnaireItem(id: 19, text: 'Я довольна своими успехами как родитель', reverse: true),
    QuestionnaireItem(id: 20, text: 'Я чувствую себя на пределе возможностей'),
    QuestionnaireItem(id: 21, text: 'Я смогу ещё много сделать в своей жизни как родитель', reverse: true),
    QuestionnaireItem(id: 22, text: 'Я проявляю больше внимания к ребёнку, чем получаю благодарности в ответ'),
  ],
);

const csiQuestionnaire = Questionnaire(
  kind: QuestionnaireKind.csi,
  scaleType: QuestionnaireScale.yesNo,
  items: [
    QuestionnaireItem(id: 1, text: 'У тебя нарушен сон?'),
    QuestionnaireItem(id: 2, text: 'Уход за ребёнком стал неудобным?'),
    QuestionnaireItem(id: 3, text: 'Уход ограничивает твоё личное время?'),
    QuestionnaireItem(id: 4, text: 'Уход ограничивает твоё социальное взаимодействие?'),
    QuestionnaireItem(id: 5, text: 'Ты испытываешь физическое напряжение?'),
    QuestionnaireItem(id: 6, text: 'Ты испытываешь эмоциональное напряжение?'),
    QuestionnaireItem(id: 7, text: 'Семейная жизнь изменилась в худшую сторону?'),
    QuestionnaireItem(id: 8, text: 'Возникли проблемы на работе?'),
    QuestionnaireItem(id: 9, text: 'Возникли финансовые трудности?'),
    QuestionnaireItem(id: 10, text: 'Ты чувствуешь себя подавленной?'),
    QuestionnaireItem(id: 11, text: 'Ты чувствуешь, что полностью поглощена заботой о ребёнке?'),
    QuestionnaireItem(id: 12, text: 'Уход за ребёнком ощущается как бремя?'),
    QuestionnaireItem(id: 13, text: 'Тебе пришлось вносить изменения в свои планы?'),
  ],
);

Questionnaire questionnaireOf(QuestionnaireKind k) {
  switch (k) {
    case QuestionnaireKind.pss:
      return pssQuestionnaire;
    case QuestionnaireKind.pbi:
      return pbiQuestionnaire;
    case QuestionnaireKind.csi:
      return csiQuestionnaire;
  }
}

/// Расчёт интерпретации.
class QuestionnaireResult {
  const QuestionnaireResult({
    required this.kind,
    required this.score,
    required this.maxScore,
    required this.zone,
  });

  final QuestionnaireKind kind;
  final int score;
  final int maxScore;
  final ResultZone zone;

  double get percent => score / maxScore;
}

/// Зоны интерпретации.
/// Цель: НЕ возвращать сырой балл и медицинский диагноз.
/// Возвращаем фразу-ориентир + зону для UI.
enum ResultZone { low, medium, high }

/// Считает результат + определяет зону.
QuestionnaireResult computeResult(
  Questionnaire q,
  Map<int, int> answers,
) {
  var score = 0;
  var answered = 0;

  for (final item in q.items) {
    final raw = answers[item.id];
    // Пропущенный пункт не считаем вовсе. Раньше здесь стоял `?? 0`, но 0 —
    // не валидный ответ на шкалах 1–5 и 1–7: для обратного пункта
    // _reverseScore(0) давал 6 при максимуме 5, то есть пропуск не занижал,
    // а завышал балл выше теоретического максимума.
    if (raw == null) continue;
    answered++;

    if (q.scaleType == QuestionnaireScale.yesNo) {
      score += raw.clamp(0, 1);
      continue;
    }

    final clamped = raw.clamp(1, _scaleMax(q.scaleType));
    score += item.reverse ? _reverseScore(clamped, q.scaleType) : clamped;
  }

  // Долю считаем от того, на что человек реально ответил, — иначе неполный
  // опросник всегда выглядел бы благополучнее, чем есть.
  final maxScore = _maxScore(q, answered == 0 ? q.items.length : answered);
  final percent = maxScore == 0 ? 0.0 : score / maxScore;

  ResultZone zone;
  if (q.kind == QuestionnaireKind.csi) {
    // Пороговое значение CSI: 7+ → высокая нагрузка.
    if (score >= 7) {
      zone = ResultZone.high;
    } else if (score >= 4) {
      zone = ResultZone.medium;
    } else {
      zone = ResultZone.low;
    }
  } else {
    if (percent >= 0.65) {
      zone = ResultZone.high;
    } else if (percent >= 0.45) {
      zone = ResultZone.medium;
    } else {
      zone = ResultZone.low;
    }
  }

  return QuestionnaireResult(
    kind: q.kind,
    score: score,
    maxScore: maxScore,
    zone: zone,
  );
}

int _scaleMax(QuestionnaireScale scale) {
  switch (scale) {
    case QuestionnaireScale.agreeFive:
      return 5;
    case QuestionnaireScale.frequencySeven:
      return 7;
    case QuestionnaireScale.yesNo:
      return 1;
  }
}

int _reverseScore(int raw, QuestionnaireScale scale) {
  switch (scale) {
    case QuestionnaireScale.agreeFive:
      return 6 - raw; // 1↔5, 2↔4, 3=3
    case QuestionnaireScale.frequencySeven:
      return 8 - raw;
    case QuestionnaireScale.yesNo:
      return raw == 0 ? 1 : 0;
  }
}

int _maxScore(Questionnaire q, int itemCount) =>
    itemCount * _scaleMax(q.scaleType);
