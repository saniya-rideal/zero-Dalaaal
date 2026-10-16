import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/shared_widgets.dart';
import '../../../shared_widgets/zero_drawer.dart';
import '../../order_entry/presentation/order_entry_sheet.dart';
import '../data/option_chain_repository.dart';
import 'payoff_graph_sheet.dart';

class OptionChainScreen extends ConsumerStatefulWidget {
  final String underlying;

  const OptionChainScreen({super.key, this.underlying = 'NIFTY 50'});

  @override
  ConsumerState<OptionChainScreen> createState() => _OptionChainScreenState();
}

class _OptionChainScreenState extends ConsumerState<OptionChainScreen> {
  int _selectedExpiryIndex = 0;
  List<String> _expiries = [];
  List<OptionChainRow> _rows = [];
  double _underlyingPrice = 0.0;

  bool _isLoading = true;
  String? _errorMessage;

  String get _cleanSymbol {
    return widget.underlying
        .replaceAll(' 50', '')
        .replaceAll(' BANK', 'BANK')
        .replaceAll(' ', '')
        .toUpperCase();
  }

  int get _lotSize {
    final sym = _cleanSymbol;
    if (sym == 'BANKNIFTY') return 15;
    if (sym == 'FINNIFTY') return 25;
    return 25;
  }

  @override
  void initState() {
    super.initState();
    _loadOptionChainData();
  }

  Future<void> _loadOptionChainData({bool refreshExpiries = true}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(optionChainRepositoryProvider);
      final sym = _cleanSymbol;

      if (refreshExpiries || _expiries.isEmpty) {
        final expiries = await repo.getExpiries(sym);
        _expiries = expiries;
        if (_expiries.isNotEmpty && _selectedExpiryIndex >= _expiries.length) {
          _selectedExpiryIndex = 0;
        }
      }

      final currentExpiry = _expiries.isNotEmpty && _selectedExpiryIndex < _expiries.length
          ? _expiries[_selectedExpiryIndex]
          : null;

      final chainData = await repo.getOptionChain(sym, expiry: currentExpiry);

      if (mounted) {
        setState(() {
          _rows = chainData.rows;
          _underlyingPrice = chainData.underlyingPrice;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onExpirySelected(int index) {
    if (index == _selectedExpiryIndex) return;
    setState(() {
      _selectedExpiryIndex = index;
    });
    _loadOptionChainData(refreshExpiries: false);
  }

  void _showStrategyPayoff() {
    final currentExpiry = _expiries.isNotEmpty && _selectedExpiryIndex < _expiries.length
        ? _expiries[_selectedExpiryIndex]
        : 'Near Expiry';

    final strategy = OptionStrategy.bullCallSpread(
      underlying: _cleanSymbol,
      spot: _underlyingPrice > 0 ? _underlyingPrice : 24000.0,
      expiry: currentExpiry,
      lotSize: _lotSize,
    );
    PayoffGraphSheet.show(context, strategy: strategy);
  }

  void _openOrderSheet(OptionChainRow row, OptionLeg leg, {required bool isCall}) {
    final strikeStr = row.strike.toInt().toString();
    final typeStr = isCall ? 'CE' : 'PE';
    final token = leg.token.isNotEmpty ? leg.token : '${_cleanSymbol}_${strikeStr}_$typeStr';
    final symbol = leg.token.isNotEmpty ? leg.token : '$_cleanSymbol $strikeStr $typeStr';

    final instrument = Instrument(
      token: token,
      symbol: symbol,
      name: '$_cleanSymbol $strikeStr ${isCall ? 'Call' : 'Put'}',
      exchange: Exchange.NSE,
      type: isCall ? InstrumentType.CE : InstrumentType.PE,
      lotSize: _lotSize.toDouble(),
      tickSize: 0.05,
    );

    OrderEntrySheet.show(context, instrument: instrument, side: TransactionType.BUY);
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
            Text(
              '${widget.underlying} Option Chain',
              style: GoogleFonts.inter(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            Text(
              _underlyingPrice > 0
                  ? 'Spot: ${CurrencyFormatter.format(_underlyingPrice)} • Lot: $_lotSize'
                  : 'Spot: -- • Lot: $_lotSize',
              style: GoogleFonts.inter(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.refreshCw, color: colors.textSecondary, size: 18),
            tooltip: 'Live Refresh',
            onPressed: () => _loadOptionChainData(refreshExpiries: true),
          ),
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

          // Expiry Selection Strip
          if (_expiries.isNotEmpty)
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(bottom: BorderSide(color: colors.divider, width: 0.5)),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _expiries.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedExpiryIndex == index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: ChoiceChip(
                      label: Text(_expiries[index]),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          _onExpirySelected(index);
                        }
                      },
                      selectedColor: colors.primary.withValues(alpha: 0.2),
                      backgroundColor: colors.cardBackground,
                      labelStyle: GoogleFonts.inter(
                        color: isSelected ? colors.primary : colors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
                  child: Text(
                    'CALLS (LTP / OI)',
                    style: GoogleFonts.inter(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'STRIKE',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'PUTS (LTP / OI)',
                    textAlign: TextAlign.end,
                    style: GoogleFonts.inter(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.divider),

          // Body Content: Loading / Error / Empty / Rows List
          Expanded(
            child: _buildBody(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(TradingColors colors) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: colors.primary),
            const SizedBox(height: 12),
            Text(
              'Loading option chain...',
              style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.alertTriangle, size: 48, color: colors.loss),
              const SizedBox(height: 12),
              Text(
                'Failed to load option chain',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _loadOptionChainData(refreshExpiries: true),
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_rows.isEmpty) {
      final expiryLabel = _expiries.isNotEmpty && _selectedExpiryIndex < _expiries.length
          ? _expiries[_selectedExpiryIndex]
          : 'selected expiry';

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.layers, size: 44, color: colors.textSecondary),
              const SizedBox(height: 12),
              Text(
                'No Option Contracts',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'No strikes available for $expiryLabel.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _loadOptionChainData(refreshExpiries: true),
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadOptionChainData(refreshExpiries: false),
      child: ListView.separated(
        itemCount: _rows.length,
        separatorBuilder: (context, index) =>
            Divider(height: 0.5, color: colors.divider.withValues(alpha: 0.5)),
        itemBuilder: (context, index) {
          final row = _rows[index];
          final isAtm = row.isAtm;

          return Container(
            color: isAtm ? colors.primary.withValues(alpha: 0.08) : Colors.transparent,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                // Call Leg (LTP + OI)
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: () => _openOrderSheet(row, row.call, isCall: true),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          CurrencyFormatter.format(row.call.ltp),
                          style: GoogleFonts.inter(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          'OI: ${(row.call.oi / 1000).toStringAsFixed(1)}k',
                          style: GoogleFonts.inter(
                            color: colors.textSecondary,
                            fontSize: 10.5,
                          ),
                        ),
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
                      color: isAtm ? colors.primary.withValues(alpha: 0.15) : colors.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      row.strike.toInt().toString(),
                      style: GoogleFonts.inter(
                        color: isAtm ? colors.primary : colors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),

                // Put Leg (LTP + OI)
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: () => _openOrderSheet(row, row.put, isCall: false),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(row.put.ltp),
                          style: GoogleFonts.inter(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          'OI: ${(row.put.oi / 1000).toStringAsFixed(1)}k',
                          style: GoogleFonts.inter(
                            color: colors.textSecondary,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
