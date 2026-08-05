import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../data/content/vent_keywords.dart';
import 'crisis_guard.dart';

/// «Выговорись» — поле ввода (можно диктовать через клавиатуру iOS).
/// При отправке: локальный анализ темы → отдельный экран с поддержкой.
class VentScreen extends StatefulWidget {
  const VentScreen({super.key});

  @override
  State<VentScreen> createState() => _VentScreenState();
}

class _VentScreenState extends State<VentScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();

    // Жёсткий слой: кризис прерывает обычный поток до подбора темы и техники.
    if (guardCrisis(context, text)) return;

    final topic = detectTopic(text);
    context.go('/vent/response?topic=${topic.name}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasText = _controller.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Выговорись', style: theme.textTheme.displayLarge),
                const SizedBox(height: 8),
                Text(
                  'Никто этого не увидит. Я просто выслушаю и предложу '
                  'одну вещь, которая может помочь сейчас. '
                  'Можно надиктовать — нажми микрофон на клавиатуре.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focus,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: theme.textTheme.bodyLarge,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText:
                            'Что внутри сейчас? Пиши как есть — без точек, без формы. '
                            'Например: «опять накричала, чувствую себя дрянью»',
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                          height: 1.5,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: hasText ? _submit : null,
                  child: const Text('Я выслушаю'),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Я не пересылаю это никому и не сохраняю в облаке',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
