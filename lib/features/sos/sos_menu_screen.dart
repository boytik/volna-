import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/content/sos_techniques.dart';

/// Меню SOS — техники сгруппированы по триггерному состоянию.
/// Это даёт пользователю быстрый путь: сначала выбираешь «что я сейчас чувствую»,
/// потом видишь подходящие техники.
class SosMenuScreen extends StatelessWidget {
  const SosMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Text('Что сейчас?', style: theme.textTheme.displayLarge),
            const SizedBox(height: 8),
            Text(
              'Выбери своё состояние — найдём технику. '
              'Это не лечение, это пауза.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ...SosTrigger.values.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _TriggerBlock(trigger: t),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Если очень плохо — позвони 8-800-2000-122',
                style: theme.textTheme.bodySmall,
              ),
            ),
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
