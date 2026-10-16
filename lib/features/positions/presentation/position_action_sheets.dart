import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/models.dart';
import '../../orders/domain/trading_repository.dart';

class PositionActionSheets {
  /// Primary options bottom sheet when tapping a position tile
  static void showFullOptions(
    BuildContext context,
    Position pos,
    TradingRepository repo, {
    VoidCallback? onRefresh,
  }) {
    final colors = context.tradingColors;
    final timeStr = DateFormat('hh:mm:ss a').format(pos.openTime);

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: Symbol, Side badge, P&L value and %
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (pos.isLong ? colors.bullish : colors.bearish).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            pos.isLong ? 'LONG' : 'SHORT',
                            style: GoogleFonts.inter(
                              color: pos.isLong ? colors.bullish : colors.bearish,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          pos.instrument.symbol,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      CurrencyFormatter.formatSigned(pos.unrealizedPnl, showSymbol: true),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: pos.unrealizedPnl >= 0 ? colors.bullish : colors.bearish,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Position Metrics Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetricCol('Net Qty', '${pos.netQty.abs()} Lots', colors),
                        _buildMetricCol('Avg Buy', '₹${pos.entryPrice.toStringAsFixed(2)}', colors),
                        _buildMetricCol('LTP', '₹${pos.ltp.toStringAsFixed(2)}', colors, isHighlighted: true),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetricCol(
                          'Product',
                          pos.product.name,
                          colors,
                        ),
                        _buildMetricCol('Opened At', timeStr, colors),
                        _buildMetricCol(
                          'Exchange',
                          pos.instrument.exchange.name,
                          colors,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              Divider(height: 1, color: colors.divider),

              // Action 1: Product Conversion (MIS <-> CNC)
              ListTile(
                leading: Icon(LucideIcons.repeat, color: colors.primary, size: 20),
                title: Text(
                  pos.product == ProductType.MIS ? 'Convert to Delivery (CNC)' : 'Convert to Intraday (MIS)',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: colors.textPrimary),
                ),
                subtitle: Text(
                  'Change position product type per contract rules',
                  style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final target = pos.product == ProductType.MIS ? 'CNC' : 'MIS';
                  try {
                    await repo.convertPosition(pos.id, targetProduct: target);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Position converted to $target successfully')),
                      );
                      onRefresh?.call();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Conversion failed: $e')),
                      );
                    }
                  }
                },
              ),

              // Action 2: Partial Close / Scale Out
              ListTile(
                leading: const Icon(LucideIcons.gitFork, color: Color(0xFFF57C00), size: 20),
                title: Text('Partial Close / Scale Out',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: colors.textPrimary)),
                subtitle: Text('Close a portion of position lots',
                    style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary)),
                onTap: () {
                  Navigator.pop(context);
                  showPartialClose(context, pos, repo, onRefresh: onRefresh);
                },
              ),

              // Action 3: Full Square Off / Exit Position
              ListTile(
                leading: Icon(LucideIcons.minimize2, color: colors.bearish, size: 20),
                title: Text('Full Close Position (Square Off)',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: colors.bearish)),
                subtitle: Text('Exit all ${pos.netQty.abs()} lots at market price',
                    style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary)),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Square Off Position?'),
                      content: Text(
                          'Are you sure you want to exit ${pos.netQty.abs()} lots of ${pos.instrument.symbol} at current market LTP (₹${pos.ltp.toStringAsFixed(2)})?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: colors.bearish, foregroundColor: Colors.white),
                          child: const Text('Confirm Exit'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    try {
                      await repo.closePosition(pos.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Position ${pos.instrument.symbol} squared off successfully'),
                            backgroundColor: colors.bearish,
                          ),
                        );
                        onRefresh?.call();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to close position: $e')),
                        );
                      }
                    }
                  }
                },
              ),

              // Action 4: Open Fullscreen Chart
              ListTile(
                leading: const Icon(LucideIcons.candlestickChart, color: Color(0xFF1E88E5), size: 20),
                title: Text('Open Fullscreen Chart',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: colors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/chart-fullscreen/${pos.instrument.token}');
                },
              ),

              // Action 5: View Script Specifications
              ListTile(
                leading: Icon(LucideIcons.info, color: colors.textSecondary, size: 20),
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

  /// Partial Close Sheet
  static void showPartialClose(
    BuildContext context,
    Position pos,
    TradingRepository repo, {
    VoidCallback? onRefresh,
  }) {
    final colors = context.tradingColors;
    final totalQty = pos.netQty.abs();
    int closeQty = (totalQty / 2).ceil().clamp(1, totalQty);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) {
          final remainingQty = totalQty - closeQty;
          final estimatedPnl = (pos.ltp - pos.entryPrice) * closeQty * (pos.isLong ? 1 : -1);

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Partial Close / Scale Out',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.x, color: colors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Text(
                  '${pos.instrument.symbol} • Open: $totalQty lots @ ${CurrencyFormatter.format(pos.entryPrice)}',
                  style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary),
                ),
                const SizedBox(height: 16),

                // Quick Percentage Presets (25%, 50%, 75%, 100%)
                Row(
                  children: [0.25, 0.50, 0.75, 1.0].map((pct) {
                    final presetQty = (totalQty * pct).round().clamp(1, totalQty);
                    final isSelected = closeQty == presetQty;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: InkWell(
                          onTap: () => setStateModal(() => closeQty = presetQty),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? colors.primary.withValues(alpha: 0.15) : colors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? colors.primary : colors.divider,
                                width: isSelected ? 1.5 : 0.8,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${(pct * 100).toInt()}%',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? colors.primary : colors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Quantity Counter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.divider.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Lots to close:', style: AppTypography.body(color: colors.textPrimary, weight: FontWeight.w600)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.minusCircle, size: 22),
                            color: colors.primary,
                            onPressed: closeQty > 1 ? () => setStateModal(() => closeQty--) : null,
                          ),
                          Text(
                            '$closeQty',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.plusCircle, size: 22),
                            color: colors.primary,
                            onPressed: closeQty < totalQty ? () => setStateModal(() => closeQty++) : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Calculation Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.divider.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Est. Realized P&L:', style: AppTypography.caption(color: colors.textSecondary)),
                          Text(
                            CurrencyFormatter.formatSigned(estimatedPnl, showSymbol: true),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: estimatedPnl >= 0 ? colors.bullish : colors.bearish,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Remaining Position:', style: AppTypography.caption(color: colors.textSecondary)),
                          Text(
                            '$remainingQty lots',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Close Button
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      await repo.closePosition(pos.id, quantity: closeQty);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Closed $closeQty lots of ${pos.instrument.symbol}'),
                            backgroundColor: colors.primary,
                          ),
                        );
                        onRefresh?.call();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to close position: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.bearish,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    closeQty == totalQty
                        ? 'Close All $closeQty Lots'
                        : 'Close $closeQty Lots ($remainingQty Remaining)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget _buildMetricCol(
    String label,
    String value,
    TradingColors colors, {
    bool isHighlighted = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10.5, color: colors.textSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
            color: isHighlighted ? colors.primary : colors.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
