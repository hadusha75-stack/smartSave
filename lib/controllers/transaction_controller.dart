import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import 'package:savesmart/core/constants/app_constants.dart';
import 'package:savesmart/core/errors/app_error.dart';
import 'package:savesmart/core/utils/savings_calculator.dart';
import 'package:savesmart/features/goals/domain/models/goal.dart';
import 'package:savesmart/features/transactions/domain/models/saving_transaction.dart';

/// GetX controller for transactions.
class TransactionController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String _uid = '';

  /// Transactions for the currently-viewed goal.
  final RxList<SavingTransaction> goalTransactions = <SavingTransaction>[].obs;

  /// All transactions across all goals (for history screen).
  final RxList<SavingTransaction> allTransactions = <SavingTransaction>[].obs;

  final RxBool isLoading = false.obs;

  StreamSubscription? _goalTxSub;
  StreamSubscription? _allTxSub;

  void setUid(String uid) {
    _uid = uid;
  }

  // ── Path helpers ────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _txRef(String goalId) => _db
      .collection(AppConstants.usersCollection)
      .doc(_uid)
      .collection(AppConstants.goalsCollection)
      .doc(goalId)
      .collection(AppConstants.transactionsCollection);

  CollectionReference<Map<String, dynamic>> get _goalsRef => _db
      .collection(AppConstants.usersCollection)
      .doc(_uid)
      .collection(AppConstants.goalsCollection);

  // ── Streams ──────────────────────────────────────────────────────────────────

  void subscribeToGoalTransactions(String goalId) {
    _goalTxSub?.cancel();
    _goalTxSub = _txRef(goalId)
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snap) {
      goalTransactions.value =
          snap.docs.map((d) => SavingTransaction.fromFirestore(d)).toList();
    });
  }

  void subscribeToAllTransactions() {
    _allTxSub?.cancel();
    _allTxSub = _db
        .collectionGroup(AppConstants.transactionsCollection)
        .where('goalId', isGreaterThan: '')
        .orderBy('goalId')
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snap) {
      allTransactions.value =
          snap.docs.map((d) => SavingTransaction.fromFirestore(d)).toList();
    });
  }

  // ── Add ──────────────────────────────────────────────────────────────────────

  Future<void> addTransaction({
    required String goalId,
    required double amount,
    required DateTime date,
    required String savedIn,
    String? note,
  }) async {
    if (amount <= 0) {
      throw const AppError(message: 'Amount must be greater than zero.');
    }

    await _db.runTransaction((tx) async {
      // 1. Read the goal
      final goalSnap = await tx.get(_goalsRef.doc(goalId));
      if (!goalSnap.exists) {
        throw const AppError(message: 'Goal not found.');
      }
      final goal = Goal.fromFirestore(goalSnap);

      // 2. Read recent transactions for streak/projection
      final txSnap = await _txRef(goalId)
          .orderBy('date', descending: true)
          .limit(100)
          .get();
      final recentTx = txSnap.docs
          .map((d) => SavingTransaction.fromFirestore(d))
          .toList();

      // 3. Compute new currentAmount
      final newCurrent = goal.currentAmount + amount;

      // 4. Compute streak
      final today = DateTime.now();
      final planned = SavingsCalculator.requiredPerPeriod(
        target: goal.targetAmount,
        current: goal.currentAmount,
        deadline: goal.deadline,
        today: today,
        frequency: AppConstants.freqDaily,
      );
      final metPlan = SavingsCalculator.metPlanThisPeriod(
        frequency: AppConstants.freqDaily,
        plannedAmount: planned,
        today: today,
        transactions: [
          ...recentTx,
          SavingTransaction(
            id: 'new',
            goalId: goalId,
            amount: amount,
            date: date,
            savedIn: savedIn,
            createdAt: today,
          ),
        ],
      );
      final lastSaved = goal.lastSavedAt;
      int newStreak = goal.streak;
      if (metPlan) {
        final alreadySavedToday = lastSaved != null &&
            lastSaved.year == today.year &&
            lastSaved.month == today.month &&
            lastSaved.day == today.day;
        if (!alreadySavedToday) newStreak = goal.streak + 1;
      }

      // 5. Milestones
      final newMilestones = SavingsCalculator.crossedMilestones(
        target: goal.targetAmount,
        current: newCurrent,
      );

      // 6. Status
      final isComplete = newCurrent >= goal.targetAmount;

      // 7. Write transaction document
      final txId = const Uuid().v4();
      final newTx = SavingTransaction(
        id: txId,
        goalId: goalId,
        amount: amount,
        date: date,
        savedIn: savedIn,
        createdAt: today,
        note: note,
      );
      tx.set(_txRef(goalId).doc(txId), newTx.toFirestore());

      // 8. Update goal
      tx.update(_goalsRef.doc(goalId), {
        'currentAmount': newCurrent,
        'streak': newStreak,
        'lastSavedAt': Timestamp.fromDate(today),
        'achievedMilestones': newMilestones,
        'status': isComplete
            ? AppConstants.goalStatusCompleted
            : AppConstants.goalStatusActive,
      });
    });
  }

  // ── Edit ─────────────────────────────────────────────────────────────────────

  Future<void> editTransaction({
    required String goalId,
    required String txId,
    required double newAmount,
    required DateTime newDate,
    required String newSavedIn,
    String? newNote,
  }) async {
    if (newAmount <= 0) {
      throw const AppError(message: 'Amount must be greater than zero.');
    }

    await _db.runTransaction((tx) async {
      final txRef = _txRef(goalId).doc(txId);
      tx.update(txRef, {
        'amount': newAmount,
        'date': Timestamp.fromDate(newDate),
        'savedIn': newSavedIn,
        if (newNote != null && newNote.isNotEmpty) 'note': newNote,
      });

      // Re-sum all transactions
      final allSnap = await _txRef(goalId).get();
      double total = 0;
      for (final d in allSnap.docs) {
        if (d.id == txId) {
          total += newAmount;
        } else {
          total += (d.data()['amount'] as num?)?.toDouble() ?? 0;
        }
      }

      final goalSnap = await tx.get(_goalsRef.doc(goalId));
      final goal = Goal.fromFirestore(goalSnap);

      final isComplete = total >= goal.targetAmount;
      final newMilestones = SavingsCalculator.crossedMilestones(
        target: goal.targetAmount,
        current: total,
      );

      tx.update(_goalsRef.doc(goalId), {
        'currentAmount': total,
        'achievedMilestones': newMilestones,
        'status': isComplete
            ? AppConstants.goalStatusCompleted
            : AppConstants.goalStatusActive,
      });
    });
  }

  // ── Delete ───────────────────────────────────────────────────────────────────

  Future<void> deleteTransaction({
    required String goalId,
    required String txId,
    required double amount,
  }) async {
    await _db.runTransaction((tx) async {
      final txRef = _txRef(goalId).doc(txId);
      final goalRef = _goalsRef.doc(goalId);

      final goalSnap = await tx.get(goalRef);
      final goal = Goal.fromFirestore(goalSnap);

      final newCurrent =
          (goal.currentAmount - amount).clamp(0, double.infinity).toDouble();
      final isComplete = newCurrent >= goal.targetAmount;
      final newMilestones = SavingsCalculator.crossedMilestones(
        target: goal.targetAmount,
        current: newCurrent,
      );

      tx.delete(txRef);
      tx.update(goalRef, {
        'currentAmount': newCurrent,
        'achievedMilestones': newMilestones,
        'status': isComplete
            ? AppConstants.goalStatusCompleted
            : AppConstants.goalStatusActive,
      });
    });
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────────

  @override
  void onClose() {
    _goalTxSub?.cancel();
    _allTxSub?.cancel();
    super.onClose();
  }
}
