import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/content/badges.dart' as badge_data;

/// Модалка-приветствие при открытии нового значка.
/// Показываем по одному (для нескольких — стек последовательно).
class NewBadgeOverlay {
  static Future<void> showAll(
    BuildContext context,
    List<badge_data.Badge> badges,
  ) async {
    for (final b in badges) {
      if (!context.mounted) return;
      HapticFeedback.lightImpact();
      await showDialog<void>(
        context: context,
        barrierColor: Colors.black54,
        builder: (_) => _BadgeDialog(badge: b),
      );
    }
  }
}

class _BadgeDialog extends StatelessWidget {
  const _BadgeDialog({required this.badge});
  final badge_data.Badge badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'НОВЫЙ ЗНАК',
              style: theme.textTheme.bodySmall?.copyWith(
                color: badge.color,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    badge.color.withValues(alpha: 0.32),
                    badge.color.withValues(alpha: 0.12),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: badge.color.withValues(alpha: 0.3),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(badge.icon, color: badge.color, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              badge.title,
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              badge.description,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(backgroundColor: badge.color),
              child: const Text('Хорошо'),
            ),
          ],
        ),
      ),
    );
  }
}
