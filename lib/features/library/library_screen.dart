import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/content/phrases.dart';

/// Главный экран библиотеки: категории фраз + ссылка на внешние ресурсы.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text(''),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Text('Библиотека', style: theme.textTheme.displayLarge),
            const SizedBox(height: 8),
            Text(
              'Фразы поддержки и полезные ресурсы. Возвращайся, когда нужно вспомнить, что ты не один.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            Text(
              'Фразы по темам',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...phraseCategories.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CategoryTile(
                  category: c,
                  onTap: () => context.push('/library/phrases/${c.id}'),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Внешние ресурсы',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _ResourcesTile(onTap: () => context.push('/library/resources')),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});

  final PhraseCategory category;
  final VoidCallback onTap;

  static const _accents = {
    'resilience': AppColors.sageDeep,
    'burnout': AppColors.terracotta,
    'guilt': AppColors.peach,
    'anxiety': AppColors.coral,
    'affirmations': AppColors.saffron,
    'support': AppColors.sage,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accents[category.id] ?? AppColors.terracotta;

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
                width: 8,
                height: 48,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(category.subtitle, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${category.phrases.length} фраз',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
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

class _ResourcesTile extends StatelessWidget {
  const _ResourcesTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.peachSoft,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.paperLift.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.terracotta,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Куда можно обратиться',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Госресурсы, юридическая помощь, телефон доверия',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(
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
