import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/leaves_device_mark.dart';

/// «Выговориться» — выбор способа: голосом или текстом.
///
/// Раньше в дневнике стояли две строки, и человеку приходилось решать
/// ещё до входа. Теперь вход один, а выбор здесь — и рядом с ним видно
/// то, чего иначе не узнать: **голос уходит на сервер, текст остаётся
/// на телефоне**. Это не мелкая деталь для этой аудитории, и она должна
/// стоять до нажатия, а не всплывать после.
class VentChoiceScreen extends StatelessWidget {
  const VentChoiceScreen({super.key});

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
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.axis,
            0,
            AppSpacing.marginRight,
            AppSpacing.xl,
          ),
          children: [
            Text('Выговориться', style: theme.textTheme.displayLarge),
            const SizedBox(height: AppSpacing.smd),
            Text(
              'Расскажи, что происходит. Я выслушаю и подберу одну вещь, '
              'которая может помочь прямо сейчас.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.xxl),
            _Way(
              icon: Icons.mic_none_rounded,
              title: 'Голосом',
              note: 'Зажми кнопку и говори. До 90 секунд — '
                  'иногда сказать легче, чем написать.',
              route: '/vent/voice',
              leavesDevice: true,
            ),
            _Way(
              icon: Icons.keyboard_outlined,
              title: 'Текстом',
              note: 'Столько, сколько захочется. '
                  'Остаётся на телефоне и никуда не уходит.',
              route: '/vent/text',
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Если сейчас невыносимо — 8-800-2000-122, круглосуточно '
              'и бесплатно.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Способ рассказать. Крупная цель: это главное действие экрана,
/// и выбирают его обычно не в лучшем состоянии.
class _Way extends StatelessWidget {
  const _Way({
    required this.icon,
    required this.title,
    required this.note,
    required this.route,
    this.leavesDevice = false,
  });

  final IconData icon;
  final String title;
  final String note;
  final String route;
  final bool leavesDevice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline,
              width: AppStroke.hairline,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 26, color: AppColors.accent),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child:
                            Text(title, style: theme.textTheme.headlineMedium),
                      ),
                      if (leavesDevice) ...[
                        const SizedBox(width: AppSpacing.sm),
                        const LeavesDeviceMark(),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(note, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
