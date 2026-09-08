import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/mock/order_simulation_engine.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/exchange_chip.dart';
import '../../../shared_widgets/section_card.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.tradingColors;
    final engine = ref.watch(orderSimulationEngineProvider);
    final Order? order = engine.orders.where((o) => o.orderId == orderId).firstOrNull;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Order Details', style: AppTypography.h1(color: colors.textPrimary)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: colors.textSecondary.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text(
                  'Order Not Found',
                  style: AppTypography.h2(color: colors.textPrimary, weight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Order #$orderId could not be located. It may have expired, been cancelled, or removed during session refresh.',
                  style: AppTypography.body(color: colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      context.go('/orders');
                    }
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Return to Order Book'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isBuy = order.request.side == TransactionType.BUY;
    final statusColor = switch (order.status) {
      OrderStatus.COMPLETE                  => colors.bullish,
      OrderStatus.CANCELLED                 => colors.bearish,
      OrderStatus.REJECTED                  => colors.bearish,
      OrderStatus.EXPIRED                   => colors.bearish,
      OrderStatus.FAILED                    => colors.bearish,
      OrderStatus.PARTIALLY_FILLED          => colors.warning,
      OrderStatus.DRAFT                     => colors.textSecondary,
      OrderStatus.SUBMITTED                 => colors.warning,
      OrderStatus.OPEN                      => colors.warning,
      OrderStatus.TRIGGER_PENDING           => colors.warning,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details', style: AppTypography.h1(color: colors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isBuy ? colors.bullish : colors.bearish,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              order.request.side.name,
                              style: AppTypography.caption(color: Colors.white, weight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            order.instrument.symbol,
                            style: AppTypography.h2(color: colors.textPrimary, weight: FontWeight.w700),
                          ),
                          const SizedBox(width: 6),
                          ExchangeChip(exchange: order.instrument.exchange, type: order.instrument.type),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          order.status.name,
                          style: AppTypography.caption(color: statusColor, weight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryItem('Qty', '${order.filledQty} / ${order.request.quantity}', colors),
                      _buildSummaryItem('Avg Price', CurrencyFormatter.format(order.averagePrice), colors),
                      _buildSummaryItem('Product', order.request.product.name, colors),
                      _buildSummaryItem('Type', order.request.kind.name, colors),
                    ],
                  ),
                ],
              ),
            ),

            // Order Lifecycle Timeline
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order Lifecycle', style: AppTypography.h2(color: colors.textPrimary)),
                  const SizedBox(height: 16),
                  ...order.timeline.map((event) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.primary,
                              ),
                            ),
                            Container(width: 2, height: 32, color: colors.divider),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.status.name,
                                style: AppTypography.body(color: colors.textPrimary, weight: FontWeight.w600),
                              ),
                              Text(
                                event.description,
                                style: AppTypography.caption(color: colors.textSecondary),
                              ),
                              Text(
                                DateFormatter.formatOrderTime(event.at),
                                style: AppTypography.labelSmall(color: colors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),

            // Zerodha-style Charges Breakdown Card (₹0 Brokerage Highlight)
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Charges Breakdown', style: AppTypography.h2(color: colors.textPrimary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.bullish.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '₹0 Brokerage',
                          style: AppTypography.caption(color: colors.bullish, weight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildChargeItem('Brokerage (Zero)', order.charges.brokerage, colors, isZeroHighlight: true),
                  _buildChargeItem('Securities Transaction Tax (STT)', order.charges.stt, colors),
                  _buildChargeItem('Exchange Transaction Charge', order.charges.exchangeTxnCharge, colors),
                  _buildChargeItem('GST (18%)', order.charges.gst, colors),
                  _buildChargeItem('SEBI Turnover Charges', order.charges.sebiCharges, colors),
                  _buildChargeItem('Stamp Duty', order.charges.stampDuty, colors),
                  const Divider(height: 16),
                  _buildChargeItem('Total Taxes & Charges', order.charges.total, colors, isBold: true),
                ],
              ),
            ),

            // Metadata Card
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order Info', style: AppTypography.h2(color: colors.textPrimary)),
                  const SizedBox(height: 12),
                  _buildInfoRow('Order ID', order.orderId, colors),
                  _buildInfoRow('Exchange Order ID', order.exchangeOrderId, colors),
                  _buildInfoRow('Placed At', DateFormatter.formatOrderDateTime(order.placedAt), colors),
                  _buildInfoRow('Validity', order.request.validity.name, colors),
                ],
              ),
            ),

            // Cancel / Modify buttons (only for cancellable/modifiable states)
            if (order.status == OrderStatus.OPEN || order.status == OrderStatus.TRIGGER_PENDING) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('CANCEL ORDER', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Confirm Cancellation'),
                        content: Text(
                          'Are you sure you want to cancel order ${order.orderId}?\n\n'
                          'This action cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('No, Keep Order'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(backgroundColor: colors.bearish),
                            child: const Text('Yes, Cancel Order', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      await engine.cancelOrder(order.orderId);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.bearish,
                    side: BorderSide(color: colors.bearish),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 0),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String val, TradingColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption(color: colors.textSecondary)),
        const SizedBox(height: 2),
        Text(val, style: AppTypography.body(color: colors.textPrimary, weight: FontWeight.w600, tabular: true)),
      ],
    );
  }

  Widget _buildChargeItem(String label, double amount, TradingColors colors, {bool isZeroHighlight = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: isBold ? AppTypography.body(color: colors.textPrimary, weight: FontWeight.w700) : AppTypography.caption(color: colors.textSecondary)),
          Text(
            isZeroHighlight && amount == 0 ? '₹0.00' : CurrencyFormatter.format(amount),
            style: isBold
                ? AppTypography.body(color: colors.textPrimary, weight: FontWeight.w700, tabular: true)
                : AppTypography.caption(color: isZeroHighlight ? colors.bullish : colors.textPrimary, weight: FontWeight.w600, tabular: true),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, TradingColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.caption(color: colors.textSecondary)),
          Text(value, style: AppTypography.caption(color: colors.textPrimary, weight: FontWeight.w600, tabular: true)),
        ],
      ),
    );
  }
}
