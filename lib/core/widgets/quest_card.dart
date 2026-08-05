import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// Карточка ежедневного квеста (утренний / вечерний).
class QuestCard extends StatelessWidget {
  const QuestCard({
    super.key,
    required this.label,
    required this.title,
    required this.description,
    required this.duration,
    required this.accent,
    required this.onStart,
    this.onSkip,
  });

  final String label; // «Утренний шаг» / «Вечерний ритуал»
  final String title;
  final String description;
  final String duration; // «2 минуты»
  final Color accent;
  final VoidCallback onStart;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                duration,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(title, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(description, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onStart,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                  ),
                  child: const Text('Сделать шаг'),
                ),
              ),
              if (onSkip != null) ...[
                const SizedBox(width: 12),
                TextButton(
                  onPressed: onSkip,
                  child: const Text('Не сейчас'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
