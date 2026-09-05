import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/utils/currency_formatter.dart';

class LeverageEducationDialog extends StatefulWidget {
  final double defaultExposure;
  final double currentLeverage;

  const LeverageEducationDialog({
    super.key,
    this.defaultExposure = 50000.0,
    this.currentLeverage = 5.0,
  });

  static Future<void> show(
    BuildContext context, {
    double defaultExposure = 50000.0,
    double currentLeverage = 5.0,
  }) {
    return showDialog(
      context: context,
      builder: (context) => LeverageEducationDialog(
        defaultExposure: defaultExposure,
        currentLeverage: currentLeverage,
      ),
    );
  }

  @override
  State<LeverageEducationDialog> createState() => _LeverageEducationDialogState();
}

class _LeverageEducationDialogState extends State<LeverageEducationDialog> {
  double _marketMovePercent = 2.0; // Default +2% move

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final capitalInvested = widget.defaultExposure / widget.currentLeverage;
    final priceChangeAmount = widget.defaultExposure * (_marketMovePercent / 100.0);
    final returnOnInvestedCapital = (priceChangeAmount / capitalInvested) * 100.0;
    final isGain = _marketMovePercent >= 0;

    return Dialog(
      backgroundColor: colors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.tune_rounded, color: colors.primary, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Leverage & Risk Guide',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                            Text(
                              'How leverage magnifies both gains and losses',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: colors.textSecondary,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: colors.textSecondary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Concept Overview Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.divider, width: 0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'What is Leverage?',
                                style: GoogleFonts.inter(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Leverage allows you to control a larger market exposure with a fraction of total capital as margin. For instance, with 5x leverage on MIS intraday orders, ₹10,000 margin controls ₹50,000 of stock exposure.',
                            style: GoogleFonts.inter(
                              color: colors.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Interactive Simulator Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (isGain ? colors.bullish : colors.bearish).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Live Risk & Return Simulator',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${widget.currentLeverage.toStringAsFixed(0)}x Leverage',
                                  style: GoogleFonts.inter(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Slider to simulate price movement
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Simulated Market Move:',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_marketMovePercent > 0 ? "+" : ""}${_marketMovePercent.toStringAsFixed(1)}%',
                                style: GoogleFonts.inter(
                                  color: isGain ? colors.bullish : colors.bearish,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: _marketMovePercent,
                            min: -10.0,
                            max: 10.0,
                            divisions: 40,
                            activeColor: isGain ? colors.bullish : colors.bearish,
                            inactiveColor: colors.divider,
                            label: '${_marketMovePercent.toStringAsFixed(1)}%',
                            onChanged: (val) => setState(() => _marketMovePercent = val),
                          ),

                          // Results breakdown
                          const SizedBox(height: 6),
                          _buildMetricRow('Position Exposure', CurrencyFormatter.format(widget.defaultExposure), colors),
                          _buildMetricRow('Margin Invested', CurrencyFormatter.format(capitalInvested), colors),
                          _buildMetricRow('Price Change Effect', '${isGain ? "+" : ""}${CurrencyFormatter.format(priceChangeAmount)}', colors, valueColor: isGain ? colors.bullish : colors.bearish),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Net ROI on Margin:',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${returnOnInvestedCapital > 0 ? "+" : ""}${returnOnInvestedCapital.toStringAsFixed(1)}%',
                                style: GoogleFonts.inter(
                                  color: isGain ? colors.bullish : colors.bearish,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isGain
                                ? 'Notice: A ${_marketMovePercent.toStringAsFixed(1)}% price increase yielded a +${returnOnInvestedCapital.toStringAsFixed(1)}% gain on your invested capital.'
                                : 'Caution: A ${_marketMovePercent.abs().toStringAsFixed(1)}% price drop caused a ${returnOnInvestedCapital.abs().toStringAsFixed(1)}% loss of your invested capital.',
                            style: GoogleFonts.inter(
                              color: isGain ? colors.bullish : colors.bearish,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Risk Management Rules
                    Text(
                      'Automated Risk Guardrails',
                      style: GoogleFonts.inter(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildGuardrailItem(
                      icon: Icons.warning_amber_rounded,
                      color: Colors.amber,
                      title: 'Margin Call (90% Utilization)',
                      description: 'Triggered when used margin reaches 90% of total funds. Placing new leveraged positions is prohibited until funds are deposited or open positions are squared off.',
                      colors: colors,
                    ),
                    const SizedBox(height: 8),
                    _buildGuardrailItem(
                      icon: Icons.dangerous_outlined,
                      color: colors.bearish,
                      title: 'RMS Forced Liquidation (100% / Margin Deficit)',
                      description: 'Triggered when equity falls below required margin. Risk Management Systems (RMS) automatically square off open positions to prevent negative balance debt.',
                      colors: colors,
                    ),
                    const SizedBox(height: 8),
                    _buildGuardrailItem(
                      icon: Icons.shield_outlined,
                      color: colors.bullish,
                      title: 'Stop-Loss Protection',
                      description: 'Always define a stop-loss price on leveraged trades to cap downside risk and avoid margin calls.',
                      colors: colors,
                    ),

                    const SizedBox(height: 16),

                    // SEBI Statutory Risk Warning
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.divider, width: 0.5),
                      ),
                      child: Text(
                        'SEBI Statutory Advisory: 9 out of 10 individual traders in equity F&O and intraday leveraged products incur net losses. Over and above the net trading losses, loss makers expended an additional 28% of net trading losses as transaction costs.',
                        style: GoogleFonts.inter(
                          color: colors.textSecondary,
                          fontSize: 10.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('I Understand the Risks', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, TradingColors colors, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              color: valueColor ?? colors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardrailItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required TradingColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    color: colors.textSecondary,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
