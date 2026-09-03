import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../data/mock/candle_generator.dart';
import '../../../data/mock/order_simulation_engine.dart';
import '../../../data/mock/seed_instruments.dart';
import '../../../data/mock/ticker_service.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/news_ticker_strip.dart';
import '../../../shared_widgets/script_selector_bar.dart';
import '../../../shared_widgets/zero_bottom_nav_bar.dart';
import '../../../shared_widgets/zero_drawer.dart';
import '../domain/indicator.dart';
import 'chart_edge_cases.dart';
import 'indicator_picker_sheet.dart';
import 'indicators/indicator_math.dart';


class ChartFullscreenScreen extends ConsumerStatefulWidget {
  final String token;

  const ChartFullscreenScreen({super.key, required this.token});

  @override
  ConsumerState<ChartFullscreenScreen> createState() =>
      _ChartFullscreenScreenState();
}

class _ChartFullscreenScreenState extends ConsumerState<ChartFullscreenScreen> {
  late String _currentToken;
  double _tradeLots = 0.10;
  String _selectedTimeframe = '4h';
  Timeframe _timeframeEnum = Timeframe.ONE_HOUR;
  ChartType _chartType = ChartType.candle;
  String _activeTool = 'crosshair';
  bool _showDrawings = true;
  bool _isLocked = false;
  bool _isLogScale = false;
  bool _isPercentScale = false;
  bool _showTradePad = true;

  double _prevBid = 0.0;
  double _prevAsk = 0.0;
  Color _sellColor = const Color(0xFF2196F3); // Dynamic Blue for Bullish / Up tick
  Color _buyColor = const Color(0xFFE82B57); // Dynamic Red for Bearish / Down tick

  late Timer _utcTimer;
  String _currentUtcTime = '';

  // Custom User Drawing Elements
  final List<List<Offset>> _userStrokes = [];
  final List<List<Offset>> _undoStrokes = [];
  final List<Offset> _currentStroke = [];
  Candle? _hoveredCandle;

  List<IndicatorConfig> _indicators = [
    const IndicatorConfig(type: IndicatorType.SMA, period: 20, isEnabled: true),
  ];

