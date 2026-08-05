import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/content/badges.dart' as badge_data;
import '../../main.dart';

/// Знаки присутствия.
///
/// Здесь намеренно нет: счётчика «открыто N из M», силуэтов под замком,
/// вопросительных знаков и сетки. Незаработанного знака в интерфейсе
/// просто не существует — нельзя увидеть, чего ты не добрала.
/// Полученные лежат неровной полкой, как сухие листья и галька на
/// подоконнике, а не выровненной таблицей достижений.
class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlocked = badgesStorage.all();
    final earned = badge_data.allBadges
        .where((b) => unlocked.contains(b.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.axis,
            0,
            AppSpacing.marginRight,
            AppSpacing.xl,
          ),
          children: [
            Text('Знаки присутствия', style: theme.textTheme.displayLarge),
            const SizedBox(height: AppSpacing.smd),
            Text(
              earned.isEmpty
                  ? 'Это не ачивки. Это места, где ты была. '
                      'Они появятся сами — считать нечего и догонять некого.'
                  : 'Это не ачивки. Это места, где ты была.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (earned.isNotEmpty)
              Wrap(
                spacing: AppSpacing.smd,
                runSpacing: AppSpacing.smd,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  for (final b in earned) _BadgeMark(badge: b),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Знак — набранная плашка на полке, не карточка в сетке.
class _BadgeMark extends StatelessWidget {
  const _BadgeMark({required this.badge});
  final badge_data.Badge badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _showDetails(context),
      borderRadius: AppRadius.smR,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.smd,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: AppRadius.smR,
          border: Border.all(
            color: theme.colorScheme.outline,
            width: AppStroke.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(badge.icon, color: AppColors.accent, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text(badge.title, style: theme.textTheme.titleLarge),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(badge.icon, color: AppColors.accent, size: 28),
              const SizedBox(height: AppSpacing.md),
              Text(badge.title, style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.smd),
              Text(badge.description, style: theme.textTheme.bodyLarge),
            ],
          ),
        );
      },
    );
  }
}
