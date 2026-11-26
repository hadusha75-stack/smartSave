import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import 'package:savesmart/core/constants/app_constants.dart';
import 'package:savesmart/core/errors/app_error.dart';

/// GetX controller for user feedback submission.
class FeedbackController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final RxBool isLoading = false.obs;

  Future<void> submitFeedback(String userId, String message) async {
    if (message.trim().isEmpty) {
      throw const AppError(message: 'Message cannot be empty.');
    }
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
