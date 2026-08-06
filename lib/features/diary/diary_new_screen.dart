import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/local/diary_storage.dart';
import '../../main.dart';
import '../vent/crisis_guard.dart';

/// Универсальный экран новой записи в дневник.
/// 3 формы — подбирается по [kind].
class DiaryNewScreen extends StatefulWidget {
  const DiaryNewScreen({super.key, required this.kind});
  final DiaryKind kind;

  @override
  State<DiaryNewScreen> createState() => _DiaryNewScreenState();
}

class _DiaryNewScreenState extends State<DiaryNewScreen> {
  final Map<String, TextEditingController> _controllers = {};

  TextEditingController _ctl(String key) =>
      _controllers.putIfAbsent(key, () => TextEditingController());

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Color get _accent {
    switch (widget.kind) {
      case DiaryKind.threeGood:
        return AppColors.saffron;
      case DiaryKind.envelope:
        return AppColors.coral;
      case DiaryKind.friendOnYourPlace:
        return AppColors.terracotta;
    }
  }

  String get _title => widget.kind.label;

  String get _intro {
    switch (widget.kind) {
      case DiaryKind.threeGood:
        return 'Назови 3 вещи, которые прошли не ужасно. Даже маленькие. '
            '«Ребёнок сам надел носок» — это уже хорошо.';
      case DiaryKind.envelope:
        return 'Напиши одну самую липкую мысль. Я закрою её в конверт. '
            'Завтра ты увидишь напоминание — открыть, отложить ещё, или выбросить.';
      case DiaryKind.friendOnYourPlace:
        return 'Запиши мысль, которая вызывает вину. А затем — что бы '
            'ты сказала лучшей подруге, если бы услышала такое от неё.';
    }
  }

  Future<void> _save() async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final payload = _collectPayload();
    final entry = DiaryEntry(
      id: id,
      kind: widget.kind,
      createdAt: DateTime.now(),
      payload: payload,
    );

    if (widget.kind == DiaryKind.envelope) {
      // Запечатываем и планируем переоткрытие через сутки.
      entry.envelopeStatus = 'sealed';
      final at = DateTime.now().add(const Duration(days: 1));
      entry.envelopeReopenAt = at;
      // Конверт обещает вернуть мысль завтра — без разрешения на уведомления
      // iOS тихо не покажет напоминание, а человек будет ждать. Спрашиваем
      // контекстно, ровно в этот момент. Не дали — конверт всё равно
      // запечатываем, просто без пуша (notifId == -1 → null).
      final granted = await notificationService.requestPermission();
      final notifId = granted
          ? await notificationService.scheduleEnvelopeReopen(
              after: const Duration(days: 1),
            )
          : -1;
      entry.envelopeNotificationId = notifId == -1 ? null : notifId;
    }

    await diaryStorage.add(entry);
    if (!mounted) return;

    // Запись сохраняем в любом случае — это её дневник. Но если в тексте есть
    // маркеры кризиса, вместо тихого возврата в список ведём к живой помощи.
    if (guardCrisis(context, payload.values.join(' '), replace: true)) return;

    context.pop();
  }

  Map<String, String> _collectPayload() {
    final map = <String, String>{};
    _controllers.forEach((k, v) {
      final t = v.text.trim();
      if (t.isNotEmpty) map[k] = t;
    });
    return map;
  }

  bool get _isValid {
    switch (widget.kind) {
      case DiaryKind.threeGood:
        return _ctl('one').text.trim().isNotEmpty ||
            _ctl('two').text.trim().isNotEmpty ||
            _ctl('three').text.trim().isNotEmpty;
      case DiaryKind.envelope:
        return _ctl('thought').text.trim().isNotEmpty;
      case DiaryKind.friendOnYourPlace:
        return _ctl('guilt').text.trim().isNotEmpty;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_title, style: theme.textTheme.displayLarge),
                const SizedBox(height: 8),
                Text(_intro, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildFields(theme),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _isValid ? _save : null,
                  style: FilledButton.styleFrom(backgroundColor: _accent),
                  child: Text(
                    widget.kind == DiaryKind.envelope
                        ? 'Запечатать'
                        : 'Сохранить',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFields(ThemeData theme) {
    switch (widget.kind) {
      case DiaryKind.threeGood:
        return Column(
          children: [
            _Field(
              controller: _ctl('one'),
              label: 'Первое',
              hint: 'например, выпила чай горячим',
              accent: _accent,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _ctl('two'),
              label: 'Второе',
              hint: 'например, ребёнок сам почистил зубы',
              accent: _accent,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _ctl('three'),
              label: 'Третье',
              hint: 'например, в окно светило солнце',
              accent: _accent,
              onChanged: () => setState(() {}),
            ),
          ],
        );
      case DiaryKind.envelope:
        return _Field(
          controller: _ctl('thought'),
          label: 'Мысль',
          hint: 'например, «завтра я не справлюсь на занятии»',
          accent: _accent,
          onChanged: () => setState(() {}),
          maxLines: 5,
        );
      case DiaryKind.friendOnYourPlace:
        return Column(
          children: [
            _Field(
              controller: _ctl('guilt'),
              label: 'Что говорит внутренний голос',
              hint: 'например, «я плохая мать, раз накричала»',
              accent: _accent,
              onChanged: () => setState(() {}),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.peachSoft.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                'Теперь представь — твоя лучшая подруга '
                'рассказывает тебе то же самое о себе. '
                'Что бы ты ей ответила?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _ctl('kind_response'),
              label: 'Что бы ты сказала подруге',
              hint: 'например, «ты устала, это нормально»',
              accent: _accent,
              onChanged: () => setState(() {}),
              maxLines: 3,
            ),
          ],
        );
    }
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.accent,
    required this.onChanged,
    this.maxLines = 2,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final Color accent;
  final VoidCallback onChanged;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: accent,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          minLines: maxLines.clamp(1, 2),
          onChanged: (_) => onChanged(),
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
            filled: true,
            fillColor: AppColors.paperLift,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(color: accent, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }
}
