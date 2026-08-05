import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/local/diary_storage.dart';
import '../../main.dart';

class DiaryListScreen extends StatefulWidget {
  const DiaryListScreen({super.key});

  @override
  State<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends State<DiaryListScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = diaryStorage.all();
    final readyEnvelopes = diaryStorage.envelopesReadyToReopen;

    // Корень вкладки: кнопки «назад» здесь нет, уходят другой вкладкой.
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.axis,
            AppSpacing.xxl,
            AppSpacing.axis,
            AppSpacing.xl,
          ),
          children: [
            Text('Дневник', style: theme.textTheme.displayLarge),
            const SizedBox(height: AppSpacing.smd),
            Text(
              'Здесь живут твои мысли. Никто их не увидит. '
              'Можно писать одной строкой — это уже работает.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.xl),

            // «Выговориться» — одна строка. Выбор между голосом и
            // текстом делается внутри: решать способ ещё до входа
            // человеку в тяжёлом состоянии незачем.
            _VentRow(
              title: 'Выговориться',
              note: 'Голосом или текстом — я выслушаю и отвечу',
              route: '/vent',
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (readyEnvelopes.isNotEmpty) ...[
              _ReopenBanner(
                count: readyEnvelopes.length,
                onTap: () => _showFirstReadyEnvelope(readyEnvelopes.first),
              ),
              const SizedBox(height: 16),
            ],
            Text('Новая запись', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            _NewEntryTile(
              icon: Icons.auto_awesome_rounded,
              accent: AppColors.saffron,
              title: 'Три хороших события',
              subtitle: 'Что сегодня прошло не ужасно',
              onTap: () => context.push('/diary/new/three-good'),
            ),
            const SizedBox(height: 8),
            _NewEntryTile(
              icon: Icons.mail_outline_rounded,
              accent: AppColors.coral,
              title: 'Конверт для тревоги',
              subtitle: 'Отложить мысль до завтра',
              onTap: () => context.push('/diary/new/envelope'),
            ),
            const SizedBox(height: 8),
            _NewEntryTile(
              icon: Icons.favorite_border_rounded,
              accent: AppColors.terracotta,
              title: 'Подруга на твоём месте',
              subtitle: 'Перестроить мысль виноватого',
              onTap: () => context.push('/diary/new/friend'),
            ),
            const SizedBox(height: 28),
            if (entries.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.peachSoft.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  'Пока пусто. Любая первая запись — это победа.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              )
            else ...[
              Text('История', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              ...entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _EntryCard(
                    entry: e,
                    onChanged: () => setState(() {}),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFirstReadyEnvelope(DiaryEntry e) {
    context.push('/diary/envelope/${e.id}');
  }
}

class _ReopenBanner extends StatelessWidget {
  const _ReopenBanner({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.coral.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.coral, width: 1.2),
          ),
          child: Row(
            children: [
              const Icon(Icons.mail_rounded, color: AppColors.coral),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count == 1
                          ? 'Один конверт ждёт'
                          : '$count конверта ждут',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Открыть, отложить ещё, или выбросить',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.terracotta,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewEntryTile extends StatelessWidget {
  const _NewEntryTile({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
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
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent),
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
                Icons.add_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.onChanged});
  final DiaryEntry entry;
  final VoidCallback onChanged;

  String _previewFor(DiaryEntry e) {
    switch (e.kind) {
      case DiaryKind.threeGood:
        final parts = [e.payload['one'], e.payload['two'], e.payload['three']]
            .where((p) => p != null && p.trim().isNotEmpty)
            .map((p) => '— $p')
            .join('\n');
        return parts;
      case DiaryKind.envelope:
        return e.payload['thought'] ?? '';
      case DiaryKind.friendOnYourPlace:
        return e.payload['kind_response'] ?? e.payload['guilt'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = _previewFor(entry);
    final isEnvelope = entry.kind == DiaryKind.envelope;
    final isSealed = isEnvelope && entry.envelopeStatus == 'sealed';

    return Material(
      color: AppColors.paperLift,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: isEnvelope
            ? () =>
                Navigator.of(context).pushNamed('/diary/envelope/${entry.id}')
            : null,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    entry.kind.label.toUpperCase(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.terracotta,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  if (isSealed)
                    const Icon(
                      Icons.lock_rounded,
                      size: 16,
                      color: AppColors.coral,
                    ),
                  if (entry.envelopeStatus == 'discarded')
                    const Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(entry.createdAt),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isSealed ? 'Запечатано до завтра' : preview,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSealed
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                  fontStyle: isSealed ? FontStyle.italic : FontStyle.normal,
                  height: 1.5,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    return '${d.day} ${months[d.month - 1]}';
  }
}

/// Вход в «выговориться» из дневника. Знак «уходит на сервер» стоит
/// не здесь, а на экране выбора: он относится к голосу, а не ко всему
/// разделу — текст никуда не отправляется.
class _VentRow extends StatelessWidget {
  const _VentRow({
    required this.title,
    required this.note,
    required this.route,
  });

  final String title;
  final String note;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => context.push(route),
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
