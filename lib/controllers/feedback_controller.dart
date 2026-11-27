import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import 'package:savesmart/core/constants/app_constants.dart';
import 'package:savesmart/core/errors/app_error.dart';

class FeedbackController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final RxBool isLoading = false.obs;

  Future<void> submitFeedback(String message) async {
    // Always get UID fresh from Firebase Auth
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) throw const AppError(message: 'Not logged in.');
    if (message.trim().isEmpty) throw const AppError(message: 'Message cannot be empty.');

    isLoading.value = true;
    try {
      final id = const Uuid().v4();
      await _db.collection(AppConstants.feedbackCollection).doc(id).set({
        'userId': userId,
        'message': message.trim(),
        'status': AppConstants.feedbackStatusOpen,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw AppError.from(e);
    } finally {
      isLoading.value = false;
    }
  }
}
