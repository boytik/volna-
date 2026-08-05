import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/tokens.dart';

/// Нижний бар: четыре вкладки и отдельная коралловая кнопка «Плохо».
///
/// Структура взята у iOS 26, где рядом с таб-баром стоит отдельная
/// кнопка поиска. Материал остался свой: плоская бумага и волосяная
/// линейка сверху. Никакого стекла, блюра, теней и градиентов —
/// они противоречат «Печатной странице» (см. DESIGN.md).
///
/// Кнопка «Плохо» вынесена из ряда вкладок намеренно. Она не раздел,
/// а выход: её нельзя перепутать с навигацией, и она видна на всех
/// четырёх корнях вкладок, а не на одной главной, как раньше.
class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.onSos,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onSos;

  static const tabs = <({String label, IconData icon})>[
    (label: 'Главная', icon: Icons.home_outlined),
    (label: 'Выговориться', icon: Icons.mic_none_rounded),
    (label: 'Дневник', icon: Icons.edit_note_outlined),
    (label: 'Ещё', icon: Icons.more_horiz_rounded),
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
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              0,
              AppSpacing.smd,
              0,
            ),
            // 64, а не 58: капсула высотой 56 иначе прилипает к
            // волосяной линейке сверху (замер на симуляторе дал 1.7pt
            // зазора). Отдельная кнопка должна читаться отдельной.
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  for (var i = 0; i < tabs.length; i++)
                    Expanded(
                      child: _Tab(
                        label: tabs[i].label,
                        icon: tabs[i].icon,
                        selected: i == currentIndex,
                        onTap: () => onSelect(i),
                      ),
                    ),
                  const SizedBox(width: AppSpacing.sm),
                  SosCapsule(onTap: onSos),
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
            // «Выговориться» не влезает в ширину вкладки на 320pt.
            // scaleDown ужимает подпись только там, где иначе был бы
            // обрез; на 375pt и шире она в полном кегле.
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

/// Кнопка выхода в кризисные техники. Одно слово: в остром состоянии
/// читать не хочется, а «Плохо» опознаётся мгновенно и по цвету, и по
/// положению — она единственная цветная в баре.
class SosCapsule extends StatelessWidget {
  const SosCapsule({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Мне сейчас плохо',
      child: Tooltip(
        message: 'Мне сейчас плохо',
        child: Material(
          color: AppColors.sos,
          borderRadius: AppRadius.smR,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.smR,
            child: const SizedBox(
              width: 64,
              height: 56,
              child: Center(child: _SosLabel()),
            ),
          ),
        ),
      ),
    );
  }
}

class _SosLabel extends StatelessWidget {
  const _SosLabel();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.pan_tool_alt_outlined,
            size: 20, color: AppColors.sosInk),
        const SizedBox(height: 2),
        Text(
          'Плохо',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: AppColors.sosInk,
              ),
        ),
      ],
    );
  }
}
