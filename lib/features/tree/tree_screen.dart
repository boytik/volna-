import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../data/local/quest_storage.dart';
import '../../main.dart';
import 'tree_painter.dart';
import 'tree_view.dart';

class TreeScreen extends StatelessWidget {
  const TreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final drops = questStorage.drops;
    final daysSince = questStorage.daysSinceActivity;
    final didToday = daysSince == 0;
    final mood = moodFromActivity(
      didSomethingToday: didToday,
      daysSinceActivity: daysSince,
    );
    final week = questStorage.activityLastDays(7);
    final completedThisWeek = week.fold<int>(0, (s, d) => s + d.count);

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
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Твоё древо', style: theme.textTheme.displayLarge),
              const SizedBox(height: 8),
              Text(
                'Каждый шаг — капля. Каждая капля помогает дереву расти. '
                'Пропуск дня — не страшно. Древо помнит корни.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.peachSoft, AppColors.peach],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: TreeView(
                    drops: drops,
                    mood: mood,
                    size: const Size(220, 280),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _StageRow(drops: drops),
              const SizedBox(height: 24),
              Text('Эта неделя', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                '$completedThisWeek ${_stepsWord(completedThisWeek)} '
                'за последние 7 дней',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              _WeekChart(week: week),
              const SizedBox(height: 24),
              _MoodNote(mood: mood, daysSince: daysSince),
            ],
          ),
        ),
      ),
    );
  }

  String _stepsWord(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod100 >= 11 && mod100 <= 14) return 'шагов';
    if (mod10 == 1) return 'шаг';
    if (mod10 >= 2 && mod10 <= 4) return 'шага';
    return 'шагов';
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({required this.drops});
  final int drops;

  static const _stages = [
    ('Росток', 0),
    ('Саженец', 5),
    ('Деревце', 20),
    ('Цветущее', 50),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(_stages.length, (i) {
            final reached = drops >= _stages[i].$2;
            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: reached
                          ? AppColors.sageDeep
                          : AppColors.textMuted.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _stages[i].$1,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: reached ? AppColors.textPrimary : AppColors.textMuted,
                      fontWeight: reached ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.week});
  final List<DayActivity> week;

  static const _weekdayShort = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: week.map((d) {
          final isToday = d.date.year == today.year &&
              d.date.month == today.month &&
              d.date.day == today.day;
          final weekdayIndex = (d.date.weekday - 1) % 7;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: 80,
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (d.evening)
                          Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.sageDeep,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        if (d.evening && d.morning) const SizedBox(height: 2),
                        if (d.morning)
                          Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.saffron,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        if (!d.morning && !d.evening)
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.textMuted.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _weekdayShort[weekdayIndex],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isToday ? AppColors.terracotta : AppColors.textMuted,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MoodNote extends StatelessWidget {
  const _MoodNote({required this.mood, required this.daysSince});
  final TreeMood mood;
  final int daysSince;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, text) = switch (mood) {
      TreeMood.vibrant => (
          Icons.eco_rounded,
          'Древо живое и сегодня уже полито. Можно отдыхать.',
        ),
      TreeMood.pale => (
          Icons.favorite_border_rounded,
          'Рада, что ты здесь. Сегодня может быть один маленький шаг — '
              'или просто этот момент рядом с древом.',
        ),
      TreeMood.sleeping => (
          Icons.favorite_border_rounded,
          'С возвращением. Прошло $daysSince ${_daysWord(daysSince)} — '
              'и это нормально. Корни живы, древо ждало.',
        ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.peachSoft.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.terracotta, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _daysWord(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod100 >= 11 && mod100 <= 14) return 'дней';
    if (mod10 == 1) return 'день';
    if (mod10 >= 2 && mod10 <= 4) return 'дня';
    return 'дней';
  }
}
