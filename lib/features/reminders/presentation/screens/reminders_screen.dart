import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:savesmart/controllers/auth_controller.dart';
import 'package:savesmart/controllers/goal_controller.dart';
import 'package:savesmart/controllers/reminder_controller.dart';
import 'package:savesmart/core/constants/app_constants.dart';
import 'package:savesmart/core/utils/savings_calculator.dart';
import 'package:savesmart/core/widgets/empty_state.dart';
import 'package:savesmart/features/reminders/domain/models/reminder.dart';
import 'package:savesmart/services/notification_service.dart';

class RemindersScreen extends StatefulWidget {
  final String goalId;
  const RemindersScreen({super.key, required this.goalId});
  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final _remCtrl  = Get.find<ReminderController>();
  final _goalCtrl = Get.find<GoalController>();
  final _auth     = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    final uid = _auth.firebaseUser.value?.uid ?? '';
    _remCtrl.setUid(uid);
    _remCtrl.subscribeToReminders(widget.goalId);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService.requestPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('Add Reminder'),
      ),
      body: Obx(() {
        final reminders = _remCtrl.reminders;
        if (reminders.isEmpty) {
          return const EmptyState(icon: Icons.alarm_outlined,
              title: 'No reminders yet',
              subtitle: 'Add a reminder and we will notify you when it is time to save.');
        }

        final goal     = _goalCtrl.activeGoal.value;
        final currency = _auth.currentUser.value?.currency ?? AppConstants.defaultCurrency;
        final weekly   = goal != null ? SavingsCalculator.requiredPerPeriod(
          target: goal.targetAmount, current: goal.currentAmount,
          deadline: goal.deadline, today: DateTime.now(),
          frequency: AppConstants.freqWeekly,
        ) : 0.0;

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reminders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _ReminderTile(
            reminder: reminders[i],
            goalId: widget.goalId,
            goalTitle: goal?.title ?? '',
            weeklyPlan: weekly,
            currency: currency,
          ),
        );
      }),
    );
  }

  void _showAddSheet(BuildContext context) {
    final goal     = _goalCtrl.activeGoal.value;
    final currency = _auth.currentUser.value?.currency ?? AppConstants.defaultCurrency;
    final weekly   = goal != null ? SavingsCalculator.requiredPerPeriod(
      target: goal.targetAmount, current: goal.currentAmount,
      deadline: goal.deadline, today: DateTime.now(),
      frequency: AppConstants.freqWeekly,
    ) : 0.0;

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddSheet(
        goalId: widget.goalId, goalTitle: goal?.title ?? '',
        weeklyPlan: weekly, currency: currency,
      ),
    );
  }
}

// ── Reminder tile ─────────────────────────────────────────────────────────────

class _ReminderTile extends StatelessWidget {
  final Reminder reminder;
  final String goalId, goalTitle, currency;
  final double weeklyPlan;
  const _ReminderTile({required this.reminder, required this.goalId,
      required this.goalTitle, required this.weeklyPlan, required this.currency});

  @override
  Widget build(BuildContext context) {
    final cs   = Theme.of(context).colorScheme;
    final ctrl = Get.find<ReminderController>();

    return Card(child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: (reminder.active ? cs.primaryContainer : cs.surfaceContainerHighest)
              .withAlpha(80),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(_icon(reminder.frequency),
            color: reminder.active ? cs.primary : cs.onSurfaceVariant, size: 22),
      ),
      title: Text(_freqLabel(reminder),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(_timeLabel(reminder),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Switch(
          value: reminder.active,
          onChanged: (val) => ctrl.setActive(
            goalId: goalId, reminderId: reminder.id, active: val,
            goalTitle: goalTitle, weeklyPlanAmount: weeklyPlan, currency: currency),
        ),
        IconButton(
          icon: Icon(Icons.delete_outline_rounded, size: 20, color: cs.error),
          onPressed: () async {
            final ok = await Get.dialog<bool>(AlertDialog(
              title: const Text('Delete Reminder'),
              content: const Text('Remove this reminder?'),
              actions: [
                TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: cs.error),
                  onPressed: () => Get.back(result: true),
                  child: const Text('Delete'),
                ),
              ],
            ));
            if (ok == true) await ctrl.deleteReminder(goalId: goalId, reminderId: reminder.id);
          },
        ),
      ]),
    ));
  }

  IconData _icon(String f) {
    switch (f) {
      case AppConstants.freqDaily:   return Icons.today_rounded;
      case AppConstants.freqWeekly:  return Icons.date_range_rounded;
      case AppConstants.freqMonthly: return Icons.calendar_month_rounded;
      default: return Icons.alarm_rounded;
    }
  }

  String _freqLabel(Reminder r) {
    switch (r.frequency) {
      case AppConstants.freqDaily: return 'Daily';
      case AppConstants.freqWeekly:
        const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return 'Every ${r.weekday != null && r.weekday! <= 7 ? days[r.weekday!] : 'Weekly'}';
      case AppConstants.freqMonthly: return 'Every month on day ${r.dayOfMonth ?? 1}';
      default: return r.frequency;
    }
  }

  String _timeLabel(Reminder r) {
    final h = r.hourOfDay.toString().padLeft(2, '0');
    final m = r.minute.toString().padLeft(2, '0');
    return 'At $h:$m';
  }
}

