import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/services/market_status_service.dart';
import '../../../core/services/realtime_quote_service.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/exchange_chip.dart';
import '../../market/data/real_market_repository.dart';
import '../../order_entry/presentation/order_entry_sheet.dart';
import '../../watchlist/presentation/watchlist_controller.dart';
import '../data/fundamentals_repository.dart';
import 'widgets/financials_tab.dart';
import 'widgets/fundamentals_tab.dart';
import 'widgets/shareholding_tab.dart';

class QuoteDetailScreen extends ConsumerStatefulWidget {
  final String token;

  const QuoteDetailScreen({super.key, required this.token});

  @override
  ConsumerState<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends ConsumerState<QuoteDetailScreen> {
  int _selectedTabIndex = 0; // 0: Overview, 1: Fundamentals, 2: Financials, 3: Shareholding

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final tickerService = ref.watch(tickerServiceProvider);

    final repo = ref.watch(marketRepositoryProvider);

    final instrument = repo.findBySymbol(widget.token) ??
        Instrument(
          token: widget.token,
          symbol: widget.token.toUpperCase().replaceAll('_', ' '),
          name: widget.token.toUpperCase().replaceAll('_', ' '),
          exchange: widget.token.toLowerCase().contains('mcx')
              ? Exchange.MCX
              : Exchange.NSE,
          type: widget.token.toLowerCase().contains('sep') ||
                  widget.token.toLowerCase().contains('oct') ||
                  widget.token.toLowerCase().contains('mcx')
              ? InstrumentType.FUT
              : InstrumentType.EQ,
        );

    final quote = tickerService.getQuote(instrument.token);
    final isBull = quote.changePercent >= 0;
    final priceColor = isBull ? colors.bullish : colors.bearish;
    final changePrefix = isBull ? '+' : '';

    final marketStatus =
        MarketStatusService.getStatusForExchange(instrument.exchange.name);

    final isCommodity = instrument.exchange == Exchange.MCX ||
        instrument.symbol.toUpperCase().contains('MCX') ||
        instrument.symbol.toUpperCase().contains('COPPER');

    final isCrypto = widget.token.contains('crypto') ||
        instrument.symbol.toUpperCase().contains('BTC') ||
        instrument.symbol.toUpperCase().contains('ETH');

    final isForex = instrument.exchange == Exchange.CDS ||
        widget.token.contains('fx_') ||
        instrument.symbol.toUpperCase().contains('USDINR');

    final isEquity = (instrument.type == InstrumentType.EQ) &&
        !isCommodity &&
        !isCrypto &&
        !isForex;

    final contractSizeStr = isCommodity
        ? (instrument.lotSize > 0
            ? NumberFormat('#,##0.00').format(instrument.lotSize)
            : '2,500.00')
        : (instrument.lotSize > 0
            ? NumberFormat('#,##0.00').format(instrument.lotSize)
            : '1.00');

    final tickSizeStr = isCommodity
        ? (instrument.tickSize > 0
            ? instrument.tickSize.toStringAsFixed(0)
            : '2')
        : (instrument.tickSize > 0
            ? instrument.tickSize.toStringAsFixed(isForex ? 4 : 2)
            : '0.05');

    final tickValueStr = isCommodity ? '25.00' : (isForex ? '2.50' : '1.00');

    final leverageStr = isCrypto || isCommodity
        ? '500x (0.20% Margin)'
        : (isForex ? '100x (1.00% Margin)' : '5x MIS (20% Margin) / 1x CNC');

    final bidColor = colors.secondary;
    final askColor = colors.bearish;

    final watchlistState = ref.watch(watchlistControllerProvider);
    final isInWatchlist = watchlistState.activeWatchlist?.instrumentTokens
            .contains(instrument.token) ??
        false;

    // Dual Bid / Ask calculation
    final bidPrice = quote.depth.buy.isNotEmpty
        ? quote.depth.buy.first.price
        : quote.ltp - 0.05;
    final bidQty =
        quote.depth.buy.isNotEmpty ? quote.depth.buy.first.qty : 150;
    final askPrice = quote.depth.sell.isNotEmpty
        ? quote.depth.sell.first.price
        : quote.ltp + 0.05;
    final askQty =
        quote.depth.sell.isNotEmpty ? quote.depth.sell.first.qty : 150;
    final spreadPts = (askPrice - bidPrice).abs();

    final fundamentals = isEquity
        ? ref.watch(stockFundamentalsProvider(instrument.symbol)).valueOrNull
        : null;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon:
              Icon(LucideIcons.arrowLeft, color: colors.textPrimary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          instrument.symbol,
          style: GoogleFonts.inter(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          // Favorite / Watchlist Star Toggle
          IconButton(
            icon: Icon(
              isInWatchlist ? LucideIcons.star : LucideIcons.star,
              color:
                  isInWatchlist ? const Color(0xFFFFB800) : colors.textPrimary,
              size: 22,
            ),
            tooltip:
                isInWatchlist ? 'Remove from Watchlist' : 'Add to Watchlist',
            onPressed: () {
              if (isInWatchlist) {
                ref
                    .read(watchlistControllerProvider.notifier)
                    .removeInstrument(instrument.token);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Removed ${instrument.symbol} from ${watchlistState.activeWatchlist?.name ?? "Watchlist"}'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              } else {
                ref
                    .read(watchlistControllerProvider.notifier)
                    .addInstrumentToActive(instrument.token);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Added ${instrument.symbol} to ${watchlistState.activeWatchlist?.name ?? "Watchlist"}'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
          // Share / Copy Symbol Button
          IconButton(
            icon: Icon(LucideIcons.share2, color: colors.textPrimary, size: 20),
            tooltip: 'Share / Copy Symbol',
            onPressed: () {
              final shareText =
                  '${instrument.symbol} (${instrument.exchange.name}) • LTP: ${isCrypto ? "\$${quote.ltp}" : "₹${quote.ltp}"} ($changePrefix${quote.changePercent.toStringAsFixed(2)}%)';
              Clipboard.setData(ClipboardData(text: shareText));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied "$shareText" to clipboard'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= HERO LIVE QUOTE CARD =================
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: colors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: colors.divider.withValues(alpha: 0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Instrument Name & Market Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                instrument.name,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  ExchangeChip(
                                      exchange: instrument.exchange,
                                      type: instrument.type),
                                  Text(
                                    'Lot: $contractSizeStr',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Real-Time Market Status Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: marketStatus.badgeColor
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: marketStatus.badgeColor
                                    .withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: marketStatus.badgeColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                marketStatus.label,
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: marketStatus.badgeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Price Hero Row
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            isCrypto
                                ? '\$${NumberFormat('#,##0.00').format(quote.ltp)}'
                                : CurrencyFormatter.format(quote.ltp),
                            style: GoogleFonts.inter(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: colors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: priceColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$changePrefix${quote.change.toStringAsFixed(2)} ($changePrefix${quote.changePercent.toStringAsFixed(2)}%)',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: priceColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Dual Bid / Ask Boxes
                    Row(
                      children: [
                        // BID Box (Blue)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: bidColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: bidColor.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BID',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: bidColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isCrypto
                                      ? '\$${NumberFormat('#,##0.00').format(bidPrice)}'
                                      : CurrencyFormatter.format(bidPrice,
                                          showSymbol: false),
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: bidColor,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                                Text(
                                  'Qty: $bidQty',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Center Spread Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'SPREAD',
                                style: GoogleFonts.inter(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textSecondary),
                              ),
                              Text(
                                spreadPts.toStringAsFixed(2),
                                style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: colors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // ASK Box (Red)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: askColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: askColor.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'ASK',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: askColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isCrypto
                                      ? '\$${NumberFormat('#,##0.00').format(askPrice)}'
                                      : CurrencyFormatter.format(askPrice,
                                          showSymbol: false),
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: askColor,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                                Text(
                                  'Qty: $askQty',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Mini OHLC Summary Bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildOhlcItem('Open', quote.open, colors),
                            _buildOhlcItem('High', quote.high, colors),
                            _buildOhlcItem('Low', quote.low, colors),
                            _buildOhlcItem(
                                'Prev Close', quote.prevClose, colors),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Quick Action Buttons (BUY / SELL / CHART)
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: ElevatedButton(
                            onPressed: () => OrderEntrySheet.show(
                              context,
                              instrument: instrument,
                              side: TransactionType.BUY,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: bidColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('BUY',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: ElevatedButton(
                            onPressed: () => OrderEntrySheet.show(
                              context,
                              instrument: instrument,
                              side: TransactionType.SELL,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: askColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('SELL',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            onPressed: () => context
                                .push('/chart-fullscreen/${instrument.token}'),
                            icon: const Icon(LucideIcons.lineChart, size: 16),
                            label: const Text('Chart',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11.5)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // ================= TABS SELECTOR (Overview, Fundamentals, Financials, Shareholding) =================
              if (isEquity) ...[
                _buildTabSelector(colors),
                const SizedBox(height: 10),
              ],

              // ================= TAB CONTENT =================
              if (!isEquity || _selectedTabIndex == 0) ...[
                // Overview & Specifications Tab
                _buildOverviewTab(
                    contractSizeStr,
                    tickSizeStr,
                    tickValueStr,
                    leverageStr,
                    isCommodity,
                    isCrypto,
                    colors),
              ] else if (_selectedTabIndex == 1 && fundamentals != null) ...[
                FundamentalsTab(fundamentals: fundamentals),
              ] else if (_selectedTabIndex == 2 && fundamentals != null) ...[
                FinancialsTab(fundamentals: fundamentals),
              ] else if (_selectedTabIndex == 3 && fundamentals != null) ...[
                ShareholdingTab(fundamentals: fundamentals),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabSelector(TradingColors colors) {
    final tabs = [
      {'title': 'Overview', 'icon': LucideIcons.fileText},
      {'title': 'Fundamentals', 'icon': LucideIcons.barChart3},
      {'title': 'Financials', 'icon': LucideIcons.landmark},
      {'title': 'Shareholding', 'icon': LucideIcons.pieChart},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          final item = tabs[index];

          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTabIndex = index),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? colors.secondary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 14,
                      color: isSelected ? Colors.white : colors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        item['title'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color:
                              isSelected ? Colors.white : colors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildOverviewTab(
    String contractSizeStr,
    String tickSizeStr,
    String tickValueStr,
    String leverageStr,
    bool isCommodity,
    bool isCrypto,
    TradingColors colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ================= SECTION 1: PROPERTIES =================
        _buildSectionHeader('Contract Specifications', colors),
        const SizedBox(height: 4),

        _buildPropertyRow('Spread', 'Live / Floating', colors),
        _buildPropertyRow('Contract Size', contractSizeStr, colors),
        _buildPropertyRow('Open Commission', '₹0.00 (Zero Brokerage)', colors),
        _buildPropertyRow('Close Commission', '₹0.00 (Zero Brokerage)', colors),
        _buildPropertyRow(
            'Intra Day Commission', '₹0.00 (Zero Brokerage)', colors),
        _buildPropertyRow('Tick Size', tickSizeStr, colors),
        _buildPropertyRow('Tick Value', '₹$tickValueStr', colors),
        _buildPropertyRow('Minimum Quantity', '0.10', colors),
        _buildPropertyRow(
            'Maximum Quantity', '20.00 Lots (1,800 Qty)', colors),
        _buildPropertyRow('Limit Offset', '0.00', colors),
        _buildPropertyRow('Stop Offset', '0.00', colors),
        _buildPropertyRow('Reference Script', 'Base', colors),
        _buildPropertyRow(
            'EOD Auto Cancel Entry Orders', 'Yes (15:30 IST)', colors),
        _buildPropertyRow('EOD Auto Cancel SLTP Orders', 'Yes', colors),
        _buildPropertyRow(
            'Close/Cancel All Deals On Expiry', 'Yes (Auto-Squareoff)', colors),
        _buildPropertyRow('Can Buy', 'YES', colors),
        _buildPropertyRow('Can Sell', 'YES', colors),

        const SizedBox(height: 18),

        // ================= SECTION 2: TRADE SESSION =================
        _buildSectionHeader('Trade Session & Timings', colors),
        const SizedBox(height: 4),

        _buildPropertyRow(
            'Weekly Open Day Time',
            isCommodity ? 'Monday 09:00 IST' : 'Monday 09:15 IST',
            colors),
        _buildPropertyRow(
            'Weekly Close Day Time',
            isCommodity ? 'Friday 23:30 IST' : 'Friday 15:30 IST',
            colors),
        _buildPropertyRow(
            'Daily Pre-Open Session',
            isCommodity ? '08:45 - 09:00 IST' : '09:00 - 09:15 IST',
            colors),
        _buildPropertyRow(
            'Daily Regular Session',
            isCommodity ? '09:00 - 23:30 IST' : '09:15 - 15:30 IST',
            colors),
        _buildPropertyRow('Expiry Date', '2026-10-01 15:30:00 IST', colors),

        const SizedBox(height: 18),

        // ================= SECTION 3: MARGIN, LEVERAGE & FINANCING =================
        _buildSectionHeader('Margin, Leverage & Financing', colors),
        const SizedBox(height: 4),

        _buildPropertyRow('Leverage', leverageStr, colors),
        _buildPropertyRow('Buy Required Margin',
            isCommodity ? '0.20%' : '20.00%', colors),
        _buildPropertyRow('Sell Required Margin',
            isCommodity ? '0.20%' : '20.00%', colors),
        _buildPropertyRow('Holding Buy Margin', '2.00%', colors),
        _buildPropertyRow('Holding Sell Margin', '2.00%', colors),
        _buildPropertyRow(
            'Swap Long (Overnight Financing)',
            isCrypto || isCommodity
                ? '-0.015% / day'
                : '₹0.00 (Zero Overnight Interest)',
            colors),
        _buildPropertyRow(
            'Swap Short (Overnight Financing)',
            isCrypto || isCommodity ? '+0.005% / day' : '₹0.00',
            colors),
        _buildPropertyRow(
            '3-Day Swap Rollover Day', 'Wednesday 23:30 IST', colors),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildOhlcItem(String label, double val, TradingColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          val.toStringAsFixed(2),
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, TradingColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: colors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildPropertyRow(String label, String value, TradingColors colors) {
    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 6,
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          thickness: 0.8,
          color: colors.divider,
        ),
      ],
    );
  }
}
