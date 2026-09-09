import 'package:flutter/foundation.dart';

enum HeatmapTimeframe {
  oneDay('1D', 'Today'),
  oneWeek('1W', '1 Week'),
  oneMonth('1M', '1 Month'),
  oneYear('1Y', '1 Year');

  final String label;
  final String description;
  const HeatmapTimeframe(this.label, this.description);
}

enum HeatmapScope {
  allSectors('All Sectors'),
  nifty50('Nifty 50'),
  gainersOnly('Top Gainers'),
  losersOnly('Top Losers');

  final String label;
  const HeatmapScope(this.label);
}

enum HeatmapViewMode {
  treemap('Treemap'),
  sectorGrid('Sector Grid');

  final String label;
  const HeatmapViewMode(this.label);
}

@immutable
class HeatmapStockItem {
  final String token;
  final String symbol;
  final String name;
  final String sector;
  final double marketCap; // in ₹ Lakh Cr
  final double weight; // Sector or Index weight %
  final double ltp;
  final double change;
  final double changePercent;
  final double changePercent1W;
  final double changePercent1M;
  final double changePercent1Y;
  final int volume;
  final double dayHigh;
  final double dayLow;
  final bool isNifty50;

  const HeatmapStockItem({
    required this.token,
    required this.symbol,
    required this.name,
    required this.sector,
    required this.marketCap,
    required this.weight,
    required this.ltp,
    required this.change,
    required this.changePercent,
    required this.changePercent1W,
    required this.changePercent1M,
    required this.changePercent1Y,
    required this.volume,
    required this.dayHigh,
    required this.dayLow,
    this.isNifty50 = true,
  });

  double getEffectiveChange(HeatmapTimeframe timeframe) {
    switch (timeframe) {
      case HeatmapTimeframe.oneDay:
        return changePercent;
      case HeatmapTimeframe.oneWeek:
        return changePercent1W;
      case HeatmapTimeframe.oneMonth:
        return changePercent1M;
      case HeatmapTimeframe.oneYear:
        return changePercent1Y;
    }
  }

  HeatmapStockItem copyWith({
    String? token,
    String? symbol,
    String? name,
    String? sector,
    double? marketCap,
    double? weight,
    double? ltp,
    double? change,
    double? changePercent,
    double? changePercent1W,
    double? changePercent1M,
    double? changePercent1Y,
    int? volume,
    double? dayHigh,
    double? dayLow,
    bool? isNifty50,
  }) {
    return HeatmapStockItem(
      token: token ?? this.token,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      sector: sector ?? this.sector,
      marketCap: marketCap ?? this.marketCap,
      weight: weight ?? this.weight,
      ltp: ltp ?? this.ltp,
      change: change ?? this.change,
      changePercent: changePercent ?? this.changePercent,
      changePercent1W: changePercent1W ?? this.changePercent1W,
      changePercent1M: changePercent1M ?? this.changePercent1M,
      changePercent1Y: changePercent1Y ?? this.changePercent1Y,
      volume: volume ?? this.volume,
      dayHigh: dayHigh ?? this.dayHigh,
      dayLow: dayLow ?? this.dayLow,
      isNifty50: isNifty50 ?? this.isNifty50,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'symbol': symbol,
      'name': name,
      'sector': sector,
      'marketCap': marketCap,
      'weight': weight,
      'ltp': ltp,
      'change': change,
      'changePercent': changePercent,
      'changePercent1W': changePercent1W,
      'changePercent1M': changePercent1M,
      'changePercent1Y': changePercent1Y,
      'volume': volume,
      'dayHigh': dayHigh,
      'dayLow': dayLow,
      'isNifty50': isNifty50,
    };
  }

  factory HeatmapStockItem.fromJson(Map<String, dynamic> json) {
    return HeatmapStockItem(
      token: json['token'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      sector: json['sector'] as String,
      marketCap: (json['marketCap'] as num).toDouble(),
      weight: (json['weight'] as num).toDouble(),
      ltp: (json['ltp'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      changePercent: (json['changePercent'] as num).toDouble(),
      changePercent1W: (json['changePercent1W'] as num).toDouble(),
      changePercent1M: (json['changePercent1M'] as num).toDouble(),
      changePercent1Y: (json['changePercent1Y'] as num).toDouble(),
      volume: json['volume'] as int,
      dayHigh: (json['dayHigh'] as num).toDouble(),
      dayLow: (json['dayLow'] as num).toDouble(),
      isNifty50: json['isNifty50'] as bool? ?? true,
    );
  }
}

@immutable
class SectorPerformance {
  final String name;
  final String indexSymbol;
  final double weight; // Sector weight % in overall market
  final double avgChangePercent;
  final int advancesCount;
  final int declinesCount;
  final int unchangedCount;
  final List<HeatmapStockItem> stocks;

  const SectorPerformance({
    required this.name,
    required this.indexSymbol,
    required this.weight,
    required this.avgChangePercent,
    required this.advancesCount,
    required this.declinesCount,
    required this.unchangedCount,
    required this.stocks,
  });

  SectorPerformance copyWith({
    String? name,
    String? indexSymbol,
    double? weight,
    double? avgChangePercent,
    int? advancesCount,
    int? declinesCount,
    int? unchangedCount,
    List<HeatmapStockItem>? stocks,
  }) {
    return SectorPerformance(
      name: name ?? this.name,
      indexSymbol: indexSymbol ?? this.indexSymbol,
      weight: weight ?? this.weight,
      avgChangePercent: avgChangePercent ?? this.avgChangePercent,
      advancesCount: advancesCount ?? this.advancesCount,
      declinesCount: declinesCount ?? this.declinesCount,
      unchangedCount: unchangedCount ?? this.unchangedCount,
      stocks: stocks ?? this.stocks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'indexSymbol': indexSymbol,
      'weight': weight,
      'avgChangePercent': avgChangePercent,
      'advancesCount': advancesCount,
      'declinesCount': declinesCount,
      'unchangedCount': unchangedCount,
      'stocks': stocks.map((s) => s.toJson()).toList(),
    };
  }

  factory SectorPerformance.fromJson(Map<String, dynamic> json) {
    return SectorPerformance(
      name: json['name'] as String,
      indexSymbol: json['indexSymbol'] as String,
      weight: (json['weight'] as num).toDouble(),
      avgChangePercent: (json['avgChangePercent'] as num).toDouble(),
      advancesCount: json['advancesCount'] as int,
      declinesCount: json['declinesCount'] as int,
      unchangedCount: json['unchangedCount'] as int,
      stocks: (json['stocks'] as List<dynamic>)
          .map((item) => HeatmapStockItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
