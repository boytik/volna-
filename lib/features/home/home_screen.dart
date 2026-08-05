import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/widgets/quest_card.dart';
import '../../core/widgets/sos_button.dart';
import '../../data/content/quests.dart';
import '../../data/content/survival.dart';
import '../../data/local/toolbox_storage.dart';
import '../../main.dart';
import '../badges/new_badge_overlay.dart';
import '../quest/quest_service.dart';
import '../tree/tree_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkBadges());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
      _checkBadges();
    }
  }

  Future<void> _checkBadges() async {
    final newly = await badgesService.checkUnlocks();
    if (!mounted || newly.isEmpty) return;
    await NewBadgeOverlay.showAll(context, newly);
    if (mounted) setState(() {});
  }

  Future<void> _go(String path) async {
    await context.push(path);
    if (!mounted) return;
    setState(() {});
    _checkBadges();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMorning = DateTime.now().hour < 17;
    final slot = isMorning ? QuestSlot.morning : QuestSlot.evening;
    final isDone = questStorage.isDoneToday(slot);
    final drops = questStorage.drops;
    final daysSince = questStorage.daysSinceActivity;
    final didToday = daysSince == 0;
    final treeMood = moodFromActivity(
      didSomethingToday: didToday,
      daysSinceActivity: daysSince,
    );
    final survivalMode = settingsStorage.survivalMode;
    final readyEnvelopes = diaryStorage.envelopesReadyToReopen;
    final topTool = toolBoxStorage.topTool();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeHeader(isMorning: isMorning),
              const SizedBox(height: 28),
              if (readyEnvelopes.isNotEmpty) ...[
                _EnvelopeBanner(
                  count: readyEnvelopes.length,
                  onTap: () => context.push(
                    '/diary/envelope/${readyEnvelopes.first.id}',
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TreeCard(
                drops: drops,
                mood: treeMood,
                onTap: () => _go('/tree'),
              ),
              const SizedBox(height: 28),
              SosButton(onTap: () => _go('/sos')),
              const SizedBox(height: 12),
              _VentCard(onTap: () => _go('/vent')),
              const SizedBox(height: 28),
              if (survivalMode)
                _SurvivalCard(
                  isMorning: isMorning,
                  isDone: isDone,
                  onTap: () => _go(
                    isMorning ? '/survival/morning' : '/survival/evening',
                  ),
                )
              else if (isDone)
                _DoneCard(
                  label: isMorning ? 'Утренний шаг' : 'Вечерний ритуал',
                  questTitle: QuestPicker.pickToday(slot).title,
                  accent: isMorning ? AppColors.saffron : AppColors.sageDeep,
                )
              else ...[
                QuestCard(
                  label: isMorning ? 'Утренний шаг' : 'Вечерний ритуал',
                  title: QuestPicker.pickToday(slot).title,
                  description: QuestPicker.pickToday(slot).description,
                  duration: QuestPicker.pickToday(slot).duration,
                  accent: isMorning ? AppColors.saffron : AppColors.sageDeep,
                  onStart: () => _go(
                    isMorning ? '/quest/morning' : '/quest/evening',
                  ),
                  onSkip: () {},
                ),
                if (topTool != null) ...[
                  const SizedBox(height: 12),
                  _ToolboxSuggestion(
                    tool: topTool,
                    onTap: () => _go(topTool.route),
                  ),
                ],
              ],
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Один маленький шаг лучше, чем сто мыслей о большом',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.isMorning});
  final bool isMorning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greeting = isMorning ? 'Доброе утро' : 'Тихий вечер';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ВОЛНА',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.terracotta,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
            // Пять иконок в фиксированном Row переполняли строку на узких
            // экранах (iPhone SE) — отдаём им остаток ширины и сжимаем
            // отступы, вместо того чтобы ловить RenderFlex overflow.
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NavIcon(
                    icon: Icons.workspace_premium_rounded,
                    tooltip: 'Знаки присутствия',
                    route: '/badges',
                  ),
                  _NavIcon(
                    icon: Icons.support_agent_rounded,
                    tooltip: 'Связь со специалистом',
                    route: '/help',
                  ),
                  _NavIcon(
                    icon: Icons.edit_note_rounded,
                    tooltip: 'Дневник',
                    route: '/diary',
                  ),
                  _NavIcon(
                    icon: Icons.menu_book_rounded,
                    tooltip: 'Библиотека',
                    route: '/library',
                  ),
                  _NavIcon(
                    icon: Icons.tune_rounded,
                    tooltip: 'Настройки',
                    route: '/settings',
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(greeting, style: theme.textTheme.displayLarge),
        const SizedBox(height: 6),
        Text(
          'Сегодня — один маленький шаг. Не марафон.',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

/// Иконка навигации в шапке. Компактнее стандартного IconButton
/// (у того минимальная ширина 48 и своя подложка), чтобы пять штук
/// помещались в строку даже на самых узких экранах.
class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.tooltip,
    required this.route,
  });

  final IconData icon;
  final String tooltip;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: () => context.push(route),
        radius: 22,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Icon(icon, color: AppColors.terracotta, size: 24),
        ),
      ),
    );
  }
}

class _DoneCard extends StatelessWidget {
  const _DoneCard({
    required this.label,
    required this.questTitle,
    required this.accent,
  });
  final String label;
  final String questTitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, color: accent, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label · сделано',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(questTitle, style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Завтра будет следующий шаг',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SurvivalCard extends StatelessWidget {
  const _SurvivalCard({
    required this.isMorning,
    required this.isDone,
    required this.onTap,
  });

  final bool isMorning;
  final bool isDone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = survivalFor(
      isMorning ? QuestSlot.morning : QuestSlot.evening,
    );

    return Material(
      color: AppColors.coral.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: isDone ? null : onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.coral.withValues(alpha: 0.5),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.coral,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'РЕЖИМ ВЫЖИВАНИЯ',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text('30 секунд', style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 14),
              Text(q.title, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(q.action, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              if (isDone)
                Row(
                  children: const [
                    Icon(
                      Icons.check_rounded,
                      color: AppColors.sageDeep,
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Сделано на сегодня',
                      style: TextStyle(color: AppColors.sageDeep),
                    ),
                  ],
                )
              else
                FilledButton(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                  ),
                  child: const Text('Сделать'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolboxSuggestion extends StatelessWidget {
  const _ToolboxSuggestion({required this.tool, required this.onTap});
  final ToolKey tool;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.peachSoft.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(
                Icons.favorite_rounded,
                color: AppColors.terracotta,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Что тебе обычно помогает',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.terracotta,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(tool.title, style: theme.textTheme.titleLarge),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Карточка «Выговориться» — между SOS и квестом, мягкого тона.
class _VentCard extends StatelessWidget {
  const _VentCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.sage.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.sageDeep.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.sageDeep.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.sageDeep,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Просто выговориться',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Я выслушаю и подберу одну вещь, которая поможет сейчас',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnvelopeBanner extends StatelessWidget {
  const _EnvelopeBanner({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.coral.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.coral, width: 1.2),
          ),
          child: Row(
            children: [
              const Icon(Icons.mail_rounded, color: AppColors.coral),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count == 1
                          ? 'Один конверт ждёт'
                          : '$count конверта ждут',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Открыть, отложить ещё, или выбросить',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.terracotta,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
