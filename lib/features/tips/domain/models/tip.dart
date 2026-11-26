import 'package:cloud_firestore/cloud_firestore.dart';

/// A saving tip posted by an admin, stored in tips/{tipId}.
class Tip {
  final String id;
  final String message;
  final DateTime createdAt;
  final String createdBy; // admin uid

  const Tip({
    required this.id,
    required this.message,
    required this.createdAt,
    required this.createdBy,
  });

  factory Tip.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Tip(
      id: doc.id,
      message: data['message'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  Tip copyWith({String? message}) {
    return Tip(
      id: id,
      message: message ?? this.message,
      createdAt: createdAt,
      createdBy: createdBy,
    );
  }
}
