import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:savesmart/controllers/auth_controller.dart';
import 'package:savesmart/controllers/goal_controller.dart';
import 'package:savesmart/controllers/transaction_controller.dart';
import 'package:savesmart/core/constants/app_constants.dart';
import 'package:savesmart/core/constants/goal_categories.dart';
import 'package:savesmart/core/utils/currency_formatter.dart';
import 'package:savesmart/core/widgets/loading_view.dart';
import 'package:savesmart/features/goals/domain/models/goal.dart';
import 'package:savesmart/features/goals/presentation/widgets/plan_summary_card.dart';
import 'package:savesmart/features/transactions/domain/models/saving_transaction.dart';
import 'package:savesmart/routing/app_router.dart';

class GoalDetailScreen extends StatefulWidget {
  final String goalId;
  const GoalDetailScreen({super.key, required this.goalId});
  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
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

    return Obx(() {
      final goal = _goals.activeGoal.value;
      final txs  = _txs.goalTransactions;

      if (goal == null) {
        return Scaffold(appBar: AppBar(), body: const LoadingView());
      }

      final cat      = GoalCategories.findById(goal.category);
      final catColor = cat?.color ?? Theme.of(context).colorScheme.primary;

      return Scaffold(
        appBar: AppBar(
          title: Text(goal.title, overflow: TextOverflow.ellipsis),
          actions: [
            PopupMenuButton<String>(
              onSelected: (v) => _onMenu(context, v, goal),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit',      child: Text('Edit Goal')),
                const PopupMenuItem(value: 'reminders', child: Text('Reminders')),
                const PopupMenuItem(value: 'archive',   child: Text('Archive')),
                const PopupMenuItem(value: 'delete',
                    child: Text('Delete', style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
        floatingActionButton: goal.isActive
            ? FloatingActionButton.extended(
                onPressed: () => Get.toNamed(AppRoutes.addSaving, arguments: goal.id),
                icon: const Icon(Icons.add),
                label: const Text('Record Saving'),
              )
            : null,
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeroCard(goal: goal, catColor: catColor, currency: currency),
            const SizedBox(height: 12),
            _MilestoneBadges(achieved: goal.achievedMilestones),
            const SizedBox(height: 12),
            PlanSummaryCard(goal: goal, transactions: txs, currency: currency),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.bar_chart_rounded),
                label: const Text('View Charts & Badges'),
                onPressed: () => Get.toNamed(AppRoutes.progress, arguments: goal.id),
              ),
            ),
            const SizedBox(height: 12),
            _SavedInBreakdown(txs: txs, currency: currency),
            const SizedBox(height: 12),
            _RecentTxList(txs: txs, currency: currency, goalId: goal.id),
            const SizedBox(height: 80),
          ],
        ),
      );
    });
  }

  Future<void> _onMenu(BuildContext context, String action, Goal goal) async {
    switch (action) {
      case 'edit':
        Get.toNamed(AppRoutes.editGoal, arguments: goal.id);
      case 'reminders':
        Get.toNamed(AppRoutes.reminders, arguments: goal.id);
      case 'archive':
        final ok = await Get.dialog<bool>(AlertDialog(
          title: const Text('Archive Goal'),
          content: const Text('The goal will be hidden from your list.'),
          actions: [
            TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Get.back(result: true), child: const Text('Archive')),
          ],
        ));
        if (ok == true) { await _goals.archiveGoal(goal.id); Get.back(); }
      case 'delete':
        final ok = await Get.dialog<bool>(AlertDialog(
          title: const Text('Delete Goal'),
          content: const Text('This will permanently delete the goal and all savings records.'),
          actions: [
            TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error),
              onPressed: () => Get.back(result: true),
              child: const Text('Delete'),
            ),
          ],
        ));
        if (ok == true) { await _goals.deleteGoal(goal.id); Get.back(); }
    }
  }
}

// ── Hero progress card ────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final Goal goal;
  final Color catColor;
  final String currency;
  const _HeroCard({required this.goal, required this.catColor, required this.currency});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final progress = goal.progressFraction;

    return Card(child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: catColor.withAlpha(30),
                borderRadius: BorderRadius.circular(14)),
            child: Icon(
              GoalCategories.findById(goal.category)?.icon ?? Icons.savings_rounded,
              color: catColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(CurrencyFormatter.format(goal.currentAmount, currency),
                style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: catColor)),
            Text('of ${CurrencyFormatter.format(goal.targetAmount, currency)}',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          ])),
          Text('${(progress * 100).toStringAsFixed(1)}%',
              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: catColor)),
        ]),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress, minHeight: 12,
            backgroundColor: catColor.withAlpha(30),
            valueColor: AlwaysStoppedAnimation<Color>(
                goal.isCompleted ? Colors.green : catColor),
          ),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            const Icon(Icons.local_fire_department_rounded, size: 14, color: Colors.orange),
            const SizedBox(width: 4),
            Text('${goal.streak} streak', style: tt.bodySmall?.copyWith(color: Colors.orange)),
          ]),
          Row(children: [
            const Icon(Icons.calendar_today_outlined, size: 14),
            const SizedBox(width: 4),
            Text(DateFormat('d MMM yyyy').format(goal.deadline),
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ]),
        ]),
      ]),
    ));
  }
}

