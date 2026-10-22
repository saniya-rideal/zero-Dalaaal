import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/response_reader.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/models/models.dart';

class SettingsRepository extends ChangeNotifier {
  final ApiClient? _apiClient;
  final Ref? _ref;
  UserSettings _settings = const UserSettings();

  SettingsRepository([this._apiClient, this._ref]) {
    _loadFromBackend();
  }

  UserSettings get settings => _settings;

  Future<void> _loadFromBackend() async {
    if (_apiClient == null) return;
    try {
      final data = await _apiClient.get(ApiPaths.userSettings);
      final obj = ResponseReader.object(data);
      if (obj.isNotEmpty) {
        _settings = _settings.copyWith(
          themeMode: (obj['theme']?.toString().toUpperCase() == 'DARK')
              ? ThemeMode.dark
              : ThemeMode.light,
          biometricEnabled: obj['biometricEnabled'] as bool? ?? _settings.biometricEnabled,
          twoFactorEnabled: obj['twoFactorEnabled'] as bool? ?? _settings.twoFactorEnabled,
          orderNotificationSound: obj['orderNotification'] as bool? ?? _settings.orderNotificationSound,
          priceAlertSound: obj['priceAlertNotification'] as bool? ?? _settings.priceAlertSound,
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _syncToBackend() async {
    if (_apiClient == null) return;
    try {
      await _apiClient.put(
        ApiPaths.userSettings,
        data: {
          'theme': _settings.themeMode == ThemeMode.light ? 'LIGHT' : 'DARK',
          'biometricEnabled': _settings.biometricEnabled,
          'twoFactorEnabled': _settings.twoFactorEnabled,
          'orderNotification': _settings.orderNotificationSound,
          'priceAlertNotification': _settings.priceAlertSound,
        },
      );
    } catch (_) {}
  }

  void setThemeMode(ThemeMode mode) {
    _settings = _settings.copyWith(themeMode: mode);
    notifyListeners();
    _syncToBackend();
  }

  void setLanguage(AppLanguage language) {
    _settings = _settings.copyWith(language: language);
    notifyListeners();
  }

  void setNumberFormatting(NumberFormattingMode mode) {
    _settings = _settings.copyWith(numberFormat: mode);
    notifyListeners();
  }

  void setDateFormatting(DateFormattingMode mode) {
    _settings = _settings.copyWith(dateFormat: mode);
    notifyListeners();
  }

  void setTimeFormatting(TimeFormattingMode mode) {
    _settings = _settings.copyWith(timeFormat: mode);
    notifyListeners();
  }

  void setCurrencyPreference(CurrencyDisplayPreference currency) {
    _settings = _settings.copyWith(currency: currency);
    notifyListeners();
  }

  void setBiometricEnabled(bool enabled) {
    _settings = _settings.copyWith(biometricEnabled: enabled);
    notifyListeners();
    _syncToBackend();
  }

  void setPinLockEnabled(bool enabled) {
    _settings = _settings.copyWith(pinLockEnabled: enabled);
    notifyListeners();
  }

  void setAppPin(String pin) {
    _settings = _settings.copyWith(appPin: pin);
    notifyListeners();
  }

  void setTwoFactorEnabled(bool enabled) {
    _settings = _settings.copyWith(twoFactorEnabled: enabled);
    notifyListeners();
    _syncToBackend();
  }

  void setAutoLockTimeout(int minutes) {
    _settings = _settings.copyWith(autoLockTimeoutMinutes: minutes);
    notifyListeners();
  }

  void setDefaultLots(double lots) {
    _settings = _settings.copyWith(defaultLots: lots);
    notifyListeners();
  }

  void setChartType(ChartTypePreference chartType) {
    _settings = _settings.copyWith(defaultChartType: chartType);
    notifyListeners();
    _syncToBackend();
  }

  void setPriceChangeDisplayMode(PriceChangeDisplayMode mode) {
    _settings = _settings.copyWith(priceChangeMode: mode);
    notifyListeners();
  }

  void setHapticFeedback(bool enabled) {
    _settings = _settings.copyWith(enableHapticFeedback: enabled);
    notifyListeners();
  }

  void setOrderExecutionSound(bool enabled) {
    _settings = _settings.copyWith(muteAllSounds: !enabled);
    notifyListeners();
    _syncToBackend();
  }

  void setPriceAlertSound(bool enabled) {
    _settings = _settings.copyWith(muteAllSounds: !enabled);
    notifyListeners();
    _syncToBackend();
  }

  void setKeepScreenAwake(bool value) {
    _settings = _settings.copyWith(keepScreenAwake: value);
    notifyListeners();
  }

  void setMuteAllSounds(bool value) {
    _settings = _settings.copyWith(muteAllSounds: value);
    notifyListeners();
    _syncToBackend();
  }

  void setOpenWhereLeft(bool value) {
    _settings = _settings.copyWith(openWhereLeft: value);
    notifyListeners();
  }

  void setQuotesGrouping(bool value) {
    _settings = _settings.copyWith(quotesGrouping: value);
    notifyListeners();
  }

  void setShowStickyScripts(bool value) {
    _settings = _settings.copyWith(showStickyScripts: value);
    notifyListeners();
  }

  bool updateAppPin(String pin) {
    if (pin.length == 4) {
      _settings = _settings.copyWith(appPin: pin, pinLockEnabled: true);
      notifyListeners();
      return true;
    }
    return false;
  }

  void setSecurityAlertsEnabled(bool enabled) {
    _settings = _settings.copyWith(securityAlertsEnabled: enabled);
    notifyListeners();
  }

  void setEnableHapticFeedback(bool enabled) => setHapticFeedback(enabled);

  void revokeSession(String sessionId) {
    final updated = _settings.activeSessions.where((s) => s.id != sessionId).toList();
    _settings = _settings.copyWith(activeSessions: updated);
    notifyListeners();
  }

  void revokeOtherSessions() {
    final updated = _settings.activeSessions.where((s) => s.isCurrentDevice).toList();
    _settings = _settings.copyWith(activeSessions: updated);
    notifyListeners();
  }

  bool changePassword({required String oldPassword, required String newPassword}) {
    if (newPassword.length < 8) return false;
    if (_apiClient != null) {
      _apiClient.put(
        ApiPaths.userSettings,
        data: {
          'currentPassword': oldPassword,
          'newPassword': newPassword,
        },
      ).catchError((_) => null);
    }
    return true;
  }

  void revokeAllOtherSessions() => revokeOtherSessions();

  void setDefaultOrderType(OrderKind type) {
    _settings = _settings.copyWith(defaultOrderType: type);
    notifyListeners();
  }

  void setDefaultProductType(ProductType type) {
    _settings = _settings.copyWith(defaultProductType: type);
    notifyListeners();
  }

  void setDefaultQuantity(int qty) {
    if (qty <= 0) return;
    _settings = _settings.copyWith(defaultQuantity: qty);
    notifyListeners();
  }

  void setConfirmBeforeOrder(bool value) {
    _settings = _settings.copyWith(confirmBeforeOrder: value);
    notifyListeners();
  }

  void setAutoStopLoss({required bool enabled, double? percent}) {
    _settings = _settings.copyWith(
      autoStopLossEnabled: enabled,
      defaultStopLossPercent: percent ?? _settings.defaultStopLossPercent,
    );
    notifyListeners();
  }

  void setAutoTakeProfit({required bool enabled, double? percent}) {
    _settings = _settings.copyWith(
      autoTakeProfitEnabled: enabled,
      defaultTakeProfitPercent: percent ?? _settings.defaultTakeProfitPercent,
    );
    notifyListeners();
  }

  void setDefaultChartType(ChartTypePreference chartType) => setChartType(chartType);

  void setDefaultTimeframe(String tf) {
    _settings = _settings.copyWith(defaultTimeframe: tf);
    notifyListeners();
  }

  void setShowChartVolume(bool show) {
    _settings = _settings.copyWith(showChartVolume: show);
    notifyListeners();
  }

  void setProViewDefault(bool pro) {
    _settings = _settings.copyWith(proViewDefault: pro);
    notifyListeners();
  }

  void setPriceChangeMode(PriceChangeDisplayMode mode) => setPriceChangeDisplayMode(mode);

  Future<bool> requestAccountDeletion({String? reason, String? feedback}) async {
    if (_apiClient != null) {
      try {
        await _apiClient.post(
          '/api/user/account-deletion',
          data: {'reason': reason ?? feedback ?? 'User requested deletion'},
        );
      } catch (_) {}
    }
    if (_ref != null) {
      try {
        _ref.read(notificationServiceProvider).notify(
          NotificationItem(
            id: 'notif_del_${DateTime.now().millisecondsSinceEpoch}',
            type: NotificationType.accountNotice,
            category: NotificationCategory.security,
            title: 'Account Closure Request Registered',
            body: 'As per statutory PMLA regulations, trade and KYC records are preserved for 5 years.',
            timestamp: DateTime.now(),
          ),
        );
      } catch (_) {}
    }
    return true;
  }
}

final settingsRepositoryProvider = ChangeNotifierProvider<SettingsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SettingsRepository(apiClient, ref);
});

final appSettingsProvider = Provider<UserSettings>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.settings;
});

final themeModeControllerProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.themeMode;
});

final activeSessionsProvider = Provider<List<ActiveSessionItem>>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.activeSessions;
});
