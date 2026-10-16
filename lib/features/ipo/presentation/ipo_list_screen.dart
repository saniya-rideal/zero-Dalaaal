import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/ipo.dart';
import '../../../shared_widgets/shared_widgets.dart';
import '../../../shared_widgets/zero_drawer.dart';
import '../data/ipo_repository.dart';

final ipoListProvider = FutureProvider.autoDispose<List<IpoListing>>((ref) async {
  final repo = ref.watch(ipoRepositoryProvider);
  return repo.getIpos();
});

final ipoApplicationsProvider = FutureProvider.autoDispose<List<IpoApplication>>((ref) async {
  final repo = ref.watch(ipoRepositoryProvider);
  return repo.getApplications();
});

class IpoListScreen extends ConsumerStatefulWidget {
  const IpoListScreen({super.key});

  @override
  ConsumerState<IpoListScreen> createState() => _IpoListScreenState();
}

class _IpoListScreenState extends ConsumerState<IpoListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final iposAsync = ref.watch(ipoListProvider);
    final applicationsAsync = ref.watch(ipoApplicationsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const ZeroDrawer(activeRoute: '/ipo'),
      appBar: AppBar(
        backgroundColor: colors.cardBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AdaptiveLeadingButton(),
        centerTitle: true,
        title: Text(
          'Initial Public Offerings',
          style: GoogleFonts.inter(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.primary,
          indicatorWeight: 2.5,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Current'),
            Tab(text: 'Upcoming'),
            Tab(text: 'My Bids'),
          ],
        ),
      ),
      body: Column(
        children: [
          const ZeroMarketHeaderStrip(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildIpoTab(iposAsync, colors, targetStatus: IpoStatus.CURRENT),
                _buildIpoTab(iposAsync, colors, targetStatus: IpoStatus.UPCOMING),
                _buildApplicationsTab(applicationsAsync, colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIpoTab(
    AsyncValue<List<IpoListing>> iposAsync,
    TradingColors colors, {
    required IpoStatus targetStatus,
  }) {
    return iposAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.alertTriangle, size: 40, color: colors.loss),
              const SizedBox(height: 12),
              Text('Failed to load IPOs', style: TextStyle(color: colors.textPrimary)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(ipoListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (allIpos) {
        final filtered = allIpos.where((i) => i.status == targetStatus).toList();
        if (filtered.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(ipoListProvider.future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                Center(
                  child: Text(
                    targetStatus == IpoStatus.CURRENT
                        ? 'No open IPOs at this time'
                        : 'No upcoming IPOs scheduled',
                    style: AppTypography.body(color: colors.textSecondary),
                  ),
                ),
              ],
            ),
          );
        }

        final isCurrent = targetStatus == IpoStatus.CURRENT;
        return RefreshIndicator(
          onRefresh: () async => ref.refresh(ipoListProvider.future),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final ipo = filtered[index];
              final minAmount = ipo.priceBandHigh * ipo.lotSize;

              return SectionCard(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ipo.companyName,
                                style: GoogleFonts.inter(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                ipo.symbol,
                                style: GoogleFonts.inter(
                                  color: colors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (ipo.gmp > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: colors.bullish.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'GMP +₹${ipo.gmp.toInt()}',
                              style: GoogleFonts.inter(
                                color: colors.bullish,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSubStat(
                            'Price Band',
                            '₹${ipo.priceBandLow.toInt()} - ₹${ipo.priceBandHigh.toInt()}',
                            colors,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildSubStat('Lot Size', '${ipo.lotSize} Shares', colors),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildSubStat('Min Investment', CurrencyFormatter.format(minAmount), colors),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Dates: ${DateFormatter.formatOrderDate(ipo.openDate)} - ${DateFormatter.formatOrderDate(ipo.closeDate)}',
                            style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 11.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _showApplyIpoDialog(ipo),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.bullish,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text('APPLY NOW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildApplicationsTab(
    AsyncValue<List<IpoApplication>> applicationsAsync,
    TradingColors colors,
  ) {
    return applicationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.alertTriangle, size: 40, color: colors.loss),
              const SizedBox(height: 12),
              Text('Failed to load applications', style: TextStyle(color: colors.textPrimary)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(ipoApplicationsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (apps) {
        if (apps.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(ipoApplicationsProvider.future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                Center(
                  child: Text('No IPO applications submitted yet', style: AppTypography.body(color: colors.textSecondary)),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(ipoApplicationsProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: apps.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final app = apps[index];
              return SectionCard(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.ipo.symbol,
                            style: GoogleFonts.inter(color: colors.textPrimary, fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${app.lots} Lot (${app.lots * app.ipo.lotSize} Shares) • UPI: ${app.upiId}',
                            style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Status: ${app.status.name}',
                            style: GoogleFonts.inter(
                              color: app.status == ApplicationStatus.ALLOTTED ? colors.bullish : colors.warning,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (app.status == ApplicationStatus.APPLIED)
                      IconButton(
                        icon: Icon(LucideIcons.trash2, size: 18, color: colors.bearish),
                        onPressed: () async {
                          try {
                            await ref.read(ipoRepositoryProvider).cancelApplication(app.id);
                            ref.invalidate(ipoApplicationsProvider);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('IPO bid cancelled and funds refunded')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to cancel bid: $e')),
                              );
                            }
                          }
                        },
                        tooltip: 'Cancel Bid',
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSubStat(String label, String value, TradingColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: GoogleFonts.inter(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  void _showApplyIpoDialog(IpoListing ipo) {
    final colors = context.tradingColors;
    final upiController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: colors.cardBackground,
          title: Text(
            'Apply for ${ipo.symbol} IPO',
            style: GoogleFonts.inter(color: colors.textPrimary, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1 Lot = ${ipo.lotSize} shares @ ₹${ipo.priceBandHigh.toInt()}',
                style: GoogleFonts.inter(color: colors.textPrimary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Amount to block: ${CurrencyFormatter.format(ipo.priceBandHigh * ipo.lotSize)}',
                style: GoogleFonts.inter(color: colors.marginValue, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: upiController,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'UPI ID for Mandate',
                  hintText: 'e.g. yourname@okhdfcbank',
                  hintStyle: TextStyle(color: colors.textSecondary),
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
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final upi = upiController.text.trim();
                      if (upi.isEmpty || !upi.contains('@')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid UPI ID (e.g. user@bank)')),
                        );
                        return;
                      }

                      setDialogState(() => isSubmitting = true);
                      try {
                        await ref.read(ipoRepositoryProvider).applyIpo(
                              id: ipo.id,
                              lots: 1,
                              bidPrice: ipo.priceBandHigh,
                              upiId: upi,
                            );
                        if (!mounted) return;
                        ref.invalidate(ipoApplicationsProvider);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('IPO Application for ${ipo.symbol} submitted successfully!')),
                        );
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to submit application: $e')),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: colors.bullish),
              child: isSubmitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit Application', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
