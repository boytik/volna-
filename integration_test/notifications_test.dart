// Smoke-проверка уведомлений на реальном iOS-рантайме (симулятор).
//
// Что тут проверяется: весь путь планирования отрабатывает на настоящем
// плагине flutter_local_notifications и iOS-рантайме, не бросая исключений, —
// приложение стартует, ежедневные напоминания перепланируются, конверт тревоги
// ставится, всё снимается. Доставку и точный состав pending здесь не проверяем:
// на iOS без выданного разрешения система тихо не регистрирует уведомления, а
// системный диалог из теста не нажать. Логика «что именно планируется» покрыта
// детерминированным test/notification_scheduling_test.dart на моке канала.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:volna/main.dart' as app;
import 'package:volna/main.dart' show notificationService, settingsStorage;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('путь планирования отрабатывает на реальном рантайме',
      (tester) async {
    await app.main();
    await tester.pump(const Duration(seconds: 1));

    // Включаем и перепланируем — как экран настроек.
    await settingsStorage.setNotificationsEnabled(true);
    await settingsStorage.setMorningHour(8);
    await settingsStorage.setEveningHour(21);
    await expectLater(notificationService.rescheduleAll(), completes);
    await tester.pump(const Duration(milliseconds: 300));

    // Конверт тревоги — разовый пуш; на инициализированном плагине возвращает
    // валидный id (не -1), то есть zonedSchedule прошёл без ошибки.
    final envelopeId =
        await notificationService.scheduleEnvelopeReopen(after: const Duration(days: 1));
    expect(envelopeId, greaterThan(0),
        reason: 'планирование конверта должно вернуть валидный id');

    // Выключение и полная очистка не бросают.
    await settingsStorage.setNotificationsEnabled(false);
    await expectLater(notificationService.rescheduleAll(), completes);
    await expectLater(notificationService.cancelAll(), completes);
    await tester.pump(const Duration(milliseconds: 300));
  });
}
