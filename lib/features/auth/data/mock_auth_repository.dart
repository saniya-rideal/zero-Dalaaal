import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/error/app_exception.dart';
import '../../../data/models/models.dart';
import '../domain/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  final FlutterSecureStorage _storage;
  static const _sessionKey = 'zd_auth_session';
  static const _pinKey = 'zd_app_pin';

  MockAuthRepository([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<Session> login(String userId, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));

    if (userId.trim().toUpperCase() != AppConstants.demoUserId && userId.trim().length < 4) {
      throw const AuthException('Invalid User ID. Please check your credentials.', code: 'INVALID_USER_ID');
    }

    if (password.length < 6) {
      throw const AuthException('Password must be at least 6 characters.', code: 'INVALID_PASSWORD');
    }

    // Returns temporary session pending 2FA
    return Session(
      token: 'temp_token_${DateTime.now().millisecondsSinceEpoch}',
      profile: const UserProfile(
        userId: AppConstants.demoUserId,
        name: AppConstants.demoUserName,
        email: AppConstants.demoEmail,
        phone: '+91 98765 43210',
        pan: AppConstants.demoPan,
        bankName: 'HDFC Bank Ltd',
        bankAccountNumber: '•••• •••• 4912',
      ),
      loggedInAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );
  }

  @override
  Future<Session> verifyTotp(String code) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (code.length != 6) {
      throw const AuthException('Invalid 6-digit TOTP / PIN code.');
    }

    final session = Session(
      token: 'auth_token_${DateTime.now().millisecondsSinceEpoch}',
      profile: const UserProfile(
        userId: AppConstants.demoUserId,
        name: AppConstants.demoUserName,
        email: AppConstants.demoEmail,
        phone: '+91 98765 43210',
        pan: AppConstants.demoPan,
        bankName: 'HDFC Bank Ltd',
        bankAccountNumber: '•••• •••• 4912',
      ),
      loggedInAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );

    // Save session and default pin
    try {
      await _storage.write(key: _sessionKey, value: jsonEncode(session.toJson()));
      await _storage.write(key: _pinKey, value: code);
    } catch (_) {}

    return session;
  }

  @override
  Future<bool> verifyPin(String pin) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      final savedPin = await _storage.read(key: _pinKey) ?? AppConstants.defaultPin;
      return pin == savedPin || pin == AppConstants.defaultPin;
    } catch (_) {
      return pin == AppConstants.defaultPin;
    }
  }

  @override
  Future<void> setPin(String pin) async {
    try {
      await _storage.write(key: _pinKey, value: pin);
    } catch (_) {}
  }

  @override
  Future<bool> hasSavedSession() async {
    try {
      final data = await _storage.read(key: _sessionKey);
      return data != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Session?> getSavedSession() async {
    try {
      final data = await _storage.read(key: _sessionKey);
      if (data == null) return null;
      return Session.fromJson(jsonDecode(data) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _storage.delete(key: _sessionKey);
    } catch (_) {}
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});
