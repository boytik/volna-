import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/launch.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/content/specialists.dart';
import '../../main.dart';

/// Экран связи со специалистом.
///
/// Блоки: подготовка к встрече, телефоны доверия, онлайн-сервисы,
/// бесплатные сообщества. Первые два меняются местами в зависимости
/// от того, как экран открыли, — см. комментарий в `build`.
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  @override
  void initState() {
    super.initState();
    // Помечаем для значка «Я ищу помощь».
    toolBoxStorage.markHelpScreenOpened();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Экран живёт в двух ролях. Как вкладка «Специалист» он корневой —
    // кнопки «назад» там быть не должно, уходят другой вкладкой. Как
    // `/specialist` он пушится из кризисного экрана и из ответа
    // «выговориться», и вернуться назад обязательно нужно: человек
    // пришёл сюда из разговора, а не из меню.
    final canGoBack = context.canPop();

    return Scaffold(
      appBar: canGoBack
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              ),
            )
          : null,
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
            Text('Связь со специалистом', style: theme.textTheme.displayLarge),
            const SizedBox(height: 8),
            Text(
              'Если приложение не помогает — это не значит, что ты слабая. '
              'Это значит, что нужен живой человек.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),

            // Порядок зависит от того, как сюда пришли.
            //
            // Вкладка — это «зайти спокойно»: подготовка к встрече и есть
            // то, зачем сюда обычно заходят, поэтому она первая.
            //
            // Но тот же экран пушится с кризисного (`/specialist`), и
            // там первым обязан стоять телефон доверия. Человека, который
            // только что написал «я не хочу жить», нельзя встречать
            // предложением подготовиться к встрече на следующей неделе.
            if (!canGoBack) ...[
              ..._prepareSection(context),
              const SizedBox(height: 24),
              ..._emergencySection(),
              const SizedBox(height: 24),
            ] else ...[
              ..._emergencySection(),
              const SizedBox(height: 24),
              ..._prepareSection(context),
              const SizedBox(height: 24),
            ],
            // Заголовок без содержимого не рисуем: список может
            // опустеть, когда из него уходит мёртвый адрес, а пустая
            // рубрика читается как «здесь ничего нет, но должно быть».
            if (onlineTherapy.isNotEmpty) ...[
              _SectionTitle('ОНЛАЙН-ПОМОЩЬ', accent: AppColors.marked),
              const SizedBox(height: 12),
              ...onlineTherapy.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ContactCard(contact: c, accent: AppColors.marked),
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (supportCommunities.isNotEmpty) ...[
              _SectionTitle('БЕСПЛАТНАЯ ПОДДЕРЖКА', accent: AppColors.dawn),
              const SizedBox(height: 12),
              ...supportCommunities.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ContactCard(contact: c, accent: AppColors.dawn),
                ),
              ),
              const SizedBox(height: 24),
            ],
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.paperSunk,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Региональные специалисты',
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Список проверенных психологов и центров для родителей детей с ОВЗ '
                    'в твоём регионе скоро появится здесь. '
                    'Если ты знаешь хороший — напиши нам, добавим.',
                    style: theme.textTheme.bodyMedium,
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

/// Телефоны доверия. Отдельным методом, потому что этот блок меняет
/// место в зависимости от того, как открыли экран.
List<Widget> _emergencySection() => [
      _SectionTitle('СРОЧНО, СЕЙЧАС', accent: AppColors.sos),
      const SizedBox(height: 12),
      ...emergencyContacts.map(
        (c) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ContactCard(contact: c, accent: AppColors.sos),
        ),
      ),
    ];

List<Widget> _prepareSection(BuildContext context) => [
      _SectionTitle('ПОДГОТОВИТЬСЯ К ВСТРЕЧЕ', accent: AppColors.accent),
      const SizedBox(height: 12),
      _PrepareForSessionCard(onTap: () => context.push('/help/prepare')),
    ];

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {required this.accent});
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: accent,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact, required this.accent});

  final SpecialistContact contact;
  final Color accent;

  Future<void> _open(BuildContext context) =>
      openExternal(context, contact.url);

  IconData get _icon {
    switch (contact.kind) {
      case ContactKind.phone:
        return Icons.phone_rounded;
      case ContactKind.link:
        return Icons.open_in_new_rounded;
      case ContactKind.telegram:
        return Icons.send_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.paperLift,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon, color: accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(contact.title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      contact.description,
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (contact.note != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        contact.note!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrepareForSessionCard extends StatelessWidget {
  const _PrepareForSessionCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.paperSunk,
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
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.note_alt_rounded,
                  color: AppColors.paperLift,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Записать для встречи с психологом',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '3 коротких вопроса. Ты ничего не забудешь, '
                      'когда придёшь на сессию.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.inkQuiet,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
