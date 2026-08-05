import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/sos_button.dart';
import '../../data/content/quests.dart';
import '../../data/content/survival.dart';
import '../../data/local/toolbox_storage.dart';
import '../../main.dart';
import '../badges/new_badge_overlay.dart';
import '../quest/quest_service.dart';
import '../tree/tree_view.dart';

/// Главный экран как плакат, а не как дашборд.
///
/// Первый экран несёт ровно четыре вещи: метку времени суток,
/// крупную фразу, две равноправные строки выбора и полосу SOS.
/// Всё остальное — древо, дневник, конверты, инструменты — уходит
/// ниже сгиба и читается как следующие страницы той же бумаги.
///
/// Раньше здесь стояли семь элементов одной формы (скруглённый
/// прямоугольник + круглая иконка + заголовок + подзаголовок +
/// шеврон). Приоритета не было: в кризисе SOS приходилось искать
/// чтением.
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
    final isMorning = DateTime.now().hour < 17;
    final slot = isMorning ? QuestSlot.morning : QuestSlot.evening;
    final isDone = questStorage.isDoneToday(slot);
    final survivalMode = settingsStorage.survivalMode;
    final quest = QuestPicker.pickToday(slot);
    final survival = survivalFor(slot);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HomeMasthead(isMorning: isMorning),
                    _Opening(isDone: isDone, isMorning: isMorning),
                    const SizedBox(height: AppSpacing.huge),
                    _Choice(
                      isDone: isDone,
                      survivalMode: survivalMode,
                      questTitle: quest.title,
                      questDuration: quest.duration,
                      survivalTitle: survival.title,
                      onFull: () => _go(
                        isMorning ? '/quest/morning' : '/quest/evening',
                      ),
                      onShort: () => _go(
                        isMorning ? '/survival/morning' : '/survival/evening',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.huge),
                    _BelowFold(onGo: _go),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
          // Полоса вровень с краем: без отступов и без радиуса.
          // SafeArea здесь намеренно нет — SosButton сам забирает
          // безопасную зону внутрь, иначе под ним остаётся щель.
          SosButton(onTap: () => _go('/sos')),
        ],
      ),
    );
  }
}

/// Шапка: метка времени суток слева, вход в разделы справа.
/// Публичная, потому что её сторожит регрессионный тест на переполнение
/// строки на узких экранах — см. `test/home_layout_test.dart`.
class HomeMasthead extends StatelessWidget {
  const HomeMasthead({super.key, required this.isMorning});
  final bool isMorning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.axis,
        AppSpacing.xxl,
        AppSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                (isMorning ? 'Утро' : 'Вечер').toUpperCase(),
                style: theme.textTheme.labelSmall,
              ),
              // Пять иконок в фиксированном Row переполняли строку на
              // узких экранах (iPhone SE) — отдаём им остаток ширины.
              // Spacer здесь ставить нельзя: он конкурирует с Flexible
              // за свободное место и снова роняет строку в overflow.
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    _NavIcon(
                      icon: Icons.workspace_premium_outlined,
                      tooltip: 'Знаки присутствия',
                      route: '/badges',
                    ),
                    _NavIcon(
                      icon: Icons.support_agent_outlined,
                      tooltip: 'Связь со специалистом',
                      route: '/help',
                    ),
                    _NavIcon(
                      icon: Icons.edit_note_outlined,
                      tooltip: 'Дневник',
                      route: '/diary',
                    ),
                    _NavIcon(
                      icon: Icons.menu_book_outlined,
                      tooltip: 'Библиотека',
                      route: '/library',
                    ),
                    _NavIcon(
                      icon: Icons.tune_outlined,
                      tooltip: 'Настройки',
                      route: '/settings',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 96,
            height: AppStroke.hairline,
            color: theme.colorScheme.outline,
          ),
        ],
      ),
    );
  }
}

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
          child: Icon(icon, color: AppColors.inkSoft, size: 22),
        ),
      ),
    );
  }
}

/// Крупная фраза. Ни приветствия по имени, ни даты, ни единой цифры.
class _Opening extends StatelessWidget {
  const _Opening({required this.isDone, required this.isMorning});
  final bool isDone;
  final bool isMorning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String text;
    if (isDone) {
      text = 'Сегодня ты уже была здесь. Больше ничего не нужно.';
    } else if (isMorning) {
      text = 'Сегодня можно ничего не делать. Это тоже участие.';
    } else {
      text = 'День кончился, и ты его прожила. Этого достаточно.';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.axis,
        AppSpacing.xxxl,
        AppSpacing.marginRight,
        0,
      ),
      child: Text(text, style: theme.textTheme.displayLarge),
    );
  }
}

