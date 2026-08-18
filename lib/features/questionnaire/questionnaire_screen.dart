import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/launch.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/content/questionnaires.dart';
import '../../data/content/specialists.dart';
import '../../data/local/questionnaire_storage.dart';
import '../../main.dart';

/// Прохождение опросника. Один пункт на странице, плавный переход.
/// На любом шаге можно выйти кнопкой «закрыть» (без потерь — всегда можно начать заново).
class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key, required this.kind});
  final QuestionnaireKind kind;

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  late final Questionnaire q;
  final Map<int, int> _answers = {};
  final _pageController = PageController();
  int _index = 0;
  bool _advancing = false;
  QuestionnaireResult? _result;
  QuestionnaireRecord? _previous;

  @override
  void initState() {
    super.initState();
    q = questionnaireOf(widget.kind);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectAnswer(int value) {
    // Переход отложен на 280 мс, чтобы человек увидел свой выбор. Без этого
    // флага быстрый повторный тап ставил в очередь второй переход и один
    // вопрос проскакивал неотвеченным.
    if (_advancing) return;

    HapticFeedback.selectionClick();
    setState(() {
      _answers[q.items[_index].id] = value;
      _advancing = true;
    });

    Future.delayed(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      final wasLast = _index >= q.items.length - 1;
      _advancing = false;
      if (wasLast) {
        _finalise();
      } else if (AppMotion.reduced(context)) {
        _pageController.jumpToPage(_index + 1);
      } else {
        // Плавный слайд к следующему вопросу. _index обновит onPageChanged.
        _pageController.nextPage(
          duration: const Duration(milliseconds: 460),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  Future<void> _finalise() async {
    final r = computeResult(q, _answers);
    await toolBoxStorage.markQuestionnaireCompleted();
    await questionnaireStorage.add(r);
    // Предыдущее прохождение читаем уже после сохранения текущего.
    final previous = questionnaireStorage.previousOf(r.kind);
    if (!mounted) return;
    setState(() {
      _result = r;
      _previous = previous;
    });
  }

  void _back() {
    if (_index > 0) {
      if (AppMotion.reduced(context)) {
        _pageController.jumpToPage(_index - 1);
      } else {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 460),
          curve: Curves.easeInOutCubic,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_result != null) {
      return _ResultScreen(result: _result!, previous: _previous);
    }

    final progress = (_index + 1) / q.items.length;

    return Scaffold(
      backgroundColor: AppColors.paperSunk,
      appBar: AppBar(
        backgroundColor: AppColors.paperSunk,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          q.kind.shortTitle,
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          if (_index > 0)
            TextButton.icon(
              onPressed: _back,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Назад'),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Прогресс — тонкая линейка во всю ширину, заполняется терракотой.
            // Редакторское «правило», а не material-полоска с округлениями.
            LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: AppColors.rule,
              valueColor: const AlwaysStoppedAnimation(AppColors.terracotta),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.axis, AppSpacing.smd, AppSpacing.axis, 0),
              child: Text(
                'Вопрос ${_index + 1} · ${q.items.length}'.toUpperCase(),
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: AppColors.textMuted),
              ),
            ),
            // Каждый вопрос — отдельная «страница». Переход между вопросами —
            // плавный горизонтальный слайд (PageView), вёрстка страниц
            // одинаковая, поэтому ничего не прыгает. Свайп руками отключён:
            // листаем только ответом или кнопкой «Назад».
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: q.items.length,
                itemBuilder: (context, i) {
                  final pageItem = q.items[i];
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.axis,
                        vertical: AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Волна — знак «Волны» над вопросом: даёт блоку опору
                          // и убирает пустоту сверху.
                          const Icon(
                            Icons.waves_rounded,
                            color: AppColors.accent,
                            size: 44,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          // Вопрос — «голос»: крупная антиква по центру.
                          Text(
                            pageItem.text,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineLarge
                                ?.copyWith(height: 1.3),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          // Варианты — во всю ширину.
                          SizedBox(
                            width: double.infinity,
                            child: _AnswerOptions(
                              scale: q.scaleType,
                              selected: _answers[pageItem.id],
                              onTap: _selectAnswer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerOptions extends StatelessWidget {
  const _AnswerOptions({
    required this.scale,
    required this.selected,
    required this.onTap,
  });

  final QuestionnaireScale scale;
  final int? selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    switch (scale) {
      case QuestionnaireScale.agreeFive:
        return _ScaleRow(
          options: const [
            (1, 'Совсем не согласна'),
            (2, 'Скорее нет'),
            (3, 'Серединка'),
            (4, 'Скорее да'),
            (5, 'Полностью согласна'),
          ],
          selected: selected,
          onTap: onTap,
        );
      case QuestionnaireScale.frequencySeven:
        return _ScaleRow(
          options: const [
            (1, 'Никогда'),
            (2, 'Очень редко'),
            (3, 'Редко'),
            (4, 'Иногда'),
            (5, 'Часто'),
            (6, 'Очень часто'),
            (7, 'Постоянно'),
          ],
          selected: selected,
          onTap: onTap,
          dense: true,
        );
      case QuestionnaireScale.yesNo:
        return Row(
          children: [
            Expanded(
              child: _BigOption(
                label: 'Нет',
                selected: selected == 0,
                accent: AppColors.sage,
                onTap: () => onTap(0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BigOption(
                label: 'Да',
                selected: selected == 1,
                accent: AppColors.coral,
                onTap: () => onTap(1),
              ),
            ),
          ],
        );
    }
  }
}

class _ScaleRow extends StatelessWidget {
  const _ScaleRow({
    required this.options,
    required this.selected,
    required this.onTap,
    this.dense = false,
  });

  final List<(int, String)> options;
  final int? selected;
  final ValueChanged<int> onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: options.map((opt) {
        final isSel = selected == opt.$1;
        return Padding(
          padding: EdgeInsets.only(bottom: dense ? 6 : 8),
          child: Material(
            color: isSel
                ? AppColors.terracotta.withValues(alpha: 0.18)
                : AppColors.paperLift,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: InkWell(
              onTap: () => onTap(opt.$1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: dense ? 10 : 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: isSel ? AppColors.terracotta : AppColors.rule,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSel
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: isSel
                          ? AppColors.terracotta
                          : AppColors.textMuted,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(opt.$2, style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BigOption extends StatelessWidget {
  const _BigOption({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent.withValues(alpha: 0.22) : AppColors.paperLift,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: selected ? accent : AppColors.rule,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: selected ? accent : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultScreen extends StatelessWidget {
  const _ResultScreen({required this.result, this.previous});
  final QuestionnaireResult result;

  /// Предыдущее прохождение этого же опросника, если оно было.
  final QuestionnaireRecord? previous;

  ({Color color, String title, String body}) _zoneCopy(
    QuestionnaireKind kind,
    ResultZone zone,
  ) {
    switch (zone) {
      case ResultZone.low:
        return (
          color: AppColors.sageDeep,
          title: 'Базовое равновесие',
          body: 'Ты держишься. Это не значит, что всё легко — это значит, '
              'что внутренние ресурсы пока есть. Продолжай возвращаться к древу.',
        );
      case ResultZone.medium:
        return (
          color: AppColors.saffron,
          title: 'Видны тревожные ноты',
          body: 'Часть нагрузки уже ощущается как тяжесть. '
              'Это сигнал — не приговор. Стоит начать с малого: '
              'добавить себе один тихий час в день.',
        );
      case ResultZone.high:
        return (
          color: AppColors.coral,
          title: 'Нужна живая помощь',
          body: 'Это уже не «просто устала». '
              'Сейчас тебе нужно не приложение, а человек. '
              'Пожалуйста, выбери одно действие ниже.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final zone = _zoneCopy(result.kind, result.zone);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(result.kind.shortTitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: zone.color,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  )),
              const SizedBox(height: 16),
              Text('Результат', style: theme.textTheme.displayLarge),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: zone.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: zone.color.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Эмодзи-значки зон убраны: DESIGN.md их запрещает,
                    // а знак предупреждения вводил ещё и семантику
                    // warning, которой в эмоциональном контуре нет.
                    // Зону называют цвет рамки и сам заголовок.
                    Text(
                      zone.title,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(zone.body, style: theme.textTheme.bodyLarge),
                  ],
                ),
              ),
              if (previous != null) ...[
                const SizedBox(height: 16),
                _ComparisonCard(current: result, previous: previous!),
              ],
              const SizedBox(height: 24),
              if (result.zone == ResultZone.high) ..._highZoneActions(context),
              if (result.zone == ResultZone.medium) ..._mediumZoneActions(context),
              if (result.zone == ResultZone.low) ..._lowZoneActions(context),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: AppColors.textMuted.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  previous == null
                      ? 'Это не диагноз. Это зеркало. '
                          'Через 2 недели можно пройти снова — и сравнить.'
                      : 'Это не диагноз. Это зеркало. '
                          'Сравнивать имеет смысл раз в пару недель, не чаще.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _highZoneActions(BuildContext context) => [
        _ActionButton(
          icon: Icons.phone_in_talk_rounded,
          color: AppColors.coral,
          title: 'Позвонить на телефон доверия',
          subtitle: '$crisisPhoneLabel · бесплатно, анонимно',
          onTap: () => openExternal(context, crisisPhoneUrl),
        ),
        const SizedBox(height: 10),
        _ActionButton(
          icon: Icons.note_alt_rounded,
          color: AppColors.terracotta,
          title: 'Подготовиться к встрече с психологом',
          subtitle: '3 коротких вопроса — и ничего не забудешь',
          onTap: () {
            context.push('/help/prepare');
          },
        ),
        const SizedBox(height: 10),
        _ActionButton(
          icon: Icons.menu_book_rounded,
          color: AppColors.sageDeep,
          title: 'Найти онлайн-психолога',
          subtitle: 'Каталоги проверенных сервисов',
          onTap: () {
            context.push('/specialist');
          },
        ),
      ];

  List<Widget> _mediumZoneActions(BuildContext context) => [
        _ActionButton(
          icon: Icons.favorite_rounded,
          color: AppColors.saffron,
          title: 'Открыть фразы поддержки',
          subtitle: 'Что почитать сейчас',
          onTap: () {
            context.push('/library');
          },
        ),
        const SizedBox(height: 10),
        _ActionButton(
          icon: Icons.air_rounded,
          color: AppColors.sageDeep,
          title: 'Сделать одну SOS-технику',
          subtitle: 'Дыхание, заземление, ладонь на сердце',
          onTap: () {
            context.push('/sos');
          },
        ),
      ];

  List<Widget> _lowZoneActions(BuildContext context) => [
        _ActionButton(
          icon: Icons.eco_rounded,
          color: AppColors.sageDeep,
          title: 'Вернуться к древу',
          subtitle: 'Продолжай в своём ритме',
          onTap: () {
            context.go('/');
          },
        ),
      ];
}

/// Сравнение с прошлым разом.
/// Сырые баллы и проценты не показываем — по тому же принципу, что и в
/// «Что я заметила»: для человека это шум. Только направление и дата.
class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.current, required this.previous});

  final QuestionnaireResult current;
  final QuestionnaireRecord previous;

  /// Порог в 5% отсекает колебания настроения в день заполнения.
  static const _noise = 0.05;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final delta = current.percent - previous.percent;

    final (IconData icon, Color color, String text) = switch (delta) {
      < -_noise => (
          Icons.trending_down_rounded,
          AppColors.sageDeep,
          'Стало легче, чем в прошлый раз',
        ),
      > _noise => (
          Icons.trending_up_rounded,
          AppColors.coral,
          'Тяжелее, чем в прошлый раз',
        ),
      _ => (
          Icons.trending_flat_rounded,
          AppColors.textSecondary,
          'Примерно так же, как в прошлый раз',
        ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paperLift,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: theme.textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(
                  'Прошлый раз — ${_dateLabel(previous.takenAt)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime d) {
    const months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.paperLift,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
