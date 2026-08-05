import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volna/core/theme/app_theme.dart';
import 'package:volna/features/home/home_screen.dart';

/// Пять иконок в шапке лежали в Row фиксированной ширины — на узких экранах
/// строка переполнялась (RenderFlex overflow) поверх приветствия.
///
/// После перехода на нижний бар в шапке осталась одна кнопка — знаки
/// присутствия. Проверка на переполнение остаётся: она дешёвая, а строка
/// с меткой времени суток и кнопкой всё ещё может разъехаться, если кто-то
/// вернёт сюда ещё элементов. Защита самого бара — в navigation_test.dart.
void main() {
  // 320 px — iPhone SE 1-го поколения, самый узкий актуальный экран.
  for (final width in const [320.0, 360.0, 375.0, 430.0]) {
    testWidgets('шапка помещается в ${width.toInt()} px', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: const HomeMasthead(isMorning: true),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason: 'шапка не должна переполнять строку',
      );
      expect(find.text('УТРО'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
    });
  }

  testWidgets('в шапке осталась ровно одна кнопка', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: SizedBox(width: 390, child: HomeMasthead(isMorning: false)),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byType(Icon),
      findsOneWidget,
      reason: 'разделы живут в нижнем баре, а не иконками в углу',
    );
  });
}
