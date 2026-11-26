// Widget tests for login form validation logic.
// These test the validator functions in isolation — no Firebase or GetX needed.
import 'package:flutter_test/flutter_test.dart';

String? validateEmail(String? v) {
  if (v == null || v.trim().isEmpty) return 'Email is required.';
  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
    return 'Enter a valid email address.';
  }
  return null;
}

String? validatePassword(String? v) {
  if (v == null || v.isEmpty) return 'Password is required.';
  if (v.length < 6) return 'Must be at least 6 characters.';
  return null;
}

String? validateConfirm(String? v, String password) {
  if (v == null || v.isEmpty) return 'Please confirm your password.';
  if (v != password) return 'Passwords do not match.';
  return null;
}

void main() {
  group('Login form validators', () {
    test('empty email returns required error', () {
      expect(validateEmail(''), 'Email is required.');
      expect(validateEmail(null), 'Email is required.');
    });

    test('invalid email format returns format error', () {
      expect(validateEmail('notanemail'), 'Enter a valid email address.');
      expect(validateEmail('missing@'), 'Enter a valid email address.');
    });

    test('valid email returns null', () {
      expect(validateEmail('user@test.com'), isNull);
    });

    test('short password returns length error', () {
      expect(validatePassword('12345'), 'Must be at least 6 characters.');
    });

    test('empty password returns required error', () {
      expect(validatePassword(''), 'Password is required.');
    });

    test('valid password returns null', () {
      expect(validatePassword('password123'), isNull);
    });
  });

  group('Register form validators', () {
    test('mismatched passwords return error', () {
      expect(validateConfirm('different', 'pass123'), 'Passwords do not match.');
    });

    test('matching passwords return null', () {
      expect(validateConfirm('pass123', 'pass123'), isNull);
    });

    test('empty confirm returns required error', () {
      expect(validateConfirm('', 'pass123'), 'Please confirm your password.');
    });
  });
}
