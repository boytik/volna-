import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';

/// Подготовка к встрече с психологом — короткая форма из 3 вопросов
/// (в духе Stoic-app «prepare for therapy»).
/// Результат можно скопировать в буфер обмена.
class PrepareSessionScreen extends StatefulWidget {
  const PrepareSessionScreen({super.key});

  @override
  State<PrepareSessionScreen> createState() => _PrepareSessionScreenState();
}

class _PrepareSessionScreenState extends State<PrepareSessionScreen> {
  final _heaviest = TextEditingController();
  final _start = TextEditingController();
  final _helps = TextEditingController();

  @override
  void dispose() {
    _heaviest.dispose();
    _start.dispose();
    _helps.dispose();
    super.dispose();
  }

  String _composeText() {
    final lines = <String>[];
    if (_heaviest.text.trim().isNotEmpty) {
      lines.add('Что сейчас тяжелее всего:\n${_heaviest.text.trim()}');
    }
    if (_start.text.trim().isNotEmpty) {
      lines.add('\nКогда это началось:\n${_start.text.trim()}');
    }
    if (_helps.text.trim().isNotEmpty) {
      lines.add('\nЧто немного помогает:\n${_helps.text.trim()}');
    }
    return lines.join('\n');
  }

  Future<void> _copyToClipboard() async {
    final text = _composeText();
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Скопировано — можно отправить себе или сохранить'),
      ),
    );
  }

  bool get _hasAnyContent =>
      _heaviest.text.trim().isNotEmpty ||
      _start.text.trim().isNotEmpty ||
      _helps.text.trim().isNotEmpty;

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
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Записать для встречи',
                  style: theme.textTheme.displayLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Три коротких вопроса. На сессии у психолога часто из головы '
                  'вылетает то, ради чего пришла.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    children: [
                      _Field(
                        controller: _heaviest,
                        label: 'Что сейчас тяжелее всего',
                        hint: 'например, я перестала спать после того, как…',
                        accent: AppColors.coral,
                        onChanged: () => setState(() {}),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 14),
                      _Field(
                        controller: _start,
                        label: 'Когда это началось',
                        hint: 'примерно 2 месяца назад / после диагноза / после школы…',
                        accent: AppColors.terracotta,
                        onChanged: () => setState(() {}),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 14),
                      _Field(
                        controller: _helps,
                        label: 'Что хоть немного помогает',
                        hint: 'дыхание, прогулка, тишина, музыка…',
                        accent: AppColors.sageDeep,
                        onChanged: () => setState(() {}),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _hasAnyContent ? _copyToClipboard : null,
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Скопировать'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.accent,
    required this.onChanged,
    this.maxLines = 3,
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
          minLines: 2,
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
