import 'package:flutter/material.dart';

import '../../data/local/toolbox_storage.dart';
import '../../main.dart';
import '../theme/colors.dart';
import '../theme/tokens.dart';

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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.smd,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadius.smR,
          border: Border.all(
            color: AppColors.marked,
            width: AppStroke.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_rounded, color: AppColors.marked, size: 16),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                'Запомнила. Что помогло — теперь твоё.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.marked),
              ),
            ),
          ],
        ),
      );
    }

    return OutlinedButton(
      onPressed: _save,
      child: const Text('Помогло — запомнить'),
    );
  }
}
