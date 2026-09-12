import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/shared_widgets.dart';
import '../../../shared_widgets/zero_drawer.dart';
import '../../order_entry/presentation/order_entry_sheet.dart';
import 'payoff_graph_sheet.dart';

class OptionChainScreen extends StatefulWidget {
  final String underlying;

  const OptionChainScreen({super.key, this.underlying = 'NIFTY 50'});

  @override
  State<OptionChainScreen> createState() => _OptionChainScreenState();
}

class _OptionChainScreenState extends State<OptionChainScreen> {
  int _selectedExpiryIndex = 0;
  final List<String> _expiries = [
    '12 Sep',
    '19 Sep',
    '26 Sep',
    '31 Oct',
    '28 Nov'
  ];
  late List<OptionChainRow> _rows;

  @override
  void initState() {
    super.initState();
    _generateOptionChain();
  }

  void _generateOptionChain() {
    const double spot = 25150.0;
    _rows = [];

    for (int i = -10; i <= 10; i++) {
      final strike = 25150.0 + (i * 50);
      final isAtm = i == 0;

      // Mock options pricing
      final callLtp = (i < 0 ? (spot - strike) + 40.0 : 180.0 / (i + 1))
          .clamp(2.5, 950.0);
      final putLtp = (i > 0 ? (strike - spot) + 40.0 : 180.0 / (i.abs() + 1))
          .clamp(2.5, 950.0);

      _rows.add(OptionChainRow(
        strike: strike,
        isAtm: isAtm,
        call: OptionLeg(
          token: 'opt_nifty_${strike.toInt()}_ce',
          ltp: double.parse(callLtp.toStringAsFixed(2)),
          change: 8.5,
          changePercent: 4.2,
          oi: 45000 + (1000 * i.abs()),
          changeInOi: 2500,
          iv: 13.4,
          volume: 120000,
        ),
        put: OptionLeg(
          token: 'opt_nifty_${strike.toInt()}_pe',
          ltp: double.parse(putLtp.toStringAsFixed(2)),
          change: -6.2,
          changePercent: -3.1,
          oi: 52000 + (1200 * i.abs()),
          changeInOi: -1400,
          iv: 14.1,
          volume: 145000,
        ),
      ));
    }
  }

  void _showStrategyPayoff() {
    final strategy = OptionStrategy.bullCallSpread(
      underlying: widget.underlying,
      spot: 25150.0,
      expiry: _expiries[_selectedExpiryIndex],
    );
    PayoffGraphSheet.show(context, strategy: strategy);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const ZeroDrawer(activeRoute: '/option-chain'),
      appBar: AppBar(
        backgroundColor: colors.cardBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AdaptiveLeadingButton(),
        centerTitle: true,
        title: Column(
          children: [
            Text('${widget.underlying} Option Chain',
                style: GoogleFonts.inter(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            Text('Spot: 25,150.25 • Lot: 25',
                style: GoogleFonts.inter(
                    color: colors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.chartLine, color: colors.primary, size: 20),
            tooltip: 'Strategy Payoff',
            onPressed: _showStrategyPayoff,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Combined Market Header Strip
          const ZeroMarketHeaderStrip(),

          // Expiry Strip
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colors.surface,
              border:
                  Border(bottom: BorderSide(color: colors.divider, width: 0.5)),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _expiries.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedExpiryIndex == index;
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: ChoiceChip(
                    label: Text(_expiries[index]),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedExpiryIndex = index);
                      }
                    },
                    selectedColor: colors.primary.withValues(alpha: 0.2),
                    backgroundColor: colors.cardBackground,
                    labelStyle: GoogleFonts.inter(
                      color: isSelected ? colors.primary : colors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? colors.primary : colors.divider,
                        width: 1,
                      ),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              },
            ),
          ),

          // Header Table Strip
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: colors.cardBackground,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('CALLS (LTP / OI)',
                      style: GoogleFonts.inter(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('STRIKE',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('PUTS (LTP / OI)',
                      textAlign: TextAlign.end,
                      style: GoogleFonts.inter(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11)),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.divider),

          // Rows List
          Expanded(
            child: ListView.separated(
              itemCount: _rows.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 0.5, color: colors.divider.withValues(alpha: 0.5)),
              itemBuilder: (context, index) {
                final row = _rows[index];
                final isAtm = row.isAtm;

                return Container(
                  color: isAtm
                      ? colors.primary.withValues(alpha: 0.08)
                      : Colors.transparent,
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      // Call Leg (LTP + OI)
                      Expanded(
                        flex: 3,
                        child: InkWell(
                          onTap: () => _openOrderSheet(row.call, isCall: true),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(CurrencyFormatter.format(row.call.ltp),
                                  style: GoogleFonts.inter(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ])),
                              Text('OI: ${(row.call.oi / 1000).toStringAsFixed(1)}k',
                                  style: GoogleFonts.inter(
                                      color: colors.textSecondary,
                                      fontSize: 10.5)),
                            ],
                          ),
                        ),
                      ),

                      // Strike Price
                      Expanded(
                        flex: 2,
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isAtm
                                ? colors.primary.withValues(alpha: 0.15)
                                : colors.surface,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            row.strike.toInt().toString(),
                            style: GoogleFonts.inter(
                              color: isAtm ? colors.primary : colors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Put Leg (LTP + OI)
                      Expanded(
                        flex: 3,
                        child: InkWell(
                          onTap: () => _openOrderSheet(row.put, isCall: false),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(CurrencyFormatter.format(row.put.ltp),
                                  style: GoogleFonts.inter(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ])),
                              Text('OI: ${(row.put.oi / 1000).toStringAsFixed(1)}k',
                                  style: GoogleFonts.inter(
                                      color: colors.textSecondary,
                                      fontSize: 10.5)),
                            ],
                          ),
                        ),
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

  void _openOrderSheet(OptionLeg leg, {required bool isCall}) {
    final instrument = Instrument(
      token: leg.token,
      symbol:
          '${widget.underlying} ${leg.token.contains('ce') ? 'CE' : 'PE'}',
      name:
          '${widget.underlying} Options',
      exchange: Exchange.NSE,
      type: isCall ? InstrumentType.CE : InstrumentType.PE,
      lotSize: 25,
      tickSize: 0.05,
    );

    OrderEntrySheet.show(context,
        instrument: instrument, side: TransactionType.BUY);
  }
}
