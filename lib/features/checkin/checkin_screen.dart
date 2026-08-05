import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/colors.dart';
import '../../data/content/quests.dart';
import '../../data/local/checkin_storage.dart';
import '../../main.dart';

/// Микро-чек-ин: 2 вопроса, ~30 секунд.
/// Показывается перед началом утреннего/вечернего квеста.
/// На основании ресёрча: «короткий чек-ин > длинная анкета», эмодзи > слова.
class CheckInScreen extends StatefulWidget {
  const CheckInScreen({
    super.key,
    required this.slot,
    required this.onDone,
  });

  final QuestSlot slot;
  final VoidCallback onDone;

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  MoodValue? _mood;
  SleepValue? _sleep;

  bool get _canSubmit => _mood != null && _sleep != null;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    HapticFeedback.lightImpact();
    await checkInStorage.save(widget.slot, mood: _mood, sleep: _sleep);
    widget.onDone();
  }

  void _skip() => widget.onDone();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMorning = widget.slot == QuestSlot.morning;
    final accent = isMorning ? AppColors.saffron : AppColors.sageDeep;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isMorning ? 'УТРО' : 'ВЕЧЕР',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                  TextButton(
                    onPressed: _skip,
                    child: const Text('Пропустить'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                isMorning ? 'Как ты сейчас?' : 'Как день?',
                style: theme.textTheme.displayLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Не оценивай — просто заметь. Это займёт 30 секунд.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              _Label(text: 'Самочувствие', accent: accent),
              const SizedBox(height: 12),
              _MoodRow(
                value: _mood,
                onChanged: (v) => setState(() => _mood = v),
                accent: accent,
              ),
              const SizedBox(height: 28),
              _Label(
                text: isMorning ? 'Как спалось' : 'Как было сегодня',
                accent: accent,
              ),
              const SizedBox(height: 12),
              _SleepRow(
                value: _sleep,
                onChanged: (v) => setState(() => _sleep = v),
                accent: accent,
                isMorning: isMorning,
              ),
              const Spacer(),
              FilledButton(
                onPressed: _canSubmit ? _submit : null,
                style: FilledButton.styleFrom(backgroundColor: accent),
                child: const Text('Дальше'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text, required this.accent});
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: accent,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
    );
  }
}

class _MoodRow extends StatelessWidget {
  const _MoodRow({
    required this.value,
    required this.onChanged,
    required this.accent,
  });

  final MoodValue? value;
  final ValueChanged<MoodValue> onChanged;
  final Color accent;

  static const _items = [
    (MoodValue.bad, '😔', 'Плохо'),
    (MoodValue.neutral, '😐', 'Средне'),
    (MoodValue.good, '😊', 'Хорошо'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _items.map((item) {
        final isSel = value == item.$1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _Tile(
              emoji: item.$2,
              label: item.$3,
              selected: isSel,
              accent: accent,
              onTap: () => onChanged(item.$1),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SleepRow extends StatelessWidget {
  const _SleepRow({
    required this.value,
    required this.onChanged,
    required this.accent,
    required this.isMorning,
  });

  final SleepValue? value;
  final ValueChanged<SleepValue> onChanged;
  final Color accent;
  final bool isMorning;

  @override
  Widget build(BuildContext context) {
    final items = isMorning
        ? const [
            (SleepValue.bad, '😴', 'Плохо'),
            (SleepValue.normal, '🛌', 'Нормально'),
            (SleepValue.great, '✨', 'Отлично'),
          ]
        : const [
            (SleepValue.bad, '🌧', 'Тяжело'),
            (SleepValue.normal, '🌤', 'Нормально'),
            (SleepValue.great, '☀️', 'Хорошо'),
          ];

    return Row(
      children: items.map((item) {
        final isSel = value == item.$1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _Tile(
              emoji: item.$2,
              label: item.$3,
              selected: isSel,
              accent: accent,
              onTap: () => onChanged(item.$1),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent.withValues(alpha: 0.18) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? accent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
