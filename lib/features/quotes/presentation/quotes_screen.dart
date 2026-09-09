import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/mock/order_simulation_engine.dart';
import '../../../data/mock/seed_instruments.dart';
import '../../../data/mock/settings_repository.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/market_status_strip.dart';
import '../../../shared_widgets/mt_price_text.dart';
import '../../../shared_widgets/news_ticker_strip.dart';
import '../../../shared_widgets/script_selector_bar.dart';
import '../../funds/presentation/add_funds_sheet.dart';
import '../../funds/presentation/withdraw_funds_sheet.dart';
import '../../order_entry/presentation/order_entry_sheet.dart';
import '../../profile_settings/presentation/live_chat_sheet.dart';
import '../../watchlist/presentation/watchlist_controller.dart';

class QuoteItemData {
  final String id;
  final String symbol;
  final String category;
  double change;
  double changePercent;
  double bid;
  double ask;
  int spread;
  double low;
  double high;
  double open;
  double close;
  double ltp;
  DateTime timestamp;
  PriceColorMode bidColorMode;
  PriceColorMode askColorMode;

  QuoteItemData({
    required this.id,
    required this.symbol,
    required this.category,
    required this.change,
    required this.changePercent,
    required this.bid,
    required this.ask,
    required this.spread,
    required this.low,
    required this.high,
    required this.open,
    required this.close,
    required this.ltp,
    required this.timestamp,
    this.bidColorMode = PriceColorMode.normal,
    this.askColorMode = PriceColorMode.normal,
  });
}

class QuotesScreen extends ConsumerStatefulWidget {
  const QuotesScreen({super.key});

  @override
  ConsumerState<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends ConsumerState<QuotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isProView = true;
  bool _isOneClickTrade = false;
  bool _isEditMode = false;
  bool _isExecutingOneClick = false;
  bool _isOpeningSheet = false;
  final Set<String> _selectedForDelete = {};
  String _query = '';
  Timer? _liveSimulationTimer;

  late List<QuoteItemData> _quotes;

