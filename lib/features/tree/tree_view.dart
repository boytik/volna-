import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import 'tree_painter.dart';

/// Виджет древа.
///
/// Из этого файла намеренно удалены `growthFromDrops`, `stageLabel`,
/// `nextStageHint` и `moodFromActivity`. Первые три складывались в
/// шкалу «до «Саженца» — 3 капли», то есть в счётчик, который человек
/// не добрал; последняя бледнила рисунок при пропуске дня. И то и
/// другое — давление прогрессом, запрещённое DESIGN.md.
class TreeView extends StatelessWidget {
  const TreeView({
    super.key,
    required this.rings,
    required this.lights,
    this.size = const Size(180, 200),
  });

  /// Прожитые недели.
  final int rings;

  /// Возраст следов практик в днях (0 — сегодня).
  final List<int> lights;

  final Size size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: size.width,
      height: size.height,
      child: CustomPaint(
        painter: TreePainter(
          rings: rings,
          lights: lights,
          season: seasonForMonth(DateTime.now().month),
          inkColor: onDark ? AppColors.nightInkSoft : AppColors.inkSoft,
          ruleColor: onDark ? AppColors.nightRule : AppColors.rule,
        ),
      ),
    );
  }
}

/// Блок древа ниже сгиба на главном экране. Не карточка: та же бумага,
/// отделённая волосяной линейкой сверху.
class TreeBlock extends StatelessWidget {
  const TreeBlock({
    super.key,
    required this.rings,
    required this.lights,
    required this.onTap,
  });

  final int rings;
  final List<int> lights;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TreeView(
              rings: rings,
              lights: lights,
              size: const Size(104, 128),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Твоё древо', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    ringsPhrase(rings),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Следы гаснут, дерево остаётся.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Формулировка про кольца. Говорит о прожитом времени, а не о заслугах.
String ringsPhrase(int rings) {
  if (rings <= 0) return 'Первая неделя вместе';
  return '$rings ${_weeksWord(rings)} вместе';
}

String _weeksWord(int n) {
  final mod10 = n % 10;
  final mod100 = n % 100;
  if (mod100 >= 11 && mod100 <= 14) return 'недель';
  if (mod10 == 1) return 'неделя';
  if (mod10 >= 2 && mod10 <= 4) return 'недели';
  return 'недель';
}
