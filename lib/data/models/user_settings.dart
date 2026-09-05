import 'package:flutter/material.dart';
import 'enums.dart';

enum AppLanguage {
  english('en', 'English'),
  hindi('hi', 'हिंदी (Hindi)'),
  gujarati('gu', 'ગુજરાતી (Gujarati)'),
  marathi('mr', 'मराठी (Marathi)'),
  bengali('bn', 'বাংলা (Bengali)'),
  tamil('ta', 'தமிழ் (Tamil)');

  final String code;
  final String displayName;
  const AppLanguage(this.code, this.displayName);
}

enum NumberFormattingMode {
  indian('Indian Grouping (1,23,456.78 - Lakhs/Crores)'),
  international('International Grouping (123,456.78 - Millions/Billions)');

  final String label;
  const NumberFormattingMode(this.label);
}

enum DateFormattingMode {
  ddMmYyyy('DD/MM/YYYY (e.g. 05/09/2026)'),
  mmDdYyyy('MM/DD/YYYY (e.g. 09/05/2026)'),
  yyyyMmDd('YYYY-MM-DD (e.g. 2026-09-05)');

  final String label;
  const DateFormattingMode(this.label);
}

enum TimeFormattingMode {
  format12h('12-Hour (e.g. 02:30:15 PM)'),
  format24h('24-Hour (e.g. 14:30:15)');

  final String label;
  const TimeFormattingMode(this.label);
}

enum CurrencyDisplayPreference {
  inr('₹ INR (Indian Rupee)', '₹'),
  usd('\$ USD (US Dollar)', '\$'),
  eur('€ EUR (Euro)', '€'),
  gbp('£ GBP (British Pound)', '£');

  final String label;
  final String symbol;
  const CurrencyDisplayPreference(this.label, this.symbol);
}

enum ChartTypePreference {
  candlestick('Candlestick (Standard)'),
  heikinAshi('Heikin-Ashi (Smoothed Trend)'),
  line('Line Chart (Close Price)'),
  area('Area / Mountain Chart');

  final String label;
  const ChartTypePreference(this.label);
}

enum PriceChangeDisplayMode {
  percent('Percentage (%)'),
  absolute('Absolute Points (₹)');

  final String label;
  const PriceChangeDisplayMode(this.label);
}

class ActiveSessionItem {
  final String id;
  final String deviceName;
  final String platform;
  final String ipAddress;
  final String lastActive;
  final bool isCurrentDevice;

  const ActiveSessionItem({
    required this.id,
    required this.deviceName,
    required this.platform,
    required this.ipAddress,
    required this.lastActive,
    this.isCurrentDevice = false,
  });

  ActiveSessionItem copyWith({
    String? id,
    String? deviceName,
    String? platform,
    String? ipAddress,
    String? lastActive,
    bool? isCurrentDevice,
  }) {
    return ActiveSessionItem(
      id: id ?? this.id,
      deviceName: deviceName ?? this.deviceName,
      platform: platform ?? this.platform,
      ipAddress: ipAddress ?? this.ipAddress,
      lastActive: lastActive ?? this.lastActive,
      isCurrentDevice: isCurrentDevice ?? this.isCurrentDevice,
    );
  }
}

class UserSettings {
  // ─── 1. Appearance & Language ──────────────────────────────────────────────
  final ThemeMode themeMode;
  final AppLanguage language;
  final NumberFormattingMode numberFormat;
  final DateFormattingMode dateFormat;
  final TimeFormattingMode timeFormat;
  final CurrencyDisplayPreference currency;

  // ─── 2. Security Settings ──────────────────────────────────────────────────
  final bool biometricEnabled;
  final bool pinLockEnabled;
  final String appPin;
  final bool twoFactorEnabled;
  final String totpSecretKey;
  final bool securityAlertsEnabled;
  final List<ActiveSessionItem> activeSessions;

  // ─── 3. Trading Preferences ────────────────────────────────────────────────
  final OrderKind defaultOrderType;
  final ProductType defaultProductType;
  final int defaultQuantity;
  final double defaultLots;
  final bool autoStopLossEnabled;
  final double defaultStopLossPercent;
  final bool autoTakeProfitEnabled;
  final double defaultTakeProfitPercent;
  final bool confirmBeforeOrder;

  // ─── 4. Chart & Watchlist Preferences ──────────────────────────────────────
  final ChartTypePreference defaultChartType;
  final String defaultTimeframe;
  final bool showChartVolume;
  final bool proViewDefault;
  final PriceChangeDisplayMode priceChangeMode;
  final bool enableHapticFeedback;
  final bool showStickyScripts;
  final bool quotesGrouping;
  final bool keepScreenAwake;
  final bool muteAllSounds;
  final bool openWhereLeft;

