/// Unified error type used throughout the app.
/// Wraps Firebase and other errors into a friendly message.
class AppError implements Exception {
  final String message;
  final String? code;
  final Object? originalError;

  const AppError({
    required this.message,
    this.code,
    this.originalError,
  });

  /// Creates an AppError from a Firebase or generic exception.
  factory AppError.from(Object error) {
    // firebase_auth errors
    final msg = error.toString();
    if (msg.contains('user-not-found') || msg.contains('wrong-password')) {
      return const AppError(
        message: 'Invalid email or password.',
        code: 'auth/invalid-credentials',
      );
    }
    if (msg.contains('email-already-in-use')) {
      return const AppError(
        message: 'An account with this email already exists.',
        code: 'auth/email-in-use',
      );
    }
    if (msg.contains('weak-password')) {
      return const AppError(
        message: 'Password must be at least 6 characters.',
        code: 'auth/weak-password',
      );
    }
    if (msg.contains('network-request-failed')) {
      return const AppError(
        message: 'No internet connection. Changes will sync when you reconnect.',
        code: 'network/offline',
      );
    }
    if (msg.contains('permission-denied')) {
      return const AppError(
        message: 'You do not have permission to do this.',
        code: 'firestore/permission-denied',
      );
    }
    if (msg.contains('suspended')) {
      return const AppError(
        message: 'Your account has been suspended. Contact support.',
        code: 'user/suspended',
      );
    }
    return AppError(
      message: 'Something went wrong. Please try again.',
      originalError: error,
    );
  }

  @override
  String toString() => 'AppError($code): $message';
}
