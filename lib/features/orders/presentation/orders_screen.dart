import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/mock/order_simulation_engine.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/shared_widgets.dart';
import '../../../shared_widgets/zero_app_bar.dart';
import '../../../shared_widgets/zero_drawer.dart';
import '../../order_entry/presentation/gtt_create_sheet.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Filter & Sort States
  TransactionType? _selectedSide; // null = all, BUY, SELL
  OrderStatus? _selectedStatus; // null = all
  HistoryDateFilter _selectedDateFilter = HistoryDateFilter.all;
  DateTimeRange? _customDateRange;
  bool _isSortNewestFirst = true; // true = newest first, false = oldest first

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedStatus = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _searchController.text.trim().isNotEmpty ||
      _selectedSide != null ||
      _selectedStatus != null ||
      _selectedDateFilter != HistoryDateFilter.all ||
      _customDateRange != null;

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedSide = null;
      _selectedStatus = null;
      _selectedDateFilter = HistoryDateFilter.all;
      _customDateRange = null;
    });
  }

  String _getDateFilterLabel() {
    if (_customDateRange != null) {
      final f = DateFormat('dd MMM');
      return '${f.format(_customDateRange!.start)} - ${f.format(_customDateRange!.end)}';
    }
    return _selectedDateFilter.label;
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final initialRange = _customDateRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: initialRange,
      builder: (context, child) {
        final colors = context.tradingColors;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: colors.primary,
              onPrimary: Colors.white,
              surface: colors.cardBackground,
              onSurface: colors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedDateFilter = HistoryDateFilter.all;
      });
    }
  }

  List<Order> _applyFiltersAndSort(List<Order> source) {
    var list = List<Order>.from(source);

    // 1. Search Query (Instrument symbol, name, or Order ID)
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list
          .where((o) =>
              o.instrument.symbol.toLowerCase().contains(query) ||
              o.instrument.name.toLowerCase().contains(query) ||
              o.orderId.toLowerCase().contains(query))
          .toList();
    }

    // 2. Filter by Side
    if (_selectedSide != null) {
      list = list.where((o) => o.request.side == _selectedSide).toList();
    }

    // 3. Filter by Status
    if (_selectedStatus != null) {
      list = list.where((o) => o.status == _selectedStatus).toList();
    }

    // 4. Filter by Date
    final now = DateTime.now();
    if (_customDateRange != null) {
      final start = DateTime(
        _customDateRange!.start.year,
        _customDateRange!.start.month,
        _customDateRange!.start.day,
      );
      final end = DateTime(
        _customDateRange!.end.year,
        _customDateRange!.end.month,
        _customDateRange!.end.day,
        23,
        59,
        59,
      );
      list = list
          .where((o) => o.placedAt.isAfter(start) && o.placedAt.isBefore(end))
          .toList();
    } else if (_selectedDateFilter == HistoryDateFilter.lastDay) {
      list = list
          .where((o) =>
              o.placedAt.year == now.year &&
              o.placedAt.month == now.month &&
              o.placedAt.day == now.day)
          .toList();
    } else if (_selectedDateFilter == HistoryDateFilter.lastWeek) {
      final weekAgo = now.subtract(const Duration(days: 7));
      list = list.where((o) => o.placedAt.isAfter(weekAgo)).toList();
    } else if (_selectedDateFilter == HistoryDateFilter.lastMonth) {
      final monthAgo = now.subtract(const Duration(days: 30));
      list = list.where((o) => o.placedAt.isAfter(monthAgo)).toList();
    }

    // 5. Sort newest/oldest
    list.sort((a, b) => _isSortNewestFirst
        ? b.placedAt.compareTo(a.placedAt)
        : a.placedAt.compareTo(b.placedAt));

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final engine = ref.watch(orderSimulationEngineProvider);

    // Watch orders stream
    final ordersAsync = ref.watch(ordersListProvider);
    final allOrders = ordersAsync.value ?? engine.orders;

    final pendingOrdersRaw = allOrders
        .where((o) =>
            o.status == OrderStatus.DRAFT ||
            o.status == OrderStatus.SUBMITTED ||
            o.status == OrderStatus.OPEN ||
            o.status == OrderStatus.TRIGGER_PENDING)
        .toList();

    final executedOrdersRaw = allOrders
        .where((o) =>
            o.status == OrderStatus.COMPLETE ||
            o.status == OrderStatus.PARTIALLY_FILLED ||
            o.status == OrderStatus.CANCELLED ||
            o.status == OrderStatus.REJECTED ||
            o.status == OrderStatus.EXPIRED ||
            o.status == OrderStatus.FAILED)
        .toList();

    final gttAsync = ref.watch(gttsListProvider);
    final gttsRaw = gttAsync.value ?? engine.gtts;

    // Filtered lists
    final pendingOrders = _applyFiltersAndSort(pendingOrdersRaw);
    final executedOrders = _applyFiltersAndSort(executedOrdersRaw);

    // Filter GTTs
    final query = _searchController.text.trim().toLowerCase();
    var filteredGtts = List<GttOrder>.from(gttsRaw);
    if (query.isNotEmpty) {
      filteredGtts = filteredGtts
          .where((g) =>
              g.instrument.symbol.toLowerCase().contains(query) ||
              g.instrument.name.toLowerCase().contains(query) ||
              g.id.toLowerCase().contains(query))
          .toList();
    }
    if (_selectedSide != null) {
      filteredGtts =
          filteredGtts.where((g) => g.request.side == _selectedSide).toList();
    }
    filteredGtts.sort((a, b) => _isSortNewestFirst
        ? b.createdAt.compareTo(a.createdAt)
        : a.createdAt.compareTo(b.createdAt));

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const ZeroDrawer(activeRoute: '/orders'),
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (innerContext) {
            if (Navigator.canPop(innerContext)) {
              return IconButton(
                icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary, size: 22),
                onPressed: () => Navigator.pop(innerContext),
                tooltip: 'Back',
              );
            }
            return IconButton(
              icon: Icon(LucideIcons.menu, color: colors.textPrimary, size: 22),
              onPressed: () {
                final rootScaffold =
                    innerContext.findRootAncestorStateOfType<ScaffoldState>();
                if (rootScaffold != null && rootScaffold.hasDrawer) {
                  rootScaffold.openDrawer();
                } else {
                  Scaffold.of(innerContext).openDrawer();
                }
              },
              tooltip: 'Menu',
            );
          },
        ),
        title: Text(
          'Orders',
          style: AppTypography.h1(color: colors.textPrimary, weight: FontWeight.w700),
        ),
        actions: [
          // Sort toggle button (Newest / Oldest)
          InkWell(
            onTap: () => setState(() => _isSortNewestFirst = !_isSortNewestFirst),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.divider.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isSortNewestFirst ? LucideIcons.arrowDown : LucideIcons.arrowUp,
                    size: 13,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isSortNewestFirst ? 'Newest' : 'Oldest',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Date Filter Popup Menu
          PopupMenuButton<String>(
            icon: Icon(
              _selectedDateFilter != HistoryDateFilter.all || _customDateRange != null
                  ? LucideIcons.calendarCheck
                  : LucideIcons.calendar,
              color: _selectedDateFilter != HistoryDateFilter.all ||
                      _customDateRange != null
                  ? colors.primary
                  : colors.textPrimary,
              size: 20,
            ),
            tooltip: 'Filter by Date',
            color: colors.cardBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            onSelected: (val) {
              if (val == 'custom') {
                _pickCustomDateRange();
              } else {
                setState(() {
                  _customDateRange = null;
                  _selectedDateFilter = HistoryDateFilter.values
                      .firstWhere((e) => e.name == val);
                });
              }
            },
            itemBuilder: (ctx) => [
              _buildDateMenuItem('all', 'All Dates',
                  _selectedDateFilter == HistoryDateFilter.all && _customDateRange == null, colors),
              _buildDateMenuItem('lastDay', 'Last Day',
                  _selectedDateFilter == HistoryDateFilter.lastDay, colors),
              _buildDateMenuItem('lastWeek', 'Last Week',
                  _selectedDateFilter == HistoryDateFilter.lastWeek, colors),
              _buildDateMenuItem('lastMonth', 'Last Month',
                  _selectedDateFilter == HistoryDateFilter.lastMonth, colors),
              _buildDateMenuItem('custom',
                  _customDateRange != null
                      ? 'Custom Range (Active)'
                      : 'Custom Date Range...',
                  _customDateRange != null,
                  colors),
            ],
          ),

          // Reset all filters button if active
          if (_hasActiveFilters)
            IconButton(
              icon: Icon(LucideIcons.filterX,
                  color: colors.bearish, size: 20),
              tooltip: 'Reset Filters',
              onPressed: _resetFilters,
            ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.primary,
          indicatorWeight: 2.5,
          labelStyle: AppTypography.body(weight: FontWeight.w600),
          tabs: [
            Tab(text: 'Pending (${pendingOrders.length})'),
            Tab(text: 'Executed (${executedOrders.length})'),
            Tab(text: 'GTT (${filteredGtts.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Search Bar (Filter by Instrument) ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
            child: Container(
              height: 38,
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
                  hintText: 'Search orders by instrument or ID...',
                  hintStyle: AppTypography.caption(color: colors.textSecondary),
                  prefixIcon:
                      Icon(LucideIcons.search, color: colors.textSecondary, size: 16),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(LucideIcons.x,
                              color: colors.textSecondary, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),

          // ── Horizontal Filter Chips Strip ───────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                // Active Date Chip
                if (_selectedDateFilter != HistoryDateFilter.all ||
                    _customDateRange != null) ...[
                  _buildDateActiveChip(colors),
                  const SizedBox(width: 6),
                ],

                // Filter by Side
                _buildFilterChip(
                  label: 'All Sides',
                  isSelected: _selectedSide == null,
                  onTap: () => setState(() => _selectedSide = null),
                  colors: colors,
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  label: 'BUY',
                  isSelected: _selectedSide == TransactionType.BUY,
                  activeColor: colors.bullish,
                  onTap: () => setState(() => _selectedSide =
                      _selectedSide == TransactionType.BUY
                          ? null
                          : TransactionType.BUY),
                  colors: colors,
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  label: 'SELL',
                  isSelected: _selectedSide == TransactionType.SELL,
                  activeColor: colors.bearish,
                  onTap: () => setState(() => _selectedSide =
                      _selectedSide == TransactionType.SELL
                          ? null
                          : TransactionType.SELL),
                  colors: colors,
                ),

                // Separator
                Container(
                  height: 18,
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: colors.divider,
                ),

                // Status Chips per Tab
                if (_tabController.index == 0) ...[
                  _buildFilterChip(
                    label: 'All Status',
                    isSelected: _selectedStatus == null,
                    onTap: () => setState(() => _selectedStatus = null),
                    colors: colors,
                  ),
                  const SizedBox(width: 6),
                  _buildFilterChip(
                    label: 'Open',
                    isSelected: _selectedStatus == OrderStatus.OPEN,
                    activeColor: colors.warning,
                    onTap: () => setState(() => _selectedStatus =
                        _selectedStatus == OrderStatus.OPEN
                            ? null
                            : OrderStatus.OPEN),
                    colors: colors,
                  ),
                  const SizedBox(width: 6),
                  _buildFilterChip(
                    label: 'Trigger Pending',
                    isSelected: _selectedStatus == OrderStatus.TRIGGER_PENDING,
                    activeColor: colors.warning,
                    onTap: () => setState(() => _selectedStatus =
                        _selectedStatus == OrderStatus.TRIGGER_PENDING
                            ? null
                            : OrderStatus.TRIGGER_PENDING),
                    colors: colors,
                  ),
                  const SizedBox(width: 6),
                  _buildFilterChip(
                    label: 'Draft',
                    isSelected: _selectedStatus == OrderStatus.DRAFT,
                    activeColor: colors.textSecondary,
                    onTap: () => setState(() => _selectedStatus =
                        _selectedStatus == OrderStatus.DRAFT
                            ? null
                            : OrderStatus.DRAFT),
                    colors: colors,
                  ),
                  const SizedBox(width: 6),
                  _buildFilterChip(
                    label: 'Submitted',
                    isSelected: _selectedStatus == OrderStatus.SUBMITTED,
                    activeColor: colors.warning,
                    onTap: () => setState(() => _selectedStatus =
                        _selectedStatus == OrderStatus.SUBMITTED
                            ? null
                            : OrderStatus.SUBMITTED),
                    colors: colors,
                  ),
                ] else if (_tabController.index == 1) ...[
                  _buildFilterChip(
                    label: 'All Status',
                    isSelected: _selectedStatus == null,
                    onTap: () => setState(() => _selectedStatus = null),
                    colors: colors,
                  ),
                  const SizedBox(width: 6),
                  _buildFilterChip(
                    label: 'Completed',
                    isSelected: _selectedStatus == OrderStatus.COMPLETE,
                    activeColor: colors.bullish,
                    onTap: () => setState(() => _selectedStatus =
                        _selectedStatus == OrderStatus.COMPLETE
                            ? null
                            : OrderStatus.COMPLETE),
                    colors: colors,
                  ),
                  const SizedBox(width: 6),
                  _buildFilterChip(
                    label: 'Cancelled',
                    isSelected: _selectedStatus == OrderStatus.CANCELLED,
                    activeColor: colors.bearish,
                    onTap: () => setState(() => _selectedStatus =
                        _selectedStatus == OrderStatus.CANCELLED
                            ? null
                            : OrderStatus.CANCELLED),
                    colors: colors,
                  ),
                  const SizedBox(width: 6),
                  _buildFilterChip(
                    label: 'Rejected',
                    isSelected: _selectedStatus == OrderStatus.REJECTED,
                    activeColor: colors.bearish,
                    onTap: () => setState(() => _selectedStatus =
                        _selectedStatus == OrderStatus.REJECTED
                            ? null
                            : OrderStatus.REJECTED),
                    colors: colors,
                  ),
                  const SizedBox(width: 6),
                  _buildFilterChip(
                    label: 'Expired',
                    isSelected: _selectedStatus == OrderStatus.EXPIRED,
                    activeColor: colors.bearish,
                    onTap: () => setState(() => _selectedStatus =
                        _selectedStatus == OrderStatus.EXPIRED
                            ? null
                            : OrderStatus.EXPIRED),
                    colors: colors,
                  ),
                  const SizedBox(width: 6),
                  _buildFilterChip(
                    label: 'Failed',
                    isSelected: _selectedStatus == OrderStatus.FAILED,
                    activeColor: colors.bearish,
                    onTap: () => setState(() => _selectedStatus =
                        _selectedStatus == OrderStatus.FAILED
                            ? null
                            : OrderStatus.FAILED),
                    colors: colors,
                  ),
                ],

                if (_hasActiveFilters) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _resetFilters,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      child: Text(
                        'Clear',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Tab Bar Views ───────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPendingTab(pendingOrders, colors),
                _buildExecutedTab(executedOrders, colors),
                _buildGttTab(filteredGtts, colors),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => GttCreateSheet.show(context),
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Create GTT',
        child: const Icon(LucideIcons.alarmClockPlus, size: 22),
      ),
    );
  }

  PopupMenuItem<String> _buildDateMenuItem(
    String value,
    String label,
    bool isSelected,
    TradingColors colors,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? colors.primary : colors.textPrimary,
            ),
          ),
          if (isSelected)
            Icon(LucideIcons.check, size: 16, color: colors.primary),
        ],
      ),
    );
  }

  Widget _buildDateActiveChip(TradingColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.calendar, size: 12, color: colors.primary),
          const SizedBox(width: 4),
          Text(
            _getDateFilterLabel(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => setState(() {
              _selectedDateFilter = HistoryDateFilter.all;
              _customDateRange = null;
            }),
            child: Icon(LucideIcons.x, size: 12, color: colors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required TradingColors colors,
    Color? activeColor,
  }) {
    final effectiveActiveColor = activeColor ?? colors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? effectiveActiveColor.withValues(alpha: 0.15)
              : colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? effectiveActiveColor
                : colors.divider.withValues(alpha: 0.5),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? effectiveActiveColor : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildPendingTab(List<Order> orders, TradingColors colors) {
    if (orders.isEmpty) {
      if (_hasActiveFilters) {
        return EmptyStateView(
          icon: LucideIcons.filterX,
          title: 'No Matching Pending Orders',
          subtitle:
              'No orders match your active search, side, status, or date filters.',
          buttonText: 'Reset Filters',
          onButtonPressed: _resetFilters,
        );
      }
      return EmptyStateView(
        icon: LucideIcons.hourglass,
        title: 'No Pending Orders',
        subtitle:
            'You do not have any open or trigger-pending orders at the moment.',
        buttonText: 'Explore Market',
        onButtonPressed: () => context.go('/quotes'),
      );
    }

    return ListView.separated(
      itemCount: orders.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final order = orders[index];

        return ListTile(
          onTap: () => context.push('/order-detail/${order.orderId}'),
          title: Row(
            children: [
              TransactionSideBadge(side: order.request.side),
              const SizedBox(width: 8),
              Text(
                order.instrument.symbol,
                style: AppTypography.body(
                    color: colors.textPrimary, weight: FontWeight.w600),
              ),
              const SizedBox(width: 6),
              ExchangeChip(exchange: order.instrument.exchange),
            ],
          ),
          subtitle: Text(
            '${order.request.product.name} • ${order.request.kind.name} • ${DateFormatter.formatOrderTime(order.placedAt)}',
            style: AppTypography.caption(color: colors.textSecondary),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  order.status.name,
                  style: AppTypography.caption(
                      color: colors.warning, weight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                order.request.price != null
                    ? '₹${order.request.price} (Qty: ${order.request.quantity})'
                    : 'Market (Qty: ${order.request.quantity})',
                style: AppTypography.caption(
                    color: colors.textPrimary,
                    weight: FontWeight.w600,
                    tabular: true),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExecutedTab(List<Order> orders, TradingColors colors) {
    if (orders.isEmpty) {
      if (_hasActiveFilters) {
        return EmptyStateView(
          icon: LucideIcons.filterX,
          title: 'No Matching Executed Orders',
          subtitle:
              'No orders match your active search, side, status, or date filters.',
          buttonText: 'Reset Filters',
          onButtonPressed: _resetFilters,
        );
      }
      return EmptyStateView(
        icon: LucideIcons.receipt,
        title: 'No Executed Orders',
        subtitle: 'Placed orders will appear here once executed or cancelled.',
        buttonText: 'Place an Order',
        onButtonPressed: () => context.go('/quotes'),
      );
    }

    return ListView.separated(
      itemCount: orders.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final order = orders[index];
        final isComplete = order.status == OrderStatus.COMPLETE;
        final isCancelled = order.status == OrderStatus.CANCELLED ||
            order.status == OrderStatus.REJECTED ||
            order.status == OrderStatus.EXPIRED ||
            order.status == OrderStatus.FAILED;

        final badgeColor = isComplete
            ? colors.bullish
            : isCancelled
                ? colors.bearish
                : colors.warning;

        return ListTile(
          onTap: () => context.push('/order-detail/${order.orderId}'),
          title: Row(
            children: [
              TransactionSideBadge(side: order.request.side),
              const SizedBox(width: 8),
              Text(
                order.instrument.symbol,
                style: AppTypography.body(
                    color: colors.textPrimary, weight: FontWeight.w600),
              ),
              const SizedBox(width: 6),
              ExchangeChip(exchange: order.instrument.exchange),
            ],
          ),
          subtitle: Text(
            '${order.request.product.name} • ${DateFormatter.formatOrderTime(order.placedAt)}',
            style: AppTypography.caption(color: colors.textSecondary),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  order.status.name,
                  style: AppTypography.labelSmall(
                    color: badgeColor,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${order.filledQty}/${order.request.quantity} @ ${CurrencyFormatter.format(order.averagePrice)}',
                style: AppTypography.caption(
                    color: colors.textPrimary,
                    weight: FontWeight.w600,
                    tabular: true),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGttTab(List<GttOrder> gtts, TradingColors colors) {
    if (gtts.isEmpty) {
      if (_hasActiveFilters) {
        return EmptyStateView(
          icon: LucideIcons.filterX,
          title: 'No Matching GTT Orders',
          subtitle:
              'No GTT orders match your search or side filter criteria.',
          buttonText: 'Reset Filters',
          onButtonPressed: _resetFilters,
        );
      }
      return EmptyStateView(
        icon: LucideIcons.alarmClock,
        title: 'No Active GTTs',
        subtitle:
            'Create Good-Till-Triggered orders to automate stoploss and target entries.',
        buttonText: 'Create GTT',
        onButtonPressed: () => GttCreateSheet.show(context),
      );
    }

    return ListView.separated(
      itemCount: gtts.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final gtt = gtts[index];

        return ListTile(
          title: Row(
            children: [
              TransactionSideBadge(side: gtt.request.side),
              const SizedBox(width: 8),
              Text(
                gtt.instrument.symbol,
                style: AppTypography.body(
                    color: colors.textPrimary, weight: FontWeight.w600),
              ),
            ],
          ),
          subtitle: Text(
            'Trigger: ₹${gtt.request.triggerPrice} • Limit: ₹${gtt.request.orderPrice} (Qty: ${gtt.request.quantity})',
            style: AppTypography.caption(color: colors.textSecondary),
          ),
          trailing: IconButton(
            icon: const Icon(LucideIcons.trash2, size: 18),
            onPressed: () =>
                ref.read(orderSimulationEngineProvider).deleteGtt(gtt.id),
          ),
        );
      },
    );
  }
}
