import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:savesmart/core/constants/app_constants.dart';
import 'package:savesmart/core/errors/app_error.dart';
import 'package:savesmart/features/auth/domain/models/app_user.dart';
import 'package:savesmart/services/notification_service.dart';
import 'package:savesmart/controllers/goal_controller.dart';
import 'package:savesmart/controllers/transaction_controller.dart';
import 'package:savesmart/controllers/reminder_controller.dart';

/// GetX controller for authentication state.
///
/// Replaces the Riverpod [authStateProvider], [currentUserProvider],
/// and [AuthNotifier].
class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Reactive state ──────────────────────────────────────────────────────────

  /// The current Firebase Auth user (null when logged out).
  final Rxn<User> firebaseUser = Rxn<User>();

  /// The current AppUser document from Firestore.
  final Rxn<AppUser> currentUser = Rxn<AppUser>();

  /// True while an auth operation is in progress.
  final RxBool isLoading = false.obs;

  /// Error message (set when an action fails, cleared on success).
  final RxnString errorMessage = RxnString();

  /// True after a successful action (e.g. password reset sent).
  final RxBool success = false.obs;

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    // Listen to Firebase Auth state changes and auto-load the user document.
    _auth.authStateChanges().listen((user) async {
      firebaseUser.value = user;
      if (user != null) {
        await _loadUserDocument(user.uid);
        // Trigger goal/transaction subscriptions as soon as we know the UID
        _notifyControllers(user.uid);
      } else {
        currentUser.value = null;
      }
    });
  }

  /// Tell all data controllers about the logged-in user's UID.
  void _notifyControllers(String uid) {
    try {
      Get.find<GoalController>().setUid(uid);
    } catch (_) {}
    try {
      Get.find<TransactionController>().setUid(uid);
    } catch (_) {}
    try {
      Get.find<ReminderController>().setUid(uid);
    } catch (_) {}
  }

  Future<void> _loadUserDocument(String uid) async {
    try {
      final doc =
          await _firestore.collection(AppConstants.usersCollection).doc(uid).get();
      if (doc.exists) {
        currentUser.value = AppUser.fromFirestore(doc);
      }
    } catch (_) {
      // Silently ignore — user may be offline
    }
  }

  // ── Actions ──────────────────────────────────────────────────────────────────

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;
    success.value = false;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;
      await credential.user!.updateDisplayName(name.trim());

      // FCM token may be null on web without VAPID key — that's fine
      String? fcmToken;
      try { fcmToken = await NotificationService.getFcmToken(); } catch (_) {}

      final user = AppUser(
        uid: uid,
        name: name.trim(),
        email: email.trim(),
        currency: AppConstants.defaultCurrency,
        language: 'en',
        role: AppConstants.roleUser,
        status: AppConstants.statusActive,
        createdAt: DateTime.now(),
        fcmToken: fcmToken,
      );
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set(user.toFirestore());

      currentUser.value = user;
      success.value = true;
      return true;
    } on AppError catch (e) {
      errorMessage.value = e.message;
      return false;
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;
    success.value = false;
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;

      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (!doc.exists) {
        throw const AppError(
          message: 'User account not found. Please register.',
          code: 'user/not-found',
        );
      }

      final user = AppUser.fromFirestore(doc);

      if (user.isSuspended) {
        await _auth.signOut();
        throw const AppError(
          message: 'Your account has been suspended. Contact support.',
          code: 'user/suspended',
        );
      }

      // FCM token may be null on web — handle gracefully
      try {
        final fcmToken = await NotificationService.getFcmToken();
        if (fcmToken != null && fcmToken != user.fcmToken) {
          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(uid)
              .update({'fcmToken': fcmToken});
        }
      } catch (_) {}

      currentUser.value = user;
      success.value = true;
      return true;
    } on AppError catch (e) {
      errorMessage.value = e.message;
      return false;
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    isLoading.value = true;
    try {
      await _auth.signOut();
      currentUser.value = null;
    } on AppError catch (e) {
      errorMessage.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    isLoading.value = true;
    errorMessage.value = null;
    success.value = false;
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      success.value = true;
      return true;
    } on AppError catch (e) {
      errorMessage.value = e.message;
      return false;
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile({
    String? name,
    String? currency,
    String? language,
  }) async {
    final uid = firebaseUser.value?.uid;
    if (uid == null) return;

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name.trim();
    if (currency != null) updates['currency'] = currency;
    if (language != null) updates['language'] = language;
    if (updates.isEmpty) return;

    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update(updates);

      // Update local state
      if (currentUser.value != null) {
        currentUser.value = currentUser.value!.copyWith(
          name: name,
          currency: currency,
          language: language,
        );
      }
    } catch (e) {
      throw AppError.from(e);
    }
  }

  void clearError() => errorMessage.value = null;
}
