import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/services/realtime_quote_service.dart';
import '../../../core/services/web_redirect_service.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/models.dart';
import '../../market/data/real_market_repository.dart';
import '../../orders/data/real_trading_repository.dart';
import '../../profile_settings/data/settings_repository.dart';
import '../../../shared_widgets/mt_price_text.dart';
import '../../../shared_widgets/news_ticker_strip.dart';
import '../../../shared_widgets/script_selector_bar.dart';
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
  StreamSubscription? _quoteSub;
  bool _isLoading = true;
  List<QuoteItemData> _quotes = [];

  @override
  void initState() {
    super.initState();
    _loadRealQuotes();
  }

  Future<void> _loadRealQuotes() async {
    try {
      final repo = ref.read(marketRepositoryProvider);
      final instruments = await repo.getInstruments();
      final quoteService = ref.read(realtimeQuoteServiceProvider);

      if (!mounted) return;
      setState(() {
        _quotes = instruments.map((inst) {
          quoteService.subscribe(inst.symbol);
          final q = quoteService.getQuote(inst.symbol);
          return QuoteItemData(
            id: inst.token,
            symbol: inst.symbol,
            category: inst.category.isNotEmpty ? inst.category : inst.exchange.name,
            change: q.netChange,
            changePercent: q.percentChange,
            bid: q.bestBid,
            ask: q.bestAsk,
            spread: ((q.bestAsk - q.bestBid) * 100).toInt(),
            low: q.dayLow,
            high: q.dayHigh,
            open: q.openPrice,
            close: q.prevClose,
            ltp: q.lastPrice > 0 ? q.lastPrice : (q.bestBid > 0 ? q.bestBid : 100.0),
            timestamp: q.lastTradeTime,
          );
        }).toList();
        _isLoading = false;
      });

      _quoteSub = quoteService.stream.listen((incoming) {
        if (!mounted) return;
        bool changed = false;
        for (final q in _quotes) {
          final updated = incoming[q.symbol] ?? incoming[q.id];
          if (updated != null && updated.lastPrice > 0) {
            final prevPrice = q.ltp;
            q.bid = updated.bestBid;
            q.ask = updated.bestAsk;
            q.ltp = updated.lastPrice;
            q.change = updated.netChange;
            q.changePercent = updated.percentChange;
            q.low = updated.dayLow;
            q.high = updated.dayHigh;
            q.open = updated.openPrice;
            q.close = updated.prevClose;
            q.spread = ((updated.bestAsk - updated.bestBid) * 100).toInt();
            q.timestamp = updated.lastTradeTime;
            if (updated.lastPrice > prevPrice) {
              q.bidColorMode = PriceColorMode.blue;
              q.askColorMode = PriceColorMode.blue;
            } else if (updated.lastPrice < prevPrice) {
              q.bidColorMode = PriceColorMode.red;
              q.askColorMode = PriceColorMode.red;
            }
            changed = true;
          }
        }
        if (changed) {
          setState(() {});
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _quoteSub?.cancel();
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
                  icon: Icon(LucideIcons.star,
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
                IconButton(
                  icon: Icon(LucideIcons.headphones,
                      color: colors.textPrimary, size: 20),
                  onPressed: () => _openSupportModal(context),
                  tooltip: 'Live Support',
                ),
                const SizedBox(width: 4),
              ],
      ),
      body: Container(
        color: isDark ? Colors.black : colors.background,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            // Collapsible Header Section: Ticker, Sticky Bar, Quick Actions, Search
            SliverToBoxAdapter(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dual-line Public & Private News Ticker Strip (Scrolls with content)
                  NewsTickerStrip(
                    onPublicNewsTap: () => context.push('/news'),
                    onPrivateNewsTap: () => context.push('/mails'),
                  ),

                  // Dual Script Selector Bar (Sticky Scripts Toggle)
                  if (settings.showStickyScripts)
                    const ScriptSelectorBar(),

                  // Sleek Quick Action Chips: DEPOSIT & WITHDRAWAL
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 6.0),
                    child: Row(
                      children: [
                        // DEPOSIT Quick Action Chip
                        Expanded(
                          child: InkWell(
                            onTap: () =>
                                WebRedirectService.openDepositWebsite(context: context),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(LucideIcons.arrowDownToLine,
                                      size: 14, color: Color(0xFF2563EB)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Deposit',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // WITHDRAWAL Quick Action Chip
                        Expanded(
                          child: InkWell(
                            onTap: () =>
                                WebRedirectService.openWithdrawWebsite(context: context),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height: 34,
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: colors.primary.withValues(alpha: 0.35),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.arrowUpFromLine,
                                      size: 14, color: colors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Withdraw',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: colors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Compact Pro View, Live Badge & One Click Trade Toolbar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 4.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Pro View Toggle Chip
                          InkWell(
                            onTap: () => setState(() => _isProView = !_isProView),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _isProView
                                    ? colors.primary.withValues(alpha: 0.12)
                                    : colors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _isProView ? colors.primary : colors.divider,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isProView
                                        ? LucideIcons.layoutGrid
                                        : LucideIcons.alignJustify,
                                    size: 13,
                                    color: _isProView
                                        ? colors.primary
                                        : colors.textSecondary,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _isProView ? 'Pro View' : 'Simple View',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: _isProView
                                          ? colors.primary
                                          : colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Live status pulse indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF00A854),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
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
                          ),

                          const SizedBox(width: 8),

                          // One Click Trade Chip
                          InkWell(
                            onTap: () => setState(
                                () => _isOneClickTrade = !_isOneClickTrade),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _isOneClickTrade
                                    ? const Color(0xFFF5A623).withValues(alpha: 0.15)
                                    : colors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _isOneClickTrade
                                      ? const Color(0xFFF5A623)
                                      : colors.divider,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.zap,
                                    size: 13,
                                    color: _isOneClickTrade
                                        ? const Color(0xFFF5A623)
                                        : colors.textSecondary,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _isOneClickTrade
                                        ? (settings.defaultLots > 0
                                            ? '1-Click (${settings.defaultLots.toStringAsFixed(1)}L)'
                                            : '1-Click ON')
                                        : '1-Click OFF',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: _isOneClickTrade
                                          ? const Color(0xFFF5A623)
                                          : colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 5.0),
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(
                            color: colors.divider.withValues(alpha: 0.6)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        textAlignVertical: TextAlignVertical.center,
                        style: AppTypography.body(color: colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search by Script Name',
                          hintStyle: AppTypography.body(color: colors.textSecondary),
                          prefixIcon: Icon(LucideIcons.search,
                              color: colors.textSecondary.withValues(alpha: 0.7),
                              size: 17),
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onChanged: (val) => setState(() => _query = val),
                      ),
                    ),
                  ),
                ],
              ),
            ),

                    // Pinned Table Header Strip (Script | Bid | Ask)
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _QuotesTableHeaderDelegate(colors: colors),
                    ),

                    // Quotes List
                    if (_isLoading)
                      SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator(color: colors.primary),
                        ),
                      )
                    else if (_isEditMode)
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
        final repo = ref.read(marketRepositoryProvider);
        final instrument = repo.findBySymbol(item.symbol) ??
            repo.findBySymbol(item.id);

        if (instrument == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Instrument ${item.symbol} not found on server.'),
              backgroundColor: const Color(0xFFD32F2F),
            ),
          );
          return;
        }

        final idempotencyKey =
            'oneclick_${DateTime.now().millisecondsSinceEpoch}_${instrument.symbol}';

        final lotMultiplier = instrument.lotSize > 0 ? instrument.lotSize : 1;
        final rawQty = (lots * lotMultiplier).toInt();
        final maxQty = instrument.freezeQty > 0 ? instrument.freezeQty : 100000;

        final tradingRepo = ref.read(tradingRepositoryProvider);
        final placedOrder = await tradingRepo.createOrder(
          symbol: instrument.symbol,
          side: TransactionType.BUY,
          orderType: OrderKind.MARKET,
          quantity: rawQty.clamp(1, maxQty),
          leverage: 5.0,
          market: 'INDIAN',
          idempotencyKey: idempotencyKey,
        );

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
      } catch (err) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order failed: $err'),
            backgroundColor: const Color(0xFFD32F2F),
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
    final repo = ref.read(marketRepositoryProvider);
    final targetInst = repo.findBySymbol(item.symbol) ??
        repo.findBySymbol(item.id);

    if (targetInst == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Instrument ${item.symbol} not found.'),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
      _isOpeningSheet = false;
      return;
    }

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
