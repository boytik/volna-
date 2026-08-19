import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/content/quests.dart';
import '../../data/local/quest_storage.dart';
import '../../main.dart';
import '../checkin/checkin_screen.dart';
import 'quest_service.dart';

enum _Phase { checkin, quest, finished }

class QuestScreen extends StatefulWidget {
  const QuestScreen({super.key, required this.slot, required this.storage});

  final QuestSlot slot;
  final QuestStorage storage;

  @override
  State<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends State<QuestScreen> {
  late _Phase _phase;

  @override
  void initState() {
    super.initState();
    final existing = checkInStorage.getCheckIn(widget.slot, DateTime.now());
    _phase = existing.isEmpty ? _Phase.checkin : _Phase.quest;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    switch (_phase) {
      case _Phase.checkin:
        return CheckInScreen(
          slot: widget.slot,
          onDone: () => setState(() => _phase = _Phase.quest),
        );
      case _Phase.quest:
        return Scaffold(
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
              child: _buildQuest(theme),
            ),
          ),
        );
      case _Phase.finished:
        return Scaffold(
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
              child: _buildFinished(theme),
            ),
          ),
        );
    }
  }

  Widget _buildQuest(ThemeData theme) {
    final quest = QuestPicker.pickToday(widget.slot);
    final accent = widget.slot == QuestSlot.morning
        ? AppColors.dawn
        : AppColors.marked;
    final label = widget.slot == QuestSlot.morning
        ? 'УТРЕННИЙ ШАГ'
        : 'ВЕЧЕРНИЙ РИТУАЛ';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            Text(quest.duration, style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 24),
        Text(quest.title, style: theme.textTheme.displayLarge),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            child: Text(
              quest.description,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () async {
            HapticFeedback.mediumImpact();
            await widget.storage.markDoneToday(widget.slot);
            // День больше не пустой — снимаем «тихое напоминание» на вечер.
            await notificationService.rescheduleAll();
            if (!mounted) return;
            setState(() => _phase = _Phase.finished);
          },
          style: FilledButton.styleFrom(backgroundColor: accent),
          child: const Text('Сделал'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => context.go('/'),
          child: const Text('Не сейчас'),
        ),
      ],
    );
  }

  Widget _buildFinished(ThemeData theme) {
    final quest = QuestPicker.pickToday(widget.slot);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.markedWash.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 64,
              color: AppColors.marked,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Шаг сделан',
          textAlign: TextAlign.center,
          style: theme.textTheme.displayLarge,
        ),
        const SizedBox(height: 16),
        Text(
          quest.afterPhrase,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontStyle: FontStyle.italic,
            color: AppColors.inkSoft,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.paperSunk,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.eco_rounded, color: AppColors.marked, size: 18),
              const SizedBox(width: 8),
              Text(
                '+1 капля для древа',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const Spacer(),
        FilledButton(
          onPressed: () => context.go('/'),
          child: const Text('Вернуться'),
        ),
      ],
    );
  }
}
