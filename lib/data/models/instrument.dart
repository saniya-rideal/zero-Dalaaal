import 'enums.dart';

class Instrument {
  final String token;
  final String symbol;
  final String name;
  final String market; // INDIAN | CRYPTO | FOREX
  final String segment; // EQUITY | COMMODITY | CRYPTO | FOREX
  final Exchange exchange; // Display: NSE | BSE | CRYPTO | FX | etc.
  final InstrumentType type; // EQ | INDEX | CRYPTO | FX | FUT | CE | PE
  final String quoteCurrency;
  final double tickSize;
  final double lotSize;
  final int minQuantity;
  final int quantityStep;
  final double maxLeverage;
  final double defaultLeverage;
  final double takerFeeRate;
  final bool isActive;
  final DateTime? expiry;
  final double? strike;
  final int freezeQty;
  final double leverageMultiplier;
  final String? surveillanceTag;
  final bool isSuspended;
  final String? suspensionReason;
  final List<ProductType>? allowedProducts;
  final List<String>? allowedOrderTypes;
  final bool tradingEnabled;

  const Instrument({
    String? token,
    required this.symbol,
    required this.name,
    this.market = 'INDIAN',
    this.segment = 'EQUITY',
    required this.exchange,
    required this.type,
    this.quoteCurrency = 'INR',
    this.tickSize = 0.05,
    this.lotSize = 1.0,
    this.minQuantity = 1,
    this.quantityStep = 1,
    this.maxLeverage = 5.0,
    this.defaultLeverage = 5.0,
    this.takerFeeRate = 0.0,
    this.isActive = true,
    this.expiry,
    this.strike,
    this.freezeQty = 25000,
    double? leverageMultiplier,
    this.surveillanceTag,
    this.isSuspended = false,
    this.suspensionReason,
    this.allowedProducts,
    this.allowedOrderTypes,
    this.tradingEnabled = true,
  })  : token = token ?? symbol,
        leverageMultiplier = leverageMultiplier ?? maxLeverage;

  /// Clean display name stripping any "(simulated)" or "[simulated]" tags
  String get displayName {
    final clean = name.replaceAll(RegExp(r'\s*[\(\[]simulated[\)\]]', caseSensitive: false), '').trim();
    return clean.isNotEmpty ? clean : symbol;
  }

  /// Contract multiplier for F&O / commodities (defaults to lotSize or 1.0)
  double get contractMultiplier => lotSize > 0 ? lotSize : 1.0;

  String get category => segment;

  bool get isCryptoOrForex {
    final m = market.toUpperCase();
    final s = segment.toUpperCase();
    return m == 'CRYPTO' || m == 'FOREX' || s == 'CRYPTO' || s == 'FOREX';
  }

  /// Safe resolution of allowed products (MIS, CNC, NRML)
  List<ProductType> get effectiveAllowedProducts {
    if (isCryptoOrForex) return const [];
    if (allowedProducts != null && allowedProducts!.isNotEmpty) {
      return allowedProducts!;
    }
    final s = segment.toUpperCase();
    if (s == 'COMMODITY' || type == InstrumentType.FUT || type == InstrumentType.CE || type == InstrumentType.PE) {
      return const [ProductType.MIS, ProductType.NRML];
    }
    return const [ProductType.MIS, ProductType.CNC];
  }

