import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../data/models/instrument.dart';
import '../../market/data/real_market_repository.dart';
import '../../../shared_widgets/news_ticker_strip.dart';
import '../../../shared_widgets/script_selector_bar.dart';
import '../../../shared_widgets/zero_bottom_nav_bar.dart';
import '../../../shared_widgets/zero_drawer.dart';

class ProfitCalculatorScreen extends ConsumerStatefulWidget {
  const ProfitCalculatorScreen({super.key});

  @override
  ConsumerState<ProfitCalculatorScreen> createState() => _ProfitCalculatorScreenState();
}

class _ProfitCalculatorScreenState extends ConsumerState<ProfitCalculatorScreen> {
  Instrument? _selectedScript;
  String _side = 'Buy';
  double _openPrice = 1156.20;
  double _closePrice = 1156.90;
  double _tradeSize = 1.00;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final repo = ref.read(marketRepositoryProvider);
      final loaded = repo.cachedInstruments;
      if (loaded.isNotEmpty) {
        setState(() => _selectedScript = loaded.first);
      } else {
        repo.getInstruments().then((list) {
          if (mounted && list.isNotEmpty) {
            setState(() => _selectedScript = list.first);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final isBuy = _side == 'Buy';
    final rawProfit = isBuy
        ? (_closePrice - _openPrice) * _tradeSize
        : (_openPrice - _closePrice) * _tradeSize;
    final profitDisplay = rawProfit.toStringAsFixed(2);

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const ZeroDrawer(activeRoute: '/profit-calculator'),
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (ctx) {
            final canPop = Navigator.of(ctx).canPop();
            if (canPop) {
              return IconButton(
                icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary, size: 22),
                onPressed: () => Navigator.of(ctx).pop(),
                tooltip: 'Back',
              );
            }
            return IconButton(
              icon: Icon(LucideIcons.menu, color: colors.textPrimary, size: 24),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
              tooltip: 'Menu',
            );
          },
        ),
        title: Text(
          'Profit Calculator',
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
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. SCRIPT CARD
                  _buildInputCard(
                    title: 'SCRIPT',
                    infoTooltip: 'Select the trading instrument / script to calculate profit.',
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
                            Icon(LucideIcons.chevronDown,
                                size: 18, color: colors.textPrimary),
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
                            Icon(LucideIcons.chevronDown,
                                size: 18, color: colors.textPrimary),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 3. OPEN PRICE CARD
                  _buildInputCard(
                    title: 'OPEN PRICE',
                    infoTooltip: 'The entry/execution price when the order was opened.',
                    colors: colors,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Red Minus Button
                        InkWell(
                          onTap: () {
                            if (_openPrice > 0.1) {
                              setState(() => _openPrice -= 0.10);
                            }
                          },
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE82B57),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.minus,
                                size: 14, color: Colors.white),
                          ),
                        ),

                        // Open Price Text
                        InkWell(
                          onTap: () => _showPriceInputDialog(
                              context, 'Open Price', _openPrice, colors, (val) {
                            setState(() => _openPrice = val);
                          }),
                          child: Text(
                            _openPrice.toStringAsFixed(2),
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
                            setState(() => _openPrice += 0.10);
                          },
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E88E5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.plus,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 4. CLOSE PRICE CARD
                  _buildInputCard(
                    title: 'CLOSE PRICE',
                    infoTooltip: 'The exit price when the position was closed or current market price.',
                    colors: colors,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Red Minus Button
                        InkWell(
                          onTap: () {
                            if (_closePrice > 0.1) {
                              setState(() => _closePrice -= 0.10);
                            }
                          },
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE82B57),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.minus,
                                size: 14, color: Colors.white),
                          ),
                        ),

                        // Close Price Text
                        InkWell(
                          onTap: () => _showPriceInputDialog(
                              context, 'Close Price', _closePrice, colors, (val) {
                            setState(() => _closePrice = val);
                          }),
                          child: Text(
                            _closePrice.toStringAsFixed(2),
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
                            setState(() => _closePrice += 0.10);
                          },
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E88E5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.plus,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 5. TRADE SIZE CARD
                  _buildInputCard(
                    title: 'Trade size',
                    infoTooltip: 'Number of lots or trade contracts.',
                    colors: colors,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Red Minus Button
                        InkWell(
                          onTap: () {
                            if (_tradeSize > 0.10) {
                              setState(() => _tradeSize -= 0.10);
                            }
                          },
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE82B57),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.minus,
                                size: 14, color: Colors.white),
                          ),
                        ),

                        // Trade Size Text
                        InkWell(
                          onTap: () => _showPriceInputDialog(
                              context, 'Trade Size', _tradeSize, colors, (val) {
                            setState(() => _tradeSize = val);
                          }),
                          child: Text(
                            _tradeSize.toStringAsFixed(2),
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
                            setState(() => _tradeSize += 0.10);
                          },
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E88E5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.plus,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 6. RESULT PROFIT DISPLAY CARD
                  Container(
                    height: 90,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        profitDisplay,
                        style: GoogleFonts.inter(
                          fontSize: 44,
                          fontWeight: FontWeight.w500,
                          color: colors.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
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
                  LucideIcons.info,
                  size: 16,
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

  void _showScriptPicker(BuildContext context, TradingColors colors) {
    final repo = ref.read(marketRepositoryProvider);
    final all = repo.cachedInstruments;
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
                        ? const Icon(LucideIcons.check, color: Color(0xFF1E88E5), size: 18)
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _selectedScript = inst);
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
                  ? const Icon(LucideIcons.check, color: Color(0xFF1E88E5), size: 18)
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
                  ? const Icon(LucideIcons.check, color: Color(0xFF1E88E5), size: 18)
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

  void _showPriceInputDialog(BuildContext context, String title, double current,
      TradingColors colors, ValueChanged<double> onSet) {
    final controller =
        TextEditingController(text: current.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.cardBackground,
        title: Text(title,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, fontSize: 16, color: colors.textPrimary)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          style: GoogleFonts.inter(color: colors.textPrimary),
          decoration: InputDecoration(
            labelText: title,
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
              if (val != null && val >= 0) {
                onSet(val);
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
