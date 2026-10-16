import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum Environment {
  dev,
  staging,
  prod,
}

class AppConfig {
  static const String _envString = String.fromEnvironment('ENV', defaultValue: 'dev');
  static const String _definedBaseUrl = String.fromEnvironment('API_URL', defaultValue: '') != ''
      ? String.fromEnvironment('API_URL')
      : String.fromEnvironment('API_BASE_URL', defaultValue: '');
  static const String _definedSocketUrl = String.fromEnvironment('SOCKET_URL', defaultValue: '') != ''
      ? String.fromEnvironment('SOCKET_URL')
      : String.fromEnvironment('SOCKET_BASE_URL', defaultValue: '');

  static Environment get currentEnvironment {
    switch (_envString.toLowerCase()) {
      case 'prod':
      case 'production':
        return Environment.prod;
      case 'staging':
      case 'stage':
        return Environment.staging;
      default:
        return Environment.dev;
    }
  }

  /// Default production API endpoint (never localhost in release mode)
  static const String _prodApiUrl = 'https://api.zerodalali.com';
  static const String _stagingApiUrl = 'https://staging-api.zerodalali.com';
  static const String _devApiUrl = 'http://localhost:5000';

  static String get defaultBaseUrl {
    if (_definedBaseUrl.isNotEmpty) {
      return _definedBaseUrl;
    }
    if (kReleaseMode) {
      // In production release builds, NEVER allow localhost fallback
      return _prodApiUrl;
    }
    switch (currentEnvironment) {
      case Environment.prod:
        return _prodApiUrl;
      case Environment.staging:
        return _stagingApiUrl;
      case Environment.dev:
        return _devApiUrl;
    }
  }

  static String get defaultSocketUrl {
    if (_definedSocketUrl.isNotEmpty) {
      return _definedSocketUrl;
    }
    return defaultBaseUrl;
  }

  final String apiBaseUrl;
  final String socketBaseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;

  const AppConfig({
    required this.apiBaseUrl,
    required this.socketBaseUrl,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 15),
    this.sendTimeout = const Duration(seconds: 15),
  });

  factory AppConfig.initial() {
    return AppConfig(
      apiBaseUrl: defaultBaseUrl,
      socketBaseUrl: defaultSocketUrl,
    );
  }

  AppConfig copyWith({
    String? apiBaseUrl,
    String? socketBaseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
  }) {
    return AppConfig(
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      socketBaseUrl: socketBaseUrl ?? this.socketBaseUrl,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      sendTimeout: sendTimeout ?? this.sendTimeout,
    );
  }
}

/// App config state provider allowing dynamic runtime inspection or overrides
final appConfigProvider = StateNotifierProvider<AppConfigNotifier, AppConfig>((ref) {
  return AppConfigNotifier(AppConfig.initial());
});

class AppConfigNotifier extends StateNotifier<AppConfig> {
  AppConfigNotifier(super.state);

  void setBaseUrl(String url) {
    state = state.copyWith(apiBaseUrl: url, socketBaseUrl: url);
  }
}
