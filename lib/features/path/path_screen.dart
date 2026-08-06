import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/content/badges.dart' as badge_data;
import '../../data/content/quests.dart';
import '../../main.dart';

/// «Путь» — взгляд назад. Один экран вместо трёх разбросанных.
///
/// Сюда слиты календарь и знаки присутствия, а рядом — «что я заметила»:
/// всё это об одном — что со мной было и что я про себя заметила. Вход
/// один, из правого верхнего угла главной. Опросники отсюда убраны — они
/// переехали в «Настройки» по просьбе заказчицы.
///
/// Правило календаря не изменилось: рисуется только то, что было.
/// Дни без отметок остаются пустой бумагой — свои пропуски невозможно
/// увидеть, потому что они не отрисованы.
class PathScreen extends StatefulWidget {
  const PathScreen({super.key});

  @override
  State<PathScreen> createState() => _PathScreenState();
}

class _PathScreenState extends State<PathScreen> {
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
    final unlocked = badgesStorage.all();
    final earned =
        badge_data.allBadges.where((b) => unlocked.contains(b.id)).toList();

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
            AppSpacing.axis,
            AppSpacing.xl,
          ),
          children: [
            Text('Твой путь', style: theme.textTheme.displayLarge),
            const SizedBox(height: AppSpacing.smd),
            Text(
              'Цвет — самочувствие из чек-инов, точка — был шаг. '
              'Дни без отметок остаются пустой бумагой.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.xl),
            _MonthHeader(
              month: _months[_month.month - 1],
              year: _month.year,
              onPrev: _prev,
              onNext: _next,
            ),
            const SizedBox(height: AppSpacing.md),
            _WeekdayRow(weekdays: _weekdays),
            const SizedBox(height: AppSpacing.sm),
            _MonthGrid(month: _month),
            const SizedBox(height: AppSpacing.lg),
            const _Legend(),
            const SizedBox(height: AppSpacing.xxl),

            // ── Знаки присутствия ────────────────────────────────
            Text('ЗНАКИ ПРИСУТСТВИЯ', style: theme.textTheme.labelSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              earned.isEmpty
                  ? 'Это не ачивки, а места, где ты была. Они появятся сами — '
                      'считать нечего и догонять некого.'
                  : 'Это не ачивки. Это места, где ты была.',
              style: theme.textTheme.bodyMedium,
            ),
            if (earned.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.smd,
                runSpacing: AppSpacing.smd,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [for (final b in earned) _BadgeMark(badge: b)],
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),

            // ── Что дальше ───────────────────────────────────────
            Text('ПОСМОТРЕТЬ ГЛУБЖЕ', style: theme.textTheme.labelSmall),
            const SizedBox(height: AppSpacing.sm),
            _LinkRow(
              title: 'Что я заметила',
              note: 'Связи между шагами и самочувствием',
              route: '/insights',
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.title,
    required this.note,
    required this.route,
  });

  final String title;
  final String note;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline,
              width: AppStroke.hairline,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(note, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

/// Знак — набранная плашка на полке, не карточка в сетке.
/// Незаработанных знаков не существует: нельзя увидеть, чего не добрала.
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
        Text('$month $year', style: theme.textTheme.headlineMedium),
        const Spacer(),
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left_rounded),
          color: AppColors.accentPress,
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
          color: AppColors.accentPress,
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
    final theme = Theme.of(context);
    return Row(
      children: weekdays
          .map(
            (w) => Expanded(
              child: Center(
                child: Text(w, style: theme.textTheme.labelSmall),
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
      cells.add(
        _DayCell(day: d, date: date, isToday: isToday, isFuture: date.isAfter(today)),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.95,
      mainAxisSpacing: AppSpacing.xs,
      crossAxisSpacing: AppSpacing.xs,
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

  /// Заливка только там, где чек-ин был. Дня без отметки не существует
  /// как объекта: ни заливки, ни рамки, ни серого квадрата.
  Color? _moodColor(double? avg) {
    if (avg == null) return null;
    if (avg < 0.7) return AppColors.sos;
    if (avg < 1.4) return AppColors.dawn;
    return AppColors.markedWash;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avg = isFuture ? null : checkInStorage.averageMood(date);
    final color = _moodColor(avg);
    final hasStep = questStorage.isDoneOn(QuestSlot.morning, date) ||
        questStorage.isDoneOn(QuestSlot.evening, date);

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.smR,
        border: isToday
            ? Border.all(color: AppColors.accent, width: AppStroke.hairline)
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Text(
              '$day',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isFuture
                    ? theme.colorScheme.outline
                    : (color != null
                        ? AppColors.inkBody
                        : theme.textTheme.bodySmall?.color),
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          if (hasStep)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: AppColors.marked,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.smR,
        border: Border.all(
          color: theme.colorScheme.outline,
          width: AppStroke.hairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _LegendRow(color: AppColors.markedWash, text: 'Хорошее самочувствие'),
          SizedBox(height: AppSpacing.sm),
          _LegendRow(color: AppColors.dawn, text: 'Среднее самочувствие'),
          SizedBox(height: AppSpacing.sm),
          _LegendRow(color: AppColors.sos, text: 'Тяжело'),
          // Строки «без чек-ина» здесь нет намеренно: день без отметки
          // не рисуется, поэтому и объяснять в легенде нечего.
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
          decoration: BoxDecoration(color: color, borderRadius: AppRadius.smR),
        ),
        const SizedBox(width: AppSpacing.smd),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
