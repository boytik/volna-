import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volna/core/theme/app_theme.dart';
import 'package:volna/core/widgets/app_bottom_bar.dart';

/// Сторожит навигацию: что главный вход не уехал, что узкие экраны
/// не ломаются и что ни один раздел не остался без входа.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget wrap(Widget child, {double width = 390, bool dark = false}) {
    return MaterialApp(
      theme: dark ? AppTheme.dark() : AppTheme.light(),
      home: Scaffold(body: Center(child: SizedBox(width: width, child: child))),
    );
  }

  group('Нижний бар', () {
    // 320 px — iPhone SE. «Настройки» и «Практики» — самые длинные
    // подписи, ради них в баре стоит FittedBox.
    for (final width in const [320.0, 360.0, 375.0, 430.0]) {
      testWidgets('помещается в ${width.toInt()} px', (tester) async {
        await tester.pumpWidget(
          wrap(AppBottomBar(currentIndex: 0, onSelect: (_) {}), width: width),
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

    test('вкладок ровно четыре и «Практики» третьи', () {
      expect(AppBottomBar.tabs.length, 4);
      expect(AppBottomBar.practicesIndex, 2);
      expect(AppBottomBar.tabs[AppBottomBar.practicesIndex].label, 'Практики');
    });

    testWidgets('«Практики» — единственная заливка в баре', (tester) async {
      await tester.pumpWidget(
        wrap(AppBottomBar(currentIndex: 0, onSelect: (_) {})),
      );
      await tester.pump();

      // Material с непрозрачным цветом внутри бара должен быть один:
      // главный вход находится по цвету, а не чтением подписей.
      // Считаем только внутри бара: Scaffold снаружи тоже Material.
      final filled = tester
          .widgetList<Material>(
            find.descendant(
              of: find.byType(AppBottomBar),
              matching: find.byType(Material),
            ),
          )
          .where((m) => m.color != null && m.color != Colors.transparent)
          .length;
      expect(filled, 1, reason: 'заливок в баре должно быть ровно одна');
    });

    testWidgets('на вкладках нет ни одной цифры', (tester) async {
      await tester.pumpWidget(
        wrap(AppBottomBar(currentIndex: 2, onSelect: (_) {})),
      );
      await tester.pump();

      final digits = RegExp(r'\d');
      for (final w in tester.widgetList<Text>(find.byType(Text))) {
        expect(
          digits.hasMatch(w.data ?? ''),
          isFalse,
          reason: 'счётчиков в баре быть не может: «${w.data}»',
        );
      }
    });

    testWidgets('каждая вкладка отдаёт свой индекс', (tester) async {
      var selected = -1;
      await tester.pumpWidget(
        wrap(AppBottomBar(currentIndex: 0, onSelect: (i) => selected = i)),
      );

      for (var i = 0; i < AppBottomBar.tabs.length; i++) {
        await tester.tap(find.text(AppBottomBar.tabs[i].label));
        await tester.pump();
        expect(selected, i);
      }
    });

    testWidgets('живёт в тёмной теме', (tester) async {
      await tester.pumpWidget(
        wrap(AppBottomBar(currentIndex: 2, onSelect: (_) {}), dark: true),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Ни один раздел не остался без входа', () {
    String read(String p) => File(p).readAsStringSync();

    test('«Практики» держат библиотеку и специалиста', () {
      final s = read('lib/features/practices/practices_screen.dart');
      expect(s.contains("'/library'"), isTrue);
      expect(s.contains("'/help'"), isTrue);
    });

    test('«Путь» держит опросники и «что я заметила»', () {
      final s = read('lib/features/path/path_screen.dart');
      expect(s.contains("'/insights'"), isTrue);
      expect(s.contains("'/questionnaire'"), isTrue);
    });

    test('«Путь» вобрал календарь и знаки присутствия', () {
      final s = read('lib/features/path/path_screen.dart');
      expect(s.contains('badge_data.allBadges'), isTrue,
          reason: 'знаки должны рисоваться прямо здесь, а не ссылкой');
      expect(s.contains('_MonthGrid'), isTrue,
          reason: 'календарь должен рисоваться прямо здесь');
    });

    test('на главной есть вход в «Путь» и никаких иконок-разделов', () {
      final s = read('lib/features/home/home_screen.dart');
      expect(s.contains("'/path'"), isTrue);
      // Пять иконок уехали в бар: если какая-то вернётся сюда, шапка
      // снова начнёт разъезжаться на узких экранах.
      for (final gone in const [
        "'/badges'",
        "'/help'",
        "'/library'",
        "'/settings'",
        "'/diary'",
      ]) {
        expect(
          s.contains(gone),
          isFalse,
          reason: '$gone вернулся иконкой в шапку — ему место в баре',
        );
      }
    });

    test('дневник держит оба входа в «выговориться»', () {
      final s = read('lib/features/diary/diary_list_screen.dart');
      expect(s.contains("'/vent'"), isTrue);
      expect(s.contains("'/vent/text'"), isTrue);
    });

    test('старые адреса ведут туда, где содержимое теперь живёт', () {
      final r = read('lib/app/router.dart');
      for (final pair in const [
        ["'/sos'", "'/practices'"],
        ["'/calendar'", "'/path'"],
        ["'/badges'", "'/path'"],
      ]) {
        expect(
          RegExp("path: ${pair[0]}, redirect: .*${pair[1]}").hasMatch(r),
          isTrue,
          reason: '${pair[0]} должен вести на ${pair[1]}',
        );
      }
    });
  });

  group('Разделы не возвращаются под шестерёнку', () {
    test('настройки не прячут календарь, инсайты и опросники', () {
      final s =
          File('lib/features/settings/settings_screen.dart').readAsStringSync();
      for (final route in const ['/insights', '/questionnaire', '/calendar']) {
        expect(
          s.contains("push('$route')"),
          isFalse,
          reason: '$route снова похоронен в настройках',
        );
      }
    });
  });
}
