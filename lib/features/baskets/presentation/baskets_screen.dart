import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/shared_widgets.dart';
import '../../../shared_widgets/zero_drawer.dart';
import '../../market/data/real_market_repository.dart';
import '../data/baskets_repository.dart';

final basketsListProvider = FutureProvider.autoDispose<List<Basket>>((ref) async {
  final repo = ref.watch(basketsRepositoryProvider);
  return repo.getBaskets();
});

class BasketsScreen extends ConsumerStatefulWidget {
  const BasketsScreen({super.key});

  @override
  ConsumerState<BasketsScreen> createState() => _BasketsScreenState();
}

class _BasketsScreenState extends ConsumerState<BasketsScreen> {
  final Set<String> _executingBasketIds = {};

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final basketsAsync = ref.watch(basketsListProvider);

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const ZeroDrawer(activeRoute: '/baskets'),
      appBar: AppBar(
        backgroundColor: colors.cardBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AdaptiveLeadingButton(),
        centerTitle: true,
        title: Text(
          'Baskets',
          style: GoogleFonts.inter(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
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
          const ZeroMarketHeaderStrip(),
          Expanded(
            child: basketsAsync.when(
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
                        'Failed to load baskets',
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
                        onPressed: () => ref.invalidate(basketsListProvider),
                        icon: const Icon(LucideIcons.refreshCw, size: 16),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (baskets) {
                if (baskets.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async => ref.refresh(basketsListProvider.future),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                        EmptyStateView(
                          icon: LucideIcons.shoppingBag,
                          title: 'No Baskets Created',
                          subtitle:
                              'Group multiple orders into a single basket to execute complex strategies in one tap.',
                          buttonText: 'Create Basket',
                          onButtonPressed: _showCreateBasketDialog,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(basketsListProvider.future),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    itemCount: baskets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final basket = baskets[index];
                      final isExecuting = _executingBasketIds.contains(basket.id);

                      return SectionCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    basket.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(LucideIcons.trash2, size: 16, color: colors.loss),
                                  onPressed: () => _deleteBasket(basket.id),
                                  tooltip: 'Delete Basket',
                                ),
                              ],
                            ),
                            Text(
                              '${basket.legs.length} Orders',
                              style: GoogleFonts.inter(
                                color: colors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...basket.legs.map((leg) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          TransactionSideBadge(side: leg.side),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              leg.instrumentToken,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                color: colors.textPrimary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${leg.quantity} Qty • ${leg.kind.name}',
                                      style: GoogleFonts.inter(
                                        color: colors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: isExecuting ? null : () => _executeBasket(basket),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: isExecuting
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'EXECUTE BASKET',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                      ),
                                    ),
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

  void _executeBasket(Basket basket) async {
    if (_executingBasketIds.contains(basket.id)) return;
    setState(() => _executingBasketIds.add(basket.id));

    try {
      await ref.read(basketsRepositoryProvider).executeBasket(basket.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Executed basket "${basket.name}" successfully'),
          action: SnackBarAction(
            label: 'VIEW ORDERS',
            onPressed: () => context.go('/orders'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to execute basket: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _executingBasketIds.remove(basket.id));
      }
    }
  }

  Future<void> _deleteBasket(String id) async {
    try {
      await ref.read(basketsRepositoryProvider).deleteBasket(id);
      ref.invalidate(basketsListProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete basket: $e')),
        );
      }
    }
  }

  void _showCreateBasketDialog() {
    final colors = context.tradingColors;
    final nameController = TextEditingController();
    final defaultSym = ref.read(cachedInstrumentsProvider).value?.firstOrNull?.symbol ?? '';
    final symbolController = TextEditingController(text: defaultSym);
    final qtyController = TextEditingController(text: '1');
    String side = 'BUY';
    bool isCreating = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: colors.cardBackground,
          title: Text(
            'Create New Basket',
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
                  controller: nameController,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Basket Name',
                    hintText: 'e.g. Banking Momentum',
                    hintStyle: TextStyle(color: colors.textSecondary),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
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
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: side,
                        dropdownColor: colors.cardBackground,
                        style: TextStyle(color: colors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Side',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'BUY', child: Text('BUY')),
                          DropdownMenuItem(value: 'SELL', child: Text('SELL')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => side = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: qtyController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: colors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
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
              onPressed: isCreating
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      final sym = symbolController.text.trim().toUpperCase();
                      final qty = int.tryParse(qtyController.text) ?? 1;
                      if (name.isEmpty || sym.isEmpty) return;

                      setDialogState(() => isCreating = true);
                      try {
                        await ref.read(basketsRepositoryProvider).createBasket(
                          name: name,
                          orders: [
                            {
                              'symbol': sym,
                              'side': side,
                              'quantity': qty,
                              'type': 'MARKET',
                            }
                          ],
                        );
                        if (!mounted) return;
                        ref.invalidate(basketsListProvider);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Basket created successfully!')),
                        );
                      } catch (e) {
                        setDialogState(() => isCreating = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to create basket: $e')),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: colors.primary),
              child: isCreating
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Create', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
