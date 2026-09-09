import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme/trading_colors.dart';
import '../core/theme/typography.dart';
import '../core/utils/currency_formatter.dart';
import '../data/models/instrument.dart';
import '../data/models/quote.dart';
import 'exchange_chip.dart';
import 'price_text.dart';

class InstrumentRow extends StatelessWidget {
  final Instrument instrument;
  final Quote quote;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onBuy;
  final VoidCallback? onSell;
  final bool enableSwipeActions;

  const InstrumentRow({
    super.key,
    required this.instrument,
    required this.quote,
    this.onTap,
    this.onLongPress,
    this.onBuy,
    this.onSell,
    this.enableSwipeActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;

    final changeColor = quote.change > 0
        ? colors.bullish
        : (quote.change < 0 ? colors.bearish : colors.neutral);

    final Widget content = InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // Left block: Symbol + Name + Exchange Chip
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          instrument.symbol,
                          style: AppTypography.body(
                            color: colors.textPrimary,
                            weight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ExchangeChip(
                        exchange: instrument.exchange,
                        type: instrument.type,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    instrument.name,
                    style: AppTypography.caption(
                      color: colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Right block: LTP + Day Change (₹ and %)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                PriceText(
                  value: quote.ltp,
                  change: quote.change,
                  style: AppTypography.body(
                    weight: FontWeight.w600,
                    tabular: true,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      CurrencyFormatter.formatSigned(quote.change, showSymbol: false),
                      style: AppTypography.caption(
                        color: changeColor,
                        weight: FontWeight.w500,
                        tabular: true,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${CurrencyFormatter.formatPercent(quote.changePercent)})',
                      style: AppTypography.caption(
                        color: changeColor,
                        weight: FontWeight.w500,
                        tabular: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (!enableSwipeActions) return content;

    return Dismissible(
      key: Key('instrument_${instrument.token}'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onBuy?.call();
        } else if (direction == DismissDirection.endToStart) {
          onSell?.call();
        }
        return false; // Don't actually dismiss the row, just trigger quick buy/sell
      },
      background: Container(
        color: colors.bullish,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Row(
          children: [
            Icon(LucideIcons.shoppingBag, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text('BUY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: colors.bearish,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('SELL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(width: 8),
            Icon(LucideIcons.tag, color: Colors.white, size: 22),
          ],
        ),
      ),
      child: content,
    );
  }
}
