import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../data/mock/order_simulation_engine.dart';
import '../../../data/mock/seed_instruments.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/empty_state_view.dart';
import '../../../shared_widgets/news_ticker_strip.dart';
import '../../../shared_widgets/script_selector_bar.dart';
import '../../../shared_widgets/section_card.dart';
import '../../../shared_widgets/zero_drawer.dart';

class BasketsScreen extends ConsumerStatefulWidget {
  const BasketsScreen({super.key});

  @override
  ConsumerState<BasketsScreen> createState() => _BasketsScreenState();
}

class _BasketsScreenState extends ConsumerState<BasketsScreen> {
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
        leading: Builder(
          builder: (innerContext) => IconButton(
            icon: Icon(Icons.menu, color: colors.textPrimary, size: 26),
            onPressed: () => Scaffold.of(innerContext).openDrawer(),
          ),
        ),
        centerTitle: true,
        title: Text('Baskets',
            style: GoogleFonts.inter(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: colors.primary, size: 26),
            onPressed: _showCreateBasketDialog,
            tooltip: 'Create Basket',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Public & Private News Ticker Strip
          const NewsTickerStrip(),

          // Dual Script Selector Bar
          const ScriptSelectorBar(),

          // Body
          Expanded(
            child: _baskets.isEmpty
                ? EmptyStateView(
                    icon: Icons.shopping_bag_outlined,
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
                                Text(basket.name,
                                    style: GoogleFonts.inter(
                                        color: colors.textPrimary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15)),
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
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color:
                                                leg.side == TransactionType.BUY
                                                    ? colors.bullish
                                                    : colors.bearish,
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            leg.side.name,
                                            style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                            inst?.symbol ??
                                                leg.instrumentToken,
                                            style: GoogleFonts.inter(
                                                color: colors.textPrimary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13.5)),
                                      ],
                                    ),
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
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _executeBasket(basket),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.primary,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6)),
                                ),
                                child: const Text('EXECUTE BASKET',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5)),
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

  void _executeBasket(Basket basket) {
    final engine = ref.read(orderSimulationEngineProvider);
    for (final leg in basket.legs) {
      engine.placeOrder(leg);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Executed basket "${basket.name}" (${basket.legs.length} orders placed)'),
      ),
    );
  }

  void _showCreateBasketDialog() {
    final colors = context.tradingColors;
    final nameController = TextEditingController();

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
              if (nameController.text.isNotEmpty) {
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
