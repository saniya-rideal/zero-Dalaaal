import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import '../error/app_exception.dart';
import 'api_paths.dart';
import 'token_storage.dart';

/// Stream controller for global logout / session expiration events
final authExpirationEventProvider = StreamProvider<void>((ref) {
  return ApiClient.authExpirationStream;
});

class ApiClient {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  final AppConfig _config;
  final Uuid _uuid = const Uuid();

  static final StreamController<void> _authExpirationController =
      StreamController<void>.broadcast();
  static Stream<void> get authExpirationStream => _authExpirationController.stream;

  Completer<String?>? _refreshCompleter;

  ApiClient({
    required AppConfig config,
    required TokenStorage tokenStorage,
    Dio? dio,
  })  : _config = config,
        _tokenStorage = tokenStorage,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: config.apiBaseUrl,
                connectTimeout: config.connectTimeout,
                receiveTimeout: config.receiveTimeout,
                sendTimeout: config.sendTimeout,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final method = options.method.toUpperCase();
          final isMutating = method == 'POST' || method == 'PUT' || method == 'DELETE';
          final path = options.path.toLowerCase();

          // Financial and order mutation routes requiring Idempotency-Key
          final isIdempotentOperation = path.contains('order') ||
              path.contains('deposit') ||
              path.contains('withdraw') ||
              path.contains('wallet') ||
              path.contains('basket') ||
              path.contains('gtt') ||
              path.contains('sip') ||
              path.contains('ipo');

          if (isMutating && isIdempotentOperation && !options.headers.containsKey('Idempotency-Key')) {
            options.headers['Idempotency-Key'] = _uuid.v4();
          }

          // Attach JWT Bearer Access Token if present
          final token = await _tokenStorage.getAccessToken();
          if (token != null && token.isNotEmpty && !options.headers.containsKey('Authorization')) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          final statusCode = error.response?.statusCode;
          final path = error.requestOptions.path;

          // Exclude public/auth routes from token refresh attempts
          final isExemptFromRefresh = path.contains(ApiPaths.authLogin) ||
              path.contains(ApiPaths.authVerifyPin) ||
              path.contains(ApiPaths.authSetupPin) ||
              path.contains(ApiPaths.authRegister) ||
              path.contains(ApiPaths.authForgotPassword) ||
              path.contains(ApiPaths.authVerifyOtp) ||
              path.contains(ApiPaths.authResetPassword) ||
              path.contains(ApiPaths.authRefreshToken);

          final isRetry = error.requestOptions.extra['isRetry'] == true;

          // Check if error is an expired session (401)
          final dynamic data = error.response?.data;
          String? errorCode;
          if (data is Map<String, dynamic>) {
            errorCode = data['errorCode']?.toString();
          }

          final isUnauthorizedSession = statusCode == 401 &&
              errorCode != 'INVALID_CREDENTIALS' &&
              errorCode != 'INVALID_PIN' &&
              errorCode != 'INVALID_TEMP_TOKEN' &&
              errorCode != 'ACCOUNT_LOCKED';

          if (isUnauthorizedSession && !isExemptFromRefresh && !isRetry) {
            final newAccessToken = await _performTokenRefresh();
            if (newAccessToken != null) {
              final retryOptions = error.requestOptions;
              retryOptions.extra['isRetry'] = true;
              retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

              try {
                final retryResponse = await _dio.fetch(retryOptions);
                return handler.resolve(retryResponse);
              } catch (retryError) {
                if (retryError is DioException) {
                  return handler.next(retryError);
                }
              }
            } else {
              // Forced logout on refresh failure
              _authExpirationController.add(null);
              await _tokenStorage.clearSession();
            }
          }

