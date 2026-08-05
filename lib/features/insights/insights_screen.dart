import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/content/quests.dart';
import '../../data/local/toolbox_storage.dart';
import '../../main.dart';

/// Корреляции между активностью и настроением — Daylio-механика.
/// Принципы (из ресёрча):
/// — нужно ≥7 дней данных, иначе показываем «карта появится через X дней»
/// — никаких процентов и «-0.7» — для пользователя это шум
/// — короткие наблюдения вида «Кажется, утренние шаги связаны с лучшим настроением вечером»
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insights = _computeInsights();

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
            Text('Что я заметила', style: theme.textTheme.displayLarge),
            const SizedBox(height: 8),
            Text(
              'Я смотрю на твои шаги и настроение вместе. '
              'Это не совет — это просто наблюдение.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (insights.isEmpty)
              _Empty(daysCollected: _daysCollected())
            else
              ...insights.map(
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _InsightCard(insight: i),
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _daysCollected() {
    final now = DateTime.now();
    var count = 0;
    for (var i = 0; i < 30; i++) {
      final d = now.subtract(Duration(days: i));
      final m = checkInStorage.averageMood(d);
      if (m != null) count++;
    }
    return count;
  }

  List<_Insight> _computeInsights() {
    final insights = <_Insight>[];
    final now = DateTime.now();
    final days = _daysCollected();
    if (days < 7) return insights;

    // 1. Среднее настроение в дни с утренним квестом vs без.
    final moodsWithMorning = <double>[];
    final moodsWithoutMorning = <double>[];
    for (var i = 0; i < 30; i++) {
      final d = now.subtract(Duration(days: i));
      final mood = checkInStorage.averageMood(d);
      if (mood == null) continue;
      if (questStorage.isDoneOn(QuestSlot.morning, d)) {
        moodsWithMorning.add(mood);
      } else {
        moodsWithoutMorning.add(mood);
      }
    }
    if (moodsWithMorning.length >= 3 && moodsWithoutMorning.length >= 3) {
      final avgWith = _avg(moodsWithMorning);
      final avgWithout = _avg(moodsWithoutMorning);
      if (avgWith - avgWithout > 0.3) {
        insights.add(
          _Insight(
            icon: Icons.wb_sunny_rounded,
            color: AppColors.saffron,
            title: 'Утренний шаг связан с лучшим настроением',
            body: 'В дни, когда ты делаешь утренний квест, '
                'настроение в среднем чуть выше, чем когда пропускаешь. '
                'Это твой собственный паттерн — не общий совет.',
          ),
        );
      } else if (avgWithout - avgWith > 0.3) {
        insights.add(
          _Insight(
            icon: Icons.nightlight_round,
            color: AppColors.sageDeep,
            title: 'Утром тебе важнее не спешить',
            body: 'В дни без утреннего квеста настроение слегка лучше. '
                'Возможно, тебе нужно больше тишины утром, а не активности.',
          ),
        );
      }
    }

    // 2. Какая SOS-техника помогает чаще всего.
    final topTool = toolBoxStorage.topTool();
    if (topTool != null && toolBoxStorage.countOf(topTool) >= 3) {
      insights.add(
        _Insight(
          icon: Icons.favorite_rounded,
          color: AppColors.terracotta,
          title: 'Чаще всего помогает: ${topTool.title}',
          body: 'Ты ${toolBoxStorage.countOf(topTool)} раз отметила, '
              'что эта техника помогла. Запомни — она твоя.',
        ),
      );
    }

    // 3. Простая статистика: сколько шагов за неделю.
    final week = questStorage.activityLastDays(7);
    final completedThisWeek = week.fold<int>(0, (s, d) => s + d.count);
    if (completedThisWeek >= 5) {
      insights.add(
        _Insight(
          icon: Icons.eco_rounded,
          color: AppColors.sageDeep,
          title: '$completedThisWeek шагов за неделю',
          body: 'Это хорошо. Не сравнивай с прошлой неделей — '
              'просто заметь, что ты приходишь.',
        ),
      );
    }

    return insights;
  }

  double _avg(List<double> values) =>
      values.fold<double>(0, (s, v) => s + v) / values.length;
}

class _Empty extends StatelessWidget {
  const _Empty({required this.daysCollected});
  final int daysCollected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = (7 - daysCollected).clamp(0, 7);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.peachSoft.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.hourglass_empty_rounded,
            size: 32,
            color: AppColors.terracotta,
          ),
          const SizedBox(height: 12),
          Text(
            remaining == 0
                ? 'Пока недостаточно данных для наблюдений'
                : 'Ещё $remaining ${_dayWord(remaining)} — и появятся первые наблюдения',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Каждый чек-ин делает картину чётче. Не торопись.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _dayWord(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod100 >= 11 && mod100 <= 14) return 'дней';
    if (mod10 == 1) return 'день';
    if (mod10 >= 2 && mod10 <= 4) return 'дня';
    return 'дней';
  }
}

class _Insight {
  const _Insight({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String body;
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});
  final _Insight insight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.paperLift,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: insight.color.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: insight.color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(insight.icon, color: insight.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(insight.title, style: theme.textTheme.titleLarge),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(insight.body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
