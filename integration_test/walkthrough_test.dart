// Живой проход по приложению на симуляторе — тапы инжектит движок Flutter,
// поэтому это работает без системных разрешений macOS. Проверяем главное, что
// менялось по просьбе заказчицы: онбординг доходит до конца, а опросники теперь
// открываются из «Настроек».
//
// Важно: pumpAndSettle нельзя использовать внутри оболочки. StatefulShellRoute
// .indexedStack держит все корни вкладок смонтированными, а «Практики» содержат
// BreathingHorizon с бесконечной анимацией — дерево никогда не «оседает».
// Поэтому после онбординга двигаемся только через pump() с паузами.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:volna/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('онбординг → Настройки → опросники открываются', (tester) async {
    await app.main();
    // Онбординг статичен (бесконечных анимаций нет) — тут pumpAndSettle можно.
    await tester.pumpAndSettle();

    // «Пропустить» без выбора якоря — так не всплывает системный диалог
    // разрешения на уведомления (его из теста не нажать).
    expect(find.text('Пропустить'), findsOneWidget,
        reason: 'старт должен быть на онбординге');
    await tester.tap(find.text('Пропустить'));
    // Переход на главную (оболочку). Дальше только pump с паузами.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Открываем вкладку «Настройки» из нижнего бара.
    await tester.tap(find.text('Настройки'));
    await tester.pump(const Duration(milliseconds: 600));

    // Секция опросников должна быть в настройках (перенос из «Пути»).
    // ListView — прокручиваем вниз ручными свайпами, пока не покажется ссылка.
    final questionnaireLink = find.text('Пройти опросник');
    final listView = find.byType(Scrollable).first;
    for (var i = 0; i < 6 && questionnaireLink.evaluate().isEmpty; i++) {
      await tester.drag(listView, const Offset(0, -260));
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(questionnaireLink, findsOneWidget,
        reason: 'вход в опросники должен жить в настройках');

    // И он действительно ведёт на список опросников.
    await tester.ensureVisible(questionnaireLink);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(questionnaireLink);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Опросники'), findsWidgets,
        reason: 'после тапа должен открыться список опросников');
  });
}
