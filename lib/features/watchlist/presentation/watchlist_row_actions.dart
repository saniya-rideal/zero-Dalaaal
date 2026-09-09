import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/shared_widgets.dart';

class WatchlistRowActions extends StatelessWidget {
  final Instrument instrument;
  final Quote quote;
  final VoidCallback onBuy;
  final VoidCallback onSell;
  final VoidCallback onRemove;

  const WatchlistRowActions({
    super.key,
    required this.instrument,
    required this.quote,
    required this.onBuy,
    required this.onSell,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const ZeroDragHandle(padding: EdgeInsets.zero),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instrument.symbol,
                      style: AppTypography.h2(color: colors.textPrimary, weight: FontWeight.w700),
                    ),
                    Text(
                      '${instrument.exchange.name} • ${instrument.name}',
                      style: AppTypography.caption(color: colors.textSecondary),
                    ),
                  ],
                ),
                Text(
                  '₹${quote.ltp.toStringAsFixed(2)}',
                  style: AppTypography.h2(color: colors.textPrimary, weight: FontWeight.w700, tabular: true),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Buy / Sell Big Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onBuy();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.bullish,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('BUY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onSell();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.bearish,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('SELL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),

          // Actions List
          ListTile(
            leading: Icon(LucideIcons.lineChart, color: colors.textPrimary, size: 20),
            title: Text('View Chart', style: AppTypography.body(color: colors.textPrimary, weight: FontWeight.w500)),
            onTap: () {
              Navigator.pop(context);
              context.push('/chart-fullscreen/${instrument.token}');
            },
          ),
          ListTile(
            leading: Icon(LucideIcons.bell, color: colors.textPrimary, size: 20),
            title: Text('Set Alert', style: AppTypography.body(color: colors.textPrimary, weight: FontWeight.w500)),
            onTap: () {
              Navigator.pop(context);
              context.push('/alerts');
            },
          ),
          ListTile(
            leading: Icon(LucideIcons.shoppingBag, color: colors.textPrimary, size: 20),
            title: Text('Add to Basket', style: AppTypography.body(color: colors.textPrimary, weight: FontWeight.w500)),
            onTap: () {
              Navigator.pop(context);
              context.push('/baskets');
            },
          ),
          if (instrument.type != InstrumentType.INDEX)
            ListTile(
              leading: Icon(LucideIcons.info, color: colors.textPrimary, size: 20),
              title: Text('Fundamentals & Technicals', style: AppTypography.body(color: colors.textPrimary, weight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                context.push('/quote/${instrument.token}');
              },
            ),
          ListTile(
            leading: Icon(LucideIcons.trash2, color: colors.bearish, size: 20),
            title: Text('Remove from Watchlist', style: AppTypography.body(color: colors.bearish, weight: FontWeight.w500)),
            onTap: () {
              Navigator.pop(context);
              onRemove();
            },
          ),
        ],
      ),
    );
  }
}
