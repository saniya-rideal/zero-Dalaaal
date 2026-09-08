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
import 'balance_breakdown_dialog.dart';
import 'transaction_receipt_dialog.dart';
import 'withdraw_funds_sheet.dart';

class FundsScreen extends ConsumerStatefulWidget {
  const FundsScreen({super.key});

  @override
  ConsumerState<FundsScreen> createState() => _FundsScreenState();
}

class _FundsScreenState extends ConsumerState<FundsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _historyFilter = 'ALL'; // 'ALL', 'DEPOSITS', 'WITHDRAWALS', 'PENDING'

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

    // Watch wallet transactions reactively
    final walletTxnsAsync = ref.watch(walletTransactionsListProvider);
    final walletTxns = walletTxnsAsync.valueOrNull ?? engine.walletTransactions;

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const ZeroDrawer(activeRoute: '/funds'),
      appBar: AppBar(
        backgroundColor: colors.cardBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (ctx) {
            final canPop = Navigator.of(ctx).canPop();
            if (canPop) {
              return IconButton(
                icon: Icon(Icons.arrow_back, color: colors.textPrimary, size: 24),
                onPressed: () => Navigator.of(ctx).pop(),
                tooltip: 'Back',
              );
            }
            return IconButton(
              icon: Icon(Icons.menu, color: colors.textPrimary, size: 26),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
              tooltip: 'Menu',
            );
          },
        ),
        centerTitle: true,
        title: Text(
          'Funds & Wallet',
          style: GoogleFonts.inter(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
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
                _buildSegmentView(equitySummary, ledger, walletTxns, colors, Segment.EQUITY),
                _buildSegmentView(
                    commoditySummary, ledger, walletTxns, colors, Segment.COMMODITY),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentView(
    FundsSummary summary,
    List<LedgerEntry> ledger,
    List<WalletTransaction> walletTxns,
    TradingColors colors,
    Segment segment,
  ) {
    final isHidden = ref.watch(balancePrivacyProvider);
    final avail = isHidden ? '••••••' : CurrencyFormatter.format(summary.availableMargin);
    final used = isHidden ? '••••••' : CurrencyFormatter.format(summary.usedMargin);
    final opening = isHidden ? '••••••' : CurrencyFormatter.format(summary.openingBalance);

    // Filter transactions based on current tab selection
    final filteredTxns = walletTxns.where((t) {
      if (_historyFilter == 'DEPOSITS') return t.isDeposit;
      if (_historyFilter == 'WITHDRAWALS') return t.isWithdrawal;
      if (_historyFilter == 'PENDING') return t.isPending;
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Main Balance Card ─────────────────────────────────────────────
          SectionCard(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Available Margin (${segment.name})',
                        style: AppTypography.caption(
                          color: colors.textSecondary,
                          weight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () => BalanceBreakdownDialog.show(context, segment),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.pie_chart_outline_rounded, size: 13, color: colors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Breakdown',
                              style: GoogleFonts.inter(
                                color: colors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'ADD FUNDS',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
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
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'WITHDRAW',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── Trust & Security Banner ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.divider, width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_user_outlined, size: 16, color: colors.bullish),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'SEBI Registered • 256-bit SSL • NPCI UPI • Segregated Client Funds Escrow',
                      style: GoogleFonts.inter(
                        color: colors.textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ─── Wallet Transactions History ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Wallet Activity',
                  style: GoogleFonts.inter(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '${walletTxns.length} Total',
                  style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Filter Chips (All, Deposits, Withdrawals, Pending)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('ALL', 'All', colors),
                const SizedBox(width: 8),
                _buildFilterChip('DEPOSITS', 'Deposits', colors),
                const SizedBox(width: 8),
                _buildFilterChip('WITHDRAWALS', 'Withdrawals', colors),
                const SizedBox(width: 8),
                _buildFilterChip('PENDING', 'Pending', colors),
              ],
            ),
          ),

          const SizedBox(height: 8),

          if (filteredTxns.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  'No transactions found for this filter.',
                  style: AppTypography.caption(color: colors.textSecondary),
                ),
              ),
            )
          else
            ...filteredTxns.map((txn) => _buildTransactionCard(txn, colors)),

          const SizedBox(height: 16),

          // ─── Ledger Statement Section ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12, bottom: 6),
            child: Text(
              'Funds Statement / Ledger',
              style: GoogleFonts.inter(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),

          if (ledger.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  'No ledger entries recorded.',
                  style: AppTypography.caption(color: colors.textSecondary),
                ),
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
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  '${DateFormatter.formatOrderDate(entry.date)} • Bal: ${CurrencyFormatter.format(entry.runningBalance)}',
                  style: GoogleFonts.inter(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                trailing: Text(
                  '${isCredit ? '+' : '-'}${CurrencyFormatter.format(amt)}',
                  style: GoogleFonts.inter(
                    color: amtColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, TradingColors colors) {
    final isSelected = _historyFilter == key;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _historyFilter = key),
      selectedColor: colors.primary.withValues(alpha: 0.15),
      labelStyle: GoogleFonts.inter(
        color: isSelected ? colors.primary : colors.textSecondary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
    );
  }

  Widget _buildTransactionCard(WalletTransaction txn, TradingColors colors) {
    final isDeposit = txn.isDeposit;
    final amtColor = txn.isFailed
        ? colors.bearish
        : txn.isPending
            ? colors.warning
            : isDeposit
                ? colors.bullish
                : colors.textPrimary;

    Color badgeBg;
    Color badgeText;
    switch (txn.status) {
      case WalletTransactionStatus.SUCCESS:
      case WalletTransactionStatus.COMPLETED:
        badgeBg = colors.bullish.withValues(alpha: 0.1);
        badgeText = colors.bullish;
        break;
      case WalletTransactionStatus.PENDING:
      case WalletTransactionStatus.INITIATED:
        badgeBg = colors.warning.withValues(alpha: 0.1);
        badgeText = colors.warning;
        break;
      case WalletTransactionStatus.PROCESSING:
        badgeBg = colors.primary.withValues(alpha: 0.1);
        badgeText = colors.primary;
        break;
      case WalletTransactionStatus.FAILED:
      case WalletTransactionStatus.REJECTED:
        badgeBg = colors.bearish.withValues(alpha: 0.1);
        badgeText = colors.bearish;
        break;
      case WalletTransactionStatus.CANCELLED:
        badgeBg = colors.divider.withValues(alpha: 0.2);
        badgeText = colors.textSecondary;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: colors.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colors.divider, width: 0.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => TransactionReceiptDialog.show(context, txn),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDeposit
                          ? colors.bullish.withValues(alpha: 0.1)
                          : colors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDeposit ? Icons.south_west_rounded : Icons.north_east_rounded,
                      size: 16,
                      color: isDeposit ? colors.bullish : colors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              isDeposit ? 'Deposit' : 'Withdrawal',
                              style: GoogleFonts.inter(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                txn.status.name,
                                style: GoogleFonts.inter(
                                  color: badgeText,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${txn.referenceId} • ${txn.method.name.replaceAll('_', ' ')}',
                          style: GoogleFonts.inter(
                            color: colors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isDeposit ? '+' : '-'}${CurrencyFormatter.format(txn.amount)}',
                        style: GoogleFonts.inter(
                          color: amtColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormatter.formatOrderDate(txn.createdAt),
                        style: GoogleFonts.inter(
                          color: colors.textSecondary,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Pending withdrawal cancel button
              if (txn.isWithdrawal && txn.status == WalletTransactionStatus.PENDING) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cutoff at 8:00 PM • Can be cancelled',
                      style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 11),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final engine = ref.read(orderSimulationEngineProvider);
                        try {
                          await engine.cancelWithdrawal(txn.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Withdrawal ${txn.referenceId} cancelled. Margin restored!'),
                                backgroundColor: colors.primary,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: colors.bearish),
                            );
                          }
                        }
                      },
                      icon: Icon(Icons.cancel_outlined, size: 14, color: colors.bearish),
                      label: Text(
                        'Cancel Request',
                        style: GoogleFonts.inter(
                          color: colors.bearish,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubStat(String label, String value, TradingColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
