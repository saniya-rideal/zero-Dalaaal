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

  factory MarketDepth.fromJson(Map<String, dynamic> json) {
    List<DepthLevel> parseList(dynamic raw) {
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map((e) => DepthLevel.fromJson(e))
            .toList();
      }
      return const [];
    }

    return MarketDepth(
      buy: parseList(json['buy']),
      sell: parseList(json['sell']),
    );
  }
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

  double get bestBid => depth.buy.isNotEmpty ? depth.buy.first.price : ltp;
  double get bestAsk => depth.sell.isNotEmpty ? depth.sell.first.price : ltp;
  double get lastPrice => ltp;
  double get openPrice => open;
  double get dayHigh => high;
  double get dayLow => low;
  double get netChange => change;
  double get percentChange => changePercent;
  DateTime get lastTradeTime => timestamp;

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

  factory Quote.fromJson(Map<String, dynamic> json) {
    final sym = (json['symbol'] ?? json['token'] ?? '').toString();
    final lastPrice = (json['last'] ?? json['ltp'] ?? json['price'] as num?)?.toDouble() ?? 0.0;
    final op = (json['open'] as num?)?.toDouble() ?? lastPrice;
    final hi = (json['high'] as num?)?.toDouble() ?? lastPrice;
    final lo = (json['low'] as num?)?.toDouble() ?? lastPrice;
    final cl = (json['close'] as num?)?.toDouble() ?? lastPrice;
    final pc = (json['prevClose'] ?? json['previousClose'] as num?)?.toDouble() ?? op;
    final chg = (json['change'] as num?)?.toDouble() ?? (lastPrice - pc);
    final chgPct = (json['changePercent'] ?? json['pChange'] as num?)?.toDouble() ??
        (pc != 0 ? ((chg / pc) * 100) : 0.0);
    final vol = (json['volume'] ?? json['vol'] as num?)?.toInt() ?? 0;

    final bid = (json['bid'] as num?)?.toDouble() ?? lastPrice;
    final ask = (json['ask'] as num?)?.toDouble() ?? lastPrice;

    MarketDepth d;
    if (json['depth'] is Map<String, dynamic>) {
      d = MarketDepth.fromJson(json['depth'] as Map<String, dynamic>);
    } else {
      d = MarketDepth(
        buy: [DepthLevel(price: bid, qty: 1, orders: 1)],
        sell: [DepthLevel(price: ask, qty: 1, orders: 1)],
      );
    }

    DateTime ts;
    if (json['timestamp'] != null) {
      ts = DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now();
    } else {
      ts = DateTime.now();
    }

    return Quote(
      token: sym,
      ltp: lastPrice,
      open: op,
      high: hi,
      low: lo,
      close: cl,
      prevClose: pc,
      change: double.parse(chg.toStringAsFixed(2)),
      changePercent: double.parse(chgPct.toStringAsFixed(2)),
      volume: vol,
      lowerCircuit: (json['lowerCircuit'] as num?)?.toDouble() ?? (pc * 0.9),
      upperCircuit: (json['upperCircuit'] as num?)?.toDouble() ?? (pc * 1.1),
      high52: (json['high52'] as num?)?.toDouble() ?? (hi * 1.2),
      low52: (json['low52'] as num?)?.toDouble() ?? (lo * 0.8),
      depth: d,
      timestamp: ts,
    );
  }

  factory Quote.zero(String token) => Quote(
    token: token,
    ltp: 0.0,
    open: 0.0,
    high: 0.0,
    low: 0.0,
    close: 0.0,
    prevClose: 0.0,
    change: 0.0,
    changePercent: 0.0,
    volume: 0,
    depth: const MarketDepth(buy: [], sell: []),
    timestamp: DateTime.now(),
  );
}