  const UserSettings({
    this.themeMode = ThemeMode.system,
    this.language = AppLanguage.english,
    this.numberFormat = NumberFormattingMode.indian,
    this.dateFormat = DateFormattingMode.ddMmYyyy,
    this.timeFormat = TimeFormattingMode.format24h,
    this.currency = CurrencyDisplayPreference.inr,
    this.biometricEnabled = false,
    this.pinLockEnabled = true,
    this.appPin = '1234',
    this.twoFactorEnabled = true,
    this.totpSecretKey = 'JBSWY3DPEHPK3PXP',
    this.securityAlertsEnabled = true,
    this.activeSessions = const [
      ActiveSessionItem(
        id: 'sess_cur',
        deviceName: 'Android App (This Device)',
        platform: 'OnePlus 12 • Android 14',
        ipAddress: '103.21.14.82',
        lastActive: 'Active Now',
        isCurrentDevice: true,
      ),
      ActiveSessionItem(
        id: 'sess_web',
        deviceName: 'WebTrader (Chrome 128)',
        platform: 'Windows 11',
        ipAddress: '103.21.14.82',
        lastActive: 'Active 2h ago',
        isCurrentDevice: false,
      ),
      ActiveSessionItem(
        id: 'sess_ios',
        deviceName: 'iPhone 15 Pro (Safari)',
        platform: 'iOS 17.5',
        ipAddress: '49.37.12.11',
        lastActive: 'Active 3 days ago',
        isCurrentDevice: false,
      ),
    ],
    this.defaultOrderType = OrderKind.MARKET,
    this.defaultProductType = ProductType.MIS,
    this.defaultQuantity = 1,
    this.defaultLots = 0.0,
    this.autoStopLossEnabled = false,
    this.defaultStopLossPercent = 2.0,
    this.autoTakeProfitEnabled = false,
    this.defaultTakeProfitPercent = 4.0,
    this.confirmBeforeOrder = true,
    this.defaultChartType = ChartTypePreference.candlestick,
    this.defaultTimeframe = '1D',
    this.showChartVolume = true,
    this.proViewDefault = false,
    this.priceChangeMode = PriceChangeDisplayMode.percent,
    this.enableHapticFeedback = true,
    this.showStickyScripts = true,
    this.quotesGrouping = false,
    this.keepScreenAwake = true,
    this.muteAllSounds = false,
    this.openWhereLeft = true,
  });

  UserSettings copyWith({
    ThemeMode? themeMode,
    AppLanguage? language,
    NumberFormattingMode? numberFormat,
    DateFormattingMode? dateFormat,
    TimeFormattingMode? timeFormat,
    CurrencyDisplayPreference? currency,
    bool? biometricEnabled,
    bool? pinLockEnabled,
    String? appPin,
    bool? twoFactorEnabled,
    String? totpSecretKey,
    bool? securityAlertsEnabled,
    List<ActiveSessionItem>? activeSessions,
    OrderKind? defaultOrderType,
    ProductType? defaultProductType,
    int? defaultQuantity,
    double? defaultLots,
    bool? autoStopLossEnabled,
    double? defaultStopLossPercent,
    bool? autoTakeProfitEnabled,
    double? defaultTakeProfitPercent,
    bool? confirmBeforeOrder,
    ChartTypePreference? defaultChartType,
    String? defaultTimeframe,
    bool? showChartVolume,
    bool? proViewDefault,
    PriceChangeDisplayMode? priceChangeMode,
    bool? enableHapticFeedback,
    bool? showStickyScripts,
    bool? quotesGrouping,
    bool? keepScreenAwake,
    bool? muteAllSounds,
    bool? openWhereLeft,
  }) {
    return UserSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      numberFormat: numberFormat ?? this.numberFormat,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
      currency: currency ?? this.currency,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      pinLockEnabled: pinLockEnabled ?? this.pinLockEnabled,
      appPin: appPin ?? this.appPin,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      totpSecretKey: totpSecretKey ?? this.totpSecretKey,
      securityAlertsEnabled: securityAlertsEnabled ?? this.securityAlertsEnabled,
      activeSessions: activeSessions ?? this.activeSessions,
      defaultOrderType: defaultOrderType ?? this.defaultOrderType,
      defaultProductType: defaultProductType ?? this.defaultProductType,
      defaultQuantity: defaultQuantity ?? this.defaultQuantity,
      defaultLots: defaultLots ?? this.defaultLots,
      autoStopLossEnabled: autoStopLossEnabled ?? this.autoStopLossEnabled,
      defaultStopLossPercent: defaultStopLossPercent ?? this.defaultStopLossPercent,
      autoTakeProfitEnabled: autoTakeProfitEnabled ?? this.autoTakeProfitEnabled,
      defaultTakeProfitPercent: defaultTakeProfitPercent ?? this.defaultTakeProfitPercent,
      confirmBeforeOrder: confirmBeforeOrder ?? this.confirmBeforeOrder,
      defaultChartType: defaultChartType ?? this.defaultChartType,
      defaultTimeframe: defaultTimeframe ?? this.defaultTimeframe,
      showChartVolume: showChartVolume ?? this.showChartVolume,
      proViewDefault: proViewDefault ?? this.proViewDefault,
      priceChangeMode: priceChangeMode ?? this.priceChangeMode,
      enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
      showStickyScripts: showStickyScripts ?? this.showStickyScripts,
      quotesGrouping: quotesGrouping ?? this.quotesGrouping,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      muteAllSounds: muteAllSounds ?? this.muteAllSounds,
      openWhereLeft: openWhereLeft ?? this.openWhereLeft,
    );
  }
}
