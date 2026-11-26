import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import 'package:savesmart/core/constants/app_constants.dart';
import 'package:savesmart/core/errors/app_error.dart';
import 'package:savesmart/features/goals/domain/models/goal.dart';

// ── Repository ────────────────────────────────────────────────────────────────

class GoalRepository {
  final FirebaseFirestore _firestore;
  final String uid;

  GoalRepository({required FirebaseFirestore firestore, required this.uid})
      : _firestore = firestore;

  // ── Helpers ───────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _goalsRef => _firestore
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .collection(AppConstants.goalsCollection);

  /// Fetch a single goal by id (one-time read, not a stream).
  Future<Goal?> fetchGoal(String goalId) async {
    if (uid.isEmpty) return null;
    final snap = await _goalsRef.doc(goalId).get();
    if (!snap.exists) return null;
    return Goal.fromFirestore(snap);
  }

  // ── Watch ─────────────────────────────────────────────────────────────────

  /// Stream of active + completed goals (not archived), newest first.
  Stream<List<Goal>> watchGoals() {
    if (uid.isEmpty) return Stream.value([]);
    return _goalsRef
        .where('status', whereNotIn: [AppConstants.goalStatusArchived])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Goal.fromFirestore(d))
            .toList());
  }

  /// Stream of a single goal document.
  Stream<Goal?> watchGoal(String goalId) {
    if (uid.isEmpty) return Stream.value(null);
    return _goalsRef.doc(goalId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return Goal.fromFirestore(snap);
    });
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  /// Create a new goal and return its generated id.
  Future<String> createGoal({
    required String title,
    required String category,
    required double targetAmount,
    required double currentAmount,
    required DateTime deadline,
    String? colorHex,
    String? iconName,
  }) async {
    if (uid.isEmpty) throw const AppError(message: 'Not logged in.');
    try {
      final id = const Uuid().v4();
      final goal = Goal(
        id: id,
        userId: uid,
        title: title.trim(),
        category: category,
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        deadline: deadline,
        status: AppConstants.goalStatusActive,
        createdAt: DateTime.now(),
        streak: 0,
        colorHex: colorHex,
        iconName: iconName,
      );
      await _goalsRef.doc(id).set(goal.toFirestore());
      return id;
    } catch (e) {
      throw AppError.from(e);
    }
  }

  /// Update an existing goal's editable fields.
  Future<void> updateGoal({
    required String goalId,
    String? title,
    String? category,
    double? targetAmount,
    DateTime? deadline,
    String? colorHex,
    String? iconName,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title.trim();
      if (category != null) updates['category'] = category;
      if (targetAmount != null) updates['targetAmount'] = targetAmount;
      if (deadline != null) updates['deadline'] = Timestamp.fromDate(deadline);
      if (colorHex != null) updates['colorHex'] = colorHex;
      if (iconName != null) updates['iconName'] = iconName;
      if (updates.isEmpty) return;
      await _goalsRef.doc(goalId).update(updates);
    } catch (e) {
      throw AppError.from(e);
    }
  }

  /// Soft-delete by archiving the goal.
  Future<void> archiveGoal(String goalId) async {
    try {
      await _goalsRef
          .doc(goalId)
          .update({'status': AppConstants.goalStatusArchived});
    } catch (e) {
      throw AppError.from(e);
    }
  }

  /// Hard-delete the goal and all its sub-collections.
  /// Uses a batched write for the goal doc and up to 500 transactions/reminders.
  Future<void> deleteGoal(String goalId) async {
    try {
      final batch = _firestore.batch();

      // Delete all transactions
      final txSnap = await _goalsRef
          .doc(goalId)
          .collection(AppConstants.transactionsCollection)
          .get();
      for (final doc in txSnap.docs) {
        batch.delete(doc.reference);
      }

      // Delete all reminders
      final remSnap = await _goalsRef
          .doc(goalId)
          .collection(AppConstants.remindersCollection)
          .get();
      for (final doc in remSnap.docs) {
        batch.delete(doc.reference);
      }

      // Delete goal document
      batch.delete(_goalsRef.doc(goalId));

      await batch.commit();
    } catch (e) {
      throw AppError.from(e);
    }
  }

  /// Mark goal as completed.
  Future<void> completeGoal(String goalId) async {
    try {
      await _goalsRef.doc(goalId).update({
        'status': AppConstants.goalStatusCompleted,
      });
    } catch (e) {
      throw AppError.from(e);
    }
  }

  /// Update currentAmount, streak, lastSavedAt, achievedMilestones, and
  /// status (completed if currentAmount >= targetAmount) atomically.
  Future<void> updateAfterTransaction({
    required String goalId,
    required double newCurrentAmount,
    required int newStreak,
    required DateTime lastSavedAt,
    required List<int> achievedMilestones,
    required double targetAmount,
  }) async {
    try {
      final isComplete = newCurrentAmount >= targetAmount;
      await _goalsRef.doc(goalId).update({
        'currentAmount': newCurrentAmount,
        'streak': newStreak,
        'lastSavedAt': Timestamp.fromDate(lastSavedAt),
        'achievedMilestones': achievedMilestones,
        'status': isComplete
            ? AppConstants.goalStatusCompleted
            : AppConstants.goalStatusActive,
      });
    } catch (e) {
      throw AppError.from(e);
    }
  }
}
