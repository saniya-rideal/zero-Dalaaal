import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/models/models.dart';

class TokenStorage {
  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'zd_access_token';
  static const _refreshTokenKey = 'zd_refresh_token';
  static const _sessionKey = 'zd_auth_session';

  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    try {
      await _storage.write(key: _accessTokenKey, value: accessToken);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _storage.write(key: _refreshTokenKey, value: refreshToken);
      }
    } catch (_) {}
  }

  Future<void> clearTokens() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
    } catch (_) {}
  }

  Future<void> saveSession(Session session, {String? refreshToken}) async {
    try {
      await _storage.write(key: _sessionKey, value: jsonEncode(session.toJson()));
      await saveTokens(
        accessToken: session.token,
        refreshToken: refreshToken,
      );
    } catch (_) {}
  }

  Future<Session?> getSession() async {
    try {
      final data = await _storage.read(key: _sessionKey);
      if (data == null) return null;
      return Session.fromJson(jsonDecode(data) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSession() async {
    try {
      await _storage.delete(key: _sessionKey);
      await clearTokens();
    } catch (_) {}
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});
