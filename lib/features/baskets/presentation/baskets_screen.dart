import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../data/mock/order_simulation_engine.dart';
import '../../../data/mock/seed_instruments.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/shared_widgets.dart';
import '../../../shared_widgets/zero_drawer.dart';
import '../../option_chain/presentation/payoff_graph_sheet.dart';

class BasketsScreen extends ConsumerStatefulWidget {
  const BasketsScreen({super.key});

  @override
  ConsumerState<BasketsScreen> createState() => _BasketsScreenState();
}

class _BasketsScreenState extends ConsumerState<BasketsScreen> {
  final Set<String> _executingBasketIds = {};
  final List<Basket> _baskets = [
    Basket(
      id: 'bsk_1',
      name: 'Nifty IT Leaders',
      legs: const [
        OrderRequest(
            instrumentToken: 'eq_tcs',
            side: TransactionType.BUY,
            product: ProductType.CNC,
            kind: OrderKind.MARKET,
            quantity: 5),
        OrderRequest(
            instrumentToken: 'eq_infy',
            side: TransactionType.BUY,
            product: ProductType.CNC,
            kind: OrderKind.MARKET,
            quantity: 10),
        OrderRequest(
            instrumentToken: 'eq_hcltech',
            side: TransactionType.BUY,
            product: ProductType.CNC,
            kind: OrderKind.MARKET,
            quantity: 8),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Basket(
      id: 'bsk_2',
      name: 'High Beta Momentum',
      legs: const [
        OrderRequest(
            instrumentToken: 'eq_zomato',
            side: TransactionType.BUY,
            product: ProductType.MIS,
            kind: OrderKind.MARKET,
            quantity: 50),
        OrderRequest(
            instrumentToken: 'eq_trent',
            side: TransactionType.BUY,
            product: ProductType.MIS,
            kind: OrderKind.MARKET,
            quantity: 2),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const ZeroDrawer(activeRoute: '/baskets'),
      appBar: AppBar(
        backgroundColor: colors.cardBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AdaptiveLeadingButton(),
        centerTitle: true,
        title: Text('Baskets',
            style: GoogleFonts.inter(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.plus, color: colors.primary, size: 22),
            onPressed: _showCreateBasketDialog,
            tooltip: 'Create Basket',
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
            child: _baskets.isEmpty
                ? EmptyStateView(
                    icon: LucideIcons.shoppingBag,
                    title: 'No Baskets Created',
                    subtitle:
                        'Group multiple orders into a single basket to execute complex strategies in one tap.',
                    buttonText: 'Create Basket',
                    onButtonPressed: _showCreateBasketDialog,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: _baskets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final basket = _baskets[index];
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
                                  child: Text(basket.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15)),
                                ),
                                const SizedBox(width: 8),
                                Text('${basket.legs.length} Orders',
                                    style: GoogleFonts.inter(
                                        color: colors.textSecondary,
                                        fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...basket.legs.map((leg) {
                              final inst = SeedInstruments.findByToken(
                                  leg.instrumentToken);
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 3.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          TransactionSideBadge(side: leg.side),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              inst?.symbol ??
                                                  leg.instrumentToken,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                  color: colors.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                        '${leg.quantity} Qty • ${leg.product.name}',
                                        style: GoogleFonts.inter(
                                            color: colors.textSecondary,
                                            fontSize: 12)),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                // Payoff Graph button
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showPayoffGraph(basket),
                                    icon: Icon(LucideIcons.chartLine,
                                        size: 14, color: colors.primary),
                                    label: Text('Payoff',
                                        style: GoogleFonts.inter(
                                            color: colors.primary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11.5)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 9),
                                      side: BorderSide(color: colors.primary),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Execute button
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed:
                                        _executingBasketIds.contains(basket.id)
                                            ? null
                                            : () => _executeBasket(basket),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                    ),
                                    child: _executingBasketIds
                                            .contains(basket.id)
                                        ? const SizedBox(
                                            height: 16,
                                            width: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white),
                                          )
                                        : const Text('EXECUTE',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12.5)),
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
        ],
      ),
    );
  }

  void _showPayoffGraph(Basket basket) {
    // Build an OptionStrategy from the basket legs using seeded instrument data.
    // For equity baskets, stock-type legs produce linear P&L payoffs.
    const double mockSpot = 25150.0;
    final legs = basket.legs.map((leg) {
      final inst = SeedInstruments.findByToken(leg.instrumentToken);
      final price = inst != null ? 1200.0 : 500.0; // approximate entry price
      return OptionStrategyLeg(
        side: leg.side,
        type: StrategyLegType.stock,
        strike: price,
        premium: 0.0,
        quantity: leg.quantity,
        lotSize: 1,
      );
    }).toList();

    final strategy = OptionStrategy(
      name: basket.name,
      underlying: 'EQUITY BASKET',
      spotPrice: mockSpot,
      expiry: 'N/A',
      legs: legs,
    );

    PayoffGraphSheet.show(context, strategy: strategy);
  }

  void _executeBasket(Basket basket) async {
    if (_executingBasketIds.contains(basket.id)) return;
    setState(() => _executingBasketIds.add(basket.id));

    try {
      final engine = ref.read(orderSimulationEngineProvider);
      for (final leg in basket.legs) {
        await engine.placeOrder(leg);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Executed basket "${basket.name}" (${basket.legs.length} orders placed)'),
          action: SnackBarAction(
            label: 'VIEW ORDERS',
            onPressed: () => context.go('/orders'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _executingBasketIds.remove(basket.id));
      }
    }
  }

  void _showCreateBasketDialog() {
    final colors = context.tradingColors;
    final nameController = TextEditingController();
    bool isCreating = false;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.cardBackground,
        title: Text('Create New Basket',
            style: GoogleFonts.inter(
                color: colors.textPrimary, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: nameController,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. Banking Momentum',
            hintStyle: TextStyle(color: colors.textSecondary),
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
              if (isCreating) return;
              if (nameController.text.isNotEmpty) {
                isCreating = true;
                setState(() {
                  _baskets.add(Basket(
                    id: 'bsk_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameController.text.trim(),
                    legs: const [
                      OrderRequest(
                          instrumentToken: 'eq_reliance',
                          side: TransactionType.BUY,
                          product: ProductType.CNC,
                          kind: OrderKind.MARKET,
                          quantity: 1),
                    ],
                    createdAt: DateTime.now(),
                  ));
                });
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: colors.primary),
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
