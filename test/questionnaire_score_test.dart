import 'package:flutter_test/flutter_test.dart';
import 'package:volna/data/content/questionnaires.dart';

/// Подсчёт опросников. Раньше пропущенный пункт считался за 0, хотя
/// минимальный валидный ответ — 1: для обратного пункта это давало 6 баллов
/// при максимуме 5, и пропуск ЗАВЫШАЛ результат выше теоретического максимума.
void main() {
  Map<int, int> answerAll(Questionnaire q, int value) => {
        for (final item in q.items) item.id: value,
      };

  group('PSS (шкала 1–5, 8 прямых + 8 обратных пунктов)', () {
    final q = pssQuestionnaire;

    test('все ответы «1»: прямые дают 1, обратные — 5', () {
      final r = computeResult(q, answerAll(q, 1));
      // 8 прямых × 1 + 8 обратных × (6−1)=5 → 8 + 40 = 48
      expect(r.score, 48);
      expect(r.maxScore, 16 * 5);
    });

    test('все ответы «5»: прямые дают 5, обратные — 1', () {
      final r = computeResult(q, answerAll(q, 5));
      expect(r.score, 8 * 5 + 8 * 1);
    });

    test('середина шкалы даёт ровно половину', () {
      final r = computeResult(q, answerAll(q, 3));
      expect(r.score, 16 * 3);
    });

    test('балл никогда не превышает максимум', () {
      for (var v = 1; v <= 5; v++) {
        final r = computeResult(q, answerAll(q, v));
        expect(r.score, lessThanOrEqualTo(r.maxScore));
      }
    });
  });

  group('Пропущенные пункты', () {
    final q = pssQuestionnaire;

    test('пропущенный обратный пункт не добавляет 6 баллов', () {
      final answers = answerAll(q, 3);
      // Пункт 9 — обратный («Мне нравится проводить время с ребёнком»).
      answers.remove(9);

      final r = computeResult(q, answers);
      expect(r.score, 15 * 3, reason: 'считаем только отвеченные пункты');
      expect(r.maxScore, 15 * 5, reason: 'максимум тоже по отвеченным');
    });

    test('пропуск не меняет долю, а значит и зону', () {
      final full = computeResult(q, answerAll(q, 3));
      final partial = computeResult(q, answerAll(q, 3)..remove(9));
      expect(partial.percent, closeTo(full.percent, 0.0001));
      expect(partial.zone, full.zone);
    });

    test('пустые ответы не роняют подсчёт делением на ноль', () {
      final r = computeResult(q, {});
      expect(r.score, 0);
      expect(r.percent, 0);
      expect(r.zone, ResultZone.low);
    });
  });

  group('Значения вне шкалы не ломают балл', () {
    test('мусорный ответ подрезается по границам шкалы', () {
      final q = pssQuestionnaire;
      final r = computeResult(q, {for (final i in q.items) i.id: 99});
      expect(r.score, lessThanOrEqualTo(r.maxScore));
    });
  });

  group('CSI (да/нет, порог 7+)', () {
    final q = csiQuestionnaire;

    test('7 «да» — красная зона', () {
      final answers = {
        for (var i = 0; i < q.items.length; i++) q.items[i].id: i < 7 ? 1 : 0,
      };
      final r = computeResult(q, answers);
      expect(r.score, 7);
      expect(r.zone, ResultZone.high);
    });

    test('4 «да» — жёлтая зона', () {
      final answers = {
        for (var i = 0; i < q.items.length; i++) q.items[i].id: i < 4 ? 1 : 0,
      };
      expect(computeResult(q, answers).zone, ResultZone.medium);
    });

    test('все «нет» — зелёная зона', () {
      expect(computeResult(q, answerAll(q, 0)).zone, ResultZone.low);
    });
  });

  group('PBI (шкала 1–7)', () {
    final q = pbiQuestionnaire;

    test('максимум считается по семибалльной шкале', () {
      expect(computeResult(q, answerAll(q, 4)).maxScore, 22 * 7);
    });

    test('обратные пункты инвертируются как 8 − ответ', () {
      final r = computeResult(q, answerAll(q, 1));
      final reverseCount = q.items.where((i) => i.reverse).length;
      final directCount = q.items.length - reverseCount;
      expect(r.score, directCount * 1 + reverseCount * 7);
    });
  });
}
