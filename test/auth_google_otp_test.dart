import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_dalali/core/config/app_config.dart';
import 'package:zero_dalali/core/network/api_client.dart';
import 'package:zero_dalali/core/network/token_storage.dart';
import 'package:zero_dalali/features/auth/data/real_auth_repository.dart';
import 'package:zero_dalali/features/auth/presentation/auth_controller.dart';

class CallRecording {
  String method = '';
  String path = '';
  dynamic data;
  Map<String, dynamic>? queryParameters;
}

Dio _createMockDio(dynamic responseBody, {int statusCode = 200, CallRecording? recording}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (recording != null) {
          recording.method = options.method;
          recording.path = options.path;
          recording.data = options.data;
          recording.queryParameters = options.queryParameters;
        }
        handler.resolve(
          Response(
            requestOptions: options,
            data: responseBody,
            statusCode: statusCode,
          ),
        );
      },
    ),
  );
  return dio;
}

ApiClient _createMockApiClient(dynamic responseBody, {int statusCode = 200, CallRecording? recording}) {
  final mockDio = _createMockDio(responseBody, statusCode: statusCode, recording: recording);
  return ApiClient(
    config: const AppConfig(
      apiBaseUrl: 'http://test',
      socketBaseUrl: 'http://test',
    ),
    tokenStorage: TokenStorage(),
    dio: mockDio,
  );
}

void main() {
  group('RealAuthRepository - Google Sign-In & Registration OTP', () {
    test('loginWithGoogle posts idToken to /api/auth/google and returns LoginResult', () async {
      final recording = CallRecording();
      final apiClient = _createMockApiClient(
        {
          'status': 'success',
          'data': {
            'requiresPin': true,
            'requiresPinSetup': false,
            'tempToken': 'temp_jwt_abc',
            'message': 'PIN required for session access',
          },
        },
        recording: recording,
      );

      final tokenStorage = TokenStorage();
      final repo = RealAuthRepository(apiClient: apiClient, tokenStorage: tokenStorage);

      final result = await repo.loginWithGoogle('google_id_token_xyz');

      expect(recording.method, 'POST');
      expect(recording.path, '/api/auth/google');
      expect(recording.data['idToken'], 'google_id_token_xyz');
      expect(result.requiresPin, isTrue);
      expect(result.requiresPinSetup, isFalse);
      expect(result.tempToken, 'temp_jwt_abc');
    });

    test('sendOtp posts identifier and type to /api/auth/send-otp', () async {
      final recording = CallRecording();
      final apiClient = _createMockApiClient(
        {
          'status': 'success',
          'message': 'OTP sent successfully',
        },
        recording: recording,
      );

      final tokenStorage = TokenStorage();
      final repo = RealAuthRepository(apiClient: apiClient, tokenStorage: tokenStorage);

      await repo.sendOtp(identifier: 'test@example.com', type: 'REGISTER');

      expect(recording.method, 'POST');
      expect(recording.path, '/api/auth/send-otp');
      expect(recording.data['identifier'], 'test@example.com');
      expect(recording.data['type'], 'REGISTER');
    });

    test('verifyOtp posts identifier, otp, and type to /api/auth/verify-otp', () async {
      final recording = CallRecording();
      final apiClient = _createMockApiClient(
        {
          'status': 'success',
          'data': {
            'verified': true,
          },
        },
        recording: recording,
      );

      final tokenStorage = TokenStorage();
      final repo = RealAuthRepository(apiClient: apiClient, tokenStorage: tokenStorage);

      final verified = await repo.verifyOtp(
        identifier: 'test@example.com',
        otp: '123456',
        type: 'REGISTER',
      );

      expect(recording.method, 'POST');
      expect(recording.path, '/api/auth/verify-otp');
      expect(recording.data['identifier'], 'test@example.com');
      expect(recording.data['otp'], '123456');
      expect(recording.data['type'], 'REGISTER');
      expect(verified, isTrue);
    });

    test('AuthController.loginWithGoogle transitions state to require PIN without issuing session', () async {
      final apiClient = _createMockApiClient(
        {
          'status': 'success',
          'data': {
            'requiresPin': true,
            'requiresPinSetup': false,
            'tempToken': 'temp_token_456',
          },
        },
      );

      final tokenStorage = TokenStorage();
      final repo = RealAuthRepository(apiClient: apiClient, tokenStorage: tokenStorage);
      final controller = AuthController(repo);

      final result = await controller.loginWithGoogle('sample_token');

      expect(result, isNotNull);
      expect(controller.state.isAuthenticated, isFalse);
      expect(controller.state.requiresPinUnlock, isTrue);
      expect(controller.state.tempToken, 'temp_token_456');
    });
  });
}
