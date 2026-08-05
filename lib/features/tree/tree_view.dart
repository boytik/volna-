import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import 'tree_painter.dart';

/// Преобразование числа капель в стадию роста.
/// 0–4: росток (0..0.2)
/// 5–19: саженец (0.2..0.5)
/// 20–49: деревце (0.5..0.8)
/// 50+: цветущее (0.8..1.0)
double growthFromDrops(int drops) {
  if (drops <= 0) return 0;
  if (drops < 5) return 0.05 + (drops / 5) * 0.15;
  if (drops < 20) return 0.20 + ((drops - 5) / 15) * 0.30;
  if (drops < 50) return 0.50 + ((drops - 20) / 30) * 0.30;
  if (drops < 100) return 0.80 + ((drops - 50) / 50) * 0.20;
  return 1.0;
}

String stageLabel(int drops) {
  if (drops < 5) return 'Росток';
  if (drops < 20) return 'Саженец';
  if (drops < 50) return 'Деревце';
  return 'Цветущее древо';
}

String? nextStageHint(int drops) {
  if (drops < 5) return 'До «Саженца» — ${5 - drops} ${_dropsWord(5 - drops)}';
  if (drops < 20) return 'До «Деревца» — ${20 - drops} ${_dropsWord(20 - drops)}';
  if (drops < 50) return 'До цветения — ${50 - drops} ${_dropsWord(50 - drops)}';
  return null;
}

String _dropsWord(int n) {
  final mod10 = n % 10;
  final mod100 = n % 100;
  if (mod100 >= 11 && mod100 <= 14) return 'капель';
  if (mod10 == 1) return 'капля';
  if (mod10 >= 2 && mod10 <= 4) return 'капли';
  return 'капель';
}

TreeMood moodFromActivity({required bool didSomethingToday, required int daysSinceActivity}) {
  if (daysSinceActivity >= 7) return TreeMood.sleeping;
  if (!didSomethingToday) return TreeMood.pale;
  return TreeMood.vibrant;
}

/// Анимированный виджет древа. На вход — целевые параметры,
/// плавно переходит к ним за ~900 мс при изменении.
class TreeView extends StatelessWidget {
  const TreeView({
    super.key,
    required this.drops,
    required this.mood,
    this.size = const Size(180, 200),
  });

  final int drops;
  final TreeMood mood;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final growth = growthFromDrops(drops);
    final season = seasonForMonth(DateTime.now().month);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: growth, end: growth),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: size.width,
          height: size.height,
          child: CustomPaint(
            painter: TreePainter(
              growth: value,
              mood: mood,
              season: season,
            ),
          ),
        );
      },
    );
  }
}

/// Карточка древа на главном экране.
class TreeCard extends StatelessWidget {
  const TreeCard({
    super.key,
    required this.drops,
    required this.mood,
    required this.onTap,
  });

  final int drops;
  final TreeMood mood;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.peachSoft, AppColors.peach],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
          child: Row(
            children: [
              TreeView(
                drops: drops,
                mood: mood,
                size: const Size(110, 140),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Твоё древо', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      '${stageLabel(drops)} · $drops ${_dropsWord(drops)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _moodHint(mood) ?? nextStageHint(drops) ?? 'Древо в цвету',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _moodHint(TreeMood m) {
    switch (m) {
      case TreeMood.vibrant:
        return null;
      case TreeMood.pale:
        return 'Рада, что ты здесь. Можно начать с одного выдоха.';
      case TreeMood.sleeping:
        return 'С возвращением. Корни живы — древо ждёт.';
    }
  }
}
