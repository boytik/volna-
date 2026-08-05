import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/launch.dart';
import '../../core/theme/colors.dart';
import '../../data/content/specialists.dart';
import '../../main.dart';

/// Экран связи со специалистом.
/// 4 уровня:
/// 1. Экстренный — телефон доверия (всегда первым).
/// 2. Подготовиться к встрече — заметка для следующей терапии.
/// 3. Онлайн-сервисы — каталоги психологов.
/// 4. Сообщества и чаты бесплатной помощи.
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Text('Связь со специалистом', style: theme.textTheme.displayLarge),
            const SizedBox(height: 8),
            Text(
              'Если приложение не помогает — это не значит, что ты слабая. '
              'Это значит, что нужен живой человек.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            _SectionTitle('СРОЧНО, СЕЙЧАС', accent: AppColors.coral),
            const SizedBox(height: 12),
            ...emergencyContacts.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ContactCard(contact: c, accent: AppColors.coral),
              ),
            ),
            const SizedBox(height: 24),
            _SectionTitle('ПОДГОТОВИТЬСЯ К ВСТРЕЧЕ', accent: AppColors.terracotta),
            const SizedBox(height: 12),
            _PrepareForSessionCard(
              onTap: () => context.push('/help/prepare'),
            ),
            const SizedBox(height: 24),
            _SectionTitle('ОНЛАЙН-ПОМОЩЬ', accent: AppColors.sageDeep),
            const SizedBox(height: 12),
            ...onlineTherapy.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ContactCard(contact: c, accent: AppColors.sageDeep),
              ),
            ),
            const SizedBox(height: 24),
            _SectionTitle('БЕСПЛАТНАЯ ПОДДЕРЖКА', accent: AppColors.saffron),
            const SizedBox(height: 12),
            ...supportCommunities.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ContactCard(contact: c, accent: AppColors.saffron),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.peachSoft.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: AppColors.terracotta,
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(16),
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
                          color: AppColors.textSecondary,
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
      color: AppColors.peachSoft.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.terracotta,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.note_alt_rounded,
                  color: Colors.white,
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
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
