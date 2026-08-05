import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/widgets/helped_button.dart';
import '../../data/local/toolbox_storage.dart';

/// Самосострадание «Ладонь на сердце».
/// 3 шага: признание боли, нормализация, разрешение себе быть неидеальным.
class SelfCompassionScreen extends StatefulWidget {
  const SelfCompassionScreen({super.key});

  @override
  State<SelfCompassionScreen> createState() => _SelfCompassionScreenState();
}

class _SelfCompassionScreenState extends State<SelfCompassionScreen> {
  static const _phrases = <_Phrase>[
    _Phrase(
      step: 'Признание',
      text: 'Сейчас очень трудно',
      hint: 'Положи тёплую ладонь на грудь. Сделай медленный вдох. '
          'Скажи это про себя — без оценок.',
    ),
    _Phrase(
      step: 'Нормализация',
      text: 'Усталость и отчаяние бывают у всех родителей,\nкто в такой ситуации',
      hint: 'Ты не одна(ин). Миллионы родителей проходят через похожее.',
    ),
    _Phrase(
      step: 'Разрешение',
      text: 'Позволяю себе быть неидеальной\nпрямо сейчас',
      hint: 'Без «всё будет хорошо». Это не позитивное мышление — '
          'это просто разрешение быть собой.',
    ),
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _index == _phrases.length - 1;
    final isFinished = _index >= _phrases.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          child: isFinished ? _buildFinished(theme) : _buildStep(theme, isLast),
        ),
      ),
    );
  }

  Widget _buildStep(ThemeData theme, bool isLast) {
    final phrase = _phrases[_index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Шаг ${_index + 1} из ${_phrases.length} · ${phrase.step}',
          style: theme.textTheme.bodyMedium,
        ),
        const Spacer(),
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.peach.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              size: 48,
              color: AppColors.terracotta,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          '«${phrase.text}»',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineLarge?.copyWith(height: 1.3),
        ),
        const SizedBox(height: 20),
        Text(
          phrase.hint,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const Spacer(),
        FilledButton(
          onPressed: () => setState(() => _index++),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.terracotta,
          ),
          child: Text(isLast ? 'Готово' : 'Дальше'),
        ),
      ],
    );
  }

  Widget _buildFinished(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.peach.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              size: 64,
              color: AppColors.terracotta,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Твоя любовь\nуже достаточна',
          textAlign: TextAlign.center,
          style: theme.textTheme.displayLarge?.copyWith(height: 1.2),
        ),
        const SizedBox(height: 16),
        Text(
          'Чувство вины говорит о твоей любви. Не о вине.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const Spacer(),
        const Center(child: HelpedButton(tool: ToolKey.selfCompassion)),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => context.go('/'),
          child: const Text('Вернуться'),
        ),
      ],
    );
  }
}

class _Phrase {
  const _Phrase({required this.step, required this.text, required this.hint});
  final String step;
  final String text;
  final String hint;
}
