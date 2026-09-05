import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/notification_service.dart';
import '../models/models.dart';

class SettingsRepository extends ChangeNotifier {
  final Ref? _ref;
  UserSettings _settings = const UserSettings();

  SettingsRepository([this._ref]);

  UserSettings get settings => _settings;

  // ─── 1. Appearance & Language ──────────────────────────────────────────────

  void setThemeMode(ThemeMode mode) {
    _settings = _settings.copyWith(themeMode: mode);
    notifyListeners();
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

  // ─── 2. Security Settings ──────────────────────────────────────────────────

  bool changePassword({required String oldPassword, required String newPassword}) {
    if (newPassword.length < 8) return false;

    // Dispatch security notification
    try {
      _ref?.read(notificationServiceProvider).notify(NotificationItem(
        id: 'notif_pwd_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.passwordChanged,
        category: NotificationCategory.security,
        title: 'Password Changed Successfully',
        body: 'Your trading account password was updated from this device.',
        timestamp: DateTime.now(),
        deepLink: '/settings',
        isCritical: true,
      ));
    } catch (_) {}

    notifyListeners();
    return true;
  }

  void setPinLockEnabled(bool enabled) {
    _settings = _settings.copyWith(pinLockEnabled: enabled);
    notifyListeners();
  }

  bool updateAppPin(String newPin) {
    if (newPin.length < 4) return false;
    _settings = _settings.copyWith(appPin: newPin, pinLockEnabled: true);
    notifyListeners();
    return true;
  }

  void setBiometricEnabled(bool enabled) {
    _settings = _settings.copyWith(biometricEnabled: enabled);
    notifyListeners();
  }

  void setTwoFactorEnabled(bool enabled) {
    _settings = _settings.copyWith(twoFactorEnabled: enabled);
    notifyListeners();
  }

  void setSecurityAlertsEnabled(bool enabled) {
    _settings = _settings.copyWith(securityAlertsEnabled: enabled);
    notifyListeners();
  }

  void revokeSession(String sessionId) {
    final updated = _settings.activeSessions.where((s) => s.id != sessionId).toList();
    _settings = _settings.copyWith(activeSessions: updated);
    notifyListeners();
  }

  void revokeAllOtherSessions() {
    final currentOnly = _settings.activeSessions.where((s) => s.isCurrentDevice).toList();
    _settings = _settings.copyWith(activeSessions: currentOnly);

    try {
      _ref?.read(notificationServiceProvider).notify(NotificationItem(
        id: 'notif_revoke_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.securityAlert,
        category: NotificationCategory.security,
        title: 'Other Sessions Terminated',
        body: 'All active sessions except this current device have been signed out.',
        timestamp: DateTime.now(),
        deepLink: '/settings',
        isCritical: false,
      ));
    } catch (_) {}

    notifyListeners();
  }

  // ─── 3. Trading Preferences ────────────────────────────────────────────────

  void setDefaultOrderType(OrderKind kind) {
    _settings = _settings.copyWith(defaultOrderType: kind);
    notifyListeners();
  }

  void setDefaultProductType(ProductType product) {
    _settings = _settings.copyWith(defaultProductType: product);
    notifyListeners();
  }

  void setDefaultQuantity(int qty) {
    if (qty <= 0) return;
    _settings = _settings.copyWith(defaultQuantity: qty);
    notifyListeners();
  }

  void setDefaultLots(double lots) {
    if (lots < 0) return;
    _settings = _settings.copyWith(defaultLots: lots);
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

  void setConfirmBeforeOrder(bool confirm) {
    _settings = _settings.copyWith(confirmBeforeOrder: confirm);
    notifyListeners();
  }

  // ─── 4. Chart & Watchlist Preferences ──────────────────────────────────────

  void setDefaultChartType(ChartTypePreference chartType) {
    _settings = _settings.copyWith(defaultChartType: chartType);
    notifyListeners();
  }

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

  void setPriceChangeMode(PriceChangeDisplayMode mode) {
    _settings = _settings.copyWith(priceChangeMode: mode);
    notifyListeners();
  }

  void setEnableHapticFeedback(bool enabled) {
    _settings = _settings.copyWith(enableHapticFeedback: enabled);
    notifyListeners();
  }

  void setShowStickyScripts(bool show) {
    _settings = _settings.copyWith(showStickyScripts: show);
    notifyListeners();
  }

  void setQuotesGrouping(bool grouping) {
    _settings = _settings.copyWith(quotesGrouping: grouping);
    notifyListeners();
  }

  void setKeepScreenAwake(bool awake) {
    _settings = _settings.copyWith(keepScreenAwake: awake);
    notifyListeners();
  }

  void setMuteAllSounds(bool mute) {
    _settings = _settings.copyWith(muteAllSounds: mute);
    notifyListeners();
  }

  void setOpenWhereLeft(bool open) {
    _settings = _settings.copyWith(openWhereLeft: open);
    notifyListeners();
  }

  // ─── 5. Account Deletion Request ───────────────────────────────────────────

  Future<bool> requestAccountDeletion({required String reason, String? feedback}) async {
    await Future.delayed(const Duration(milliseconds: 600));

    try {
      _ref?.read(notificationServiceProvider).notify(NotificationItem(
        id: 'notif_del_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.accountNotice,
        category: NotificationCategory.security,
        title: 'Account Closure Request Registered',
        body: 'Your closure request (Reason: $reason) is logged. As per SEBI regulations, historical trade records will be retained for 5 years.',
        timestamp: DateTime.now(),
        deepLink: '/settings',
        isCritical: true,
      ));
    } catch (_) {}

    return true;
  }
}

final settingsRepositoryProvider = ChangeNotifierProvider<SettingsRepository>((ref) {
  return SettingsRepository(ref);
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
