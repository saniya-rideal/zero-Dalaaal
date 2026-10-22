import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../funds/data/real_funds_repository.dart';
import '../../orders/data/real_trading_repository.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/zero_app_bar.dart';
import '../../../shared_widgets/zero_drawer.dart';
import 'statement_view_dialog.dart';
import 'transaction_detail_sheet.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  late ScrollController _transactionsScrollController;

  HistoryDateFilter _selectedDateFilter = HistoryDateFilter.all;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  bool _isSortAscending = true;

  // Pagination state
  final List<TransactionRecord> _loadedTransactions = [];
  bool _hasMore = true;
  bool _isLoadingMore = false;

  final List<String> _subTabs = ['TRANSACTIONS', 'CLASSIC', 'POSITIONS', 'ORDERS', 'DEALS'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _subTabs.length, vsync: this);
    _transactionsScrollController = ScrollController()..addListener(_onTransactionsScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _resetAndLoadTransactions());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _transactionsScrollController.dispose();
    super.dispose();
  }

  void _onTransactionsScroll() {
    if (_transactionsScrollController.position.pixels >=
        _transactionsScrollController.position.maxScrollExtent - 200) {
      if (_hasMore && !_isLoadingMore) {
        _loadNextPage();
      }
    }
  }

  Future<void> _resetAndLoadTransactions() async {
    try {
      final ledger = await ref.read(fundsRepositoryProvider).getLedger();
      final records = ledger.map((e) => TransactionRecord(
        id: e.id,
        category: e.credit > 0 ? TransactionCategory.DEPOSIT : TransactionCategory.TRANSFER,
        title: e.narration.isNotEmpty ? e.narration : 'Ledger Entry',
        narration: e.narration,
        amount: e.credit > 0 ? e.credit : e.debit,
        isCredit: e.credit > 0,
        runningBalance: e.runningBalance,
        timestamp: e.date,
        status: 'COMPLETED',
        account: 'Trading Ledger',
      )).toList();

      if (mounted) {
        setState(() {
          _loadedTransactions.clear();
          _loadedTransactions.addAll(records);
          _hasMore = false;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasMore = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadNextPage() async {}

  Future<void> _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : DateTimeRange(start: DateTime.now().subtract(const Duration(days: 30)), end: DateTime.now()),
    );
    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _selectedDateFilter = HistoryDateFilter.custom;
      });
      _resetAndLoadTransactions();
    }
  }

  void _applyPresetDateFilter(HistoryDateFilter filter) {
    final now = DateTime.now();
    setState(() {
      _selectedDateFilter = filter;
      if (filter == HistoryDateFilter.lastDay) {
        _customStartDate = DateTime(now.year, now.month, now.day);
        _customEndDate = now;
      } else if (filter == HistoryDateFilter.lastWeek) {
        _customStartDate = now.subtract(const Duration(days: 7));
        _customEndDate = now;
      } else if (filter == HistoryDateFilter.lastMonth) {
        _customStartDate = now.subtract(const Duration(days: 30));
        _customEndDate = now;
      } else if (filter == HistoryDateFilter.custom) {
        _pickCustomDateRange();
        return;
      } else if (filter == HistoryDateFilter.all) {
        _customStartDate = null;
        _customEndDate = null;
      }
    });
    _resetAndLoadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final ordersAsync = ref.watch(ordersListProvider);
    final positionsAsync = ref.watch(positionsListProvider);
    final fundsAsync = ref.watch(fundsSummaryProvider);

    final allOrders = ordersAsync.valueOrNull ?? [];
    final allPositions = positionsAsync.valueOrNull ?? [];
    final funds = fundsAsync.valueOrNull ?? const FundsSummary(
      availableMargin: 0,
      usedMargin: 0,
      openingBalance: 0,
      payin: 0,
      payout: 0,
      spanMargin: 0,
      exposureMargin: 0,
      unrealizedPnl: 0,
    );

    var executedOrders = List<Order>.from(
        allOrders.where((o) => o.status == OrderStatus.COMPLETE));
    var closedPositions = List<Position>.from(allPositions);

    // Apply Legacy Sub-tab Date Filter
    final now = DateTime.now();
    if (_selectedDateFilter == HistoryDateFilter.lastDay) {
      executedOrders = executedOrders
          .where((o) =>
              o.placedAt.year == now.year &&
              o.placedAt.month == now.month &&
              o.placedAt.day == now.day)
          .toList();
    } else if (_selectedDateFilter == HistoryDateFilter.lastWeek) {
      final weekAgo = now.subtract(const Duration(days: 7));
      executedOrders =
          executedOrders.where((o) => o.placedAt.isAfter(weekAgo)).toList();
    } else if (_selectedDateFilter == HistoryDateFilter.lastMonth) {
      final monthAgo = now.subtract(const Duration(days: 30));
      executedOrders =
          executedOrders.where((o) => o.placedAt.isAfter(monthAgo)).toList();
    }

    // Apply Search Filter for Legacy tabs
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      executedOrders = executedOrders
          .where((o) =>
              o.instrument.symbol.toLowerCase().contains(query) ||
              o.orderId.toLowerCase().contains(query))
          .toList();
      closedPositions = closedPositions
          .where((p) =>
              p.instrument.symbol.toLowerCase().contains(query) ||
              p.id.toLowerCase().contains(query))
          .toList();
    }

    // Apply Legacy Sorting
    executedOrders.sort((a, b) => _isSortAscending
        ? a.instrument.symbol.compareTo(b.instrument.symbol)
        : b.instrument.symbol.compareTo(a.instrument.symbol));
    closedPositions.sort((a, b) => _isSortAscending
        ? a.instrument.symbol.compareTo(b.instrument.symbol)
        : b.instrument.symbol.compareTo(a.instrument.symbol));

    // Dynamic Realized Metrics
    final totalRealizedProfit = closedPositions.fold<double>(
        0.0, (sum, p) => sum + p.realizedPnl);
    final totalDeposit = funds.payin > 0 ? funds.payin : 500000.00;
    final totalWithdrawal = funds.payout;
    final totalCommission = closedPositions.length * 20.0;

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const ZeroDrawer(activeRoute: '/history'),
      appBar: ZeroAppBar(
        title: 'History & Reports',
        showFilterAction: false,
        showSortAction: true,
        showCalendarAction: true,
        isSortAscending: _isSortAscending,
        onSortTap: () {
          setState(() {
            _isSortAscending = !_isSortAscending;
          });
          _resetAndLoadTransactions();
        },
        selectedDateFilter: _selectedDateFilter,
        onDateFilterSelected: _applyPresetDateFilter,
        trailingAction: IconButton(
          icon: Icon(LucideIcons.fileText, color: colors.textPrimary, size: 20),
          tooltip: 'Account Statement',
          onPressed: () => StatementViewDialog.show(
            context,
            startDate: _customStartDate,
            endDate: _customEndDate,
          ),
        ),
      ),
      body: Column(
        children: [
          // Universal Search Bar
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
                  hintText: 'Search by symbol, narration, order ID, or txn ID',
                  hintStyle: AppTypography.body(color: colors.textSecondary),
                  prefixIcon: Icon(LucideIcons.search, color: colors.textSecondary, size: 18),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(LucideIcons.x, color: colors.textSecondary, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            _resetAndLoadTransactions();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onChanged: (_) => _resetAndLoadTransactions(),
              ),
            ),
          ),

          // Sub Tabs Strip with Dot Indicator
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colors.background,
              border: Border(
                bottom: BorderSide(
                  color: colors.divider.withValues(alpha: 0.4),
                  width: 0.5,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: colors.primary,
              unselectedLabelColor: colors.textSecondary,
              indicator: DotTabIndicator(color: colors.primary, radius: 2.5),
              labelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                letterSpacing: 0.3,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                letterSpacing: 0.3,
              ),
              tabs: _subTabs.map((title) => Tab(text: title)).toList(),
            ),
          ),

          // Sub Tabs Body
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTransactionsView(colors),
                _buildClassicView(
                  colors,
                  profit: totalRealizedProfit,
                  deposit: totalDeposit,
                  withdrawal: totalWithdrawal,
                  commission: totalCommission,
                ),
                _buildPositionsView(
                  closedPositions,
                  colors,
                  profit: totalRealizedProfit,
                  deposit: totalDeposit,
                  withdrawal: totalWithdrawal,
                  commission: totalCommission,
                ),
                _buildOrdersView(
                  executedOrders,
                  colors,
                  profit: totalRealizedProfit,
                  deposit: totalDeposit,
                  withdrawal: totalWithdrawal,
                  commission: totalCommission,
                ),
                _buildDealsView(
                  executedOrders,
                  colors,
                  profit: totalRealizedProfit,
                  deposit: totalDeposit,
                  withdrawal: totalWithdrawal,
                  commission: totalCommission,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Unified Transactions Tab View (with Pagination) ───────
  Widget _buildTransactionsView(TradingColors colors) {
    return Column(
      children: [
        // Infinite Scroll / Paginated List

        // Infinite Scroll / Paginated List
        Expanded(
          child: _loadedTransactions.isEmpty
              ? _buildEmptyState('No transactions match the selected filters.', colors)
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  controller: _transactionsScrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _loadedTransactions.length + 1,
                  itemBuilder: (context, index) {
                    if (index < _loadedTransactions.length) {
                      final txn = _loadedTransactions[index];
                      return _buildUnifiedTransactionTile(txn, colors);
                    }

                    // Bottom Pagination / Infinite Scroll Loading / Finished indicator
                    if (_isLoadingMore) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Loading more records...',
                                style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: Text(
                          _hasMore
                              ? 'Scroll down to load more records'
                              : 'All ${_loadedTransactions.length} records loaded (End of Statement)',
                          style: GoogleFonts.inter(
                            color: colors.textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildUnifiedTransactionTile(TransactionRecord txn, TradingColors colors) {
    final isCredit = txn.isCredit;
    final amtColor = isCredit ? colors.bullish : colors.bearish;

    IconData catIcon;
    switch (txn.category) {
      case TransactionCategory.TRADE:
        catIcon = LucideIcons.candlestickChart;
        break;
      case TransactionCategory.DEPOSIT:
        catIcon = LucideIcons.arrowDownLeft;
        break;
      case TransactionCategory.WITHDRAWAL:
        catIcon = LucideIcons.arrowUpRight;
        break;
      case TransactionCategory.FEE_CHARGE:
        catIcon = LucideIcons.receipt;
        break;
      case TransactionCategory.DIVIDEND:
        catIcon = LucideIcons.sparkles;
        break;
      case TransactionCategory.TRANSFER:
        catIcon = LucideIcons.arrowLeftRight;
        break;
    }

    Color badgeBg;
    Color badgeText;
    switch (txn.status.toUpperCase()) {
      case 'COMPLETE':
      case 'SUCCESS':
      case 'COMPLETED':
        badgeBg = colors.bullish.withValues(alpha: 0.1);
        badgeText = colors.bullish;
        break;
      case 'PENDING':
      case 'INITIATED':
        badgeBg = colors.warning.withValues(alpha: 0.1);
        badgeText = colors.warning;
        break;
      case 'FAILED':
      case 'REJECTED':
        badgeBg = colors.bearish.withValues(alpha: 0.1);
        badgeText = colors.bearish;
        break;
      case 'CANCELLED':
      default:
        badgeBg = colors.divider.withValues(alpha: 0.3);
        badgeText = colors.textSecondary;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: colors.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colors.divider.withValues(alpha: 0.6), width: 0.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => TransactionDetailSheet.show(context, txn),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isCredit ? colors.bullish : colors.primary).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(catIcon, color: isCredit ? colors.bullish : colors.primary, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            txn.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            txn.status,
                            style: GoogleFonts.inter(
                              color: badgeText,
                              fontWeight: FontWeight.w700,
                              fontSize: 9.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${txn.id} • ${DateFormatter.formatOrderDateTime(txn.timestamp)}',
                      style: GoogleFonts.inter(
                        color: colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isCredit ? '+' : '-'}${CurrencyFormatter.format(txn.amount)}',
                    style: GoogleFonts.inter(
                      color: amtColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bal: ${CurrencyFormatter.format(txn.runningBalance)}',
                    style: GoogleFonts.inter(
                      color: colors.textSecondary,
                      fontSize: 10.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Reusable Summary Metrics Block (Profit, Credit, Deposit, Withdrawal, Adjustment, Commission)
  Widget _buildSummaryBlock(TradingColors colors,
      {double profit = 0.00,
      double deposit = 500000.00,
      double withdrawal = 0.00,
      double commission = 0.00}) {
    final rows = [
      {'label': 'Profit', 'val': profit, 'isProfit': true},
      {'label': 'Credit', 'val': 0.00, 'isProfit': false},
      {'label': 'Deposit', 'val': deposit, 'isProfit': false},
      {'label': 'Withdrawal', 'val': withdrawal, 'isProfit': false},
      {'label': 'Adjustment', 'val': 0.00, 'isProfit': false},
      {'label': 'Commission', 'val': commission, 'isProfit': false},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.divider, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: rows.map((item) {
          final label = item['label'] as String;
          final val = item['val'] as double;
          final isProfit = item['isProfit'] as bool;

          Color valColor = colors.textPrimary;
          if (isProfit && val != 0.0) {
            valColor = val >= 0 ? colors.bullish : colors.bearish;
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(val, showSymbol: false),
                  style: TextStyle(
                    color: valColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildClassicView(TradingColors colors,
      {required double profit,
      required double deposit,
      required double withdrawal,
      required double commission}) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 10),
      children: [
        _buildSummaryBlock(colors,
            profit: profit,
            deposit: deposit,
            withdrawal: withdrawal,
            commission: commission),
      ],
    );
  }

  Widget _buildPositionsView(List<Position> positions, TradingColors colors,
      {required double profit,
      required double deposit,
      required double withdrawal,
      required double commission}) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 10),
      children: [
        _buildSummaryBlock(colors,
            profit: profit,
            deposit: deposit,
            withdrawal: withdrawal,
            commission: commission),
        if (positions.isEmpty)
          _buildEmptyState('No Closed Positions', colors)
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('CLOSED POSITIONS',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: colors.textSecondary)),
          ),
          ...positions.map((pos) => Material(
                color: Colors.transparent,
                child: ListTile(
                  onTap: () => _showPositionDetailsSheet(context, pos, colors),
                  title: Text(
                    pos.instrument.symbol,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    'Qty: ${pos.netQty} • Avg: ${pos.buyAvg.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        CurrencyFormatter.formatSigned(pos.unrealizedPnl,
                            showSymbol: true),
                        style: TextStyle(
                          color: pos.unrealizedPnl >= 0
                              ? colors.bullish
                              : colors.bearish,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(LucideIcons.chevronRight,
                          color: colors.textSecondary, size: 18),
                    ],
                  ),
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildOrdersView(List<Order> orders, TradingColors colors,
      {required double profit,
      required double deposit,
      required double withdrawal,
      required double commission}) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 10),
      children: [
        _buildSummaryBlock(colors,
            profit: profit,
            deposit: deposit,
            withdrawal: withdrawal,
            commission: commission),
        if (orders.isEmpty)
          _buildEmptyState('No Executed Orders', colors)
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('EXECUTED ORDERS',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: colors.textSecondary)),
          ),
          ...orders.map((order) => Material(
                color: Colors.transparent,
                child: ListTile(
                  onTap: () => _showOrderDetailsSheet(context, order, colors),
                  title: Text(
                    order.instrument.symbol,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    '${order.request.side.name} • ${order.request.quantity} Qty • ${DateFormatter.formatOrderTime(order.placedAt)}',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.format(order.averagePrice),
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.status.name,
                            style: TextStyle(
                              color: colors.bullish,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
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
              )),
        ],
      ],
    );
  }

  Widget _buildDealsView(List<Order> orders, TradingColors colors,
      {required double profit,
      required double deposit,
      required double withdrawal,
      required double commission}) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 10),
      children: [
        _buildSummaryBlock(colors,
            profit: profit,
            deposit: deposit,
            withdrawal: withdrawal,
            commission: commission),
        if (orders.isEmpty)
          _buildEmptyState('No Deal Records', colors)
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('SETTLED DEALS',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: colors.textSecondary)),
          ),
          ...orders.map((deal) => Material(
                color: Colors.transparent,
                child: ListTile(
                  onTap: () => _showOrderDetailsSheet(context, deal, colors),
                  title: Text(
                    deal.instrument.symbol,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    'ID: #${deal.orderId} • ${DateFormatter.formatOrderDateTime(deal.placedAt)}',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        CurrencyFormatter.format(deal.averagePrice),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(LucideIcons.chevronRight,
                          color: colors.textSecondary, size: 18),
                    ],
                  ),
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildEmptyState(String message, TradingColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(LucideIcons.history, size: 36, color: colors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.inter(
                color: colors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showOrderDetailsSheet(
      BuildContext context, Order order, TradingColors colors) {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.instrument.symbol,
                    style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.bullish.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      order.status.name,
                      style: GoogleFonts.inter(
                          color: colors.bullish,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: colors.divider),
              const SizedBox(height: 10),
              _buildDetailRow('Order ID', '#${order.orderId}', colors),
              _buildDetailRow('Side', order.request.side.name, colors),
              _buildDetailRow('Executed Price',
                  CurrencyFormatter.format(order.averagePrice), colors),
              _buildDetailRow('Quantity', '${order.request.quantity} Lots', colors),
              _buildDetailRow(
                  'Placed At',
                  DateFormatter.formatOrderDateTime(order.placedAt),
                  colors),
              _buildDetailRow('Brokerage', '₹0.00 (Zero)', colors),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPositionDetailsSheet(
      BuildContext context, Position pos, TradingColors colors) {
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
              Row(
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
                    CurrencyFormatter.formatSigned(pos.unrealizedPnl,
                        showSymbol: true),
                    style: GoogleFonts.inter(
                      color: pos.unrealizedPnl >= 0
                          ? colors.bullish
                          : colors.bearish,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: colors.divider),
              const SizedBox(height: 10),
              _buildDetailRow('Position ID', '#${pos.id}', colors),
              _buildDetailRow('Net Quantity', '${pos.netQty} Lots', colors),
              _buildDetailRow('Buy Avg Price',
                  CurrencyFormatter.format(pos.buyAvg), colors),
              _buildDetailRow('Sell Avg Price',
                  CurrencyFormatter.format(pos.sellAvg), colors),
              _buildDetailRow('Realized P&L',
                  CurrencyFormatter.formatSigned(pos.realizedPnl), colors),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String val, TradingColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  color: colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          Text(val,
              style: GoogleFonts.inter(
                  color: colors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}

class DotTabIndicator extends Decoration {
  final Color color;
  final double radius;

  const DotTabIndicator({required this.color, this.radius = 2.5});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _DotPainter(color: color, radius: radius);
}

class _DotPainter extends BoxPainter {
  final Color color;
  final double radius;

  _DotPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Paint paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    final Offset circleOffset = offset +
        Offset(configuration.size!.width / 2,
            configuration.size!.height - radius - 2);
    canvas.drawCircle(circleOffset, radius, paint);
  }
}
