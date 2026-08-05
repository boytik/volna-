import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/tokens.dart';

/// Нижний бар: четыре равных места, третье — «Практики».
///
/// «Практики» это вкладка, а не отдельная кнопка сбоку: главный вход
/// для тяжёлого момента должен стоять в ряду, а не выглядеть аварийным
/// рычагом. Выделен цветом и заливкой, а не положением — глаз находит
/// его по кораллу быстрее, чем считает миллиметры от края.
///
/// Материал плоский: бумага и волосяная линейка сверху. Ни стекла,
/// ни блюра, ни теней (см. DESIGN.md).
class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  /// Индекс «Практик». Вынесен константой: на него завязана и заливка,
  /// и тесты, которые следят, что главный вход не уехал.
  static const practicesIndex = 2;

  static const tabs = <({String label, IconData icon})>[
    (label: 'Главная', icon: Icons.home_outlined),
    (label: 'Дневник', icon: Icons.edit_note_outlined),
    (label: 'Практики', icon: Icons.spa_outlined),
    (label: 'Настройки', icon: Icons.tune_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    // Безопасную зону бар забирает внутренним отступом. Обернуть его
    // в SafeArea нельзя: под баром останется полоска бумаги, и он
    // начнёт читаться как плавающая панель, а не как край страницы.
    final inset = MediaQuery.paddingOf(context).bottom;
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: EdgeInsets.only(bottom: inset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: AppStroke.hairline,
            color: theme.colorScheme.outline,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: SizedBox(
              height: 62,
              child: Row(
                children: [
                  for (var i = 0; i < tabs.length; i++)
                    Expanded(
                      child: i == practicesIndex
                          ? _PracticesTab(
                              label: tabs[i].label,
                              icon: tabs[i].icon,
                              selected: i == currentIndex,
                              onTap: () => onSelect(i),
                            )
                          : _Tab(
                              label: tabs[i].label,
                              icon: tabs[i].icon,
                              selected: i == currentIndex,
                              onTap: () => onSelect(i),
                            ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? (theme.brightness == Brightness.dark
            ? AppColors.nightAccent
            : AppColors.accentPress)
        : theme.textTheme.bodySmall?.color;

    return Semantics(
      selected: selected,
      button: true,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Активная вкладка помечена короткой линейкой сверху —
            // печатной закладкой, а не заливкой и не пилюлей.
            Container(
              height: 2,
              width: 18,
              color: selected ? color : Colors.transparent,
            ),
            const SizedBox(height: AppSpacing.sm),
            Icon(icon, size: 21, color: color),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  height: 1.1,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// «Практики» — единственная заливка в баре. Это главный вход, когда
/// тяжело, и он не должен искаться чтением подписей.
class _PracticesTab extends StatelessWidget {
  const _PracticesTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      selected: selected,
      button: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Material(
          color: AppColors.sos,
          borderRadius: AppRadius.smR,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.smR,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Та же закладка, что у обычных вкладок, только
                // чернилами по кораллу.
                Container(
                  height: 2,
                  width: 18,
                  color: selected ? AppColors.sosInk : Colors.transparent,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Icon(Icons.spa_outlined,
                    size: 21, color: AppColors.sosInk),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      color: AppColors.sosInk,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
