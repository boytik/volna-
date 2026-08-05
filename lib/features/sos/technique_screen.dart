import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/helped_button.dart';
import '../../data/content/sos_techniques.dart';
import '../../data/local/toolbox_storage.dart';

/// Универсальный экран SOS-техники.
/// Если у техники есть routeOverride — мы туда не попадаем (роутер ведёт сразу).
/// Этот экран — для пошаговых техник без специальной анимации.
class TechniqueScreen extends StatefulWidget {
  const TechniqueScreen({super.key, required this.id});
  final String id;

  @override
  State<TechniqueScreen> createState() => _TechniqueScreenState();
}

class _TechniqueScreenState extends State<TechniqueScreen> {
  int _step = 0;
  bool _ackContraindication = false;

  @override
  Widget build(BuildContext context) {
    final tech = techniqueById(widget.id);
    if (tech == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Техника не найдена')),
      );
    }

    final theme = Theme.of(context);

    // Если есть противопоказания и пользователь ещё не подтвердил — показываем экран-предупреждение.
    if (tech.contraindication != null && !_ackContraindication) {
      return _ContraindicationScreen(
        tech: tech,
        onAck: () => setState(() => _ackContraindication = true),
      );
    }

    final isLast = _step == tech.steps.length - 1;
    final isFinished = _step >= tech.steps.length;
    final step = isFinished ? null : tech.steps[_step];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/sos'),
        ),
        title: Text(
          tech.title,
          style: theme.textTheme.titleLarge,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: isFinished
              ? _buildFinished(theme, tech)
              : _buildStep(theme, tech, step!, isLast),
        ),
      ),
    );
  }

  Widget _buildStep(
    ThemeData theme,
    SosTechnique tech,
    TechniqueStep step,
    bool isLast,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: LinearProgressIndicator(
            value: (_step + 1) / tech.steps.length,
            minHeight: 5,
            backgroundColor: AppColors.textMuted.withValues(alpha: 0.18),
            valueColor: AlwaysStoppedAnimation(tech.accent),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Шаг ${_step + 1} из ${tech.steps.length}',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: tech.accent.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(tech.icon, color: tech.accent, size: 40),
          ),
        ),
        const SizedBox(height: 24),
        Text(step.heading, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Text(
              step.body,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
          ),
        ),
        FilledButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            setState(() => _step++);
          },
          style: FilledButton.styleFrom(backgroundColor: tech.accent),
          child: Text(isLast ? 'Готово' : 'Дальше'),
        ),
      ],
    );
  }

  Widget _buildFinished(ThemeData theme, SosTechnique tech) {
    final tool = _toolKeyFor(tech);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.sage.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 64,
              color: AppColors.sageDeep,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Сделано',
          textAlign: TextAlign.center,
          style: theme.textTheme.displayLarge,
        ),
        const SizedBox(height: 16),
        Text(
          tech.afterPhrase,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontStyle: FontStyle.italic,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const Spacer(),
        if (tool != null) Center(child: HelpedButton(tool: tool)),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => context.go('/'),
          child: const Text('Вернуться'),
        ),
      ],
    );
  }

  ToolKey? _toolKeyFor(SosTechnique tech) {
    // Маппим часть техник на ToolBox для подсказки на главной.
    switch (tech.id) {
      case 'physiological_sigh':
      case 'extended_exhale':
        return ToolKey.breathing;
      case 'micro_movements':
      case 'detective':
        return ToolKey.grounding;
      case 'butterfly_hug':
      case 'name_and_fact':
        return ToolKey.selfCompassion;
      default:
        return null;
    }
  }
}

class _ContraindicationScreen extends StatelessWidget {
  const _ContraindicationScreen({required this.tech, required this.onAck});
  final SosTechnique tech;
  final VoidCallback onAck;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/sos'),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(tech.title, style: theme.textTheme.displayLarge),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.coral.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: AppColors.coral.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.coral,
                        ),
                        const SizedBox(width: 8),
                        Text('Важно знать',
                            style: theme.textTheme.titleLarge),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tech.contraindication!,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: onAck,
                style: FilledButton.styleFrom(
                  backgroundColor: tech.accent,
                ),
                child: const Text('Поняла, продолжить'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/sos'),
                child: const Text('Выбрать другую технику'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
