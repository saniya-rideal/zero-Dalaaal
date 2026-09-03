// chart_edge_cases.dart
// Handles all 7 chart edge cases from the ZeroDalali QA checklist:
//  1. No data
//  2. Delayed data disclosure
//  3. Market closed
//  4. Network interruption
//  5. Large historical range (loading state)
//  6. Very fast price movement (flash badge)
//  7. Symbol changed / delisted

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../data/models/models.dart';

// ---------------------------------------------------------------------------
// CHART STATE ENUM
// ---------------------------------------------------------------------------
enum ChartDataState {
  loading,           // fetching / generating data
  loaded,            // all good
  noData,            // candles list is empty
  networkError,      // connection lost
  marketClosed,      // outside trading hours
  delisted,          // symbol no longer traded
  delayedData,       // data may be delayed (non-live feed)
  loadingLargeRange, // loading a very large historical range
}

// ---------------------------------------------------------------------------
// CHART EDGE CASE CONTROLLER  (mix into StatefulWidget state)
// ---------------------------------------------------------------------------
class ChartEdgeCaseController {
  ChartDataState _state;
  bool _fastMovement = false;
  final bool _hasDelayedDisclosure;
  String? _delistedMessage;
  String? _closedMessage;
  double _fastMovementPercent = 0;
  final double priceChangeThreshold; // % per tick to trigger badge
  double _lastPrice = 0;
  Timer? _flashTimer;

  ChartEdgeCaseController({
    ChartDataState initialState = ChartDataState.loading,
    this.priceChangeThreshold = 1.0,
    bool hasDelayedData = false,
  })  : _state = initialState,
        _hasDelayedDisclosure = hasDelayedData;

  ChartDataState get state => _state;
  bool get isFastMovement => _fastMovement;
  double get fastMovementPercent => _fastMovementPercent;
  bool get hasDelayedDisclosure => _hasDelayedDisclosure;
  String? get delistedMessage => _delistedMessage;
  String? get closedMessage => _closedMessage;

  // Call whenever candles finish loading.
  void onCandlesLoaded(List<Candle> candles, {bool isMarketClosed = false}) {
    if (candles.isEmpty) {
      _state = ChartDataState.noData;
    } else if (isMarketClosed) {
      _state = ChartDataState.marketClosed;
      _closedMessage = 'Market is currently closed. Showing last session data.';
    } else {
      _state = ChartDataState.loaded;
      _closedMessage = null;
    }
  }

  void startLargeRangeLoad() => _state = ChartDataState.loadingLargeRange;

  void onNetworkError() => _state = ChartDataState.networkError;

  void onNetworkRestored(List<Candle> candles) {
    _state = candles.isEmpty ? ChartDataState.noData : ChartDataState.loaded;
  }

  void onSymbolDelisted(String symbol) {
    _state = ChartDataState.delisted;
    _delistedMessage =
        '$symbol has been delisted or suspended. No live data available.';
  }

  void onSymbolChanged() {
    _state = ChartDataState.loading;
    _delistedMessage = null;
    _closedMessage = null;
    _fastMovement = false;
    _fastMovementPercent = 0;
    _lastPrice = 0;
  }

  // Detects rapid price movement (flash crash / pump).
  // Returns true if setState should be called.
  bool checkPriceMovement(double newPrice, VoidCallback onFadeOut) {
    if (_lastPrice == 0) {
      _lastPrice = newPrice;
      return false;
    }
    final pct = ((newPrice - _lastPrice) / _lastPrice).abs() * 100;
    final signed = ((newPrice - _lastPrice) / _lastPrice) * 100;
    _lastPrice = newPrice;
    if (pct >= priceChangeThreshold && !_fastMovement) {
      _fastMovement = true;
      _fastMovementPercent = signed;
      _flashTimer?.cancel();
      _flashTimer = Timer(const Duration(seconds: 4), () {
        _fastMovement = false;
        onFadeOut();
      });
      return true;
    }
    return false;
  }

