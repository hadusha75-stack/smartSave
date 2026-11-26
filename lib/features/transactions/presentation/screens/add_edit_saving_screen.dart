import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:savesmart/controllers/auth_controller.dart';
import 'package:savesmart/controllers/transaction_controller.dart';
import 'package:savesmart/core/constants/app_constants.dart';
import 'package:savesmart/core/utils/currency_formatter.dart';

class AddEditSavingScreen extends StatefulWidget {
  final String  goalId;
  final String? transactionId;
  const AddEditSavingScreen({super.key, required this.goalId, this.transactionId});
  @override
  State<AddEditSavingScreen> createState() => _AddEditSavingScreenState();
}

class _AddEditSavingScreenState extends State<AddEditSavingScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl   = TextEditingController();
  final _txCtrl     = Get.find<TransactionController>();
  final _auth       = Get.find<AuthController>();

  DateTime _date   = DateTime.now();
  String   _savedIn = AppConstants.savedInCash;
  bool     _loading = false;
  bool     _loadingExisting = false;

  @override
  void initState() {
    super.initState();
    if (widget.transactionId != null) _prefill();
  }

  Future<void> _prefill() async {
    setState(() => _loadingExisting = true);
    _txCtrl.subscribeToGoalTransactions(widget.goalId);
    // Wait for stream to populate
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    final tx = _txCtrl.goalTransactions
        .firstWhereOrNull((t) => t.id == widget.transactionId);
    if (tx != null && mounted) {
      final cur = _auth.currentUser.value?.currency ?? 'ETB';
      setState(() {
        _amountCtrl.text = CurrencyFormatter.formatPlain(tx.amount, cur);
        _noteCtrl.text   = tx.note ?? '';
        _date    = tx.date;
        _savedIn = tx.savedIn;
        _loadingExisting = false;
      });
    } else {
      setState(() => _loadingExisting = false);
    }
  }

  @override
  void dispose() { _amountCtrl.dispose(); _noteCtrl.dispose(); super.dispose(); }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final amount = CurrencyFormatter.parse(_amountCtrl.text);
    final note   = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
    try {
      if (widget.transactionId == null) {
        await _txCtrl.addTransaction(
            goalId: widget.goalId, amount: amount,
            date: _date, savedIn: _savedIn, note: note);
        Get.back();
        Get.snackbar('Success', 'Saving recorded!');
      } else {
        await _txCtrl.editTransaction(
            goalId: widget.goalId, txId: widget.transactionId!,
            newAmount: amount, newDate: _date,
            newSavedIn: _savedIn, newNote: note);
        Get.back();
        Get.snackbar('Success', 'Saving updated!');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString(),
          // ignore: use_build_context_synchronously
          backgroundColor: Theme.of(context).colorScheme.error,
          // ignore: use_build_context_synchronously
          colorText: Theme.of(context).colorScheme.onError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.transactionId != null;
    if (isEdit && _loadingExisting) {
      return Scaffold(appBar: AppBar(title: const Text('Edit Saving')),
          body: const Center(child: CircularProgressIndicator()));
    }
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Saving' : 'Record Saving'),
        actions: [if (!_loading)
          TextButton(onPressed: _submit, child: const Text('Save'))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(key: _formKey, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Amount
         const _Lbl('Amount (ETB)'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            style: tt.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700, color: cs.primary),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: tt.headlineMedium?.copyWith(color: cs.outlineVariant),
              prefixIcon: const Icon(Icons.savings_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Amount is required.';
              if (CurrencyFormatter.parse(v) <= 0) return 'Enter a positive amount.';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Date
        const  _Lbl('Date'),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickDate,
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
              child: Text(DateFormat('EEEE, d MMMM yyyy').format(_date),
                  style: tt.bodyLarge),
            ),
          ),
          const SizedBox(height: 20),

          // Saved In
        const  _Lbl('Saved In'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8,
            children: AppConstants.savedInOptions.map((opt) => ChoiceChip(
              selected: _savedIn == opt,
              label: Text(opt),
              avatar: Icon(_savedInIcon(opt), size: 16,
                  color: _savedIn == opt
                      ? cs.onSecondaryContainer : cs.onSurfaceVariant),
              onSelected: (_) => setState(() => _savedIn = opt),
            )).toList(),
          ),
          const SizedBox(height: 20),

          // Note
        const  _Lbl('Note (optional)'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _noteCtrl, maxLines: 3, maxLength: 200,
            decoration: const InputDecoration(
              hintText: 'e.g. Monthly salary deposit',
              prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 48),
                  child: Icon(Icons.notes_rounded)),
            ),
          ),
          const SizedBox(height: 28),

          SizedBox(width: double.infinity, height: 52,
            child: FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5))
                  : Text(isEdit ? 'Update Saving' : 'Record Saving'),
            ),
          ),
          const SizedBox(height: 24),
        ])),
      ),
    );
  }

  IconData _savedInIcon(String opt) {
    switch (opt) {
      case AppConstants.savedInBank:   return Icons.account_balance_rounded;
      case AppConstants.savedInWallet: return Icons.phone_android_rounded;
      case AppConstants.savedInCash:   return Icons.home_rounded;
      case AppConstants.savedInGroup:  return Icons.group_rounded;
      default: return Icons.savings_rounded;
    }
  }
}

class _Lbl extends StatelessWidget {
  final String text;
  const _Lbl(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant));
}
