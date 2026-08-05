import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';

/// «Ещё» — оглавление приложения.
///
/// Набрано как оглавление книги: заголовок группы, затем строки
/// «название плюс короткое пояснение», разделённые волосяными
/// линейками. Ни сетки иконок, ни карточек.
///
/// Сюда переехали календарь, инсайты и опросники — раньше они лежали
/// в «Настройках», под шестерёнкой. Это не служебные экраны: рефлексия
/// и самооценка — ядро продукта, а не его конфигурация.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  static const groups = <({String title, List<_Entry> entries})>[
    (
      title: 'Наблюдение',
      entries: [
        _Entry('Древо', 'Кольца прожитых недель и следы практик', '/tree'),
        _Entry('Календарь', 'Месяц настроений и шагов', '/calendar'),
        _Entry('Что я заметила', 'Связи между шагами и самочувствием',
            '/insights'),
      ],
    ),
    (
      title: 'Материалы',
      entries: [
        _Entry('Библиотека', 'Фразы на трудные моменты и ресурсы', '/library'),
        _Entry('Опросники', 'PSS, PBI, CSI — когда захочется', '/questionnaire'),
      ],
    ),
    (
      title: 'Поддержка',
      entries: [
        _Entry('Специалист', 'Подготовиться к сессии, найти помощь', '/help'),
      ],
    ),
    (
      title: 'Твоё',
      entries: [
        _Entry('Знаки присутствия', 'Места, где ты была', '/badges'),
        _Entry('Настройки', 'Напоминания, режим выживания, данные',
            '/settings'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.axis,
            AppSpacing.xxl,
            AppSpacing.marginRight,
            AppSpacing.xl,
          ),
          children: [
            Text('Ещё', style: theme.textTheme.displayLarge),
            const SizedBox(height: AppSpacing.smd),
            Text(
              'Всё, что не нужно каждый день, но пусть будет под рукой.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.xl),
            for (final g in groups) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  g.title.toUpperCase(),
                  style: theme.textTheme.labelSmall,
                ),
              ),
              for (final e in g.entries) _EntryRow(entry: e),
              const SizedBox(height: AppSpacing.xl),
            ],
          ],
        ),
      ),
    );
  }
}

class _Entry {
  const _Entry(this.title, this.note, this.route);
  final String title;
  final String note;
  final String route;
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry});
  final _Entry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => context.push(entry.route),
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
            Text(entry.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(entry.note, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
