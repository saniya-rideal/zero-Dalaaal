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

  factory Position.fromJson(Map<String, dynamic> json) {
    final pId = (json['id'] ?? json['_id'] ?? '').toString();

    // Instrument parsing
    Instrument inst;
    if (json['instrument'] is Map<String, dynamic>) {
      inst = Instrument.fromJson(json['instrument'] as Map<String, dynamic>);
    } else {
      final sym = (json['symbol'] ?? json['instrumentToken'] ?? '').toString();
      inst = Instrument(
        symbol: sym,
        token: sym,
        name: sym,
        exchange: Exchange.NSE,
        type: InstrumentType.EQ,
      );
    }

    // Product parsing
    ProductType prod = ProductType.MIS;
    final prodRaw = (json['product'] ?? '').toString().toUpperCase();
    for (final val in ProductType.values) {
      if (val.name == prodRaw) {
        prod = val;
        break;
      }
    }

    // Quantities
    int net = (json['netQty'] ?? json['quantity'] as num?)?.toInt() ?? 0;
    final sideRaw = (json['side'] ?? '').toString().toUpperCase();
    if (sideRaw == 'SELL' && net > 0) {
      net = -net;
    }

    final bQty = (json['buyQty'] as num?)?.toInt() ?? (net > 0 ? net : 0);
    final sQty = (json['sellQty'] as num?)?.toInt() ?? (net < 0 ? net.abs() : 0);

    final entry = (json['entryPrice'] ?? json['avgPrice'] ?? json['buyAvg'] as num?)?.toDouble() ?? 0.0;
    final bAvg = (json['buyAvg'] as num?)?.toDouble() ?? (net > 0 ? entry : 0.0);
    final sAvg = (json['sellAvg'] as num?)?.toDouble() ?? (net < 0 ? entry : 0.0);

    final lastPrice = (json['ltp'] ?? json['currentPrice'] ?? json['markPrice'] as num?)?.toDouble() ?? entry;
    final rPnl = (json['realizedPnl'] as num?)?.toDouble() ?? 0.0;
    final uPnl = (json['unrealizedPnl'] as num?)?.toDouble() ?? 0.0;

    final lev = (json['leverage'] as num?)?.toDouble() ?? inst.maxLeverage;
    final margin = (json['usedMargin'] ?? json['margin'] as num?)?.toDouble() ?? 0.0;

    DateTime ot;
    final rawDate = json['openTime'] ?? json['createdAt'] ?? json['timestamp'];
    if (rawDate != null) {
      ot = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
    } else {
      ot = DateTime.now();
    }

    return Position(
      id: pId,
      instrument: inst,
      product: prod,
      buyQty: bQty,
      sellQty: sQty,
      netQty: net,
      buyAvg: bAvg,
      sellAvg: sAvg,
      ltp: lastPrice,
      realizedPnl: rPnl,
      unrealizedPnl: uPnl,
      isDayPosition: json['isDayPosition'] as bool? ?? true,
      stopLoss: (json['stopLoss'] as num?)?.toDouble(),
      takeProfit: (json['takeProfit'] as num?)?.toDouble(),
      leverage: lev,
      usedMargin: margin,
      openTime: ot,
    );
  }
}
