import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volna/core/theme/app_theme.dart';
import 'package:volna/features/home/home_screen.dart';

/// Пять иконок в шапке лежали в Row фиксированной ширины — на узких экранах
/// строка переполнялась (RenderFlex overflow) поверх приветствия.
///
/// Шапка пережила переход на систему «Печатная страница»: вордмарк «ВОЛНА»
/// уступил место метке времени суток, иконки стали контурными. Проверка
/// на переполнение остаётся — это её единственная задача.
void main() {
  // 320 px — iPhone SE 1-го поколения, самый узкий актуальный экран.
  for (final width in const [320.0, 360.0, 375.0, 430.0]) {
    testWidgets('шапка помещается в ${width.toInt()} px', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              // Шапка держит собственные поля, поэтому отдаём ей всю ширину.
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
      expect(find.byIcon(Icons.tune_outlined), findsOneWidget);
      expect(find.byIcon(Icons.workspace_premium_outlined), findsOneWidget);
    });
  }
}
