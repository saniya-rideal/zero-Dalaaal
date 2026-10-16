import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../market/data/real_market_repository.dart';
import '../../../data/models/models.dart';
import '../domain/indicator.dart';
import 'chart_edge_cases.dart';
import 'indicators/indicator_math.dart';


class CandlestickChartView extends ConsumerStatefulWidget {
  final String token;
  final Timeframe initialTimeframe;
  final ChartType initialChartType;
  final bool isFullscreen;
  final VoidCallback? onFullscreenToggle;

  const CandlestickChartView({
    super.key,
    required this.token,
    this.initialTimeframe = Timeframe.ONE_DAY,
    this.initialChartType = ChartType.candle,
    this.isFullscreen = false,
    this.onFullscreenToggle,
  });

  @override
  ConsumerState<CandlestickChartView> createState() => _CandlestickChartViewState();
}

class _CandlestickChartViewState extends ConsumerState<CandlestickChartView> {
  late Timeframe _selectedTimeframe;
  late ChartType _selectedChartType;
  List<Candle> _candles = [];
  late ChartEdgeCaseController _edgeCtrl;

  double _candleWidth = 8.0;
  double _scrollOffset = 0.0;
  Offset? _crosshairPosition;
  Candle? _selectedCandle;

  final List<IndicatorConfig> _activeIndicators = [
    const IndicatorConfig(type: IndicatorType.SMA, period: 20, isEnabled: true),
  ];

  @override
  void initState() {
    super.initState();
    _selectedTimeframe = widget.initialTimeframe;
    _selectedChartType = widget.initialChartType;
    // Track delayed data for exchanges that don't have live feed
    _edgeCtrl = ChartEdgeCaseController(
      initialState: ChartDataState.loading,
      hasDelayedData: _isDelayedFeed(widget.token),
    );
    _loadCandles();
  }

  @override
  void dispose() {
    _edgeCtrl.dispose();
    super.dispose();
  }

  /// Instruments on non-live feeds (e.g. global indices) show delayed banner.
  bool _isDelayedFeed(String token) {
    const delayedPrefixes = ['global_', 'crypto_', 'fx_'];
    return delayedPrefixes.any((p) => token.startsWith(p));
  }

