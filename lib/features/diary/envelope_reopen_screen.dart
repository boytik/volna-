import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import '../../main.dart';

/// Экран переоткрытия конверта.
/// 3 действия: открыть и прочитать → ещё раз отложить → выбросить.
/// Большинство тревог через сутки воспринимаются иначе — это терапевтический эффект.
class EnvelopeReopenScreen extends StatelessWidget {
  const EnvelopeReopenScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = diaryStorage.all().where((e) => e.id == id).firstOrNull;

    if (entry == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Конверт не найден')),
      );
    }

    final thought = entry.payload['thought'] ?? '';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Конверт', style: theme.textTheme.displayLarge),
              const SizedBox(height: 8),
              Text(
                _ageString(entry.createdAt),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.peachSoft.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: AppColors.coral.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.format_quote_rounded,
                          color: AppColors.coral,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ТЫ НАПИСАЛА',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.coral,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      thought,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Что с этой мыслью сейчас?',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _ActionTile(
                accent: AppColors.sageDeep,
                icon: Icons.delete_outline_rounded,
                title: 'Выбросить',
                subtitle: 'Эта мысль больше не нужна. Отпустить.',
                onTap: () async {
                  // Сначала снимаем запланированный пуш: человек сознательно
                  // отпустил мысль, возвращать её через сутки нельзя.
                  final notifId = entry.envelopeNotificationId;
                  if (notifId != null) {
                    await notificationService.cancelEnvelope(notifId);
                  }
                  await diaryStorage.update(
                    entry.copyWith(
                      envelopeStatus: 'discarded',
                      clearNotificationId: true,
                    ),
                  );
                  if (context.mounted) context.pop();
                },
              ),
              const SizedBox(height: 10),
              _ActionTile(
                accent: AppColors.saffron,
                icon: Icons.schedule_rounded,
                title: 'Отложить ещё на день',
                subtitle: 'Пока не готова — пусть подождёт',
                onTap: () async {
                  // Старый пуш мог ещё не сработать (конверт открыли из списка) —
                  // снимаем, чтобы не пришло два.
                  final oldId = entry.envelopeNotificationId;
                  if (oldId != null) {
                    await notificationService.cancelEnvelope(oldId);
                  }
                  final notifId = await notificationService
                      .scheduleEnvelopeReopen(after: const Duration(days: 1));
                  await diaryStorage.update(
                    entry.copyWith(
                      envelopeStatus: 'sealed',
                      envelopeReopenAt:
                          DateTime.now().add(const Duration(days: 1)),
                      envelopeNotificationId: notifId == -1 ? null : notifId,
                      clearNotificationId: notifId == -1,
                    ),
                  );
                  if (context.mounted) context.pop();
                },
              ),
              const SizedBox(height: 10),
              _ActionTile(
                accent: AppColors.terracotta,
                icon: Icons.edit_note_rounded,
                title: 'Переписать',
                subtitle: 'Записать новую мысль про это',
                onTap: () async {
                  final notifId = entry.envelopeNotificationId;
                  if (notifId != null) {
                    await notificationService.cancelEnvelope(notifId);
                  }
                  await diaryStorage.update(
                    entry.copyWith(
                      envelopeStatus: 'reopened',
                      clearNotificationId: true,
                    ),
                  );
                  if (context.mounted) {
                    context.pop();
                    context.push('/diary/new/friend');
                  }
                },
              ),
              const Spacer(),
              Center(
                child: Text(
                  'Большинство мыслей через сутки звучат иначе. '
                  'Не торопись — посмотри.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ageString(DateTime d) {
    final hours = DateTime.now().difference(d).inHours;
    if (hours < 24) return 'Запечатан $hours ч назад';
    final days = hours ~/ 24;
    if (days == 1) return 'Запечатан вчера';
    return 'Запечатан $days дн. назад';
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.accent,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color accent;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.paperLift,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