  @override
  void initState() {
    super.initState();
    _quotes = [
      QuoteItemData(
        id: 'copper_mcx',
        symbol: 'COPPER MCX Sep',
        category: 'COMMODITIES',
        change: -3.85,
        changePercent: -0.28,
        bid: 1368.20,
        ask: 1368.60,
        spread: 40,
        low: 1361.10,
        high: 1368.60,
        open: 1366.00,
        close: 1372.40,
        ltp: 1368.55,
        timestamp: DateTime.now(),
        bidColorMode: PriceColorMode.red,
        askColorMode: PriceColorMode.blue,
      ),
      QuoteItemData(
        id: 'ltc_spot',
        symbol: 'Litecoin Spot',
        category: 'CRYPTO',
        change: -0.65,
        changePercent: -1.30,
        bid: 49.27,
        ask: 49.31,
        spread: 4,
        low: 48.84,
        high: 50.06,
        open: 49.91,
        close: 49.92,
        ltp: 49.27,
        timestamp: DateTime.now(),
        bidColorMode: PriceColorMode.normal,
        askColorMode: PriceColorMode.blue,
      ),
      QuoteItemData(
        id: 'mankind_sep',
        symbol: 'MANKIND Sep',
        category: 'EQUITIES',
        change: 23.60,
        changePercent: 1.00,
        bid: 2382.10,
        ask: 2386.50,
        spread: 440,
        low: 2347.30,
        high: 2388.00,
        open: 2347.30,
        close: 2360.40,
        ltp: 2384.00,
        timestamp: DateTime.now(),
        bidColorMode: PriceColorMode.red,
        askColorMode: PriceColorMode.red,
      ),
      QuoteItemData(
        id: 'gold_mcx',
        symbol: 'GOLD MCX Oct',
        category: 'COMMODITIES',
        change: -1680.00,
        changePercent: -1.11,
        bid: 15002.90,
        ask: 15004.90,
        spread: 20,
        low: 149665.0,
        high: 150329.0,
        open: 150033.0,
        close: 151729.0,
        ltp: 150049.0,
        timestamp: DateTime.now(),
        bidColorMode: PriceColorMode.normal,
        askColorMode: PriceColorMode.normal,
      ),
      QuoteItemData(
        id: 'mazdock_sep',
        symbol: 'MAZDOCK Sep',
        category: 'EQUITIES',
        change: -19.90,
        changePercent: -0.80,
        bid: 2466.30,
        ask: 2469.30,
        spread: 300,
        low: 2455.30,
        high: 2480.00,
        open: 2480.00,
        close: 2488.90,
        ltp: 2469.00,
        timestamp: DateTime.now(),
        bidColorMode: PriceColorMode.blue,
        askColorMode: PriceColorMode.red,
      ),
      QuoteItemData(
        id: 'natgas_mcx',
        symbol: 'NATURALGAS MCX Sep',
        category: 'COMMODITIES',
        change: 2.90,
        changePercent: 1.05,
        bid: 280.10,
        ask: 281.30,
        spread: 10,
        low: 278.50,
        high: 281.30,
        open: 279.00,
        close: 278.40,
        ltp: 280.10,
        timestamp: DateTime.now(),
        bidColorMode: PriceColorMode.normal,
        askColorMode: PriceColorMode.normal,
      ),
      QuoteItemData(
        id: 'crude_mcx',
        symbol: 'CRUDEOIL MCX Oct',
        category: 'COMMODITIES',
        change: -35.00,
        changePercent: -0.57,
        bid: 6142.00,
        ask: 6145.00,
        spread: 30,
        low: 6120.00,
        high: 6195.00,
        open: 6180.00,
        close: 6177.00,
        ltp: 6142.00,
        timestamp: DateTime.now(),
        bidColorMode: PriceColorMode.red,
        askColorMode: PriceColorMode.red,
      ),
      QuoteItemData(
        id: 'nifty_50',
        symbol: 'NIFTY 50',
        category: 'INDICES',
        change: 74.50,
        changePercent: 0.30,
        bid: 25150.25,
        ask: 25151.50,
        spread: 12,
        low: 25080.00,
        high: 25185.00,
        open: 25095.00,
        close: 25075.75,
        ltp: 25150.25,
        timestamp: DateTime.now(),
        bidColorMode: PriceColorMode.blue,
        askColorMode: PriceColorMode.normal,
      ),
      QuoteItemData(
        id: 'crypto_btcusd',
        symbol: 'Bitcoin Spot (BTC)',
        category: 'CRYPTO',
        change: 1420.50,
        changePercent: 2.49,
        bid: 58450.00,
        ask: 58452.50,
        spread: 250,
        low: 56980.00,
        high: 58600.00,
        open: 57029.50,
        close: 57029.50,
        ltp: 58450.00,
        timestamp: DateTime.now(),
        bidColorMode: PriceColorMode.blue,
        askColorMode: PriceColorMode.blue,
      ),
      QuoteItemData(
        id: 'crypto_ethusd',
        symbol: 'Ethereum Spot (ETH)',
        category: 'CRYPTO',
        change: -32.40,
        changePercent: -1.27,
        bid: 2510.00,
        ask: 2510.80,
        spread: 80,
        low: 2480.00,
        high: 2555.00,
        open: 2542.40,
        close: 2542.40,
        ltp: 2510.00,
        timestamp: DateTime.now(),
        bidColorMode: PriceColorMode.red,
        askColorMode: PriceColorMode.red,
      ),
      QuoteItemData(
        id: 'fx_usdinr',
        symbol: 'USDINR Sep FUT',
        category: 'FOREX',
        change: 0.08,
        changePercent: 0.10,
        bid: 83.9425,
        ask: 83.9450,
        spread: 2,
        low: 83.8500,
        high: 83.9800,
        open: 83.8625,
        close: 83.8625,
        ltp: 83.9425,
        timestamp: DateTime.now(),
        bidColorMode: PriceColorMode.blue,
        askColorMode: PriceColorMode.normal,
      ),
      QuoteItemData(
        id: 'fx_eurusd',
        symbol: 'EURUSD Spot',
        category: 'FOREX',
        change: -0.0035,
        changePercent: -0.32,
        bid: 1.1045,
        ask: 1.1047,
        spread: 2,
        low: 1.1020,
        high: 1.1090,
        open: 1.1080,
        close: 1.1080,
        ltp: 1.1045,
        timestamp: DateTime.now(),
        bidColorMode: PriceColorMode.red,
        askColorMode: PriceColorMode.red,
      ),
      QuoteItemData(
        id: 'global_us500',
        symbol: 'US 500 (S&P 500)',
        category: 'INDICES',
        change: 28.40,
        changePercent: 0.52,
        bid: 5520.20,
        ask: 5521.00,
        spread: 8,
        low: 5490.00,
        high: 5535.00,
        open: 5491.80,
        close: 5491.80,
        ltp: 5520.20,
        timestamp: DateTime.now(),
        bidColorMode: PriceColorMode.blue,
        askColorMode: PriceColorMode.blue,
      ),
    ];

    _startLiveSimulation();
  }

