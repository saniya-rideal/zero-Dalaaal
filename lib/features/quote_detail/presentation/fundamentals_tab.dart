import 'package:flutter/material.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/section_card.dart';

class FundamentalsTab extends StatelessWidget {
  final Instrument instrument;
  final Quote quote;

  const FundamentalsTab({
    super.key,
    required this.instrument,
    required this.quote,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;

    // Computed mock fundamentals
    final mcap = (quote.ltp * 150000000);
    final pe = (24.5 + (instrument.symbol.hashCode % 30)).abs();
    final pb = (3.2 + (instrument.symbol.hashCode % 8)).abs();
    final divYield = (1.2 + ((instrument.symbol.hashCode % 15) / 10)).abs();
    final roe = (18.4 + (instrument.symbol.hashCode % 12)).abs();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Valuation & Financials', style: AppTypography.h2(color: colors.textPrimary)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatCol('Market Cap', CurrencyFormatter.formatCompact(mcap), colors),
                    _buildStatCol('P/E Ratio', pe.toStringAsFixed(2), colors),
                    _buildStatCol('P/B Ratio', pb.toStringAsFixed(2), colors),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatCol('Div Yield', '${divYield.toStringAsFixed(2)}%', colors),
                    _buildStatCol('ROE', '${roe.toStringAsFixed(2)}%', colors),
                    _buildStatCol('Sector P/E', '28.40', colors),
                  ],
                ),
              ],
            ),
          ),

          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Price Summary', style: AppTypography.h2(color: colors.textPrimary)),
                const SizedBox(height: 16),
                _buildPriceRangeRow(
                  label: "Today's Range",
                  low: quote.low,
                  high: quote.high,
                  current: quote.ltp,
                  colors: colors,
                ),
                const SizedBox(height: 20),
                _buildPriceRangeRow(
                  label: '52 Week Range',
                  low: quote.low52 > 0 ? quote.low52 : quote.ltp * 0.75,
                  high: quote.high52 > 0 ? quote.high52 : quote.ltp * 1.35,
                  current: quote.ltp,
                  colors: colors,
                ),
              ],
            ),
          ),

          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Company Profile', style: AppTypography.h2(color: colors.textPrimary)),
                const SizedBox(height: 8),
                Text(
                  '${instrument.name} is a leading Indian enterprise traded on ${instrument.exchange.name}. Key business operations span core market segments with consistent revenue and healthy promoter holding.',
                  style: AppTypography.body(color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol(String label, String value, TradingColors colors) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption(color: colors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.body(color: colors.textPrimary, weight: FontWeight.w600, tabular: true)),
        ],
      ),
    );
  }

  Widget _buildPriceRangeRow({
    required String label,
    required double low,
    required double high,
    required double current,
    required TradingColors colors,
  }) {
    final range = (high - low).abs();
    final fraction = range > 0 ? ((current - low) / range).clamp(0.0, 1.0) : 0.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.caption(color: colors.textSecondary, weight: FontWeight.w600)),
            Text(CurrencyFormatter.format(current), style: AppTypography.caption(color: colors.textPrimary, weight: FontWeight.w600, tabular: true)),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            FractionallySizedBox(
              widthFactor: fraction,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('L: ${CurrencyFormatter.format(low)}', style: AppTypography.labelSmall(color: colors.textSecondary, tabular: true)),
            Text('H: ${CurrencyFormatter.format(high)}', style: AppTypography.labelSmall(color: colors.textSecondary, tabular: true)),
          ],
        ),
      ],
    );
  }
}
