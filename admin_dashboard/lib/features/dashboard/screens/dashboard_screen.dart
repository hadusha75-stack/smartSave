import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:savesmart_admin/services/admin_providers.dart';

final _statsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.read(adminFirestoreServiceProvider).getStats();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(_statsProvider);
    final textTheme  = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_statsProvider),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48),
              const SizedBox(height: 12),
              Text(e.toString()),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(_statsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Overview',
                  style: textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),

              // ── Stats grid ───────────────────────────────────────
              _StatsGrid(stats: stats),
              const SizedBox(height: 28),

              // ── Top categories ───────────────────────────────────
              Text('Most Popular Goal Categories',
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _TopCategoriesCard(
                  entries: stats['topCategories'] as List),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stats grid ────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem(
        icon: Icons.people_rounded,
        label: 'Total Users',
        value: '${stats['totalUsers']}',
        color: Colors.blue,
      ),
      _StatItem(
        icon: Icons.flag_rounded,
        label: 'Active Goals',
        value: '${stats['activeGoals']}',
        color: Colors.green,
      ),
      _StatItem(
        icon: Icons.emoji_events_rounded,
        label: 'Completed Goals',
        value: '${stats['completedGoals']}',
        color: Colors.amber,
      ),
      _StatItem(
        icon: Icons.feedback_rounded,
        label: 'Open Feedback',
        value: '${stats['openFeedback']}',
        color: Colors.orange,
      ),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final crossAxis = constraints.maxWidth > 600 ? 4 : 2;
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxis,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: items.map((item) => _StatCard(item: item)).toList(),
      );
    });
  }
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(item.icon, color: item.color, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.value,
                    style: textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                Text(item.label,
                    style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top categories ────────────────────────────────────────────────────────────

class _TopCategoriesCard extends StatelessWidget {
  final List entries;
  const _TopCategoriesCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (entries.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No goal data yet.'),
        ),
      );
    }
    final maxCount = (entries.first.value as int).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: entries.map((e) {
            final cat   = e.key as String;
            final count = e.value as int;
            final ratio = maxCount > 0 ? count / maxCount : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      _catLabel(cat),
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 10,
                        backgroundColor:
                            colorScheme.primaryContainer.withAlpha(60),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('$count',
                      style: Theme.of(context).textTheme.labelLarge),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _catLabel(String id) => id
      .split('_')
      .map((w) => w.isNotEmpty
          ? w[0].toUpperCase() + w.substring(1)
          : '')
      .join(' ');
}
