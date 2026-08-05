import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../data/content/quests.dart';
import '../../main.dart';

/// Календарь месяца с цветными точками по среднему настроению дня (из чек-инов).
/// Каждый день: цвет = настроение, маленькая капля = был выполнен квест.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _prev() => setState(
        () => _month = DateTime(_month.year, _month.month - 1),
      );

  void _next() {
    final now = DateTime.now();
    final nextMonth = DateTime(_month.year, _month.month + 1);
    // Не идём в будущее.
    if (nextMonth.isAfter(DateTime(now.year, now.month))) return;
    setState(() => _month = nextMonth);
  }

  static const _months = [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
  ];

  static const _weekdays = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Text('Календарь', style: theme.textTheme.displayLarge),
            const SizedBox(height: 8),
            Text(
              'Цвет — твоё настроение из чек-инов. '
              'Капелька — был утренний или вечерний шаг.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            _MonthHeader(
              month: _months[_month.month - 1],
              year: _month.year,
              onPrev: _prev,
              onNext: _next,
            ),
            const SizedBox(height: 16),
            _WeekdayRow(weekdays: _weekdays),
            const SizedBox(height: 8),
            _MonthGrid(month: _month),
            const SizedBox(height: 24),
            _Legend(),
          ],
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.year,
    required this.onPrev,
    required this.onNext,
  });

  final String month;
  final int year;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left_rounded),
          color: AppColors.terracotta,
        ),
        Expanded(
          child: Center(
            child: Text(
              '$month $year',
              style: theme.textTheme.titleLarge,
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
          color: AppColors.terracotta,
        ),
      ],
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow({required this.weekdays});
  final List<String> weekdays;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: weekdays
          .map(
            (w) => Expanded(
              child: Center(
                child: Text(
                  w,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.month});
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // weekday: 1=пн ... 7=вс. Сдвигаем чтобы пн был колонкой 0.
    final firstWeekday = (firstDay.weekday - 1) % 7;
    final today = DateTime.now();

    final cells = <Widget>[];
    for (var i = 0; i < firstWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      final isFuture = date.isAfter(today);
      cells.add(
        _DayCell(
          day: d,
          date: date,
          isToday: isToday,
          isFuture: isFuture,
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.95,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: cells,
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.date,
    required this.isToday,
    required this.isFuture,
  });

  final int day;
  final DateTime date;
  final bool isToday;
  final bool isFuture;

  Color _moodColor(double? avg) {
    if (avg == null) return AppColors.textMuted.withValues(alpha: 0.18);
    // 0=плохо, 1=средне, 2=хорошо. Цвет: коралл → персик → шалфей.
    if (avg < 0.7) return AppColors.coral;
    if (avg < 1.4) return AppColors.peach;
    return AppColors.sage;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avg = isFuture ? null : checkInStorage.averageMood(date);
    final color = _moodColor(avg);
    final didMorning =
        questStorage.isDoneOn(QuestSlot.morning, date);
    final didEvening =
        questStorage.isDoneOn(QuestSlot.evening, date);
    final hasDrops = didMorning || didEvening;

    return Container(
      decoration: BoxDecoration(
        color: isFuture ? Colors.transparent : color,
        borderRadius: BorderRadius.circular(10),
        border: isToday
            ? Border.all(color: AppColors.terracotta, width: 1.5)
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Text(
              '$day',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isFuture ? AppColors.textMuted : AppColors.textPrimary,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          if (hasDrops)
            const Positioned(
              right: 4,
              top: 4,
              child: Icon(
                Icons.eco_rounded,
                color: AppColors.sageDeep,
                size: 9,
              ),
            ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Что значат цвета', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          _LegendRow(color: AppColors.sage, text: 'Хорошее самочувствие'),
          const SizedBox(height: 6),
          _LegendRow(color: AppColors.peach, text: 'Среднее самочувствие'),
          const SizedBox(height: 6),
          _LegendRow(color: AppColors.coral, text: 'Тяжело'),
          const SizedBox(height: 6),
          _LegendRow(
            color: AppColors.textMuted.withValues(alpha: 0.18),
            text: 'Без чек-ина',
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
