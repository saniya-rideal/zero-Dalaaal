import 'enums.dart';
import 'instrument.dart';

class Holding {
  final Instrument instrument;
  final int quantity;
  final int t1Quantity;
  final double averagePrice;
  final double ltp;
  final double closePrice;
  final DateTime firstBuyDate;

  const Holding({
    required this.instrument,
    required this.quantity,
    this.t1Quantity = 0,
    required this.averagePrice,
    required this.ltp,
    required this.closePrice,
    required this.firstBuyDate,
  });

  int get totalQuantity => quantity + t1Quantity;
  double get currentPrice => ltp;
  double get investedValue => totalQuantity * averagePrice;
  double get currentValue => totalQuantity * ltp;
  double get totalPnl => currentValue - investedValue;
  double get totalPnlPercent => investedValue > 0 ? (totalPnl / investedValue) * 100 : 0.0;
  double get dayPnl => totalQuantity * (ltp - closePrice);
  double get dayPnlPercent => closePrice > 0 ? ((ltp - closePrice) / closePrice) * 100 : 0.0;
  int get daysHeld => DateTime.now().difference(firstBuyDate).inDays;

  /// Percentage weight of this holding relative to the total portfolio current value
  double allocationWeight(double totalPortfolioValue) =>
      totalPortfolioValue > 0 ? (currentValue / totalPortfolioValue) * 100 : 0.0;

  Holding copyWith({
    Instrument? instrument,
    int? quantity,
    int? t1Quantity,
    double? averagePrice,
    double? ltp,
    double? closePrice,
    DateTime? firstBuyDate,
  }) {
    return Holding(
      instrument: instrument ?? this.instrument,
      quantity: quantity ?? this.quantity,
      t1Quantity: t1Quantity ?? this.t1Quantity,
      averagePrice: averagePrice ?? this.averagePrice,
      ltp: ltp ?? this.ltp,
      closePrice: closePrice ?? this.closePrice,
      firstBuyDate: firstBuyDate ?? this.firstBuyDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'instrument': instrument.toJson(),
    'quantity': quantity,
    't1Quantity': t1Quantity,
    'averagePrice': averagePrice,
    'ltp': ltp,
    'closePrice': closePrice,
    'firstBuyDate': firstBuyDate.toIso8601String(),
  };

  factory Holding.fromJson(Map<String, dynamic> json) {
    Instrument inst;
    if (json['instrument'] is Map<String, dynamic>) {
      inst = Instrument.fromJson(json['instrument'] as Map<String, dynamic>);
    } else {
      final sym = (json['symbol'] ?? json['instrument'] ?? '').toString();
      inst = Instrument(
        token: (json['token'] ?? json['instrumentToken'] ?? sym).toString(),
        symbol: sym,
        name: (json['name'] ?? sym).toString(),
        exchange: Exchange.NSE,
        type: InstrumentType.EQ,
      );
    }

    return Holding(
      instrument: inst,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      t1Quantity: (json['t1Quantity'] as num?)?.toInt() ?? 0,
      averagePrice: (json['averagePrice'] as num?)?.toDouble() ?? 0.0,
      ltp: (json['ltp'] as num?)?.toDouble() ?? 0.0,
      closePrice: (json['closePrice'] as num?)?.toDouble() ?? (json['ltp'] as num?)?.toDouble() ?? 0.0,
      firstBuyDate: DateTime.tryParse((json['firstBuyDate'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}

class PortfolioSummary {
  final double totalInvestment;
  final double currentValue;
  final double totalPnl;
  final double totalPnlPercent;
  final double todayPnl;
  final double todayPnlPercent;

  const PortfolioSummary({
    required this.totalInvestment,
    required this.currentValue,
    required this.totalPnl,
    required this.totalPnlPercent,
    required this.todayPnl,
    required this.todayPnlPercent,
  });

  factory PortfolioSummary.fromHoldings(List<Holding> holdings) {
    double totalInv = 0;
    double currentVal = 0;
    double todayChange = 0;

    for (final h in holdings) {
      totalInv += h.investedValue;
      currentVal += h.currentValue;
      todayChange += h.dayPnl;
    }

    final pnl = currentVal - totalInv;
    final pnlPct = totalInv > 0 ? (pnl / totalInv) * 100 : 0.0;
    final prevDayVal = currentVal - todayChange;
    final dayPct = prevDayVal > 0 ? (todayChange / prevDayVal) * 100 : 0.0;

    return PortfolioSummary(
      totalInvestment: totalInv,
      currentValue: currentVal,
      totalPnl: pnl,
      totalPnlPercent: pnlPct,
      todayPnl: todayChange,
      todayPnlPercent: dayPct,
    );
  }

  Map<String, dynamic> toJson() => {
    'totalInvestment': totalInvestment,
    'currentValue': currentValue,
    'totalPnl': totalPnl,
    'totalPnlPercent': totalPnlPercent,
    'todayPnl': todayPnl,
    'todayPnlPercent': todayPnlPercent,
  };

  factory PortfolioSummary.fromJson(Map<String, dynamic> json) => PortfolioSummary(
    totalInvestment: (json['totalInvestment'] as num).toDouble(),
    currentValue: (json['currentValue'] as num).toDouble(),
    totalPnl: (json['totalPnl'] as num).toDouble(),
    totalPnlPercent: (json['totalPnlPercent'] as num).toDouble(),
    todayPnl: (json['todayPnl'] as num).toDouble(),
    todayPnlPercent: (json['todayPnlPercent'] as num).toDouble(),
  );
}
