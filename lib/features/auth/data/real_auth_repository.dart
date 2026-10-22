import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/token_storage.dart';
import '../../../data/mappers/auth_mapper.dart';
import '../../../data/models/models.dart';
import '../domain/auth_repository.dart';

class RealAuthRepository implements AuthRepository {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  RealAuthRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage;

  @override
  Future<LoginResult> login(String identifier, String password) async {
    // Contract Section 2.2: POST /api/auth/login
    final data = await _apiClient.post(
      ApiPaths.authLogin,
      data: {
        'login': identifier.trim(),
        'identifier': identifier.trim(),
        'email': identifier.trim(),
        'password': password,
      },
    );

    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final bool requiresPin = map['requiresPin'] as bool? ?? false;
    final bool requiresPinSetup = map['requiresPinSetup'] as bool? ?? false;
    final String tempToken = (map['tempToken'] ?? '').toString();

    if (!requiresPin && (map.containsKey('token') || map.containsKey('accessToken') || map.containsKey('user'))) {
      try {
        final session = AuthMapper.sessionFromData(map);
        final refreshToken = map['refreshToken']?.toString();
        await _tokenStorage.saveSession(session, refreshToken: refreshToken);
      } catch (_) {}
    }

    return LoginResult(
      requiresPin: requiresPin,
      requiresPinSetup: requiresPinSetup,
      tempToken: tempToken,
      message: (map['message'] ?? '').toString(),
    );
  }

  @override
  Future<LoginResult> loginWithGoogle(String idToken) async {
    // Contract Phase 4: POST /api/auth/google
    final data = await _apiClient.post(
      ApiPaths.authGoogle,
      data: {
        'idToken': idToken,
        'token': idToken,
      },
    );

    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final bool requiresPin = map['requiresPin'] as bool? ?? false;
    final bool requiresPinSetup = map['requiresPinSetup'] as bool? ?? false;
    final String tempToken = (map['tempToken'] ?? '').toString();

    if (!requiresPin && (map.containsKey('token') || map.containsKey('accessToken') || map.containsKey('user'))) {
      try {
        final session = AuthMapper.sessionFromData(map);
        final refreshToken = map['refreshToken']?.toString();
        await _tokenStorage.saveSession(session, refreshToken: refreshToken);
      } catch (_) {}
    }

    return LoginResult(
      requiresPin: requiresPin,
      requiresPinSetup: requiresPinSetup,
      tempToken: tempToken,
      message: (map['message'] ?? '').toString(),
    );
  }

  @override
  Future<Session> verifyPin({required String tempToken, required String pin}) async {
    // Contract Section 2.3: POST /api/auth/verify-pin
    final data = await _apiClient.post(
      ApiPaths.authVerifyPin,
      data: {
        'tempToken': tempToken,
        'pin': pin,
      },
    );

    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final session = AuthMapper.sessionFromData(map);
    final refreshToken = map['refreshToken']?.toString();

    await _tokenStorage.saveSession(session, refreshToken: refreshToken);
    return session;
  }

  @override
  Future<Session> setPin({required String tempToken, required String pin}) async {
    // Contract Section 2.4: POST /api/auth/setup-pin
    final data = await _apiClient.post(
      ApiPaths.authSetupPin,
      data: {
        'pin': pin,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $tempToken',
        },
      ),
    );

    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final session = AuthMapper.sessionFromData(map);
    final refreshToken = map['refreshToken']?.toString();

