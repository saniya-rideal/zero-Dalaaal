enum IndicatorType {
  SMA('SMA', 'Simple Moving Average', isOverlay: true),
  EMA('EMA', 'Exponential Moving Average', isOverlay: true),
  BOLLINGER('BB', 'Bollinger Bands', isOverlay: true),
  VWAP('VWAP', 'Volume Weighted Average Price', isOverlay: true),
  SUPERTREND('SUPERTREND', 'Supertrend Trend Following', isOverlay: true),
  RSI('RSI', 'Relative Strength Index', isOverlay: false),
  MACD('MACD', 'Moving Average Convergence Divergence', isOverlay: false),
  STOCHASTIC('STOCH', 'Stochastic Oscillator (%K, %D)', isOverlay: false),
  ATR('ATR', 'Average True Range', isOverlay: false);

  final String shortName;
  final String fullName;
  final bool isOverlay;
  const IndicatorType(this.shortName, this.fullName, {required this.isOverlay});
}

class IndicatorConfig {
  final IndicatorType type;
  final bool isEnabled;
  final int period;
  final int secondPeriod;
  final int signalPeriod;
  final double stdDev;

  const IndicatorConfig({
    required this.type,
    this.isEnabled = true,
    this.period = 14,
    this.secondPeriod = 26,
    this.signalPeriod = 9,
    this.stdDev = 2.0,
  });

  IndicatorConfig copyWith({
    bool? isEnabled,
    int? period,
    int? secondPeriod,
    int? signalPeriod,
    double? stdDev,
  }) {
    return IndicatorConfig(
      type: type,
      isEnabled: isEnabled ?? this.isEnabled,
      period: period ?? this.period,
      secondPeriod: secondPeriod ?? this.secondPeriod,
      signalPeriod: signalPeriod ?? this.signalPeriod,
      stdDev: stdDev ?? this.stdDev,
    );
  }
}
