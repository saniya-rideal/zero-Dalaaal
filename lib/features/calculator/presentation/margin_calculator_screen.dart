import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../data/mock/seed_instruments.dart';
import '../../../data/models/instrument.dart';
import '../../../shared_widgets/news_ticker_strip.dart';
import '../../../shared_widgets/script_selector_bar.dart';
import '../../../shared_widgets/zero_bottom_nav_bar.dart';
import '../../../shared_widgets/zero_drawer.dart';

class MarginCalculatorScreen extends StatefulWidget {
  const MarginCalculatorScreen({super.key});

  @override
  State<MarginCalculatorScreen> createState() => _MarginCalculatorScreenState();
}

class _MarginCalculatorScreenState extends State<MarginCalculatorScreen> {
  Instrument? _selectedScript;
  String _side = 'Buy';
  double _amount = 1.00;
  double _rate = 1160.60;

  @override
  void initState() {
    super.initState();
    _selectedScript = SeedInstruments.findBySymbol('COPPER MCX Sep') ??
        SeedInstruments.findByToken('mcx_copper') ??
        SeedInstruments.all.first;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final intradayMargin = (_rate * _amount * 0.002);
    final holdingMargin = (_rate * _amount * 0.02);

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const ZeroDrawer(activeRoute: '/margin-calculator'),
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu, color: colors.textPrimary, size: 26),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          'Margin Calculator',
          style: GoogleFonts.inter(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Public News & Private News Strip
          const NewsTickerStrip(),

          // Dual Script Selector Bar
          const ScriptSelectorBar(),

          // Main Inputs Scrollable List
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. SCRIPT CARD
                  _buildInputCard(
                    title: 'SCRIPT',
                    infoTooltip: 'Select the trading instrument to calculate margin requirement.',
                    colors: colors,
                    child: InkWell(
                      onTap: () => _showScriptPicker(context, colors),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedScript?.symbol ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            Icon(Icons.arrow_drop_down,
                                size: 22, color: colors.textPrimary),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 2. BUY OR SELL CARD
                  _buildInputCard(
                    title: 'BUY OR SELL',
                    infoTooltip: 'Select whether the initial trade position is a Buy or Sell.',
                    colors: colors,
                    child: InkWell(
                      onTap: () => _showSidePicker(context, colors),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _side,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            Icon(Icons.arrow_drop_down,
                                size: 22, color: colors.textPrimary),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 3. AMOUNT CARD
                  _buildInputCard(
                    title: 'AMOUNT',
                    infoTooltip: 'Number of lots / trading contracts.',
                    colors: colors,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Red Minus Button
                        InkWell(
                          onTap: () {
                            if (_amount > 0.10) {
                              setState(() => _amount -= 0.10);
                            }
                          },
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE82B57),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.remove,
                                size: 16, color: Colors.white),
                          ),
                        ),

                        // Amount Text (Tappable for exact typing)
                        InkWell(
                          onTap: () => _showAmountInputDialog(context, colors),
                          child: Text(
                            _amount.toStringAsFixed(2),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),

                        // Blue Plus Button
                        InkWell(
                          onTap: () {
                            setState(() => _amount += 0.10);
                          },
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E88E5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. MARGIN BREAKDOWN RESULT CARD
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18.0, vertical: 14.0),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // Rate Row
                        _buildBreakdownRow(
                          'Rate:',
                          _rate.toStringAsFixed(2),
                          colors,
                        ),
                        const SizedBox(height: 6),

                        // Intraday Margin Row
                        _buildBreakdownRow(
                          'Intraday Margin:',
                          intradayMargin.toStringAsFixed(2),
                          colors,
                        ),
                        const SizedBox(height: 6),

                        // Holding Margin Row
                        _buildBreakdownRow(
                          'Holding Margin:',
                          holdingMargin.toStringAsFixed(2),
                          colors,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ZeroBottomNavBar(
        currentIndex: 0,
        isExpanded: false,
        onCenterToggle: () {},
        onTabSelected: (index) {
          if (index == 0) context.go('/quotes');
          if (index == 1) context.go('/deals');
          if (index == 2) context.go('/net-deals');
          if (index == 3) context.go('/history');
        },
      ),
    );
  }

  Widget _buildInputCard({
    required String title,
    required String infoTooltip,
    required Widget child,
    required TradingColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  letterSpacing: 0.2,
                ),
              ),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(infoTooltip),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Color(0xFF1E88E5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value, TradingColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  void _showScriptPicker(BuildContext context, TradingColors colors) {
    final all = SeedInstruments.all;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Select Script',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary),
              ),
            ),
            Divider(height: 1, color: colors.divider),
            Expanded(
              child: ListView.separated(
                itemCount: all.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: colors.divider),
                itemBuilder: (ctx, index) {
                  final inst = all[index];
                  final isSelected = inst.token == _selectedScript?.token;

                  return ListTile(
                    title: Text(
                      inst.symbol,
                      style: GoogleFonts.inter(
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFF1E88E5)
                            : colors.textPrimary,
                      ),
                    ),
                    subtitle: Text('${inst.exchange.name} • ${inst.type.name}',
                        style: GoogleFonts.inter(color: colors.textSecondary)),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Color(0xFF1E88E5))
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _selectedScript = inst;
                        if (inst.symbol.toUpperCase().contains('COPPER')) {
                          _rate = 1160.60;
                        } else if (inst.symbol.toUpperCase().contains('GOLD')) {
                          _rate = 71450.00;
                        } else if (inst.symbol.toUpperCase().contains('SILVER')) {
                          _rate = 83200.00;
                        } else {
                          _rate = 1000.00;
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSidePicker(BuildContext context, TradingColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Buy',
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary)),
              trailing: _side == 'Buy'
                  ? const Icon(Icons.check, color: Color(0xFF1E88E5))
                  : null,
              onTap: () {
                setState(() => _side = 'Buy');
                Navigator.pop(context);
              },
            ),
            Divider(height: 1, color: colors.divider),
            ListTile(
              title: Text('Sell',
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary)),
              trailing: _side == 'Sell'
                  ? const Icon(Icons.check, color: Color(0xFF1E88E5))
                  : null,
              onTap: () {
                setState(() => _side = 'Sell');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAmountInputDialog(BuildContext context, TradingColors colors) {
    final controller =
        TextEditingController(text: _amount.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.cardBackground,
        title: Text('Enter Amount (Lots)',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, fontSize: 16, color: colors.textPrimary)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          style: GoogleFonts.inter(color: colors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Lots',
            labelStyle: GoogleFonts.inter(color: colors.textSecondary),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                setState(() => _amount = val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }
}
