import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/mock/order_simulation_engine.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/empty_state_view.dart';
import '../../../shared_widgets/exchange_chip.dart';
import '../../order_entry/presentation/gtt_create_sheet.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final engine = ref.watch(orderSimulationEngineProvider);
    
    // Watch orders stream
    final ordersAsync = ref.watch(ordersListProvider);
    final allOrders = ordersAsync.value ?? engine.orders;
    
    final pendingOrders = allOrders.where((o) => o.status == OrderStatus.OPEN || o.status == OrderStatus.TRIGGER_PENDING).toList();
    final executedOrders = allOrders.where((o) => o.status != OrderStatus.OPEN && o.status != OrderStatus.TRIGGER_PENDING).toList();
    
    final gttAsync = ref.watch(gttsListProvider);
    final gtts = gttAsync.value ?? engine.gtts;

    return Scaffold(
      appBar: AppBar(
        title: Text('Orders', style: AppTypography.h1(color: colors.textPrimary, weight: FontWeight.w700)),
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
            Tab(text: 'GTT (${gtts.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pending Orders Tab
          _buildPendingTab(pendingOrders, colors),

          // Executed Orders Tab
          _buildExecutedTab(executedOrders, colors),

          // GTT Tab
          _buildGttTab(gtts, colors),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => GttCreateSheet.show(context),
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Create GTT',
        child: const Icon(Icons.add_alarm),
      ),
    );
  }

  Widget _buildPendingTab(List<Order> orders, TradingColors colors) {
    if (orders.isEmpty) {
      return EmptyStateView(
        icon: Icons.hourglass_empty,
        title: 'No Pending Orders',
        subtitle: 'You do not have any open or trigger-pending orders at the moment.',
        buttonText: 'Explore Market',
        onButtonPressed: () => context.go('/watchlist'),
      );
    }

    return ListView.separated(
      itemCount: orders.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final order = orders[index];
        final isBuy = order.request.side == TransactionType.BUY;

        return ListTile(
          onTap: () => context.push('/order-detail/${order.orderId}'),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isBuy ? colors.bullish : colors.bearish,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  order.request.side.name,
                  style: AppTypography.labelSmall(color: Colors.white, weight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                order.instrument.symbol,
                style: AppTypography.body(color: colors.textPrimary, weight: FontWeight.w600),
              ),
              const SizedBox(width: 6),
              ExchangeChip(exchange: order.instrument.exchange),
            ],
          ),
          subtitle: Text(
            '${order.request.product.name} • ${order.request.kind.name} • Qty: ${order.request.quantity}',
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
                  style: AppTypography.caption(color: colors.warning, weight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                order.request.price != null ? '₹${order.request.price}' : 'Market',
                style: AppTypography.caption(color: colors.textPrimary, weight: FontWeight.w600, tabular: true),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExecutedTab(List<Order> orders, TradingColors colors) {
    if (orders.isEmpty) {
      return EmptyStateView(
        icon: Icons.receipt_long_outlined,
        title: 'No Executed Orders',
        subtitle: 'Placed orders will appear here once executed or cancelled.',
        buttonText: 'Place an Order',
        onButtonPressed: () => context.go('/watchlist'),
      );
    }

    return ListView.separated(
      itemCount: orders.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final order = orders[index];
        final isBuy = order.request.side == TransactionType.BUY;
        final isComplete = order.status == OrderStatus.COMPLETE;

        return ListTile(
          onTap: () => context.push('/order-detail/${order.orderId}'),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isBuy ? colors.bullish : colors.bearish,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  order.request.side.name,
                  style: AppTypography.labelSmall(color: Colors.white, weight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                order.instrument.symbol,
                style: AppTypography.body(color: colors.textPrimary, weight: FontWeight.w600),
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
                  color: (isComplete ? colors.bullish : colors.bearish).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  order.status.name,
                  style: AppTypography.labelSmall(
                    color: isComplete ? colors.bullish : colors.bearish,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${order.filledQty}/${order.request.quantity} @ ${CurrencyFormatter.format(order.averagePrice)}',
                style: AppTypography.caption(color: colors.textPrimary, weight: FontWeight.w600, tabular: true),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGttTab(List<GttOrder> gtts, TradingColors colors) {
    if (gtts.isEmpty) {
      return EmptyStateView(
        icon: Icons.alarm_outlined,
        title: 'No Active GTTs',
        subtitle: 'Create Good-Till-Triggered orders to automate stoploss and target entries.',
        buttonText: 'Create GTT',
        onButtonPressed: () => GttCreateSheet.show(context),
      );
    }

    return ListView.separated(
      itemCount: gtts.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final gtt = gtts[index];
        final isBuy = gtt.request.side == TransactionType.BUY;

        return ListTile(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isBuy ? colors.bullish : colors.bearish,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  gtt.request.side.name,
                  style: AppTypography.labelSmall(color: Colors.white, weight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                gtt.instrument.symbol,
                style: AppTypography.body(color: colors.textPrimary, weight: FontWeight.w600),
              ),
            ],
          ),
          subtitle: Text(
            'Trigger: ₹${gtt.request.triggerPrice} • Limit: ₹${gtt.request.orderPrice} (Qty: ${gtt.request.quantity})',
            style: AppTypography.caption(color: colors.textSecondary),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => ref.read(orderSimulationEngineProvider).deleteGtt(gtt.id),
          ),
        );
      },
    );
  }
}
