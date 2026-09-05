import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/mock/order_simulation_engine.dart';
import '../../../data/models/transaction_record.dart';

class StatementViewDialog extends ConsumerStatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const StatementViewDialog({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
  });

  static Future<void> show(
    BuildContext context, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => StatementViewDialog(
        initialStartDate: startDate,
        initialEndDate: endDate,
      ),
    );
  }

  @override
  ConsumerState<StatementViewDialog> createState() => _StatementViewDialogState();
}

class _StatementViewDialogState extends ConsumerState<StatementViewDialog> {
  late DateTime _startDate;
  late DateTime _endDate;
  TransactionCategory? _selectedCategory;
  String _periodPreset = '30D'; // '7D', '30D', '90D', 'FY', 'CUSTOM'

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _endDate = widget.initialEndDate ?? now;
    _startDate = widget.initialStartDate ?? now.subtract(const Duration(days: 30));
  }

  void _applyPeriodPreset(String preset) {
    final now = DateTime.now();
    setState(() {
      _periodPreset = preset;
      _endDate = now;
      if (preset == '7D') {
        _startDate = now.subtract(const Duration(days: 7));
      } else if (preset == '30D') {
        _startDate = now.subtract(const Duration(days: 30));
      } else if (preset == '90D') {
        _startDate = now.subtract(const Duration(days: 90));
      } else if (preset == 'FY') {
        _startDate = DateTime(now.year, 4, 1);
        if (_startDate.isAfter(now)) {
          _startDate = DateTime(now.year - 1, 4, 1);
        }
      }
    });
  }

  Future<void> _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _periodPreset = 'CUSTOM';
      });
    }
  }

  void _exportCsv(OrderSimulationEngine engine) {
    final csvData = engine.generateStatementCsv(
      fromDate: _startDate,
      endDate: _endDate,
      category: _selectedCategory,
    );

    Clipboard.setData(ClipboardData(text: csvData));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Account statement (${csvData.split('\n').length - 2} records) copied to clipboard as CSV!'),
        backgroundColor: context.tradingColors.bullish,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _shareReport(StatementSummary summary, int count, TradingColors colors) {
    final reportText = '''
ZeroDalali Account Statement
Client: Anurag (ID: 1208160058291244)
Period: ${DateFormatter.formatOrderDate(_startDate)} to ${DateFormatter.formatOrderDate(_endDate)}
Opening Balance: ${CurrencyFormatter.format(summary.openingBalance)}
Closing Balance: ${CurrencyFormatter.format(summary.closingBalance)}
Total Credits: ${CurrencyFormatter.format(summary.totalCredits)}
Total Debits: ${CurrencyFormatter.format(summary.totalDebits)}
Taxes & Fees: ${CurrencyFormatter.format(summary.totalCharges)}
Net Cash Flow: ${CurrencyFormatter.format(summary.netCashFlow)}
Total Transactions: $count

ZeroDalali Broking Ltd • SEBI Reg: INZ000031633
''';

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Share Statement Summary',
                    style: GoogleFonts.inter(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.textSecondary, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.divider, width: 0.5),
                ),
                child: Text(
                  reportText,
                  style: GoogleFonts.robotoMono(
                    color: colors.textPrimary,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: reportText));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Statement summary copied to clipboard!')),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy Summary to Clipboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final engine = ref.watch(orderSimulationEngineProvider);
    final summary = engine.generateStatementSummary(
      fromDate: _startDate,
      toDate: _endDate,
    );

    final transactions = engine.getUnifiedTransactions(
      startDate: _startDate,
      endDate: _endDate,
      category: _selectedCategory,
      sortBy: 'DATE_ASC',
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: colors.cardBackground,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Statement',
                      style: GoogleFonts.inter(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Anurag • Demat Client ID: 1208160058291244',
                      style: GoogleFonts.inter(
                        color: colors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close, color: colors.textSecondary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Period Selector Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPeriodChip('7D', 'Last 7 Days', colors),
                  const SizedBox(width: 6),
                  _buildPeriodChip('30D', 'Last 30 Days', colors),
                  const SizedBox(width: 6),
                  _buildPeriodChip('90D', 'Last Quarter', colors),
                  const SizedBox(width: 6),
                  _buildPeriodChip('FY', 'FY 2025-26', colors),
                  const SizedBox(width: 6),
                  ActionChip(
                    avatar: Icon(Icons.date_range_rounded, size: 14, color: colors.primary),
                    label: Text(
                      _periodPreset == 'CUSTOM'
                          ? '${DateFormatter.formatOrderDate(_startDate)} - ${DateFormatter.formatOrderDate(_endDate)}'
                          : 'Custom Dates',
                      style: GoogleFonts.inter(
                        color: _periodPreset == 'CUSTOM' ? colors.primary : colors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                    onPressed: _pickCustomDateRange,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Summary Metric Banner Cards
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.divider, width: 0.5),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryStat('Opening Balance', summary.openingBalance, colors.textSecondary, colors),
                      _buildSummaryStat('Total Credits', summary.totalCredits, colors.bullish, colors),
                      _buildSummaryStat('Total Debits', summary.totalDebits, colors.bearish, colors),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryStat('Taxes & Charges', summary.totalCharges, colors.textSecondary, colors),
                      _buildSummaryStat('Net Flow', summary.netCashFlow, summary.netCashFlow >= 0 ? colors.bullish : colors.bearish, colors),
                      _buildSummaryStat('Closing Balance', summary.closingBalance, colors.primary, colors, isBold: true),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip(null, 'All Types', colors),
                  const SizedBox(width: 6),
                  _buildCategoryChip(TransactionCategory.TRADE, 'Trades', colors),
                  const SizedBox(width: 6),
                  _buildCategoryChip(TransactionCategory.DEPOSIT, 'Deposits', colors),
                  const SizedBox(width: 6),
                  _buildCategoryChip(TransactionCategory.WITHDRAWAL, 'Withdrawals', colors),
                  const SizedBox(width: 6),
                  _buildCategoryChip(TransactionCategory.FEE_CHARGE, 'Fees & Charges', colors),
                  const SizedBox(width: 6),
                  _buildCategoryChip(TransactionCategory.DIVIDEND, 'Dividends', colors),
                ],
              ),
            ),

            const SizedBox(height: 8),
            const Divider(height: 1),

            // Itemized Transaction Table / List
            Expanded(
              child: transactions.isEmpty
                  ? Center(
                      child: Text(
                        'No transactions recorded for selected period & filters.',
                        style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 13),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: transactions.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: colors.divider.withValues(alpha: 0.3)),
                      itemBuilder: (context, index) {
                        final txn = transactions[index];
                        final isCredit = txn.isCredit;
                        final amtColor = isCredit ? colors.bullish : colors.bearish;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date column
                              SizedBox(
                                width: 75,
                                child: Text(
                                  DateFormatter.formatOrderDate(txn.timestamp),
                                  style: GoogleFonts.inter(
                                    color: colors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Narration & ID
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      txn.title,
                                      style: GoogleFonts.inter(
                                        color: colors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    Text(
                                      '${txn.id} • ${txn.narration}',
                                      style: GoogleFonts.inter(
                                        color: colors.textSecondary,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Amount & Running Balance
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${isCredit ? '+' : '-'}${CurrencyFormatter.format(txn.amount)}',
                                    style: GoogleFonts.inter(
                                      color: amtColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                  Text(
                                    'Bal: ${CurrencyFormatter.format(txn.runningBalance)}',
                                    style: GoogleFonts.inter(
                                      color: colors.textSecondary,
                                      fontSize: 10.5,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Action Buttons (Export CSV, Share Statement)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _exportCsv(engine),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Export CSV'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.primary,
                      side: BorderSide(color: colors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareReport(summary, transactions.length, colors),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String key, String label, TradingColors colors) {
    final isSelected = _periodPreset == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: colors.primary.withValues(alpha: 0.15),
      labelStyle: GoogleFonts.inter(
        color: isSelected ? colors.primary : colors.textSecondary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 11.5,
      ),
      onSelected: (_) => _applyPeriodPreset(key),
    );
  }

  Widget _buildCategoryChip(TransactionCategory? cat, String label, TradingColors colors) {
    final isSelected = _selectedCategory == cat;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: colors.primary.withValues(alpha: 0.15),
      labelStyle: GoogleFonts.inter(
        color: isSelected ? colors.primary : colors.textSecondary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 11.5,
      ),
      onSelected: (_) => setState(() => _selectedCategory = cat),
    );
  }

  Widget _buildSummaryStat(
    String label,
    double value,
    Color valueColor,
    TradingColors colors, {
    bool isBold = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: colors.textSecondary,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          CurrencyFormatter.format(value),
          style: GoogleFonts.inter(
            color: valueColor,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            fontSize: 12.5,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
