import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:savesmart/controllers/auth_controller.dart';
import 'package:savesmart/controllers/goal_controller.dart';
import 'package:savesmart/controllers/transaction_controller.dart';
import 'package:savesmart/core/constants/app_constants.dart';
import 'package:savesmart/core/utils/currency_formatter.dart';
import 'package:savesmart/core/widgets/loading_view.dart';
import 'package:savesmart/features/transactions/domain/models/saving_transaction.dart';

class ProgressScreen extends StatefulWidget {
  final String goalId;
  const ProgressScreen({super.key, required this.goalId});
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _goals = Get.find<GoalController>();
  final _txs   = Get.find<TransactionController>();
  final _auth  = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _goals.subscribeToGoal(widget.goalId);
    _txs.subscribeToGoalTransactions(widget.goalId);
  }

  @override
  Widget build(BuildContext context) {
    final currency = _auth.currentUser.value?.currency ?? AppConstants.defaultCurrency;

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: Obx(() {
        final goal = _goals.activeGoal.value;
        final txs  = _txs.goalTransactions;

        if (goal == null) return const LoadingView();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StatsRow(goal: goal, currency: currency),
            const SizedBox(height: 16),
            _StreakCard(streak: goal.streak),
            const SizedBox(height: 16),
            _SavingsChart(transactions: txs, currency: currency,
                targetAmount: goal.targetAmount),
            const SizedBox(height: 16),
            _MilestoneSection(
                achievedMilestones: List<int>.from(goal.achievedMilestones),
                progressPercent: goal.progressPercent),
            const SizedBox(height: 16),
            _SavedInPie(transactions: txs, currency: currency),
            const SizedBox(height: 32),
          ],
        );
      }),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final dynamic goal;
  final String currency;
  const _StatsRow({required this.goal, required this.currency});

  @override
  Widget build(BuildContext context) {
    final remaining = (goal.targetAmount as double) -
        (goal.currentAmount as double);
    final today = DateTime.now();
    final daysLeft =
        (goal.deadline as DateTime).difference(today).inDays;

    return Row(
      children: [
        _MiniStat(
          label: 'Saved',
          value: CurrencyFormatter.format(
              goal.currentAmount as double, currency),
          icon: Icons.check_circle_rounded,
          color: Colors.green,
        ),
        const SizedBox(width: 10),
        _MiniStat(
          label: 'Remaining',
          value: CurrencyFormatter.format(
              remaining.clamp(0, double.infinity), currency),
          icon: Icons.hourglass_bottom_rounded,
          color: Colors.orange,
        ),
        const SizedBox(width: 10),
        _MiniStat(
          label: 'Days left',
          value: daysLeft > 0 ? '$daysLeft' : 'Past due',
          icon: Icons.calendar_today_rounded,
          color: daysLeft <= 7 ? Colors.red : Colors.blue,
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MiniStat(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withAlpha(80),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    )),
          ],
        ),
      ),
    );
  }
}

// ── Streak card ───────────────────────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  final int streak;
  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(25),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.local_fire_department_rounded,
                  size: 32, color: Colors.orange),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    streak == 0
                        ? 'No streak yet'
                        : '$streak-period streak 🔥',
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    streak == 0
                        ? 'Record a saving to start your streak!'
                        : 'You have saved on plan for $streak consecutive period${streak == 1 ? '' : 's'}.',
                    style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant),
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

// ── Savings line chart ────────────────────────────────────────────────────────

class _SavingsChart extends StatelessWidget {
  final List<SavingTransaction> transactions;
  final String currency;
  final double targetAmount;

