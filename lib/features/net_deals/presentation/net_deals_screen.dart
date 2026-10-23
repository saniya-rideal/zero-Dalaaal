import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/services/realtime_quote_service.dart';
import '../../orders/data/real_trading_repository.dart';
import '../../../data/models/position.dart';
import '../../../shared_widgets/zero_app_bar.dart';
import '../../../shared_widgets/zero_drawer.dart';
import '../../../shared_widgets/zero_market_header_strip.dart';

class NetDealsScreen extends ConsumerStatefulWidget {
  const NetDealsScreen({super.key});

  @override
  ConsumerState<NetDealsScreen> createState() => _NetDealsScreenState();
}

class _NetDealsScreenState extends ConsumerState<NetDealsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final quoteService = ref.watch(realtimeQuoteServiceProvider);
    ref.watch(quotesStreamProvider); // Automatically rebuilds on live WebSocket tick
    final positionsAsync = ref.watch(positionsListProvider);
    var positions = List<Position>.from(positionsAsync.valueOrNull ?? const <Position>[]);

    // Subscribe to live quotes for all net deals symbols
    for (final pos in positions) {
      quoteService.subscribe(pos.instrument.symbol);
    }

    // Apply Search Filter
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      positions = positions
          .where((p) =>
              p.instrument.symbol.toLowerCase().contains(query) ||
              p.instrument.displayName.toLowerCase().contains(query) ||
              p.id.toLowerCase().contains(query))
          .toList();
    }

    // Compute Net Totals
    double totalNetPnl = 0.0;
    for (final pos in positions) {
      final quote = quoteService.getQuote(pos.instrument.symbol);
      final currentPrice = quote.ltp > 0 ? quote.ltp : pos.ltp;
      final unrealized = pos.netQty *
          (currentPrice - (pos.buyAvg > 0 ? pos.buyAvg : pos.sellAvg));
      totalNetPnl += (pos.realizedPnl + unrealized);
    }

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const ZeroDrawer(activeRoute: '/net-deals'),
      appBar: const ZeroAppBar(
        title: 'Net Deals',
        showFilterAction: false,
        showSortAction: false,
        showCalendarAction: false,
      ),
      body: Column(
        children: [
          // Public News & Dual Ticker Header Strip
          const ZeroMarketHeaderStrip(),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.divider.withValues(alpha: 0.5)),
              ),
              child: TextField(
                controller: _searchController,
                textAlignVertical: TextAlignVertical.center,
                style: GoogleFonts.inter(color: colors.textPrimary, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Search Net Deals by script',
                  hintStyle: GoogleFonts.inter(color: colors.textSecondary, fontSize: 13.5),
                  prefixIcon: Icon(LucideIcons.search, color: colors.textSecondary, size: 18),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(LucideIcons.x, color: colors.textSecondary, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onChanged: (val) => setState(() {}),
              ),
            ),
          ),

          // Net Deals Pill Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: colors.scriptBarBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.divider.withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Net Deals (${positions.length})',
                    style: GoogleFonts.inter(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                  if (positions.isNotEmpty)
                    Text(
                      CurrencyFormatter.formatSigned(totalNetPnl, showSymbol: true),
                      style: GoogleFonts.inter(
                        color: totalNetPnl >= 0 ? colors.bullish : colors.bearish,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Net Deals Content List (Simple Section — No Bottom Sheet)
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(positionsListProvider);
                await ref.read(positionsListProvider.future);
              },
              child: positions.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.layers, size: 36, color: colors.textSecondary.withValues(alpha: 0.5)),
                              const SizedBox(height: 8),
                              Text(
                                'No open net deals',
                                style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.divider.withValues(alpha: 0.5)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: positions.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            thickness: 0.5,
                            color: colors.divider.withValues(alpha: 0.4),
                          ),
                          itemBuilder: (context, index) {
                            final pos = positions[index];
                            final quote = quoteService.getQuote(pos.instrument.symbol);
                            final currentPrice = quote.ltp > 0 ? quote.ltp : pos.ltp;
                            final posWithLtp = pos.copyWith(ltp: currentPrice);
                            final itemPnl = posWithLtp.realizedPnl + posWithLtp.unrealizedPnl;
                            final pnlColor = itemPnl >= 0 ? colors.bullish : colors.bearish;

                            return Material(
                              color: Colors.transparent,
                              child: ListTile(
                                // Simple section display: no bottom sheet popup on tap
                                onTap: null,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                title: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: (posWithLtp.isLong ? colors.bullish : colors.bearish).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        posWithLtp.isLong ? 'LONG' : 'SHORT',
                                        style: GoogleFonts.inter(
                                          color: posWithLtp.isLong ? colors.bullish : colors.bearish,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        pos.instrument.displayName,
                                        style: GoogleFonts.inter(
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.5,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: colors.surface,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${pos.leverage.toInt()}x ${pos.product.name}',
                                        style: GoogleFonts.inter(
                                          fontSize: 9.5,
                                          color: colors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 3),
                                    Text(
                                      'Qty: ${pos.netQty.abs()} • Entry: ${CurrencyFormatter.format(pos.entryPrice)} → LTP: ${CurrencyFormatter.format(currentPrice)}',
                                      style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 11),
                                    ),
                                    const SizedBox(height: 2),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 2,
                                      children: [
                                        Text(
                                          pos.stopLoss != null ? 'SL: ₹${pos.stopLoss!.toStringAsFixed(2)}' : 'SL: --',
                                          style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          pos.takeProfit != null ? 'TP: ₹${pos.takeProfit!.toStringAsFixed(2)}' : 'TP: --',
                                          style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          'Margin: ${CurrencyFormatter.format(pos.usedMargin)}',
                                          style: GoogleFonts.inter(color: colors.textSecondary.withValues(alpha: 0.8), fontSize: 10.5),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      CurrencyFormatter.formatSigned(itemPnl, showSymbol: true),
                                      style: GoogleFonts.inter(
                                        color: pnlColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5,
                                        fontFeatures: const [FontFeature.tabularFigures()],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: (posWithLtp.pnlPercent >= 0 ? colors.bullish : colors.bearish).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        '${posWithLtp.pnlPercent >= 0 ? '+' : ''}${posWithLtp.pnlPercent.toStringAsFixed(2)}%',
                                        style: GoogleFonts.inter(
                                          color: posWithLtp.pnlPercent >= 0 ? colors.bullish : colors.bearish,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          fontFeatures: const [FontFeature.tabularFigures()],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
