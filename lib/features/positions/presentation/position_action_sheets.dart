import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/mock/order_simulation_engine.dart';
import '../../../data/models/models.dart';

class PositionActionSheets {
  /// Primary options bottom sheet when tapping a position tile
  static void showFullOptions(
    BuildContext context,
    Position pos,
    OrderSimulationEngine engine, {
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (pos.isLong ? colors.bullish : colors.bearish)
                                .withValues(alpha: 0.15),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.formatSigned(pos.unrealizedPnl,
                              showSymbol: true),
                          style: GoogleFonts.inter(
                            color: pos.unrealizedPnl >= 0
                                ? colors.bullish
                                : colors.bearish,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          '${pos.pnlPercent >= 0 ? '+' : ''}${pos.pnlPercent.toStringAsFixed(2)}%',
                          style: GoogleFonts.inter(
                            color: pos.pnlPercent >= 0
                                ? colors.bullish
                                : colors.bearish,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Metrics Grid: Qty, Entry, LTP, Exposure, Margin, Leverage, Open time
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: colors.divider.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetricCol('Quantity', '${pos.netQty.abs()} lots',
                            colors),
                        _buildMetricCol('Entry Price',
                            CurrencyFormatter.format(pos.entryPrice), colors),
                        _buildMetricCol(
                            'Current LTP',
                            CurrencyFormatter.format(pos.ltp),
                            colors,
                            isHighlighted: true),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetricCol('Exposure',
                            CurrencyFormatter.format(pos.exposure), colors),
                        _buildMetricCol('Used Margin',
                            CurrencyFormatter.format(pos.usedMargin), colors),
                        _buildMetricCol(
                            'Leverage', '${pos.leverage.toInt()}x', colors),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetricCol(
                          'Stop-Loss',
                          pos.stopLoss != null
                              ? '₹${pos.stopLoss!.toStringAsFixed(2)}'
                              : 'Not set',
                          colors,
                        ),
                        _buildMetricCol(
                          'Take-Profit',
                          pos.takeProfit != null
                              ? '₹${pos.takeProfit!.toStringAsFixed(2)}'
                              : 'Not set',
                          colors,
                        ),
                        _buildMetricCol('Opened At', timeStr, colors),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              Divider(height: 1, color: colors.divider),

              // Action 1: Modify SL / TP
              ListTile(
                leading: Icon(Icons.shield_outlined, color: colors.primary),
                title: Text('Modify Stop-Loss / Take-Profit',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, color: colors.textPrimary)),
                subtitle: Text('Set protective SL or target TP order thresholds',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: colors.textSecondary)),
                onTap: () {
                  Navigator.pop(context);
                  showModifySlTp(context, pos, engine);
                },
              ),

              // Action 2: Partial Close / Scale Out
              ListTile(
                leading:
                    const Icon(Icons.call_split_outlined, color: Color(0xFFF57C00)),
                title: Text('Partial Close / Scale Out',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, color: colors.textPrimary)),
                subtitle: Text('Close 25%, 50%, 75% or custom portion of lots',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: colors.textSecondary)),
                onTap: () {
                  Navigator.pop(context);
                  showPartialClose(context, pos, engine);
                },
              ),