  void dispose() {
    _flashTimer?.cancel();
  }
}

// ---------------------------------------------------------------------------
// 1. NO DATA OVERLAY
// ---------------------------------------------------------------------------
class ChartNoDataOverlay extends StatelessWidget {
  final String symbol;
  final TradingColors colors;
  final VoidCallback? onRetry;

  const ChartNoDataOverlay({
    super.key,
    required this.symbol,
    required this.colors,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.chartBackground,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 56,
              color: colors.textSecondary.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 14),
            Text(
              'No chart data available',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Historical prices for $symbol could not be loaded.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary),
            ),
            if (onRetry != null) ...[  
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primary,
                  side: BorderSide(color: colors.primary),
                  textStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. DELAYED DATA DISCLOSURE BANNER (non-blocking amber top strip)
// ---------------------------------------------------------------------------
class ChartDelayedDataBanner extends StatelessWidget {
  final TradingColors colors;
  final int delayMinutes;

  const ChartDelayedDataBanner({
    super.key,
    required this.colors,
    this.delayMinutes = 15,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      color: const Color(0xFFF57C00).withValues(alpha: 0.15),
      child: Row(
        children: [
          const Icon(Icons.access_time, size: 13, color: Color(0xFFF57C00)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Data delayed by $delayMinutes min. Subscribe to live feed for real-time prices.',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                color: const Color(0xFFF57C00),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. MARKET CLOSED BANNER (non-blocking grey top strip)
// ---------------------------------------------------------------------------
class ChartMarketClosedBanner extends StatelessWidget {
  final TradingColors colors;
  final String? message;

  const ChartMarketClosedBanner({super.key, required this.colors, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      color: colors.textSecondary.withValues(alpha: 0.10),
      child: Row(
        children: [
          Icon(Icons.lock_clock_outlined, size: 13, color: colors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message ?? 'Market closed. Showing last available session data.',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. NETWORK ERROR OVERLAY (full screen with reconnect CTA)
// ---------------------------------------------------------------------------
class ChartNetworkErrorOverlay extends StatelessWidget {
  final TradingColors colors;
  final VoidCallback onRetry;

  const ChartNetworkErrorOverlay({
    super.key,
    required this.colors,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.chartBackground,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: colors.bearish.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 14),
            Text(
              'Connection Lost',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Chart data feed interrupted.\nCheck your internet connection and retry.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reconnect'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                textStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. LARGE HISTORICAL RANGE LOADING OVERLAY (animated spinner)
// ---------------------------------------------------------------------------
class ChartLargeRangeLoadingOverlay extends StatefulWidget {
  final TradingColors colors;

  const ChartLargeRangeLoadingOverlay({super.key, required this.colors});

  @override
  State<ChartLargeRangeLoadingOverlay> createState() =>
      _ChartLargeRangeLoadingOverlayState();
}

class _ChartLargeRangeLoadingOverlayState
    extends State<ChartLargeRangeLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        color: widget.colors.chartBackground,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: null,
                  strokeWidth: 3,
                  color: widget.colors.primary
                      .withValues(alpha: 0.5 + _anim.value * 0.5),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading historical data…',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: widget.colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Fetching large date range — this may take a moment.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: widget.colors.textSecondary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. FAST PRICE MOVEMENT BADGE (positioned overlay, auto-fade-out)
// ---------------------------------------------------------------------------
class ChartFastMovementBadge extends StatefulWidget {
  final TradingColors colors;
  final double changePercent;

  const ChartFastMovementBadge({
    super.key,
    required this.colors,
    required this.changePercent,
  });

  @override
  State<ChartFastMovementBadge> createState() =>
      _ChartFastMovementBadgeState();
}

class _ChartFastMovementBadgeState extends State<ChartFastMovementBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _ctrl.reverse();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUp = widget.changePercent >= 0;
    final color =
        isUp ? const Color(0xFF00897B) : const Color(0xFFE82B57);
    final icon =
        isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded;
    final pctStr =
        '${isUp ? '+' : ''}${widget.changePercent.toStringAsFixed(2)}%';

    return FadeTransition(
      opacity: _opacity,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 8,
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              '$pctStr Rapid Move',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 7. SYMBOL DELISTED OVERLAY
// ---------------------------------------------------------------------------
class ChartDelistedOverlay extends StatelessWidget {
  final TradingColors colors;
  final String symbol;
  final String? message;
  final VoidCallback? onChangeSymbol;

  const ChartDelistedOverlay({
    super.key,
    required this.colors,
    required this.symbol,
    this.message,
    this.onChangeSymbol,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.chartBackground,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.do_not_disturb_alt_rounded,
              size: 56,
              color: colors.textSecondary.withValues(alpha: 0.40),
            ),
            const SizedBox(height: 14),
            Text(
              'Symbol Unavailable',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message ??
                    '$symbol has been delisted or suspended. No live data available.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 12, color: colors.textSecondary),
              ),
            ),
            if (onChangeSymbol != null) ...[  
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onChangeSymbol,
                icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                label: const Text('Change Symbol'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primary,
                  side: BorderSide(color: colors.primary),
                  textStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// STANDARD LOADING SPINNER (timeframe switch)
// ---------------------------------------------------------------------------
class ChartLoadingOverlay extends StatelessWidget {
  final TradingColors colors;

  const ChartLoadingOverlay({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.chartBackground,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MASTER DISPATCHER — wraps chart canvas with correct overlay/banner
// ---------------------------------------------------------------------------
class ChartEdgeCaseWrapper extends StatelessWidget {
  /// The actual chart painter shown when everything is OK.
  final Widget child;
  final ChartDataState state;
  final TradingColors colors;
  final String symbol;
  final bool hasDelayedData;
  final bool isFastMovement;
  final double fastMovementPercent;
  final VoidCallback onRetry;
  final VoidCallback? onChangeSymbol;
  final String? delistedMessage;
  final String? closedMessage;

  const ChartEdgeCaseWrapper({
    super.key,
    required this.child,
    required this.state,
    required this.colors,
    required this.symbol,
    required this.onRetry,
    this.hasDelayedData = false,
    this.isFastMovement = false,
    this.fastMovementPercent = 0,
    this.onChangeSymbol,
    this.delistedMessage,
    this.closedMessage,
  });

  @override
  Widget build(BuildContext context) {
    // Full-replacement overlays
    switch (state) {
      case ChartDataState.loading:
        return ChartLoadingOverlay(colors: colors);
      case ChartDataState.loadingLargeRange:
        return ChartLargeRangeLoadingOverlay(colors: colors);
      case ChartDataState.noData:
        return ChartNoDataOverlay(
            symbol: symbol, colors: colors, onRetry: onRetry);
      case ChartDataState.networkError:
        return ChartNetworkErrorOverlay(
            colors: colors, onRetry: onRetry);
      case ChartDataState.delisted:
        return ChartDelistedOverlay(
          colors: colors,
          symbol: symbol,
          message: delistedMessage,
          onChangeSymbol: onChangeSymbol,
        );
      default:
        break;
    }

    // Partial overlays — chart is visible with banners/badges on top
    return Stack(
      children: [
        child,

        // Market-closed banner (top strip)
        if (state == ChartDataState.marketClosed)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ChartMarketClosedBanner(
                colors: colors, message: closedMessage),
          ),

        // Delayed-data banner (top strip, shown during loaded state only)
        if (hasDelayedData && state == ChartDataState.loaded)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ChartDelayedDataBanner(colors: colors),
          ),

        // Fast-movement badge (top-right, floats above banners)
        if (isFastMovement)
          Positioned(
            top: (hasDelayedData || state == ChartDataState.marketClosed)
                ? 30
                : 8,
            right: 70,
            child: ChartFastMovementBadge(
              colors: colors,
              changePercent: fastMovementPercent,
            ),
          ),
      ],
    );
  }
}
