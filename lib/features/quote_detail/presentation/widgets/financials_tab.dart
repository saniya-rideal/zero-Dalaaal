import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/trading_colors.dart';
import '../../../../data/models/stock_fundamentals.dart';

class FinancialsTab extends StatefulWidget {
  final StockFundamentals fundamentals;

  const FinancialsTab({super.key, required this.fundamentals});

  @override
  State<FinancialsTab> createState() => _FinancialsTabState();
}

class _FinancialsTabState extends State<FinancialsTab> {
  bool _isQuarterly = true; // true = Quarterly, false = Annual

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final periods = _isQuarterly
        ? widget.fundamentals.quarterlyResults
        : widget.fundamentals.annualResults;
    final balanceSheet = widget.fundamentals.balanceSheet;
    final cashFlow = widget.fundamentals.cashFlow;

    final currencyFmt = NumberFormat('#,##0');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Period Selector: Quarterly vs Annual Pill Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Financial Performance',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.divider),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleBtn('Quarterly', _isQuarterly, () {
                      if (!_isQuarterly) setState(() => _isQuarterly = true);
                    }, colors),
                    _buildToggleBtn('Annual', !_isQuarterly, () {
                      if (_isQuarterly) setState(() => _isQuarterly = false);
                    }, colors),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. Financial Results Cards (P&L List)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: periods.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final p = periods[index];
              final isProfitGrowth = p.yoyProfitGrowth >= 0;
              final isRevenueGrowth = p.yoyRevenueGrowth >= 0;

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.divider.withValues(alpha: 0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Period Name & Margin
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colors.secondary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  p.period,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: colors.secondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Margin: ${p.ebitdaMargin.toStringAsFixed(1)}%',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // EPS Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'EPS: ₹${p.eps.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Metrics Row 1: Revenue
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Revenue from Operations',
                            style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹${currencyFmt.format(p.revenue)} Cr',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${isRevenueGrowth ? "+" : ""}${p.yoyRevenueGrowth.toStringAsFixed(1)}%',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isRevenueGrowth ? colors.bullish : colors.bearish,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Metrics Row 2: EBITDA
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Operating EBITDA',
                            style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary),
                          ),
                        ),
                        Text(
                          '₹${currencyFmt.format(p.ebitda)} Cr',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Metrics Row 3: Net Profit (PAT)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Net Profit (PAT)',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textPrimary),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹${currencyFmt.format(p.netProfit)} Cr',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: p.netProfit >= 0 ? colors.textPrimary : colors.bearish,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${isProfitGrowth ? "+" : ""}${p.yoyProfitGrowth.toStringAsFixed(1)}%',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isProfitGrowth ? colors.bullish : colors.bearish,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // 3. Balance Sheet Summary
          Row(
            children: [
              const Icon(LucideIcons.landmark, size: 18, color: Color(0xFF4F46E5)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Balance Sheet Snapshot (${balanceSheet.asOfDate})',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.divider.withValues(alpha: 0.6)),
            ),
            child: Column(
              children: [
                _buildSummaryLine('Total Assets', '₹${currencyFmt.format(balanceSheet.totalAssets)} Cr', colors),
                _buildSummaryLine('Shareholder Equity / Net Worth', '₹${currencyFmt.format(balanceSheet.shareholderEquity)} Cr', colors, isBold: true),
                _buildSummaryLine('Total Debt & Borrowings', '₹${currencyFmt.format(balanceSheet.totalDebt)} Cr', colors),
                _buildSummaryLine('Total Liabilities', '₹${currencyFmt.format(balanceSheet.totalLiabilities)} Cr', colors),
                _buildSummaryLine('Cash & Liquid Investments', '₹${currencyFmt.format(balanceSheet.cashAndEquivalents)} Cr', colors, isAccent: true),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. Cash Flow Statement Summary
          Row(
            children: [
              const Icon(LucideIcons.arrowDownUp, size: 18, color: Color(0xFF00A854)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cash Flow Summary (${cashFlow.asOfDate})',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.divider.withValues(alpha: 0.6)),
            ),
            child: Column(
              children: [
                _buildSummaryLine('Operating Cash Flow (CFO)', '₹${currencyFmt.format(cashFlow.operatingCashFlow)} Cr', colors, isPositive: cashFlow.operatingCashFlow >= 0),
                _buildSummaryLine('Investing Cash Flow (CFI)', '₹${currencyFmt.format(cashFlow.investingCashFlow)} Cr', colors),
                _buildSummaryLine('Financing Cash Flow (CFF)', '₹${currencyFmt.format(cashFlow.financingCashFlow)} Cr', colors),
                _buildSummaryLine('Free Cash Flow (FCF)', '₹${currencyFmt.format(cashFlow.freeCashFlow)} Cr', colors, isBold: true, isPositive: cashFlow.freeCashFlow >= 0),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(String label, bool isSelected, VoidCallback onTap, TradingColors colors) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? colors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryLine(String label, String value, TradingColors colors, {bool isBold = false, bool isAccent = false, bool? isPositive}) {
    Color valueColor = isBold ? colors.textPrimary : colors.textSecondary;
    if (isAccent) valueColor = colors.secondary;
    if (isPositive != null) {
      valueColor = isPositive ? colors.bullish : colors.bearish;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: isBold ? colors.textPrimary : colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
