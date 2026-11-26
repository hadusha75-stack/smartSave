import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:savesmart/core/constants/app_constants.dart';

/// Represents a SaveSmart user document stored in Firestore at users/{uid}.
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String currency; // e.g. 'ETB'
  final String language; // e.g. 'en', 'am', 'ti'
  final String role; // 'user' or 'admin'
  final String status; // 'active' or 'suspended'
  final DateTime createdAt;
  final String? fcmToken; // Firebase Cloud Messaging device token

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.currency,
    required this.language,
    required this.role,
    required this.status,
    required this.createdAt,
    this.fcmToken,
  });

  bool get isAdmin => role == AppConstants.roleAdmin;
  bool get isActive => status == AppConstants.statusActive;
  bool get isSuspended => status == AppConstants.statusSuspended;

  // ── Firestore serialization ───────────────────────────────────────────────

  /// Create an AppUser from a Firestore document snapshot.
  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AppUser(
      uid: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      currency: data['currency'] as String? ?? AppConstants.defaultCurrency,
      language: data['language'] as String? ?? 'en',
      role: data['role'] as String? ?? AppConstants.roleUser,
      status: data['status'] as String? ?? AppConstants.statusActive,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fcmToken: data['fcmToken'] as String?,
    );
  }

  /// Convert to a Map for writing to Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'currency': currency,
      'language': language,
      'role': role,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      if (fcmToken != null) 'fcmToken': fcmToken,
    };
  }

  /// Return a copy of this user with updated fields.
  AppUser copyWith({
    String? name,
    String? email,
    String? currency,
    String? language,
    String? role,
    String? status,
    String? fcmToken,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      currency: currency ?? this.currency,
      language: language ?? this.language,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AppUser && other.uid == uid);

  @override
  int get hashCode => uid.hashCode;
}
