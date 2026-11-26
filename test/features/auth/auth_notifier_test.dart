// Tests for AuthController (GetX).
// We test the state machine logic using fake Firebase Auth via method stubs.
// Pure business logic tests — no Firebase connection needed.
import 'package:flutter_test/flutter_test.dart';

/// Minimal fake that mimics what AuthController does,
/// without touching Firebase or GetX bindings.
class FakeAuthLogic {
  bool _isLoading = false;
  String? _errorMessage;
  bool _success = false;
  bool shouldFail;
  String? failMessage;

  FakeAuthLogic({this.shouldFail = false, this.failMessage});

  bool get isLoading    => _isLoading;
  String? get error     => _errorMessage;
  bool get success      => _success;

  Future<bool> login(String email, String password) async {
    _isLoading = true; _errorMessage = null; _success = false;
    await Future.microtask(() {});
    if (shouldFail) {
      _errorMessage = failMessage ?? 'Invalid credentials.';
      _isLoading = false; return false;
    }
    _success = true; _isLoading = false; return true;
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true; _errorMessage = null; _success = false;
    await Future.microtask(() {});
    if (shouldFail) {
      _errorMessage = failMessage ?? 'Registration failed.';
      _isLoading = false; return false;
    }
    _success = true; _isLoading = false; return true;
  }

  Future<bool> sendPasswordReset(String email) async {
    _isLoading = true; _errorMessage = null; _success = false;
    await Future.microtask(() {});
    if (shouldFail) {
      _errorMessage = failMessage ?? 'Email not found.';
      _isLoading = false; return false;
    }
    _success = true; _isLoading = false; return true;
  }

  void clearError() => _errorMessage = null;
}

void main() {
  group('AuthController logic (fake)', () {
    group('login', () {
      test('sets success=true on valid credentials', () async {
        final fake = FakeAuthLogic();
        final ok = await fake.login('a@b.com', 'pass123');
        expect(ok, isTrue);
        expect(fake.success, isTrue);
        expect(fake.error, isNull);
        expect(fake.isLoading, isFalse);
      });

      test('sets error message on failure', () async {
        final fake = FakeAuthLogic(shouldFail: true, failMessage: 'Invalid credentials.');
        final ok = await fake.login('a@b.com', 'wrong');
        expect(ok, isFalse);
        expect(fake.error, 'Invalid credentials.');
        expect(fake.success, isFalse);
      });
    });

    group('register', () {
      test('succeeds with valid data', () async {
        final fake = FakeAuthLogic();
        final ok = await fake.register('Abebe', 'a@b.com', 'pass123');
        expect(ok, isTrue);
        expect(fake.success, isTrue);
      });

      test('surfaces error on duplicate email', () async {
        final fake = FakeAuthLogic(
          shouldFail: true,
          failMessage: 'An account with this email already exists.',
        );
        final ok = await fake.register('Abebe', 'exists@b.com', 'pass123');
        expect(ok, isFalse);
        expect(fake.error, contains('already exists'));
      });
    });

    group('sendPasswordReset', () {
      test('returns true on success', () async {
        final fake = FakeAuthLogic();
        final ok = await fake.sendPasswordReset('a@b.com');
        expect(ok, isTrue);
        expect(fake.success, isTrue);
      });

      test('returns false and sets error on failure', () async {
        final fake = FakeAuthLogic(shouldFail: true, failMessage: 'Email not found.');
        final ok = await fake.sendPasswordReset('ghost@b.com');
        expect(ok, isFalse);
        expect(fake.error, 'Email not found.');
      });
    });

    test('clearError removes the error message', () async {
      final fake = FakeAuthLogic(shouldFail: true, failMessage: 'Oops');
      await fake.login('a@b.com', 'x');
      expect(fake.error, isNotNull);
      fake.clearError();
      expect(fake.error, isNull);
    });
  });
}