  void _startLiveSimulation() {
    _liveSimulationTimer =
        Timer.periodic(const Duration(milliseconds: 1600), (_) {
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < _quotes.length; i++) {
          if (i % 2 == 0) {
            final delta = (i.isEven ? 0.20 : -0.20);
            _quotes[i].bid += delta;
            _quotes[i].ask += delta;
            _quotes[i].ltp = _quotes[i].bid;
            _quotes[i].timestamp = DateTime.now();
            _quotes[i].bidColorMode =
                delta > 0 ? PriceColorMode.blue : PriceColorMode.red;
            _quotes[i].askColorMode =
                delta > 0 ? PriceColorMode.blue : PriceColorMode.red;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _liveSimulationTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedForDelete.length == _quotes.length) {
        _selectedForDelete.clear();
      } else {
        _selectedForDelete.addAll(_quotes.map((q) => q.id));
      }
    });
  }

  void _deleteSelected() {
    if (_selectedForDelete.isEmpty) return;
    setState(() {
      _quotes.removeWhere((q) => _selectedForDelete.contains(q.id));
      _selectedForDelete.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final settings = ref.watch(appSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredQuotes = _query.isEmpty
        ? _quotes
        : _quotes
            .where((q) => q.symbol.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    final Map<String, List<QuoteItemData>> groupedQuotes = {};
    if (settings.quotesGrouping) {
      for (final quote in filteredQuotes) {
        groupedQuotes.putIfAbsent(quote.category, () => []).add(quote);
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: _isEditMode
            ? IconButton(
                icon:
                    Icon(LucideIcons.arrowLeft, color: colors.textPrimary, size: 22),
                onPressed: () => setState(() {
                  _isEditMode = false;
                  _selectedForDelete.clear();
                }),
                tooltip: 'Exit Edit',
              )
            : Builder(
                builder: (innerContext) => IconButton(
                  icon: Icon(LucideIcons.menu, color: colors.textPrimary, size: 22),
                  onPressed: () {
                    final rootScaffold = innerContext
                        .findRootAncestorStateOfType<ScaffoldState>();
                    if (rootScaffold != null && rootScaffold.hasDrawer) {
                      rootScaffold.openDrawer();
                    } else {
                      Scaffold.of(innerContext).openDrawer();
                    }
                  },
                  tooltip: 'Menu',
                ),
              ),
        centerTitle: true,
        title: Text(
          'Quotes',
          style: AppTypography.h1(
              color: colors.textPrimary, weight: FontWeight.w600),
        ),
        actions: _isEditMode
            ? [
                IconButton(
                  icon: Icon(
                    _selectedForDelete.length == _quotes.length &&
                            _quotes.isNotEmpty
                        ? LucideIcons.checkSquare
                        : LucideIcons.square,
                    color: colors.textPrimary,
                    size: 22,
                  ),
                  onPressed: _toggleSelectAll,
                  tooltip: 'Select All',
                ),
                IconButton(
                  icon: Icon(
                    LucideIcons.copy,
                    color: colors.textPrimary,
                    size: 22,
                  ),
                  onPressed: _deleteSelected,
                  tooltip: 'Delete / Manage Selected',
                ),
                IconButton(
                  icon: Icon(LucideIcons.check, color: colors.textPrimary, size: 22),
                  onPressed: () => setState(() {
                    _isEditMode = false;
                    _selectedForDelete.clear();
                  }),
                  tooltip: 'Done',
                ),
                const SizedBox(width: 4),
              ]
            : [
                IconButton(
                  icon: Icon(LucideIcons.layoutGrid,
                      color: colors.textPrimary, size: 20),
                  onPressed: () => context.push('/heatmap'),
                  tooltip: 'Market Heatmap',
                ),
                IconButton(
                  icon: Icon(LucideIcons.folderOpen,
                      color: colors.textPrimary, size: 22),
                  onPressed: () => _showManageWatchlistSheet(context, colors),
                  tooltip: 'Manage Watchlists',
                ),
                IconButton(
                  icon: Icon(LucideIcons.plus, color: colors.textPrimary, size: 22),
                  onPressed: () => context.push('/add-script'),
                  tooltip: 'Add Script',
                ),
                IconButton(
                  icon: Icon(LucideIcons.edit3,
                      color: colors.textPrimary, size: 22),
                  onPressed: () => setState(() => _isEditMode = true),
                  tooltip: 'Edit Scripts',
                ),
                const SizedBox(width: 4),
              ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Dual-line Public & Private News Ticker Strip (Permanently Pinned)
              NewsTickerStrip(
                onPublicNewsTap: () => context.push('/news'),
                onPrivateNewsTap: () => context.push('/mails'),
              ),

              // Real-time Market Status Strip (NSE/MCX Open/Closed & IST Timezone)
              const MarketStatusStrip(),

              // Dual Script Selector Bar (Sticky Scripts Toggle)
              if (settings.showStickyScripts)
                const ScriptSelectorBar(),

              // Scrollable Quotes & Actions Area
              Expanded(
                child: Container(
                  color: isDark ? Colors.black : colors.background,
                  child: ClipRect(
                    clipBehavior: Clip.hardEdge,
                    child: CustomScrollView(
                      clipBehavior: Clip.hardEdge,
                      slivers: [
                    // Collapsible Header Section (Deposit/Withdraw, Toggles, Search)
                    SliverToBoxAdapter(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // DEPOSIT & WITHDRAWAL Action Buttons Bar
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 4.0),
                            child: Row(
                              children: [
                                // DEPOSIT Button (Deep Navy Blue)
                                Expanded(
                                  child: SizedBox(
                                    height: 38,
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          AddFundsSheet.show(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF1D357F),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(6)),
                                        elevation: 0,
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: const Text(
                                        'DEPOSIT',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                            fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // WITHDRAWAL Button (Vibrant Rose Red)
                                Expanded(
                                  child: SizedBox(
                                    height: 38,
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          WithdrawFundsSheet.show(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(6)),
                                        elevation: 0,
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: const Text(
                                        'WITHDRAWAL',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                            fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Pro View & One Click Trade Toggles Bar
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 4.0),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Pro View Switch
                                  Row(
                                    children: [
                                      Transform.scale(
                                        scale: 0.75,
                                        child: Switch(
                                          value: _isProView,
                                          activeColor: colors.primary,
                                          onChanged: (val) =>
                                              setState(() => _isProView = val),
                                        ),
                                      ),
                                      Text(
                                        'Pro View',
                                        style: AppTypography.caption(
                                            color: colors.textPrimary,
                                            weight: FontWeight.w600),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(width: 12),

                                  // Live Last Updated Timestamp Badge
                                  Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF00A854),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Live • ${DateFormat('HH:mm:ss').format(DateTime.now())}',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(width: 12),

                                  // One Click Trade Switch
                                  Row(
                                    children: [
                                      Text(
                                        settings.defaultLots > 0
                                            ? 'One Click (${settings.defaultLots.toStringAsFixed(1)}L)'
                                            : 'One Click Trade',
                                        style: AppTypography.caption(
                                            color: colors.textPrimary,
                                            weight: FontWeight.w600),
                                      ),
                                      Transform.scale(
                                        scale: 0.75,
                                        child: Switch(
                                          value: _isOneClickTrade,
                                          activeColor: colors.primary,
                                          onChanged: (val) => setState(
                                              () => _isOneClickTrade = val),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Search Bar
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 4.0),
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color:
                                        colors.divider.withValues(alpha: 0.6)),
                              ),
                              child: TextField(
                                controller: _searchController,
                                textAlignVertical: TextAlignVertical.center,
                                style: AppTypography.body(
                                    color: colors.textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'Search by Script Name',
                                  hintStyle: AppTypography.body(
                                      color: colors.textSecondary),
                                  prefixIcon: Icon(LucideIcons.search,
                                      color: colors.textSecondary
                                          .withValues(alpha: 0.7),
                                      size: 18),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(LucideIcons.x,
                                              color: colors.textSecondary, size: 16),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _query = '');
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                ),
                                onChanged: (val) =>
                                    setState(() => _query = val),
                              ),
                            ),
                          ),

                          // Top Movers (Gainers & Losers) Horizontal Carousel Strip
                          _buildTopMoversStrip(colors),
                        ],
                      ),
                    ),

                    // Pinned Table Header Strip (Script | Bid | Ask)
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _QuotesTableHeaderDelegate(colors: colors),
                    ),

                    // Quotes List
                    if (_isEditMode)
                      SliverReorderableList(
                        itemCount: filteredQuotes.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex--;
                            final item = _quotes.removeAt(oldIndex);
                            _quotes.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          final item = filteredQuotes[index];
                          return ReorderableDelayedDragStartListener(
                            key: ValueKey(item.id),
                            index: index,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        color: colors.divider
                                            .withValues(alpha: 0.5),
                                        width: 0.5)),
                              ),
                              child: _buildQuoteRow(item, colors, index: index),
                            ),
                          );
                        },
                      )
                    else if (settings.quotesGrouping)
                      ...groupedQuotes.entries.expand((entry) => [
                        SliverToBoxAdapter(
                          child: _buildCategoryHeader(
                              entry.key, entry.value.length, colors),
                        ),
                        SliverList.separated(
                          itemCount: entry.value.length,
                          separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: isDark
                                  ? const Color(0xFF141414)
                                  : colors.divider),
                          itemBuilder: (context, index) {
                            final item = entry.value[index];
                            return Container(
                              color: isDark ? Colors.black : colors.background,
                              child: _buildQuoteRow(item, colors),
                            );
                          },
                        ),
                      ])
                    else
                      SliverList.separated(
                        itemCount: filteredQuotes.length,
                        separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: isDark
                                ? const Color(0xFF141414)
                                : colors.divider),
                        itemBuilder: (context, index) {
                          final item = filteredQuotes[index];
                          return Container(
                            color: isDark ? Colors.black : colors.background,
                            child: _buildQuoteRow(item, colors),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
            ],
          ),

          // Floating Support Chat Headset Button (in normal mode)
          if (!_isEditMode)
            Positioned(
              right: 16,
              bottom: 12,
              child: GestureDetector(
                onTap: () => _openSupportModal(context),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.headphones,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuoteRow(QuoteItemData item, TradingColors colors,
      {int? index}) {
    final timeStr = DateFormat('HH:mm:ss.SSS').format(item.timestamp);
    final isChecked = _selectedForDelete.contains(item.id);

    // Single-line clean black text view when Pro View is closed (Classic View)
    if (!_isProView) {
      return InkWell(
        onTap: () {
          if (_isEditMode) {
            setState(() {
              if (isChecked) {
                _selectedForDelete.remove(item.id);
              } else {
                _selectedForDelete.add(item.id);
              }
            });
          } else {
            _handleQuoteTap(item);
          }
        },
        child: Container(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Row(
            children: [
              // Edit Mode Checkbox
              if (_isEditMode) ...[
                Checkbox(
                  value: isChecked,
                  activeColor: colors.primary,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedForDelete.add(item.id);
                      } else {
                        _selectedForDelete.remove(item.id);
                      }
                    });
                  },
                ),
              ],

              // Script Symbol in bold black text
              Expanded(
                flex: 4,
                child: Text(
                  item.symbol,
                  style: AppTypography.body(
                    color: colors.textPrimary,
                    weight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Bid price in black text
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    CurrencyFormatter.format(item.bid, showSymbol: false),
                    style: AppTypography.body(
                      color: colors.textPrimary,
                      weight: FontWeight.w700,
                      tabular: true,
                    ),
                  ),
                ),
              ),

              // Ask price in black text
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    CurrencyFormatter.format(item.ask, showSymbol: false),
                    style: AppTypography.body(
                      color: colors.textPrimary,
                      weight: FontWeight.w700,
                      tabular: true,
                    ),
                  ),
                ),
              ),

              // Edit Mode Reorder Handle
              if (_isEditMode && index != null) ...[
                const SizedBox(width: 8),
                ReorderableDragStartListener(
                  index: index,
                  child: Icon(
                    LucideIcons.gripVertical,
                    color: colors.textSecondary,
                    size: 20,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Pro View
    return InkWell(
      onTap: () {
        if (_isEditMode) {
          setState(() {
            if (isChecked) {
              _selectedForDelete.remove(item.id);
            } else {
              _selectedForDelete.add(item.id);
            }
          });
        } else {
          _handleQuoteTap(item);
        }
      },
      child: Container(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            // Edit Mode Checkbox
            if (_isEditMode) ...[
              Checkbox(
                value: isChecked,
                activeColor: colors.primary,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedForDelete.add(item.id);
                    } else {
                      _selectedForDelete.remove(item.id);
                    }
                  });
                },
              ),
            ],

            // Main Quote Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Change + Bid / Ask
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Change indicator
                      Expanded(
                        flex: 4,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.lineChart,
                                size: 14,
                                color: colors.textPrimary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${CurrencyFormatter.formatSigned(item.change, showSymbol: false)} (${CurrencyFormatter.formatPercent(item.changePercent)})',
                                style: AppTypography.labelSmall(
                                  color: colors.textPrimary,
                                  weight: FontWeight.w500,
                                  tabular: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Bid
                      Expanded(
                        flex: 3,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: MtPriceText(
                            price: item.bid,
                            colorMode: item.bidColorMode,
                          ),
                        ),
                      ),

                      // Ask
                      Expanded(
                        flex: 3,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: MtPriceText(
                            price: item.ask,
                            colorMode: item.askColorMode,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Script Symbol Title
                  Text(
                    item.symbol,
                    style: AppTypography.body(
                      color: colors.textPrimary,
                      weight: FontWeight.w700,
                    ),
                  ),

                  if (_isProView) ...[
                    const SizedBox(height: 3),
                    // Pro View Row 1: Timestamp + Spread + Low / High
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Text(
                                  timeStr,
                                  style: AppTypography.labelSmall(
                                      color: colors.textSecondary, tabular: true),
                                ),
                                const SizedBox(width: 4),
                                Icon(LucideIcons.arrowLeftRight,
                                    size: 11, color: colors.textSecondary),
                                const SizedBox(width: 2),
                                Text(
                                  '${item.spread}',
                                  style: AppTypography.labelSmall(
                                      color: colors.textSecondary, tabular: true),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                'L: ${CurrencyFormatter.format(item.low, showSymbol: false)}',
                                style: AppTypography.labelSmall(
                                    color: colors.textSecondary, tabular: true),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'H: ${CurrencyFormatter.format(item.high, showSymbol: false)}',
                              style: AppTypography.labelSmall(
                                  color: colors.textSecondary, tabular: true),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 2),
                    // Pro View Row 2: O: Open | C: Close | L: Last
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            'O: ${CurrencyFormatter.format(item.open, showSymbol: false)}',
                            style: AppTypography.labelSmall(
                                color: colors.textSecondary, tabular: true),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'C: ${CurrencyFormatter.format(item.close, showSymbol: false)}',
                              style: AppTypography.labelSmall(
                                  color: colors.textSecondary, tabular: true),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'L: ${CurrencyFormatter.format(item.ltp, showSymbol: false)}',
                              style: AppTypography.labelSmall(
                                  color: colors.textSecondary, tabular: true),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Edit Mode: 6-dot Reorder Drag Handle (:::)
            if (_isEditMode && index != null) ...[
              const SizedBox(width: 8),
              ReorderableDragStartListener(
                index: index,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Icon(
                    LucideIcons.gripVertical,
                    color: colors.textSecondary,
                    size: 24,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Quote Tap Action Sheet (Matching WhatsApp Image 2026-09-02 at 10.20.31 AM.jpeg)
  void _handleQuoteTap(QuoteItemData item) async {
    if (_isOneClickTrade) {
      if (_isExecutingOneClick) return;
      _isExecutingOneClick = true;
      try {
        final settings = ref.read(appSettingsProvider);
        final lots = settings.defaultLots > 0 ? settings.defaultLots : 1.0;
        final engine = ref.read(orderSimulationEngineProvider);
        final isCommodity = item.category == 'COMMODITIES';

        final seedInst = SeedInstruments.all.firstWhere(
          (s) =>
              s.symbol.toLowerCase() == item.symbol.toLowerCase() ||
              s.token == item.id,
          orElse: () =>
              SeedInstruments.findByToken(item.id) ?? SeedInstruments.all.first,
        );

        final idempotencyKey =
            'oneclick_${DateTime.now().millisecondsSinceEpoch}_${seedInst.token}';

        final request = OrderRequest(
          idempotencyKey: idempotencyKey,
          instrumentToken: seedInst.token,
          side: TransactionType.BUY,
          product: isCommodity ? ProductType.NRML : ProductType.MIS,
          kind: OrderKind.MARKET,
          quantity: (lots * (seedInst.lotSize > 0 ? seedInst.lotSize : 1))
              .toInt()
              .clamp(1, seedInst.freezeQty > 0 ? seedInst.freezeQty : 100000),
          validity: Validity.DAY,
        );

        final placedOrder = await engine.placeOrder(request);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              placedOrder.status == OrderStatus.REJECTED
                  ? 'One-Click Buy rejected: ${placedOrder.rejectionReason ?? "Insufficient Margin"}'
                  : 'Instant Market Buy executed: ${lots.toStringAsFixed(1)} lot(s) of ${item.symbol} @ ${item.ask > 0 ? item.ask.toStringAsFixed(2) : item.ltp.toStringAsFixed(2)}',
            ),
            backgroundColor: placedOrder.status == OrderStatus.REJECTED
                ? const Color(0xFFD32F2F)
                : const Color(0xFF00A854),
            duration: const Duration(seconds: 4),
            action: placedOrder.status == OrderStatus.COMPLETE
                ? SnackBarAction(
                    label: 'VIEW DEALS',
                    textColor: Colors.white,
                    onPressed: () => context.go('/deals'),
                  )
                : null,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isExecutingOneClick = false;
          });
        }
      }
      return;
    }

    if (_isOpeningSheet) return;
    _isOpeningSheet = true;

    final colors = context.tradingColors;
    final targetInst = SeedInstruments.findByToken(item.id) ??
        SeedInstruments.all.where((i) => i.symbol.toLowerCase() == item.symbol.toLowerCase()).firstOrNull ??
        Instrument(
          token: item.id,
          symbol: item.symbol,
          name: item.symbol,
          exchange: Exchange.MCX,
          type: InstrumentType.FUT,
        );

    try {
      await showModalBottomSheet(
        context: context,
        backgroundColor: colors.cardBackground,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (bottomSheetContext) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 20.0, bottom: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sheet Header: Symbol Title (Bold Black, no divider below)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    item.symbol,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 1. Trade (Pink / Crimson #E82B57)
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
                    title: Text(
                      'Trade',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Icon(LucideIcons.chevronRight,
                        color: colors.textSecondary, size: 18),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      OrderEntrySheet.show(context, instrument: targetInst);
                    },
                  ),
                ),
                Divider(height: 1, thickness: 0.8, color: colors.divider.withValues(alpha: 0.6)),

                // 2. Add to watchlist
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
                    title: Text(
                      'Add to watchlist',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(LucideIcons.chevronRight,
                        color: colors.textSecondary, size: 18),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      ref.read(watchlistControllerProvider.notifier).addInstrumentToActive(targetInst.token);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item.symbol} added to active watchlist'),
                          action: SnackBarAction(
                            label: 'VIEW',
                            textColor: colors.primary,
                            onPressed: () => context.go('/watchlist'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Divider(height: 1, thickness: 0.8, color: colors.divider.withValues(alpha: 0.6)),

                // 3. Add Alert
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
                    title: Text(
                      'Add Alert',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(LucideIcons.chevronRight,
                        color: colors.textSecondary, size: 18),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      context.push('/alerts');
                    },
                  ),
                ),
                Divider(height: 1, thickness: 0.8, color: colors.divider.withValues(alpha: 0.6)),

                // 4. Option Chain
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
                    title: Text(
                      'Option Chain',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(LucideIcons.chevronRight,
                        color: colors.textSecondary, size: 18),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      context.push('/option-chain?symbol=${Uri.encodeComponent(targetInst.symbol)}');
                    },
                  ),
                ),
                Divider(height: 1, thickness: 0.8, color: colors.divider.withValues(alpha: 0.6)),

                // 5. Chart
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
                    title: Text(
                      'Chart',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(LucideIcons.chevronRight,
                        color: colors.textSecondary, size: 18),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      context.push('/chart-fullscreen/${targetInst.token}');
                    },
                  ),
                ),
                Divider(height: 1, thickness: 0.8, color: colors.divider.withValues(alpha: 0.6)),

                // 6. Details
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
                    title: Text(
                      'Details',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(LucideIcons.chevronRight,
                        color: colors.textSecondary, size: 18),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      context.push('/quote/${targetInst.token}');
                    },
                  ),
                ),
                Divider(height: 1, thickness: 0.8, color: colors.divider.withValues(alpha: 0.6)),

                // 6. Hide Extra Data / Show Extra Data
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
                    title: Text(
                      _isProView ? 'Hide Extra Data' : 'Show Extra Data',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(LucideIcons.chevronRight,
                        color: colors.textSecondary, size: 18),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      setState(() => _isProView = !_isProView);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningSheet = false;
        });
      }
    }
  }

  void _openSupportModal(BuildContext context) {
    LiveChatSheet.show(context);
  }

  Widget _buildTopMoversStrip(TradingColors colors) {
    final sortedByGain = List<QuoteItemData>.from(_quotes)
      ..sort((a, b) => b.changePercent.compareTo(a.changePercent));
    final topGainers = sortedByGain.where((q) => q.changePercent > 0).take(3).toList();
    final topLosers = sortedByGain.reversed.where((q) => q.changePercent < 0).take(3).toList();
    final allMovers = [...topGainers, ...topLosers];

    if (allMovers.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: allMovers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = allMovers[index];
          final isBull = item.changePercent >= 0;
          final color = isBull ? colors.bullish : colors.bearish;
          final prefix = isBull ? '+' : '';

          return InkWell(
            onTap: () => _handleQuoteTap(item),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isBull ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                    color: color,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    item.symbol.split(' ').first,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$prefix${item.changePercent.toStringAsFixed(2)}%',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryHeader(
      String category, int count, TradingColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black,
      child: Row(
        children: [
          Icon(LucideIcons.tag, size: 14, color: colors.primary),
          const SizedBox(width: 8),
          Text(
            category,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: colors.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count SCRIPTS',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showManageWatchlistSheet(BuildContext context, TradingColors colors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final wlState = ref.watch(watchlistControllerProvider);
        final watchlists = wlState.watchlists;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Manage Watchlists',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.x, color: colors.textSecondary, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Watchlist List
                ...watchlists.asMap().entries.map((entry) {
                  final index = entry.key;
                  final group = entry.value;
                  final isActive = index == wlState.activeIndex;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive
                            ? colors.primary.withValues(alpha: 0.5)
                            : colors.divider.withValues(alpha: 0.4),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      leading: Icon(
                        isActive ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
                        color: isActive ? colors.primary : colors.textSecondary,
                        size: 20,
                      ),
                      title: Text(
                        group.name,
                        style: GoogleFonts.inter(
                          fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                          color: colors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${group.instrumentTokens.length} scripts',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: colors.textSecondary,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Rename Button
                          IconButton(
                            icon: Icon(LucideIcons.edit2, size: 16, color: colors.textSecondary),
                            tooltip: 'Rename',
                            onPressed: () => _showRenameDialog(context, group.id, group.name, colors),
                          ),
                          // Delete Button (if more than 1 watchlist)
                          if (watchlists.length > 1)
                            IconButton(
                              icon: Icon(LucideIcons.trash2, size: 16, color: colors.bearish),
                              tooltip: 'Delete',
                              onPressed: () => _confirmDeleteWatchlist(context, group.id, group.name, colors),
                            ),
                        ],
                      ),
                      onTap: () {
                        ref.read(watchlistControllerProvider.notifier).setActiveIndex(index);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Switched to ${group.name}'),
                            duration: const Duration(milliseconds: 800),
                          ),
                        );
                      },
                    ),
                  );
                }),

                const SizedBox(height: 12),

                // Create Watchlist Button
                OutlinedButton.icon(
                  onPressed: () => _showCreateWatchlistDialog(context, colors),
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('Create New Watchlist'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    side: BorderSide(color: colors.primary.withValues(alpha: 0.5)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context, String id, String currentName, TradingColors colors) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.cardBackground,
        title: Text('Rename Watchlist', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: colors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Watchlist Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                ref.read(watchlistControllerProvider.notifier).renameWatchlist(id, newName);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Watchlist renamed to "$newName"')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteWatchlist(BuildContext context, String id, String name, TradingColors colors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.cardBackground,
        title: Text('Delete "$name"?', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: colors.textPrimary)),
        content: Text('All scripts in this watchlist will be removed.', style: TextStyle(color: colors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colors.bearish, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(watchlistControllerProvider.notifier).deleteWatchlist(id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Watchlist "$name" deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreateWatchlistDialog(BuildContext context, TradingColors colors) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.cardBackground,
        title: Text('New Watchlist', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: colors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Watchlist Name (e.g. Breakouts)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(watchlistControllerProvider.notifier).createWatchlist(name);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Created watchlist "$name"')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _QuotesTableHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TradingColors colors;

  const _QuotesTableHeaderDelegate({required this.colors});

  @override
  double get minExtent => 32.0;

  @override
  double get maxExtent => 32.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF212121) : colors.dockBackground,
        border: isDark
            ? null
            : Border(
                bottom: BorderSide(
                  color: colors.divider,
                  width: 0.5,
                ),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text('Script',
                style: AppTypography.labelSmall(
                    color: colors.textPrimary, weight: FontWeight.w600)),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('Bid',
                  style: AppTypography.labelSmall(
                      color: colors.textPrimary, weight: FontWeight.w600)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('Ask',
                  style: AppTypography.labelSmall(
                      color: colors.textPrimary, weight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _QuotesTableHeaderDelegate oldDelegate) =>
      oldDelegate.colors != colors;
}
