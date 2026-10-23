import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/services/realtime_quote_service.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../orders/data/real_trading_repository.dart';
import '../../orders/domain/trading_repository.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/margin_risk_banner.dart';
import '../../../shared_widgets/zero_app_bar.dart';
import '../../../shared_widgets/zero_drawer.dart';
import '../../../shared_widgets/zero_market_header_strip.dart';
import '../../funds/data/real_funds_repository.dart';
import '../../order_entry/presentation/order_entry_sheet.dart';

class DealsScreen extends ConsumerStatefulWidget {
  const DealsScreen({super.key});

  @override
  ConsumerState<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends ConsumerState<DealsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSortAscending = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSort() {
    setState(() {
      _isSortAscending = !_isSortAscending;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final tradingRepo = ref.read(tradingRepositoryProvider);
    final quoteService = ref.watch(realtimeQuoteServiceProvider);
    ref.watch(quotesStreamProvider); // Automatically rebuilds on live WebSocket tick
    final ordersAsync = ref.watch(ordersListProvider);
    final positionsAsync = ref.watch(positionsListProvider);

    final allOrders = ordersAsync.valueOrNull ?? const <Order>[];
    var openOrders = allOrders
        .where((o) =>
            o.status == OrderStatus.OPEN ||
            o.status == OrderStatus.SUBMITTED ||
            o.status == OrderStatus.TRIGGER_PENDING)
        .toList();
    final rawPositions = List<Position>.from(positionsAsync.valueOrNull ?? const <Position>[]);

    // Subscribe to live quotes & dynamically attach real-time tick LTP
    var activePositions = rawPositions.map((p) {
      quoteService.subscribe(p.instrument.symbol);
      final quote = quoteService.getQuote(p.instrument.symbol);
      final currentPrice = quote.ltp > 0 ? quote.ltp : p.ltp;
      return p.copyWith(ltp: currentPrice);
    }).toList();

    // Apply Search Filter
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      openOrders = openOrders.where((o) => o.instrument.symbol.toLowerCase().contains(query)).toList();
      activePositions = activePositions.where((p) => p.instrument.symbol.toLowerCase().contains(query)).toList();
    }

    // Apply Alphabetical Sorting
    openOrders.sort((a, b) =>
        _isSortAscending ? a.instrument.symbol.compareTo(b.instrument.symbol) : b.instrument.symbol.compareTo(a.instrument.symbol));
    activePositions.sort((a, b) =>
        _isSortAscending ? a.instrument.symbol.compareTo(b.instrument.symbol) : b.instrument.symbol.compareTo(a.instrument.symbol));

    final totalDealsPnl = activePositions.fold<double>(0.0, (sum, p) => sum + p.unrealizedPnl);

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const ZeroDrawer(activeRoute: '/deals'),
      appBar: ZeroAppBar(
        title: 'Deals',
        showFilterAction: false,
        showSortAction: true,
        showCalendarAction: false,
        isSortAscending: _isSortAscending,
        onSortTap: _toggleSort,
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
                  hintText: 'Search Deals by script',
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

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(positionsListProvider);
                ref.invalidate(ordersListProvider);
                ref.invalidate(fundsSummaryProvider);
                await Future.wait([
                  ref.read(positionsListProvider.future),
                  ref.read(ordersListProvider.future),
                ]);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                children: [
                  // Margin Risk Alert Banner
                  const MarginRiskBanner(
                    segment: Segment.EQUITY,
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                  const SizedBox(height: 6),

                  // Deals Section Pill Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                            'Deals (${activePositions.length})',
                            style: GoogleFonts.inter(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                          ),
                          if (activePositions.isNotEmpty)
                            Text(
                              CurrencyFormatter.formatSigned(totalDealsPnl, showSymbol: true),
                              style: GoogleFonts.inter(
                                color: totalDealsPnl >= 0 ? colors.bullish : colors.bearish,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Deals Content List / Empty State
                  if (activePositions.isEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: colors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.divider.withValues(alpha: 0.4)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'No open deals',
                        style: GoogleFonts.inter(color: colors.textSecondary, fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
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
                          itemCount: activePositions.length,
                          separatorBuilder: (_, __) => Divider(height: 1, thickness: 0.5, color: colors.divider.withValues(alpha: 0.4)),
                          itemBuilder: (context, index) {
                            final pos = activePositions[index];

                            return Material(
                              color: Colors.transparent,
                              child: ListTile(
                                onTap: () => _showDealOptionsSheet(context, pos, tradingRepo, colors),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                title: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: (pos.isLong ? colors.bullish : colors.bearish).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        pos.isLong ? 'LONG' : 'SHORT',
                                        style: GoogleFonts.inter(
                                          color: pos.isLong ? colors.bullish : colors.bearish,
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
                                          fontWeight: FontWeight.w700,
                                          color: colors.textPrimary,
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
                                      'Qty: ${pos.netQty.abs()} • Entry: ${CurrencyFormatter.format(pos.entryPrice)} → LTP: ${CurrencyFormatter.format(pos.ltp)}',
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
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          CurrencyFormatter.formatSigned(pos.unrealizedPnl, showSymbol: true),
                                          style: GoogleFonts.inter(
                                            color: pos.unrealizedPnl >= 0 ? colors.bullish : colors.bearish,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13.5,
                                            fontFeatures: const [FontFeature.tabularFigures()],
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: (pos.pnlPercent >= 0 ? colors.bullish : colors.bearish).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            '${pos.pnlPercent >= 0 ? '+' : ''}${pos.pnlPercent.toStringAsFixed(2)}%',
                                            style: GoogleFonts.inter(
                                              color: pos.pnlPercent >= 0 ? colors.bullish : colors.bearish,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              fontFeatures: const [FontFeature.tabularFigures()],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(LucideIcons.chevronRight, color: colors.textSecondary.withValues(alpha: 0.7), size: 16),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Orders Section Pill Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                            'Orders (${openOrders.length})',
                            style: GoogleFonts.inter(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                          ),
                          if (openOrders.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'PENDING',
                                style: GoogleFonts.inter(
                                  color: colors.warning,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Orders Content List / Empty State
                  if (openOrders.isEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: colors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.divider.withValues(alpha: 0.4)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'No pending orders',
                        style: GoogleFonts.inter(color: colors.textSecondary, fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
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
                          itemCount: openOrders.length,
                          separatorBuilder: (_, __) => Divider(height: 1, thickness: 0.5, color: colors.divider.withValues(alpha: 0.4)),
                          itemBuilder: (context, index) {
                            final order = openOrders[index];
                            final isBuy = order.request.side == TransactionType.BUY;

                            return Material(
                              color: Colors.transparent,
                              child: ListTile(
                                onTap: () => _showOrderOptionsSheet(context, order, tradingRepo, colors),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                title: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: (isBuy ? colors.bullish : colors.bearish).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        order.request.side.name,
                                        style: GoogleFonts.inter(
                                          color: isBuy ? colors.bullish : colors.bearish,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        order.instrument.displayName,
                                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: colors.textPrimary, fontSize: 13.5),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 3),
                                    Text(
                                      '${order.request.quantity} Qty on Ticket #${order.orderId}',
                                      style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 11),
                                    ),
                                    if (order.request.price != null && order.request.price! > 0)
                                      Text(
                                        'Limit: ₹${order.request.price!.toStringAsFixed(2)}',
                                        style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 10.5),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        if (order.request.price != null && order.request.price! > 0)
                                          Text(
                                            '₹${order.request.price!.toStringAsFixed(2)}',
                                            style: GoogleFonts.inter(
                                              color: colors.secondary,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13.5,
                                              fontFeatures: const [FontFeature.tabularFigures()],
                                            ),
                                          ),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: colors.warning.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            order.status.name,
                                            style: GoogleFonts.inter(
                                              color: colors.warning,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 10.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(LucideIcons.chevronRight, color: colors.textSecondary.withValues(alpha: 0.7), size: 16),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }

  // --- "Select Option" Modal for Deals (Matches Orders Style) ---
  void _showDealOptionsSheet(
      BuildContext context, Position pos, TradingRepository tradingRepo, TradingColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E222D) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Select Option',
                  style: GoogleFonts.inter(
                    color: colors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                _buildModalOptionItem(
                  title: 'Close Deal',
                  colors: colors,
                  onTap: () async {
                    Navigator.pop(ctx);
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        title: Text('Close Deal', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                        content: Text(
                          'Are you sure you want to close ${pos.instrument.displayName} position of ${pos.netQty.abs()} ${pos.instrument.lotSize > 1 ? "lots" : "qty"} at market price?\n\nCurrent P&L: ${CurrencyFormatter.formatSigned(pos.unrealizedPnl, showSymbol: true)}',
                          style: GoogleFonts.inter(fontSize: 13.5),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx, false),
                            child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(dialogCtx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.bearish,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Close Deal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      try {
                        final key = 'cls_${pos.id}_${DateTime.now().millisecondsSinceEpoch}';
                        await tradingRepo.closePosition(pos.id, idempotencyKey: key);
                        ref.invalidate(positionsListProvider);
                        ref.invalidate(fundsSummaryProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${pos.instrument.displayName} closed successfully'),
                              backgroundColor: colors.bullish,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          final msg = e.toString().replaceAll('Exception: ', '');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to close position: $msg'),
                              backgroundColor: colors.bearish,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
                Divider(height: 1, thickness: 0.6, color: colors.divider.withValues(alpha: 0.6)),
                _buildModalOptionItem(
                  title: 'Modify Deal',
                  colors: colors,
                  onTap: () {
                    Navigator.pop(ctx);
                    OrderEntrySheet.show(
                      context,
                      instrument: pos.instrument,
                      side: pos.isLong ? TransactionType.BUY : TransactionType.SELL,
                      initialQuantity: pos.netQty.abs(),
                      initialStopLoss: pos.stopLoss,
                      initialTakeProfit: pos.takeProfit,
                    );
                  },
                ),
                Divider(height: 1, thickness: 0.6, color: colors.divider.withValues(alpha: 0.6)),
                _buildModalOptionItem(
                  title: 'Go To Market',
                  colors: colors,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/chart-fullscreen/${pos.instrument.token}');
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- "Select Option" Modal for Orders (Matches Screenshot Exactly) ---
  void _showOrderOptionsSheet(
      BuildContext context, Order order, TradingRepository tradingRepo, TradingColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E222D) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Select Option',
                  style: GoogleFonts.inter(
                    color: colors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                _buildModalOptionItem(
                  title: 'Cancel Order',
                  colors: colors,
                  onTap: () async {
                    Navigator.pop(ctx);
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        title: Text('Confirm Cancellation', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                        content: Text(
                          'Cancel order for ${order.instrument.displayName}?\n\nOrder ID: ${order.orderId}\n\nThis action cannot be undone.',
                          style: GoogleFonts.inter(fontSize: 13.5),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx, false),
                            child: Text('No, Keep', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(dialogCtx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.bearish,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      await tradingRepo.cancelOrder(order.id);
                      ref.invalidate(ordersListProvider);
                      ref.invalidate(fundsSummaryProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Order ${order.orderId} cancelled'),
                            backgroundColor: colors.bearish,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        );
                      }
                    }
                  },
                ),
                Divider(height: 1, thickness: 0.6, color: colors.divider.withValues(alpha: 0.6)),
                _buildModalOptionItem(
                  title: 'Modify Order',
                  colors: colors,
                  onTap: () {
                    Navigator.pop(ctx);
                    OrderEntrySheet.show(
                      context,
                      instrument: order.instrument,
                      side: order.request.side,
                    );
                  },
                ),
                Divider(height: 1, thickness: 0.6, color: colors.divider.withValues(alpha: 0.6)),
                _buildModalOptionItem(
                  title: 'Go To Market',
                  colors: colors,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/chart-fullscreen/${order.instrument.token}');
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Modal Option Row with Chevron ---
  Widget _buildModalOptionItem({
    required String title,
    required TradingColors colors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: colors.textSecondary.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}

