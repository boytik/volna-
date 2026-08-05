import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../data/content/badges.dart' as badge_data;
import '../../main.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlocked = badgesStorage.all();
    final unlockedCount = badge_data.allBadges
        .where((b) => unlocked.contains(b.id))
        .length;

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
            Text('Знаки присутствия', style: theme.textTheme.displayLarge),
            const SizedBox(height: 8),
            Text(
              'Это не ачивки. Это места, где ты была. '
              'Открыто $unlockedCount из ${badge_data.allBadges.length}.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: badge_data.allBadges.length,
              itemBuilder: (_, i) {
                final b = badge_data.allBadges[i];
                final isUnlocked = unlocked.contains(b.id);
                return _BadgeCard(badge: b, unlocked: isUnlocked);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge, required this.unlocked});
  final badge_data.Badge badge;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = unlocked ? badge.color : AppColors.textMuted;

    return GestureDetector(
      onTap: () => _showDetails(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: unlocked ? Colors.white : AppColors.cream,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: unlocked
                ? color.withValues(alpha: 0.4)
                : AppColors.textMuted.withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: unlocked ? 0.22 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                unlocked ? badge.icon : Icons.lock_outline_rounded,
                color: color,
                size: 26,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              unlocked ? badge.title : '?',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: unlocked ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: badge.color.withValues(alpha: unlocked ? 0.22 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  unlocked ? badge.icon : Icons.lock_outline_rounded,
                  color: unlocked ? badge.color : AppColors.textMuted,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                unlocked ? badge.title : 'Пока скрыто',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                unlocked
                    ? badge.description
                    : 'Этот знак откроется неожиданно. '
                        'Никаких счётчиков и спойлеров.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
