import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:savesmart/core/constants/goal_categories.dart';
import 'package:savesmart/core/utils/currency_formatter.dart';
import 'package:savesmart/features/goals/domain/models/goal.dart';
import 'package:savesmart/routing/app_router.dart';

/// A card showing a single goal's title, category, progress, and amounts.
/// Tapping navigates to the Goal Detail screen.
class GoalCard extends StatelessWidget {
  final Goal goal;
  final String currency;

  const GoalCard({super.key, required this.goal, required this.currency});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final category = GoalCategories.findById(goal.category);
    final catColor = _parseColor(goal.colorHex) ?? category?.color ?? colorScheme.primary;
    final progress = goal.progressFraction;
    final pct = (progress * 100).toStringAsFixed(0);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Get.toNamed(AppRoutes.goalDetail, arguments: goal.id),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: icon + title + status chip ──────────────────
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: catColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      category?.icon ?? Icons.savings_rounded,
                      color: catColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _deadlineLabel(goal.deadline),
                          style: textTheme.bodySmall?.copyWith(
                            color: _deadlineColor(goal.deadline, colorScheme),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (goal.isCompleted)
                    const _StatusChip(
                      label: 'Done',
                      color: Colors.green,
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Progress bar ─────────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: catColor.withAlpha(30),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    goal.isCompleted ? Colors.green : catColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── Amounts row ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    CurrencyFormatter.format(goal.currentAmount, currency),
                    style: textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$pct% of ${CurrencyFormatter.format(goal.targetAmount, currency)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              // ── Streak chip (if > 0) ──────────────────────────────────
              if (goal.streak > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                  const   Icon(Icons.local_fire_department_rounded,
                        size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      '${goal.streak}-period streak',
                      style: textTheme.labelSmall?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    // Quick action: view progress
                    InkWell(
                      onTap: () => Get.toNamed(AppRoutes.progress, arguments: goal.id),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        child: Icon(Icons.bar_chart_rounded,
                            size: 16,
                            color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _deadlineLabel(DateTime deadline) {
    final daysLeft = DateTime.now().difference(deadline).inDays.abs();
    if (deadline.isBefore(DateTime.now())) return 'Deadline passed';
    if (daysLeft == 0) return 'Due today';
    if (daysLeft == 1) return '1 day left';
    if (daysLeft < 30) return '$daysLeft days left';
    final months = (daysLeft / 30).floor();
    if (months == 1) return '1 month left';
    return '$months months left';
  }

  Color _deadlineColor(DateTime deadline, ColorScheme cs) {
    final daysLeft = deadline.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return cs.error;
    if (daysLeft <= 7) return Colors.orange;
    return cs.onSurfaceVariant;
  }

  Color? _parseColor(String? hex) {
    if (hex == null) return null;
    try {
      final cleaned = hex.replaceFirst('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return null;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
