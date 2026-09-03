import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/mock/order_simulation_engine.dart';
import '../../../data/mock/ticker_service.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/empty_state_view.dart';
import '../../../shared_widgets/exchange_chip.dart';
import '../../../shared_widgets/section_card.dart';
import '../../order_entry/presentation/order_entry_sheet.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.tradingColors;
    final engine = ref.watch(orderSimulationEngineProvider);
    final tickerService = ref.watch(tickerServiceProvider);

    final holdingsAsync = ref.watch(holdingsListProvider);
    final holdings = holdingsAsync.value ?? engine.holdings;

    // Recalculate summary live
    final updatedHoldings = holdings.map((h) {
      final quote = tickerService.getQuote(h.instrument.token);
      return h.copyWith(ltp: quote.ltp);
    }).toList();

    final summary = PortfolioSummary.fromHoldings(updatedHoldings);
    final totalPnlColor = summary.totalPnl >= 0 ? colors.bullish : colors.bearish;
    final todayPnlColor = summary.todayPnl >= 0 ? colors.bullish : colors.bearish;

    return Scaffold(
      appBar: AppBar(
        title: Text('Holdings (${holdings.length})', style: AppTypography.h1(color: colors.textPrimary, weight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => context.push('/reports'),
            tooltip: 'Tax & Analytics',
          ),
        ],
      ),
      body: Column(
        children: [
          // Portfolio Summary Card
          SectionCard(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Invested', style: AppTypography.caption(color: colors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.format(summary.totalInvestment),
                          style: AppTypography.h2(color: colors.textPrimary, weight: FontWeight.w700, tabular: true),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Current Value', style: AppTypography.caption(color: colors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.format(summary.currentValue),
                          style: AppTypography.h2(color: colors.textPrimary, weight: FontWeight.w700, tabular: true),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total P&L', style: AppTypography.caption(color: colors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          '${CurrencyFormatter.formatSigned(summary.totalPnl)} (${CurrencyFormatter.formatPercent(summary.totalPnlPercent)})',
                          style: AppTypography.body(color: totalPnlColor, weight: FontWeight.w700, tabular: true),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("Today's P&L", style: AppTypography.caption(color: colors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          '${CurrencyFormatter.formatSigned(summary.todayPnl)} (${CurrencyFormatter.formatPercent(summary.todayPnlPercent)})',
                          style: AppTypography.body(color: todayPnlColor, weight: FontWeight.w700, tabular: true),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Mock Corporate Action Banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.campaign_outlined, color: colors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'INFY: Dividend of ₹18.00 per share announced (Ex-Date: 12 Sep)',
                    style: AppTypography.caption(color: colors.primary, weight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // Holdings List
          Expanded(
            child: updatedHoldings.isEmpty
                ? EmptyStateView(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'No Holdings in Demat',
                    subtitle: 'Buy stocks with CNC product type to build your long-term wealth portfolio.',
                    buttonText: 'Start Investing',
                    onButtonPressed: () => context.go('/watchlist'),
                  )
                : ListView.separated(
                    itemCount: updatedHoldings.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final holding = updatedHoldings[index];
                      final pnlColor = holding.totalPnl >= 0 ? colors.bullish : colors.bearish;

                      return ListTile(
                        onTap: () => _showHoldingActions(context, holding),
                        title: Row(
                          children: [
                            Text(
                              holding.instrument.symbol,
                              style: AppTypography.body(color: colors.textPrimary, weight: FontWeight.w600),
                            ),
                            const SizedBox(width: 6),
                            ExchangeChip(exchange: holding.instrument.exchange),
                          ],
                        ),
                        subtitle: Text(
                          'Qty: ${holding.totalQuantity} • Avg: ${CurrencyFormatter.format(holding.averagePrice)} • Inv: ${CurrencyFormatter.formatCompact(holding.investedValue)}',
                          style: AppTypography.caption(color: colors.textSecondary, tabular: true),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyFormatter.formatSigned(holding.totalPnl),
                              style: AppTypography.body(color: pnlColor, weight: FontWeight.w700, tabular: true),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '(${CurrencyFormatter.formatPercent(holding.totalPnlPercent)})',
                              style: AppTypography.caption(color: pnlColor, weight: FontWeight.w600, tabular: true),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showHoldingActions(BuildContext context, Holding holding) {
    final colors = context.tradingColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(holding.instrument.symbol, style: AppTypography.h1(color: colors.textPrimary)),
            Text('${holding.totalQuantity} Shares • Held for ${holding.daysHeld} days', style: AppTypography.caption(color: colors.textSecondary)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      OrderEntrySheet.show(
                        context,
                        instrument: holding.instrument,
                        side: TransactionType.SELL,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.bearish,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('SELL / EXIT', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      OrderEntrySheet.show(
                        context,
                        instrument: holding.instrument,
                        side: TransactionType.BUY,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.bullish,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('BUY MORE', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.show_chart),
              title: const Text('View Chart'),
              onTap: () {
                Navigator.pop(context);
                context.push('/chart-fullscreen/${holding.instrument.token}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('View Fundamentals & Analytics'),
              onTap: () {
                Navigator.pop(context);
                context.push('/quote/${holding.instrument.token}');
              },
            ),
          ],
        ),
      ),
    );
  }
}
