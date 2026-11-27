import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import 'package:savesmart/core/constants/app_constants.dart';
import 'package:savesmart/core/errors/app_error.dart';
import 'package:savesmart/core/utils/savings_calculator.dart';
import 'package:savesmart/features/goals/domain/models/goal.dart';
import 'package:savesmart/features/transactions/domain/models/saving_transaction.dart';

class TransactionController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String _uid = '';

  final RxList<SavingTransaction> goalTransactions = <SavingTransaction>[].obs;
  final RxList<SavingTransaction> allTransactions  = <SavingTransaction>[].obs;
  final RxBool isLoading = false.obs;

  StreamSubscription? _goalTxSub;
  StreamSubscription? _allTxSub;

  // Always get fresh UID from Firebase Auth
  String get _currentUid {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isNotEmpty) _uid = uid;
    return _uid;
  }

  void setUid(String uid) { if (uid.isNotEmpty) _uid = uid; }

  // ── Path helpers ────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _txRef(String goalId) => _db
      .collection(AppConstants.usersCollection)
      .doc(_currentUid)
      .collection(AppConstants.goalsCollection)
      .doc(goalId)
      .collection(AppConstants.transactionsCollection);

  CollectionReference<Map<String, dynamic>> get _goalsRef => _db
      .collection(AppConstants.usersCollection)
      .doc(_currentUid)
      .collection(AppConstants.goalsCollection);

  // ── Streams ──────────────────────────────────────────────────────────────────

  void subscribeToGoalTransactions(String goalId) {
    _goalTxSub?.cancel();
    _goalTxSub = _txRef(goalId)
        .orderBy('date', descending: true)
        .snapshots()
        .listen(
          (snap) => goalTransactions.value =
              snap.docs.map((d) => SavingTransaction.fromFirestore(d)).toList(),
          onError: (_) => goalTransactions.value = [],
        );
  }

  void subscribeToAllTransactions() {
    final uid = _currentUid;
    if (uid.isEmpty) return;
    _allTxSub?.cancel();
    // Use per-user path instead of collectionGroup (avoids index requirement)
    _allTxSub = _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.goalsCollection)
        .snapshots()
        .asyncExpand((goalsSnap) async* {
          final List<SavingTransaction> all = [];
          for (final goalDoc in goalsSnap.docs) {
            final txSnap = await _db
                .collection(AppConstants.usersCollection)
                .doc(uid)
                .collection(AppConstants.goalsCollection)
                .doc(goalDoc.id)
                .collection(AppConstants.transactionsCollection)
                .orderBy('date', descending: true)
                .get();
            all.addAll(
                txSnap.docs.map((d) => SavingTransaction.fromFirestore(d)));
          }
          all.sort((a, b) => b.date.compareTo(a.date));
          yield all;
        })
        .listen(
          (txs) => allTransactions.value = txs,
          onError: (_) => allTransactions.value = [],
        );
  }

  // ── Add ──────────────────────────────────────────────────────────────────────

  Future<void> addTransaction({
    required String goalId,
    required double amount,
    required DateTime date,
    required String savedIn,
    String? note,
  }) async {
    final uid = _currentUid;
    if (uid.isEmpty) throw const AppError(message: 'Not logged in.');
    if (amount <= 0) throw const AppError(message: 'Amount must be greater than zero.');

    await _db.runTransaction((tx) async {
      final goalSnap = await tx.get(_goalsRef.doc(goalId));
      if (!goalSnap.exists) throw const AppError(message: 'Goal not found.');
      final goal = Goal.fromFirestore(goalSnap);

      final txSnap = await _txRef(goalId).orderBy('date', descending: true).limit(100).get();
      final recentTx = txSnap.docs.map((d) => SavingTransaction.fromFirestore(d)).toList();

      final newCurrent = goal.currentAmount + amount;
      final today = DateTime.now();
      final planned = SavingsCalculator.requiredPerPeriod(
        target: goal.targetAmount, current: goal.currentAmount,
        deadline: goal.deadline, today: today, frequency: AppConstants.freqDaily,
      );
      final metPlan = SavingsCalculator.metPlanThisPeriod(
        frequency: AppConstants.freqDaily, plannedAmount: planned, today: today,
        transactions: [...recentTx,
          SavingTransaction(id: 'new', goalId: goalId, amount: amount,
              date: date, savedIn: savedIn, createdAt: today)],
      );

      int newStreak = goal.streak;
      if (metPlan) {
        final last = goal.lastSavedAt;
        final sameDay = last != null && last.year == today.year &&
            last.month == today.month && last.day == today.day;
        if (!sameDay) newStreak = goal.streak + 1;
      }

      final newMilestones = SavingsCalculator.crossedMilestones(
          target: goal.targetAmount, current: newCurrent);
      final isComplete = newCurrent >= goal.targetAmount;
      final txId = const Uuid().v4();

      tx.set(_txRef(goalId).doc(txId),
          SavingTransaction(id: txId, goalId: goalId, amount: amount,
              date: date, savedIn: savedIn, createdAt: today, note: note).toFirestore());
      tx.update(_goalsRef.doc(goalId), {
        'currentAmount': newCurrent,
        'streak': newStreak,
        'lastSavedAt': Timestamp.fromDate(today),
        'achievedMilestones': newMilestones,
        'status': isComplete ? AppConstants.goalStatusCompleted : AppConstants.goalStatusActive,
      });
    });
  }

  // ── Edit ─────────────────────────────────────────────────────────────────────

  Future<void> editTransaction({
    required String goalId, required String txId,
    required double newAmount, required DateTime newDate,
    required String newSavedIn, String? newNote,
  }) async {
    if (newAmount <= 0) throw const AppError(message: 'Amount must be greater than zero.');
    await _db.runTransaction((tx) async {
      tx.update(_txRef(goalId).doc(txId), {
        'amount': newAmount, 'date': Timestamp.fromDate(newDate),
        'savedIn': newSavedIn,
        if (newNote != null && newNote.isNotEmpty) 'note': newNote,
      });
      final allSnap = await _txRef(goalId).get();
      double total = 0;
      for (final d in allSnap.docs) {
        total += d.id == txId ? newAmount : (d.data()['amount'] as num?)?.toDouble() ?? 0;
      }
      final goalSnap = await tx.get(_goalsRef.doc(goalId));
      final goal = Goal.fromFirestore(goalSnap);
      tx.update(_goalsRef.doc(goalId), {
        'currentAmount': total,
        'achievedMilestones': SavingsCalculator.crossedMilestones(target: goal.targetAmount, current: total),
        'status': total >= goal.targetAmount ? AppConstants.goalStatusCompleted : AppConstants.goalStatusActive,
      });
    });
  }

  // ── Delete ───────────────────────────────────────────────────────────────────

  Future<void> deleteTransaction({
    required String goalId, required String txId, required double amount,
  }) async {
    await _db.runTransaction((tx) async {
      final goalSnap = await tx.get(_goalsRef.doc(goalId));
      final goal = Goal.fromFirestore(goalSnap);
      final newCurrent = (goal.currentAmount - amount).clamp(0, double.infinity).toDouble();
      tx.delete(_txRef(goalId).doc(txId));
      tx.update(_goalsRef.doc(goalId), {
        'currentAmount': newCurrent,
        'achievedMilestones': SavingsCalculator.crossedMilestones(target: goal.targetAmount, current: newCurrent),
        'status': newCurrent >= goal.targetAmount ? AppConstants.goalStatusCompleted : AppConstants.goalStatusActive,
      });
    });
  }

  @override
  void onClose() {
    _goalTxSub?.cancel();
    _allTxSub?.cancel();
    super.onClose();
  }
}
