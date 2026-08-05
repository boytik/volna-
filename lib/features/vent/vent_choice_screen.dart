import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/leaves_device_mark.dart';
import '../../services/on_device_transcribe_service.dart';

/// «Выговориться» — выбор способа: голосом или текстом.
///
/// Раньше в дневнике стояли две строки, и человеку приходилось решать
/// ещё до входа. Теперь вход один, а выбор здесь — и рядом с ним видно
/// то, чего иначе не узнать: что именно покидает телефон.
///
/// Ответ на это зависит от телефона. Если система распознаёт речь сама,
/// аудио не уходит никуда, и знак «уходит на сервер» не показывается —
/// иначе он перестанет что-либо значить. Поэтому экран спрашивает
/// платформу до того, как что-то показать.
class VentChoiceScreen extends StatefulWidget {
  const VentChoiceScreen({super.key});

  @override
  State<VentChoiceScreen> createState() => _VentChoiceScreenState();
}

class _VentChoiceScreenState extends State<VentChoiceScreen> {
  final _onDevice = OnDeviceTranscribeService();

  /// null — ещё не знаем. Пока не знаем, про приватность молчим:
  /// сказать неточно хуже, чем подождать сотню миллисекунд.
  bool? _voiceStaysOnDevice;

  @override
  void initState() {
    super.initState();
    _probe();
  }

  Future<void> _probe() async {
    final onDevice = await _onDevice.supportsOnDevice();
    if (!mounted) return;
    setState(() => _voiceStaysOnDevice = onDevice);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final known = _voiceStaysOnDevice != null;
    final local = _voiceStaysOnDevice ?? false;

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
              note: !known
                  ? 'Зажми кнопку и говори. До 90 секунд.'
                  : local
                      ? 'Зажми кнопку и говори. До 90 секунд. Речь '
                          'распознаётся прямо на телефоне — запись никуда '
                          'не уходит.'
                      : 'Зажми кнопку и говори. До 90 секунд. Этот телефон '
                          'не умеет распознавать речь без интернета, поэтому '
                          'запись уйдёт на расшифровку.',
              route: '/vent/voice',
              leavesDevice: known && !local,
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