  Instrument copyWith({
    String? token,
    String? symbol,
    String? name,
    String? market,
    String? segment,
    Exchange? exchange,
    InstrumentType? type,
    String? quoteCurrency,
    double? lotSize,
    double? tickSize,
    int? minQuantity,
    int? quantityStep,
    double? maxLeverage,
    double? defaultLeverage,
    double? takerFeeRate,
    bool? isActive,
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
      market: market ?? this.market,
      segment: segment ?? this.segment,
      exchange: exchange ?? this.exchange,
      type: type ?? this.type,
      quoteCurrency: quoteCurrency ?? this.quoteCurrency,
      lotSize: lotSize ?? this.lotSize,
      tickSize: tickSize ?? this.tickSize,
      minQuantity: minQuantity ?? this.minQuantity,
      quantityStep: quantityStep ?? this.quantityStep,
      maxLeverage: maxLeverage ?? this.maxLeverage,
      defaultLeverage: defaultLeverage ?? this.defaultLeverage,
      takerFeeRate: takerFeeRate ?? this.takerFeeRate,
      isActive: isActive ?? this.isActive,
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
    'market': market,
    'segment': segment,
    'exchange': exchange.name,
    'type': type.name,
    'quoteCurrency': quoteCurrency,
    'lotSize': lotSize,
    'tickSize': tickSize,
    'minQuantity': minQuantity,
    'quantityStep': quantityStep,
    'maxLeverage': maxLeverage,
    'defaultLeverage': defaultLeverage,
    'takerFeeRate': takerFeeRate,
    'isActive': isActive,
    'expiry': expiry?.toIso8601String(),
    'strike': strike,
    'freezeQty': freezeQty,
    'leverageMultiplier': leverageMultiplier,
    'surveillanceTag': surveillanceTag,
    'isSuspended': isSuspended,
    'suspensionReason': suspensionReason,
    'allowedProducts': allowedProducts?.map((p) => p.name).toList(),
    'allowedOrderTypes': allowedOrderTypes,
    'tradingEnabled': tradingEnabled,
  };

  factory Instrument.fromJson(Map<String, dynamic> json) {
    final sym = (json['symbol'] ?? json['token'] ?? '').toString().trim();
    final rawTok = (json['token'] ?? '').toString().trim();
    final tok = rawTok.isNotEmpty ? rawTok : sym;

    // Tolerant exchange parsing
    Exchange ex = Exchange.NSE;
    final exRaw = (json['exchange'] ?? '').toString().toUpperCase();
    for (final val in Exchange.values) {
      if (val.name == exRaw) {
        ex = val;
        break;
      }
    }

    // Tolerant instrument type parsing
    InstrumentType it = InstrumentType.EQ;
    final itRaw = (json['type'] ?? '').toString().toUpperCase();
    for (final val in InstrumentType.values) {
      if (val.name == itRaw) {
        it = val;
        break;
      }
    }

    final maxLev = (json['maxLeverage'] ?? json['leverageMultiplier'] as num?)?.toDouble() ?? 5.0;
    final defLev = (json['defaultLeverage'] as num?)?.toDouble() ?? maxLev;

    List<ProductType>? allowedProds;
    if (json['allowedProducts'] is List) {
      allowedProds = (json['allowedProducts'] as List)
          .map((e) => e.toString().toUpperCase())
          .map((name) {
            switch (name) {
              case 'CNC':
                return ProductType.CNC;
              case 'NRML':
                return ProductType.NRML;
              case 'MIS':
              default:
                return ProductType.MIS;
            }
          })
          .toSet()
          .toList();
    }

    List<String>? allowedOrders;
    if (json['allowedOrderTypes'] is List) {
      allowedOrders = (json['allowedOrderTypes'] as List).map((e) => e.toString().toUpperCase()).toList();
    }

    final rawName = (json['name'] ?? sym).toString();
    final cleanName = rawName.replaceAll(RegExp(r'\s*[\(\[]simulated[\)\]]', caseSensitive: false), '').trim();

    return Instrument(
      token: tok,
      symbol: sym,
      name: cleanName.isNotEmpty ? cleanName : sym,
      market: (json['market'] ?? 'INDIAN').toString(),
      segment: (json['segment'] ?? 'EQUITY').toString(),
      exchange: ex,
      type: it,
      quoteCurrency: (json['quoteCurrency'] ?? 'INR').toString(),
      lotSize: (json['lotSize'] as num?)?.toDouble() ?? 1.0,
      tickSize: (json['tickSize'] as num?)?.toDouble() ?? 0.05,
      minQuantity: (json['minQuantity'] as num?)?.toInt() ?? 1,
      quantityStep: (json['quantityStep'] as num?)?.toInt() ?? 1,
      maxLeverage: maxLev,
      defaultLeverage: defLev,
      takerFeeRate: (json['takerFeeRate'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] as bool? ?? true,
      expiry: json['expiry'] != null ? DateTime.tryParse(json['expiry'].toString()) : null,
      strike: (json['strike'] as num?)?.toDouble(),
      freezeQty: (json['freezeQty'] as num?)?.toInt() ?? 25000,
      leverageMultiplier: (json['leverageMultiplier'] as num?)?.toDouble() ?? maxLev,
      surveillanceTag: json['surveillanceTag'] as String?,
      isSuspended: json['isSuspended'] as bool? ?? false,
      suspensionReason: json['suspensionReason'] as String?,
      allowedProducts: allowedProds,
      allowedOrderTypes: allowedOrders,
      tradingEnabled: json['tradingEnabled'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Instrument && runtimeType == other.runtimeType && symbol == other.symbol;

  @override
  int get hashCode => symbol.hashCode;
}
