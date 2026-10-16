import 'enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

/// The type of instrument in the strategy leg.
enum StrategyLegType {
  ce('Call (CE)'),
  pe('Put (PE)'),
  futures('Futures'),
  stock('Stock');

  final String label;
  const StrategyLegType(this.label);
}

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

/// A single leg in an option strategy.
class OptionStrategyLeg {
  final TransactionType side; // BUY or SELL
  final StrategyLegType type; // CE, PE, FUTURES, STOCK
  final double strike; // Strike price (0 for stock/futures)
  final double premium; // Premium paid (BUY) or received (SELL) per unit
  final int quantity; // Number of units
  final int lotSize; // Lot size (1 for stocks)

  const OptionStrategyLeg({
    required this.side,
    required this.type,
    required this.strike,
    required this.premium,
    required this.quantity,
    this.lotSize = 1,
  });

  int get totalUnits => quantity * lotSize;

  /// Net debit/credit for this leg (positive = paid, negative = received)
  double get netPremium =>
      side == TransactionType.BUY ? premium * totalUnits : -premium * totalUnits;
}

/// A named multi-leg option strategy.
class OptionStrategy {
  final String name;
  final String underlying;
  final double spotPrice;
  final String expiry;
  final List<OptionStrategyLeg> legs;

  const OptionStrategy({
    required this.name,
    required this.underlying,
    required this.spotPrice,
    required this.expiry,
    required this.legs,
  });

  /// Total premium paid (positive) or received (negative) for the strategy.
  double get netCost => legs.fold(0.0, (sum, l) => sum + l.netPremium);

  /// Computes payoff curve points and metrics for this strategy.
  StrategyMetrics analyze() {
    final points = StrategyPayoffEngine.computePayoff(this);
    return StrategyPayoffEngine.computeMetrics(this, points);
  }

  static OptionStrategy bullCallSpread({
    required String underlying,
    required double spot,
    required String expiry,
    double atmPremium = 180.0,
    double otmPremium = 80.0,
    int lotSize = 25,
  }) =>
      StrategyPayoffEngine.bullCallSpread(
        underlying: underlying,
        spot: spot,
        expiry: expiry,
        atmPremium: atmPremium,
        otmPremium: otmPremium,
        lotSize: lotSize,
      );

  static OptionStrategy bearPutSpread({
    required String underlying,
    required double spot,
    required String expiry,
    double atmPremium = 175.0,
    double otmPremium = 75.0,
    int lotSize = 25,
  }) =>
      StrategyPayoffEngine.bearPutSpread(
        underlying: underlying,
        spot: spot,
        expiry: expiry,
        atmPremium: atmPremium,
        otmPremium: otmPremium,
        lotSize: lotSize,
      );

  static OptionStrategy longStraddle({
    required String underlying,
    required double spot,
    required String expiry,
    double callPremium = 180.0,
    double putPremium = 175.0,
    int lotSize = 25,
  }) =>
      StrategyPayoffEngine.longStraddle(
        underlying: underlying,
        spot: spot,
        expiry: expiry,
        callPremium: callPremium,
        putPremium: putPremium,
        lotSize: lotSize,
      );

  static OptionStrategy ironCondor({
    required String underlying,
    required double spot,
    required String expiry,
    int lotSize = 25,
  }) =>
      StrategyPayoffEngine.ironCondor(
        underlying: underlying,
        spot: spot,
        expiry: expiry,
        lotSize: lotSize,
      );
}

/// A single (spotPrice, pnl) data point on the payoff curve.
class PayoffPoint {
  final double spot;
  final double pnl;

  const PayoffPoint(this.spot, this.pnl);
}

/// Computed analytics for a strategy payoff.
class StrategyMetrics {
  final double maxProfit; // double.infinity for unlimited
  final double maxLoss; // negative, double.negativeInfinity for unlimited
  final List<double> breakevens;
  final double riskRewardRatio; // maxProfit / |maxLoss|, 0 if undefined
  final bool isMaxProfitUnlimited;
  final bool isMaxLossUnlimited;

