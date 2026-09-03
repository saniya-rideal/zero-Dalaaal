class AppConstants {
  AppConstants._();

  static const String appName = 'Zero';
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

  // Ticker interval
  static const int tickerIntervalMs = 1200;
}
