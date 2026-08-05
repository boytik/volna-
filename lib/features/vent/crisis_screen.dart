import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/launch.dart';
import '../../core/theme/colors.dart';
import '../../data/content/crisis_keywords.dart';
import '../../data/content/specialists.dart';

/// Кризисный экран.
///
/// Показывается детерминированно, до любой LLM-обработки, из всех мест, где
/// человек вводит свободный текст: голосовое и текстовое «Выговорись», дневник.
/// Единственная задача экрана — соединить с живым человеком, поэтому кнопка
/// звонка здесь настоящая, а не переход в список ссылок.
class CrisisScreen extends StatelessWidget {
  const CrisisScreen({super.key, required this.category});

  final CrisisCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          children: [
            const SizedBox(height: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.coral.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: AppColors.coral,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(category.label, style: theme.textTheme.displayLarge),
            const SizedBox(height: 12),
            Text(
              category.body,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => openExternal(context, crisisPhoneUrl),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.coral,
                minimumSize: const Size.fromHeight(64),
              ),
              icon: const Icon(Icons.phone_in_talk_rounded, size: 28),
              label: const Text(
                crisisPhoneLabel,
                style: TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'Бесплатно, анонимно, круглосуточно',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => context.push('/specialist'),
              child: const Text('Другие способы связи'),
            ),
          ],
        ),
      ),
    );
  }
}
