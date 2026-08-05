/// Локальный анализатор тона для «Выговорись».
/// Принципы:
/// — лучше пропустить тонкость, чем неверно интерпретировать,
/// — все словари — нормализованные основы (без учёта окончаний по startsWith),
/// — категория «общее» — fallback, всегда даём поддержку.
library;

enum VentTopic { anger, anxiety, exhaustion, guilt, sadness, general }

extension VentTopicExt on VentTopic {
  String get label {
    switch (this) {
      case VentTopic.anger:
        return 'Похоже, ты сейчас злишься';
      case VentTopic.anxiety:
        return 'Похоже, тебе тревожно';
      case VentTopic.exhaustion:
        return 'Похоже, у тебя нет сил';
      case VentTopic.guilt:
        return 'Похоже, ты винишь себя';
      case VentTopic.sadness:
        return 'Похоже, тебе грустно';
      case VentTopic.general:
        return 'Я тебя слышу';
    }
  }

  String get acknowledgement {
    switch (this) {
      case VentTopic.anger:
        return 'Гнев — это сигнал, что что-то очень важное было нарушено. '
            'Ты не плохая, что чувствуешь его.';
      case VentTopic.anxiety:
        return 'Тревога живёт в будущем, которого ещё нет. '
            'Сейчас ты в безопасности — несмотря на то, что внутри.';
      case VentTopic.exhaustion:
        return 'Истощение — не лень, не слабость, не вина. '
            'Это сигнал, что ты слишком долго отдавала без восстановления.';
      case VentTopic.guilt:
        return 'Чувство вины говорит о твоей любви, не о твоей вине. '
            'Ты не плохой родитель — ты родитель в трудный день.';
      case VentTopic.sadness:
        return 'Грусть — это не ошибка. Это иногда правильная реакция '
            'на то, что с тобой происходит.';
      case VentTopic.general:
        return 'Ты пришла, написала, поделилась. '
            'Это уже шаг — даже если внутри ничего не сдвинулось.';
    }
  }
}

/// Корни слов для каждой категории.
/// Сравниваем через `text.contains(stem)` без учёта регистра.
const _angerStems = [
  'бес', 'злюсь', 'злая', 'злость', 'злы', 'ярос', 'ненавиж',
  'достал', 'накричал', 'наорал', 'сорв', 'удар', 'хочу убит',
  'хочется кричат', 'не могу терпет', 'выбе',
];

const _anxietyStems = [
  'тревог', 'страшно', 'боюс', 'боит', 'паник', 'волнуюс',
  'не могу уснут', 'сердце колот', 'не могу дышат', 'трус',
  'а что если', 'катастро', 'будущ',
];

const _exhaustionStems = [
  'устал', 'выжат', 'нет сил', 'не могу больш', 'нет энерг',
  'сил больше нет', 'без сил', 'вымотан', 'выгор', 'опустош',
  'сонн', 'не сплю', 'не выспал',
];

const _guiltStems = [
  'виноват', 'плохая мат', 'плохой родител', 'я плохая',
  'не достойн', 'не справля', 'не получ', 'зря',
  'я ужасна', 'я ужасн', 'стыд', 'стыдно', 'не заслуж',
];

const _sadnessStems = [
  'грустн', 'плач', 'слёз', 'слез', 'тоск', 'безнадёж',
  'безнадеж', 'пуст', 'один', 'одинок', 'никому не нужн',
  'нет смысл', 'хочется плакат',
];

VentTopic detectTopic(String text) {
  final lower = text.toLowerCase();
  if (lower.trim().isEmpty) return VentTopic.general;

  final scores = <VentTopic, int>{
    VentTopic.anger: _count(lower, _angerStems),
    VentTopic.anxiety: _count(lower, _anxietyStems),
    VentTopic.exhaustion: _count(lower, _exhaustionStems),
    VentTopic.guilt: _count(lower, _guiltStems),
    VentTopic.sadness: _count(lower, _sadnessStems),
  };

  VentTopic best = VentTopic.general;
  var maxScore = 0;
  scores.forEach((topic, score) {
    if (score > maxScore) {
      maxScore = score;
      best = topic;
    }
  });

  return maxScore == 0 ? VentTopic.general : best;
}

int _count(String text, List<String> stems) {
  var n = 0;
  for (final s in stems) {
    if (text.contains(s)) n++;
  }
  return n;
}

/// Подбор SOS-техники под тему.
/// Возвращает id техники из sos_techniques.dart или путь к экрану.
class VentSuggestion {
  const VentSuggestion({
    required this.techniqueId,
    required this.techniqueRoute,
    required this.techniqueLabel,
    required this.fallbackPhraseCategoryId,
  });

  final String techniqueId;
  final String techniqueRoute;
  final String techniqueLabel;
  final String fallbackPhraseCategoryId;
}

VentSuggestion suggestionFor(VentTopic t) {
  switch (t) {
    case VentTopic.anger:
      return const VentSuggestion(
        techniqueId: 'intense_movement',
        techniqueRoute: '/sos/technique/intense_movement',
        techniqueLabel: 'Разрядка движением',
        fallbackPhraseCategoryId: 'burnout',
      );
    case VentTopic.anxiety:
      return const VentSuggestion(
        techniqueId: 'physiological_sigh',
        techniqueRoute: '/sos/technique/physiological_sigh',
        techniqueLabel: 'Двойной вдох',
        fallbackPhraseCategoryId: 'anxiety',
      );
    case VentTopic.exhaustion:
      return const VentSuggestion(
        techniqueId: 'extended_exhale',
        techniqueRoute: '/sos/technique/extended_exhale',
        techniqueLabel: 'Удлинённый выдох',
        fallbackPhraseCategoryId: 'burnout',
      );
    case VentTopic.guilt:
      return const VentSuggestion(
        techniqueId: 'butterfly_hug',
        techniqueRoute: '/sos/technique/butterfly_hug',
        techniqueLabel: 'Крылья бабочки',
        fallbackPhraseCategoryId: 'guilt',
      );
    case VentTopic.sadness:
      return const VentSuggestion(
        techniqueId: 'self_compassion',
        techniqueRoute: '/sos/self-compassion',
        techniqueLabel: 'Ладонь на сердце',
        fallbackPhraseCategoryId: 'support',
      );
    case VentTopic.general:
      return const VentSuggestion(
        techniqueId: 'breathing_box',
        techniqueRoute: '/sos/breathing',
        techniqueLabel: 'Дыхание «Квадрат»',
        fallbackPhraseCategoryId: 'support',
      );
  }
}