          return handler.next(error);
        },
      ),
    );

    // Comprehensive Debug Console Logger Interceptor (Requests, Payloads, Responses, Errors)
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('┌──────────────────────────────────────────────────────────');
          debugPrint('│ 🌐 [HTTP REQUEST] ${options.method} ${options.uri}');
          if (options.headers.isNotEmpty) {
            final sanitizedHeaders = Map<String, dynamic>.from(options.headers);
            debugPrint('│ 📋 Headers: $sanitizedHeaders');
          }
          if (options.queryParameters.isNotEmpty) {
            debugPrint('│ 🔍 QueryParams: ${options.queryParameters}');
          }
          if (options.data != null) {
            debugPrint('│ 📦 Payload: ${options.data}');
          }
          debugPrint('└──────────────────────────────────────────────────────────');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('┌──────────────────────────────────────────────────────────');
          debugPrint('│ ✅ [HTTP RESPONSE ${response.statusCode}] ${response.requestOptions.method} ${response.requestOptions.uri}');
          debugPrint('│ 📥 Response Body: ${response.data}');
          debugPrint('└──────────────────────────────────────────────────────────');
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          debugPrint('┌──────────────────────────────────────────────────────────');
          debugPrint('│ ❌ [HTTP ERROR ${error.response?.statusCode ?? 'NO_STATUS'}] ${error.requestOptions.method} ${error.requestOptions.uri}');
          debugPrint('│ ⚠️ Error Type: ${error.type}');
          debugPrint('│ ⚠️ Error Message: ${error.message}');
          if (error.response?.data != null) {
            debugPrint('│ 📥 Error Response Body: ${error.response?.data}');
          }
          debugPrint('└──────────────────────────────────────────────────────────');
          return handler.next(error);
        },
      ),
    );
  }

  /// Single in-flight token refresh mutex using POST /api/auth/refresh-token
  Future<String?> _performTokenRefresh() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();

    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshCompleter!.complete(null);
        return null;
      }

      final cleanDio = Dio(
        BaseOptions(
          baseUrl: _config.apiBaseUrl,
          connectTimeout: _config.connectTimeout,
          receiveTimeout: _config.receiveTimeout,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final response = await cleanDio.post(
        ApiPaths.authRefreshToken,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = response.data;
        if (resData is Map<String, dynamic>) {
          final data = resData['data'] is Map<String, dynamic>
              ? resData['data'] as Map<String, dynamic>
              : resData;
          final String newAccessToken =
              (data['accessToken'] ?? data['token'] ?? '').toString();
          final String newRefreshToken =
              (data['refreshToken'] ?? refreshToken).toString();

          if (newAccessToken.isNotEmpty) {
            await _tokenStorage.saveTokens(
              accessToken: newAccessToken,
              refreshToken: newRefreshToken,
            );
            _refreshCompleter!.complete(newAccessToken);
            return newAccessToken;
          }
        }
      }

      _refreshCompleter!.complete(null);
      return null;
    } catch (_) {
      _refreshCompleter!.complete(null);
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }

  /// Public token refresh accessor for external services (like SocketService) needing session refresh
  Future<String?> refreshToken() => _performTokenRefresh();

  // --- HTTP Methods Unwrapping Backend Envelope with Safe GET Retries ---

  /// Safe GET request with automatic exponential backoff retry on transient 5xx or network drops.
  /// Retries are strictly limited to idempotent, safe GET requests.
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    int maxRetries = 2,
  }) async {
    int attempts = 0;
    while (true) {
      attempts++;
      try {
        final response = await _dio.get(
          path,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
        );
        return _unwrapEnvelope(response.data);
      } on DioException catch (e) {
        final isTransient = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError ||
            (e.response != null && e.response!.statusCode! >= 500 && e.response!.statusCode! <= 504);

        if (isTransient && attempts <= maxRetries) {
          // Exponential backoff: 300ms, 600ms
          await Future.delayed(Duration(milliseconds: 300 * attempts));
          continue;
        }
        throw _mapDioException(e);
      } catch (e) {
        if (e is AppException) rethrow;
        throw NetworkException(e.toString());
      }
    }
  }

  /// POST mutation. Never retried automatically to prevent duplicate executions.
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return _unwrapEnvelope(response.data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(e.toString());
    }
  }

  /// PUT mutation. Never retried automatically.
  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return _unwrapEnvelope(response.data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(e.toString());
    }
  }

  /// PATCH mutation. Never retried automatically.
  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return _unwrapEnvelope(response.data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(e.toString());
    }
  }

  /// DELETE mutation. Never retried automatically.
  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return _unwrapEnvelope(response.data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(e.toString());
    }
  }

  /// Unwraps backend standard envelope `{ success: true, message: "...", data: ... }`
  dynamic _unwrapEnvelope(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      if (responseData.containsKey('success') && responseData['success'] == false) {
        throw _mapErrorMap(responseData);
      }
      if (responseData.containsKey('data')) {
        return responseData['data'];
      }
    }
    return responseData;
  }

  /// Maps Dio exceptions & backend error envelopes to typed AppExceptions using errorCode first
  AppException _mapDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkException(
        'Unable to connect to trading server. Please check your network or server address.',
        code: 'NETWORK_TIMEOUT',
      );
    }

    final response = e.response;
    if (response == null) {
      return NetworkException(
        e.message ?? 'Unknown network error occurred.',
        code: 'NETWORK_ERROR',
      );
    }

    final statusCode = response.statusCode ?? 500;
    int? retryAfterSeconds;
    final retryHeader = response.headers.value('retry-after');
    if (retryHeader != null) {
      retryAfterSeconds = int.tryParse(retryHeader);
    }

    if (response.data is Map<String, dynamic>) {
      return _mapErrorMap(
        response.data as Map<String, dynamic>,
        statusCode: statusCode,
        retryAfter: retryAfterSeconds,
      );
    } else if (response.data is String && (response.data as String).isNotEmpty) {
      if (statusCode == 429) {
        return RateLimitedException(
          'Too many requests. Please slow down.',
          retryAfterSeconds: retryAfterSeconds,
        );
      }
      return NetworkException(response.data as String, code: 'HTTP_$statusCode');
    }

    if (statusCode == 429) {
      return RateLimitedException(
        'Too many requests. Please slow down.',
        retryAfterSeconds: retryAfterSeconds,
      );
    }

    return NetworkException('Server error occurred ($statusCode)', code: 'HTTP_$statusCode');
  }

  /// Map JSON error payload to typed AppException
  AppException _mapErrorMap(
    Map<String, dynamic> data, {
    int? statusCode,
    int? retryAfter,
  }) {
    final errorCode = (data['errorCode'] ?? data['code'] ?? '').toString().toUpperCase();
    final message = data['message']?.toString() ?? 'An error occurred';
    final errorsList = data['errors'] is List
        ? (data['errors'] as List).map((e) {
            if (e is Map) {
              final field = (e['field'] ?? e['path'] ?? '').toString();
              final msg = (e['message'] ?? e['msg'] ?? '').toString();
              return field.isNotEmpty ? '$field: $msg' : msg;
            }
            return e.toString();
          }).toList()
        : <String>[];

    // 1. Check specific error codes
    switch (errorCode) {
      case 'INVALID_CREDENTIALS':
        return AuthException(message, code: 'INVALID_CREDENTIALS');
      case 'INVALID_PIN':
        return PinException(message, code: 'INVALID_PIN');
      case 'INVALID_TEMP_TOKEN':
        return PinException(message, code: 'INVALID_TEMP_TOKEN');
      case 'ACCOUNT_LOCKED':
        return AccountLockedException(message, code: 'ACCOUNT_LOCKED');
      case 'RATE_LIMITED':
        return RateLimitedException(message, code: 'RATE_LIMITED', retryAfterSeconds: retryAfter);
      case 'VALIDATION_ERROR':
        return ValidationException(message, code: 'VALIDATION_ERROR', errors: errorsList);
      case 'INVALID_OTP':
        return OtpException(message, code: 'INVALID_OTP');
      case 'OTP_MAX_ATTEMPTS':
        return OtpException(message, code: 'OTP_MAX_ATTEMPTS');
      case 'USER_EXISTS':
        return UserExistsException(message, code: 'USER_EXISTS');
      case 'USER_INACTIVE':
        return UserInactiveException(message, code: 'USER_INACTIVE');
      case 'INSUFFICIENT_MARGIN':
      case 'INSUFFICIENT_FUNDS':
        return InsufficientFundsException(message, code: errorCode);
      case 'MARKET_CLOSED':
        return MarketClosedException(message, code: 'MARKET_CLOSED');
      case 'IDEMPOTENCY_CONFLICT':
      case 'IDEMPOTENCY_KEY_REUSED':
        return IdempotencyException(message, code: 'IDEMPOTENCY_CONFLICT');
      case 'TRANSACTIONS_UNAVAILABLE':
      case 'MAINTENANCE_MODE':
        return ServiceUnavailableException(message, code: errorCode);
      case 'NOT_FOUND':
      case 'ACCOUNT_NOT_FOUND':
        return NotFoundException(message, code: errorCode);
      case 'FORBIDDEN':
        return ForbiddenException(message, code: 'FORBIDDEN');
      case 'ORDER_NOT_FOUND':
      case 'POSITION_NOT_FOUND':
      case 'ALREADY_CLOSED':
        return OrderException(message, code: errorCode);
      case 'UNAUTHORIZED':
        return AuthException(message, code: 'UNAUTHORIZED');
    }

    // 2. Check HTTP status codes
    if (statusCode == 423) {
      return AccountLockedException(message, code: errorCode.isNotEmpty ? errorCode : 'ACCOUNT_LOCKED');
    }
    if (statusCode == 429) {
      return RateLimitedException(
        message,
        code: errorCode.isNotEmpty ? errorCode : 'RATE_LIMITED',
        retryAfterSeconds: retryAfter,
      );
    }
    if (statusCode == 401) {
      return AuthException(message, code: errorCode.isNotEmpty ? errorCode : 'UNAUTHORIZED');
    }
    if (statusCode == 403) {
      return ForbiddenException(message, code: errorCode.isNotEmpty ? errorCode : 'FORBIDDEN');
    }
    if (statusCode == 404) {
      return NotFoundException(message, code: errorCode.isNotEmpty ? errorCode : 'NOT_FOUND');
    }
    if (statusCode == 409) {
      return IdempotencyException(message, code: errorCode.isNotEmpty ? errorCode : 'IDEMPOTENCY_CONFLICT');
    }
    if (statusCode == 400 || statusCode == 422) {
      if (errorsList.isNotEmpty) {
        return ValidationException(message, code: 'VALIDATION_ERROR', errors: errorsList);
      }
      return OrderException(message, code: errorCode.isNotEmpty ? errorCode : 'BAD_REQUEST');
    }

    return NetworkException(message, code: errorCode.isNotEmpty ? errorCode : 'HTTP_${statusCode ?? 500}');
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient(config: config, tokenStorage: tokenStorage);
});
