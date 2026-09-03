import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/news_ticker_strip.dart';
import '../../../shared_widgets/script_selector_bar.dart';
import '../../../shared_widgets/zero_drawer.dart';
import '../../order_entry/presentation/order_entry_sheet.dart';

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
      final callLtp = (i < 0
              ? (spot - strike) + 40.0
              : 180.0 / (i + 1))
          .clamp(2.5, 950.0);
      final putLtp = (i > 0
              ? (strike - spot) + 40.0
              : 180.0 / (i.abs() + 1))
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
        leading: Builder(
          builder: (innerContext) => IconButton(
            icon: Icon(Icons.menu, color: colors.textPrimary, size: 26),
            onPressed: () => Scaffold.of(innerContext).openDrawer(),
          ),
        ),
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
      ),
      body: Column(
        children: [
          // Public & Private News Ticker Strip
          const NewsTickerStrip(),

          // Dual Script Selector Bar
          const ScriptSelectorBar(),

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
                    label: Text(_expiries[index],
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: isSelected
                                ? Colors.white
                                : colors.textPrimary)),
                    selected: isSelected,
                    selectedColor: colors.primary,
                    backgroundColor: colors.cardBackground,
                    onSelected: (_) =>
                        setState(() => _selectedExpiryIndex = index),
                  ),
                );
              },
            ),
          ),

          // Option Chain Header (CALLS | STRIKE | PUTS)
          Container(
            height: 32,
            color: colors.scriptBarBackground,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('CALLS (CE)',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          color: colors.bullish,
                          fontWeight: FontWeight.w800,
                          fontSize: 11)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('STRIKE',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 11)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('PUTS (PE)',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          color: colors.bearish,
                          fontWeight: FontWeight.w800,
                          fontSize: 11)),
                ),
              ],
            ),
          ),

          // Option Chain Rows
          Expanded(
            child: ListView.separated(
              itemCount: _rows.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: colors.divider),
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
