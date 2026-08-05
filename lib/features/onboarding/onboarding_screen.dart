import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../data/content/anchor_options.dart';
import '../../main.dart';

/// Онбординг по тексту из ТЗ + дополнительный шаг про якоря рутины
/// (на основании ресёрча: фиксированные часы → «push fatigue»,
/// «после купания» → ощущение «приложение про мою жизнь»).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  String? _selectedMorningAnchor;
  String? _selectedEveningAnchor;

  static const _totalPages = 6;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_selectedMorningAnchor != null) {
      await settingsStorage.setMorningAnchor(_selectedMorningAnchor);
    }
    if (_selectedEveningAnchor != null) {
      await settingsStorage.setEveningAnchor(_selectedEveningAnchor);
    }

    final wantsNotifications =
        _selectedMorningAnchor != null || _selectedEveningAnchor != null;

    if (wantsNotifications) {
      final granted = await notificationService.requestPermission();
      await settingsStorage.setNotificationsEnabled(granted);
      if (granted) {
        await notificationService.rescheduleAll();
      }
    } else {
      await settingsStorage.setNotificationsEnabled(false);
    }

    await settingsStorage.setOnboardingDone(true);

    if (!mounted) return;
    context.go('/');
  }

  String _ctaForPage() {
    switch (_page) {
      case 0:
        return 'Хочу попробовать';
      case 1:
        return 'Понятно. Дальше';
      case 2:
        return 'Понятно';
      case 3:
        return 'Удобный момент';
      case 4:
        return 'Сделать первый шаг';
      case 5:
        return 'Начать';
      default:
        return 'Дальше';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _page == _totalPages - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
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
                  TextButton(
                    onPressed: _finish,
                    child: const Text('Пропустить'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  const _StoryPage(
                    title: 'Ты здесь',
                    body: 'Значит, сегодня ты решил сделать шаг.\n'
                        'Не прыжок, не марафон. Один маленький шаг.\n\n'
                        'Это уже много.',
                    accent: AppColors.peach,
                  ),
                  const _StoryPage(
                    title: 'Это нормально',
                    body: 'Ты можешь уставать, злиться, бояться, '
                        'ничего не хотеть.\n\n'
                        '«Волна» не требует быть супергероем. '
                        'Она просто помогает дышать и замечать тепло.',
                    accent: AppColors.saffron,
                  ),
                  const _StoryPage(
                    title: 'Как это работает',
                    body: 'Три простых шага каждый день:\n\n'
                        '— Утром короткий квест (2–3 минуты)\n'
                        '— В любой момент кнопка «Мне тяжело»\n'
                        '— Вечером тихий ритуал\n\n'
                        'Никаких сложных анкет и обязательств.',
                    accent: AppColors.sage,
                  ),
                  const _DataPage(),
                  _AnchorPage(
                    selectedMorning: _selectedMorningAnchor,
                    selectedEvening: _selectedEveningAnchor,
                    onSelectMorning: (id) => setState(() {
                      _selectedMorningAnchor =
                          _selectedMorningAnchor == id ? null : id;
                    }),
                    onSelectEvening: (id) => setState(() {
                      _selectedEveningAnchor =
                          _selectedEveningAnchor == id ? null : id;
                    }),
                  ),
                  const _StoryPage(
                    title: 'Первый шаг',
                    body: 'Сделай три медленных выдоха.\n\n'
                        'Просто почувствуй, как воздух выходит. '
                        'Это уже практика. Это уже шаг.',
                    accent: AppColors.terracotta,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _totalPages,
                      (i) => Container(
                        width: i == _page ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i == _page
                              ? AppColors.terracotta
                              : AppColors.textMuted.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      if (isLast) {
                        _finish();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                        );
                      }
                    },
                    child: Text(_ctaForPage()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryPage extends StatelessWidget {
  const _StoryPage({
    required this.title,
    required this.body,
    required this.accent,
  });

  final String title;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.6),
                  accent,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.displayLarge,
          ),
          const SizedBox(height: 20),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

/// Страница про данные. Стоит до всего, что что-то куда-то отправляет:
/// человек должен знать правила раньше, чем нажмёт микрофон.
class _DataPage extends StatelessWidget {
  const _DataPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Что с твоими записями', style: theme.textTheme.headlineLarge),
          const SizedBox(height: 20),
          const _DataRow(
            icon: Icons.phone_iphone_rounded,
            accent: AppColors.sageDeep,
            title: 'Дневник остаётся на телефоне',
            body: 'Записи, чек-ины, опросники и значки хранятся только на '
                'этом устройстве. У приложения нет аккаунтов и нет сервера.',
          ),
          const SizedBox(height: 14),
          const _DataRow(
            icon: Icons.mic_rounded,
            accent: AppColors.terracotta,
            title: 'Голос — единственное исключение',
            body: 'Чтобы разобрать запись «Выговорись», её нужно отправить '
                'на расшифровку в облако. Мы спросим отдельно, прежде чем '
                'включить это. Писать текстом можно без облака.',
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () => context.push('/privacy'),
              child: const Text('Подробнее про данные'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.icon,
    required this.accent,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(body, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Страница с двумя якорями — утренним и вечерним.
/// Можно ничего не выбирать — тогда уведомления выключены.
class _AnchorPage extends StatelessWidget {
  const _AnchorPage({
    required this.selectedMorning,
    required this.selectedEvening,
    required this.onSelectMorning,
    required this.onSelectEvening,
  });

  final String? selectedMorning;
  final String? selectedEvening;
  final ValueChanged<String> onSelectMorning;
  final ValueChanged<String> onSelectEvening;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Когда тебе удобнее?',
            style: theme.textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Не «в 8:00». А «когда я обычно могу выдохнуть». '
            'Можно ничего не выбирать — тогда напоминаний не будет.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Text('УТРОМ', style: _label(theme)),
          const SizedBox(height: 8),
          ...morningAnchors.map(
            (a) => _AnchorTile(
              text: a.text,
              selected: selectedMorning == a.id,
              accent: AppColors.saffron,
              onTap: () => onSelectMorning(a.id),
            ),
          ),
          const SizedBox(height: 20),
          Text('ВЕЧЕРОМ', style: _label(theme)),
          const SizedBox(height: 8),
          ...eveningAnchors.map(
            (a) => _AnchorTile(
              text: a.text,
              selected: selectedEvening == a.id,
              accent: AppColors.sageDeep,
              onTap: () => onSelectEvening(a.id),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle? _label(ThemeData theme) => theme.textTheme.bodySmall?.copyWith(
        color: AppColors.terracotta,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      );
}

class _AnchorTile extends StatelessWidget {
  const _AnchorTile({
    required this.text,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? accent.withValues(alpha: 0.18) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? accent : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: selected ? accent : AppColors.textMuted,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: theme.textTheme.bodyLarge,
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
