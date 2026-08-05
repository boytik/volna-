import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/content/sos_techniques.dart';

/// «Практики» — центральная вкладка и главный вход, когда тяжело.
///
/// Техники сгруппированы по состоянию: сначала выбираешь «что я сейчас
/// чувствую», потом видишь подходящее. Раньше это был экран `/sos`,
/// куда вела одна кнопка с главной; теперь это вкладка, доступная
/// откуда угодно.
///
/// Сюда же переехали библиотека фраз и связь со специалистом: всё
/// это — что делать, когда тяжело, от техники до живого человека.
/// Раньше они лежали в «Ещё», а до того — под шестерёнкой.
class PracticesScreen extends StatelessWidget {
  const PracticesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.axis,
            AppSpacing.xxl,
            AppSpacing.axis,
            AppSpacing.xl,
          ),
          children: [
            Text('Что сейчас?', style: theme.textTheme.displayLarge),
            const SizedBox(height: AppSpacing.smd),
            Text(
              'Выбери своё состояние — найдём технику. '
              'Это не лечение, это пауза.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.xl),
            ...SosTrigger.values.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _TriggerBlock(trigger: t),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('ЕЩЁ ЧТО МОЖЕТ ПОМОЧЬ', style: theme.textTheme.labelSmall),
            const SizedBox(height: AppSpacing.sm),
            _LinkRow(
              title: 'Библиотека',
              note: 'Фразы на трудные моменты и ресурсы',
              route: '/library',
            ),
            _LinkRow(
              title: 'Специалист',
              note: 'Подготовиться к сессии, найти помощь',
              route: '/help',
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Если очень плохо — позвони 8-800-2000-122',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Строка оглавления: набранная, а не карточка с иконкой.
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

class _TriggerBlock extends StatelessWidget {
  const _TriggerBlock({required this.trigger});
  final SosTrigger trigger;

  Color get _accent {
    switch (trigger) {
      case SosTrigger.panic:
        return AppColors.coral;
      case SosTrigger.rage:
        return AppColors.terracotta;
      case SosTrigger.freeze:
        return AppColors.sageDeep;
      case SosTrigger.shame:
        return AppColors.peach;
      case SosTrigger.anxiety:
        return AppColors.saffron;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final techs = techniquesForTrigger(trigger);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paperLift,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 32,
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trigger.label, style: theme.textTheme.titleLarge),
                    Text(trigger.sub, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...techs.map(
            (t) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _TechniqueRow(technique: t),
            ),
          ),
        ],
      ),
    );
  }
}

class _TechniqueRow extends StatelessWidget {
  const _TechniqueRow({required this.technique});
  final SosTechnique technique;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: () {
          final route = technique.routeOverride ?? '/sos/technique/${technique.id}';
          context.push(route);
        },
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: technique.accent.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: Icon(technique.icon, color: technique.accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      technique.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(technique.duration, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              if (technique.contraindication != null)
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.coral,
                  size: 18,
                ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
