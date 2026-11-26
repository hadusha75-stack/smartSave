import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:savesmart/core/constants/app_constants.dart';

/// User-submitted feedback stored in feedback/{id}.
class UserFeedback {
  final String id;
  final String userId;
  final String message;
  final String status; // 'open' or 'resolved'
  final String? reply; // admin reply
  final DateTime createdAt;

  const UserFeedback({
    required this.id,
    required this.userId,
    required this.message,
    required this.status,
    this.reply,
    required this.createdAt,
  });

  bool get isOpen => status == AppConstants.feedbackStatusOpen;

  factory UserFeedback.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return UserFeedback(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      message: data['message'] as String? ?? '',
      status: data['status'] as String? ?? AppConstants.feedbackStatusOpen,
      reply: data['reply'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'message': message,
      'status': status,
      if (reply != null) 'reply': reply,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserFeedback copyWith({String? status, String? reply}) {
    return UserFeedback(
      id: id,
      userId: userId,
      message: message,
      status: status ?? this.status,
      reply: reply ?? this.reply,
      createdAt: createdAt,
    );
  }
}
