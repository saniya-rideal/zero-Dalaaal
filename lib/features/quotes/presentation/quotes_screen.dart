import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/services/market_status_service.dart';
import '../../../core/services/realtime_quote_service.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/models.dart';
import '../../market/data/real_market_repository.dart';
import '../../orders/data/real_trading_repository.dart';
import '../../profile_settings/data/settings_repository.dart';
import '../../../shared_widgets/market_closed_banner.dart';
import '../../../shared_widgets/mt_price_text.dart';
import '../../../shared_widgets/news_ticker_strip.dart';
import '../../../shared_widgets/quote_status_badge.dart';
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
  QuoteStatus status;
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
    this.status = QuoteStatus.live,
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
  final ScrollController _scrollController = ScrollController();
  bool _isProView = true;
  bool _isOneClickTrade = false;
  bool _isEditMode = false;
  bool _isExecutingOneClick = false;
  bool _isOpeningSheet = false;
  final Set<String> _selectedForDelete = {};
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
            ltp: q.lastPrice > 0 ? q.lastPrice : (q.bestBid > 0 ? q.bestBid : 0.0),
            timestamp: q.lastTradeTime,
            status: q.status,
          );
        }).toList();
        _isLoading = false;
      });

      _quoteSub = quoteService.stream.listen((incoming) {
        if (!mounted) return;
        bool changed = false;
        for (final q in _quotes) {
          final updated = incoming[q.symbol] ?? incoming[q.id];
          if (updated != null) {
            final prevPrice = q.ltp;
            q.bid = updated.bestBid;
            q.ask = updated.bestAsk;
            q.ltp = updated.lastPrice > 0 ? updated.lastPrice : 0.0;
            q.change = updated.netChange;
            q.changePercent = updated.percentChange;
            q.low = updated.dayLow;
            q.high = updated.dayHigh;
            q.open = updated.openPrice;
            q.close = updated.prevClose;
            q.spread = ((updated.bestAsk - updated.bestBid) * 100).toInt();
            q.timestamp = updated.lastTradeTime;
            q.status = updated.status;
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
    _scrollController.dispose();
    _quoteSub?.cancel();
    super.dispose();
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedForDelete.length == _quotes.length) {
        _selectedForDelete.clear();
      } else {
        _selectedForDelete.addAll(_quotes.map((q) => q.symbol));
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedForDelete.isEmpty) return;
    final toDelete = List<String>.from(_selectedForDelete);
    final notifier = ref.read(watchlistControllerProvider.notifier);
    final success = await notifier.removeMultiple(toDelete);

    if (!mounted) return;
    if (success) {
      setState(() {
        _quotes.removeWhere((q) => toDelete.contains(q.id) || toDelete.contains(q.symbol));
        _selectedForDelete.clear();
        _isEditMode = false;
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed ${toDelete.length} script(s) from Watchlist'),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: Colors.white,
            onPressed: () {
              for (final sym in toDelete.reversed) {
                ref.read(watchlistControllerProvider.notifier).addInstrument(sym);
              }
            },
          ),
        ),
      );
    } else {
      final err = ref.read(watchlistControllerProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Failed to remove selected scripts'),
          backgroundColor: const Color(0xFFC62828),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final settings = ref.watch(appSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wlState = ref.watch(watchlistControllerProvider);
    final activeWl = wlState.watchlist;
    final activeTokens = activeWl?.instrumentTokens ?? [];

    // Listen to additions for smooth scroll to top and handle errors
    ref.listen<WatchlistState>(watchlistControllerProvider, (prev, next) {
      if (next.lastAddedSymbol != null && next.lastAddedSymbol != prev?.lastAddedSymbol) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        final msg = next.errorMessage == 'MAX_SYMBOLS_EXCEEDED'
            ? 'Watchlist limit reached: Maximum 50 symbols allowed.'
            : next.errorMessage!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
    });

    // Ensure any tokens in the watchlist are populated in _quotes
    if (activeTokens.isNotEmpty) {
      final repo = ref.read(marketRepositoryProvider);
      final quoteService = ref.read(realtimeQuoteServiceProvider);
      for (final token in activeTokens) {
        final tokenUpper = token.toUpperCase();
        if (!_quotes.any((q) => q.id.toUpperCase() == tokenUpper || q.symbol.toUpperCase() == tokenUpper)) {
          final inst = repo.findBySymbol(token) ??
              Instrument(
                token: token,
                symbol: tokenUpper,
                name: tokenUpper.replaceAll('_', ' '),
                exchange: Exchange.NSE,
                type: InstrumentType.EQ,
              );
          quoteService.subscribe(inst.symbol);
          quoteService.subscribe(inst.token);
          final q = quoteService.getQuote(inst.symbol);
          _quotes.add(QuoteItemData(
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
            ltp: q.lastPrice > 0 ? q.lastPrice : (q.bestBid > 0 ? q.bestBid : 0.0),
            timestamp: q.lastTradeTime,
            status: q.status,
          ));
        }
      }
    }

    // STRICT: Never fall back to all instruments! Preserve exact backend order (newest at index 0)
    final List<QuoteItemData> baseQuotes = [];
    if (activeTokens.isNotEmpty) {
      for (final token in activeTokens) {
        final tUpper = token.toUpperCase();
        final match = _quotes.cast<QuoteItemData?>().firstWhere(
              (q) => q != null && (q.id.toUpperCase() == tUpper || q.symbol.toUpperCase() == tUpper),
              orElse: () => null,
            );
        if (match != null) {
          baseQuotes.add(match);
        }
      }
    }

    final filteredQuotes = baseQuotes;

    final Map<String, List<QuoteItemData>> groupedQuotes = {};
    if (settings.quotesGrouping) {
      for (final quote in filteredQuotes) {
        groupedQuotes.putIfAbsent(quote.category, () => []).add(quote);
      }
    }

    final nseStatus = MarketStatusService.getStatusForExchange('NSE');
    final isMarketClosed = nseStatus.state == MarketSessionState.closed;

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
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Watchlist',
              style: AppTypography.h1(
                  color: colors.textPrimary, weight: FontWeight.w700),
            ),
            Text(
              '${activeTokens.length} / 50 symbols',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
        actions: _isEditMode
            ? [
                IconButton(
                  icon: Icon(
                    _selectedForDelete.length == filteredQuotes.length &&
                            filteredQuotes.isNotEmpty
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
                    LucideIcons.trash2,
                    color: colors.bearish,
                    size: 22,
                  ),
                  onPressed: _deleteSelected,
                  tooltip: 'Delete Selected',
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
                  icon: Icon(LucideIcons.plus, color: colors.textPrimary, size: 22),
                  onPressed: () => context.push('/add-script'),
                  tooltip: 'Add Script',
                ),
                IconButton(
                  icon: Icon(LucideIcons.edit3,
                      color: colors.textPrimary, size: 22),
                  onPressed: () => setState(() => _isEditMode = true),
                  tooltip: 'Edit Watchlist',
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
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            // Collapsible Header Section: Ticker, Sticky Bar, Quick Actions, Search
            SliverToBoxAdapter(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dual-line Public & Private News Ticker Strip
                  NewsTickerStrip(
                    onPublicNewsTap: () => context.push('/news'),
                    onPrivateNewsTap: () => context.push('/mails'),
                  ),

                  // Dual Script Selector Bar (Sticky Scripts Toggle)
                  if (settings.showStickyScripts)
                    const ScriptSelectorBar(),

                  // Quick Action Chips: DEPOSIT & WITHDRAWAL
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 6.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => AddFundsSheet.show(context),
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
                        Expanded(
                          child: InkWell(
                            onTap: () => WithdrawFundsSheet.show(context),
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

                  const SizedBox(height: 6),
                ],
              ),
            ),

            // Market Closed Banner when market is not open
            if (isMarketClosed)
              const SliverToBoxAdapter(
                child: MarketClosedBanner(),
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
                onReorder: (oldIndex, newIndex) async {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _quotes.removeAt(oldIndex);
                    _quotes.insert(newIndex, item);
                  });
                  await ref.read(watchlistControllerProvider.notifier).reorder(oldIndex, newIndex);
                },
                itemBuilder: (context, index) {
                  final item = filteredQuotes[index];
                  return ReorderableDelayedDragStartListener(
                    key: ValueKey(item.symbol),
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
            else if (settings.quotesGrouping && groupedQuotes.isNotEmpty)
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
                    return _buildDismissibleRow(item, colors);
                  },
                ),
              ])
            else if (filteredQuotes.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.bookmark,
                          size: 44,
                          color: colors.primary.withValues(alpha: 0.8),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Your watchlist is empty',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add equities, commodities, forex, or crypto scripts to track live prices.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(LucideIcons.plus, size: 18),
                          label: const Text('Add script'),
                          onPressed: () => context.push('/add-script'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
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
                  return _buildDismissibleRow(item, colors);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDismissibleRow(QuoteItemData item, TradingColors colors) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dismissible(
      key: ValueKey('dismiss_${item.symbol}_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: const Color(0xFFC62828),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.trash2, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Remove',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        final notifier = ref.read(watchlistControllerProvider.notifier);
        final success = await notifier.removeInstrument(item.symbol);
        if (!success) {
          if (mounted) {
            final err = ref.read(watchlistControllerProvider).errorMessage;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(err ?? 'Failed to remove ${item.symbol}'),
                backgroundColor: const Color(0xFFC62828),
              ),
            );
          }
          return false;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed ${item.symbol} from Watchlist'),
              action: SnackBarAction(
                label: 'UNDO',
                textColor: Colors.white,
                onPressed: () {
                  notifier.addInstrument(item.symbol);
                },
              ),
            ),
          );
        }
        return true;
      },
      child: Container(
        color: isDark ? Colors.black : colors.background,
        child: _buildQuoteRow(item, colors),
      ),
    );
  }

  Widget _buildQuoteRow(QuoteItemData item, TradingColors colors,
      {int? index}) {
    final isChecked = _selectedForDelete.contains(item.symbol);
    final isDimmed = item.status == QuoteStatus.stale || item.status == QuoteStatus.closed;

    // Single-line clean view when Pro View is closed (Classic View)
    if (!_isProView) {
      return InkWell(
        onTap: () {
          if (_isEditMode) {
            setState(() {
              if (isChecked) {
                _selectedForDelete.remove(item.symbol);
              } else {
                _selectedForDelete.add(item.symbol);
              }
            });
          } else {
            _handleQuoteTap(item);
          }
        },
        onLongPress: _isEditMode ? null : () => _showQuoteActionSheet(context, item, colors),
        child: Container(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Row(
            children: [
              if (_isEditMode) ...[
                Checkbox(
                  value: isChecked,
                  activeColor: colors.primary,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedForDelete.add(item.symbol);
                      } else {
                        _selectedForDelete.remove(item.symbol);
                      }
                    });
                  },
                ),
              ],

              // Script Symbol with Quote Status Badge
              Expanded(
                flex: 4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
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
                    const SizedBox(width: 5),
                    QuoteStatusBadge(status: item.status),
                  ],
                ),
              ),

              // Bid price
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Opacity(
                    opacity: isDimmed ? 0.5 : 1.0,
                    child: MtPriceText(
                      price: item.bid,
                      colorMode: item.bidColorMode,
                    ),
                  ),
                ),
              ),

              // Ask price
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Opacity(
                    opacity: isDimmed ? 0.5 : 1.0,
                    child: MtPriceText(
                      price: item.ask,
                      colorMode: item.askColorMode,
                    ),
                  ),
                ),
              ),

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
              _selectedForDelete.remove(item.symbol);
            } else {
              _selectedForDelete.add(item.symbol);
            }
          });
        } else {
          _handleQuoteTap(item);
        }
      },
      onLongPress: _isEditMode ? null : () => _showQuoteActionSheet(context, item, colors),
      child: Container(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            if (_isEditMode) ...[
              Checkbox(
                value: isChecked,
                activeColor: colors.primary,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedForDelete.add(item.symbol);
                    } else {
                      _selectedForDelete.remove(item.symbol);
                    }
                  });
                },
              ),
            ],

            // Main Quote Content - Clean 2-Line Layout
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Line 1: Symbol + Status Badge (Left) + Bid (Center-Right) + Ask (Far-Right)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 4,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
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
                            const SizedBox(width: 5),
                            QuoteStatusBadge(status: item.status),
                          ],
                        ),
                      ),

                      // Bid
                      Expanded(
                        flex: 3,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Opacity(
                            opacity: isDimmed ? 0.5 : 1.0,
                            child: MtPriceText(
                              price: item.bid,
                              colorMode: item.bidColorMode,
                            ),
                          ),
                        ),
                      ),

                      // Ask
                      Expanded(
                        flex: 3,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Opacity(
                            opacity: isDimmed ? 0.5 : 1.0,
                            child: MtPriceText(
                              price: item.ask,
                              colorMode: item.askColorMode,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 3),

                  // Line 2: Change & % Change (Left) + LTP (Right)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 4,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.change >= 0
                                    ? LucideIcons.trendingUp
                                    : LucideIcons.trendingDown,
                                size: 13,
                                color: item.change >= 0
                                    ? const Color(0xFF00A854)
                                    : const Color(0xFFEA3943),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${CurrencyFormatter.formatSigned(item.change, showSymbol: false)} (${CurrencyFormatter.formatPercent(item.changePercent)})',
                                style: AppTypography.labelSmall(
                                  color: item.change >= 0
                                      ? const Color(0xFF00A854)
                                      : const Color(0xFFEA3943),
                                  weight: FontWeight.w600,
                                  tabular: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // LTP
                      Expanded(
                        flex: 6,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Opacity(
                            opacity: isDimmed ? 0.5 : 1.0,
                            child: Text(
                              'LTP: ${item.ltp > 0 ? CurrencyFormatter.format(item.ltp, showSymbol: false) : "—"}',
                              style: AppTypography.labelSmall(
                                color: colors.textSecondary,
                                weight: FontWeight.w500,
                                tabular: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

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

  void _handleQuoteTap(QuoteItemData item) async {
    if (_isOneClickTrade) {
      if (_isExecutingOneClick) return;
      _isExecutingOneClick = true;
      try {
        if (item.status == QuoteStatus.stale || item.status == QuoteStatus.closed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Market orders disabled: Market is CLOSED or quote data is STALE. Use a Limit/Pending order.'),
              backgroundColor: Color(0xFFC62828),
            ),
          );
          return;
        }

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
                  : 'Instant Market Buy executed: ${lots.toStringAsFixed(1)} lot(s) of ${item.symbol} @ ${item.ask > 0 ? item.ask.toStringAsFixed(2) : (item.ltp > 0 ? item.ltp.toStringAsFixed(2) : "—")}',
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

    _showQuoteActionSheet(context, item, context.tradingColors);
  }

  void _showQuoteActionSheet(BuildContext context, QuoteItemData item, TradingColors colors) async {
    if (_isOpeningSheet) return;
    _isOpeningSheet = true;

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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      Text(
                        item.symbol,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      QuoteStatusBadge(status: item.status),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 1. Trade
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

                // 2. Remove from Watchlist (with undo support)
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
                    title: Text(
                      'Remove from Watchlist',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: colors.bearish,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Icon(LucideIcons.trash2,
                        color: colors.bearish, size: 18),
                    onTap: () async {
                      Navigator.pop(bottomSheetContext);
                      final notifier = ref.read(watchlistControllerProvider.notifier);
                      final success = await notifier.removeInstrument(targetInst.symbol);
                      if (context.mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Removed ${targetInst.symbol} from Watchlist'),
                              action: SnackBarAction(
                                label: 'UNDO',
                                textColor: Colors.white,
                                onPressed: () {
                                  notifier.addInstrument(targetInst.symbol);
                                },
                              ),
                            ),
                          );
                        } else {
                          final err = ref.read(watchlistControllerProvider).errorMessage;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(err ?? 'Failed to remove ${targetInst.symbol}'),
                              backgroundColor: const Color(0xFFC62828),
                            ),
                          );
                        }
                      }
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

                // 4. Chart
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

                // 5. Details
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
