import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_firestore_service.dart';

// ── Firebase singletons ───────────────────────────────────────────────────────

final _authProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final _firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final adminFirestoreServiceProvider =
    Provider<AdminFirestoreService>((ref) {
  return AdminFirestoreService(ref.read(_firestoreProvider));
});

// ── Auth state ────────────────────────────────────────────────────────────────

final authStreamProvider = StreamProvider<User?>((ref) {
  return ref.read(_authProvider).authStateChanges();
});

// ── Admin auth notifier ───────────────────────────────────────────────────────

class _AdminAuthState {
  final bool isLoading;
  final String? errorMessage;
  final bool isAdmin;

  const _AdminAuthState({
    this.isLoading = false,
    this.errorMessage,
    this.isAdmin = false,
  });

  _AdminAuthState copyWith(
      {bool? isLoading, String? errorMessage, bool? isAdmin,
      bool clearError = false}) =>
      _AdminAuthState(
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        isAdmin: isAdmin ?? this.isAdmin,
      );
}

class AdminAuthNotifier extends StateNotifier<_AdminAuthState> {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AdminAuthNotifier(this._auth, this._db)
      : super(const _AdminAuthState());

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      final uid = cred.user!.uid;

      // Verify admin role in Firestore
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists || doc.data()?['role'] != 'admin') {
        await _auth.signOut();
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'You do not have admin access.',
        );
        return false;
      }

      // Check account not suspended
      if (doc.data()?['status'] == 'suspended') {
        await _auth.signOut();
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'This account is suspended.',
        );
        return false;
      }

      state = state.copyWith(isLoading: false, isAdmin: true);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _authMessage(e.code),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    state = const _AdminAuthState();
  }

  String _authMessage(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Login failed. Please try again.';
    }
  }
}

final adminAuthProvider =
    StateNotifierProvider<AdminAuthNotifier, _AdminAuthState>((ref) {
  return AdminAuthNotifier(
    ref.read(_authProvider),
    ref.read(_firestoreProvider),
  );
});
