import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/content/quests.dart';
import '../../data/content/survival.dart';
import '../../main.dart';

/// Экран survival-квеста. Без анимаций, без чек-ина, без таймера.
class SurvivalScreen extends StatefulWidget {
  const SurvivalScreen({super.key, required this.slot});
  final QuestSlot slot;

  @override
  State<SurvivalScreen> createState() => _SurvivalScreenState();
}

class _SurvivalScreenState extends State<SurvivalScreen> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = survivalFor(widget.slot);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'РЕЖИМ ВЫЖИВАНИЯ',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.sos,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Text(q.title, style: theme.textTheme.displayLarge),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.paperLift,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  _done ? q.afterPhrase : q.action,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                    fontStyle: _done ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ),
              const Spacer(),
              if (!_done)
                FilledButton(
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    await questStorage.markDoneToday(widget.slot);
                    // День больше не пустой — снимаем «тихое напоминание».
                    await notificationService.rescheduleAll();
                    if (!mounted) return;
                    setState(() => _done = true);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                  ),
                  child: const Text('Сделала'),
                )
              else
                FilledButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Вернуться'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
