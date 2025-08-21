sealed class AppError implements Exception {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;
  const AppError(this.message, {this.cause, this.stackTrace});
  @override
  String toString() => '$runtimeType: $message';
}

class NetworkError extends AppError {
  const NetworkError(super.message, {super.cause, super.stackTrace});
}

class PermissionDeniedError extends AppError {
  const PermissionDeniedError(super.message, {super.cause, super.stackTrace});
}

class NotFoundError extends AppError {
  const NotFoundError(super.message, {super.cause, super.stackTrace});
}

class UnknownAppError extends AppError {
  const UnknownAppError(super.message, {super.cause, super.stackTrace});
}

AppError mapFirebaseException(Object error, StackTrace stackTrace) {
  final message = error.toString();
  final lower = message.toLowerCase();
  if (lower.contains('permission-denied')) {
    return PermissionDeniedError(
      'Permission denied',
      cause: error,
      stackTrace: stackTrace,
    );
  }
  if (lower.contains('not-found') || lower.contains('document not found')) {
    return NotFoundError('Not found', cause: error, stackTrace: stackTrace);
  }
  if (lower.contains('network') || lower.contains('unavailable')) {
    return NetworkError('Network issue', cause: error, stackTrace: stackTrace);
  }
  return UnknownAppError('Unknown error', cause: error, stackTrace: stackTrace);
}
