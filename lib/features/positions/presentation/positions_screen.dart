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
import '../../../shared_widgets/price_text.dart';
import '../../../shared_widgets/section_card.dart';
import '../../order_entry/presentation/order_entry_sheet.dart';

class PositionsScreen extends ConsumerStatefulWidget {
  const PositionsScreen({super.key});

  @override
  ConsumerState<PositionsScreen> createState() => _PositionsScreenState();
}

class _PositionsScreenState extends ConsumerState<PositionsScreen> {
  bool _isDayView = true;

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final engine = ref.watch(orderSimulationEngineProvider);
    final tickerService = ref.watch(tickerServiceProvider);
    
    final positionsAsync = ref.watch(positionsListProvider);
    final allPositions = positionsAsync.value ?? engine.positions;

    final filteredPositions = _isDayView
        ? allPositions.where((p) => p.isDayPosition).toList()
        : allPositions;

    // Compute live P&L
    double totalPnl = 0.0;
    for (final pos in filteredPositions) {
      final quote = tickerService.getQuote(pos.instrument.token);
      final currentPrice = quote.ltp;
      final unrealized = pos.netQty * (currentPrice - (pos.buyAvg > 0 ? pos.buyAvg : pos.sellAvg));
      totalPnl += pos.realizedPnl + unrealized;
    }

    final pnlColor = totalPnl >= 0 ? colors.bullish : colors.bearish;

    return Scaffold(
      appBar: AppBar(
        title: Text('Positions', style: AppTypography.h1(color: colors.textPrimary, weight: FontWeight.w700)),
        actions: [
          // Day vs Net Toggle Chip
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ChoiceChip(
              label: Text(_isDayView ? 'Day View' : 'Net View', style: AppTypography.labelSmall(weight: FontWeight.w600)),
              selected: true,
              selectedColor: colors.surface,
              onSelected: (_) => setState(() => _isDayView = !_isDayView),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Header Card
          SectionCard(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total P&L', style: AppTypography.caption(color: colors.textSecondary, weight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.formatSigned(totalPnl),
                      style: AppTypography.h1(color: pnlColor, weight: FontWeight.w700, tabular: true),
                    ),
                  ],
                ),
                Text(
                  '${filteredPositions.length} Open Positions',
                  style: AppTypography.caption(color: colors.textSecondary),
                ),
              ],
            ),
          ),

          // Positions List
          Expanded(
            child: filteredPositions.isEmpty
                ? EmptyStateView(
                    icon: Icons.layers_outlined,
                    title: 'No Open Positions',
                    subtitle: 'You do not have any active intraday or F&O positions for today.',
                    buttonText: 'Trade Now',
                    onButtonPressed: () => context.go('/watchlist'),
                  )
                : ListView.separated(
                    itemCount: filteredPositions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final pos = filteredPositions[index];
                      final quote = tickerService.getQuote(pos.instrument.token);
                      final currentPrice = quote.ltp;
                      final unrealized = pos.netQty * (currentPrice - (pos.buyAvg > 0 ? pos.buyAvg : pos.sellAvg));
                      final itemPnl = pos.realizedPnl + unrealized;
                      final itemPnlColor = itemPnl >= 0 ? colors.bullish : colors.bearish;

                      return ListTile(
                        onTap: () => _showPositionActions(context, pos, currentPrice),
                        title: Row(
                          children: [
                            Text(
                              pos.instrument.symbol,
                              style: AppTypography.body(color: colors.textPrimary, weight: FontWeight.w600),
                            ),
                            const SizedBox(width: 6),
                            ExchangeChip(exchange: pos.instrument.exchange, type: pos.instrument.type),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                pos.product.name,
                                style: AppTypography.labelSmall(color: colors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          'Qty: ${pos.netQty} • Avg: ${CurrencyFormatter.format(pos.buyAvg > 0 ? pos.buyAvg : pos.sellAvg)}',
                          style: AppTypography.caption(color: colors.textSecondary, tabular: true),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyFormatter.formatSigned(itemPnl),
                              style: AppTypography.body(color: itemPnlColor, weight: FontWeight.w700, tabular: true),
                            ),
                            const SizedBox(height: 2),
                            PriceText(
                              value: currentPrice,
                              change: quote.change,
                              style: AppTypography.caption(tabular: true),
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

  void _showPositionActions(BuildContext context, Position pos, double currentPrice) {
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
            Text(pos.instrument.symbol, style: AppTypography.h1(color: colors.textPrimary)),
            Text('${pos.product.name} • Net Qty: ${pos.netQty}', style: AppTypography.caption(color: colors.textSecondary)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Exit position by placing opposite side market order
                      final exitSide = pos.netQty > 0 ? TransactionType.SELL : TransactionType.BUY;
                      OrderEntrySheet.show(
                        context,
                        instrument: pos.instrument,
                        side: exitSide,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.bearish,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('EXIT POSITION', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      OrderEntrySheet.show(
                        context,
                        instrument: pos.instrument,
                        side: TransactionType.BUY,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.bullish,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('ADD MORE', style: TextStyle(fontWeight: FontWeight.bold)),
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
                context.push('/chart-fullscreen/${pos.instrument.token}');
              },
            ),
          ],
        ),
      ),
    );
  }
}
