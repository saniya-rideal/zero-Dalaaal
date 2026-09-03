import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared_widgets/news_ticker_strip.dart';
import '../../../shared_widgets/script_selector_bar.dart';
import '../../../shared_widgets/section_card.dart';
import '../../../shared_widgets/zero_drawer.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _financialYear = 'FY 2025-26';
  String _segment = 'Equity';

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const ZeroDrawer(activeRoute: '/reports'),
      appBar: AppBar(
        backgroundColor: colors.cardBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (innerContext) => IconButton(
            icon: Icon(Icons.menu, color: colors.textPrimary, size: 26),
            onPressed: () => Scaffold.of(innerContext).openDrawer(),
          ),
        ),
        centerTitle: true,
        title: Text('Tax P&L & Analytics',
            style: GoogleFonts.inter(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
      ),
      body: Column(
        children: [
          // Public & Private News Ticker Strip
          const NewsTickerStrip(),

          // Dual Script Selector Bar
          const ScriptSelectorBar(),

          // Reports Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Filter Bar
                  SectionCard(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _financialYear,
                            dropdownColor: colors.cardBackground,
                            style: TextStyle(color: colors.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'Financial Year',
                              labelStyle:
                                  TextStyle(color: colors.textSecondary),
                            ),
                            items: ['FY 2025-26', 'FY 2024-25', 'FY 2023-24']
                                .map((fy) {
                              return DropdownMenuItem(
                                  value: fy, child: Text(fy));
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _financialYear = val!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _segment,
                            dropdownColor: colors.cardBackground,
                            style: TextStyle(color: colors.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'Segment',
                              labelStyle:
                                  TextStyle(color: colors.textSecondary),
                            ),
                            items: ['Equity', 'F&O', 'Commodity'].map((seg) {
                              return DropdownMenuItem(
                                  value: seg, child: Text(seg));
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _segment = val!),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Capital Gains Summary
                  SectionCard(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Realized Gains Breakdown',
                            style: GoogleFonts.inter(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 16)),
                        const SizedBox(height: 14),
                        _buildGainRow('Short Term Capital Gains (STCG)',
                            42580.00, colors.bullish, colors),
                        _buildGainRow('Long Term Capital Gains (LTCG)',
                            185420.00, colors.bullish, colors),
                        _buildGainRow('Intraday & Speculative P&L', -3450.00,
                            colors.bearish, colors),
                        _buildGainRow('Total Turnover', 1245000.00,
                            colors.textPrimary, colors),
                        Divider(height: 20, color: colors.divider),
                        _buildGainRow('Net Realized Profit', 224550.00,
                            colors.bullish, colors,
                            isBold: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Download Statement Cards
                  SectionCard(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Download Statements',
                            style: GoogleFonts.inter(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 16)),
                        const SizedBox(height: 12),
                        Material(
                          color: Colors.transparent,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.picture_as_pdf,
                                color: Colors.red, size: 28),
                            title: Text('Tax P&L Summary (PDF)',
                                style: GoogleFonts.inter(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                            subtitle: Text(
                                'For ITR Filing & Tax Computation',
                                style: GoogleFonts.inter(
                                    color: colors.textSecondary,
                                    fontSize: 12)),
                            trailing: Icon(Icons.download,
                                color: colors.primary, size: 22),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Tax P&L PDF downloaded to device storage.')),
                              );
                            },
                          ),
                        ),
                        Divider(height: 1, color: colors.divider),
                        Material(
                          color: Colors.transparent,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.table_view,
                                color: Colors.green, size: 28),
                            title: Text('Trade Log (Excel / CSV)',
                                style: GoogleFonts.inter(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                            subtitle: Text('Complete trade history record',
                                style: GoogleFonts.inter(
                                    color: colors.textSecondary,
                                    fontSize: 12)),
                            trailing: Icon(Icons.download,
                                color: colors.primary, size: 22),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Trade Log Excel spreadsheet exported successfully.')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGainRow(
      String label, double amount, Color amountColor, TradingColors colors,
      {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: isBold ? colors.textPrimary : colors.textSecondary,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
              fontSize: isBold ? 14.5 : 13,
            ),
          ),
          Text(
            CurrencyFormatter.format(amount),
            style: GoogleFonts.inter(
              color: amountColor,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
              fontSize: isBold ? 15 : 13.5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
