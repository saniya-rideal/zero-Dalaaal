import 'dart:math';
import '../../data/models/enums.dart';
import '../../data/models/funds.dart';

class FillCalculationResult {
  final int newNetQty;
  final double newEntryPrice;
  final double newRealizedPnl;
  final double realizedPnlDelta;
  final int closedQty;
  final bool isReversal;

  const FillCalculationResult({
    required this.newNetQty,
    required this.newEntryPrice,
    required this.newRealizedPnl,
    required this.realizedPnlDelta,
    required this.closedQty,
    required this.isReversal,
  });
}

class SlTpValidationResult {
  final bool isValid;
  final String? errorMessage;

  const SlTpValidationResult({required this.isValid, this.errorMessage});

  static const valid = SlTpValidationResult(isValid: true);
}

class LedgerReconciliationResult {
  final double calculatedBalance;
  final double expectedBalance;
  final bool isReconciled;
  final double difference;

  const LedgerReconciliationResult({
    required this.calculatedBalance,
    required this.expectedBalance,
    required this.isReconciled,
    required this.difference,
  });
}

class FinancialCalculationService {
  FinancialCalculationService._();

  // ─── 1. Order Calculations ──────────────────────────────────────────────────

  /// Order value = price × quantity × contract multiplier
  static double calculateOrderValue({
    required double price,
    required int quantity,
    double contractMultiplier = 1.0,
  }) {
    final multiplier = contractMultiplier > 0 ? contractMultiplier : 1.0;
    return price * quantity * multiplier;
  }

  /// Required margin using exact server-side specification
  static double calculateRequiredMargin({
    required double price,
    required int quantity,
    required ProductType product,
    required InstrumentType instrumentType,
    required double leverageMultiplier,
    double contractMultiplier = 1.0,
  }) {
    final totalOrderValue = calculateOrderValue(
      price: price,
      quantity: quantity,
      contractMultiplier: contractMultiplier,
    );

    if (product == ProductType.CNC) {
      // 100% margin for cash delivery
      return totalOrderValue;
    } else if (product == ProductType.MIS) {
      // Intraday equity: 5x leverage max (20% margin) under SEBI peak margin rules
      final leverage = leverageMultiplier > 0 ? leverageMultiplier : 5.0;
      return totalOrderValue / leverage;
    } else {
      // Derivatives / NRML
      if (instrumentType == InstrumentType.CE || instrumentType == InstrumentType.PE) {
        // Options Buy requires 100% premium margin
        return totalOrderValue;
      }
      final leverage = leverageMultiplier > 0 ? leverageMultiplier : 5.0;
      return totalOrderValue / leverage;
    }
  }

  /// Stop-Loss & Take-Profit distances validation obeying instrument rules and circuits
  static SlTpValidationResult validateSlTpDistances({
    required double entryPrice,
    required TransactionType side,
    double? stopLoss,
    double? takeProfit,
    required double tickSize,
    double? lowerCircuit,
    double? upperCircuit,
  }) {
    if (entryPrice <= 0) {
      return const SlTpValidationResult(isValid: false, errorMessage: 'Entry price must be positive.');
    }
    final effectiveTick = tickSize > 0 ? tickSize : 0.05;

    // Validate Stop-Loss
    if (stopLoss != null && stopLoss > 0) {
      if (side == TransactionType.BUY) {
        if (stopLoss >= entryPrice) {
          return const SlTpValidationResult(
            isValid: false,
            errorMessage: 'Stop-loss must be strictly below entry price for Buy (Long) positions.',
          );
        }
        if ((entryPrice - stopLoss) < effectiveTick) {
          return SlTpValidationResult(
            isValid: false,
            errorMessage: 'Stop-loss distance must be at least one tick size (₹$effectiveTick).',
          );
        }
      } else {
        if (stopLoss <= entryPrice) {
          return const SlTpValidationResult(
            isValid: false,
            errorMessage: 'Stop-loss must be strictly above entry price for Sell (Short) positions.',
          );
        }
        if ((stopLoss - entryPrice) < effectiveTick) {
          return SlTpValidationResult(
            isValid: false,
            errorMessage: 'Stop-loss distance must be at least one tick size (₹$effectiveTick).',
          );
        }
      }

      if (lowerCircuit != null && stopLoss < lowerCircuit) {
        return SlTpValidationResult(
          isValid: false,
          errorMessage: 'Stop-loss cannot be outside lower circuit limit (₹$lowerCircuit).',
        );
      }
      if (upperCircuit != null && stopLoss > upperCircuit) {
        return SlTpValidationResult(
          isValid: false,
          errorMessage: 'Stop-loss cannot be outside upper circuit limit (₹$upperCircuit).',
        );
      }
    }

    // Validate Take-Profit
    if (takeProfit != null && takeProfit > 0) {
      if (side == TransactionType.BUY) {
        if (takeProfit <= entryPrice) {
          return const SlTpValidationResult(
            isValid: false,
            errorMessage: 'Target price must be strictly above entry price for Buy (Long) positions.',
          );
        }
        if ((takeProfit - entryPrice) < effectiveTick) {
          return SlTpValidationResult(
            isValid: false,
            errorMessage: 'Target distance must be at least one tick size (₹$effectiveTick).',
          );
        }
      } else {
        if (takeProfit >= entryPrice) {
          return const SlTpValidationResult(
            isValid: false,
            errorMessage: 'Target price must be strictly below entry price for Sell (Short) positions.',
          );
        }
        if ((entryPrice - takeProfit) < effectiveTick) {
          return SlTpValidationResult(
            isValid: false,
            errorMessage: 'Target distance must be at least one tick size (₹$effectiveTick).',
          );
        }
      }

      if (lowerCircuit != null && takeProfit < lowerCircuit) {
        return SlTpValidationResult(
          isValid: false,
          errorMessage: 'Target price cannot be outside lower circuit limit (₹$lowerCircuit).',
        );
      }
      if (upperCircuit != null && takeProfit > upperCircuit) {
        return SlTpValidationResult(
          isValid: false,
          errorMessage: 'Target price cannot be outside upper circuit limit (₹$upperCircuit).',
        );
      }
    }

    return SlTpValidationResult.valid;
  }

