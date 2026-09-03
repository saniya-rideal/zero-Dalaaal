class DepthLevel {
  final double price;
  final int qty;
  final int orders;

  const DepthLevel({
    required this.price,
    required this.qty,
    required this.orders,
  });

  Map<String, dynamic> toJson() => {
    'price': price,
    'qty': qty,
    'orders': orders,
  };

  factory DepthLevel.fromJson(Map<String, dynamic> json) => DepthLevel(
    price: (json['price'] as num).toDouble(),
    qty: (json['qty'] as num).toInt(),
    orders: (json['orders'] as num).toInt(),
  );
}

class MarketDepth {
  final List<DepthLevel> buy;
  final List<DepthLevel> sell;

  const MarketDepth({
    required this.buy,
    required this.sell,
  });

  int get totalBuyQty => buy.fold(0, (sum, item) => sum + item.qty);
  int get totalSellQty => sell.fold(0, (sum, item) => sum + item.qty);

  Map<String, dynamic> toJson() => {
    'buy': buy.map((e) => e.toJson()).toList(),
    'sell': sell.map((e) => e.toJson()).toList(),
  };

  factory MarketDepth.fromJson(Map<String, dynamic> json) => MarketDepth(
    buy: (json['buy'] as List<dynamic>).map((e) => DepthLevel.fromJson(e as Map<String, dynamic>)).toList(),
    sell: (json['sell'] as List<dynamic>).map((e) => DepthLevel.fromJson(e as Map<String, dynamic>)).toList(),
  );
}

class Quote {
  final String token;
  final double ltp;
  final double open;
  final double high;
  final double low;
  final double close;
  final double prevClose;
  final double change;
  final double changePercent;
  final int volume;
  final double lowerCircuit;
  final double upperCircuit;
  final double high52;
  final double low52;
  final MarketDepth depth;
  final DateTime timestamp;

  const Quote({
    required this.token,
    required this.ltp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.prevClose,
    required this.change,
    required this.changePercent,
    required this.volume,
    this.lowerCircuit = 0.0,
    this.upperCircuit = 0.0,
    this.high52 = 0.0,
    this.low52 = 0.0,
    required this.depth,
    required this.timestamp,
  });

  Quote copyWith({
    String? token,
    double? ltp,
    double? open,
    double? high,
    double? low,
    double? close,
    double? prevClose,
    double? change,
    double? changePercent,
    int? volume,
    double? lowerCircuit,
    double? upperCircuit,
    double? high52,
    double? low52,
    MarketDepth? depth,
    DateTime? timestamp,
  }) {
    return Quote(
      token: token ?? this.token,
      ltp: ltp ?? this.ltp,
      open: open ?? this.open,
      high: high ?? this.high,
      low: low ?? this.low,
      close: close ?? this.close,
      prevClose: prevClose ?? this.prevClose,
      change: change ?? this.change,
      changePercent: changePercent ?? this.changePercent,
      volume: volume ?? this.volume,
      lowerCircuit: lowerCircuit ?? this.lowerCircuit,
      upperCircuit: upperCircuit ?? this.upperCircuit,
      high52: high52 ?? this.high52,
      low52: low52 ?? this.low52,
      depth: depth ?? this.depth,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'ltp': ltp,
    'open': open,
    'high': high,
    'low': low,
    'close': close,
    'prevClose': prevClose,
    'change': change,
    'changePercent': changePercent,
    'volume': volume,
    'lowerCircuit': lowerCircuit,
    'upperCircuit': upperCircuit,
    'high52': high52,
    'low52': low52,
    'depth': depth.toJson(),
    'timestamp': timestamp.toIso8601String(),
  };

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
    token: json['token'] as String,
    ltp: (json['ltp'] as num).toDouble(),
    open: (json['open'] as num).toDouble(),
    high: (json['high'] as num).toDouble(),
    low: (json['low'] as num).toDouble(),
    close: (json['close'] as num).toDouble(),
    prevClose: (json['prevClose'] as num).toDouble(),
    change: (json['change'] as num).toDouble(),
    changePercent: (json['changePercent'] as num).toDouble(),
    volume: (json['volume'] as num).toInt(),
    lowerCircuit: (json['lowerCircuit'] as num?)?.toDouble() ?? 0.0,
    upperCircuit: (json['upperCircuit'] as num?)?.toDouble() ?? 0.0,
    high52: (json['high52'] as num?)?.toDouble() ?? 0.0,
    low52: (json['low52'] as num?)?.toDouble() ?? 0.0,
    depth: MarketDepth.fromJson(json['depth'] as Map<String, dynamic>),
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}
