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

  factory Candle.fromJson(Map<String, dynamic> json) {
    DateTime parsedTime;
    final rawTime = json['time'] ??
        json['openTime'] ??
        json['timestamp'] ??
        json['t'] ??
        json['date'] ??
        json['closeTime'];

    if (rawTime is String) {
      parsedTime = DateTime.tryParse(rawTime) ?? DateTime.now();
    } else if (rawTime is num) {
      final millis = rawTime > 10000000000 ? rawTime.toInt() : (rawTime * 1000).toInt();
      parsedTime = DateTime.fromMillisecondsSinceEpoch(millis);
    } else {
      parsedTime = DateTime.now();
    }

    return Candle(
      time: parsedTime,
      open: (json['open'] as num?)?.toDouble() ?? 0.0,
      high: (json['high'] as num?)?.toDouble() ?? 0.0,
      low: (json['low'] as num?)?.toDouble() ?? 0.0,
      close: (json['close'] as num?)?.toDouble() ?? 0.0,
      volume: (json['volume'] as num?)?.toInt() ?? 0,
    );
  }
}
