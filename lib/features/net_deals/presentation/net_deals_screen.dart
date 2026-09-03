import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/mock/order_simulation_engine.dart';
import '../../../data/mock/ticker_service.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/position.dart';
import '../../../shared_widgets/news_ticker_strip.dart';
import '../../../shared_widgets/script_selector_bar.dart';
import '../../../shared_widgets/zero_app_bar.dart';
import '../../../shared_widgets/zero_drawer.dart';
import '../../order_entry/presentation/order_entry_sheet.dart';

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
    final engine = ref.watch(orderSimulationEngineProvider);
    final tickerService = ref.watch(tickerServiceProvider);
    var positions = List<Position>.from(engine.positions);

    // Apply Search Filter
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      positions = positions
          .where((p) =>
              p.instrument.symbol.toLowerCase().contains(query) ||
              p.id.toLowerCase().contains(query))
          .toList();
    }

    // Compute Net Totals
    double totalNetPnl = 0.0;
    for (final pos in positions) {
      final quote = tickerService.getQuote(pos.instrument.token);
      final currentPrice = quote.ltp;
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
          // Public & Private News Ticker Strip
          const NewsTickerStrip(),

          // Dual Script Selector Bar
          const ScriptSelectorBar(),

          // Search Bar
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: colors.divider.withValues(alpha: 0.5)),
              ),
              child: TextField(
                controller: _searchController,
                textAlignVertical: TextAlignVertical.center,
                style: AppTypography.body(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search Net Deals by script',
                  hintStyle: AppTypography.body(color: colors.textSecondary),
                  prefixIcon:
                      Icon(Icons.search, color: colors.textSecondary, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear,
                              color: colors.textSecondary, size: 18),
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

          // Total Net PnL Summary Banner
          if (positions.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colors.cardBackground,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: colors.divider, width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Net MTM P&L (${positions.length} Open)',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary),
                  ),
                  Text(
                    CurrencyFormatter.formatSigned(totalNetPnl, showSymbol: true),
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: totalNetPnl >= 0 ? colors.bullish : colors.bearish,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),

          // Net Deals List
          Expanded(
            child: positions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 42,
                            color: colors.textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 8),
                        Text(
                          'No open net deals',
                          style: GoogleFonts.inter(
                              color: colors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: positions.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: colors.divider),
                    itemBuilder: (context, index) {
                      final pos = positions[index];
                      final quote =
                          tickerService.getQuote(pos.instrument.token);
                      final currentPrice = quote.ltp;
                      final unrealized = pos.netQty *
                          (currentPrice -
                              (pos.buyAvg > 0 ? pos.buyAvg : pos.sellAvg));
                      final itemPnl = pos.realizedPnl + unrealized;
                      final pnlColor =
                          itemPnl >= 0 ? colors.bullish : colors.bearish;

                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          onTap: () =>
                              _showNetDealOptionsSheet(context, pos, currentPrice, itemPnl, colors),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(pos.instrument.symbol,
                                  style: GoogleFonts.inter(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.w800)),
                              Text(
                                CurrencyFormatter.formatSigned(itemPnl,
                                    showSymbol: false),
                                style: GoogleFonts.inter(
                                    color: pnlColor,
                                    fontWeight: FontWeight.w800,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ]),
                              ),
                            ],
                          ),
                          subtitle: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  'Net Lots: ${pos.netQty} • Entry: ${CurrencyFormatter.format(pos.buyAvg > 0 ? pos.buyAvg : pos.sellAvg)}',
                                  style: GoogleFonts.inter(
                                      color: colors.textSecondary,
                                      fontSize: 12)),
                              Text('LTP: ${CurrencyFormatter.format(currentPrice)}',
                                  style: GoogleFonts.inter(
                                      color: colors.marginValue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ])),
                            ],
                          ),
                          trailing: Icon(Icons.chevron_right,
                              color: colors.textSecondary, size: 20),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showNetDealOptionsSheet(BuildContext context, Position pos,
      double currentPrice, double pnl, TradingColors colors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.cardBackground,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      pos.instrument.symbol,
                      style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary),
                    ),
                    Text(
                      CurrencyFormatter.formatSigned(pnl, showSymbol: true),
                      style: GoogleFonts.inter(
                        color: pnl >= 0 ? colors.bullish : colors.bearish,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Divider(height: 1, color: colors.divider),
              ListTile(
                leading: Icon(Icons.close_fullscreen, color: colors.primary),
                title: Text('Close Net Position',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary)),
                subtitle: Text(
                    'Exit current ${pos.netQty} lots at market LTP ${CurrencyFormatter.format(currentPrice)}',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: colors.textSecondary)),
                onTap: () {
                  Navigator.pop(context);
                  final exitSide = pos.netQty > 0
                      ? TransactionType.SELL
                      : TransactionType.BUY;
                  OrderEntrySheet.show(context,
                      instrument: pos.instrument, side: exitSide);
                },
              ),
              ListTile(
                leading: const Icon(Icons.candlestick_chart,
                    color: Color(0xFF1E88E5)),
                title: Text('Open Fullscreen Chart',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/chart-fullscreen/${pos.instrument.token}');
                },
              ),
              ListTile(
                leading: Icon(Icons.info_outline, color: colors.textSecondary),
                title: Text('View Script Details',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/quote-detail/${pos.instrument.token}');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
