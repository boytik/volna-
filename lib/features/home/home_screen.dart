import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/content/quests.dart';
import '../../data/content/survival.dart';
import '../../data/local/toolbox_storage.dart';
import '../../main.dart';
import '../badges/new_badge_overlay.dart';
import '../quest/quest_service.dart';
import '../tree/tree_view.dart';

/// Главный экран как плакат, а не как дашборд.
///
/// Первый экран несёт метку времени суток, крупную фразу, шаг дня
/// с двумя кнопками и древо. Всё это должно помещаться без скролла:
/// ритм в 96pt между блоками выглядел красиво в макете, но на живом
/// телефоне выталкивал древо за нижний бар.
///
/// Разделы и практики живут в нижнем баре, конверты и подсказки —
/// ниже древа.
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
    // checkUnlocks и записывает новые значки, и возвращает их. Записываем
    // всегда (иначе значок не появится в коллекции «Пути»), а поздравление
    // показываем только когда видна сама главная.
    final newly = await badgesService.checkUnlocks();
    if (!mounted || newly.isEmpty) return;
    // Значки могли открыться в другой вкладке (специалист, дневник) или пока
    // человек был во внешнем браузере. Показывать пачку модалок поверх чужого
    // экрана — то, на что жаловались. На чужом экране просто тихо пополняем
    // коллекцию; поздравление придёт, когда главная снова окажется активной.
    if (_isHomeCurrent()) {
      await NewBadgeOverlay.showAll(context, newly);
    }
    if (mounted) setState(() {});
  }

  /// Главная сейчас на переднем плане (ничего не открыто поверх оболочки и это
  /// не другая вкладка). Берём глобальное текущее место из go_router — внутри
  /// ветки оболочки локальный матч всегда «/», поэтому смотрим весь маршрут.
  bool _isHomeCurrent() {
    final location =
        GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    return location == '/';
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
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeMasthead(isMorning: isMorning),
              _Opening(isDone: isDone, isMorning: isMorning),
              const SizedBox(height: AppSpacing.xxl),
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
              const SizedBox(height: AppSpacing.xxl),
              _BelowFold(onGo: _go),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
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
        AppSpacing.lg,
        AppSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Пять безымянных иконок переехали в нижний бар. Осталась
          // одна — вход в «Путь», где слиты календарь, знаки, опросники
          // и «что я заметила». Заодно исчез повод для Flexible: в
          // строке два элемента вместо шести, и уронить её в overflow
          // на узком экране больше нечем.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                (isMorning ? 'Утро' : 'Вечер').toUpperCase(),
                style: theme.textTheme.labelSmall,
              ),
              const _NavIcon(
                icon: Icons.calendar_month_outlined,
                tooltip: 'Твой путь',
                route: '/path',
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
        AppSpacing.xl,
        AppSpacing.marginRight,
        0,
      ),
      child: Text(text, style: theme.textTheme.displayLarge),
    );
  }
}

/// Шаг дня: название практики и две кнопки. Короткая версия — кнопка
/// того же размера и кегля, а не серая ссылка внизу.
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

    // Раньше выбор был набран строками бланка с волосяной линейкой.
    // Равноправие полной и короткой версии это давало, а вот того,
    // что сюда можно нажать, — нет: строка с подчёркиванием читается
    // заголовком. Теперь это две настоящие кнопки одной высоты.
    final title = survivalMode ? survivalTitle : questTitle;
    final duration = survivalMode ? '40 секунд' : questDuration;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.axis),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            (survivalMode ? 'Режим выживания' : 'Шаг дня').toUpperCase(),
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(duration, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          if (!survivalMode) ...[
            FilledButton(onPressed: onFull, child: const Text('Начать')),
            const SizedBox(height: AppSpacing.smd),
            // Короткая версия — кнопка того же размера и кегля, а не
            // серая ссылка внизу: отказ от полной практики должен
            // весить столько же, сколько согласие.
            OutlinedButton(
              onPressed: onShort,
              child: const Text('Короткая версия — 40 секунд'),
            ),
          ] else
            FilledButton(onPressed: onShort, child: const Text('Начать')),
        ],
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

    // «Выговориться» отсюда ушло: теперь это вкладка в нижнем баре,
    // и дублировать её строкой значит показывать одно и то же дважды.
    final rows = <Widget>[
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
              TreeBlock(
                rings: rings,
                lights: lights,
                onTap: () => onGo('/tree'),
              ),
              ...rows,
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
  });

  final String title;
  final String note;
  final VoidCallback onTap;

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
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(note, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
