import 'enums.dart';

class Instrument {
  final String token;
  final String symbol;
  final String name;
  final Exchange exchange;
  final InstrumentType type;
  final double lotSize;
  final double tickSize;
  final DateTime? expiry;
  final double? strike;
  final int freezeQty;
  final double leverageMultiplier;
  final String? surveillanceTag;
  final bool isSuspended;
  final String? suspensionReason;

  const Instrument({
    required this.token,
    required this.symbol,
    required this.name,
    required this.exchange,
    required this.type,
    this.lotSize = 1.0,
    this.tickSize = 0.05,
    this.expiry,
    this.strike,
    this.freezeQty = 25000,
    this.leverageMultiplier = 5.0,
    this.surveillanceTag,
    this.isSuspended = false,
    this.suspensionReason,
  });

  /// Contract multiplier for F&O / commodities (defaults to lotSize or 1.0)
  double get contractMultiplier => lotSize > 0 ? lotSize : 1.0;

  Instrument copyWith({
    String? token,
    String? symbol,
    String? name,
    Exchange? exchange,
    InstrumentType? type,
    double? lotSize,
    double? tickSize,
    DateTime? expiry,
    double? strike,
    int? freezeQty,
    double? leverageMultiplier,
    String? surveillanceTag,
    bool? isSuspended,
    String? suspensionReason,
  }) {
    return Instrument(
      token: token ?? this.token,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      exchange: exchange ?? this.exchange,
      type: type ?? this.type,
      lotSize: lotSize ?? this.lotSize,
      tickSize: tickSize ?? this.tickSize,
      expiry: expiry ?? this.expiry,
      strike: strike ?? this.strike,
      freezeQty: freezeQty ?? this.freezeQty,
      leverageMultiplier: leverageMultiplier ?? this.leverageMultiplier,
      surveillanceTag: surveillanceTag ?? this.surveillanceTag,
      isSuspended: isSuspended ?? this.isSuspended,
      suspensionReason: suspensionReason ?? this.suspensionReason,
    );
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'symbol': symbol,
    'name': name,
    'exchange': exchange.name,
    'type': type.name,
    'lotSize': lotSize,
    'tickSize': tickSize,
    'expiry': expiry?.toIso8601String(),
    'strike': strike,
    'freezeQty': freezeQty,
    'leverageMultiplier': leverageMultiplier,
    'surveillanceTag': surveillanceTag,
    'isSuspended': isSuspended,
    'suspensionReason': suspensionReason,
  };

  factory Instrument.fromJson(Map<String, dynamic> json) => Instrument(
    token: json['token'] as String,
    symbol: json['symbol'] as String,
    name: json['name'] as String,
    exchange: Exchange.values.byName(json['exchange'] as String),
    type: InstrumentType.values.byName(json['type'] as String),
    lotSize: (json['lotSize'] as num?)?.toDouble() ?? 1.0,
    tickSize: (json['tickSize'] as num?)?.toDouble() ?? 0.05,
    expiry: json['expiry'] != null ? DateTime.parse(json['expiry'] as String) : null,
    strike: (json['strike'] as num?)?.toDouble(),
    freezeQty: (json['freezeQty'] as num?)?.toInt() ?? 25000,
    leverageMultiplier: (json['leverageMultiplier'] as num?)?.toDouble() ?? 5.0,
    surveillanceTag: json['surveillanceTag'] as String?,
    isSuspended: json['isSuspended'] as bool? ?? false,
    suspensionReason: json['suspensionReason'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Instrument && runtimeType == other.runtimeType && token == other.token;

  @override
  int get hashCode => token.hashCode;
}
