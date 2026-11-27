import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:savesmart/controllers/auth_controller.dart';
import 'package:savesmart/controllers/goal_controller.dart';
import 'package:savesmart/controllers/tip_controller.dart';
import 'package:savesmart/core/constants/app_constants.dart';
import 'package:savesmart/core/utils/currency_formatter.dart';
import 'package:savesmart/core/widgets/empty_state.dart';
import 'package:savesmart/features/goals/presentation/widgets/goal_card.dart';
import 'package:savesmart/features/transactions/presentation/screens/all_history_screen.dart';
import 'package:savesmart/features/settings/presentation/screens/settings_screen.dart';
import 'package:savesmart/routing/app_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RxInt _navIndex = 0.obs;

  @override
  void initState() {
    super.initState();
    // AuthController._notifyControllers() handles setUid when Firebase Auth resolves.
    // No need to call setUid here — it causes a race condition on web.
  }

  static const _pages = [_GoalsTab(), AllHistoryScreen(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      body: IndexedStack(index: _navIndex.value, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex.value,
        onDestinationSelected: (i) => _navIndex.value = i,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.savings_outlined),
              selectedIcon: Icon(Icons.savings_rounded), label: 'Goals'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded), label: 'History'),
          NavigationDestination(icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    ));
  }
}

// ── Goals Tab ─────────────────────────────────────────────────────────────────

class _GoalsTab extends StatelessWidget {
  const _GoalsTab();

  @override
  Widget build(BuildContext context) {
    final auth     = Get.find<AuthController>();
    final goals    = Get.find<GoalController>();
    final tips     = Get.find<TipController>();
    final currency = auth.currentUser.value?.currency ?? AppConstants.defaultCurrency;
    final user     = auth.currentUser.value;

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('SaveSmart'),
          if (user != null)
            Text('Hello, ${user.name.split(' ').first}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _confirmLogout(context, auth),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.createGoal),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Goal'),
      ),
      body: Obx(() {
        final all       = goals.goals;
        final active    = all.where((g) => g.isActive).toList();
        final completed = all.where((g) => g.isCompleted).toList();

        if (all.isEmpty) {
          return ListView(children: [
            _TipBanner(tips: tips),
            const SizedBox(height: 16),
            const EmptyState(
              icon: Icons.savings_rounded,
              title: 'No savings goals yet',
              subtitle: 'Tap "New Goal" to create your first goal!',
            ),
          ]);
        }

        return RefreshIndicator(
          onRefresh: () async => Get.find<GoalController>().subscribeToGoals(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              _TipBanner(tips: tips),
              const SizedBox(height: 16),
              _SummaryStrip(goals: all, currency: currency),
              const SizedBox(height: 16),
              if (active.isNotEmpty) ...[
                _SectionHeader('Active Goals (${active.length})'),
                const SizedBox(height: 8),
                ...active.map((g) => GoalCard(goal: g, currency: currency)),
                const SizedBox(height: 16),
              ],
              if (completed.isNotEmpty) ...[
                _SectionHeader('Completed Goals (${completed.length})'),
                const SizedBox(height: 8),
                ...completed.map((g) => GoalCard(goal: g, currency: currency)),
              ],
            ],
          ),
        );
      }),
    );
  }

  Future<void> _confirmLogout(BuildContext context, AuthController auth) async {
    final ok = await Get.dialog<bool>(AlertDialog(
      title: const Text('Log Out'),
      content: const Text('Are you sure you want to log out?'),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Get.back(result: true), child: const Text('Log Out')),
      ],
    ));
    if (ok == true) {
      await auth.logout();
      Get.offAllNamed(AppRoutes.login);
    }
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _TipBanner extends StatelessWidget {
  final TipController tips;
  const _TipBanner({required this.tips});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tip = tips.latestTip.value;
      if (tip == null) return const SizedBox.shrink();
      final cs = Theme.of(context).colorScheme;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withAlpha(80),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.primary.withAlpha(40)),
        ),
        child: Row(children: [
          Icon(Icons.lightbulb_outline_rounded, color: cs.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tip of the Day', style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(tip.message, style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: cs.onPrimaryContainer),
                maxLines: 3, overflow: TextOverflow.ellipsis),
          ])),
        ]),
      );
    });
  }
}

class _SummaryStrip extends StatelessWidget {
  final List goals;
  final String currency;
  const _SummaryStrip({required this.goals, required this.currency});

  @override
  Widget build(BuildContext context) {
    final saved  = goals.fold<double>(0, (s, g) => s + (g.currentAmount as double));
    final active = goals.where((g) => g.isActive as bool).length;

    return Row(children: [
      Expanded(flex: 2, child: _StatBox(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Total Saved',
        value: CurrencyFormatter.format(saved, currency),
      )),
      const SizedBox(width: 10),
      Expanded(child: _StatBox(
        icon: Icons.flag_rounded,
        label: 'Active',
        value: active.toString(),
      )),
    ]);
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _StatBox({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Icon(icon, color: cs.primary, size: 20),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: cs.onSurfaceVariant)),
          Text(value, style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);
  @override
  Widget build(BuildContext context) => Text(label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700));
}
