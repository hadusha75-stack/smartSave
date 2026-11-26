import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import 'package:savesmart/core/constants/app_constants.dart';
import 'package:savesmart/core/errors/app_error.dart';
import 'package:savesmart/features/goals/domain/models/goal.dart';

/// GetX controller for goals CRUD + streams.
class GoalController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Reactive state ──────────────────────────────────────────────────────────

  /// All non-archived goals for the current user, newest first.
  final RxList<Goal> goals = <Goal>[].obs;

  /// The currently-viewed goal (for detail screen).
  final Rxn<Goal> activeGoal = Rxn<Goal>();

  /// True while a create/update/delete is in progress.
  final RxBool isLoading = false.obs;

  final RxnString errorMessage = RxnString();

  // ── Internal ──────────────────────────────────────────────────────────────────

  String _uid = ''; // empty until setUid() is called
  StreamSubscription? _goalsSub;
  StreamSubscription? _goalDetailSub;

  void setUid(String uid) {
    if (uid.isEmpty) return;
    if (_uid == uid) return; // already subscribed for this user
    _uid = uid;
    subscribeToGoals();
  }

  // ── Streams ──────────────────────────────────────────────────────────────────

  void subscribeToGoals() {
    _goalsSub?.cancel();
    // Use simple orderBy without whereNotIn to avoid needing a composite index.
    // Filter archived goals client-side.
    _goalsSub = _goalsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      goals.value = snap.docs
          .map((d) => Goal.fromFirestore(d))
          .where((g) => g.status != AppConstants.goalStatusArchived)
          .toList();
    }, onError: (e) {
      // Log but don't crash — stream will retry
      goals.value = [];
    });
  }

  void subscribeToGoal(String goalId) {
    _goalDetailSub?.cancel();
    _goalDetailSub = _goalsRef.doc(goalId).snapshots().listen((snap) {
      activeGoal.value = snap.exists ? Goal.fromFirestore(snap) : null;
    });
  }

  CollectionReference<Map<String, dynamic>> get _goalsRef => _db
      .collection(AppConstants.usersCollection)
      .doc(_uid)
      .collection(AppConstants.goalsCollection);

  // ── CRUD ──────────────────────────────────────────────────────────────────────

  Future<String> createGoal({
    required String title,
    required String category,
    required double targetAmount,
    required double currentAmount,
    required DateTime deadline,
    String? colorHex,
    String? iconName,
  }) async {
    // Always get UID fresh from Firebase Auth — never rely on _uid being set
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) throw const AppError(message: 'Not logged in.');
    // Also update _uid for future stream operations
    if (_uid.isEmpty || _uid != uid) { _uid = uid; subscribeToGoals(); }

    isLoading.value = true;
    errorMessage.value = null;
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
      errorMessage.value = AppError.from(e).message;
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateGoal({
    required String goalId,
    String? title,
    String? category,
    double? targetAmount,
    DateTime? deadline,
    String? colorHex,
    String? iconName,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title.trim();
    if (category != null) updates['category'] = category;
    if (targetAmount != null) updates['targetAmount'] = targetAmount;
    if (deadline != null) updates['deadline'] = Timestamp.fromDate(deadline);
    if (colorHex != null) updates['colorHex'] = colorHex;
    if (iconName != null) updates['iconName'] = iconName;
    if (updates.isEmpty) return;
    await _goalsRef.doc(goalId).update(updates);
  }

  Future<void> archiveGoal(String goalId) async {
    await _goalsRef
        .doc(goalId)
        .update({'status': AppConstants.goalStatusArchived});
  }

  Future<void> deleteGoal(String goalId) async {
    final batch = _db.batch();

    final txSnap = await _goalsRef
        .doc(goalId)
        .collection(AppConstants.transactionsCollection)
        .get();
    for (final doc in txSnap.docs) {
      batch.delete(doc.reference);
    }

    final remSnap = await _goalsRef
        .doc(goalId)
        .collection(AppConstants.remindersCollection)
        .get();
    for (final doc in remSnap.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_goalsRef.doc(goalId));
    await batch.commit();
  }

  Future<Goal?> fetchGoal(String goalId) async {
    final snap = await _goalsRef.doc(goalId).get();
    if (!snap.exists) return null;
    return Goal.fromFirestore(snap);
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────────

  @override
  void onClose() {
    _goalsSub?.cancel();
    _goalDetailSub?.cancel();
    super.onClose();
  }
}