  /// Deferred final-stage rounding: maintains full 64-bit IEEE precision during calculation
  static double roundToPrecision(double value, [int decimals = 2]) {
    final mod = pow(10.0, decimals).toDouble();
    return (value * mod).roundToDouble() / mod;
  }

  // ─── 2. P&L Engine ──────────────────────────────────────────────────────────

  /// Unrealized P&L: direction and contract multiplier aware
  /// Long: (ltp - entryPrice) * netQty * multiplier
  /// Short: (entryPrice - ltp) * netQty.abs() * multiplier = netQty * (ltp - entryPrice) * multiplier
  static double calculateUnrealizedPnl({
    required int netQty,
    required double entryPrice,
    required double ltp,
    double contractMultiplier = 1.0,
  }) {
    if (netQty == 0 || entryPrice <= 0 || ltp <= 0) return 0.0;
    final multiplier = contractMultiplier > 0 ? contractMultiplier : 1.0;
    return netQty * (ltp - entryPrice) * multiplier;
  }

  /// Evaluates a fill against an existing position:
  /// - Increasing position: Computes new weighted average entry price. Realized PnL is unchanged.
  /// - Partial close: Realizes PnL on the closed portion. Remaining position entry price is preserved!
  /// - Full close: Realizes PnL on entire position. Net quantity becomes 0.
  /// - Position flip/reversal: Realizes PnL on old position. New opposite position starts at fill price.
  static FillCalculationResult calculatePositionFill({
    required int currentNetQty,
    required double currentEntryPrice,
    required double currentRealizedPnl,
    required TransactionType fillSide,
    required int fillQty,
    required double fillPrice,
    double contractMultiplier = 1.0,
  }) {
    final multiplier = contractMultiplier > 0 ? contractMultiplier : 1.0;
    final signedFillQty = fillSide == TransactionType.BUY ? fillQty : -fillQty;

    // Case 1: Brand new position
    if (currentNetQty == 0) {
      return FillCalculationResult(
        newNetQty: signedFillQty,
        newEntryPrice: fillPrice,
        newRealizedPnl: currentRealizedPnl,
        realizedPnlDelta: 0.0,
        closedQty: 0,
        isReversal: false,
      );
    }

    final isLong = currentNetQty > 0;
    final isSameDirection = (isLong && fillSide == TransactionType.BUY) ||
        (!isLong && fillSide == TransactionType.SELL);

    // Case 2: Adding to existing position (Long + Buy OR Short + Sell)
    if (isSameDirection) {
      final oldTotalUnits = currentNetQty.abs();
      final newTotalUnits = oldTotalUnits + fillQty;
      final weightedAvg = ((currentEntryPrice * oldTotalUnits) + (fillPrice * fillQty)) / newTotalUnits;

      return FillCalculationResult(
        newNetQty: isLong ? newTotalUnits : -newTotalUnits,
        newEntryPrice: weightedAvg,
        newRealizedPnl: currentRealizedPnl,
        realizedPnlDelta: 0.0,
        closedQty: 0,
        isReversal: false,
      );
    }

    // Case 3: Opposite side fill (Closing or Reversing)
    final existingUnits = currentNetQty.abs();

    if (fillQty < existingUnits) {
      // 3A: Partial close
      final closedQty = fillQty;
      final remainingUnits = existingUnits - closedQty;
      // Realized PnL = (exitPrice - entryPrice) * closedQty * multiplier * (isLong ? 1 : -1)
      final pnlDelta = (fillPrice - currentEntryPrice) * closedQty * multiplier * (isLong ? 1.0 : -1.0);

      return FillCalculationResult(
        newNetQty: isLong ? remainingUnits : -remainingUnits,
        newEntryPrice: currentEntryPrice, // Entry price on remaining units remains untouched!
        newRealizedPnl: currentRealizedPnl + pnlDelta,
        realizedPnlDelta: pnlDelta,
        closedQty: closedQty,
        isReversal: false,
      );
    } else if (fillQty == existingUnits) {
      // 3B: Exact full close
      final closedQty = fillQty;
      final pnlDelta = (fillPrice - currentEntryPrice) * closedQty * multiplier * (isLong ? 1.0 : -1.0);

      return FillCalculationResult(
        newNetQty: 0,
        newEntryPrice: 0.0,
        newRealizedPnl: currentRealizedPnl + pnlDelta,
        realizedPnlDelta: pnlDelta,
        closedQty: closedQty,
        isReversal: false,
      );
    } else {
      // 3C: Position reversal / flip (e.g. Long 10, Sell 15 -> Closes 10 Long, Opens 5 Short)
      final closedQty = existingUnits;
      final pnlDelta = (fillPrice - currentEntryPrice) * closedQty * multiplier * (isLong ? 1.0 : -1.0);
      final reversedUnits = fillQty - existingUnits;
      final newDirectionSigned = fillSide == TransactionType.BUY ? reversedUnits : -reversedUnits;

      return FillCalculationResult(
        newNetQty: newDirectionSigned,
        newEntryPrice: fillPrice, // Reversal begins at current fill price
        newRealizedPnl: currentRealizedPnl + pnlDelta,
        realizedPnlDelta: pnlDelta,
        closedQty: closedQty,
        isReversal: true,
      );
    }
  }