    await _tokenStorage.saveSession(session, refreshToken: refreshToken);
    return session;
  }

  @override
  Future<bool> verifyAppPin(String pin) async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) return false;
    try {
      final data = await _apiClient.post(
        ApiPaths.authVerifyPin,
        data: {
          'tempToken': token,
          'pin': pin,
        },
      );
      if (data is Map<String, dynamic>) {
        final session = AuthMapper.sessionFromData(data);
        final refreshToken = data['refreshToken']?.toString();
        await _tokenStorage.saveSession(session, refreshToken: refreshToken);
      }
      return data != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> changePin({required String currentPin, required String newPin}) async {
    final data = await _apiClient.post(
      ApiPaths.authSetupPin,
      data: {'pin': newPin},
    );
    return data != null;
  }

  @override
  Future<void> sendOtp({required String identifier, String type = 'REGISTER'}) async {
    // Contract Phase 4: POST /api/auth/send-otp
    await _apiClient.post(
      ApiPaths.authSendOtp,
      data: {
        'identifier': identifier.trim(),
        'email': identifier.trim(),
        'phone': identifier.trim(),
        'type': type,
      },
    );
  }

  @override
  Future<bool> verifyOtp({required String identifier, required String otp, String type = 'REGISTER'}) async {
    // Contract Phase 4: POST /api/auth/verify-otp
    final res = await _apiClient.post(
      ApiPaths.authVerifyOtp,
      data: {
        'identifier': identifier.trim(),
        'email': identifier.trim(),
        'phone': identifier.trim(),
        'otp': otp.trim(),
        'type': type,
      },
    );
    final map = res is Map<String, dynamic> ? res : <String, dynamic>{};
    return map['verified'] == true || map['success'] == true || res != null;
  }

  @override
  Future<RegisterResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String pin,
  }) async {
    // Contract Section 2.1: POST /api/auth/register
    final data = await _apiClient.post(
      ApiPaths.authRegister,
      data: {
        'name': name.trim(),
        'email': email.trim(),
        'mobile': phone.trim(),
        'phone': phone.trim(),
        'password': password,
        'pin': pin,
      },
    );

    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final session = AuthMapper.sessionFromData(map);
    final refreshToken = map['refreshToken']?.toString();

    await _tokenStorage.saveSession(session, refreshToken: refreshToken);

    final userMap = map['user'] is Map<String, dynamic> ? map['user'] as Map<String, dynamic> : map;
    final clientId = (userMap['clientId'] ?? session.profile.userId).toString();

    return RegisterResult(
      clientId: clientId,
      session: session,
    );
  }

  @override
  Future<void> forgotPassword(String identifier) async {
    // Contract Section 2.6: POST /api/auth/forgot-password
    await _apiClient.post(
      ApiPaths.authForgotPassword,
      data: {
        'email': identifier.trim(),
      },
    );
  }

  @override
  Future<void> resetPassword({
    required String identifier,
    required String otp,
    required String newPassword,
  }) async {
    // Contract Section 2.6: POST /api/auth/verify-otp and reset-password
    final otpRes = await _apiClient.post(
      ApiPaths.authVerifyOtp,
      data: {
        'email': identifier.trim(),
        'otp': otp.trim(),
      },
    );

    final map = otpRes is Map<String, dynamic> ? otpRes : <String, dynamic>{};
    final resetToken = (map['resetToken'] ?? '').toString();

    await _apiClient.post(
      ApiPaths.authResetPassword,
      data: {
        'resetToken': resetToken,
        'password': newPassword,
      },
    );
  }

  @override
  Future<UserProfile> getProfile() async {
    // Contract Section 3.1: GET /api/account/profile
    final data = await _apiClient.get(ApiPaths.profile);
    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final userMap = map['user'] is Map<String, dynamic> ? map['user'] as Map<String, dynamic> : map;
    return AuthMapper.userProfileFromJson(userMap);
  }

  @override
  Future<UserProfile> updateProfile(Map<String, dynamic> changedFields) async {
    // Contract Section 3.2: PUT /api/account/profile
    final data = await _apiClient.put(
      ApiPaths.profile,
      data: changedFields,
    );
    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final userMap = map['user'] is Map<String, dynamic> ? map['user'] as Map<String, dynamic> : map;
    return AuthMapper.userProfileFromJson(userMap);
  }

  @override
  Future<bool> hasSavedSession() async {
    final token = await _tokenStorage.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<Session?> getSavedSession() async {
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null || token.isEmpty) return null;

      final profile = await getProfile();
      final session = Session(
        token: token,
        profile: profile,
        loggedInAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 365)),
      );
      await _tokenStorage.saveSession(session);
      return session;
    } catch (_) {
      await _tokenStorage.clearSession();
      return null;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiPaths.authLogout);
    } catch (_) {}
    await _tokenStorage.clearSession();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return RealAuthRepository(apiClient: apiClient, tokenStorage: tokenStorage);
});
