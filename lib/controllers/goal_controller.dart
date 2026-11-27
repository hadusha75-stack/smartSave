import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import 'package:savesmart/core/constants/app_constants.dart';
import 'package:savesmart/core/errors/app_error.dart';
import 'package:savesmart/features/goals/domain/models/goal.dart';

/// GetX controller for goals CRUD + streams.
class GoalController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final RxList<Goal> goals      = <Goal>[].obs;
  final Rxn<Goal>   activeGoal  = Rxn<Goal>();
  final RxBool      isLoading   = false.obs;
  final RxnString   errorMessage = RxnString();

  String _uid = '';
  StreamSubscription? _goalsSub;
  StreamSubscription? _goalDetailSub;

  // ── Get current uid — always fresh from Firebase Auth ─────────────────────

  String get _currentUid {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isNotEmpty && _uid != uid) {
      _uid = uid;
      subscribeToGoals();
    }
    return _uid;
  }

  void setUid(String uid) {
    if (uid.isEmpty || _uid == uid) return;
    _uid = uid;
    subscribeToGoals();
  }

  // ── Firestore path ─────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _goalsRef => _db
      .collection(AppConstants.usersCollection)
      .doc(_currentUid)
      .collection(AppConstants.goalsCollection);

  // ── Streams ────────────────────────────────────────────────────────────────

  void subscribeToGoals() {
    if (_uid.isEmpty) return;
    _goalsSub?.cancel();
    _goalsSub = _db
        .collection(AppConstants.usersCollection)
        .doc(_uid)
        .collection(AppConstants.goalsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snap) {
        goals.value = snap.docs
            .map((d) => Goal.fromFirestore(d))
            .where((g) => g.status != AppConstants.goalStatusArchived)
            .toList();
      },
      onError: (_) => goals.value = [],
    );
  }

  void subscribeToGoal(String goalId) {
    _goalDetailSub?.cancel();
    _goalDetailSub = _goalsRef.doc(goalId).snapshots().listen((snap) {
      activeGoal.value = snap.exists ? Goal.fromFirestore(snap) : null;
    });
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────

  Future<String> createGoal({
    required String title,
    required String category,
    required double targetAmount,
    required double currentAmount,
    required DateTime deadline,
    String? colorHex,
    String? iconName,
  }) async {
    final uid = _currentUid;
    if (uid.isEmpty) throw const AppError(message: 'Not logged in.');

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
    await _goalsRef.doc(goalId).update({'status': AppConstants.goalStatusArchived});
  }

  Future<void> deleteGoal(String goalId) async {
    final batch = _db.batch();
    final txSnap = await _goalsRef
        .doc(goalId).collection(AppConstants.transactionsCollection).get();
    for (final doc in txSnap.docs) batch.delete(doc.reference);
    final remSnap = await _goalsRef
        .doc(goalId).collection(AppConstants.remindersCollection).get();
    for (final doc in remSnap.docs) batch.delete(doc.reference);
    batch.delete(_goalsRef.doc(goalId));
    await batch.commit();
  }

  Future<Goal?> fetchGoal(String goalId) async {
    final snap = await _goalsRef.doc(goalId).get();
    if (!snap.exists) return null;
    return Goal.fromFirestore(snap);
  }

  @override
  void onClose() {
    _goalsSub?.cancel();
    _goalDetailSub?.cancel();
    super.onClose();
  }
}
