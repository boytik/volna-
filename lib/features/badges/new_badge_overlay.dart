import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/content/badges.dart' as badge_data;

/// Тихое сообщение об открытии нового знака.
///
/// Приложение никогда не празднует. Раньше здесь были радиальный
/// градиент, свечение, вибрация и всё по центру — это торжество,
/// а торжество подразумевает, что человек справился, то есть что
/// в другой день он не справился. Осталась вклейка с ровным текстом.
class NewBadgeOverlay {
  static Future<void> showAll(
    BuildContext context,
    List<badge_data.Badge> badges,
  ) async {
    for (final b in badges) {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        barrierColor: AppColors.ink.withValues(alpha: 0.32),
        builder: (_) => _BadgeDialog(badge: b),
      );
    }
  }
}

class _BadgeDialog extends StatelessWidget {
  const _BadgeDialog({required this.badge});
  final badge_data.Badge badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.smR,
        side: BorderSide(
          color: theme.colorScheme.outline,
          width: AppStroke.hairline,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(badge.icon, color: AppColors.accent, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'НОВЫЙ ЗНАК',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: AppColors.accentPress),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(badge.title, style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.smd),
            Text(badge.description, style: theme.textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Хорошо'),
            ),
          ],
        ),
      ),
    );
  }
}
