import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../data/content/questionnaires.dart';

class QuestionnaireListScreen extends StatelessWidget {
  const QuestionnaireListScreen({super.key});

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
            Text(
              'Опросники',
              style: theme.textTheme.displayLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Профессиональные шкалы. Помогают увидеть себя со стороны. '
              'Не диагноз, а зеркало. Можно проходить раз в 2 недели — '
              'или когда сама захочешь.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.peachSoft.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.shield_rounded,
                    color: AppColors.terracotta,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Если в процессе станет тяжело — закрой и приди в SOS. '
                      'Опросник может подождать.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ..._tile(context, QuestionnaireKind.csi, AppColors.sageDeep),
            const SizedBox(height: 12),
            ..._tile(context, QuestionnaireKind.pss, AppColors.saffron),
            const SizedBox(height: 12),
            ..._tile(context, QuestionnaireKind.pbi, AppColors.terracotta),
          ],
        ),
      ),
    );
  }

  List<Widget> _tile(
    BuildContext context,
    QuestionnaireKind kind,
    Color accent,
  ) {
    final theme = Theme.of(context);

    return [
      Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => context.push('/questionnaire/${kind.name}'),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 56,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(kind.title, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(kind.description, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text(
                        '${kind.duration} · ${kind.shortTitle}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
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
      ),
    ];
  }
}
