import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volna/data/content/questionnaires.dart';
import 'package:volna/data/local/questionnaire_storage.dart';

/// Экран результата обещает сравнение с прошлым разом — значит история
/// должна где-то жить. Раньше сохранялся только флаг «опросник пройден».
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  QuestionnaireResult resultOf(QuestionnaireKind kind, int score) =>
      QuestionnaireResult(
        kind: kind,
        score: score,
        maxScore: 80,
        zone: ResultZone.medium,
      );

  test('первое прохождение — сравнивать не с чем', () async {
    final storage = await QuestionnaireStorage.create();
    await storage.add(resultOf(QuestionnaireKind.pss, 40));

    expect(storage.previousOf(QuestionnaireKind.pss), isNull);
    expect(storage.lastOf(QuestionnaireKind.pss)?.score, 40);
  });

  test('второе прохождение видит первое', () async {
    final storage = await QuestionnaireStorage.create();
    await storage.add(
      resultOf(QuestionnaireKind.pss, 40),
      takenAt: DateTime(2026, 7, 20),
    );
    await storage.add(
      resultOf(QuestionnaireKind.pss, 30),
      takenAt: DateTime(2026, 8, 4),
    );

    expect(storage.lastOf(QuestionnaireKind.pss)?.score, 30);
    expect(storage.previousOf(QuestionnaireKind.pss)?.score, 40);
  });

  test('опросники не путаются между собой', () async {
    final storage = await QuestionnaireStorage.create();
    await storage.add(resultOf(QuestionnaireKind.pss, 40));
    await storage.add(resultOf(QuestionnaireKind.csi, 9));

    expect(storage.previousOf(QuestionnaireKind.pss), isNull);
    expect(storage.ofKind(QuestionnaireKind.csi), hasLength(1));
  });

  test('история переживает перезапуск приложения', () async {
    final first = await QuestionnaireStorage.create();
    await first.add(resultOf(QuestionnaireKind.pbi, 100));

    final afterRestart = await QuestionnaireStorage.create();
    expect(afterRestart.lastOf(QuestionnaireKind.pbi)?.score, 100);
  });

  test('битые данные не роняют экран', () async {
    SharedPreferences.setMockInitialValues({
      'questionnaire_history': 'не json',
    });
    final storage = await QuestionnaireStorage.create();
    expect(storage.all(), isEmpty);
  });
}
