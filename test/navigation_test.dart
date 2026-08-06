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

    test('вкладок ровно пять, в заданном порядке', () {
      expect(AppBottomBar.tabs.length, 5);
      expect(AppBottomBar.tabs.map((t) => t.label).toList(),
          ['Главная', 'Дневник', 'Практики', 'Специалист', 'Настройки']);
    });

    testWidgets('все вкладки равны — ни одной заливки', (tester) async {
      await tester.pumpWidget(
        wrap(AppBottomBar(currentIndex: 0, onSelect: (_) {})),
      );
      await tester.pump();

      // Внутри бара не должно быть ни одного залитого Material:
      // вкладки различаются только цветом текста и линейкой сверху.
      final filled = tester
          .widgetList<Material>(
            find.descendant(
              of: find.byType(AppBottomBar),
              matching: find.byType(Material),
            ),
          )
          .where((m) => m.color != null && m.color != Colors.transparent)
          .length;
      expect(filled, 0, reason: 'ни одна вкладка не выделяется заливкой');
    });

    testWidgets('активная вкладка помечена утолщением линейки',
        (tester) async {
      for (final active in [0, 2, 3]) {
        await tester.pumpWidget(
          wrap(AppBottomBar(currentIndex: active, onSelect: (_) {})),
        );
        await tester.pump();

        // Линейка бара: четыре сегмента, ровно один толщиной 2.
        final thick = tester
            .widgetList<Container>(
              find.descendant(
                of: find.byType(AppBottomBar),
                matching: find.byType(Container),
              ),
            )
            .where((c) => c.constraints?.maxHeight == 2)
            .length;
        expect(thick, 1, reason: 'утолщение должно быть ровно одно');
      }
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

    test('«Практики» держат библиотеку', () {
      final s = read('lib/features/practices/practices_screen.dart');
      expect(s.contains("'/library'"), isTrue);
    });

    test('специалист достижим и вкладкой, и из глубины', () {
      final r = read('lib/app/router.dart');
      // Вкладка — «зайти посмотреть». /specialist — вход из кризисного
      // экрана и ответа «выговориться», откуда нужен возврат назад.
      expect(r.contains("path: '/help'"), isTrue);
      expect(r.contains("path: '/specialist'"), isTrue);

      for (final f in const [
        'lib/features/vent/crisis_screen.dart',
        'lib/features/vent/vent_response_screen.dart',
      ]) {
        expect(
          read(f).contains("push('/help')"),
          isFalse,
          reason: '$f пушит ветку оболочки — бар вылезет поверх экрана',
        );
      }
    });

    test('на экране специалиста подготовка выше телефонов доверия', () {
      final s = read('lib/features/help/help_screen.dart');
      // Порядок должен зависеть от того, как открыли экран: вкладка —
      // подготовка первой, из кризиса — телефоны первыми.
      expect(s.contains('if (!canGoBack)'), isTrue,
          reason: 'порядок блоков должен зависеть от способа входа');
      final tabBranch = s.indexOf('if (!canGoBack)');
      final elseBranch = s.indexOf('] else ...[');
      expect(
        s.indexOf('_prepareSection', tabBranch),
        lessThan(s.indexOf('_emergencySection', tabBranch)),
        reason: 'во вкладке подготовка идёт первой',
      );
      expect(
        s.indexOf('_emergencySection', elseBranch),
        lessThan(s.indexOf('_prepareSection', elseBranch)),
        reason: 'из кризиса первым обязан быть телефон доверия',
      );
    });

    test('состояния в «Практиках» сворачиваются', () {
      final s = read('lib/features/practices/practices_screen.dart');
      expect(s.contains('SosTrigger? _open'), isTrue,
          reason: 'открытым может быть только одно состояние');
      expect(s.contains('AnimatedSize'), isTrue);
    });

    test('«Путь» держит «что я заметила»', () {
      final s = read('lib/features/path/path_screen.dart');
      expect(s.contains("'/insights'"), isTrue);
      // Опросники по просьбе заказчицы переехали в «Настройки».
      expect(s.contains("'/questionnaire'"), isFalse);
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

    test('дневник держит один вход в «выговориться»', () {
      final s = read('lib/features/diary/diary_list_screen.dart');
      expect(s.contains("'/vent'"), isTrue);
      expect(
        s.contains("'/vent/text'"),
        isFalse,
        reason: 'способ выбирается внутри, а не в списке дневника',
      );
    });

    test('экран выбора предлагает оба способа', () {
      final s = read('lib/features/vent/vent_choice_screen.dart');
      expect(s.contains("'/vent/voice'"), isTrue);
      expect(s.contains("'/vent/text'"), isTrue);
    });

    test('знак «уходит на сервер» нигде не проставлен безусловно', () {
      // Знак должен зависеть от того, умеет ли телефон распознавать
      // речь сам. Захардкоженный `leavesDevice: true` означал бы, что
      // мы пугаем человека там, где ничего не уходит.
      for (final p in const [
        'lib/features/vent/vent_choice_screen.dart',
        'lib/features/vent/voice_vent_screen.dart',
        'lib/features/diary/diary_list_screen.dart',
      ]) {
        expect(
          RegExp(r'leavesDevice: true').hasMatch(read(p)),
          isFalse,
          reason: '$p проставляет знак не глядя на телефон',
        );
      }
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
    test('настройки не прячут календарь и инсайты', () {
      final s =
          File('lib/features/settings/settings_screen.dart').readAsStringSync();
      // Опросники — исключение: заказчица попросила вернуть их в настройки.
      for (final route in const ['/insights', '/calendar']) {
        expect(
          s.contains("push('$route')"),
          isFalse,
          reason: '$route снова похоронен в настройках',
        );
      }
    });

    test('опросники теперь доступны из настроек', () {
      final s =
          File('lib/features/settings/settings_screen.dart').readAsStringSync();
      expect(s.contains("push('/questionnaire')"), isTrue);
    });
  });
}
