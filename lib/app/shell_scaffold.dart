import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/app_bottom_bar.dart';

/// Оболочка с нижним баром. Внутри неё живут только корни вкладок —
/// главная, «выговориться», дневник и «ещё».
///
/// Сфокусированные экраны (квест, дыхание, заземление, запись в
/// дневник) пушатся поверх оболочки и бар прячут: из них выходят
/// «назад», а не переключением вкладок. Прерывать практику рядом
/// стоящей вкладкой — ровно то давление, которого продукт избегает.
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomBar(
        currentIndex: navigationShell.currentIndex,
        onSelect: (i) => navigationShell.goBranch(
          i,
          // Повторный тап по активной вкладке возвращает её в корень —
          // привычное поведение, и заодно выход из тупика.
          initialLocation: i == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