/// Две строки бланка. Короткая версия набрана тем же кеглем и весом,
/// что и полная: это равноправный выбор, а не «запасная кнопка».
class _Choice extends StatelessWidget {
  const _Choice({
    required this.isDone,
    required this.survivalMode,
    required this.questTitle,
    required this.questDuration,
    required this.survivalTitle,
    required this.onFull,
    required this.onShort,
  });

  final bool isDone;
  final bool survivalMode;
  final String questTitle;
  final String questDuration;
  final String survivalTitle;
  final VoidCallback onFull;
  final VoidCallback onShort;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isDone) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.axis),
        child: Text(
          'Завтра будет следующий шаг. Или не будет.',
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.axis),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!survivalMode)
            _FormLine(
              text: '$questTitle · $questDuration',
              color: AppColors.accentPress,
              onTap: onFull,
            ),
          _FormLine(
            text: survivalMode
                ? '$survivalTitle · 40 секунд'
                : 'или короткая версия — 40 секунд',
            color: survivalMode
                ? AppColors.accentPress
                : theme.textTheme.bodyLarge?.color,
            onTap: onShort,
          ),
        ],
      ),
    );
  }
}

/// Строка бланка: текст и волосяная линейка до правого края.
class _FormLine extends StatelessWidget {
  const _FormLine({
    required this.text,
    required this.color,
    required this.onTap,
  });

  final String text;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(
          top: AppSpacing.md,
          bottom: AppSpacing.smd,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outline,
              width: AppStroke.hairline,
            ),
          ),
        ),
        child: Text(
          text,
          style: theme.textTheme.labelLarge?.copyWith(color: color),
        ),
      ),
    );
  }
}

/// Ниже сгиба — следующие страницы той же бумаги, разделённые
/// волосяными линейками. Не карточки.
class _BelowFold extends StatelessWidget {
  const _BelowFold({required this.onGo});
  final Future<void> Function(String) onGo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final readyEnvelopes = diaryStorage.envelopesReadyToReopen;
    final topTool = toolBoxStorage.topTool();
    final rings = questStorage.weeksLived;
    final lights = questStorage.recentActivityAges();

    final rows = <Widget>[
      _PageRow(
        title: 'Просто выговориться',
        note: 'Я выслушаю и подберу одну вещь, которая поможет сейчас',
        leavesDevice: true,
        onTap: () => onGo('/vent'),
      ),
      if (readyEnvelopes.isNotEmpty)
        _PageRow(
          title: readyEnvelopes.length == 1
              ? 'Один конверт ждёт'
              : '${readyEnvelopes.length} конверта ждут',
          note: 'Открыть, отложить ещё, или выбросить',
          onTap: () => onGo('/diary/envelope/${readyEnvelopes.first.id}'),
        ),
      if (topTool != null)
        _PageRow(
          title: topTool.title,
          note: 'Что тебе обычно помогает',
          onTap: () => onGo(topTool.route),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.axis),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...rows,
              TreeBlock(
                rings: rings,
                lights: lights,
                onTap: () => onGo('/tree'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.axis, right: 64),
          child: Text(
            'Один маленький шаг лучше, чем сто мыслей о большом',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _PageRow extends StatelessWidget {
  const _PageRow({
    required this.title,
    required this.note,
    required this.onTap,
    this.leavesDevice = false,
  });

  final String title;
  final String note;
  final VoidCallback onTap;

  /// Единственный внешний вызов в приложении — распознавание речи и
  /// ответ в «выговориться». Знак стоит там и только там.
  final bool leavesDevice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(title, style: theme.textTheme.titleLarge),
                ),
                if (leavesDevice) ...[
                  const SizedBox(width: AppSpacing.sm),
                  const LeavesDeviceMark(),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(note, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

/// Знак «уходит с телефона». Дневник, чек-ины и записи его не имеют —
/// и это видно глазом, а не только написано в политике.
class LeavesDeviceMark extends StatelessWidget {
  const LeavesDeviceMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Этот раздел отправляет запись на сервер распознавания',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: AppRadius.smR,
          border: Border.all(
            color: AppColors.accent,
            width: AppStroke.hairline,
          ),
        ),
        child: Text(
          'УХОДИТ НА СЕРВЕР',
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: AppColors.accentPress),
        ),
      ),
    );
  }
}
