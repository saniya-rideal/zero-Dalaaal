import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../orders/data/real_trading_repository.dart';
import '../../orders/domain/trading_repository.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/margin_risk_banner.dart';
import '../../../shared_widgets/zero_app_bar.dart';
import '../../../shared_widgets/zero_drawer.dart';
import '../../positions/presentation/position_action_sheets.dart';

enum DealProfitFilter { all, profitable, losing }

class DealsScreen extends ConsumerStatefulWidget {
  const DealsScreen({super.key});

  @override
  ConsumerState<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends ConsumerState<DealsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSortAscending = true;
  DealProfitFilter _dealProfitFilter = DealProfitFilter.all;
  final Set<String> _selectedDeals = {};
  final Set<String> _selectedOrders = {};

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
    final ordersAsync = ref.watch(ordersListProvider);
    final positionsAsync = ref.watch(positionsListProvider);

    final allOrders = ordersAsync.valueOrNull ?? const <Order>[];
    var openOrders = allOrders
        .where((o) =>
            o.status == OrderStatus.OPEN ||
            o.status == OrderStatus.SUBMITTED ||
            o.status == OrderStatus.TRIGGER_PENDING)
        .toList();
    var activePositions = List<Position>.from(positionsAsync.valueOrNull ?? const <Position>[]);

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

    final profitableDealsCount = activePositions.where((p) => p.unrealizedPnl > 0).length;
    final losingDealsCount = activePositions.where((p) => p.unrealizedPnl < 0).length;

