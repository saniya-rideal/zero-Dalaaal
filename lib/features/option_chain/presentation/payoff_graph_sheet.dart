import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/option_strategy.dart';
import '../../../shared_widgets/shared_widgets.dart';
import 'widgets/payoff_chart.dart';

/// A modal bottom sheet that shows an interactive 2D option strategy payoff graph.
///
/// Displays:
/// - Strategy name + underlying + expiry header
/// - [PayoffChart] canvas (P&L curve vs spot price)
/// - Metrics row: Max Profit, Max Loss, Breakeven(s), Risk:Reward
/// - Per-leg breakdown table
///
/// Usage:
/// ```dart
/// PayoffGraphSheet.show(context, strategy: myStrategy);
/// ```
class PayoffGraphSheet extends StatefulWidget {
  final OptionStrategy strategy;

  const PayoffGraphSheet({super.key, required this.strategy});

  /// Show the payoff graph sheet for [strategy].
  static Future<void> show(BuildContext context,
      {required OptionStrategy strategy}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PayoffGraphSheet(strategy: strategy),
    );
  }

  @override
  State<PayoffGraphSheet> createState() => _PayoffGraphSheetState();
}

class _PayoffGraphSheetState extends State<PayoffGraphSheet> {
  late List<PayoffPoint> _points;
  late StrategyMetrics _metrics;
  int _selectedStrategyIndex = 0;

  late List<OptionStrategy> _presets;

  @override
  void initState() {
    super.initState();
    final spot = widget.strategy.spotPrice;
    final underlying = widget.strategy.underlying;
    final expiry = widget.strategy.expiry;

    // Build preset list (active strategy first, then others)
    _presets = [
      widget.strategy,
      if (widget.strategy.name != 'Bull Call Spread')
        StrategyPayoffEngine.bullCallSpread(
            underlying: underlying, spot: spot, expiry: expiry),
      if (widget.strategy.name != 'Bear Put Spread')
        StrategyPayoffEngine.bearPutSpread(
            underlying: underlying, spot: spot, expiry: expiry),
      if (widget.strategy.name != 'Long Straddle')
        StrategyPayoffEngine.longStraddle(
            underlying: underlying, spot: spot, expiry: expiry),
      if (widget.strategy.name != 'Iron Condor')
        StrategyPayoffEngine.ironCondor(
            underlying: underlying, spot: spot, expiry: expiry),
    ];

    _computePayoff();
  }

  void _computePayoff() {
    final strategy = _presets[_selectedStrategyIndex];
    _points = StrategyPayoffEngine.computePayoff(strategy);
    _metrics = StrategyPayoffEngine.computeMetrics(strategy, _points);
  }

  OptionStrategy get _activeStrategy => _presets[_selectedStrategyIndex];

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenH * 0.92),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const ZeroDragHandle(),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.chartLine,
                          size: 14, color: colors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Strategy Payoff',
                        style: GoogleFonts.inter(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(LucideIcons.x,
                      size: 18, color: colors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  const SizedBox(height: 4),

          // Strategy name + expiry
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _activeStrategy.name,
                      style: GoogleFonts.inter(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18),
                    ),
                    Text(
                      '${_activeStrategy.underlying} • Exp: ${_activeStrategy.expiry}',
                      style: GoogleFonts.inter(
                          color: colors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                // Net cost pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _activeStrategy.netCost > 0
                        ? colors.bearish.withValues(alpha: 0.12)
                        : colors.bullish.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _activeStrategy.netCost > 0
                        ? '−₹${_activeStrategy.netCost.toStringAsFixed(0)} Debit'
                        : '+₹${_activeStrategy.netCost.abs().toStringAsFixed(0)} Credit',
                    style: GoogleFonts.inter(
                      color: _activeStrategy.netCost > 0
                          ? colors.bearish
                          : colors.bullish,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Strategy Preset Selector
          SizedBox(
            height: 34,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _presets.length,
              itemBuilder: (context, i) {
                final isSelected = i == _selectedStrategyIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      _presets[i].name,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : colors.textSecondary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: colors.primary,
                    backgroundColor: colors.surface,
                    side: BorderSide(
                        color: isSelected
                            ? colors.primary
                            : colors.divider,
                        width: 1),
                    onSelected: (_) => setState(() {
                      _selectedStrategyIndex = i;
                      _computePayoff();
                    }),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Payoff Chart
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: PayoffChart(
              points: _points,
              metrics: _metrics,
              spotPrice: _activeStrategy.spotPrice,
              height: 270,
            ),
          ),

          // Current spot label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 2,
                  color: colors.textSecondary.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 4),
                Text(
                  'Spot: ₹${_activeStrategy.spotPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                      color: colors.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Metrics Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _MetricCard(
                  label: 'Max Profit',
                  value: _metrics.isMaxProfitUnlimited
                      ? '∞ Unlimited'
                      : '₹${_metrics.maxProfit.toStringAsFixed(0)}',
                  valueColor: colors.bullish,
                ),
                const SizedBox(width: 8),
                _MetricCard(
                  label: 'Max Loss',
                  value: _metrics.isMaxLossUnlimited
                      ? '∞ Unlimited'
                      : '₹${_metrics.maxLoss.abs().toStringAsFixed(0)}',
                  valueColor: colors.bearish,
                ),
                const SizedBox(width: 8),
                _MetricCard(
                  label: 'Breakeven',
                  value: _metrics.breakevens.isEmpty
                      ? '—'
                      : _metrics.breakevens
                          .map((b) => '₹${b.toStringAsFixed(0)}')
                          .join('\n'),
                  valueColor: colors.textPrimary,
                ),
                const SizedBox(width: 8),
                _MetricCard(
                  label: 'Risk:Reward',
                  value: _metrics.riskRewardRatio == 0
                      ? '—'
                      : '1 : ${_metrics.riskRewardRatio.toStringAsFixed(1)}',
                  valueColor: colors.primary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Legs Table
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Legs',
                    style: GoogleFonts.inter(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.8)),
                const SizedBox(height: 8),
                ..._activeStrategy.legs.map((leg) => _LegRow(leg: leg)),
              ],
            ),
          ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.divider, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    color: colors.textSecondary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4)),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.inter(
                    color: valueColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _LegRow extends StatelessWidget {
  final OptionStrategyLeg leg;

  const _LegRow({required this.leg});

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final isBuy = leg.side == TransactionType.BUY;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Side badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isBuy
                  ? colors.bullish.withValues(alpha: 0.12)
                  : colors.bearish.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isBuy ? 'BUY' : 'SELL',
              style: GoogleFonts.inter(
                  color: isBuy ? colors.bullish : colors.bearish,
                  fontWeight: FontWeight.w800,
                  fontSize: 10),
            ),
          ),
          const SizedBox(width: 10),

          // Type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              leg.type.label,
              style: GoogleFonts.inter(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 10),
            ),
          ),
          const SizedBox(width: 10),

          // Strike
          if (leg.strike > 0)
            Text(
              'Strike ₹${leg.strike.toStringAsFixed(0)}',
              style: GoogleFonts.inter(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12),
            ),

          const Spacer(),

          // Premium
          Text(
            isBuy
                ? '−₹${leg.premium.toStringAsFixed(0)}'
                : '+₹${leg.premium.toStringAsFixed(0)}',
            style: GoogleFonts.inter(
                color: isBuy ? colors.bearish : colors.bullish,
                fontWeight: FontWeight.w700,
                fontSize: 12),
          ),
          const SizedBox(width: 8),

          // Qty
          Text(
            '× ${leg.quantity} lot',
            style: GoogleFonts.inter(
                color: colors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
