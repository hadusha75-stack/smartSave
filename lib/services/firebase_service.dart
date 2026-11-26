import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Central accessor for Firebase singletons.
///
/// By going through this class rather than calling FirebaseAuth.instance
/// directly everywhere, we can swap implementations in tests and keep
/// imports tidy.
class FirebaseService {
  FirebaseService._();

  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseMessaging get messaging => FirebaseMessaging.instance;

  /// Enable Firestore offline persistence.
  /// Call this once, before any Firestore reads/writes.
  static Future<void> enableOfflinePersistence() async {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }
}