    final displayedPositions = activePositions.where((p) {
      switch (_dealProfitFilter) {
        case DealProfitFilter.all:
          return true;
        case DealProfitFilter.profitable:
          return p.unrealizedPnl > 0;
        case DealProfitFilter.losing:
          return p.unrealizedPnl < 0;
      }
    }).toList();

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
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.divider.withValues(alpha: 0.5)),
              ),
              child: TextField(
                controller: _searchController,
                textAlignVertical: TextAlignVertical.center,
                style: AppTypography.body(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search Deals by script',
                  hintStyle: AppTypography.body(color: colors.textSecondary),
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
                  const SizedBox(height: 4),

                  // Deals Section Pill Header (Select | Deals | Action)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: colors.scriptBarBackground,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (_selectedDeals.length == activePositions.length) {
                                  _selectedDeals.clear();
                                } else {
                                  _selectedDeals.addAll(activePositions.map((p) => p.id));
                                }
                              });
                            },
                            child: Text(
                              _selectedDeals.length == activePositions.length && activePositions.isNotEmpty
                                  ? 'Deselect'
                                  : 'Select',
                              style: AppTypography.body(color: colors.secondary, weight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            'Deals (${activePositions.length})',
                            style: AppTypography.body(color: colors.textPrimary, weight: FontWeight.w700),
                          ),
                          InkWell(
                            onTap: () => _showBatchActionSheet(context, tradingRepo, colors),
                            child: Text(
                              'Action',
                              style: AppTypography.body(color: colors.primary, weight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Profitable vs Losing Quick Filter Chips
                  if (activePositions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: Text(
                                'All (${activePositions.length})',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                              selected: _dealProfitFilter == DealProfitFilter.all,
                              onSelected: (val) {
                                if (val) setState(() => _dealProfitFilter = DealProfitFilter.all);
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: colors.bullish,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '$profitableDealsCount Profitable',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _dealProfitFilter == DealProfitFilter.profitable ? colors.bullish : colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              selected: _dealProfitFilter == DealProfitFilter.profitable,
                              selectedColor: colors.bullish.withValues(alpha: 0.18),
                              onSelected: (val) {
                                if (val) setState(() => _dealProfitFilter = DealProfitFilter.profitable);
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: colors.bearish,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '$losingDealsCount Losing',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _dealProfitFilter == DealProfitFilter.losing ? colors.bearish : colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              selected: _dealProfitFilter == DealProfitFilter.losing,
                              selectedColor: colors.bearish.withValues(alpha: 0.18),
                              onSelected: (val) {
                                if (val) setState(() => _dealProfitFilter = DealProfitFilter.losing);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Deals Content List / Empty State
                  if (activePositions.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      alignment: Alignment.center,
                      child: Text(
                        'No open deals',
                        style: AppTypography.body(color: colors.textSecondary, weight: FontWeight.w500),
                      ),
                    )
                  else if (displayedPositions.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      alignment: Alignment.center,
                      child: Text(
                        _dealProfitFilter == DealProfitFilter.profitable
                            ? 'No profitable deals'
                            : 'No losing deals',
                        style: AppTypography.body(color: colors.textSecondary, weight: FontWeight.w500),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayedPositions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final pos = displayedPositions[index];
                        final isSelected = _selectedDeals.contains(pos.id);

                        return Material(
                          color: Colors.transparent,
                          child: ListTile(
                            onTap: () => PositionActionSheets.showFullOptions(
                              context,
                              pos,
                              tradingRepo,
                              onRefresh: () => ref.invalidate(positionsListProvider),
                            ),
                            leading: Checkbox(
                              value: isSelected,
                              activeColor: colors.primary,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedDeals.add(pos.id);
                                  } else {
                                    _selectedDeals.remove(pos.id);
                                  }
                                });
                              },
                            ),
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: (pos.isLong ? colors.bullish : colors.bearish)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    pos.isLong ? 'LONG' : 'SHORT',
                                    style: GoogleFonts.inter(
                                      color: pos.isLong
                                          ? colors.bullish
                                          : colors.bearish,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    pos.instrument.symbol,
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w800,
                                        color: colors.textPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: colors.surface,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    '${pos.leverage.toInt()}x ${pos.product.name}',
                                    style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: colors.textSecondary,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text(
                                  'Qty: ${pos.netQty.abs()} • Entry: ${CurrencyFormatter.format(pos.entryPrice)} • LTP: ${CurrencyFormatter.format(pos.ltp)}',
                                  style: GoogleFonts.inter(
                                      color: colors.textSecondary, fontSize: 11),
                                ),
                                const SizedBox(height: 2),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 2,
                                  children: [
                                    Text(
                                      pos.stopLoss != null
                                          ? 'SL: ₹${pos.stopLoss!.toStringAsFixed(2)}'
                                          : 'SL: --',
                                      style: GoogleFonts.inter(
                                          color: colors.textSecondary,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      pos.takeProfit != null
                                          ? 'TP: ₹${pos.takeProfit!.toStringAsFixed(2)}'
                                          : 'TP: --',
                                      style: GoogleFonts.inter(
                                          color: colors.textSecondary,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      'Margin: ${CurrencyFormatter.format(pos.usedMargin)}',
                                      style: GoogleFonts.inter(
                                          color: colors.textSecondary
                                              .withValues(alpha: 0.8),
                                          fontSize: 10.5),
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
                                      CurrencyFormatter.formatSigned(
                                          pos.unrealizedPnl,
                                          showSymbol: true),
                                      style: GoogleFonts.inter(
                                        color: pos.unrealizedPnl >= 0
                                            ? colors.bullish
                                            : colors.bearish,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures()
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: (pos.pnlPercent >= 0
                                                ? colors.bullish
                                                : colors.bearish)
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        '${pos.pnlPercent >= 0 ? '+' : ''}${pos.pnlPercent.toStringAsFixed(2)}%',
                                        style: GoogleFonts.inter(
                                          color: pos.pnlPercent >= 0
                                              ? colors.bullish
                                              : colors.bearish,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures()
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 4),
                                Icon(LucideIcons.chevronRight,
                                    color: colors.textSecondary, size: 18),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 16),

                  // Orders Section Pill Header (Select All | Orders | Cancel)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: colors.scriptBarBackground,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  if (_selectedOrders.length == openOrders.length) {
                                    _selectedOrders.clear();
                                  } else {
                                    _selectedOrders.addAll(openOrders.map((o) => o.orderId));
                                  }
                                });
                              },
                              child: Text(
                                _selectedOrders.length == openOrders.length && openOrders.isNotEmpty
                                    ? 'Deselect'
                                    : 'Select All',
                                style: AppTypography.caption(color: colors.secondary, weight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0),
                            child: Text(
                              'Orders (${openOrders.length})',
                              style: AppTypography.body(color: colors.textPrimary, weight: FontWeight.w700),
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              if (_selectedOrders.isNotEmpty) {
                                for (final orderId in _selectedOrders) {
                                  await tradingRepo.cancelOrder(orderId);
                                }
                                _selectedOrders.clear();
                                ref.invalidate(ordersListProvider);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Selected orders cancelled')),
                                  );
                                }
                              }
                            },
                            child: Text(
                              'Cancel',
                              style: AppTypography.caption(color: colors.primary, weight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Orders Content List / Empty State
                  if (openOrders.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      alignment: Alignment.center,
                      child: Text(
                        'No pending orders',
                        style: AppTypography.body(color: colors.textSecondary, weight: FontWeight.w500),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: openOrders.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: colors.divider),
                      itemBuilder: (context, index) {
                        final order = openOrders[index];
                        final isSelected = _selectedOrders.contains(order.orderId);

                        return Material(
                          color: Colors.transparent,
                          child: ListTile(
                            onTap: () => _showOrderOptionsSheet(context, order, tradingRepo, colors),
                            leading: Checkbox(
                              value: isSelected,
                              activeColor: colors.primary,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedOrders.add(order.orderId);
                                  } else {
                                    _selectedOrders.remove(order.orderId);
                                  }
                                });
                              },
                            ),
                            title: Text(order.instrument.symbol,
                                style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: colors.textPrimary)),
                            subtitle: Text('${order.request.side.name} • ${order.request.quantity} Qty • Limit: ${order.request.price}',
                                style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 12)),
                            trailing: Text(
                              order.status.name,
                              style: GoogleFonts.inter(
                                color: colors.warning,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderOptionsSheet(
      BuildContext context, Order order, TradingRepository tradingRepo, TradingColors colors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.instrument.symbol,
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: colors.textPrimary),
                    ),
                    Text(
                      'Order #${order.orderId}',
                      style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Divider(height: 1, color: colors.divider),
              ListTile(
                leading: Icon(LucideIcons.xCircle, color: colors.bearish, size: 20),
                title: Text('Cancel Order',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: colors.bearish)),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm Cancellation'),
                      content: Text(
                        'Cancel order for ${order.instrument.symbol}?\n\nOrder ID: ${order.orderId}\n\nThis action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('No, Keep'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: colors.bearish),
                          child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    await tradingRepo.cancelOrder(order.id);
                    ref.invalidate(ordersListProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Order ${order.orderId} cancelled'),
                          backgroundColor: colors.bearish,
                        ),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.candlestickChart, color: Color(0xFF1E88E5), size: 20),
                title: Text('Open Fullscreen Chart',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: colors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/chart-fullscreen/${order.instrument.token}');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBatchActionSheet(
      BuildContext context, TradingRepository tradingRepo, TradingColors colors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Deals Quick Actions',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: colors.textPrimary)),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Batch Square-off request submitted')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Square Off All Active Positions'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _selectedDeals.clear();
                  setState(() {});
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Clear Selection'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
