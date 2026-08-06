import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/content/anchor_options.dart';
import '../../data/content/specialists.dart';
import '../../data/local/wipe.dart';
import '../../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _enabled;
  String? _morning;
  String? _evening;
  bool _survival = false;
  bool _cloudVoice = false;
  int? _morningHour;
  int? _eveningHour;

  @override
  void initState() {
    super.initState();
    _enabled = settingsStorage.notificationsEnabled;
    _morning = settingsStorage.morningAnchorId;
    _evening = settingsStorage.eveningAnchorId;
    _survival = settingsStorage.survivalMode;
    _cloudVoice = settingsStorage.cloudVoiceConsent;
    _morningHour = settingsStorage.morningHour;
    _eveningHour = settingsStorage.eveningHour;
  }

  Future<void> _confirmWipe() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить все данные?'),
        content: const Text(
          'Исчезнет всё: дневник и конверты, чек-ины, результаты опросников, '
          'значки и настройки. Вернуть будет нельзя.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.coral),
            child: const Text('Удалить всё'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await wipeAllLocalData(
      cancelNotifications: notificationService.cancelAll,
    );
    if (!mounted) return;
    // Данных больше нет — начинаем с чистого листа, как при первом запуске.
    context.go('/onboarding');
  }

  Future<void> _apply() async {
    await settingsStorage.setNotificationsEnabled(_enabled);
    await settingsStorage.setMorningAnchor(_morning);
    await settingsStorage.setEveningAnchor(_evening);
    await settingsStorage.setSurvivalMode(_survival);

    if (_enabled) {
      final granted = await notificationService.requestPermission();
      if (granted) {
        await notificationService.rescheduleAll();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Разрешение на уведомления не дано. '
              'Включить можно в настройках телефона.',
            ),
          ),
        );
      }
    } else {
      await notificationService.rescheduleAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Корень вкладки: кнопки «назад» здесь нет, уходят другой вкладкой.
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.axis,
            AppSpacing.xxl,
            AppSpacing.axis,
            AppSpacing.xl,
          ),
          children: [
            Text('Настройки', style: theme.textTheme.displayLarge),
            const SizedBox(height: 28),
            _Section(
              title: 'Напоминания',
              subtitle: 'Утром и вечером — мягкий пуш с фразой. '
                  'Если выключишь, всё работает как обычно, просто без подсказок.',
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _enabled,
                    onChanged: (v) async {
                      setState(() => _enabled = v);
                      await _apply();
                    },
                    title: const Text('Включить напоминания'),
                  ),
                  if (_enabled) ...[
                    const SizedBox(height: 16),
                    Text('УТРОМ', style: _label(theme)),
                    const SizedBox(height: 8),
                    _AnchorList(
                      options: morningAnchors,
                      selected: _morning,
                      accent: AppColors.saffron,
                      onTap: (id) async {
                        setState(() => _morning = _morning == id ? null : id);
                        await _apply();
                      },
                    ),
                    _HourRow(
                      label: 'Во сколько напомнить утром',
                      hour: _morningHour,
                      defaultHour: 8,
                      accent: AppColors.saffron,
                      onPick: (h) async {
                        setState(() => _morningHour = h);
                        await settingsStorage.setMorningHour(h);
                        await _apply();
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('ВЕЧЕРОМ', style: _label(theme)),
                    const SizedBox(height: 8),
                    _AnchorList(
                      options: eveningAnchors,
                      selected: _evening,
                      accent: AppColors.sageDeep,
                      onTap: (id) async {
                        setState(() => _evening = _evening == id ? null : id);
                        await _apply();
                      },
                    ),
                    _HourRow(
                      label: 'Во сколько напомнить вечером',
                      hour: _eveningHour,
                      defaultHour: 21,
                      accent: AppColors.sageDeep,
                      onPick: (h) async {
                        setState(() => _eveningHour = h);
                        await settingsStorage.setEveningHour(h);
                        await _apply();
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'Режим выживания',
              subtitle: 'Когда сегодня всё рушится. Квесты становятся '
                  'короче — 30 секунд вместо 2-3 минут. Без анимаций, без счёта капель. '
                  'Можно включать и выключать в любой момент.',
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _survival,
                onChanged: (v) async {
                  setState(() => _survival = v);
                  await _apply();
                },
                title: const Text('Включить режим выживания'),
              ),
            ),
            // Календарь и «что я заметила» живут в «Пути» — это рефлексия,
            // а не конфигурация. Опросники по просьбе заказчицы вернули сюда
            // (секция ниже): их удобнее находить под шестерёнкой.
            const SizedBox(height: 24),
            _Section(
              title: 'Данные',
              subtitle: 'Дневник, чек-ины и опросники хранятся только на этом '
                  'телефоне. В облако уходит одно — голос из «Выговорись».',
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _cloudVoice,
                    onChanged: (v) async {
                      setState(() => _cloudVoice = v);
                      await settingsStorage.setCloudVoiceConsent(v);
                    },
                    title: const Text('Разбирать голос через облако'),
                    subtitle: const Text(
                      'Выключишь — «Выговорись» останется, но только текстом',
                    ),
                  ),
                  _LinkRow(
                    icon: Icons.shield_outlined,
                    accent: AppColors.sageDeep,
                    title: 'Что происходит с данными',
                    subtitle: 'Коротко и без юридического языка',
                    onTap: () => context.push('/privacy'),
                  ),
                  _LinkRow(
                    icon: Icons.delete_outline_rounded,
                    accent: AppColors.coral,
                    title: 'Удалить все мои данные',
                    subtitle: 'Стереть всё с этого телефона, без возврата',
                    onTap: _confirmWipe,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'Опросники',
              subtitle: 'Короткие шкалы — свериться с собой, когда захочется.',
              child: _LinkRow(
                icon: Icons.fact_check_outlined,
                accent: AppColors.sageDeep,
                title: 'Пройти опросник',
                subtitle: 'PSS, PBI, CSI — когда захочется',
                onTap: () => context.push('/questionnaire'),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Если очень тяжело — $crisisPhoneLabel',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle? _label(ThemeData theme) => theme.textTheme.bodySmall?.copyWith(
        color: AppColors.terracotta,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      );
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.paperLift,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(subtitle, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
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
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Выбор часа напоминания.
///
/// `setMorningHour`/`setEveningHour` в SettingsStorage существовали и читались
/// сервисом уведомлений, но задать час было негде — время бралось только из
/// «якоря». Пустое значение = час по умолчанию из выбранного якоря.
class _HourRow extends StatelessWidget {
  const _HourRow({
    required this.label,
    required this.hour,
    required this.defaultHour,
    required this.accent,
    required this.onPick,
  });

  final String label;
  final int? hour;
  final int defaultHour;
  final Color accent;
  final ValueChanged<int?> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effective = hour ?? defaultHour;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          if (hour != null)
            TextButton(
              onPressed: () => onPick(null),
              child: const Text('Сбросить'),
            ),
          TextButton(
            onPressed: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: effective, minute: 0),
                helpText: label,
                // Минуты не используем: расписание построено на целых часах.
                initialEntryMode: TimePickerEntryMode.dial,
              );
              if (picked != null) onPick(picked.hour);
            },
            child: Text(
              '${effective.toString().padLeft(2, '0')}:00',
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnchorList extends StatelessWidget {
  const _AnchorList({
    required this.options,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final List<AnchorOption> options;
  final String? selected;
  final Color accent;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((a) {
        final isSel = a.id == selected;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Material(
            color: isSel ? accent.withValues(alpha: 0.18) : AppColors.cream,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: InkWell(
              onTap: () => onTap(a.id),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: isSel ? accent : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSel ? Icons.check_circle_rounded : Icons.circle_outlined,
                      color: isSel ? accent : AppColors.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(a.text)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
