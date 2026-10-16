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

  // Statutory Regulatory Identifiers & Disclaimers (Configured from API)
  static const String paperTradingDisclaimer = 'Regulatory disclaimer unavailable';
  static const String regulatoryCin = 'Unavailable';
  static const String sebiRegistrationNo = 'Unavailable';
  static const String cdslDpId = 'Unavailable';
  static const int minimumAge = 18;
  static const String sebiFnoLossWarning = 'Regulatory warning unavailable';

  // Ticker interval
  static const int tickerIntervalMs = 1200;
}
