import 'package:cloud_firestore/cloud_firestore.dart';

/// Centralised Firestore access for the admin dashboard.
/// All admin operations go through this class so we have one place
/// to audit queries and collection names.
class AdminFirestoreService {
  final FirebaseFirestore _db;
  AdminFirestoreService(this._db);

  // ── Users ─────────────────────────────────────────────────────────────────

  /// Stream all user documents (admin role required by security rules).
  Stream<QuerySnapshot<Map<String, dynamic>>> streamUsers() =>
      _db.collection('users').orderBy('createdAt', descending: true).snapshots();

  /// Search users by name prefix (case-insensitive approximation using
  /// Firestore range query on the name field).
  Stream<QuerySnapshot<Map<String, dynamic>>> searchUsers(String query) {
    final end = query.substring(0, query.length - 1) +
        String.fromCharCode(query.codeUnitAt(query.length - 1) + 1);
    return _db
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: end)
        .snapshots();
  }

  /// Suspend a user account.
  Future<void> suspendUser(String uid) =>
      _db.collection('users').doc(uid).update({'status': 'suspended'});

  /// Reactivate a suspended user.
  Future<void> unsuspendUser(String uid) =>
      _db.collection('users').doc(uid).update({'status': 'active'});

  /// Delete a user document (Firebase Auth deletion must be done
  /// server-side via Cloud Functions — UI shows a warning).
  Future<void> deleteUserDoc(String uid) =>
      _db.collection('users').doc(uid).delete();

  /// Return aggregate counts for a user (goal count only;
  /// we never expose individual transactions to the admin).
  Future<Map<String, int>> getUserAggregates(String uid) async {
    final goalsSnap = await _db
        .collection('users')
        .doc(uid)
        .collection('goals')
        .count()
        .get();
    final completedSnap = await _db
        .collection('users')
        .doc(uid)
        .collection('goals')
        .where('status', isEqualTo: 'completed')
        .count()
        .get();
    return {
      'totalGoals': goalsSnap.count ?? 0,
      'completedGoals': completedSnap.count ?? 0,
    };
  }

  // ── Tips ──────────────────────────────────────────────────────────────────

  Stream<QuerySnapshot<Map<String, dynamic>>> streamTips() =>
      _db
          .collection('tips')
          .orderBy('createdAt', descending: true)
          .snapshots();

  Future<void> createTip(
      {required String message, required String adminUid}) =>
      _db.collection('tips').add({
        'message': message.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': adminUid,
      });

  Future<void> updateTip(String tipId, String message) =>
      _db.collection('tips').doc(tipId).update({'message': message.trim()});

  Future<void> deleteTip(String tipId) =>
      _db.collection('tips').doc(tipId).delete();

  // ── Feedback ──────────────────────────────────────────────────────────────

  Stream<QuerySnapshot<Map<String, dynamic>>> streamFeedback() =>
      _db
          .collection('feedback')
          .orderBy('createdAt', descending: true)
          .snapshots();

  Future<void> replyToFeedback(
      {required String feedbackId, required String reply}) =>
      _db.collection('feedback').doc(feedbackId).update({
        'reply': reply.trim(),
        'status': 'resolved',
      });

  Future<void> markResolved(String feedbackId) =>
      _db
          .collection('feedback')
          .doc(feedbackId)
          .update({'status': 'resolved'});

  // ── Categories ────────────────────────────────────────────────────────────

  Stream<QuerySnapshot<Map<String, dynamic>>> streamCategories() =>
      _db.collection('categories').orderBy('name').snapshots();

  Future<void> createCategory(String name) =>
      _db.collection('categories').add({'name': name.trim()});

  Future<void> deleteCategory(String id) =>
      _db.collection('categories').doc(id).delete();

  // ── Statistics ────────────────────────────────────────────────────────────

  /// Returns aggregate stats for the dashboard.
  Future<Map<String, dynamic>> getStats() async {
    final userCount =
        await _db.collection('users').count().get();
    final activeGoals = await _db
        .collectionGroup('goals')
        .where('status', isEqualTo: 'active')
        .count()
        .get();
    final completedGoals = await _db
        .collectionGroup('goals')
        .where('status', isEqualTo: 'completed')
        .count()
        .get();
    final openFeedback = await _db
        .collection('feedback')
        .where('status', isEqualTo: 'open')
        .count()
        .get();

    // Category distribution
    final goalsSnap = await _db
        .collectionGroup('goals')
        .where('status', isEqualTo: 'active')
        .get();
    final Map<String, int> catCounts = {};
    for (final doc in goalsSnap.docs) {
      final cat = doc.data()['category'] as String? ?? 'other';
      catCounts[cat] = (catCounts[cat] ?? 0) + 1;
    }
    final topCategories = catCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'totalUsers': userCount.count ?? 0,
      'activeGoals': activeGoals.count ?? 0,
      'completedGoals': completedGoals.count ?? 0,
      'openFeedback': openFeedback.count ?? 0,
      'topCategories': topCategories.take(5).toList(),
    };
  }
}
