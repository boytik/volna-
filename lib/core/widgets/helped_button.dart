import 'package:flutter/material.dart';

import '../../data/local/toolbox_storage.dart';
import '../../main.dart';
import '../theme/colors.dart';

/// Кнопка «помогло» в конце SOS-техник. Тап → +1 в toolbox, лёгкая анимация.
class HelpedButton extends StatefulWidget {
  const HelpedButton({super.key, required this.tool});
  final ToolKey tool;

  @override
  State<HelpedButton> createState() => _HelpedButtonState();
}

class _HelpedButtonState extends State<HelpedButton> {
  bool _saved = false;

  Future<void> _save() async {
    if (_saved) return;
    await toolBoxStorage.markHelpful(widget.tool);
    if (!mounted) return;
    setState(() => _saved = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_saved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.sage.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.sageDeep,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Запомнила. Что помогло — теперь твоё.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.sageDeep,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return TextButton.icon(
      onPressed: _save,
      icon: const Icon(Icons.favorite_border_rounded, size: 18),
      label: const Text('Помогло — запомнить'),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.terracotta,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }
}
