import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared_widgets/shared_widgets.dart';
import '../../../shared_widgets/zero_drawer.dart';
import '../../funds/data/real_funds_repository.dart';
import '../../history/presentation/statement_view_dialog.dart';
import '../data/reports_repository.dart';

final pnlReportProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.getPnl();
});

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
    final pnlAsync = ref.watch(pnlReportProvider);

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const ZeroDrawer(activeRoute: '/reports'),
      appBar: AppBar(
        backgroundColor: colors.cardBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AdaptiveLeadingButton(),
        centerTitle: true,
        title: Text(
          'Tax P&L & Analytics',
          style: GoogleFonts.inter(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Digital Statement',
            icon: Icon(LucideIcons.fileText, color: colors.primary),
            onPressed: () => StatementViewDialog.show(context),
          ),
        ],
      ),
      body: Column(
        children: [
          const ZeroMarketHeaderStrip(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Filter Bar
                  SectionCard(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _financialYear,
                            isExpanded: true,
                            dropdownColor: colors.cardBackground,
                            style: TextStyle(color: colors.textPrimary),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              labelText: 'Financial Year',
                              labelStyle: TextStyle(color: colors.textSecondary),
                            ),
                            items: ['FY 2025-26', 'FY 2024-25', 'FY 2023-24'].map((fy) {
                              return DropdownMenuItem(value: fy, child: Text(fy, overflow: TextOverflow.ellipsis));
                            }).toList(),
                            onChanged: (val) => setState(() => _financialYear = val!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _segment,
                            isExpanded: true,
                            dropdownColor: colors.cardBackground,
                            style: TextStyle(color: colors.textPrimary),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              labelText: 'Segment',
                              labelStyle: TextStyle(color: colors.textSecondary),
                            ),
                            items: ['Equity', 'F&O', 'Commodity'].map((seg) {
                              return DropdownMenuItem(value: seg, child: Text(seg, overflow: TextOverflow.ellipsis));
                            }).toList(),
                            onChanged: (val) => setState(() => _segment = val!),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Real Capital Gains Summary
                  SectionCard(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: pnlAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, _) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Realized Gains Breakdown',
                            style: GoogleFonts.inter(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'P&L statement unavailable: $err',
                            style: TextStyle(color: colors.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => ref.invalidate(pnlReportProvider),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                      data: (pnl) {
                        final realized = (pnl['realizedPnl'] as num?)?.toDouble() ?? 0.0;
                        final unrealized = (pnl['unrealizedPnl'] as num?)?.toDouble() ?? 0.0;
                        final intraday = (pnl['intradayPnl'] as num?)?.toDouble() ?? 0.0;
                        final delivery = (pnl['deliveryPnl'] as num?)?.toDouble() ?? 0.0;
                        final turnover = (pnl['totalTurnover'] ?? pnl['turnover'] as num?)?.toDouble() ?? 0.0;
                        final netProfit = (pnl['netPnl'] ?? (realized - (pnl['charges'] as num? ?? 0.0))) as num;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Realized Gains Breakdown',
                              style: GoogleFonts.inter(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildGainRow(
                              'Realized Delivery P&L',
                              delivery,
                              delivery >= 0 ? colors.bullish : colors.bearish,
                              colors,
                            ),
                            _buildGainRow(
                              'Intraday & Speculative P&L',
                              intraday,
                              intraday >= 0 ? colors.bullish : colors.bearish,
                              colors,
                            ),
                            _buildGainRow(
                              'Unrealized Open P&L',
                              unrealized,
                              unrealized >= 0 ? colors.bullish : colors.bearish,
                              colors,
                            ),
                            _buildGainRow(
                              'Total Turnover',
                              turnover,
                              colors.textPrimary,
                              colors,
                            ),
                            Divider(height: 20, color: colors.divider),
                            _buildGainRow(
                              'Net Realized Profit',
                              netProfit.toDouble(),
                              netProfit >= 0 ? colors.bullish : colors.bearish,
                              colors,
                              isBold: true,
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Download Statement Cards
                  SectionCard(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Statements & Ledger',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: Icon(LucideIcons.externalLink, size: 16, color: colors.primary),
                              label: Text(
                                'Open Viewer',
                                style: GoogleFonts.inter(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              onPressed: () => StatementViewDialog.show(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(LucideIcons.fileText, color: colors.primary, size: 20),
                          ),
                          title: Text(
                            'Account Statement & Ledger',
                            style: GoogleFonts.inter(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            'Complete itemized ledger with running balance',
                            style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 12),
                          ),
                          trailing: Icon(LucideIcons.chevronRight, color: colors.textSecondary, size: 20),
                          onTap: () => StatementViewDialog.show(context),
                        ),
                        Divider(height: 1, color: colors.divider),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(LucideIcons.sheet, color: Colors.green, size: 20),
                          ),
                          title: Text(
                            'Trade Log & Ledger (CSV / Excel)',
                            style: GoogleFonts.inter(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            'Full ledger transactions exported to device clipboard',
                            style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 12),
                          ),
                          trailing: Icon(LucideIcons.download, color: colors.primary, size: 20),
                          onTap: () async {
                            final ledger = await ref.read(fundsRepositoryProvider).getLedger();
                            final buffer = StringBuffer();
                            buffer.writeln('Date,ID,Narration,Debit,Credit,RunningBalance');
                            for (final e in ledger) {
                              buffer.writeln('${e.date.toIso8601String()},${e.id},"${e.narration}",${e.debit},${e.credit},${e.runningBalance}');
                            }
                            Clipboard.setData(ClipboardData(text: buffer.toString()));
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: colors.bullish,
                                content: Text('Complete Ledger CSV (${ledger.length} entries) copied to clipboard!'),
                                action: SnackBarAction(
                                  label: 'Preview',
                                  textColor: Colors.white,
                                  onPressed: () => StatementViewDialog.show(context),
                                ),
                              ),
                            );
                          },
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
    String label,
    double amount,
    Color amountColor,
    TradingColors colors, {
    bool isBold = false,
  }) {
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
