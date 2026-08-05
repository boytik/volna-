/// Жёсткий слой детекции кризиса.
/// Регулярки на русском с морфологией — простые подстроки, чтобы тест был детерминированным.
/// Любое совпадение прерывает обычный поток и ведёт на crisis-экран.
///
/// Принцип (из исследования harm-cases — Tessa, Character.AI):
/// детерминированный слой ДО любых LLM-обработок.
/// LLM не должна решать, кризис это или нет.
library;

class CrisisDetector {
  /// Возвращает категорию кризиса или null.
  static CrisisCategory? detect(String text) {
    final t = text.toLowerCase();

    if (_anyMatch(t, _suicideStems)) return CrisisCategory.suicide;
    if (_anyMatch(t, _selfHarmStems)) return CrisisCategory.selfHarm;
    if (_anyMatch(t, _childHarmStems)) return CrisisCategory.childHarm;
    if (_anyMatch(t, _abuseStems)) return CrisisCategory.abuse;

    return null;
  }

  static bool _anyMatch(String text, List<String> stems) {
    for (final s in stems) {
      if (text.contains(s)) return true;
    }
    return false;
  }
}

enum CrisisCategory {
  suicide,
  selfHarm,
  childHarm,
  abuse,
}

extension CrisisCategoryExt on CrisisCategory {
  String get label {
    switch (this) {
      case CrisisCategory.suicide:
        return 'Сейчас важно поговорить с человеком';
      case CrisisCategory.selfHarm:
        return 'Сейчас важно поговорить с человеком';
      case CrisisCategory.childHarm:
        return 'Сейчас важно поговорить с человеком';
      case CrisisCategory.abuse:
        return 'Сейчас важно поговорить с человеком';
    }
  }

  String get body {
    switch (this) {
      case CrisisCategory.suicide:
      case CrisisCategory.selfHarm:
        return 'Я ИИ. Я выслушаю, но рядом с твоей болью '
            'должен быть живой человек, который умеет больше. '
            'Один звонок — и ты не одна.';
      case CrisisCategory.childHarm:
        return 'То, что ты описываешь, очень тяжело. '
            'Не из-за того, что ты плохая — наоборот, потому что ты '
            'разрешила себе это заметить. Сейчас нужен человек.';
      case CrisisCategory.abuse:
        return 'То, что происходит, не должно происходить. '
            'Тебе нужна не техника из приложения, а живая помощь.';
    }
  }
}

const _suicideStems = [
  'убить себя',
  'убью себя',
  'покончить с собой',
  'не хочу жить',
  'не хочется жить',
  'жить не хочу',
  'жить не хочется',
  'лучше бы меня не было',
  'свести счёты',
  'свести счеты',
  'выпрыгнуть',
  'выйти в окно',
  'спрыгнуть',
  'вены',
  'таблеток сразу',
  'всех таблеток',
  'передозировк',
  'устала жить',
  'устал жить',
  'умереть хочу',
  'умереть хочется',
];

const _selfHarmStems = [
  'порезать себя',
  'резать себя',
  'ударить себя',
  'бить себя',
  'причинить себе боль',
];

const _childHarmStems = [
  'убью его',
  'убью её',
  'хочу убить ребёнк',
  'хочу убить ребенк',
  'убить ребёнк',
  'убить ребенк',
  'ударю ребёнк',
  'ударю ребенк',
  'избить ребёнк',
  'избить ребенк',
  'причинить ему боль',
  'причинить ей боль',
  'выкинуть ребёнк',
  'выкинуть ребенк',
  'избавиться от ребёнк',
  'избавиться от ребенк',
];

const _abuseStems = [
  'он меня бьёт',
  'он меня бьет',
  'он бьёт ребёнк',
  'он бьет ребенк',
  'муж меня бьёт',
  'муж меня бьет',
  'мне угрожают',
  'боюсь домой',
];
