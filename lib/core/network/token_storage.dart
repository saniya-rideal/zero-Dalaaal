import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/models/models.dart';

class TokenStorage {
  final FlutterSecureStorage? _storage;
  final Map<String, String> _memoryStorage = {};

  static const _accessTokenKey = 'zd_access_token';
  static const _refreshTokenKey = 'zd_refresh_token';
  static const _sessionKey = 'zd_auth_session';

  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  TokenStorage.inMemory() : _storage = null;

  Future<String?> getAccessToken() async {
    try {
      if (_storage != null) {
        final val = await _storage.read(key: _accessTokenKey);
        if (val != null) return val;
      }
    } catch (_) {}
    return _memoryStorage[_accessTokenKey];
  }

  Future<String?> getRefreshToken() async {
    try {
      if (_storage != null) {
        final val = await _storage.read(key: _refreshTokenKey);
        if (val != null) return val;
      }
    } catch (_) {}
    return _memoryStorage[_refreshTokenKey];
  }

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    _memoryStorage[_accessTokenKey] = accessToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      _memoryStorage[_refreshTokenKey] = refreshToken;
    }
    try {
      if (_storage != null) {
        await _storage.write(key: _accessTokenKey, value: accessToken);
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await _storage.write(key: _refreshTokenKey, value: refreshToken);
        }
      }
    } catch (_) {}
  }

  Future<void> clearTokens() async {
    _memoryStorage.remove(_accessTokenKey);
    _memoryStorage.remove(_refreshTokenKey);
    try {
      if (_storage != null) {
        await _storage.delete(key: _accessTokenKey);
        await _storage.delete(key: _refreshTokenKey);
      }
    } catch (_) {}
  }

  Future<void> saveSession(Session session, {String? refreshToken}) async {
    final encoded = jsonEncode(session.toJson());
    _memoryStorage[_sessionKey] = encoded;
    try {
      if (_storage != null) {
        await _storage.write(key: _sessionKey, value: encoded);
      }
    } catch (_) {}
    await saveTokens(
      accessToken: session.token,
      refreshToken: refreshToken,
    );
  }

  Future<Session?> getSession() async {
    try {
      if (_storage != null) {
        final data = await _storage.read(key: _sessionKey);
        if (data != null) {
          return Session.fromJson(jsonDecode(data) as Map<String, dynamic>);
        }
      }
    } catch (_) {}
    final mem = _memoryStorage[_sessionKey];
    if (mem != null) {
      try {
        return Session.fromJson(jsonDecode(mem) as Map<String, dynamic>);
      } catch (_) {}
    }
    return null;
  }

  Future<void> clearSession() async {
    _memoryStorage.remove(_sessionKey);
    try {
      if (_storage != null) {
        await _storage.delete(key: _sessionKey);
      }
    } catch (_) {}
    await clearTokens();
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});
