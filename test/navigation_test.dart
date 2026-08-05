import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volna/core/theme/app_theme.dart';
import 'package:volna/core/widgets/app_bottom_bar.dart';
import 'package:volna/features/more/more_screen.dart';

/// Сторожит навигацию: выход в кризисные техники, узкие экраны и то,
/// что разделы не уезжают обратно под шестерёнку.
void main() {
  Widget wrap(Widget child, {double width = 390, bool dark = false}) {
    return MaterialApp(
      theme: dark ? AppTheme.dark() : AppTheme.light(),
      home: Scaffold(body: Center(child: SizedBox(width: width, child: child))),
    );
  }

  group('Нижний бар', () {
    // 320 px — iPhone SE. «Выговориться» — самая длинная подпись,
    // ради неё в баре стоит FittedBox.
    for (final width in const [320.0, 360.0, 375.0, 430.0]) {
      testWidgets('помещается в ${width.toInt()} px', (tester) async {
        await tester.pumpWidget(
          wrap(
            AppBottomBar(currentIndex: 0, onSelect: (_) {}, onSos: () {}),
            width: width,
          ),
        );
        await tester.pump();

        expect(
          tester.takeException(),
          isNull,
          reason: 'бар не должен переполнять строку',
        );
        for (final t in AppBottomBar.tabs) {
          expect(find.text(t.label), findsOneWidget);
        }
      });
    }

    testWidgets('кнопка «Плохо» не меньше 56×56 даже на 320 px',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          AppBottomBar(currentIndex: 0, onSelect: (_) {}, onSos: () {}),
          width: 320,
        ),
      );
      await tester.pump();

      final size = tester.getSize(find.byType(SosCapsule));
      expect(size.width, greaterThanOrEqualTo(56));
      expect(size.height, greaterThanOrEqualTo(56));
    });

    testWidgets('кнопка «Плохо» отделена от вкладок и зовёт наружу',
        (tester) async {
      var sos = 0;
      var selected = -1;
      await tester.pumpWidget(
        wrap(
          AppBottomBar(
            currentIndex: 0,
            onSelect: (i) => selected = i,
            onSos: () => sos++,
          ),
        ),
      );
      await tester.tap(find.byType(SosCapsule));
      await tester.pump();

      expect(sos, 1);
      expect(
        selected,
        -1,
        reason: 'кризисный выход не должен переключать вкладку',
      );
    });

    testWidgets('на вкладках нет ни одной цифры', (tester) async {
      await tester.pumpWidget(
        wrap(AppBottomBar(currentIndex: 2, onSelect: (_) {}, onSos: () {})),
      );
      await tester.pump();

      final digits = RegExp(r'\d');
      for (final w in tester.widgetList<Text>(find.byType(Text))) {
        final text = w.data ?? '';
        expect(
          digits.hasMatch(text),
          isFalse,
          reason: 'счётчиков в баре быть не может: «$text»',
        );
      }
    });

    testWidgets('переключение вкладки отдаёт индекс', (tester) async {
      var selected = -1;
      await tester.pumpWidget(
        wrap(
          AppBottomBar(
            currentIndex: 0,
            onSelect: (i) => selected = i,
            onSos: () {},
          ),
        ),
      );
      await tester.tap(find.text('Дневник'));
      await tester.pump();

      expect(selected, 2);
    });

    testWidgets('живёт в тёмной теме', (tester) async {
      await tester.pumpWidget(
        wrap(
          AppBottomBar(currentIndex: 1, onSelect: (_) {}, onSos: () {}),
          dark: true,
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(SosCapsule), findsOneWidget);
    });
  });

  group('«Ещё» собирает всё, что не вкладка', () {
    testWidgets('показывает разделы, вытащенные из настроек',
        (tester) async {
      // ListView ленивый: на короткой поверхности нижние группы просто
      // не построятся, и проверка станет ложноотрицательной.
      tester.view.physicalSize = const Size(1170, 6000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light(), home: const MoreScreen()),
      );
      await tester.pump();

      for (final title in const [
        'Древо',
        'Календарь',
        'Что я заметила',
        'Библиотека',
        'Опросники',
        'Специалист',
        'Знаки присутствия',
        'Настройки',
      ]) {
        expect(find.text(title), findsOneWidget, reason: 'нет пункта «$title»');
      }
    });

    test('каждый пункт ведёт на существующий маршрут', () {
      final router = File('lib/app/router.dart').readAsStringSync();
      for (final g in MoreScreen.groups) {
        for (final e in g.entries) {
          expect(
            router.contains("'${e.route}'"),
            isTrue,
            reason: 'маршрут ${e.route} не объявлен в роутере',
          );
        }
      }
    });
  });

  group('Разделы не возвращаются под шестерёнку', () {
    test('настройки больше не прячут календарь, инсайты и опросники', () {
      final settings =
          File('lib/features/settings/settings_screen.dart').readAsStringSync();
      for (final route in const ['/insights', '/questionnaire', '/calendar']) {
        expect(
          settings.contains("push('$route')"),
          isFalse,
          reason: '$route снова похоронен в настройках',
        );
      }
    });
  });
}