// ── Add reminder bottom sheet ─────────────────────────────────────────────────

class _AddSheet extends StatefulWidget {
  final String goalId, goalTitle, currency;
  final double weeklyPlan;
  const _AddSheet({required this.goalId, required this.goalTitle,
      required this.weeklyPlan, required this.currency});
  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  final _ctrl      = Get.find<ReminderController>();
  String _freq     = AppConstants.freqDaily;
  int    _weekday  = DateTime.monday;
  int    _dayOfMonth = 1;
  TimeOfDay _time  = const TimeOfDay(hour: 8, minute: 0);
  bool   _saving   = false;

  Future<void> _pickTime() async {
    final p = await showTimePicker(context: context, initialTime: _time);
    if (p != null) setState(() => _time = p);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _ctrl.createReminder(
        goalId: widget.goalId, goalTitle: widget.goalTitle,
        frequency: _freq, hourOfDay: _time.hour, minute: _time.minute,
        weekday: _freq == AppConstants.freqWeekly ? _weekday : null,
        dayOfMonth: _freq == AppConstants.freqMonthly ? _dayOfMonth : null,
        weeklyPlanAmount: widget.weeklyPlan, currency: widget.currency,
      );
      Get.back();
      Get.snackbar('Success', 'Reminder saved!');
    } catch (e) {
      Get.snackbar('Error', e.toString(),
          // ignore: use_build_context_synchronously
          backgroundColor: Theme.of(context).colorScheme.error,
          // ignore: use_build_context_synchronously
          colorText: Theme.of(context).colorScheme.onError);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs      = Theme.of(context).colorScheme;
    final tt      = Theme.of(context).textTheme;
    final botPad  = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + botPad),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Text('New Reminder', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),

        Text('Frequency', style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: AppConstants.freqDaily,   label: Text('Daily'),   icon: Icon(Icons.today_rounded, size: 16)),
            ButtonSegment(value: AppConstants.freqWeekly,  label: Text('Weekly'),  icon: Icon(Icons.date_range_rounded, size: 16)),
            ButtonSegment(value: AppConstants.freqMonthly, label: Text('Monthly'), icon: Icon(Icons.calendar_month_rounded, size: 16)),
          ],
          selected: {_freq},
          onSelectionChanged: (s) => setState(() => _freq = s.first),
        ),
        const SizedBox(height: 16),

        if (_freq == AppConstants.freqWeekly) ...[
          Text('Day of week', style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: _weekday,
            decoration: const InputDecoration(),
            items: const [
              DropdownMenuItem(value: 1, child: Text('Monday')),
              DropdownMenuItem(value: 2, child: Text('Tuesday')),
              DropdownMenuItem(value: 3, child: Text('Wednesday')),
              DropdownMenuItem(value: 4, child: Text('Thursday')),
              DropdownMenuItem(value: 5, child: Text('Friday')),
              DropdownMenuItem(value: 6, child: Text('Saturday')),
              DropdownMenuItem(value: 7, child: Text('Sunday')),
            ],
            onChanged: (v) => setState(() => _weekday = v ?? 1),
          ),
          const SizedBox(height: 16),
        ],

        if (_freq == AppConstants.freqMonthly) ...[
          Text('Day of month', style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: _dayOfMonth,
            decoration: const InputDecoration(),
            items: List.generate(28, (i) =>
                DropdownMenuItem(value: i + 1, child: Text('${i + 1}'))),
            onChanged: (v) => setState(() => _dayOfMonth = v ?? 1),
          ),
          const SizedBox(height: 16),
        ],

        Text('Time', style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickTime,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withAlpha(80),
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(Icons.access_time_rounded, size: 20, color: cs.primary),
              const SizedBox(width: 10),
              Text(_time.format(context), style: tt.bodyLarge),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ]),
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(width: double.infinity, height: 52,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5))
                : const Text('Save Reminder'),
          ),
        ),
      ]),
    );
  }
}