// ── Milestone badges ──────────────────────────────────────────────────────────

class _MilestoneBadges extends StatelessWidget {
  final List<int> achieved;
  const _MilestoneBadges({required this.achieved});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final badges = {25: '🌱', 50: '🌿', 75: '🌳', 100: '🏆'};
    return Card(child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Milestones', style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: badges.entries.map((e) {
            final unlocked = achieved.contains(e.key);
            return Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: unlocked ? cs.primaryContainer : Colors.transparent,
                  border: Border.all(
                      color: unlocked ? cs.primary : cs.outlineVariant,
                      width: unlocked ? 2 : 1.5)),
                child: Center(child: Text(e.value,
                    style: TextStyle(fontSize: 22,
                        color: unlocked ? null : Colors.grey))),
              ),
              const SizedBox(height: 4),
              Text('${e.key}%', style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(fontWeight: FontWeight.w600,
                      color: unlocked ? cs.primary : cs.outlineVariant)),
            ]);
          }).toList(),
        ),
      ]),
    ));
  }
}

// ── Saved-in breakdown ────────────────────────────────────────────────────────

class _SavedInBreakdown extends StatelessWidget {
  final List<SavingTransaction> txs;
  final String currency;
  const _SavedInBreakdown({required this.txs, required this.currency});

  @override
  Widget build(BuildContext context) {
    if (txs.isEmpty) return const SizedBox.shrink();
    final Map<String, double> totals = {};
    for (final tx in txs) {
      totals[tx.savedIn] = (totals[tx.savedIn] ?? 0) + tx.amount;
    }
    final cs = Theme.of(context).colorScheme;
    return Card(child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Where you saved', style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...totals.entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Icon(_icon(e.key), size: 16, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(e.key)),
            Text(CurrencyFormatter.format(e.value, currency),
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ]),
        )),
      ]),
    ));
  }

  IconData _icon(String s) {
    switch (s) {
      case AppConstants.savedInBank:   return Icons.account_balance_rounded;
      case AppConstants.savedInWallet: return Icons.phone_android_rounded;
      case AppConstants.savedInCash:   return Icons.home_rounded;
      case AppConstants.savedInGroup:  return Icons.group_rounded;
      default: return Icons.savings_rounded;
    }
  }
}

// ── Recent transactions ───────────────────────────────────────────────────────

class _RecentTxList extends StatelessWidget {
  final List<SavingTransaction> txs;
  final String currency, goalId;
  const _RecentTxList({required this.txs, required this.currency, required this.goalId});

  @override
  Widget build(BuildContext context) {
    if (txs.isEmpty) return const SizedBox.shrink();
    final recent = txs.take(5).toList();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Recent Savings', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          if (txs.length > 5)
            TextButton(onPressed: () => Get.toNamed(AppRoutes.allHistory),
                child: const Text('See all')),
        ]),
        const SizedBox(height: 8),
        ...recent.map((tx) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: cs.primaryContainer.withAlpha(80),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.arrow_upward_rounded, size: 18, color: cs.primary),
          ),
          title: Text(CurrencyFormatter.format(tx.amount, currency),
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          subtitle: Text(
              '${DateFormat('d MMM yyyy').format(tx.date)} · ${tx.savedIn}'
              '${tx.note != null ? '\n${tx.note}' : ''}',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18),
            onSelected: (action) => _onTxAction(context, action, tx),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red))),
            ],
          ),
        )),
      ]),
    ));
  }

  Future<void> _onTxAction(BuildContext context, String action, SavingTransaction tx) async {
    final txController = Get.find<TransactionController>();
    if (action == 'edit') {
      Get.toNamed(AppRoutes.editSaving,
          arguments: {'goalId': goalId, 'txId': tx.id});
    } else if (action == 'delete') {
      final ok = await Get.dialog<bool>(AlertDialog(
        title: const Text('Delete Saving'),
        content: const Text('Remove this saving record?'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Get.back(result: true),
            child: const Text('Delete'),
          ),
        ],
      ));
      if (ok == true) {
        await txController.deleteTransaction(
            goalId: goalId, txId: tx.id, amount: tx.amount);
      }
    }
  }
}
