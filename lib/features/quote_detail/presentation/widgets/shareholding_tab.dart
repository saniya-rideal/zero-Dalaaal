import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/trading_colors.dart';
import '../../../../data/models/stock_fundamentals.dart';

class ShareholdingTab extends StatelessWidget {
  final StockFundamentals fundamentals;

  const ShareholdingTab({super.key, required this.fundamentals});

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final sh = fundamentals.shareholding;

    const promoterColor = Color(0xFF4F46E5);
    const fiiColor = Color(0xFF06B6D4);
    const diiColor = Color(0xFF10B981);
    const publicColor = Color(0xFFF59E0B);

    final total = (sh.promoterPercent + sh.fiiPercent + sh.diiPercent + sh.publicPercent);
    final normTotal = total > 0 ? total : 100.0;

    final pFlex = (sh.promoterPercent / normTotal * 1000).toInt().clamp(1, 1000);
    final fFlex = (sh.fiiPercent / normTotal * 1000).toInt().clamp(1, 1000);
    final dFlex = (sh.diiPercent / normTotal * 1000).toInt().clamp(1, 1000);
    final pubFlex = (sh.publicPercent / normTotal * 1000).toInt().clamp(1, 1000);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Shareholding Pattern
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Shareholding Distribution',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'As of ${sh.asOfQuarter}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. Multi-color Segmented Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 18,
              child: Row(
                children: [
                  if (sh.promoterPercent > 0)
                    Expanded(
                      flex: pFlex,
                      child: Container(color: promoterColor),
                    ),
                  if (sh.fiiPercent > 0)
                    Expanded(
                      flex: fFlex,
                      child: Container(color: fiiColor),
                    ),
                  if (sh.diiPercent > 0)
                    Expanded(
                      flex: dFlex,
                      child: Container(color: diiColor),
                    ),
                  if (sh.publicPercent > 0)
                    Expanded(
                      flex: pubFlex,
                      child: Container(color: publicColor),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2. Legend Grid / Wrap
          Wrap(
            spacing: 16,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _buildLegend('Promoters', '${sh.promoterPercent.toStringAsFixed(1)}%', promoterColor, colors),
              _buildLegend('FII', '${sh.fiiPercent.toStringAsFixed(1)}%', fiiColor, colors),
              _buildLegend('DII', '${sh.diiPercent.toStringAsFixed(1)}%', diiColor, colors),
              _buildLegend('Public', '${sh.publicPercent.toStringAsFixed(1)}%', publicColor, colors),
            ],
          ),
          const SizedBox(height: 20),

          // 3. Ownership Category Cards
          _buildHolderCard(
            'Promoters & Group',
            '${sh.promoterPercent.toStringAsFixed(2)}%',
            sh.promoterChangeQoq,
            promoterColor,
            subNotice: sh.promoterPledgedPercent > 0
                ? 'Pledged Shares: ${sh.promoterPledgedPercent.toStringAsFixed(2)}%'
                : 'Zero Promoter Pledge (Safe)',
            isWarning: sh.promoterPledgedPercent > 5.0,
            colors: colors,
          ),
          const SizedBox(height: 10),

          _buildHolderCard(
            'Foreign Institutional Investors (FII)',
            '${sh.fiiPercent.toStringAsFixed(2)}%',
            sh.fiiChangeQoq,
            fiiColor,
            subNotice: 'Global hedge funds, sovereign funds & pensions',
            colors: colors,
          ),
          const SizedBox(height: 10),

          _buildHolderCard(
            'Domestic Institutional Investors (DII)',
            '${sh.diiPercent.toStringAsFixed(2)}%',
            sh.diiChangeQoq,
            diiColor,
            subNotice: 'Indian Mutual Funds, Insurance & Banks',
            colors: colors,
          ),
          const SizedBox(height: 10),

          _buildHolderCard(
            'Public & Retail Investors',
            '${sh.publicPercent.toStringAsFixed(2)}%',
            -(sh.promoterChangeQoq + sh.fiiChangeQoq + sh.diiChangeQoq),
            publicColor,
            subNotice: 'Individual retail traders and small bodies corporate',
            colors: colors,
          ),
          const SizedBox(height: 22),

          // 4. Compliance Information Note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.divider.withValues(alpha: 0.6)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.shieldCheck, size: 18, color: colors.secondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SEBI Minimum Public Shareholding (MPS)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Listed companies are mandated by SEBI to maintain at least 25% non-promoter public shareholding. Low promoter pledging indicates healthy balance sheet solvency.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: colors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, String value, Color dotColor, TradingColors colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 10.5, color: colors.textSecondary, fontWeight: FontWeight.w500),
            ),
            Text(
              value,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: colors.textPrimary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHolderCard(
    String title,
    String percentage,
    double changeQoq,
    Color accentColor, {
    required String subNotice,
    bool isWarning = false,
    required TradingColors colors,
  }) {
    final isPositive = changeQoq >= 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 38,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subNotice,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: isWarning ? FontWeight.w700 : FontWeight.w500,
                    color: isWarning ? colors.bearish : colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                percentage,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                    size: 11,
                    color: isPositive ? colors.bullish : colors.bearish,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${isPositive ? "+" : ""}${changeQoq.toStringAsFixed(2)}% QoQ',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isPositive ? colors.bullish : colors.bearish,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
