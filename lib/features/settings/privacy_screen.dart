import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';

/// Что происходит с данными — человеческим языком.
///
/// Открывается из настроек и из онбординга. Формулировки намеренно honest:
/// раньше приложение писало «в облаке голос не хранится», хотя аудио и
/// расшифровка уходят в Azure OpenAI.
///
/// TODO(заказчица): текст согласован с юристом? Для публикации в сторах
/// потребуется ещё и внешняя ссылка на политику — см. privacyPolicyUrl.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

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
            Text('Твои данные', style: theme.textTheme.displayLarge),
            const SizedBox(height: 8),
            Text(
              'Коротко и без юридического языка.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            const _Block(
              icon: Icons.phone_iphone_rounded,
              accent: AppColors.sageDeep,
              title: 'Остаётся только на телефоне',
              lines: [
                'Дневник — все три формы, включая конверты',
                'Настроение и сон в чек-инах',
                'Ответы на опросники и их результаты',
                'Выполненные шаги, капли, значки',
              ],
              footer: 'Это никуда не отправляется. У приложения нет аккаунтов '
                  'и нет сервера, куда это можно было бы положить.',
            ),
            const SizedBox(height: 16),
            const _Block(
              icon: Icons.cloud_upload_rounded,
              accent: AppColors.terracotta,
              title: 'Уходит в облако — только голос',
              lines: [
                'Аудиозапись «Выговорись» и её расшифровка',
                'Отправляются в Azure OpenAI (Microsoft) — там их превращают '
                    'в текст и составляют ответ',
              ],
              footer: 'Microsoft может хранить эти запросы до 30 дней для '
                  'защиты от злоупотреблений. Мы не связываем их с тобой: '
                  'ни имени, ни телефона, ни аккаунта приложение не собирает. '
                  'Голосовая функция включается только с твоего явного '
                  'согласия и выключается в настройках в любой момент. '
                  'Текстовое «Выговорись» работает полностью на телефоне.',
            ),
            const SizedBox(height: 16),
            const _Block(
              icon: Icons.delete_outline_rounded,
              accent: AppColors.coral,
              title: 'Можно стереть',
              lines: [
                'Кнопка «Удалить все мои данные» в настройках',
              ],
              footer: 'Удаляет всё разом и без возврата: дневник, чек-ины, '
                  'результаты опросников, значки и настройки.',
            ),
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
                '«Волна» — это поддержка, а не терапия и не медицинская '
                'помощь. Приложение не ставит диагнозов и не заменяет '
                'специалиста.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
    required this.icon,
    required this.accent,
    required this.title,
    required this.lines,
    required this.footer,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final List<String> lines;
  final String footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.paperLift,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                child: Text(title, style: theme.textTheme.titleLarge),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...lines.map(
            (l) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7, right: 10),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(l, style: theme.textTheme.bodyLarge),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(footer, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
