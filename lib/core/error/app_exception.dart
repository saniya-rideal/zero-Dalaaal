/// Base exception class for all domain and repository errors in Zero.
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

class OrderException extends AppException {
  const OrderException(super.message, {super.code});
}

class InsufficientFundsException extends AppException {
  const InsufficientFundsException(super.message, {super.code});
}

class MarketClosedException extends AppException {
  const MarketClosedException(super.message, {super.code});
}
