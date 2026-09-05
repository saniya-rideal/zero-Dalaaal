class AppConstants {
  AppConstants._();

  static const String appName = 'Zero';
  static const String appFormalTitle = 'ZeroDalali Life';
  static const String operatedBy = 'Winds Global';
  static const String storeListingUpdateDate = 'March 30, 2026';
  static const String officialWebsiteUrl = 'https://zerodalali.com';
  static const String appTagline = 'Zero Commission Trading & Investing';
  static const String appVersion = '1.0.0';

  // Watchlist limits
  static const int maxWatchlists = 25;
  static const int maxInstrumentsPerWatchlist = 250;

  // Demo user defaults
  static const String demoUserId = 'ZERO1234';
  static const String demoUserName = 'Anurag Sharma';
  static const String demoEmail = 'anurag@zero.com';
  static const String demoPan = 'ABCDE1234F';
  static const String defaultPin = '123456';

  // Seed initial capital
  static const double initialEquityMargin = 250000.00;
  static const double initialCommodityMargin = 100000.00;

  // Production & Release Metadata
  static const String packageId = 'com.Zero.zero_dalali';
  static const String privacyPolicyUrl = 'https://zerodalali.com/privacy';
  static const String termsConditionsUrl = 'https://zerodalali.com/terms';
  static const String riskDisclosureUrl = 'https://zerodalali.com/risk-disclosure';
  static const String supportHelpUrl = 'https://zerodalali.com/support';
  static const String accountDeletionUrl = 'https://zerodalali.com/account/delete';

  // Statutory SEBI & Regulatory Identifiers
  static const String regulatoryCin = 'U67120KA2024PTC189201';
  static const String sebiRegistrationNo = 'INZ000312345';
  static const String cdslDpId = 'IN-DP-CDSL-892-2024';
  static const int minimumAge = 18;
  static const String sebiFnoLossWarning =
      '9 out of 10 individual traders in equity Futures and Options Segment incurred net losses.';

  // Ticker interval
  static const int tickerIntervalMs = 1200;
}
