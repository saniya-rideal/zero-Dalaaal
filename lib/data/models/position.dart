import 'enums.dart';
import 'instrument.dart';

class Position {
  final String id;
  final Instrument instrument;
  final ProductType product;
  final int buyQty;
  final int sellQty;
  final int netQty;
  final double buyAvg;
  final double sellAvg;
  final double ltp;
  final double realizedPnl;
  final double? _unrealizedPnl;
  final bool isDayPosition;
  final double? stopLoss;
  final double? takeProfit;
  final double leverage;
  final double usedMargin;
  final DateTime openTime;

  Position({
    required this.id,
    required this.instrument,
    required this.product,
    required this.buyQty,
    required this.sellQty,
    required this.netQty,
    required this.buyAvg,
    required this.sellAvg,
    required this.ltp,
    required this.realizedPnl,
    double? unrealizedPnl,
    this.isDayPosition = true,
    this.stopLoss,
    this.takeProfit,
    this.leverage = 5.0,
    this.usedMargin = 0.0,
    DateTime? openTime,
  })  : _unrealizedPnl = unrealizedPnl,
        openTime = openTime ?? DateTime.now();

  double get unrealizedPnl {
    if (netQty != 0 && entryPrice > 0 && ltp > 0) {
      final multiplier = instrument.exchange == Exchange.MCX ? instrument.contractMultiplier : 1.0;
      return netQty * (ltp - entryPrice) * multiplier;
    }
    return _unrealizedPnl ?? 0.0;
  }

  // Helper getters
  bool get isLong => netQty > 0;
  bool get isShort => netQty < 0;
  bool get isClosed => netQty == 0;
  TransactionType get side => isLong ? TransactionType.BUY : TransactionType.SELL;

  double get entryPrice => isLong ? buyAvg : (sellAvg > 0 ? sellAvg : buyAvg);
  double get totalPnl => realizedPnl + unrealizedPnl;
  double get exposure => netQty.abs() * ltp * (instrument.exchange == Exchange.MCX ? instrument.contractMultiplier : 1.0);
  double get currentValue => netQty * ltp * (instrument.exchange == Exchange.MCX ? instrument.contractMultiplier : 1.0);
  double get investedValue => netQty.abs() * (entryPrice > 0 ? entryPrice : ltp) * (instrument.exchange == Exchange.MCX ? instrument.contractMultiplier : 1.0);

  /// Unrealized P&L percentage based on entry price
  double get pnlPercent {
    if (entryPrice <= 0) return 0.0;
    final diff = ltp - entryPrice;
    return (diff / entryPrice) * 100 * (isLong ? 1 : -1);
  }

  Position copyWith({
    String? id,
    Instrument? instrument,
    ProductType? product,
    int? buyQty,
    int? sellQty,
    int? netQty,
    double? buyAvg,
    double? sellAvg,
    double? ltp,
    double? realizedPnl,
    double? unrealizedPnl,
    bool? isDayPosition,
    double? stopLoss,
    double? takeProfit,
    double? leverage,
    double? usedMargin,
    DateTime? openTime,
  }) {
    return Position(
      id: id ?? this.id,
      instrument: instrument ?? this.instrument,
      product: product ?? this.product,
      buyQty: buyQty ?? this.buyQty,
      sellQty: sellQty ?? this.sellQty,
      netQty: netQty ?? this.netQty,
      buyAvg: buyAvg ?? this.buyAvg,
      sellAvg: sellAvg ?? this.sellAvg,
      ltp: ltp ?? this.ltp,
      realizedPnl: realizedPnl ?? this.realizedPnl,
      unrealizedPnl: unrealizedPnl ?? this.unrealizedPnl,
      isDayPosition: isDayPosition ?? this.isDayPosition,
      stopLoss: stopLoss ?? this.stopLoss,
      takeProfit: takeProfit ?? this.takeProfit,
      leverage: leverage ?? this.leverage,
      usedMargin: usedMargin ?? this.usedMargin,
      openTime: openTime ?? this.openTime,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'instrument': instrument.toJson(),
    'product': product.name,
    'buyQty': buyQty,
    'sellQty': sellQty,
    'netQty': netQty,
    'buyAvg': buyAvg,
    'sellAvg': sellAvg,
    'ltp': ltp,
    'realizedPnl': realizedPnl,
    'unrealizedPnl': unrealizedPnl,
    'isDayPosition': isDayPosition,
    'stopLoss': stopLoss,
    'takeProfit': takeProfit,
    'leverage': leverage,
    'usedMargin': usedMargin,
    'openTime': openTime.toIso8601String(),
  };

  factory Position.fromJson(Map<String, dynamic> json) => Position(
    id: json['id'] as String,
    instrument: Instrument.fromJson(json['instrument'] as Map<String, dynamic>),
    product: ProductType.values.byName(json['product'] as String),
    buyQty: (json['buyQty'] as num).toInt(),
    sellQty: (json['sellQty'] as num).toInt(),
    netQty: (json['netQty'] as num).toInt(),
    buyAvg: (json['buyAvg'] as num).toDouble(),
    sellAvg: (json['sellAvg'] as num).toDouble(),
    ltp: (json['ltp'] as num).toDouble(),
    realizedPnl: (json['realizedPnl'] as num).toDouble(),
    unrealizedPnl: (json['unrealizedPnl'] as num).toDouble(),
    isDayPosition: json['isDayPosition'] as bool? ?? true,
    stopLoss: (json['stopLoss'] as num?)?.toDouble(),
    takeProfit: (json['takeProfit'] as num?)?.toDouble(),
    leverage: (json['leverage'] as num?)?.toDouble() ?? 5.0,
    usedMargin: (json['usedMargin'] as num?)?.toDouble() ?? 0.0,
    openTime: json['openTime'] != null ? DateTime.parse(json['openTime'] as String) : DateTime.now(),
  );
}
