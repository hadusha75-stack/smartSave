import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:savesmart/controllers/auth_controller.dart';
import 'package:savesmart/controllers/goal_controller.dart';
import 'package:savesmart/core/constants/goal_categories.dart';
import 'package:savesmart/core/utils/currency_formatter.dart';

class CreateEditGoalScreen extends StatefulWidget {
  final String? goalId;
  const CreateEditGoalScreen({super.key, this.goalId});
  @override
  State<CreateEditGoalScreen> createState() => _CreateEditGoalScreenState();
}

class _CreateEditGoalScreenState extends State<CreateEditGoalScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _titleCtrl   = TextEditingController();
  final _targetCtrl  = TextEditingController();
  final _currentCtrl = TextEditingController();
  final _goals       = Get.find<GoalController>();
  final _auth        = Get.find<AuthController>();

  String   _category   = GoalCategories.defaults.first.id;
  DateTime? _deadline;
  String?  _colorHex;
  bool     _loading    = false;
  bool     _loadingGoal = true;

  @override
  void initState() {
    super.initState();
    if (widget.goalId != null) {
      _prefill();
    } else {
      setState(() => _loadingGoal = false);
    }
  }

  Future<void> _prefill() async {
    final goal = await _goals.fetchGoal(widget.goalId!);
    if (!mounted) return;
    if (goal != null) {
      final cur = _auth.currentUser.value?.currency ?? 'ETB';
      setState(() {
        _titleCtrl.text   = goal.title;
        _targetCtrl.text  = CurrencyFormatter.formatPlain(goal.targetAmount, cur);
        _currentCtrl.text = CurrencyFormatter.formatPlain(goal.currentAmount, cur);
        _category         = goal.category;
        _deadline         = goal.deadline;
        _colorHex         = goal.colorHex;
        _loadingGoal      = false;
      });
    } else {
      setState(() => _loadingGoal = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _targetCtrl.dispose(); _currentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 90)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_deadline == null) { Get.snackbar('Error', 'Please select a deadline.'); return; }
    setState(() => _loading = true);
    final target  = CurrencyFormatter.parse(_targetCtrl.text);
    final current = CurrencyFormatter.parse(_currentCtrl.text);
    try {
      if (widget.goalId == null) {
        await _goals.createGoal(title: _titleCtrl.text, category: _category,
            targetAmount: target, currentAmount: current,
            deadline: _deadline!, colorHex: _colorHex);
        Get.back();
        Get.snackbar('Success', 'Goal created!');
      } else {
        await _goals.updateGoal(goalId: widget.goalId!, title: _titleCtrl.text,
            category: _category, targetAmount: target, deadline: _deadline,
            colorHex: _colorHex);
        Get.back();
        Get.snackbar('Success', 'Goal updated!');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.goalId != null;
    if (isEdit && _loadingGoal) {
      return Scaffold(appBar: AppBar(title: const Text('Edit Goal')),
          body: const Center(child: CircularProgressIndicator()));
    }
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Goal' : 'New Goal'),
        actions: [
          if (!_loading)
            TextButton(onPressed: _submit, child: const Text('Save')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Title
            const _Label('Goal Name'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'e.g. Buy a laptop',
                  prefixIcon: Icon(Icons.flag_outlined)),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Goal name is required.';
                if (v.trim().length > 60) return 'Max 60 characters.';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Category
            const _Label('Category'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8,
              children: GoalCategories.defaults.map((cat) => FilterChip(
                selected: cat.id == _category,
                avatar: Icon(cat.icon, size: 16, color: cat.color),
                label: Text(cat.id.split('_').map((w) =>
                    '${w[0].toUpperCase()}${w.substring(1)}').join(' ')),
                onSelected: (_) => setState(() => _category = cat.id),
                selectedColor: cat.color.withAlpha(40),
                checkmarkColor: cat.color,
              )).toList(),
            ),
            const SizedBox(height: 20),

            // Target
            const _Label('Target Amount (ETB)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _targetCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'e.g. 15000',
                  prefixIcon: Icon(Icons.savings_outlined)),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Target amount is required.';
                if (CurrencyFormatter.parse(v) <= 0) return 'Enter a positive amount.';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Current (create only)
            if (!isEdit) ...[
              const _Label('Already Saved (ETB)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _currentCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: '0',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined)),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (CurrencyFormatter.parse(v) < 0) return 'Cannot be negative.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            // Deadline
            const _Label('Deadline'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDeadline,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withAlpha(80),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                child: Text(
                  _deadline == null ? 'Select a deadline'
                      : DateFormat('d MMMM yyyy').format(_deadline!),
                  style: tt.bodyLarge?.copyWith(
                      color: _deadline == null
                          ? cs.onSurfaceVariant : cs.onSurface),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Color
            const _Label('  Goal Color (optional)'),
            const SizedBox(height: 8),
            _ColorPicker(selected: _colorHex,
                onChanged: (hex) => setState(() => _colorHex = hex)),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity, height: 52,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5))
                    : Text(isEdit ? 'Update Goal' : 'Create Goal'),
              ),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String label;
  const _Label(this.label);
  @override
  Widget build(BuildContext context) => Text(label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant));
}

class _ColorPicker extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;
  const _ColorPicker({required this.selected, required this.onChanged});

  static const _colors = ['2E7D32','1565C0','6A1B9A','E65100','B71C1C','00695C','37474F'];

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      GestureDetector(
        onTap: () => onChanged(null),
        child: Container(
          width: 36, height: 36,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(shape: BoxShape.circle,
            border: Border.all(color: selected == null
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.withAlpha(80),
              width: selected == null ? 2.5 : 1)),
          child: const Icon(Icons.block, size: 18, color: Colors.grey),
        ),
      ),
      ..._colors.map((hex) {
        final color = Color(int.parse('FF$hex', radix: 16));
        final sel   = selected == '#$hex';
        return GestureDetector(
          onTap: () => onChanged('#$hex'),
          child: Container(
            width: 36, height: 36,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle,
              border: Border.all(
                  color: sel ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
                  width: 2.5)),
            child: sel ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
          ),
        );
      }),
    ]);
  }
}
