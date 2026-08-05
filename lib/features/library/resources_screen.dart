import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/launch.dart';
import '../../core/theme/colors.dart';
import '../../data/content/resources.dart';

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});

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
            Text('Куда можно обратиться', style: theme.textTheme.displayLarge),
            const SizedBox(height: 8),
            Text(
              'Официальные ресурсы и службы помощи. '
              'Если очень тяжело — начни с телефона доверия.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            ...resourceCategories.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _CategoryBlock(category: c),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBlock extends StatelessWidget {
  const _CategoryBlock({required this.category});
  final ResourceCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category.title.toUpperCase(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.terracotta,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ...category.resources.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ResourceCard(resource: r),
          ),
        ),
      ],
    );
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({required this.resource});
  final Resource resource;

  Future<void> _open(BuildContext context) =>
      openExternal(context, resource.url);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPhone = resource.url.startsWith('tel:');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (isPhone ? AppColors.coral : AppColors.sage)
                      .withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPhone ? Icons.phone_rounded : Icons.link_rounded,
                  color: isPhone ? AppColors.coral : AppColors.sageDeep,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(resource.title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      resource.description,
                      style: theme.textTheme.bodyMedium,
                    ),
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
