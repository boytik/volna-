import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/tokens.dart';

/// Нижний бар: четыре равные вкладки, ни одной выделенной заливкой.
///
/// Активная помечается **самой линейкой бара**: она идёт через весь
/// экран, но над текущей вкладкой утолщается до 2px и берёт акцент.
/// Это язычок оглавления, а не подчёркивание из веба — и он не требует
/// отдельного элемента внутри вкладки, поэтому бар ниже на 8pt.
///
/// Материал плоский: бумага и волосяная линейка. Ни стекла, ни блюра,
/// ни теней, ни заливок (см. DESIGN.md).
class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

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
    final accent = theme.brightness == Brightness.dark
        ? AppColors.nightAccent
        : AppColors.accentPress;

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: EdgeInsets.only(bottom: inset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 2,
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          height: i == currentIndex ? 2 : AppStroke.hairline,
                          color: i == currentIndex
                              ? accent
                              : theme.colorScheme.outline,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 54,
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: _Tab(
                      label: tabs[i].label,
                      icon: tabs[i].icon,
                      selected: i == currentIndex,
                      accent: accent,
                      onTap: () => onSelect(i),
                    ),
                  ),
              ],
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
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? accent : theme.textTheme.bodySmall?.color;

    return Semantics(
      selected: selected,
      button: true,
      child: InkResponse(
        onTap: onTap,
        radius: 34,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: AppSpacing.xs),
            // «Настройки» — самая длинная подпись; на 320pt она иначе
            // обрезается. scaleDown ужимает только там, где нужно.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  height: 1.1,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  letterSpacing: 0.2,
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
