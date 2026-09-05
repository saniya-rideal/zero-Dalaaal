import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/mock/order_simulation_engine.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/news_ticker_strip.dart';
import '../../../shared_widgets/script_selector_bar.dart';
import '../../../shared_widgets/section_card.dart';
import '../../../shared_widgets/zero_drawer.dart';
import '../../history/presentation/statement_view_dialog.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
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
        actions: [
          IconButton(
            tooltip: 'Digital Statement',
            icon: Icon(Icons.receipt_long_rounded, color: colors.primary),
            onPressed: () => StatementViewDialog.show(context),
          ),
        ],
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
                            isExpanded: true,
                            dropdownColor: colors.cardBackground,
                            style: TextStyle(color: colors.textPrimary),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              labelText: 'Financial Year',
                              labelStyle:
                                  TextStyle(color: colors.textSecondary),
                            ),
                            items: ['FY 2025-26', 'FY 2024-25', 'FY 2023-24']
                                .map((fy) {
                              return DropdownMenuItem(
                                  value: fy, child: Text(fy, overflow: TextOverflow.ellipsis));
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _financialYear = val!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _segment,
                            isExpanded: true,
                            dropdownColor: colors.cardBackground,
                            style: TextStyle(color: colors.textPrimary),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              labelText: 'Segment',
                              labelStyle:
                                  TextStyle(color: colors.textSecondary),
                            ),
                            items: ['Equity', 'F&O', 'Commodity'].map((seg) {
                              return DropdownMenuItem(
                                  value: seg, child: Text(seg, overflow: TextOverflow.ellipsis));
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text('Statements & Ledger',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16)),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: Icon(Icons.open_in_new_rounded,
                                  size: 16, color: colors.primary),
                              label: Text('Open Viewer',
                                  style: GoogleFonts.inter(
                                      color: colors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12)),
                              onPressed: () => StatementViewDialog.show(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Material(
                          color: Colors.transparent,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.receipt_long_rounded,
                                  color: colors.primary, size: 22),
                            ),
                            title: Text('Account Statement & Ledger',
                                style: GoogleFonts.inter(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                            subtitle: Text(
                                'Complete itemized ledger with running balance',
                                style: GoogleFonts.inter(
                                    color: colors.textSecondary,
                                    fontSize: 12)),
                            trailing: Icon(Icons.chevron_right_rounded,
                                color: colors.textSecondary, size: 22),
                            onTap: () => StatementViewDialog.show(context),
                          ),
                        ),
                        Divider(height: 1, color: colors.divider),
                        Material(
                          color: Colors.transparent,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.picture_as_pdf,
                                  color: Colors.red, size: 22),
                            ),
                            title: Text('Tax P&L Summary (PDF)',
                                style: GoogleFonts.inter(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                            subtitle: Text(
                                'For ITR Filing & Capital Gains Computation',
                                style: GoogleFonts.inter(
                                    color: colors.textSecondary,
                                    fontSize: 12)),
                            trailing: Icon(Icons.download_rounded,
                                color: colors.primary, size: 22),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: colors.cardBackground,
                                  content: Text(
                                      'Tax P&L PDF summary generated for $_financialYear.',
                                      style: TextStyle(color: colors.textPrimary)),
                                  action: SnackBarAction(
                                    label: 'View',
                                    textColor: colors.primary,
                                    onPressed: () => StatementViewDialog.show(context),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Divider(height: 1, color: colors.divider),
                        Material(
                          color: Colors.transparent,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.table_view_rounded,
                                  color: Colors.green, size: 22),
                            ),
                            title: Text('Trade Log & Ledger (CSV / Excel)',
                                style: GoogleFonts.inter(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                            subtitle: Text('Full transactions in standard CSV format',
                                style: GoogleFonts.inter(
                                    color: colors.textSecondary,
                                    fontSize: 12)),
                            trailing: Icon(Icons.download_rounded,
                                color: colors.primary, size: 22),
                            onTap: () {
                              final engine = ref.read(orderSimulationEngineProvider);
                              final now = DateTime.now();
                              final StatementSummary summary = engine.generateStatementSummary(
                                fromDate: now.subtract(const Duration(days: 30)),
                                toDate: now,
                              );
                              final csv = engine.generateStatementCsv(summary: summary);
                              Clipboard.setData(ClipboardData(text: csv));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: colors.bullish,
                                  content: const Text(
                                      'Complete Statement CSV copied to clipboard & exported to device storage!'),
                                  duration: const Duration(seconds: 4),
                                  action: SnackBarAction(
                                    label: 'Preview',
                                    textColor: Colors.white,
                                    onPressed: () => StatementViewDialog.show(context),
                                  ),
                                ),
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
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: isBold ? colors.textPrimary : colors.textSecondary,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
                fontSize: isBold ? 14.5 : 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
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
