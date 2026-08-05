import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volna/core/theme/app_theme.dart';
import 'package:volna/features/home/home_screen.dart';

/// Пять иконок в шапке лежали в Row фиксированной ширины — на узких экранах
/// строка переполнялась (RenderFlex overflow) поверх приветствия.
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
                // Ширина экрана минус горизонтальные отступы главной (20+20).
                width: width - 40,
                child: const HomeHeader(isMorning: true),
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
      expect(find.text('ВОЛНА'), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
      expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
    });
  }
}
