import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/widgets/helped_button.dart';
import '../../data/local/toolbox_storage.dart';

/// Заземление 5-4-3-2-1: пошаговое возвращение в «здесь и сейчас».
class GroundingScreen extends StatefulWidget {
  const GroundingScreen({super.key});

  @override
  State<GroundingScreen> createState() => _GroundingScreenState();
}

class _GroundingScreenState extends State<GroundingScreen> {
  static const _steps = <_Step>[
    _Step(5, 'предметов', 'которые ты видишь', Icons.visibility_rounded),
    _Step(4, 'поверхности', 'которые ощущаешь под пальцами или стопами', Icons.touch_app_rounded),
    _Step(3, 'звука', 'которые сейчас слышишь', Icons.hearing_rounded),
    _Step(2, 'запаха', 'которые сейчас чувствуешь', Icons.spa_rounded),
    _Step(1, 'вкус', 'или движение языка по нёбу', Icons.coffee_rounded),
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _index == _steps.length - 1;
    final isFinished = _index >= _steps.length;

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
    final step = _steps[_index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Шаг ${_index + 1} из ${_steps.length}',
          style: theme.textTheme.bodyMedium,
        ),
        const Spacer(),
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.dawn.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(step.icon, size: 48, color: AppColors.dawn),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Назови ${step.count} ${step.what}',
          textAlign: TextAlign.center,
          style: theme.textTheme.displayLarge?.copyWith(height: 1.2),
        ),
        const SizedBox(height: 12),
        Text(
          step.hint,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.inkSoft,
          ),
        ),
        const Spacer(),
        FilledButton(
          onPressed: () => setState(() => _index++),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.dawn,
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
              color: AppColors.markedWash.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 64,
              color: AppColors.marked,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Ты вернулся.\nЗдесь и сейчас.',
          textAlign: TextAlign.center,
          style: theme.textTheme.displayLarge?.copyWith(height: 1.2),
        ),
        const SizedBox(height: 16),
        Text(
          'Тревога живёт в будущем, которого ещё нет. '
          'Ты — здесь, на земле, в своём теле.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const Spacer(),
        const Center(child: HelpedButton(tool: ToolKey.grounding)),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => context.go('/'),
          child: const Text('Вернуться'),
        ),
      ],
    );
  }
}

class _Step {
  const _Step(this.count, this.what, this.hint, this.icon);
  final int count;
  final String what;
  final String hint;
  final IconData icon;
}
