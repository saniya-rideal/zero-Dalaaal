import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/mock/seed_instruments.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/shared_widgets.dart';
import '../../../shared_widgets/zero_drawer.dart';

class SipScreen extends StatefulWidget {
  const SipScreen({super.key});

  @override
  State<SipScreen> createState() => _SipScreenState();
}

class _SipScreenState extends State<SipScreen> {
  final List<Sip> _sips = [
    Sip(
      id: 'sip_1',
      instrument: SeedInstruments.findByToken('eq_reliance')!,
      amount: 5000.0,
      frequency: SipFrequency.MONTHLY,
      startDate: DateTime.now().subtract(const Duration(days: 60)),
      totalInstallments: 12,
      completedInstallments: 2,
      status: SipStatus.ACTIVE,
    ),
    Sip(
      id: 'sip_2',
      instrument: SeedInstruments.findByToken('eq_tcs')!,
      amount: 4000.0,
      frequency: SipFrequency.WEEKLY,
      startDate: DateTime.now().subtract(const Duration(days: 28)),
      totalInstallments: 24,
      completedInstallments: 4,
      status: SipStatus.ACTIVE,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const ZeroDrawer(activeRoute: '/sip'),
      appBar: AppBar(
        backgroundColor: colors.cardBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AdaptiveLeadingButton(),
        centerTitle: true,
        title: Text('Stock SIPs',
            style: GoogleFonts.inter(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.plus, color: colors.primary, size: 22),
            onPressed: _showCreateSipDialog,
            tooltip: 'Create SIP',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Combined Market Header Strip
          const ZeroMarketHeaderStrip(),

          // Body
          Expanded(
            child: _sips.isEmpty
                ? EmptyStateView(
                    icon: LucideIcons.calendar,
                    title: 'No Active SIPs',
                    subtitle:
                        'Automate recurring investments in high quality stocks with Systematic Investment Plans.',
                    buttonText: 'Create Stock SIP',
                    onButtonPressed: _showCreateSipDialog,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: _sips.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final sip = _sips[index];
                      final isActive = sip.status == SipStatus.ACTIVE;

                      return SectionCard(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(sip.instrument.symbol,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                                color: colors.textPrimary,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15)),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: (isActive
                                                  ? colors.bullish
                                                  : colors.warning)
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          sip.status.name,
                                          style: GoogleFonts.inter(
                                            color: isActive
                                                ? colors.bullish
                                                : colors.warning,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  CurrencyFormatter.format(sip.amount),
                                  style: GoogleFonts.inter(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${sip.frequency.name} • Completed: ${sip.completedInstallments}/${sip.totalInstallments} installments',
                              style: GoogleFonts.inter(
                                  color: colors.textSecondary, fontSize: 12),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _sips[index] = sip.copyWith(
                                          status: isActive
                                              ? SipStatus.PAUSED
                                              : SipStatus.ACTIVE,
                                        );
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: colors.textPrimary,
                                      side: BorderSide(color: colors.divider),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                    ),
                                    child: Text(
                                        isActive ? 'PAUSE SIP' : 'RESUME SIP',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(LucideIcons.trash2,
                                      color: colors.bearish, size: 18),
                                  onPressed: () {
                                    setState(() => _sips.removeAt(index));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Stock SIP cancelled')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showCreateSipDialog() {
    final colors = context.tradingColors;
    final amountController = TextEditingController(text: '5000');
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.cardBackground,
        title: Text('Create Stock SIP',
            style: GoogleFonts.inter(
                color: colors.textPrimary, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Installment Amount (₹)',
                labelStyle: TextStyle(color: colors.textSecondary),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (isSubmitting) return;
              isSubmitting = true;
              final amt = double.tryParse(amountController.text) ?? 5000.0;
              setState(() {
                _sips.add(Sip(
                  id: 'sip_${DateTime.now().millisecondsSinceEpoch}',
                  instrument: SeedInstruments.findByToken('eq_infy')!,
                  amount: amt,
                  frequency: SipFrequency.MONTHLY,
                  startDate: DateTime.now(),
                  totalInstallments: 12,
                  completedInstallments: 0,
                  status: SipStatus.ACTIVE,
                ));
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Monthly Stock SIP of ₹${amt.toInt()} started successfully!'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: colors.primary),
            child: const Text('Start SIP',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
