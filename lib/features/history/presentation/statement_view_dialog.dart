import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/funds.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../funds/data/real_funds_repository.dart';

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
        final currentYear = now.month >= 4 ? now.year : now.year - 1;
        _startDate = DateTime(currentYear, 4, 1);
        _endDate = DateTime(currentYear + 1, 3, 31, 23, 59, 59);
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

  void _exportCsv(List<LedgerEntry> entries) {
    final buffer = StringBuffer();
    buffer.writeln('Date,ID,Narration,Debit,Credit,RunningBalance');
    for (final e in entries) {
      buffer.writeln('${e.date.toIso8601String()},${e.id},"${e.narration}",${e.debit.toStringAsFixed(2)},${e.credit.toStringAsFixed(2)},${e.runningBalance.toStringAsFixed(2)}');
    }
    final csvData = buffer.toString();
    Clipboard.setData(ClipboardData(text: csvData));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Account statement (${entries.length} records) copied to clipboard as CSV!'),
        backgroundColor: context.tradingColors.bullish,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _shareReport({
    required double opening,
    required double closing,
    required double credits,
    required double debits,
    required int count,
    required TradingColors colors,
  }) {
    final profile = ref.read(authControllerProvider).session?.profile;
    final clientName = (profile?.name.isNotEmpty ?? false) ? profile!.name : 'Client';
    final clientId = profile?.userId ?? '-';

    final reportText = '''
ZeroDalali Digital Account Statement
Client: $clientName (ID: $clientId)
Period: ${DateFormatter.formatOrderDate(_startDate)} to ${DateFormatter.formatOrderDate(_endDate)}
Opening Balance: ${CurrencyFormatter.format(opening)}
Closing Balance: ${CurrencyFormatter.format(closing)}
Total Credits: ${CurrencyFormatter.format(credits)}
Total Debits: ${CurrencyFormatter.format(debits)}
Net Flow: ${CurrencyFormatter.format(credits - debits)}
Total Ledger Entries: $count
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
                    icon: Icon(LucideIcons.x, color: colors.textSecondary, size: 20),
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
                icon: const Icon(LucideIcons.copy, size: 18),
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
    final ledgerAsync = ref.watch(walletLedgerProvider);

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
                    Builder(
                      builder: (_) {
                        final profile = ref.watch(authControllerProvider).session?.profile;
                        final sub = (profile != null && profile.name.isNotEmpty)
                            ? '${profile.name} • Client ID: ${profile.userId}'
                            : (profile != null ? 'Client ID: ${profile.userId}' : 'Account Statement');
                        return Text(
                          sub,
                          style: GoogleFonts.inter(
                            color: colors.textSecondary,
                            fontSize: 11.5,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(LucideIcons.x, color: colors.textSecondary, size: 20),
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
                    avatar: Icon(LucideIcons.calendar, size: 14, color: colors.primary),
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

            Expanded(
              child: ledgerAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Text('Failed to load ledger: $err', style: TextStyle(color: colors.loss)),
                ),
                data: (allEntries) {
                  // Filter by date range
                  final entries = allEntries.where((e) {
                    final inRange = e.date.isAfter(_startDate.subtract(const Duration(seconds: 1))) &&
                        e.date.isBefore(_endDate.add(const Duration(seconds: 1)));
                    return inRange;
                  }).toList();

                  double totalCredits = 0.0;
                  double totalDebits = 0.0;
                  for (final e in entries) {
                    totalCredits += e.credit;
                    totalDebits += e.debit;
                  }
                  final opening = entries.isNotEmpty ? (entries.last.runningBalance - entries.last.credit + entries.last.debit) : 0.0;
                  final closing = entries.isNotEmpty ? entries.first.runningBalance : 0.0;

                  return Column(
                    children: [
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
                                _buildSummaryStat('Opening Balance', opening, colors.textSecondary, colors),
                                _buildSummaryStat('Total Credits', totalCredits, colors.bullish, colors),
                                _buildSummaryStat('Total Debits', totalDebits, colors.bearish, colors),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSummaryStat('Net Flow', totalCredits - totalDebits, totalCredits >= totalDebits ? colors.bullish : colors.bearish, colors),
                                _buildSummaryStat('Closing Balance', closing, colors.primary, colors, isBold: true),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),
                      const Divider(height: 1),

                      // Itemized Ledger List
                      Expanded(
                        child: entries.isEmpty
                            ? Center(
                                child: Text(
                                  'No transactions recorded for selected period.',
                                  style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 13),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                itemCount: entries.length,
                                separatorBuilder: (_, __) => Divider(height: 1, color: colors.divider.withValues(alpha: 0.3)),
                                itemBuilder: (context, index) {
                                  final item = entries[index];
                                  final isCredit = item.credit > 0;
                                  final amtColor = isCredit ? colors.bullish : colors.bearish;
                                  final amt = isCredit ? item.credit : item.debit;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 75,
                                          child: Text(
                                            DateFormatter.formatOrderDate(item.date),
                                            style: GoogleFonts.inter(
                                              color: colors.textSecondary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.narration.isNotEmpty ? item.narration : 'Transaction',
                                                style: GoogleFonts.inter(
                                                  color: colors.textPrimary,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                              Text(
                                                item.id,
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
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${isCredit ? '+' : '-'}${CurrencyFormatter.format(amt)}',
                                              style: GoogleFonts.inter(
                                                color: amtColor,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 12.5,
                                                fontFeatures: const [FontFeature.tabularFigures()],
                                              ),
                                            ),
                                            Text(
                                              'Bal: ${CurrencyFormatter.format(item.runningBalance)}',
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
                              onPressed: () => _exportCsv(entries),
                              icon: const Icon(LucideIcons.download, size: 18),
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
                              onPressed: () => _shareReport(
                                opening: opening,
                                closing: closing,
                                credits: totalCredits,
                                debits: totalDebits,
                                count: entries.length,
                                colors: colors,
                              ),
                              icon: const Icon(LucideIcons.share2, size: 18),
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
                  );
                },
              ),
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
