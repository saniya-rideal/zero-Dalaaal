import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MarketSessionState {
  open,
  closed,
  preOpen,
  halted,
}

class MarketExchangeStatus {
  final MarketSessionState state;
  final String label;
  final String exchange;
  final String tradingHours;
  final Color badgeColor;

  const MarketExchangeStatus({
    required this.state,
    required this.label,
    required this.exchange,
    required this.tradingHours,
    required this.badgeColor,
  });
}

class MarketStatusService {
  static const String timeZoneLabel = 'IST (UTC+05:30)';

  /// Evaluates real-time market status for NSE/BSE and MCX based on IST clock
  static MarketExchangeStatus getStatusForExchange(String exchange) {
    // Current Indian Standard Time (UTC + 5:30)
    final nowUtc = DateTime.now().toUtc();
    final ist = nowUtc.add(const Duration(hours: 5, minutes: 30));
    final weekday = ist.weekday; // 1 = Monday, ..., 6 = Saturday, 7 = Sunday
    final minutesSinceMidnight = ist.hour * 60 + ist.minute;

    final isWeekend = weekday == DateTime.saturday || weekday == DateTime.sunday;

    if (exchange.toUpperCase() == 'MCX') {
      if (isWeekend) {
        return const MarketExchangeStatus(
          state: MarketSessionState.closed,
          label: 'MCX: CLOSED',
          exchange: 'MCX',
          tradingHours: '09:00 - 23:30 IST (Mon-Fri)',
          badgeColor: Color(0xFFC62828),
        );
      }
      // MCX: 09:00 (540 min) to 23:30 (1410 min)
      if (minutesSinceMidnight >= 540 && minutesSinceMidnight < 1410) {
        return const MarketExchangeStatus(
          state: MarketSessionState.open,
          label: 'MCX: OPEN',
          exchange: 'MCX',
          tradingHours: 'Closes at 23:30 IST',
          badgeColor: Color(0xFF00A854),
        );
      }
      return const MarketExchangeStatus(
        state: MarketSessionState.closed,
        label: 'MCX: CLOSED',
        exchange: 'MCX',
        tradingHours: 'Opens at 09:00 IST',
        badgeColor: Color(0xFFC62828),
      );
    }

    // Default: NSE / BSE Equity & Derivatives
    if (isWeekend) {
      return const MarketExchangeStatus(
        state: MarketSessionState.closed,
        label: 'NSE: CLOSED',
        exchange: 'NSE',
        tradingHours: '09:15 - 15:30 IST (Mon-Fri)',
        badgeColor: Color(0xFFC62828),
      );
    }

    // Pre-Open: 09:00 (540 min) to 09:15 (555 min)
    if (minutesSinceMidnight >= 540 && minutesSinceMidnight < 555) {
      return const MarketExchangeStatus(
        state: MarketSessionState.preOpen,
        label: 'NSE: PRE-OPEN',
        exchange: 'NSE',
        tradingHours: 'Regular session starts 09:15 IST',
        badgeColor: Color(0xFFE65100),
      );
    }

    // Regular Session: 09:15 (555 min) to 15:30 (930 min)
    if (minutesSinceMidnight >= 555 && minutesSinceMidnight < 930) {
      return const MarketExchangeStatus(
        state: MarketSessionState.open,
        label: 'NSE: OPEN',
        exchange: 'NSE',
        tradingHours: 'Closes at 15:30 IST',
        badgeColor: Color(0xFF00A854),
      );
    }

    // Closed / Post-Market
    return const MarketExchangeStatus(
      state: MarketSessionState.closed,
      label: 'NSE: CLOSED',
      exchange: 'NSE',
      tradingHours: 'Opens at 09:15 IST',
      badgeColor: Color(0xFFC62828),
    );
  }
}

final marketStatusProvider = Provider<MarketExchangeStatus>((ref) {
  return MarketStatusService.getStatusForExchange('NSE');
});
