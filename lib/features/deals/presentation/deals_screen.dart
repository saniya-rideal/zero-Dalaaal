import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/mock/order_simulation_engine.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/news_ticker_strip.dart';
import '../../../shared_widgets/script_selector_bar.dart';
import '../../../shared_widgets/zero_app_bar.dart';
import '../../../shared_widgets/zero_drawer.dart';
import '../../order_entry/presentation/order_entry_sheet.dart';

class DealsScreen extends ConsumerStatefulWidget {
  const DealsScreen({super.key});

  @override
  ConsumerState<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends ConsumerState<DealsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSortAscending = true;
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
    final engine = ref.watch(orderSimulationEngineProvider);
    var openOrders = List<Order>.from(engine.orders
        .where((o) => o.status == OrderStatus.OPEN || o.status == OrderStatus.TRIGGER_PENDING));
    var activePositions = List<Position>.from(engine.positions);

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
          // Public & Private News Ticker Strip
          const NewsTickerStrip(),

          // Dual Script Selector Bar
          const ScriptSelectorBar(),

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
                  prefixIcon: Icon(Icons.search, color: colors.textSecondary, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: colors.textSecondary, size: 18),
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
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  const SizedBox(height: 6),

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
                            onTap: () => _showBatchActionSheet(context, engine, colors),
                            child: Text(
                              'Action',
                              style: AppTypography.body(color: colors.primary, weight: FontWeight.w600),
                            ),
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
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activePositions.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: colors.divider),
                      itemBuilder: (context, index) {
                        final pos = activePositions[index];
                        final isSelected = _selectedDeals.contains(pos.id);

                        return Material(
                          color: Colors.transparent,
                          child: ListTile(
                            onTap: () => _showDealOptionsSheet(context, pos, engine, colors),
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
                            title: Text(pos.instrument.symbol,
                                style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: colors.textPrimary)),
                            subtitle: Text('Qty: ${pos.netQty} • Buy Avg: ${pos.buyAvg.toStringAsFixed(2)}',
                                style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 12)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  CurrencyFormatter.formatSigned(pos.unrealizedPnl, showSymbol: true),
                                  style: GoogleFonts.inter(
                                    color: pos.unrealizedPnl >= 0 ? colors.bullish : colors.bearish,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.chevron_right, color: colors.textSecondary, size: 20),
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
                                if (_selectedOrders.length == openOrders.length) {
                                  _selectedOrders.clear();
                                } else {
                                  _selectedOrders.addAll(openOrders.map((o) => o.orderId));
                                }
                              });
                            },
                            child: Text(
                              _selectedOrders.length == openOrders.length && openOrders.isNotEmpty
                                  ? 'Deselect All'
                                  : 'Select All',
                              style: AppTypography.body(color: colors.secondary, weight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            'Orders (${openOrders.length})',
                            style: AppTypography.body(color: colors.textPrimary, weight: FontWeight.w700),
                          ),
                          InkWell(
                            onTap: () {
                              if (_selectedOrders.isNotEmpty) {
                                for (final orderId in _selectedOrders) {
                                  engine.cancelOrder(orderId);
                                }
                                _selectedOrders.clear();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Selected orders cancelled')),
                                );
                              }
                            },
                            child: Text(
                              'Cancel',
                              style: AppTypography.body(color: colors.primary, weight: FontWeight.w600),
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
                            onTap: () => _showOrderOptionsSheet(context, order, engine, colors),
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

  void _showDealOptionsSheet(
      BuildContext context, Position pos, OrderSimulationEngine engine, TradingColors colors) {
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
                      pos.instrument.symbol,
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: colors.textPrimary),
                    ),
                    Text(
                      CurrencyFormatter.formatSigned(pos.unrealizedPnl, showSymbol: true),
                      style: GoogleFonts.inter(
                        color: pos.unrealizedPnl >= 0 ? colors.bullish : colors.bearish,
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
                title: Text('Square Off / Close Deal',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: colors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  final exitSide = pos.netQty > 0 ? TransactionType.SELL : TransactionType.BUY;
                  OrderEntrySheet.show(context, instrument: pos.instrument, side: exitSide);
                },
              ),
              ListTile(
                leading: const Icon(Icons.candlestick_chart, color: Color(0xFF1E88E5)),
                title: Text('Open Fullscreen Chart',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: colors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/chart-fullscreen/${pos.instrument.token}');
                },
              ),
              ListTile(
                leading: Icon(Icons.info_outline, color: colors.textSecondary),
                title: Text('View Script Specifications',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: colors.textPrimary)),
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

  void _showOrderOptionsSheet(
      BuildContext context, Order order, OrderSimulationEngine engine, TradingColors colors) {
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
                leading: Icon(Icons.cancel_outlined, color: colors.bearish),
                title: Text('Cancel Order',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: colors.bearish)),
                onTap: () {
                  Navigator.pop(context);
                  engine.cancelOrder(order.orderId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order cancelled')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.candlestick_chart, color: Color(0xFF1E88E5)),
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
      BuildContext context, OrderSimulationEngine engine, TradingColors colors) {
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
