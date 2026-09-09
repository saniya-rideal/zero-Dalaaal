import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/shared_widgets.dart';
import '../../../shared_widgets/zero_drawer.dart';

class IpoListScreen extends StatefulWidget {
  const IpoListScreen({super.key});

  @override
  State<IpoListScreen> createState() => _IpoListScreenState();
}

class _IpoListScreenState extends State<IpoListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<IpoListing> _currentIpos = [
    IpoListing(
      id: 'ipo_swiggy',
      companyName: 'Swiggy Limited',
      symbol: 'SWIGGY',
      openDate: DateTime.now().subtract(const Duration(days: 1)),
      closeDate: DateTime.now().add(const Duration(days: 2)),
      priceBandLow: 371.0,
      priceBandHigh: 390.0,
      lotSize: 38,
      gmp: 45.0,
      status: IpoStatus.CURRENT,
      description: 'Online food delivery and quick-commerce platform.',
    ),
    IpoListing(
      id: 'ipo_hyundai',
      companyName: 'Hyundai Motor India Ltd',
      symbol: 'HYUNDAI',
      openDate: DateTime.now().subtract(const Duration(days: 2)),
      closeDate: DateTime.now().add(const Duration(days: 1)),
      priceBandLow: 1865.0,
      priceBandHigh: 1960.0,
      lotSize: 7,
      gmp: 120.0,
      status: IpoStatus.CURRENT,
      description: 'Leading automobile manufacturer in India.',
    ),
  ];

  final List<IpoListing> _upcomingIpos = [
    IpoListing(
      id: 'ipo_ntpcgreen',
      companyName: 'NTPC Green Energy Ltd',
      symbol: 'NTPCGREEN',
      openDate: DateTime.now().add(const Duration(days: 10)),
      closeDate: DateTime.now().add(const Duration(days: 13)),
      priceBandLow: 102.0,
      priceBandHigh: 108.0,
      lotSize: 138,
      gmp: 18.0,
      status: IpoStatus.UPCOMING,
      description: 'Renewable energy arm of NTPC.',
    ),
  ];

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

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const ZeroDrawer(activeRoute: '/ipo'),
      appBar: AppBar(
        backgroundColor: colors.cardBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AdaptiveLeadingButton(),
        centerTitle: true,
        title: Text('Initial Public Offerings',
            style: GoogleFonts.inter(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.primary,
          indicatorWeight: 2.5,
          labelStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Current'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Closed'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Combined Market Header Strip
          const ZeroMarketHeaderStrip(),

          // Body
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildIpoList(_currentIpos, colors, isCurrent: true),
                _buildIpoList(_upcomingIpos, colors, isCurrent: false),
                _buildClosedIpos(colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIpoList(List<IpoListing> ipos, TradingColors colors,
      {required bool isCurrent}) {
    if (ipos.isEmpty) {
      return Center(
        child: Text('No IPO listings in this category',
            style: AppTypography.body(color: colors.textSecondary)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: ipos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final ipo = ipos[index];
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
                        Text(ipo.companyName,
                            style: GoogleFonts.inter(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 15)),
                        Text(ipo.symbol,
                            style: GoogleFonts.inter(
                                color: colors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  if (ipo.gmp > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
                    child: _buildSubStat('Price Band',
                        '₹${ipo.priceBandLow.toInt()} - ₹${ipo.priceBandHigh.toInt()}', colors),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildSubStat('Lot Size', '${ipo.lotSize} Shares', colors),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildSubStat('Min Investment',
                        CurrencyFormatter.format(minAmount), colors),
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
                      style: GoogleFonts.inter(
                          color: colors.textSecondary, fontSize: 11.5),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text('APPLY NOW',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClosedIpos(TradingColors colors) {
    return Center(
      child: Text('No closed IPO history available',
          style: AppTypography.body(color: colors.textSecondary)),
    );
  }

  Widget _buildSubStat(String label, String value, TradingColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
                color: colors.textSecondary, fontSize: 11)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              style: GoogleFonts.inter(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ),
      ],
    );
  }

  void _showApplyIpoDialog(IpoListing ipo) {
    final colors = context.tradingColors;
    final upiController = TextEditingController(text: 'trader@okhdfcbank');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.cardBackground,
        title: Text('Apply for ${ipo.symbol} IPO',
            style: GoogleFonts.inter(
                color: colors.textPrimary, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1 Lot = ${ipo.lotSize} shares @ ₹${ipo.priceBandHigh.toInt()}',
                style: GoogleFonts.inter(
                    color: colors.textPrimary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
                'Amount to block: ${CurrencyFormatter.format(ipo.priceBandHigh * ipo.lotSize)}',
                style: GoogleFonts.inter(
                    color: colors.marginValue, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            TextField(
              controller: upiController,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                labelText: 'UPI ID for Mandate',
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
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'IPO Application for ${ipo.symbol} submitted via UPI Mandate!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: colors.bullish),
            child: const Text('Submit Application',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
