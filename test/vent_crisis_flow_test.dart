import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volna/app/router.dart';
import 'package:volna/core/theme/app_theme.dart';
import 'package:volna/data/local/badges_storage.dart';
import 'package:volna/data/local/checkin_storage.dart';
import 'package:volna/data/local/diary_storage.dart';
import 'package:volna/data/local/quest_storage.dart';
import 'package:volna/data/local/settings_storage.dart';
import 'package:volna/data/local/toolbox_storage.dart';
import 'package:volna/features/vent/crisis_screen.dart';
import 'package:volna/features/vent/vent_response_screen.dart';
import 'package:volna/main.dart' as app;

/// Регрессия: текстовое «Выговорись» — фолбэк, куда приложение само уводит
/// при отсутствии сети и микрофона. Проверка на кризис там отсутствовала,
/// и на «не хочу жить» показывался экран «Похоже, тебе грустно».
void main() {
  // Сторы в main.dart — глобальные `late final`, присвоить их можно один раз,
  // поэтому setUpAll, а не setUp.
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'onboarding_done': true});
    app.questStorage = await QuestStorage.create();
    app.settingsStorage = await SettingsStorage.create();
    app.checkInStorage = await CheckInStorage.create();
    app.diaryStorage = await DiaryStorage.create();
    app.toolBoxStorage = await ToolBoxStorage.create();
    app.badgesStorage = await BadgesStorage.create();
  });

  Future<void> pumpAt(WidgetTester tester, String location) async {
    appRouter.go(location);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: appRouter,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> ventText(WidgetTester tester, String text) async {
    await pumpAt(tester, '/vent/text');
    await tester.enterText(find.byType(TextField), text);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Я выслушаю'));
    await tester.pumpAndSettle();
  }

  testWidgets('кризисная фраза текстом ведёт на кризисный экран', (
    tester,
  ) async {
    await ventText(tester, 'сил больше нет, я не хочу жить');

    expect(find.byType(CrisisScreen), findsOneWidget);
    expect(find.byType(VentResponseScreen), findsNothing);
    expect(find.text('8-800-2000-122'), findsOneWidget);
  });

  testWidgets('обычная фраза ведёт на обычный ответ', (tester) async {
    await ventText(tester, 'просто очень устала за сегодня');

    expect(find.byType(VentResponseScreen), findsOneWidget);
    expect(find.byType(CrisisScreen), findsNothing);
  });

  testWidgets('с кризисного экрана можно уйти в «другие способы связи» '
      'и вернуться назад', (tester) async {
    await ventText(tester, 'я не хочу жить');

    await tester.tap(find.text('Другие способы связи'));
    await tester.pumpAndSettle();
    expect(find.text('Связь со специалистом'), findsOneWidget);

    // Кнопка «назад» на экране помощи не должна падать:
    // раньше на /help попадали через go(), который затирал стек.
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(CrisisScreen), findsOneWidget);
  });
}
