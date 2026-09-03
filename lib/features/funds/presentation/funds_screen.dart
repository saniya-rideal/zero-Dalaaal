import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/balance_privacy_service.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/mock/order_simulation_engine.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/news_ticker_strip.dart';
import '../../../shared_widgets/script_selector_bar.dart';
import '../../../shared_widgets/section_card.dart';
import '../../../shared_widgets/zero_drawer.dart';
import 'add_funds_sheet.dart';
import 'withdraw_funds_sheet.dart';

class FundsScreen extends ConsumerStatefulWidget {
  const FundsScreen({super.key});

  @override
  ConsumerState<FundsScreen> createState() => _FundsScreenState();
}

class _FundsScreenState extends ConsumerState<FundsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final engine = ref.watch(orderSimulationEngineProvider);
    final isHidden = ref.watch(balancePrivacyProvider);
    final equitySummary = engine.getFundsSummary(Segment.EQUITY);
    final commoditySummary = engine.getFundsSummary(Segment.COMMODITY);
    final ledger = engine.ledger;

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const ZeroDrawer(activeRoute: '/funds'),
      appBar: AppBar(
        backgroundColor: colors.cardBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu, color: colors.textPrimary, size: 26),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        centerTitle: true,
        title: Text('Funds',
            style: GoogleFonts.inter(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        actions: [
          IconButton(
            icon: Icon(
              isHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: colors.textSecondary,
              size: 20,
            ),
            tooltip: isHidden ? 'Show Balance' : 'Hide Balance',
            onPressed: () {
              ref.read(balancePrivacyProvider.notifier).state = !isHidden;
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.primary,
          indicatorWeight: 2.5,
          labelStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.5),
          tabs: const [
            Tab(text: 'Equity'),
            Tab(text: 'Commodity'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Public & Private News Ticker Strip
          const NewsTickerStrip(),

          // Dual Script Selector Bar
          const ScriptSelectorBar(),

          // Tab Bar View Body
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSegmentView(equitySummary, ledger, colors, Segment.EQUITY),
                _buildSegmentView(
                    commoditySummary, ledger, colors, Segment.COMMODITY),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentView(FundsSummary summary, List<LedgerEntry> ledger,
      TradingColors colors, Segment segment) {
    final isHidden = ref.watch(balancePrivacyProvider);
    final avail = isHidden ? '••••••' : CurrencyFormatter.format(summary.availableMargin);
    final used = isHidden ? '••••••' : CurrencyFormatter.format(summary.usedMargin);
    final opening = isHidden ? '••••••' : CurrencyFormatter.format(summary.openingBalance);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main Balance Card
          SectionCard(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Available Margin (${segment.name})',
                    style: AppTypography.caption(
                        color: colors.textSecondary,
                        weight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  avail,
                  style: GoogleFonts.inter(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSubStat('Used Margin', used, colors),
                    _buildSubStat('Opening Balance', opening, colors),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => AddFundsSheet.show(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.bullish,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: const Text('ADD FUNDS',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => WithdrawFundsSheet.show(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.primary,
                          side: BorderSide(color: colors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('WITHDRAW',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Statement / Ledger Section
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12, bottom: 6),
            child: Text(
              'Funds Statement',
              style: GoogleFonts.inter(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15),
            ),
          ),

          if (ledger.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Text('No transactions recorded for this segment.',
                    style: AppTypography.caption(color: colors.textSecondary)),
              ),
            )
          else
            ...ledger.map((entry) {
              final isCredit = entry.credit > 0;
              final amt = isCredit ? entry.credit : entry.debit;
              final amtColor = isCredit ? colors.bullish : colors.bearish;

              return ListTile(
                title: Text(
                  entry.narration,
                  style: GoogleFonts.inter(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                ),
                subtitle: Text(
                  '${DateFormatter.formatOrderDate(entry.date)} • Bal: ${CurrencyFormatter.format(entry.runningBalance)}',
                  style: GoogleFonts.inter(
                      color: colors.textSecondary,
                      fontSize: 12,
                      fontFeatures: const [FontFeature.tabularFigures()]),
                ),
                trailing: Text(
                  '${isCredit ? '+' : '-'}${CurrencyFormatter.format(amt)}',
                  style: GoogleFonts.inter(
                      color: amtColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSubStat(String label, String value, TradingColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value,
            style: GoogleFonts.inter(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                fontFeatures: const [FontFeature.tabularFigures()])),
      ],
    );
  }
}
