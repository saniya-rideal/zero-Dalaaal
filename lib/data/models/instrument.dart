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
  });

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
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Instrument && runtimeType == other.runtimeType && token == other.token;

  @override
  int get hashCode => token.hashCode;
}
