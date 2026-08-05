import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/content/phrases.dart';
import '../../data/content/vent_keywords.dart';

/// Ответ на «выговорись»: признание + одна техника + одна фраза.
class VentResponseScreen extends StatelessWidget {
  const VentResponseScreen({super.key, required this.topic});
  final VentTopic topic;

  Color get _accent {
    switch (topic) {
      case VentTopic.anger:
        return AppColors.coral;
      case VentTopic.anxiety:
        return AppColors.saffron;
      case VentTopic.exhaustion:
        return AppColors.sageDeep;
      case VentTopic.guilt:
        return AppColors.terracotta;
      case VentTopic.sadness:
        return AppColors.peach;
      case VentTopic.general:
        return AppColors.terracotta;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = suggestionFor(topic);
    final phraseCategory = phraseCategories.firstWhere(
      (c) => c.id == s.fallbackPhraseCategoryId,
      orElse: () => phraseCategories.first,
    );
    // Случайная (не совсем — первая) фраза, чтобы не быть постоянно одной и той же.
    final phrase = phraseCategory.phrases[
        DateTime.now().millisecondsSinceEpoch %
            phraseCategory.phrases.length];

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
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: _accent.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.label,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    topic.acknowledgement,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'ОДНА ВЕЩЬ, КОТОРАЯ МОЖЕТ ПОМОЧЬ',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Material(
              color: AppColors.paperLift,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: InkWell(
                onTap: () => context.push(s.techniqueRoute),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.air_rounded, color: _accent),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.techniqueLabel,
                                style: theme.textTheme.titleLarge),
                            const SizedBox(height: 2),
                            Text(
                              'Открыть и сделать',
                              style: theme.textTheme.bodyMedium,
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
            const SizedBox(height: 24),
            Text(
              'НА ПАМЯТЬ',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.paperLift,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.format_quote_rounded,
                      color: AppColors.terracotta,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      phrase,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Material(
              color: AppColors.peachSoft.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: InkWell(
                onTap: () => context.push('/help'),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.support_agent_rounded,
                        color: AppColors.terracotta,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Если этого мало — есть живая помощь',
                          style: theme.textTheme.bodyLarge,
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
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('Спасибо, на главную'),
            ),
          ],
        ),
      ),
    );
  }
}
