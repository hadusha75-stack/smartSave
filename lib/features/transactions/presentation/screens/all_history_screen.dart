import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:savesmart/controllers/auth_controller.dart';
import 'package:savesmart/controllers/goal_controller.dart';
import 'package:savesmart/controllers/transaction_controller.dart';
import 'package:savesmart/core/utils/currency_formatter.dart';
import 'package:savesmart/core/widgets/empty_state.dart';
import 'package:savesmart/features/transactions/domain/models/saving_transaction.dart';

class AllHistoryScreen extends StatefulWidget {
  const AllHistoryScreen({super.key});
  @override
  State<AllHistoryScreen> createState() => _AllHistoryScreenState();
}

class _AllHistoryScreenState extends State<AllHistoryScreen> {
  final _txCtrl    = Get.find<TransactionController>();
  final _goalCtrl  = Get.find<GoalController>();
  final _auth      = Get.find<AuthController>();
  String? _filterGoalId;
  DateTimeRange? _filterRange;

  @override
  void initState() {
    super.initState();
    _txCtrl.subscribeToAllTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final currency = _auth.currentUser.value?.currency ?? 'ETB';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showFilter(context),
          ),
          if (_filterGoalId != null || _filterRange != null)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () => setState(() { _filterGoalId = null; _filterRange = null; }),
            ),
        ],
      ),
      body: Obx(() {
        final filtered = _txCtrl.allTransactions.where((tx) {
          if (_filterGoalId != null && tx.goalId != _filterGoalId) return false;
          if (_filterRange != null) {
            if (tx.date.isBefore(_filterRange!.start)) return false;
            if (tx.date.isAfter(_filterRange!.end.add(const Duration(days: 1)))) return false;
          }
          return true;
        }).toList();

        if (filtered.isEmpty) {
          return const EmptyState(icon: Icons.receipt_long_rounded,
              title: 'No transactions yet',
              subtitle: 'Your saving records will appear here.');
        }

        final grouped = <String, List<SavingTransaction>>{};
        for (final tx in filtered) {
          final key = DateFormat('MMMM yyyy').format(tx.date);
          grouped.putIfAbsent(key, () => []).add(tx);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: grouped.length,
          itemBuilder: (_, i) {
            final key  = grouped.keys.elementAt(i);
            final txs  = grouped[key]!;
            final total = txs.fold<double>(0, (s, t) => s + t.amount);
            final cs   = Theme.of(context).colorScheme;
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(key, style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
                  Text(CurrencyFormatter.format(total, currency),
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
                ]),
              ),
              Card(child: Column(children: txs.asMap().entries.map((e) => Column(children: [
                ListTile(
                  leading: Container(width: 40, height: 40,
                    decoration: BoxDecoration(color: cs.primaryContainer.withAlpha(80),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.arrow_upward_rounded, size: 18, color: cs.primary)),
                  title: Text(CurrencyFormatter.format(e.value.amount, currency),
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  subtitle: Text('${DateFormat('d MMM yyyy').format(e.value.date)} · ${e.value.savedIn}',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ),
                if (e.key < txs.length - 1) const Divider(height: 1, indent: 56),
              ])).toList())),
              const SizedBox(height: 8),
            ]);
          },
        );
      }),
    );
  }

  Future<void> _showFilter(BuildContext context) async {
    final goals = _goalCtrl.goals;
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(builder: (ctx, setLocal) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Filter History', style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            initialValue: _filterGoalId,
            decoration: const InputDecoration(hintText: 'All goals'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All goals')),
              ...goals.map((g) => DropdownMenuItem(value: g.id, child: Text(g.title))),
            ],
            onChanged: (v) { setState(() => _filterGoalId = v); setLocal(() {}); },
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            icon: const Icon(Icons.date_range_rounded),
            label: Text(_filterRange == null ? 'Select date range'
                : '${DateFormat('d MMM').format(_filterRange!.start)} – '
                  '${DateFormat('d MMM yyyy').format(_filterRange!.end)}'),
            onPressed: () async {
              final r = await showDateRangePicker(
                  context: context, firstDate: DateTime(2020),
                  lastDate: DateTime.now());
              if (r != null) { setState(() => _filterRange = r); setLocal(() {}); }
            },
          )),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Apply'))),
        ]),
      )),
    );
  }
}