  const StrategyMetrics({
    required this.maxProfit,
    required this.maxLoss,
    required this.breakevens,
    required this.riskRewardRatio,
    this.isMaxProfitUnlimited = false,
    this.isMaxLossUnlimited = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Payoff Engine
// ─────────────────────────────────────────────────────────────────────────────

class StrategyPayoffEngine {
  static const int _numPoints = 200;
  static const double _rangePercent = 0.25; // ±25% of spot

  /// Compute the P&L at expiry for a single leg at a given spot price.
  static double _legPnl(OptionStrategyLeg leg, double spot) {
    final units = leg.totalUnits;
    final premium = leg.premium;
    final strike = leg.strike;
    final isBuy = leg.side == TransactionType.BUY;

    switch (leg.type) {
      case StrategyLegType.ce:
        // Call intrinsic value at expiry
        final intrinsic = (spot - strike).clamp(0.0, double.infinity);
        return isBuy
            ? (intrinsic - premium) * units
            : (premium - intrinsic) * units;

      case StrategyLegType.pe:
        // Put intrinsic value at expiry
        final intrinsic = (strike - spot).clamp(0.0, double.infinity);
        return isBuy
            ? (intrinsic - premium) * units
            : (premium - intrinsic) * units;

      case StrategyLegType.futures:
        // Futures P&L: difference from entry price (strike = entry price)
        return isBuy ? (spot - strike) * units : (strike - spot) * units;

      case StrategyLegType.stock:
        // Stock P&L: difference from entry price (strike = purchase price)
        return isBuy
            ? (spot - strike - premium) * units
            : (premium - (spot - strike)) * units;
    }
  }

  /// Compute the total strategy P&L at a given spot price.
  static double strategyPnlAtSpot(OptionStrategy strategy, double spot) {
    return strategy.legs.fold(0.0, (sum, leg) => sum + _legPnl(leg, spot));
  }

  /// Compute 200 P&L data points across a ±25% spot range.
  static List<PayoffPoint> computePayoff(OptionStrategy strategy) {
    final spot = strategy.spotPrice;
    final minSpot = spot * (1 - _rangePercent);
    final maxSpot = spot * (1 + _rangePercent);
    final step = (maxSpot - minSpot) / (_numPoints - 1);

    return List.generate(_numPoints, (i) {
      final s = minSpot + i * step;
      return PayoffPoint(s, strategyPnlAtSpot(strategy, s));
    });
  }

  /// Derive breakeven crossings from a list of payoff points.
  static List<double> _findBreakevens(List<PayoffPoint> points) {
    final breakevens = <double>[];
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      // Sign change → crossing zero
      if ((prev.pnl < 0 && curr.pnl >= 0) || (prev.pnl >= 0 && curr.pnl < 0)) {
        // Linear interpolation
        final t = prev.pnl.abs() / (prev.pnl.abs() + curr.pnl.abs());
        final be = prev.spot + t * (curr.spot - prev.spot);
        breakevens.add(double.parse(be.toStringAsFixed(2)));
      }
    }
    return breakevens;
  }

  /// Compute strategy metrics from the payoff points.
  static StrategyMetrics computeMetrics(
      OptionStrategy strategy, List<PayoffPoint> points) {
    if (points.isEmpty) {
      return const StrategyMetrics(
        maxProfit: 0,
        maxLoss: 0,
        breakevens: [],
        riskRewardRatio: 0,
      );
    }

    final pnls = points.map((p) => p.pnl).toList();
    final maxP = pnls.reduce((a, b) => a > b ? a : b);
    final maxL = pnls.reduce((a, b) => a < b ? a : b);
    final breakevens = _findBreakevens(points);

    // Determine if profit/loss are "at the boundary" of the range
    // (meaning they may be unlimited beyond our computed range)
    final firstPnl = points.first.pnl;
    final lastPnl = points.last.pnl;
    final isProfitUnlimited = lastPnl >= maxP * 0.98 || firstPnl >= maxP * 0.98;
    final isLossUnlimited = lastPnl <= maxL * 0.98 || firstPnl <= maxL * 0.98;

    final rrRatio = (maxP > 0 && maxL < 0)
        ? double.parse((maxP / maxL.abs()).toStringAsFixed(2))
        : 0.0;

    return StrategyMetrics(
      maxProfit: maxP,
      maxLoss: maxL,
      breakevens: breakevens,
      riskRewardRatio: rrRatio,
      isMaxProfitUnlimited: isProfitUnlimited,
      isMaxLossUnlimited: isLossUnlimited,
    );
  }

  // ─── Pre-built Strategy Factories ───────────────────────────────────────

  /// Bull Call Spread: Buy ATM Call + Sell OTM Call.
  static OptionStrategy bullCallSpread({
    required String underlying,
    required double spot,
    required String expiry,
    double atmPremium = 180.0,
    double otmPremium = 80.0,
    int lotSize = 25,
  }) {
    final atmStrike = (spot / 50).round() * 50.0;
    final otmStrike = atmStrike + 100.0;
    return OptionStrategy(
      name: 'Bull Call Spread',
      underlying: underlying,
      spotPrice: spot,
      expiry: expiry,
      legs: [
        OptionStrategyLeg(
          side: TransactionType.BUY,
          type: StrategyLegType.ce,
          strike: atmStrike,
          premium: atmPremium,
          quantity: 1,
          lotSize: lotSize,
        ),
        OptionStrategyLeg(
          side: TransactionType.SELL,
          type: StrategyLegType.ce,
          strike: otmStrike,
          premium: otmPremium,
          quantity: 1,
          lotSize: lotSize,
        ),
      ],
    );
  }

  /// Bear Put Spread: Buy OTM Put + Sell Further OTM Put.
  static OptionStrategy bearPutSpread({
    required String underlying,
    required double spot,
    required String expiry,
    double atmPremium = 175.0,
    double otmPremium = 75.0,
    int lotSize = 25,
  }) {
    final atmStrike = (spot / 50).round() * 50.0;
    final otmStrike = atmStrike - 100.0;
    return OptionStrategy(
      name: 'Bear Put Spread',
      underlying: underlying,
      spotPrice: spot,
      expiry: expiry,
      legs: [
        OptionStrategyLeg(
          side: TransactionType.BUY,
          type: StrategyLegType.pe,
          strike: atmStrike,
          premium: atmPremium,
          quantity: 1,
          lotSize: lotSize,
        ),
        OptionStrategyLeg(
          side: TransactionType.SELL,
          type: StrategyLegType.pe,
          strike: otmStrike,
          premium: otmPremium,
          quantity: 1,
          lotSize: lotSize,
        ),
      ],
    );
  }

  /// Long Straddle: Buy ATM Call + Buy ATM Put.
  static OptionStrategy longStraddle({
    required String underlying,
    required double spot,
    required String expiry,
    double callPremium = 180.0,
    double putPremium = 175.0,
    int lotSize = 25,
  }) {
    final atmStrike = (spot / 50).round() * 50.0;
    return OptionStrategy(
      name: 'Long Straddle',
      underlying: underlying,
      spotPrice: spot,
      expiry: expiry,
      legs: [
        OptionStrategyLeg(
          side: TransactionType.BUY,
          type: StrategyLegType.ce,
          strike: atmStrike,
          premium: callPremium,
          quantity: 1,
          lotSize: lotSize,
        ),
        OptionStrategyLeg(
          side: TransactionType.BUY,
          type: StrategyLegType.pe,
          strike: atmStrike,
          premium: putPremium,
          quantity: 1,
          lotSize: lotSize,
        ),
      ],
    );
  }

  /// Iron Condor: Sell OTM Call + Buy further OTM Call + Sell OTM Put + Buy further OTM Put.
  static OptionStrategy ironCondor({
    required String underlying,
    required double spot,
    required String expiry,
    int lotSize = 25,
  }) {
    final atm = (spot / 50).round() * 50.0;
    return OptionStrategy(
      name: 'Iron Condor',
      underlying: underlying,
      spotPrice: spot,
      expiry: expiry,
      legs: [
        OptionStrategyLeg(side: TransactionType.SELL, type: StrategyLegType.ce, strike: atm + 100, premium: 90, quantity: 1, lotSize: lotSize),
        OptionStrategyLeg(side: TransactionType.BUY,  type: StrategyLegType.ce, strike: atm + 200, premium: 40, quantity: 1, lotSize: lotSize),
        OptionStrategyLeg(side: TransactionType.SELL, type: StrategyLegType.pe, strike: atm - 100, premium: 85, quantity: 1, lotSize: lotSize),
        OptionStrategyLeg(side: TransactionType.BUY,  type: StrategyLegType.pe, strike: atm - 200, premium: 35, quantity: 1, lotSize: lotSize),
      ],
    );
  }
}
