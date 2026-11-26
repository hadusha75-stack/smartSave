import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import 'package:savesmart/core/constants/app_constants.dart';
import 'package:savesmart/core/errors/app_error.dart';

class FeedbackRepository {
  final FirebaseFirestore _db;
  final String uid;

  FeedbackRepository({required FirebaseFirestore firestore, required this.uid})
      : _db = firestore;

  Future<void> submitFeedback(String message) async {
    if (uid.isEmpty) throw const AppError(message: 'Not logged in.');
    if (message.trim().isEmpty) {
      throw const AppError(message: 'Message cannot be empty.');
    }
    try {
      final id = const Uuid().v4();
      await _db.collection(AppConstants.feedbackCollection).doc(id).set({
        'userId': uid,
        'message': message.trim(),
        'status': AppConstants.feedbackStatusOpen,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw AppError.from(e);
    }
  }
}