              // Action 3: Full Square Off / Exit Position
              ListTile(
                leading: Icon(Icons.close_fullscreen, color: colors.bearish),
                title: Text('Full Close Position (Square Off)',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, color: colors.bearish)),
                subtitle: Text('Exit all ${pos.netQty.abs()} lots at market LTP',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: colors.textSecondary)),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm Square Off'),
                      content: Text(
                        'Square off full position of ${pos.netQty.abs()} lots of ${pos.instrument.symbol} at market price?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: colors.bearish),
                          child: const Text('Confirm Square Off',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    await engine.closePosition(pos.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Position for ${pos.instrument.symbol} squared off successfully'),
                        backgroundColor: colors.primary,
                      ),
                    );
                    onRefresh?.call();
                  }
                },
              ),

              // Action 4: Open Fullscreen Chart
              ListTile(
                leading: const Icon(Icons.candlestick_chart,
                    color: Color(0xFF1E88E5)),
                title: Text('Open Fullscreen Chart',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, color: colors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/chart-fullscreen/${pos.instrument.token}');
                },
              ),

              // Action 5: View Script Specifications
              ListTile(
                leading: Icon(Icons.info_outline, color: colors.textSecondary),
                title: Text('View Script Specifications',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, color: colors.textPrimary)),
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

  /// Modify Stop-Loss and Take-Profit Sheet
  static void showModifySlTp(
    BuildContext context,
    Position pos,
    OrderSimulationEngine engine,
  ) {
    final colors = context.tradingColors;
    final slController = TextEditingController(
      text: pos.stopLoss != null ? pos.stopLoss!.toStringAsFixed(2) : '',
    );
    final tpController = TextEditingController(
      text: pos.takeProfit != null ? pos.takeProfit!.toStringAsFixed(2) : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) {
          final slVal = double.tryParse(slController.text.trim());
          final tpVal = double.tryParse(tpController.text.trim());

          // Estimate risk / reward
          double? estimatedRisk;
          if (slVal != null && slVal > 0) {
            estimatedRisk = (slVal - pos.entryPrice) *
                pos.netQty.abs() *
                (pos.isLong ? 1 : -1);
          }
          double? estimatedReward;
          if (tpVal != null && tpVal > 0) {
            estimatedReward = (tpVal - pos.entryPrice) *
                pos.netQty.abs() *
                (pos.isLong ? 1 : -1);
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 16,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Modify SL / TP',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: colors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Text(
                  '${pos.instrument.symbol} (${pos.isLong ? 'LONG' : 'SHORT'}) • Entry: ₹${pos.entryPrice.toStringAsFixed(2)} • LTP: ₹${pos.ltp.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                // Stop-Loss Field
                Text('Stop-Loss Trigger (₹)',
                    style: AppTypography.caption(
                        color: colors.textPrimary, weight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: slController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: AppTypography.body(color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: pos.isLong
                        ? 'e.g. ${(pos.entryPrice * 0.98).toStringAsFixed(2)} (Below entry)'
                        : 'e.g. ${(pos.entryPrice * 1.02).toStringAsFixed(2)} (Above entry)',
                    hintStyle:
                        AppTypography.caption(color: colors.textSecondary),
                    prefixIcon:
                        Icon(Icons.shield, color: colors.bearish, size: 18),
                    suffixIcon: slController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              slController.clear();
                              setStateModal(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  onChanged: (_) => setStateModal(() {}),
                ),
                if (estimatedRisk != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      'Est. Max Loss: ${CurrencyFormatter.formatSigned(estimatedRisk)}',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: estimatedRisk < 0 ? colors.bearish : colors.bullish,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                const SizedBox(height: 14),

                // Take-Profit Field
                Text('Take-Profit Trigger (₹)',
                    style: AppTypography.caption(
                        color: colors.textPrimary, weight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: tpController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: AppTypography.body(color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: pos.isLong
                        ? 'e.g. ${(pos.entryPrice * 1.05).toStringAsFixed(2)} (Above entry)'
                        : 'e.g. ${(pos.entryPrice * 0.95).toStringAsFixed(2)} (Below entry)',
                    hintStyle:
                        AppTypography.caption(color: colors.textSecondary),
                    prefixIcon:
                        Icon(Icons.flag, color: colors.bullish, size: 18),
                    suffixIcon: tpController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              tpController.clear();
                              setStateModal(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  onChanged: (_) => setStateModal(() {}),
                ),
                if (estimatedReward != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      'Est. Max Gain: ${CurrencyFormatter.formatSigned(estimatedReward)}',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: estimatedReward >= 0
                            ? colors.bullish
                            : colors.bearish,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          engine.modifyPositionSlTp(pos.id,
                              stopLoss: null, takeProfit: null);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('SL & TP removed')),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.textSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Clear All'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          engine.modifyPositionSlTp(
                            pos.id,
                            stopLoss: slVal,
                            takeProfit: tpVal,
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'SL/TP updated for ${pos.instrument.symbol}'),
                              backgroundColor: colors.primary,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Save SL / TP',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Partial Close Sheet
  static void showPartialClose(
    BuildContext context,
    Position pos,
    OrderSimulationEngine engine,
  ) {
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
          final estimatedPnl = (pos.ltp - pos.entryPrice) *
              closeQty *
              (pos.isLong ? 1 : -1);

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
                      icon: Icon(Icons.close, color: colors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Text(
                  '${pos.instrument.symbol} • Open: $totalQty lots @ ${CurrencyFormatter.format(pos.entryPrice)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
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
                          onTap: () {
                            setStateModal(() => closeQty = presetQty);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colors.primary.withValues(alpha: 0.15)
                                  : colors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? colors.primary
                                    : colors.divider,
                                width: isSelected ? 1.5 : 0.8,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${(pct * 100).toInt()}%',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? colors.primary
                                      : colors.textPrimary,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: colors.divider.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Lots to close:',
                          style: AppTypography.body(
                              color: colors.textPrimary,
                              weight: FontWeight.w600)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            color: colors.primary,
                            onPressed: closeQty > 1
                                ? () => setStateModal(() => closeQty--)
                                : null,
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
                            icon: const Icon(Icons.add_circle_outline),
                            color: colors.primary,
                            onPressed: closeQty < totalQty
                                ? () => setStateModal(() => closeQty++)
                                : null,
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
                    border: Border.all(
                        color: colors.divider.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Est. Realized P&L for this close:',
                              style: AppTypography.caption(
                                  color: colors.textSecondary)),
                          Text(
                            CurrencyFormatter.formatSigned(estimatedPnl,
                                showSymbol: true),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: estimatedPnl >= 0
                                  ? colors.bullish
                                  : colors.bearish,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Remaining Position after close:',
                              style: AppTypography.caption(
                                  color: colors.textSecondary)),
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
                    await engine.closePosition(pos.id, quantity: closeQty);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Closed $closeQty lots of ${pos.instrument.symbol}'),
                        backgroundColor: colors.primary,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.bearish,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
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
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10.5, color: colors.textSecondary)),
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
