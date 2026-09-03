import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/trading_colors.dart';
import '../core/theme/typography.dart';
import '../core/utils/currency_formatter.dart';
import '../data/models/quote.dart';

class DepthLadder extends StatelessWidget {
  final MarketDepth depth;

  const DepthLadder({
    super.key,
    required this.depth,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;

    int maxQty = 1;
    for (final b in depth.buy) {
      maxQty = max(maxQty, b.qty);
    }
    for (final s in depth.sell) {
      maxQty = max(maxQty, s.qty);
    }

    final totalBuy = depth.totalBuyQty;
    final totalSell = depth.totalSellQty;
    final totalAll = max(1, totalBuy + totalSell);
    final buyRatio = (totalBuy / totalAll).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Table Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Text('BID', style: AppTypography.caption(color: colors.textSecondary, weight: FontWeight.w600)),
              ),
              Expanded(
                flex: 1,
                child: Text('ORDERS', textAlign: TextAlign.center, style: AppTypography.caption(color: colors.textSecondary)),
              ),
              Expanded(
                flex: 1,
                child: Text('QTY', textAlign: TextAlign.right, style: AppTypography.caption(color: colors.textSecondary)),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: Text('OFFER', style: AppTypography.caption(color: colors.textSecondary, weight: FontWeight.w600)),
              ),
              Expanded(
                flex: 1,
                child: Text('ORDERS', textAlign: TextAlign.center, style: AppTypography.caption(color: colors.textSecondary)),
              ),
              Expanded(
                flex: 1,
                child: Text('QTY', textAlign: TextAlign.right, style: AppTypography.caption(color: colors.textSecondary)),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // 5 Rows
        ...List.generate(5, (index) {
          final buyLevel = index < depth.buy.length ? depth.buy[index] : const DepthLevel(price: 0, qty: 0, orders: 0);
          final sellLevel = index < depth.sell.length ? depth.sell[index] : const DepthLevel(price: 0, qty: 0, orders: 0);

          final buyFraction = (buyLevel.qty / maxQty).clamp(0.0, 1.0);
          final sellFraction = (sellLevel.qty / maxQty).clamp(0.0, 1.0);

          return Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Buy Side (Left)
                Expanded(
                  flex: 3,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Buy depth fill bar
                      FractionallySizedBox(
                        widthFactor: buyFraction,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colors.bullish.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Text(
                              CurrencyFormatter.format(buyLevel.price, showSymbol: false),
                              style: AppTypography.caption(color: colors.bullish, weight: FontWeight.w600, tabular: true),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              '${buyLevel.orders}',
                              textAlign: TextAlign.center,
                              style: AppTypography.caption(color: colors.textSecondary, tabular: true),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              '${buyLevel.qty}',
                              textAlign: TextAlign.right,
                              style: AppTypography.caption(color: colors.textPrimary, tabular: true),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Sell Side (Right)
                Expanded(
                  flex: 3,
                  child: Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      // Sell depth fill bar
                      FractionallySizedBox(
                        widthFactor: sellFraction,
                        alignment: Alignment.centerRight,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colors.bearish.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Text(
                              CurrencyFormatter.format(sellLevel.price, showSymbol: false),
                              style: AppTypography.caption(color: colors.bearish, weight: FontWeight.w600, tabular: true),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              '${sellLevel.orders}',
                              textAlign: TextAlign.center,
                              style: AppTypography.caption(color: colors.textSecondary, tabular: true),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              '${sellLevel.qty}',
                              textAlign: TextAlign.right,
                              style: AppTypography.caption(color: colors.textPrimary, tabular: true),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),

        const Divider(height: 1),

        // Total Buy / Sell Summary Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Buy: $totalBuy',
                    style: AppTypography.caption(color: colors.bullish, weight: FontWeight.w600, tabular: true),
                  ),
                  Text(
                    'Total Sell: $totalSell',
                    style: AppTypography.caption(color: colors.bearish, weight: FontWeight.w600, tabular: true),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(
                  height: 4,
                  child: Row(
                    children: [
                      Expanded(
                        flex: (buyRatio * 100).toInt(),
                        child: Container(color: colors.bullish),
                      ),
                      Expanded(
                        flex: ((1.0 - buyRatio) * 100).toInt(),
                        child: Container(color: colors.bearish),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
