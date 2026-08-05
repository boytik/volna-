import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volna/core/theme/app_theme.dart';
import 'package:volna/core/widgets/breath_flower.dart';
import 'package:volna/core/widgets/breathing_horizon.dart';
import 'package:volna/data/content/sos_techniques.dart';

/// Единственная зацикленная анимация в приложении. Правило «бесконечных
/// анимаций нет» ради неё ослаблено, поэтому её поведение сторожится
/// отдельно: темп должен быть дыхательным, а движение — прекращаться,
/// когда система просит меньше движения.
void main() {
  Widget wrap(Widget child, {bool reduceMotion = false}) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(body: child),
      ),
    );
  }

  testWidgets('дышит: горизонт двигается сам по себе', (tester) async {
    await tester.pumpWidget(wrap(const BreathingHorizon()));
    await tester.pump();

    // Позиция самой линии — единственное, что здесь движется.
    Rect fill() => tester.getRect(
          find
              .descendant(
                of: find.byType(BreathingHorizon),
                matching: find.byType(FractionallySizedBox),
              )
              .first,
        );
    final start = fill();

    await tester.pump(const Duration(seconds: 2));
    final mid = fill();

    expect(
      mid.top,
      isNot(closeTo(start.top, 0.5)),
      reason: 'за две секунды вдоха горизонт обязан сдвинуться',
    );

    // Дожидаемся конца цикла, чтобы не оставить таймер висеть.
    await tester.pump(const Duration(seconds: 8));
  });

  testWidgets('при «уменьшении движения» стоит неподвижно', (tester) async {
    await tester.pumpWidget(
      wrap(const BreathingHorizon(), reduceMotion: true),
    );
    await tester.pump();

    Rect fill() => tester.getRect(
          find
              .descendant(
                of: find.byType(BreathingHorizon),
                matching: find.byType(FractionallySizedBox),
              )
              .first,
        );
    final start = fill();

    await tester.pump(const Duration(seconds: 3));
    expect(
      fill().top,
      closeTo(start.top, 0.01),
      reason: 'reduce-motion не терпит исключений',
    );
  });

  group('Цветок в дыхательных техниках', () {
    test('темп задан только у дыхательных, и выдох всегда длиннее', () {
      final withBreath =
          allTechniques.where((t) => t.breath != null).map((t) => t.id).toSet();

      expect(
        withBreath,
        {'physiological_sigh', 'extended_exhale'},
        reason: 'цветок ставится там, где дыхание и есть упражнение',
      );

      for (final t in allTechniques.where((t) => t.breath != null)) {
        expect(
          t.breath!.exhale,
          greaterThan(t.breath!.inhale),
          reason: '«${t.title}»: выдох обязан быть длиннее вдоха',
        );
      }
    });

    testWidgets('цветок дышит в темпе техники', (tester) async {
      await tester.pumpWidget(
        wrap(const AmbientBreathFlower(
          inhale: Duration(seconds: 2),
          exhale: Duration(seconds: 4),
        )),
      );
      await tester.pump();

      double level() => tester
          .widget<BreathFlower>(find.byType(BreathFlower))
          .level;

      final start = level();
      await tester.pump(const Duration(seconds: 2));
      // Через вдох лепестки должны быть максимально разошедшимися.
      expect(level(), greaterThan(start));

      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 1));
    });

    testWidgets('при «уменьшении движения» цветок замирает', (tester) async {
      await tester.pumpWidget(
        wrap(const AmbientBreathFlower(), reduceMotion: true),
      );
      await tester.pump();

      double level() => tester
          .widget<BreathFlower>(find.byType(BreathFlower))
          .level;

      final start = level();
      await tester.pump(const Duration(seconds: 3));
      expect(level(), closeTo(start, 0.001));
    });
  });

  test('выдох длиннее вдоха и темп дыхательный', () {
    expect(
      BreathingHorizon.exhale,
      greaterThan(BreathingHorizon.inhale),
      reason: 'длинный выдох — это и есть успокоение',
    );

    final cycle = BreathingHorizon.inhale + BreathingHorizon.exhale;
    final perMinute = 60 / cycle.inSeconds;
    expect(
      perMinute,
      inInclusiveRange(5, 7),
      reason: 'около шести дыханий в минуту; быстрее — уже не успокаивает',
    );
  });
}
