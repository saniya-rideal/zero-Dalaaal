class Candle {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;

  const Candle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  bool get isBullish => close >= open;

  Map<String, dynamic> toJson() => {
    'time': time.toIso8601String(),
    'open': open,
    'high': high,
    'low': low,
    'close': close,
    'volume': volume,
  };

  factory Candle.fromJson(Map<String, dynamic> json) => Candle(
    time: DateTime.parse(json['time'] as String),
    open: (json['open'] as num).toDouble(),
    high: (json['high'] as num).toDouble(),
    low: (json['low'] as num).toDouble(),
    close: (json['close'] as num).toDouble(),
    volume: (json['volume'] as num).toInt(),
  );
}
