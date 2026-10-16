/// Base exception class for all domain and repository errors in ZeroDalali.
abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => '$runtimeType: $message ${code != null ? '($code)' : ''}';
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

class ForbiddenException extends AppException {
  const ForbiddenException(super.message, {super.code = 'FORBIDDEN'});
}

class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.code = 'NOT_FOUND'});
}

class AccountLockedException extends AppException {
  const AccountLockedException(super.message, {super.code = 'ACCOUNT_LOCKED'});
}

class RateLimitedException extends AppException {
  final int? retryAfterSeconds;

  const RateLimitedException(
    super.message, {
    super.code = 'RATE_LIMITED',
    this.retryAfterSeconds,
  });

  @override
  String toString() =>
      'RateLimitedException: $message${retryAfterSeconds != null ? ' (Retry after ${retryAfterSeconds}s)' : ''}';
}

class ValidationException extends AppException {
  final List<String> errors;
  const ValidationException(
    super.message, {
    super.code = 'VALIDATION_ERROR',
    this.errors = const [],
  });

  @override
  String toString() {
    if (errors.isNotEmpty) {
      return '$message: ${errors.join(', ')}';
    }
    return super.toString();
  }
}

class OtpException extends AppException {
  const OtpException(super.message, {super.code});
}

class PinException extends AppException {
  const PinException(super.message, {super.code});
}

class UserExistsException extends AppException {
  const UserExistsException(super.message, {super.code = 'USER_EXISTS'});
}

class UserInactiveException extends AppException {
  const UserInactiveException(super.message, {super.code = 'USER_INACTIVE'});
}

class OrderException extends AppException {
  const OrderException(super.message, {super.code});
}

class InsufficientFundsException extends AppException {
  const InsufficientFundsException(super.message, {super.code});
}

class MarketClosedException extends AppException {
  const MarketClosedException(super.message, {super.code = 'MARKET_CLOSED'});
}

class IdempotencyException extends AppException {
  const IdempotencyException(super.message, {super.code = 'IDEMPOTENCY_CONFLICT'});
}

class ServiceUnavailableException extends AppException {
  const ServiceUnavailableException(super.message, {super.code = 'SERVICE_UNAVAILABLE'});
}