  /// Returns true when current time is outside normal trading hours.
  bool _isMarketClosed() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final totalMins = hour * 60 + minute;
    // NSE/BSE: 09:15 – 15:30 IST, Mon-Fri
    final isWeekday = now.weekday >= DateTime.monday && now.weekday <= DateTime.friday;
    return !isWeekday || totalMins < 555 || totalMins > 930;
  }


  void _loadCandles({bool isLargeRange = false}) async {
    if (isLargeRange) {
      setState(() => _edgeCtrl.startLargeRangeLoad());
    }

    try {
      final repo = ref.read(marketRepositoryProvider);
      final days = isLargeRange ? 180 : 30;
      final from = DateTime.now().subtract(Duration(days: days));
      final to = DateTime.now();
      final candles = await repo.getCandles(
        widget.token,
        interval: _timeframeToResolution(_selectedTimeframe),
        from: from.millisecondsSinceEpoch ~/ 1000,
        to: to.millisecondsSinceEpoch ~/ 1000,
      );
      if (!mounted) return;
      setState(() {
        _candles = candles;
        _scrollOffset = 0.0;
        _edgeCtrl.onCandlesLoaded(candles, isMarketClosed: _isMarketClosed());
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _edgeCtrl.onCandlesLoaded(_candles, isMarketClosed: _isMarketClosed());
      });
    }
  }

  String _timeframeToResolution(Timeframe tf) {
    switch (tf) {
      case Timeframe.ONE_MIN:
        return '1m';
      case Timeframe.FIVE_MIN:
        return '5m';
      case Timeframe.FIFTEEN_MIN:
        return '15m';
      case Timeframe.THIRTY_MIN:
        return '30m';
      case Timeframe.ONE_HOUR:
        return '1h';
      case Timeframe.ONE_DAY:
        return '1d';
      case Timeframe.ONE_WEEK:
        return '1w';
      case Timeframe.ONE_MONTH:
        return '1M';
    }
  }


  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Chart Controls Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(bottom: BorderSide(color: colors.divider, width: 0.5)),
          ),
          child: Row(
            children: [
              // Chart Type Selector
              _buildChartTypeIcon(LucideIcons.candlestickChart, ChartType.candle),
              _buildChartTypeIcon(LucideIcons.lineChart, ChartType.line),
              _buildChartTypeIcon(LucideIcons.barChart2, ChartType.bar),

              const SizedBox(width: 8),
              Container(width: 1, height: 20, color: colors.divider),
              const SizedBox(width: 8),

              // Timeframe Strip
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: Timeframe.values.map((tf) {
                      final isSelected = _selectedTimeframe == tf;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: InkWell(
                          onTap: () {
                            final isLarge = tf == Timeframe.ONE_WEEK ||
                                tf == Timeframe.ONE_MONTH;
                            setState(() => _selectedTimeframe = tf);
                            _loadCandles(isLargeRange: isLarge);
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? colors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tf.label,
                              style: AppTypography.caption(
                                color: isSelected ? Colors.white : colors.textSecondary,
                                weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              if (widget.onFullscreenToggle != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    widget.isFullscreen ? LucideIcons.minimize : LucideIcons.maximize,
                    color: colors.textPrimary,
                    size: 20,
                  ),
                  onPressed: widget.onFullscreenToggle,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ],
          ),
        ),

        // Crosshair OHLC readout bar
        Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: colors.cardBackground,
          child: _selectedCandle != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildOhlcLabel('O', _selectedCandle!.open, colors),
                    _buildOhlcLabel('H', _selectedCandle!.high, colors),
                    _buildOhlcLabel('L', _selectedCandle!.low, colors),
                    _buildOhlcLabel('C', _selectedCandle!.close, colors),
                    Text(
                      DateFormatter.formatChartDate(_selectedCandle!.time),
                      style: AppTypography.labelSmall(color: colors.textSecondary),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Text(
                      'Hold & drag on chart for crosshair details',
                      style: AppTypography.labelSmall(color: colors.textSecondary),
                    ),
                  ],
                ),
        ),

        // Interactive Painter Canvas wrapped with edge-case handler
        Expanded(
          child: ChartEdgeCaseWrapper(
            state: _edgeCtrl.state,
            colors: colors,
            symbol: widget.token.toUpperCase(),
            hasDelayedData: _edgeCtrl.hasDelayedDisclosure,
            isFastMovement: _edgeCtrl.isFastMovement,
            fastMovementPercent: _edgeCtrl.fastMovementPercent,
            onRetry: () => _loadCandles(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleUpdate: (details) {
                    setState(() {
                      if (details.scale != 1.0) {
                        _candleWidth = (_candleWidth * details.scale).clamp(3.0, 24.0);
                      }
                      if (details.focalPointDelta.dx != 0) {
                        final spacing = _candleWidth * 0.3;
                        final fullStep = _candleWidth + spacing;
                        final chartWidth = constraints.maxWidth - 60.0;
                        final maxScroll = max(0.0, (_candles.length * fullStep) - chartWidth);
                        _scrollOffset = (_scrollOffset + details.focalPointDelta.dx).clamp(-maxScroll, 0.0);
                      }
                    });
                  },
                  onLongPressStart: (details) {
                    _updateCrosshairPosition(details.localPosition, constraints.maxWidth);
                  },
                  onLongPressMoveUpdate: (details) {
                    _updateCrosshairPosition(details.localPosition, constraints.maxWidth);
                  },
                  onLongPressEnd: (_) {
                    setState(() {
                      _crosshairPosition = null;
                      _selectedCandle = null;
                    });
                  },
                  child: ClipRect(
                    child: _edgeCtrl.state == ChartDataState.loaded ||
                            _edgeCtrl.state == ChartDataState.marketClosed
                        ? RepaintBoundary(
                            child: CustomPaint(
                              painter: _TradingChartPainter(
                                candles: _candles,
                                candleWidth: _candleWidth,
                                scrollOffset: _scrollOffset,
                                chartType: _selectedChartType,
                                crosshairPosition: _crosshairPosition,
                                colors: colors,
                                indicators: _activeIndicators,
                              ),
                              child: Container(),
                            ),
                          )
                        : const SizedBox.expand(),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _updateCrosshairPosition(Offset pos, double totalWidth) {
    if (_candles.isEmpty) return;
    const priceAxisWidth = 60.0;
    final chartWidth = totalWidth - priceAxisWidth;
    final spacing = _candleWidth * 0.3;
    final fullStep = _candleWidth + spacing;
    final totalCandles = _candles.length;

    final maxScroll = max(0.0, (totalCandles * fullStep) - chartWidth);
    final clampedOffset = _scrollOffset.clamp(-maxScroll, 0.0);

    final double rawIndex = (totalCandles - 1) - ((chartWidth + clampedOffset - pos.dx) / fullStep);
    final int index = rawIndex.round().clamp(0, totalCandles - 1);
    final candle = _candles[index];

    if (_crosshairPosition != pos || _selectedCandle != candle) {
      setState(() {
        _crosshairPosition = pos;
        _selectedCandle = candle;
      });
    }
  }

  Widget _buildChartTypeIcon(IconData icon, ChartType type) {
    final colors = context.tradingColors;
    final isSelected = _selectedChartType == type;
    return IconButton(
      icon: Icon(icon, size: 20, color: isSelected ? colors.primary : colors.textSecondary),
      onPressed: () => setState(() => _selectedChartType = type),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  Widget _buildOhlcLabel(String prefix, double val, TradingColors colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$prefix: ', style: AppTypography.labelSmall(color: colors.textSecondary)),
        Text(val.toStringAsFixed(2), style: AppTypography.labelSmall(color: colors.textPrimary, weight: FontWeight.w600, tabular: true)),
      ],
    );
  }
}

class _TradingChartPainter extends CustomPainter {
  final List<Candle> candles;
  final double candleWidth;
  final double scrollOffset;
  final ChartType chartType;
  final Offset? crosshairPosition;
  final TradingColors colors;
  final List<IndicatorConfig> indicators;

  _TradingChartPainter({
    required this.candles,
    required this.candleWidth,
    required this.scrollOffset,
    required this.chartType,
    required this.crosshairPosition,
    required this.colors,
    required this.indicators,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    const priceAxisWidth = 60.0;
    const timeAxisHeight = 24.0;
    final chartWidth = size.width - priceAxisWidth;
    final chartHeight = size.height - timeAxisHeight;
    final volumeHeight = chartHeight * 0.18;
    final mainChartHeight = chartHeight - volumeHeight;

    // Background
    final bgPaint = Paint()..color = colors.chartBackground;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final totalCandles = candles.length;
    final spacing = candleWidth * 0.3;
    final fullStep = candleWidth + spacing;

    // Viewport index calculation
    final maxScroll = max(0.0, (totalCandles * fullStep) - chartWidth);
    final clampedOffset = scrollOffset.clamp(-maxScroll, 0.0);

    final rightX = chartWidth + clampedOffset;
    final firstVisibleIdx = max(0, ((0 - rightX + (totalCandles * fullStep)) / fullStep).floor() - 2);
    final lastVisibleIdx = min(totalCandles - 1, ((chartWidth - rightX + (totalCandles * fullStep)) / fullStep).ceil() + 2);

    if (firstVisibleIdx > lastVisibleIdx) return;

    // Find Min / Max Price in viewport
    double minPrice = double.infinity;
    double maxPrice = -double.infinity;
    int maxVol = 1;

    for (int i = firstVisibleIdx; i <= lastVisibleIdx; i++) {
      final c = candles[i];
      minPrice = min(minPrice, c.low);
      maxPrice = max(maxPrice, c.high);
      maxVol = max(maxVol, c.volume);
    }

    final pricePadding = (maxPrice - minPrice) * 0.08;
    minPrice -= pricePadding;
    maxPrice += pricePadding;
    final priceRange = max(1.0, maxPrice - minPrice);

    // Draw Horizontal Grid Lines & Price Labels
    final gridPaint = Paint()
      ..color = colors.chartGrid
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 5; i++) {
      final y = (mainChartHeight / 5) * i;
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);

      final priceAtY = maxPrice - (i * (priceRange / 5));
      final textPainter = TextPainter(
        text: TextSpan(
          text: CurrencyFormatter.format(priceAtY, showSymbol: false),
          style: AppTypography.labelSmall(color: colors.textSecondary, tabular: true),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(chartWidth + 6, y - (textPainter.height / 2)));
    }

    // SMA Overlay Calculation
    final smaValues = IndicatorMath.calculateSma(candles, 20);
    final smaPath = Path();
    bool smaStarted = false;

    // Candle Render Loop
    for (int i = 0; i < totalCandles; i++) {
      final candle = candles[i];
      final x = chartWidth - ((totalCandles - 1 - i) * fullStep) + clampedOffset;

      if (x < -candleWidth || x > chartWidth + candleWidth) continue;

      final isBull = candle.isBullish;
      final candleColor = isBull ? colors.bullish : colors.bearish;

      // Volume Bar
      final volFraction = (candle.volume / maxVol).clamp(0.0, 1.0);
      final volBarHeight = volumeHeight * volFraction;
      final volY = chartHeight - volBarHeight;
      final volPaint = Paint()..color = candleColor.withValues(alpha: 0.25);
      canvas.drawRect(Rect.fromLTWH(x - (candleWidth / 2), volY, candleWidth, volBarHeight), volPaint);

      final openY = mainChartHeight - (((candle.open - minPrice) / priceRange) * mainChartHeight);
      final closeY = mainChartHeight - (((candle.close - minPrice) / priceRange) * mainChartHeight);
      final highY = mainChartHeight - (((candle.high - minPrice) / priceRange) * mainChartHeight);
      final lowY = mainChartHeight - (((candle.low - minPrice) / priceRange) * mainChartHeight);

      if (chartType == ChartType.candle) {
        // Wick line
        final wickPaint = Paint()
          ..color = candleColor
          ..strokeWidth = 1.2;
        canvas.drawLine(Offset(x, highY), Offset(x, lowY), wickPaint);

        // Body rect
        final bodyTop = min(openY, closeY);
        final bodyHeight = max(1.5, (openY - closeY).abs());
        final bodyPaint = Paint()..color = candleColor;
        canvas.drawRect(Rect.fromLTWH(x - (candleWidth / 2), bodyTop, candleWidth, bodyHeight), bodyPaint);
      } else if (chartType == ChartType.line) {
        // Line chart will be drawn via path below
      } else if (chartType == ChartType.bar) {
        final barPaint = Paint()
          ..color = candleColor
          ..strokeWidth = 1.5;
        // High-Low line
        canvas.drawLine(Offset(x, highY), Offset(x, lowY), barPaint);
        // Open tick (left)
        canvas.drawLine(Offset(x - (candleWidth / 2), openY), Offset(x, openY), barPaint);
        // Close tick (right)
        canvas.drawLine(Offset(x, closeY), Offset(x + (candleWidth / 2), closeY), barPaint);
      }

      // SMA Path point
      final sma = smaValues[i];
      if (sma != null) {
        final smaY = mainChartHeight - (((sma - minPrice) / priceRange) * mainChartHeight);
        if (!smaStarted) {
          smaPath.moveTo(x, smaY);
          smaStarted = true;
        } else {
          smaPath.lineTo(x, smaY);
        }
      }
    }

    // Draw Line chart if selected
    if (chartType == ChartType.line) {
      final linePath = Path();
      bool lineStarted = false;
      for (int i = 0; i < totalCandles; i++) {
        final candle = candles[i];
        final x = chartWidth - ((totalCandles - 1 - i) * fullStep) + clampedOffset;
        final closeY = mainChartHeight - (((candle.close - minPrice) / priceRange) * mainChartHeight);
        if (!lineStarted) {
          linePath.moveTo(x, closeY);
          lineStarted = true;
        } else {
          linePath.lineTo(x, closeY);
        }
      }
      final linePaint = Paint()
        ..color = colors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawPath(linePath, linePaint);
    }

    // Draw SMA Path
    if (smaStarted) {
      final smaPaint = Paint()
        ..color = colors.warning
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(smaPath, smaPaint);
    }

    // Crosshair Lines
    if (crosshairPosition != null && crosshairPosition!.dx <= chartWidth) {
      final chPaint = Paint()
        ..color = colors.textSecondary.withValues(alpha: 0.6)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;

      // Vertical line
      canvas.drawLine(Offset(crosshairPosition!.dx, 0), Offset(crosshairPosition!.dx, chartHeight), chPaint);
      // Horizontal line
      canvas.drawLine(Offset(0, crosshairPosition!.dy), Offset(chartWidth, crosshairPosition!.dy), chPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TradingChartPainter oldDelegate) {
    return oldDelegate.candles != candles ||
        oldDelegate.candleWidth != candleWidth ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.chartType != chartType ||
        oldDelegate.crosshairPosition != crosshairPosition ||
        oldDelegate.indicators != indicators ||
        oldDelegate.colors != colors;
  }
}