  @override
  void initState() {
    super.initState();
    _currentToken = widget.token;
    _updateUtcTime();
    _utcTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateUtcTime());
  }

  void _updateUtcTime() {
    final now = DateTime.now().toUtc();
    final formatted = DateFormat('HH:mm:ss').format(now);
    if (mounted) {
      setState(() => _currentUtcTime = '$formatted (UTC)');
    }
  }

  @override
  void dispose() {
    _utcTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final instrument = SeedInstruments.findByToken(_currentToken) ??
        Instrument(
          token: _currentToken,
          symbol: _currentToken.replaceAll('_', ' ').toUpperCase(),
          name: _currentToken,
          exchange: Exchange.MCX,
          type: InstrumentType.FUT,
        );

    final tickerService = ref.watch(tickerServiceProvider);
    final quote = tickerService.getQuote(_currentToken);
    final ltp = quote.ltp > 0 ? quote.ltp : 1373.50;
    final bid = ltp - 0.15;
    final ask = ltp + 0.15;

    // Reactively update colors according to graph price movement ticks
    if (_prevBid != 0.0 && bid != _prevBid) {
      _sellColor = bid > _prevBid
          ? const Color(0xFF2196F3) // Electric Blue on price up
          : const Color(0xFFE82B57); // Crimson Red on price down
    }
    if (_prevAsk != 0.0 && ask != _prevAsk) {
      _buyColor = ask > _prevAsk
          ? const Color(0xFF2196F3) // Electric Blue on price up
          : const Color(0xFFE82B57); // Crimson Red on price down
    }
    _prevBid = bid;
    _prevAsk = ask;

    final change = quote.change;
    final changePct = quote.changePercent;
    final isPositive = change >= 0;

    return Scaffold(
      backgroundColor: colors.background,
      drawer: ZeroDrawer(activeRoute: '/chart-fullscreen/$_currentToken'),
      appBar: AppBar(
        backgroundColor: colors.cardBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu, color: colors.textPrimary, size: 26),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          'Chart',
          style: GoogleFonts.inter(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: Center(
              child: InkWell(
                onTap: () {
                  setState(() => _showTradePad = !_showTradePad);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_showTradePad
                          ? 'Quick Trade Pad Enabled'
                          : 'Quick Trade Pad Hidden'),
                      duration: const Duration(milliseconds: 800),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 32,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: colors.divider.withValues(alpha: 0.8),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: _sellColor,
                            borderRadius:
                                const BorderRadius.horizontal(left: Radius.circular(2)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: _buyColor,
                            borderRadius:
                                const BorderRadius.horizontal(right: Radius.circular(2)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Public News & Private News Strip
          const NewsTickerStrip(),

          // Dual Script Selector Bar
          const ScriptSelectorBar(),

          // TradingView Top Header Ribbon
          _buildTradingViewHeaderRibbon(instrument, colors),

          // Main Chart Canvas with Left Drawing Tools Bar
          Expanded(
            child: Row(
              children: [
                // Left Vertical Drawing Tools Sidebar
                _buildLeftDrawingToolbar(colors),

                // Center/Right Chart Canvas
                Expanded(
                  child: Column(
                    children: [
                      // Canvas with Interactive Chart, Drawings, Crosshair, and Legend
                      Expanded(
                        child: Stack(
                          children: [
                            // Interactive Chart Painter Canvas
                            _TradingViewInteractiveCanvas(
                              token: _currentToken,
                              timeframeEnum: _timeframeEnum,
                              chartType: _chartType,
                              colors: colors,
                              ltp: ltp,
                              activeTool: _activeTool,
                              showDrawings: _showDrawings,
                              isLogScale: _isLogScale,
                              isPercentScale: _isPercentScale,
                              indicators: _indicators,
                              userStrokes: _userStrokes,
                              currentStroke: _currentStroke,
                              onStrokeFinished: (stroke) {
                                if (!_isLocked && stroke.isNotEmpty) {
                                  setState(() {
                                    _userStrokes.add(List.from(stroke));
                                    _undoStrokes.clear();
                                  });
                                }
                              },
                              onCrosshairUpdate: (_, candle) {
                                setState(() {
                                  _hoveredCandle = candle;
                                });
                              },
                            ),

                            // Legend in Top-Left of Chart Canvas
                            Positioned(
                              top: 8,
                              left: 10,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${instrument.symbol} · $_selectedTimeframe',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF00A854),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _hoveredCandle != null
                                        ? 'O:${_hoveredCandle!.open.toStringAsFixed(2)}  H:${_hoveredCandle!.high.toStringAsFixed(2)}  L:${_hoveredCandle!.low.toStringAsFixed(2)}  C:${_hoveredCandle!.close.toStringAsFixed(2)}'
                                        : '${ltp.toStringAsFixed(2)}  ${isPositive ? '+' : ''}${change.toStringAsFixed(2)} (${isPositive ? '+' : ''}${changePct.toStringAsFixed(2)}%)',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: isPositive
                                          ? const Color(0xFF00897B)
                                          : const Color(0xFFE82B57),
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // TradingView Logo Watermark at bottom-left
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: InkWell(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('TradingView Chart Engine v2.4 Active')),
                                  );
                                },
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: colors.cardBackground,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      'TV',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom Timezone & Scale Ribbon
                      Container(
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: colors.cardBackground,
                          border: Border(
                            top: BorderSide(
                              color: colors.divider.withValues(alpha: 0.5),
                              width: 0.5,
                            ),
                            bottom: BorderSide(
                              color: colors.divider.withValues(alpha: 0.5),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () => _showDateRangePicker(context),
                              child: Row(
                                children: [
                                  Text(
                                    'Date Range',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: colors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(Icons.keyboard_arrow_down,
                                      size: 14, color: colors.textSecondary),
                                ],
                              ),
                            ),
                            Text(
                              _currentUtcTime,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w500,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() => _isPercentScale = !_isPercentScale);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      '%',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: _isPercentScale
                                            ? const Color(0xFF1E88E5)
                                            : colors.textSecondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () {
                                    setState(() => _isLogScale = !_isLogScale);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      'log',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: _isLogScale
                                            ? const Color(0xFF1E88E5)
                                            : colors.textSecondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _isLogScale = false;
                                      _isPercentScale = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Scale reset to Auto')),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      'auto',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: const Color(0xFF1E88E5),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => _showChartSettingsSheet(context),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                    child: Icon(
                                      Icons.settings_outlined,
                                      size: 14,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Vibrant Blue Quick Trade Pad
          if (_showTradePad)
            _buildQuickTradePad(bid, ask, instrument, colors),
        ],
      ),
      bottomNavigationBar: ZeroBottomNavBar(
        currentIndex: 0,
        isExpanded: false,
        onCenterToggle: () {},
        onTabSelected: (index) {
          if (index == 0) context.go('/quotes');
          if (index == 1) context.go('/deals');
          if (index == 2) context.go('/net-deals');
          if (index == 3) context.go('/history');
        },
      ),
    );
  }

  // 1. TradingView Top Header Ribbon
  Widget _buildTradingViewHeaderRibbon(
      Instrument instrument, TradingColors colors) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        border: Border(
          bottom: BorderSide(
            color: colors.divider.withValues(alpha: 0.6),
            width: 0.8,
          ),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Symbol Name Button
          InkWell(
            onTap: () => _showInstrumentPicker(context),
            child: Center(
              child: Row(
                children: [
                  Text(
                    instrument.symbol,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.keyboard_arrow_down,
                      size: 14, color: colors.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildVerticalSeparator(colors),
          const SizedBox(width: 8),

          // Timeframe Selector
          InkWell(
            onTap: () => _showTimeframePicker(context),
            child: Center(
              child: Row(
                children: [
                  Text(
                    _selectedTimeframe,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.keyboard_arrow_down,
                      size: 14, color: colors.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildVerticalSeparator(colors),
          const SizedBox(width: 8),

          // Chart Display Type Icon
          InkWell(
            onTap: () => _showChartSettingsSheet(context),
            child: Center(
              child: Icon(
                _chartType == ChartType.candle
                    ? Icons.candlestick_chart_outlined
                    : _chartType == ChartType.line
                        ? Icons.show_chart
                        : Icons.bar_chart,
                size: 18,
                color: colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildVerticalSeparator(colors),
          const SizedBox(width: 8),

          // Compare Symbol (+)
          InkWell(
            onTap: () => _showInstrumentPicker(context),
            child: const Center(
              child: Icon(Icons.add_circle_outline,
                  size: 18, color: Color(0xFF4A5568)),
            ),
          ),
          const SizedBox(width: 14),

          // Indicators (fx)
          InkWell(
            onTap: () {
              IndicatorPickerSheet.show(
                context,
                currentConfigs: _indicators,
                onApply: (configs) {
                  setState(() => _indicators = configs);
                },
              );
            },
            child: Center(
              child: Text(
                'fx',
                style: GoogleFonts.sourceSerif4(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: _indicators.isNotEmpty
                      ? const Color(0xFF1E88E5)
                      : const Color(0xFF4A5568),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Undo
          InkWell(
            onTap: () {
              if (_userStrokes.isNotEmpty) {
                setState(() {
                  _undoStrokes.add(_userStrokes.removeLast());
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Drawing undone'), duration: Duration(milliseconds: 600)),
                );
              }
            },
            child: const Center(
              child: Icon(Icons.undo, size: 18, color: Color(0xFF4A5568)),
            ),
          ),
          const SizedBox(width: 14),

          // Redo
          InkWell(
            onTap: () {
              if (_undoStrokes.isNotEmpty) {
                setState(() {
                  _userStrokes.add(_undoStrokes.removeLast());
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Drawing redone'), duration: Duration(milliseconds: 600)),
                );
              }
            },
            child: const Center(
              child: Icon(Icons.redo, size: 18, color: Color(0xFF4A5568)),
            ),
          ),
          const SizedBox(width: 14),

          // Cloud Template Save
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Chart template saved for ${instrument.symbol} ($_selectedTimeframe)'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: Center(
              child: Row(
                children: [
                  const Icon(Icons.cloud_outlined,
                      size: 18, color: Color(0xFF4A5568)),
                  const SizedBox(width: 4),
                  Text(
                    'Save',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4A5568),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalSeparator(TradingColors colors) {
    return Center(
      child: Container(
        width: 1,
        height: 16,
        color: colors.divider.withValues(alpha: 0.8),
      ),
    );
  }

  // 2. Left Vertical Drawing Toolbar
  Widget _buildLeftDrawingToolbar(TradingColors colors) {
    final tools = [
      {'id': 'crosshair', 'icon': Icons.add, 'label': 'Crosshair'},
      {'id': 'trendline', 'icon': Icons.timeline_outlined, 'label': 'Trend Line'},
      {'id': 'fibonacci', 'icon': Icons.density_medium_outlined, 'label': 'Fibonacci'},
      {'id': 'brush', 'icon': Icons.brush_outlined, 'label': 'Brush'},
      {'id': 'text', 'icon': Icons.title_outlined, 'label': 'Text'},
      {'id': 'pattern', 'icon': Icons.gesture_outlined, 'label': 'Pattern'},
      {'id': 'prediction', 'icon': Icons.square_foot_outlined, 'label': 'Long/Short Position'},
      {'id': 'emoji', 'icon': Icons.sentiment_satisfied_alt_outlined, 'label': 'Sticker'},
      {'id': 'ruler', 'icon': Icons.straighten_outlined, 'label': 'Ruler'},
      {'id': 'zoom', 'icon': Icons.zoom_in_outlined, 'label': 'Zoom In'},
      {'id': 'magnet', 'icon': Icons.all_inclusive_outlined, 'label': 'Magnet Mode'},
      {'id': 'lock', 'icon': _isLocked ? Icons.lock : Icons.lock_outline, 'label': 'Lock All'},
      {'id': 'eye', 'icon': _showDrawings ? Icons.visibility_outlined : Icons.visibility_off_outlined, 'label': 'Hide Drawings'},
      {'id': 'trash', 'icon': Icons.delete_outline, 'label': 'Clear All'},
    ];

    return Container(
      width: 36,
      decoration: BoxDecoration(
        color: colors.cardBackground,
        border: Border(
          right: BorderSide(
            color: colors.divider.withValues(alpha: 0.6),
            width: 0.8,
          ),
        ),
      ),
      child: ListView.builder(
        itemCount: tools.length,
        itemBuilder: (context, index) {
          final t = tools[index];
          final isSelected = _activeTool == t['id'];

          return InkWell(
            onTap: () {
              final id = t['id'] as String;
              if (id == 'lock') {
                setState(() => _isLocked = !_isLocked);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_isLocked ? 'Drawings Locked' : 'Drawings Unlocked'),
                    duration: const Duration(milliseconds: 600),
                  ),
                );
              } else if (id == 'eye') {
                setState(() => _showDrawings = !_showDrawings);
              } else if (id == 'trash') {
                setState(() {
                  _userStrokes.clear();
                  _undoStrokes.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All drawings cleared'), duration: Duration(milliseconds: 600)),
                );
              } else {
                setState(() => _activeTool = id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${t['label']} Tool Active'),
                    duration: const Duration(milliseconds: 500),
                  ),
                );
              }
            },
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1E88E5).withValues(alpha: 0.12)
                    : Colors.transparent,
              ),
              child: Center(
                child: Icon(
                  t['icon'] as IconData,
                  size: 17,
                  color: isSelected
                      ? const Color(0xFF1E88E5)
                      : colors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 3. Bottom Dynamic Quick Trade Pad with Price Movement Flashing
  Widget _buildQuickTradePad(
      double bid, double ask, Instrument instrument, TradingColors colors) {
    return Container(
      height: 60,
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left SELL & Right BUY Half Buttons
          Row(
            children: [
              // Left SELL
              Expanded(
                child: Material(
                  color: _sellColor,
                  child: InkWell(
                    onTap: () => _executeQuickTrade(TransactionType.SELL, bid, instrument),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              bid.toStringAsFixed(2),
                              style: GoogleFonts.inter(
                                color: Colors.black,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w900,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                          Text(
                            'SELL',
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Solid Black Divider
              Container(width: 1.5, height: 60, color: Colors.black),

              // Right BUY
              Expanded(
                child: Material(
                  color: _buyColor,
                  child: InkWell(
                    onTap: () => _executeQuickTrade(TransactionType.BUY, ask, instrument),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Center(
                            child: Text(
                              ask.toStringAsFixed(2),
                              style: GoogleFonts.inter(
                                color: Colors.black,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w900,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                          Text(
                            'BUY',
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Center Floating White Stepper with Black Border
          Positioned(
            bottom: 0,
            child: Container(
              width: 142,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.black, width: 2.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Down Arrow (▼)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (_tradeLots > 0.05) {
                          setState(() => _tradeLots =
                              (_tradeLots - 0.05).clamp(0.01, 100.0));
                        }
                      },
                      child: const SizedBox(
                        width: 32,
                        height: 32,
                        child: Center(
                          child: Icon(Icons.arrow_drop_down,
                              size: 24, color: Colors.black),
                        ),
                      ),
                    ),
                  ),

                  // Lot Number (Tappable to type exact lots)
                  InkWell(
                    onTap: () => _showCustomLotDialog(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        _tradeLots.toStringAsFixed(2),
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),

                  // Up Arrow (▲)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() => _tradeLots =
                            (_tradeLots + 0.05).clamp(0.01, 100.0));
                      },
                      child: const SizedBox(
                        width: 32,
                        height: 32,
                        child: Center(
                          child: Icon(Icons.arrow_drop_up,
                              size: 24, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _executeQuickTrade(TransactionType side, double price, Instrument instrument) {
    final engine = ref.read(orderSimulationEngineProvider);
    final request = OrderRequest(
      instrumentToken: instrument.token,
      side: side,
      product: ProductType.NRML,
      kind: OrderKind.MARKET,
      quantity: (_tradeLots * 100).toInt().clamp(1, 10000),
      price: price,
    );
    engine.placeOrder(request);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Instant ${side.name} order executed for ${_tradeLots.toStringAsFixed(2)} lots of ${instrument.symbol} at ${price.toStringAsFixed(2)}',
        ),
        backgroundColor: side == TransactionType.BUY
            ? const Color(0xFF1E2B60)
            : const Color(0xFFE82B57),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showCustomLotDialog(BuildContext context) {
    final controller = TextEditingController(text: _tradeLots.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Enter Lot Size', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Lots', hintText: 'e.g. 0.10, 1.00'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                setState(() => _tradeLots = val.clamp(0.01, 1000.0));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  void _showDateRangePicker(BuildContext context) {
    final ranges = ['1D', '5D', '1M', '3M', '6M', 'YTD', '1Y', '5Y', 'ALL'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Select Date Range',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            const Divider(height: 1),
            Wrap(
              children: ranges.map((r) {
                return InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Date Range set to $r')),
                    );
                  },
                  child: Container(
                    width: 70,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    child: Text(
                      r,
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showTimeframePicker(BuildContext context) {
    final timeframes = [
      {'label': '1m', 'tf': Timeframe.ONE_MIN},
      {'label': '5m', 'tf': Timeframe.FIVE_MIN},
      {'label': '15m', 'tf': Timeframe.FIFTEEN_MIN},
      {'label': '30m', 'tf': Timeframe.THIRTY_MIN},
      {'label': '1h', 'tf': Timeframe.ONE_HOUR},
      {'label': '4h', 'tf': Timeframe.ONE_HOUR},
      {'label': '1D', 'tf': Timeframe.ONE_DAY},
      {'label': '1W', 'tf': Timeframe.ONE_WEEK},
      {'label': '1M', 'tf': Timeframe.ONE_MONTH},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Select Timeframe',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Divider(height: 1),
            Wrap(
              children: timeframes.map((tfItem) {
                final label = tfItem['label'] as String;
                final tf = tfItem['tf'] as Timeframe;
                final isSelected = _selectedTimeframe == label;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedTimeframe = label;
                      _timeframeEnum = tf;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 70,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1E88E5).withValues(alpha: 0.15)
                          : Colors.transparent,
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF1E88E5)
                            : Colors.black87,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showInstrumentPicker(BuildContext context) {
    final colors = context.tradingColors;
    final allInstruments = SeedInstruments.all;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Select Instrument Chart',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: allInstruments.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final inst = allInstruments[index];
                  final isSelected = inst.token == _currentToken;

                  return Material(
                    color: Colors.transparent,
                    child: ListTile(
                      title: Text(
                        inst.symbol,
                        style: GoogleFonts.inter(
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color:
                              isSelected ? colors.primary : colors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '${inst.exchange.name} • ${inst.type.name}',
                        style: GoogleFonts.inter(
                            color: colors.textSecondary, fontSize: 12),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check, color: colors.primary)
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _currentToken = inst.token);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChartSettingsSheet(BuildContext context) {
    final colors = context.tradingColors;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chart Display Settings',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary)),
              const SizedBox(height: 16),
              Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: const Icon(Icons.candlestick_chart_outlined),
                  title: Text('Candlestick Chart',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  trailing: _chartType == ChartType.candle
                      ? const Icon(Icons.check, color: Color(0xFF00A854))
                      : null,
                  onTap: () {
                    setState(() => _chartType = ChartType.candle);
                    Navigator.pop(context);
                  },
                ),
              ),
              Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: const Icon(Icons.show_chart),
                  title: Text('Line Chart',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  trailing: _chartType == ChartType.line
                      ? const Icon(Icons.check, color: Color(0xFF00A854))
                      : null,
                  onTap: () {
                    setState(() => _chartType = ChartType.line);
                    Navigator.pop(context);
                  },
                ),
              ),
              Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: const Icon(Icons.bar_chart),
                  title: Text('Bar Chart',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  trailing: _chartType == ChartType.bar
                      ? const Icon(Icons.check, color: Color(0xFF00A854))
                      : null,
                  onTap: () {
                    setState(() => _chartType = ChartType.bar);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Interactive TradingView Chart Canvas Painter
class _TradingViewInteractiveCanvas extends StatefulWidget {
  final String token;
  final Timeframe timeframeEnum;
  final ChartType chartType;
  final TradingColors colors;
  final double ltp;
  final String activeTool;
  final bool showDrawings;
  final bool isLogScale;
  final bool isPercentScale;
  final List<IndicatorConfig> indicators;
  final List<List<Offset>> userStrokes;
  final List<Offset> currentStroke;
  final ValueChanged<List<Offset>> onStrokeFinished;
  final Function(Offset?, Candle?) onCrosshairUpdate;

  const _TradingViewInteractiveCanvas({
    required this.token,
    required this.timeframeEnum,
    required this.chartType,
    required this.colors,
    required this.ltp,
    required this.activeTool,
    required this.showDrawings,
    required this.isLogScale,
    required this.isPercentScale,
    required this.indicators,
    required this.userStrokes,
    required this.currentStroke,
    required this.onStrokeFinished,
    required this.onCrosshairUpdate,
  });

  @override
  State<_TradingViewInteractiveCanvas> createState() =>
      _TradingViewInteractiveCanvasState();
}

class _TradingViewInteractiveCanvasState
    extends State<_TradingViewInteractiveCanvas> {
  List<Candle> _candles = [];
  double _candleWidth = 8.5;
  double _baseCandleWidth = 8.5;
  double _scrollOffset = 0.0;
  final List<Offset> _inProgressStroke = [];
  Offset? _touchPos;
  Timer? _liveTickTimer;

  // Edge-case controller for this canvas
  late ChartEdgeCaseController _edgeCtrl;

  @override
  void initState() {
    super.initState();
    _edgeCtrl = ChartEdgeCaseController(
      initialState: ChartDataState.loading,
      hasDelayedData: _isDelayedFeed(widget.token),
      priceChangeThreshold: 0.8, // 0.8% tick change triggers flash badge
    );
    _loadCandles();
    _startLiveTicking();
  }

  bool _isDelayedFeed(String token) {
    const delayed = ['global_', 'crypto_', 'fx_'];
    return delayed.any((p) => token.startsWith(p));
  }

  bool _isMarketClosed() {
    final now = DateTime.now();
    final mins = now.hour * 60 + now.minute;
    final isWeekday =
        now.weekday >= DateTime.monday && now.weekday <= DateTime.friday;
    return !isWeekday || mins < 555 || mins > 930;
  }


  void _startLiveTicking() {
    _liveTickTimer?.cancel();
    _liveTickTimer = Timer.periodic(const Duration(milliseconds: 650), (_) {
      if (mounted && _candles.isNotEmpty) {
        setState(() {
          final last = _candles.last;
          final rand = Random();
          final delta = ((rand.nextDouble() - 0.48) * 0.45);
          final newClose = double.parse((last.close + delta).toStringAsFixed(2));
          final newHigh = max(last.high, newClose);
          final newLow = min(last.low, newClose);

          _candles[_candles.length - 1] = Candle(
            time: last.time,
            open: last.open,
            high: newHigh,
            low: newLow,
            close: newClose,
            volume: last.volume + rand.nextInt(10),
          );
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant _TradingViewInteractiveCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.token != widget.token ||
        oldWidget.timeframeEnum != widget.timeframeEnum) {
      // Reset edge-case state on symbol/timeframe change
      _edgeCtrl.onSymbolChanged();
      final isLarge = widget.timeframeEnum == Timeframe.ONE_WEEK ||
          widget.timeframeEnum == Timeframe.ONE_MONTH;
      _loadCandles(isLargeRange: isLarge);
    }
  }


  @override
  void dispose() {
    _liveTickTimer?.cancel();
    _edgeCtrl.dispose();
    super.dispose();
  }


  void _loadCandles({bool isLargeRange = false}) {
    if (isLargeRange) {
      setState(() => _edgeCtrl.startLargeRangeLoad());
    }
    Future.delayed(Duration(milliseconds: isLargeRange ? 900 : 80), () {
      if (!mounted) return;
      final candles = CandleGenerator.generateCandles(
        token: widget.token,
        timeframe: widget.timeframeEnum,
        count: isLargeRange ? 500 : 100,
      );
      setState(() {
        _candles = candles;
        _scrollOffset = 0.0;
        _edgeCtrl.onCandlesLoaded(candles, isMarketClosed: _isMarketClosed());
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check live price ticks for fast-movement detection
    if (_candles.isNotEmpty) {
      final livePrice = _candles.last.close;
      if (_edgeCtrl.checkPriceMovement(livePrice, () => setState(() {}))) {
        // setState already triggered inside checkPriceMovement callback
      }
    }

    final chartCanvas = Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          setState(() {
            _candleWidth =
                (_candleWidth - (event.scrollDelta.dy * 0.02)).clamp(2.5, 36.0);
          });
        }
      },
      child: GestureDetector(
        onDoubleTap: () {
          setState(() {
            _candleWidth = _candleWidth > 12.0 ? 6.5 : 15.0;
          });
        },
        onScaleStart: (details) {
          _baseCandleWidth = _candleWidth;
          if (widget.activeTool != 'crosshair' && widget.activeTool != 'zoom') {
            _inProgressStroke.clear();
            _inProgressStroke.add(details.localFocalPoint);
            setState(() {});
          } else {
            setState(() => _touchPos = details.localFocalPoint);
          }
        },
        onScaleUpdate: (details) {
          setState(() {
            if (details.scale != 1.0) {
              _candleWidth =
                  (_baseCandleWidth * details.scale).clamp(2.5, 36.0);
            }
            if (details.focalPointDelta.dx != 0 &&
                (widget.activeTool == 'crosshair' ||
                    details.pointerCount > 1 ||
                    widget.activeTool == 'zoom')) {
              _scrollOffset += details.focalPointDelta.dx;
            }
            if (widget.activeTool != 'crosshair' &&
                widget.activeTool != 'zoom') {
              _inProgressStroke.add(details.localFocalPoint);
            } else {
              _touchPos = details.localFocalPoint;
            }
          });
        },
        onScaleEnd: (_) {
          if (widget.activeTool != 'crosshair' &&
              widget.activeTool != 'zoom' &&
              _inProgressStroke.isNotEmpty) {
            widget.onStrokeFinished(List.from(_inProgressStroke));
            _inProgressStroke.clear();
            setState(() {});
          } else {
            setState(() => _touchPos = null);
            widget.onCrosshairUpdate(null, null);
          }
        },
        child: ClipRect(
          child: CustomPaint(
            size: Size.infinite,
            painter: _TvChartCanvasPainter(
              candles: _candles,
              candleWidth: _candleWidth,
              scrollOffset: _scrollOffset,
              chartType: widget.chartType,
              colors: widget.colors,
              ltp: _candles.isNotEmpty ? _candles.last.close : widget.ltp,
              activeTool: widget.activeTool,
              showDrawings: widget.showDrawings,
              isLogScale: widget.isLogScale,
              isPercentScale: widget.isPercentScale,
              indicators: widget.indicators,
              userStrokes: widget.userStrokes,
              currentStroke: _inProgressStroke,
              crosshairPos: _touchPos,
              onCandleHover: (c) => widget.onCrosshairUpdate(_touchPos, c),
            ),
          ),
        ),
      ),
    );

    // Wrap with edge-case dispatcher
    return ChartEdgeCaseWrapper(
      state: _edgeCtrl.state,
      colors: widget.colors,
      symbol: widget.token.toUpperCase(),
      hasDelayedData: _edgeCtrl.hasDelayedDisclosure,
      isFastMovement: _edgeCtrl.isFastMovement,
      fastMovementPercent: _edgeCtrl.fastMovementPercent,
      onRetry: () => setState(() => _loadCandles()),
      child: chartCanvas,
    );
  }
}


class _TvChartCanvasPainter extends CustomPainter {
  final List<Candle> candles;
  final double candleWidth;
  final double scrollOffset;
  final ChartType chartType;
  final TradingColors colors;
  final double ltp;
  final String activeTool;
  final bool showDrawings;
  final bool isLogScale;
  final bool isPercentScale;
  final List<IndicatorConfig> indicators;
  final List<List<Offset>> userStrokes;
  final List<Offset> currentStroke;
  final Offset? crosshairPos;
  final ValueChanged<Candle?> onCandleHover;

  _TvChartCanvasPainter({
    required this.candles,
    required this.candleWidth,
    required this.scrollOffset,
    required this.chartType,
    required this.colors,
    required this.ltp,
    required this.activeTool,
    required this.showDrawings,
    required this.isLogScale,
    required this.isPercentScale,
    required this.indicators,
    required this.userStrokes,
    required this.currentStroke,
    required this.crosshairPos,
    required this.onCandleHover,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    const priceAxisWidth = 68.0; // Ample width to prevent text cutting
    const timeAxisHeight = 22.0;
    final chartWidth = size.width - priceAxisWidth;
    final chartHeight = size.height - timeAxisHeight;

    // Dynamic Background (Deep OLED Black in Dark Mode)
    final bgPaint = Paint()..color = colors.chartBackground;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final totalCandles = candles.length;
    final spacing = candleWidth * 0.35;
    final fullStep = candleWidth + spacing;

    // Viewport index calculation
    final maxScroll = max(0.0, (totalCandles * fullStep) - chartWidth);
    final clampedOffset = scrollOffset.clamp(-maxScroll, 0.0);

    final rightX = chartWidth + clampedOffset;
    final firstVisibleIdx = ((((0 - rightX + (totalCandles * fullStep)) / fullStep).floor() - 2)).clamp(0, totalCandles - 1);
    final lastVisibleIdx = ((((chartWidth - rightX + (totalCandles * fullStep)) / fullStep).ceil() + 2)).clamp(0, totalCandles - 1);

    if (firstVisibleIdx > lastVisibleIdx) return;

    // Min / Max Price in viewport
    double minPrice = double.infinity;
    double maxPrice = -double.infinity;

    for (int i = firstVisibleIdx; i <= lastVisibleIdx; i++) {
      final c = candles[i];
      if (c.low < minPrice) minPrice = c.low;
      if (c.high > maxPrice) maxPrice = c.high;
    }

    if (minPrice == double.infinity || maxPrice == -double.infinity) {
      minPrice = ltp - 20;
      maxPrice = ltp + 20;
    }

    final pricePadding = (maxPrice - minPrice) * 0.10;
    minPrice -= pricePadding;
    maxPrice += pricePadding;
    final priceRange = (maxPrice - minPrice).clamp(1.0, 1000000.0);

    // Draw Subtle Dotted Grid Lines & Price Labels
    final gridPaint = Paint()
      ..color = colors.chartGrid
      ..strokeWidth = 1.0;

    const int gridSteps = 9;
    for (int i = 0; i <= gridSteps; i++) {
      final y = (chartHeight / gridSteps) * i;
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);

      final priceAtY = maxPrice - (i * (priceRange / gridSteps));
      final priceLabel = isPercentScale
          ? '${(((priceAtY - ltp) / ltp) * 100).toStringAsFixed(2)}%'
          : priceAtY.toStringAsFixed(2);

      final textPainter = TextPainter(
        text: TextSpan(
          text: priceLabel,
          style: GoogleFonts.inter(
            color: colors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(chartWidth + 4, y - (textPainter.height / 2)));
    }

    // Right Axis Border line
    final axisLinePaint = Paint()
      ..color = colors.divider
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(chartWidth, 0), Offset(chartWidth, size.height), axisLinePaint);
    canvas.drawLine(Offset(0, chartHeight), Offset(size.width, chartHeight), axisLinePaint);

    // Candle Render Loop
    const bullColor = Color(0xFF00897B); // Teal-Cyan Bullish
    const bearColor = Color(0xFFE53935); // Crimson-Red Bearish

    Candle? closestCandle;
    double closestDist = double.infinity;

    for (int i = 0; i < totalCandles; i++) {
      final candle = candles[i];
      final x = chartWidth - ((totalCandles - 1 - i) * fullStep) + clampedOffset;

      if (x < -candleWidth || x > chartWidth + candleWidth) continue;

      if (crosshairPos != null) {
        final dist = (crosshairPos!.dx - x).abs();
        if (dist < closestDist) {
          closestDist = dist;
          closestCandle = candle;
        }
      }

      final isBull = candle.isBullish;
      final candleColor = isBull ? bullColor : bearColor;

      final openY = chartHeight - (((candle.open - minPrice) / priceRange) * chartHeight);
      final closeY = chartHeight - (((candle.close - minPrice) / priceRange) * chartHeight);
      final highY = chartHeight - (((candle.high - minPrice) / priceRange) * chartHeight);
      final lowY = chartHeight - (((candle.low - minPrice) / priceRange) * chartHeight);

      if (chartType == ChartType.candle) {
        // Wick line
        final wickPaint = Paint()
          ..color = candleColor
          ..strokeWidth = 1.2;
        canvas.drawLine(Offset(x, highY), Offset(x, lowY), wickPaint);

        // Body rect
        final bodyTop = min(openY, closeY);
        final bodyHeight = max(2.0, (openY - closeY).abs());
        final bodyPaint = Paint()..color = candleColor;
        canvas.drawRect(
          Rect.fromLTWH(x - (candleWidth / 2), bodyTop, candleWidth, bodyHeight),
          bodyPaint,
        );
      } else if (chartType == ChartType.bar) {
        final barPaint = Paint()
          ..color = candleColor
          ..strokeWidth = 1.5;
        canvas.drawLine(Offset(x, highY), Offset(x, lowY), barPaint);
        canvas.drawLine(Offset(x - (candleWidth / 2), openY), Offset(x, openY), barPaint);
        canvas.drawLine(Offset(x + (candleWidth / 2), closeY), Offset(x, closeY), barPaint);
      }
    }

    if (closestCandle != null) {
      onCandleHover(closestCandle);
    }

    // Draw Line Chart
    if (chartType == ChartType.line) {
      final linePath = Path();
      bool lineStarted = false;
      for (int i = 0; i < totalCandles; i++) {
        final candle = candles[i];
        final x = chartWidth - ((totalCandles - 1 - i) * fullStep) + clampedOffset;
        final closeY = chartHeight - (((candle.close - minPrice) / priceRange) * chartHeight);
        if (!lineStarted) {
          linePath.moveTo(x, closeY);
          lineStarted = true;
        } else {
          linePath.lineTo(x, closeY);
        }
      }
      final linePaint = Paint()
        ..color = const Color(0xFF1E88E5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawPath(linePath, linePaint);
    }

    // Draw SMA Indicator Overlay
    if (indicators.any((ind) => ind.isEnabled && ind.type == IndicatorType.SMA)) {
      final smaValues = IndicatorMath.calculateSma(candles, 20);
      final smaPath = Path();
      bool smaStarted = false;

      for (int i = 0; i < totalCandles; i++) {
        final sma = smaValues[i];
        if (sma != null) {
          final x = chartWidth - ((totalCandles - 1 - i) * fullStep) + clampedOffset;
          final smaY = chartHeight - (((sma - minPrice) / priceRange) * chartHeight);
          if (!smaStarted) {
            smaPath.moveTo(x, smaY);
            smaStarted = true;
          } else {
            smaPath.lineTo(x, smaY);
          }
        }
      }

      final smaPaint = Paint()
        ..color = const Color(0xFFFB8C00) // Orange SMA line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(smaPath, smaPaint);
    }

    // Draw User Strokes / Freehand Drawings
    if (showDrawings) {
      final strokePaint = Paint()
        ..color = const Color(0xFF1E88E5)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.0;

      for (final stroke in userStrokes) {
        if (stroke.length > 1) {
          final p = Path()..moveTo(stroke.first.dx, stroke.first.dy);
          for (int s = 1; s < stroke.length; s++) {
            p.lineTo(stroke[s].dx, stroke[s].dy);
          }
          canvas.drawPath(p, strokePaint);
        }
      }

      if (currentStroke.length > 1) {
        final p = Path()..moveTo(currentStroke.first.dx, currentStroke.first.dy);
        for (int s = 1; s < currentStroke.length; s++) {
          p.lineTo(currentStroke[s].dx, currentStroke[s].dy);
        }
        canvas.drawPath(p, strokePaint);
      }
    }

    // Crosshair Lines
    if (crosshairPos != null && crosshairPos!.dx <= chartWidth) {
      final chPaint = Paint()
        ..color = colors.textSecondary.withValues(alpha: 0.8)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;

      // Vertical line
      canvas.drawLine(
        Offset(crosshairPos!.dx, 0),
        Offset(crosshairPos!.dx, chartHeight),
        chPaint,
      );
      // Horizontal line
      canvas.drawLine(
        Offset(0, crosshairPos!.dy),
        Offset(chartWidth, crosshairPos!.dy),
        chPaint,
      );
    }

    // Current LTP Dotted Horizontal Line & Teal Pill on Right Axis
    final ltpY = chartHeight - (((ltp - minPrice) / priceRange) * chartHeight);
    if (ltpY >= 0 && ltpY <= chartHeight) {
      final ltpDottedPaint = Paint()
        ..color = const Color(0xFF00897B)
        ..strokeWidth = 1.0;

      // Draw dashed horizontal line
      double dashX = 0;
      while (dashX < chartWidth) {
        canvas.drawLine(Offset(dashX, ltpY), Offset(dashX + 4, ltpY), ltpDottedPaint);
        dashX += 7;
      }

      // Draw Teal Pill Tag on Right Price Scale
      final pillPaint = Paint()..color = const Color(0xFF00897B);
      final pillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(chartWidth + 1, ltpY - 10, priceAxisWidth - 2, 20),
        const Radius.circular(3),
      );
      canvas.drawRRect(pillRect, pillPaint);

      final ltpPainter = TextPainter(
        text: TextSpan(
          text: ltp.toStringAsFixed(2),
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      ltpPainter.paint(
        canvas,
        Offset(
          chartWidth + ((priceAxisWidth - ltpPainter.width) / 2),
          ltpY - (ltpPainter.height / 2),
        ),
      );
    }

    // Time axis labels (Aug, 08:00, Sep, 4)
    final timeLabels = ['Aug', '08:00', 'Sep', '4'];
    final timeStep = chartWidth / (timeLabels.length + 1);
    for (int i = 0; i < timeLabels.length; i++) {
      final tX = timeStep * (i + 1);
      final tp = TextPainter(
        text: TextSpan(
          text: timeLabels[i],
          style: GoogleFonts.inter(
            color: colors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(tX - (tp.width / 2), chartHeight + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _TvChartCanvasPainter oldDelegate) => true;
}