  const _SavingsChart({
    required this.transactions,
    required this.currency,
    required this.targetAmount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (transactions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text('No savings recorded yet.',
                style: textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant)),
          ),
        ),
      );
    }

    // Build cumulative daily spots
    // Sort oldest first
    final sorted = [...transactions]
      ..sort((a, b) => a.date.compareTo(b.date));

    // Accumulate by day: map date -> cumulative total
    final Map<DateTime, double> dailyCumulative = {};
    double running = 0;
    for (final tx in sorted) {
      final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
      running += tx.amount;
      dailyCumulative[day] = running;
    }

    final days = dailyCumulative.keys.toList()..sort();
    final spots = days.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), dailyCumulative[e.value]!);
    }).toList();

    // X-axis labels (show at most 5)
    final labelStep = (days.length / 5).ceil().clamp(1, days.length);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 16),
              child: Text('Savings Over Time',
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: targetAmount * 1.05,
                  clipData: const FlClipData.all(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: colorScheme.outlineVariant.withAlpha(60),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 52,
                        getTitlesWidget: (value, _) => Text(
                          CurrencyFormatter.formatPlain(value, currency),
                          style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 9),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (value, _) {
                          final idx = value.toInt();
                          if (idx % labelStep != 0 || idx >= days.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              DateFormat('d MMM').format(days[idx]),
                              style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 9),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    // Actual savings line
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: colorScheme.primary,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: spots.length <= 10,
                        getDotPainter: (_, __, ___, ____) =>
                            FlDotCirclePainter(
                          radius: 3,
                          color: colorScheme.primary,
                          strokeWidth: 0,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colorScheme.primary.withAlpha(20),
                      ),
                    ),
                    // Target line (horizontal)
                    LineChartBarData(
                      spots: [
                        FlSpot(0, targetAmount),
                        FlSpot((spots.length - 1).toDouble(), targetAmount),
                      ],
                      isCurved: false,
                      color: Colors.green.withAlpha(120),
                      barWidth: 1.5,
                      dashArray: [6, 4],
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((s) {
                          final idx = s.x.toInt();
                          final date = idx < days.length ? days[idx] : null;
                          return LineTooltipItem(
                            '${date != null ? DateFormat('d MMM').format(date) : ''}\n'
                            '${CurrencyFormatter.format(s.y, currency)}',
                            TextStyle(
                                color: colorScheme.onPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: colorScheme.primary, label: 'Saved'),
                const SizedBox(width: 16),
                _LegendDot(
                    color: Colors.green.withAlpha(160),
                    label: 'Target',
                    dashed: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;
  const _LegendDot(
      {required this.color, required this.label, this.dashed = false});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 16,
              height: 3,
              decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 6),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      );
}

// ── Milestone section ─────────────────────────────────────────────────────────

class _MilestoneSection extends StatelessWidget {
  final List<int> achievedMilestones;
  final double progressPercent;

  const _MilestoneSection({
    required this.achievedMilestones,
    required this.progressPercent,
  });

  static const _badgeData = {
    25: _BadgeInfo('25%', '🌱', 'First Quarter', 'You saved 25% of your goal!'),
    50: _BadgeInfo('50%', '🌿', 'Halfway There', 'You have saved half your goal!'),
    75: _BadgeInfo('75%', '🌳', 'Almost There', 'Only 25% left to go!'),
    100: _BadgeInfo('100%', '🏆', 'Goal Achieved', 'Congratulations! Goal complete!'),
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Milestone Badges',
                style:
                    textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ..._badgeData.entries.map((e) {
              final unlocked = achievedMilestones.contains(e.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    // Badge icon
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: unlocked
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHighest
                                .withAlpha(80),
                        border: Border.all(
                          color: unlocked
                              ? colorScheme.primary
                              : colorScheme.outlineVariant,
                          width: unlocked ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          e.value.emoji,
                          style: TextStyle(
                              fontSize: 24,
                              color: unlocked ? null : Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.value.title,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: unlocked
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            unlocked
                                ? e.value.description
                                : 'Reach ${e.key}% to unlock',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (unlocked)
                  const    Icon(Icons.check_circle_rounded,
                          color: Colors.green, size: 20)
                    else
                      Icon(Icons.lock_outline_rounded,
                          color: colorScheme.outlineVariant, size: 20),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _BadgeInfo {
  final String percent;
  final String emoji;
  final String title;
  final String description;
  const _BadgeInfo(this.percent, this.emoji, this.title, this.description);
}

// ── Saved-in pie chart ────────────────────────────────────────────────────────

class _SavedInPie extends StatefulWidget {
  final List<SavingTransaction> transactions;
  final String currency;

  const _SavedInPie({required this.transactions, required this.currency});

  @override
  State<_SavedInPie> createState() => _SavedInPieState();
}

class _SavedInPieState extends State<_SavedInPie> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.transactions.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Group by savedIn
    final Map<String, double> totals = {};
    for (final tx in widget.transactions) {
      totals[tx.savedIn] = (totals[tx.savedIn] ?? 0) + tx.amount;
    }
    final grandTotal = totals.values.fold<double>(0, (s, v) => s + v);

    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      Colors.orange,
      Colors.purple,
    ];

    final sections = totals.entries.toList().asMap().entries.map((entry) {
      final i = entry.key;
      final e = entry.value;
      final pct = grandTotal > 0 ? e.value / grandTotal : 0.0;
      final isTouched = i == _touched;
      return PieChartSectionData(
        value: e.value,
        color: colors[i % colors.length],
        radius: isTouched ? 64 : 54,
        title: isTouched ? '${(pct * 100).toStringAsFixed(1)}%' : '',
        titleStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
        badgeWidget: isTouched
            ? null
            : null,
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Savings by Location',
                style:
                    textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 40,
                        pieTouchData: PieTouchData(
                          touchCallback: (evt, resp) {
                            setState(() {
                              if (!evt.isInterestedForInteractions ||
                                  resp == null ||
                                  resp.touchedSection == null) {
                                _touched = -1;
                              } else {
                                _touched = resp.touchedSection!
                                    .touchedSectionIndex;
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Legend
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: totals.entries.toList().asMap().entries.map((e) {
                      final i = e.key;
                      final entry = e.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: colors[i % colors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              entry.key,
                              style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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

