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
  final double unrealizedPnl;
  final bool isDayPosition;

  const Position({
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
    required this.unrealizedPnl,
    this.isDayPosition = true,
  });

  double get totalPnl => realizedPnl + unrealizedPnl;
  double get currentValue => netQty * ltp;
  double get investedValue => netQty * (buyAvg > 0 ? buyAvg : sellAvg);

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
  );
}