  /// Currency conversion to INR for foreign / global assets
  static double convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
    double exchangeRate = 83.50, // Default USD/INR
  }) {
    if (fromCurrency.toUpperCase() == toCurrency.toUpperCase()) {
      return amount;
    }
    if (fromCurrency.toUpperCase() == 'USD' && toCurrency.toUpperCase() == 'INR') {
      return amount * exchangeRate;
    }
    if (fromCurrency.toUpperCase() == 'INR' && toCurrency.toUpperCase() == 'USD') {
      return amount / (exchangeRate > 0 ? exchangeRate : 1.0);
    }
    return amount * exchangeRate;
  }

  /// Overnight / MTF financing interest calculation under SEBI margin guidelines
  /// Daily Interest = Borrowed Amount × (Annual Rate / 365) × Days
  static double calculateOvernightFinancing({
    required double borrowedAmount,
    double annualInterestRate = 0.146, // 14.60% p.a. standard SEBI MTF rate
    int days = 1,
  }) {
    if (borrowedAmount <= 0 || days <= 0) return 0.0;
    return borrowedAmount * (annualInterestRate / 365.0) * days;
  }

  // ─── 3. Portfolio & Account Balancing ───────────────────────────────────────

  /// Equity = Cash Balance + Unrealized P&L
  static double calculateAccountEquity({
    required double cashBalance,
    required double unrealizedPnl,
  }) {
    return cashBalance + unrealizedPnl;
  }

  /// Free Margin = Equity - Used Margin
  static double calculateFreeMargin({
    required double equity,
    required double usedMargin,
  }) {
    return max(0.0, equity - usedMargin);
  }

  /// Margin Level (%) = (Equity / Used Margin) * 100
  static double calculateMarginLevel({
    required double equity,
    required double usedMargin,
  }) {
    if (usedMargin <= 0) return 999.99;
    return (equity / usedMargin) * 100.0;
  }

  /// Reconciles deposit/withdrawal ledger with displayed balance
  /// Calculated = Opening Balance + Total Credits - Total Debits
  static LedgerReconciliationResult reconcileLedgerBalance({
    required double openingBalance,
    required List<LedgerEntry> entries,
  }) {
    double running = openingBalance;
    for (final entry in entries) {
      running = running + entry.credit - entry.debit;
    }

    final expectedFromLastEntry = entries.isNotEmpty ? entries.last.runningBalance : openingBalance;
    final diff = (running - expectedFromLastEntry).abs();
    final isReconciled = diff < 0.01;

    return LedgerReconciliationResult(
      calculatedBalance: running,
      expectedBalance: expectedFromLastEntry,
      isReconciled: isReconciled,
      difference: diff,
    );
  }
}
