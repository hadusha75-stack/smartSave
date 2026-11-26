import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:savesmart/core/constants/app_constants.dart';
import 'package:savesmart/core/utils/currency_formatter.dart';
import 'package:savesmart/core/utils/savings_calculator.dart';
import 'package:savesmart/features/goals/domain/models/goal.dart';
import 'package:savesmart/features/transactions/domain/models/saving_transaction.dart';

/// Shows the saving plan: required per period, expected vs actual,
/// behind-schedule warning, and projected completion date.
class PlanSummaryCard extends StatelessWidget {
  final Goal goal;
  final List<SavingTransaction> transactions;
  final String currency;

  const PlanSummaryCard({
    super.key,
    required this.goal,
    required this.transactions,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final today = DateTime.now();

    // Calculate all three periods
    final daily = SavingsCalculator.requiredPerPeriod(
      target: goal.targetAmount,
      current: goal.currentAmount,
      deadline: goal.deadline,
      today: today,
      frequency: AppConstants.freqDaily,
    );
    final weekly = SavingsCalculator.requiredPerPeriod(
      target: goal.targetAmount,
      current: goal.currentAmount,
      deadline: goal.deadline,
      today: today,
      frequency: AppConstants.freqWeekly,
    );
    final monthly = SavingsCalculator.requiredPerPeriod(
      target: goal.targetAmount,
      current: goal.currentAmount,
      deadline: goal.deadline,
      today: today,
      frequency: AppConstants.freqMonthly,
    );

    final behind = SavingsCalculator.behindAmount(
      target: goal.targetAmount,
      current: goal.currentAmount,
      createdAt: goal.createdAt,
      deadline: goal.deadline,
      today: today,
    );

    final projected = SavingsCalculator.projectedCompletionDate(
      target: goal.targetAmount,
      current: goal.currentAmount,
      today: today,
      recentTransactions: transactions,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.calculate_outlined,
                    size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('Saving Plan',
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 14),

            // ── Three period rows ─────────────────────────────────────
            _PeriodRow(
              icon: Icons.today_rounded,
              label: 'Daily',
              amount: CurrencyFormatter.format(daily, currency),
              color: colorScheme.primary,
            ),
            const SizedBox(height: 8),
            _PeriodRow(
              icon: Icons.date_range_rounded,
              label: 'Weekly',
              amount: CurrencyFormatter.format(weekly, currency),
              color: colorScheme.secondary,
            ),
            const SizedBox(height: 8),
            _PeriodRow(
              icon: Icons.calendar_month_rounded,
              label: 'Monthly',
              amount: CurrencyFormatter.format(monthly, currency),
              color: colorScheme.tertiary,
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),

            // ── Behind schedule banner ────────────────────────────────
            if (behind > 0 && !goal.isCompleted) ...[
              _BehindBanner(
                behind: behind,
                currency: currency,
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
              const SizedBox(height: 10),
            ] else if (!goal.isCompleted) ...[
              Row(
                children: [
                const  Icon(Icons.check_circle_rounded,
                      size: 16, color: Colors.green),
                  const SizedBox(width: 6),
                  Text(
                    'You are on track! Keep it up.',
                    style: textTheme.bodySmall
                        ?.copyWith(color: Colors.green[700]),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            // ── Projected completion ──────────────────────────────────
            if (projected != null && !goal.isCompleted)
              Row(
                children: [
                  Icon(Icons.flag_outlined,
                      size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'Projected: ${DateFormat('d MMM yyyy').format(projected)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

            if (goal.isCompleted) ...[
              Row(
                children: [
                  const Icon(Icons.emoji_events_rounded,
                      size: 18, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    'Goal achieved! 🏆',
                    style: textTheme.titleSmall?.copyWith(
                      color: Colors.amber[800],
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _PeriodRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String amount;
  final Color color;

  const _PeriodRow({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          amount,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
        ),
      ],
    );
  }
}

class _BehindBanner extends StatelessWidget {
  final double behind;
  final String currency;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _BehindBanner({
    required this.behind,
    required this.currency,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    // Suggest saving behind / 4 more per week to catch up
    final suggestion = behind / 4;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withAlpha(80),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: colorScheme.error.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 16, color: colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You are ${CurrencyFormatter.format(behind, currency)} behind plan. '
              'Saving ${CurrencyFormatter.format(suggestion, currency)} extra per week puts you back on track.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
