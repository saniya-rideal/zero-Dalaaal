import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/trading_colors.dart';
import '../../../../data/models/stock_fundamentals.dart';

class FundamentalsTab extends StatelessWidget {
  final StockFundamentals fundamentals;

  const FundamentalsTab({super.key, required this.fundamentals});

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final ratios = fundamentals.ratios;
    final isPeCheaper = ratios.peRatio < ratios.sectorPe;
    final peDifference = (ratios.peRatio - ratios.sectorPe).abs();

    final bannerColor = isPeCheaper ? colors.bullish : colors.bearish;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Valuation Benchmark Comparison Banner
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: bannerColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: bannerColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  isPeCheaper ? LucideIcons.trendingDown : LucideIcons.trendingUp,
                  color: bannerColor,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPeCheaper
                            ? 'Trading at Discount to Sector'
                            : 'Trading at Premium to Sector',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Stock P/E of ${ratios.peRatio} is ${peDifference.toStringAsFixed(1)} pts ${isPeCheaper ? "lower" : "higher"} than Sector P/E (${ratios.sectorPe}).',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 2. Key Valuation Ratios Header
          Text(
            'Key Valuation & Performance Ratios',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // 2x2 / 3x2 Grid of Ratios
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.75,
            children: [
              _buildRatioTile('P/E Ratio (TTM)', ratios.peRatio.toStringAsFixed(2), 'Sector: ${ratios.sectorPe}', colors),
              _buildRatioTile('Price to Book (P/B)', ratios.pbRatio.toStringAsFixed(2), 'Book: ₹${ratios.bookValuePerShare.toStringAsFixed(0)}', colors),
              _buildRatioTile('Return on Equity (ROE)', '${ratios.roe.toStringAsFixed(2)}%', ratios.roe > 15 ? 'High Return' : 'Moderate', colors, isPositive: ratios.roe > 15),
              _buildRatioTile('ROCE', '${ratios.roce.toStringAsFixed(2)}%', 'Capital Efficiency', colors, isPositive: ratios.roce > 15),
              _buildRatioTile('Debt to Equity', ratios.debtToEquity.toStringAsFixed(2), ratios.debtToEquity < 0.5 ? 'Low Debt / Safe' : 'Leveraged', colors, isPositive: ratios.debtToEquity < 1.0),
              _buildRatioTile('Dividend Yield', '${ratios.dividendYield.toStringAsFixed(2)}%', 'Annual Payout', colors),
              _buildRatioTile('Market Cap', '₹${NumberFormat('#,##0').format(ratios.marketCap)} Cr', ratios.marketCapCategory, colors),
              _buildRatioTile('Beta (1Y)', ratios.beta.toStringAsFixed(2), ratios.beta > 1 ? 'High Volatility' : 'Defensive', colors),
              _buildRatioTile('EV / EBITDA', '${ratios.evToEbitda.toStringAsFixed(1)}x', 'Enterprise Multiple', colors),
              _buildRatioTile('Face Value', '₹${ratios.faceValue.toStringAsFixed(0)}', 'Authorized unit', colors),
            ],
          ),
          const SizedBox(height: 22),

          // 3. About Company Profile Card
          Text(
            'About the Company',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.divider.withValues(alpha: 0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildChip(fundamentals.sector, colors.secondary, colors),
                    _buildChip(fundamentals.industry, colors.textSecondary, colors),
                    _buildChip(ratios.marketCapCategory, const Color(0xFFF59E0B), colors),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  fundamentals.about,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    height: 1.5,
                    color: colors.textPrimary,
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

  Widget _buildRatioTile(String label, String value, String subtitle, TradingColors colors, {bool? isPositive}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.divider.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isPositive == null
                  ? colors.textSecondary.withValues(alpha: 0.8)
                  : (isPositive ? colors.bullish : colors.bearish),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String text, Color accentColor, TradingColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: accentColor,
        ),
      ),
    );
  }
}
