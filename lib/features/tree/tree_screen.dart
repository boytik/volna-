import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/local/quest_storage.dart';
import '../../main.dart';
import 'tree_painter.dart';
import 'tree_view.dart';

class TreeScreen extends StatelessWidget {
  const TreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rings = questStorage.weeksLived;
    final lights = questStorage.recentActivityAges();
    final week = questStorage.activityLastDays(7);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.axis,
            0,
            AppSpacing.marginRight,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Твоё древо', style: theme.textTheme.displayLarge),
              const SizedBox(height: AppSpacing.smd),
              Text(
                'Оно уже выросло — его не надо выращивать. '
                'Кольца у корней добавляются за каждую прожитую неделю, '
                'просто потому что она прошла, а ты есть.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: TreeView(
                  rings: rings,
                  lights: lights,
                  size: const Size(240, 300),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(ringsPhrase(rings), style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Следы гаснут за десять дней, дерево остаётся. '
                'Ничего здесь не вянет и не засыпает.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text('Последние дни', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _weekPhrase(week),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              _WeekMarks(week: week),
              const SizedBox(height: AppSpacing.xxl),
              _SeasonNote(season: seasonForMonth(DateTime.now().month)),
            ],
          ),
        ),
      ),
    );
  }

  /// Никаких «0 шагов за неделю» — пустая неделя не комментируется
  /// числом, потому что это была бы цифра, которая упала.
  String _weekPhrase(List<DayActivity> week) {
    final days = week.where((d) => d.count > 0).length;
    if (days == 0) return 'На этой неделе ты просто была. Этого достаточно.';
    return 'Отмечено дней: $days';
  }
}

/// Отметки последних семи дней. Рисуется только то, что было:
/// у дня без отметки нет ни контура, ни заливки, ни подписи —
/// свои пропуски невозможно увидеть, потому что они не отрисованы.
class _WeekMarks extends StatelessWidget {
  const _WeekMarks({required this.week});
  final List<DayActivity> week;

  static const _weekdayShort = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();

    return Row(
      children: week.map((d) {
        final isToday = d.date.year == today.year &&
            d.date.month == today.month &&
            d.date.day == today.day;
        final weekdayIndex = (d.date.weekday - 1) % 7;

        return Expanded(
          child: Column(
            children: [
              SizedBox(
                height: 20,
                child: d.count == 0
                    ? null
                    : Center(
                        child: Container(
                          width: d.count > 1 ? 16 : 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.marked,
                            borderRadius: BorderRadius.all(
                              Radius.circular(AppRadius.sm),
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _weekdayShort[weekdayIndex],
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isToday ? AppColors.accentPress : null,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Приложение меняется от того, что прошло время, а не от того,
/// справился ли человек.
class _SeasonNote extends StatelessWidget {
  const _SeasonNote({required this.season});
  final Season season;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = switch (season) {
      Season.winter => 'Зима. Крона реже — так и должно быть.',
      Season.spring => 'Весна. Дерево прибавляет само.',
      Season.summer => 'Лето. Крона самая полная в году.',
      Season.autumn => 'Осень. Под деревом появились листья.',
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.smR,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: AppStroke.hairline,
        ),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.textTheme.bodyLarge?.color,
        ),
      ),
    );
  }
}
