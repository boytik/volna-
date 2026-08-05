import 'package:flutter_test/flutter_test.dart';
import 'package:volna/data/content/crisis_keywords.dart';

/// Детектор кризиса — единственный детерминированный слой защиты перед LLM.
/// Ложноотрицательное срабатывание здесь стоит дороже всего остального в проекте,
/// поэтому набор фраз фиксируем тестами.
void main() {
  group('CrisisDetector — суицидальные маркеры', () {
    const phrases = [
      'я не хочу жить',
      'иногда думаю покончить с собой',
      'лучше бы меня не было',
      'устала жить, честное слово',
      'хочу выйти в окно',
      'думаю выпить всех таблеток',
      'жить не хочется совсем',
    ];

    for (final p in phrases) {
      test('«$p» → suicide', () {
        expect(CrisisDetector.detect(p), CrisisCategory.suicide);
      });
    }
  });

  group('CrisisDetector — остальные категории', () {
    test('самоповреждение', () {
      expect(
        CrisisDetector.detect('хочется резать себя чтобы отпустило'),
        CrisisCategory.selfHarm,
      );
    });

    test('угроза ребёнку', () {
      expect(
        CrisisDetector.detect('боюсь, что ударю ребёнка'),
        CrisisCategory.childHarm,
      );
    });

    test('насилие в семье', () {
      expect(
        CrisisDetector.detect('муж меня бьёт, я не знаю что делать'),
        CrisisCategory.abuse,
      );
    });
  });

  group('CrisisDetector — регистр и пунктуация', () {
    test('верхний регистр распознаётся', () {
      expect(CrisisDetector.detect('Я НЕ ХОЧУ ЖИТЬ'), CrisisCategory.suicide);
    });

    test('фраза внутри длинного текста распознаётся', () {
      const text = 'сегодня опять весь день одна с ним, накричала, потом '
          'сидела на кухне и думала что не хочу жить, потом стало легче';
      expect(CrisisDetector.detect(text), CrisisCategory.suicide);
    });

    test('обе формы «ё»/«е» распознаются', () {
      expect(
        CrisisDetector.detect('свести счеты'),
        CrisisCategory.suicide,
      );
      expect(
        CrisisDetector.detect('свести счёты'),
        CrisisCategory.suicide,
      );
    });
  });

  group('CrisisDetector — обычная усталость не считается кризисом', () {
    const ordinary = [
      '',
      'просто очень устала сегодня',
      'опять накричала на него, чувствую себя дрянью',
      'не высыпаюсь уже месяц',
      'тревожно перед завтрашним занятием',
      'мне грустно и пусто',
      'ненавижу эти истерики в магазине',
    ];

    for (final p in ordinary) {
      test('«$p» → без кризиса', () {
        expect(CrisisDetector.detect(p), isNull);
      });
    }
  });
}
