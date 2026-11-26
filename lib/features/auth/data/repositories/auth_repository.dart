// This file is kept for the AuthRepository interface only.
// All Firebase operations are handled by AuthController (GetX).
// The abstract interface is used by unit tests via FakeAuthRepository.

import 'package:savesmart/features/auth/domain/models/app_user.dart';

abstract class AuthRepository {
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  });

  Future<AppUser> login({
    required String email,
    required String password,
  });

  Future<void> logout();

  Future<void> sendPasswordReset(String email);

  Future<void> updateProfile({
    required String uid,
    String? name,
    String? currency,
    String? language,
  });
}
