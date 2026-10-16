import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/sip.dart';
import '../../../shared_widgets/shared_widgets.dart';
import '../../../shared_widgets/zero_drawer.dart';
import '../data/sip_repository.dart';

final sipListProvider = FutureProvider.autoDispose<List<Sip>>((ref) async {
  final repo = ref.watch(sipRepositoryProvider);
  return repo.getSips();
});

class SipScreen extends ConsumerStatefulWidget {
  const SipScreen({super.key});

  @override
  ConsumerState<SipScreen> createState() => _SipScreenState();
}

class _SipScreenState extends ConsumerState<SipScreen> {
  final Set<String> _loadingSipIds = {};

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final sipsAsync = ref.watch(sipListProvider);

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const ZeroDrawer(activeRoute: '/sip'),
      appBar: AppBar(
        backgroundColor: colors.cardBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AdaptiveLeadingButton(),
        centerTitle: true,
        title: Text(
          'Stock SIPs',
          style: GoogleFonts.inter(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
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
          const ZeroMarketHeaderStrip(),
          Expanded(
            child: sipsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.alertTriangle, size: 48, color: colors.loss),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load SIPs',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        err.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => ref.invalidate(sipListProvider),
                        icon: const Icon(LucideIcons.refreshCw, size: 16),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (sips) {
                if (sips.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async => ref.refresh(sipListProvider.future),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                        EmptyStateView(
                          icon: LucideIcons.calendar,
                          title: 'No Active SIPs',
                          subtitle:
                              'Automate recurring investments in high quality stocks with Systematic Investment Plans.',
                          buttonText: 'Create Stock SIP',
                          onButtonPressed: _showCreateSipDialog,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(sipListProvider.future),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    itemCount: sips.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final sip = sips[index];
                      final isActive = sip.status == SipStatus.ACTIVE;
                      final isLoading = _loadingSipIds.contains(sip.id);

                      return SectionCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Text(
                                        sip.instrument.symbol,
                                        style: GoogleFonts.inter(
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? colors.bullish.withValues(alpha: 0.1)
                                              : colors.warning.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          sip.status.name,
                                          style: GoogleFonts.inter(
                                            color: isActive ? colors.bullish : colors.warning,
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
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${sip.frequency.name} • Completed: ${sip.completedInstallments}/${sip.totalInstallments} installments',
                              style: GoogleFonts.inter(
                                color: colors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: isLoading ? null : () => _toggleSipPause(sip),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: colors.textPrimary,
                                      side: BorderSide(color: colors.divider),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                            height: 14,
                                            width: 14,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : Text(
                                            isActive ? 'PAUSE SIP' : 'RESUME SIP',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(LucideIcons.trash2, color: colors.bearish, size: 18),
                                  onPressed: isLoading ? null : () => _deleteSip(sip.id),
                                  tooltip: 'Delete SIP',
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSipPause(Sip sip) async {
    setState(() => _loadingSipIds.add(sip.id));
    try {
      if (sip.status == SipStatus.ACTIVE) {
        await ref.read(sipRepositoryProvider).pauseSip(sip.id);
      } else {
        await ref.read(sipRepositoryProvider).resumeSip(sip.id);
      }
      ref.invalidate(sipListProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update SIP: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingSipIds.remove(sip.id));
    }
  }

  Future<void> _deleteSip(String id) async {
    try {
      await ref.read(sipRepositoryProvider).deleteSip(id);
      ref.invalidate(sipListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock SIP cancelled successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete SIP: $e')),
        );
      }
    }
  }

  void _showCreateSipDialog() {
    final colors = context.tradingColors;
    final symbolController = TextEditingController(text: 'RELIANCE');
    final amountController = TextEditingController(text: '5000');
    String frequency = 'MONTHLY';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: colors.cardBackground,
          title: Text(
            'Create Stock SIP',
            style: GoogleFonts.inter(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: symbolController,
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Symbol',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: frequency,
                  dropdownColor: colors.cardBackground,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'MONTHLY', child: Text('Monthly')),
                    DropdownMenuItem(value: 'WEEKLY', child: Text('Weekly')),
                    DropdownMenuItem(value: 'DAILY', child: Text('Daily')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => frequency = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: colors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Installment Amount (₹)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final sym = symbolController.text.trim().toUpperCase();
                      final amt = double.tryParse(amountController.text) ?? 0.0;
                      if (sym.isEmpty || amt <= 0) return;

                      setDialogState(() => isSubmitting = true);
                      try {
                        await ref.read(sipRepositoryProvider).createSip(
                              symbol: sym,
                              frequency: frequency,
                              amount: amt,
                            );
                        if (!mounted) return;
                        ref.invalidate(sipListProvider);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$frequency Stock SIP of ₹${amt.toInt()} for $sym started!')),
                        );
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to start SIP: $e')),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: colors.primary),
              child: isSubmitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Start SIP', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
