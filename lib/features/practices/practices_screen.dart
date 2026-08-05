import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/content/sos_techniques.dart';

/// «Практики» — центральная вкладка и главный вход, когда тяжело.
///
/// Состояния свёрнуты. Раньше все пять раскрывались сразу, экран
/// уезжал на три с лишним высоты, и человеку в остром состоянии
/// приходилось прокручивать чужие техники, чтобы добраться до своих.
/// Теперь сначала видно весь список состояний целиком — «что я сейчас
/// чувствую» — и раскрывается только нужное.
///
/// Открыто всегда одно: два раскрытых блока возвращают ту же простыню,
/// от которой уходили.
class PracticesScreen extends StatefulWidget {
  const PracticesScreen({super.key});

  @override
  State<PracticesScreen> createState() => _PracticesScreenState();
}

class _PracticesScreenState extends State<PracticesScreen> {
  /// null — всё свёрнуто. Это и есть состояние по умолчанию: в кризис
  /// человек должен увидеть список состояний, а не чужую технику.
  SosTrigger? _open;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.axis,
            AppSpacing.lg,
            AppSpacing.axis,
            AppSpacing.xl,
          ),
          children: [
            Text('Что сейчас?', style: theme.textTheme.displayLarge),
            const SizedBox(height: AppSpacing.smd),
            Text(
              'Выбери своё состояние — найдём технику. '
              'Это не лечение, это пауза.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final t in SosTrigger.values)
              _TriggerBlock(
                trigger: t,
                expanded: _open == t,
                onTap: () => setState(() => _open = _open == t ? null : t),
              ),
            // Нижняя линейка, чтобы последний блок не висел в воздухе.
            Container(
              height: AppStroke.hairline,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: AppSpacing.lg),
            _LinkRow(
              title: 'Библиотека',
              note: 'Фразы на трудные моменты и ресурсы',
              route: '/library',
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Если очень плохо — позвони 8-800-2000-122',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Состояние: заголовок всегда виден, техники раскрываются по тапу.
class _TriggerBlock extends StatelessWidget {
  const _TriggerBlock({
    required this.trigger,
    required this.expanded,
    required this.onTap,
  });

  final SosTrigger trigger;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final techs = techniquesForTrigger(trigger);
    final accent = theme.brightness == Brightness.dark
        ? AppColors.nightAccent
        : AppColors.accentPress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trigger.label,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: expanded ? accent : null,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(trigger.sub, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.smd),
                // Шеврон, а не «+»: раскрытие, а не добавление.
                // Поворот без пружины — только длинный ease-out.
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: AppMotion.stateFor(context),
                  curve: AppMotion.enter,
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 22,
                    color: expanded ? accent : theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: AppMotion.stateFor(context),
          curve: AppMotion.enter,
          alignment: Alignment.topCenter,
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final t in techs) _TechniqueRow(technique: t),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Техника внутри раскрытого состояния. Не карточка: отступ слева
/// показывает вложенность, круглых подложек под иконками нет.
class _TechniqueRow extends StatelessWidget {
  const _TechniqueRow({required this.technique});
  final SosTechnique technique;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => context.push(
        technique.routeOverride ?? '/sos/technique/${technique.id}',
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.smd,
          0,
          AppSpacing.smd,
        ),
        child: Row(
          children: [
            Icon(technique.icon, size: 20, color: AppColors.accent),
            const SizedBox(width: AppSpacing.smd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(technique.title, style: theme.textTheme.titleLarge),
                  Text(technique.duration, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (technique.contraindication != null)
              Tooltip(
                message: technique.contraindication!,
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Строка оглавления: набранная, а не карточка с иконкой.
class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.title,
    required this.note,
    required this.route,
  });

  final String title;
  final String note;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outline,
              width: AppStroke.hairline,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(note, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
