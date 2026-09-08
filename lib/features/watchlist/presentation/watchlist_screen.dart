import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/mock/seed_instruments.dart';
import '../../../data/mock/ticker_service.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/empty_state_view.dart';
import '../../../shared_widgets/instrument_row.dart';
import '../../../shared_widgets/skeleton_loader.dart';
import '../../../shared_widgets/zero_drawer.dart';
import '../../order_entry/presentation/order_entry_sheet.dart';
import 'watchlist_controller.dart';
import 'watchlist_row_actions.dart';
import 'watchlist_tab_strip.dart';
import '../../../core/services/notification_service.dart';

class WatchlistScreen extends ConsumerStatefulWidget {
  const WatchlistScreen({super.key});

  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen> {
  final TextEditingController _newWatchlistController = TextEditingController();

  @override
  void dispose() {
    _newWatchlistController.dispose();
    super.dispose();
  }

  void _showCreateWatchlistDialog() {
    _newWatchlistController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Watchlist'),
        content: TextField(
          controller: _newWatchlistController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Pharma, Dividend Stocks',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _newWatchlistController.text.trim();
              if (name.isNotEmpty) {
                ref.read(watchlistControllerProvider.notifier).createWatchlist(name);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final state = ref.watch(watchlistControllerProvider);
    final activeGroup = state.activeWatchlist;
    final tickerService = ref.watch(tickerServiceProvider);

    // Subscribe visible tokens to ticker
    if (activeGroup != null && activeGroup.instrumentTokens.isNotEmpty) {
      tickerService.subscribeAll(activeGroup.instrumentTokens);
    }

    // Watch stream of quotes for real-time ticking
    final quotesAsync = ref.watch(quotesStreamProvider);
    final quotesMap = quotesAsync.value ?? tickerService.getAllQuotes();

    return Scaffold(
      drawer: const ZeroDrawer(activeRoute: '/watchlist'),
      appBar: AppBar(
        leading: Builder(
          builder: (innerContext) {
            final canPop = Navigator.of(innerContext).canPop();
            if (canPop) {
              return IconButton(
                icon: Icon(Icons.arrow_back, color: colors.textPrimary, size: 24),
                onPressed: () => Navigator.of(innerContext).pop(),
                tooltip: 'Back',
              );
            }
            return IconButton(
              icon: Icon(Icons.menu, color: colors.textPrimary, size: 26),
              onPressed: () => Scaffold.of(innerContext).openDrawer(),
              tooltip: 'Menu',
            );
          },
        ),
        title: Text(
          'Marketwatch',
          style: AppTypography.h1(color: colors.textPrimary, weight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          Consumer(
            builder: (context, ref, child) {
              final unreadCount = ref.watch(unreadNotificationsCountProvider);
              return IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none_outlined),
                    if (unreadCount > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () => context.push('/notifications'),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Watchlist Tabs Header
          if (state.watchlists.isNotEmpty)
            WatchlistTabStrip(
              watchlists: state.watchlists,
              activeIndex: state.activeIndex,
              onSelectTab: (idx) => ref.read(watchlistControllerProvider.notifier).setActiveIndex(idx),
              onAddWatchlist: _showCreateWatchlistDialog,
            ),

          // Main List View
          Expanded(
            child: state.isLoading
                ? const ListSkeletonView(count: 10)
                : activeGroup == null || activeGroup.instrumentTokens.isEmpty
                    ? EmptyStateView(
                        icon: Icons.bookmark_border,
                        title: 'Your Watchlist is Empty',
                        subtitle: 'Explore 150+ equities, indices, and derivatives to add them to this list.',
                        buttonText: 'Add Instruments',
                        onButtonPressed: () => context.push('/search'),
                      )
                    : ReorderableListView.builder(
                        itemCount: activeGroup.instrumentTokens.length,
                        onReorder: (oldIdx, newIdx) =>
                            ref.read(watchlistControllerProvider.notifier).reorder(oldIdx, newIdx),
                        itemBuilder: (context, index) {
                          final token = activeGroup.instrumentTokens[index];
                          final instrument = SeedInstruments.findByToken(token) ??
                              Instrument(
                                token: token,
                                symbol: token.toUpperCase(),
                                name: token,
                                exchange: Exchange.NSE,
                                type: InstrumentType.EQ,
                              );
                          final quote = quotesMap[token] ?? tickerService.getQuote(token);

                          return Column(
                            key: ValueKey('row_$token'),
                            children: [
                              InstrumentRow(
                                instrument: instrument,
                                quote: quote,
                                onTap: () => context.push('/quote/${instrument.token}'),
                                onBuy: () => OrderEntrySheet.show(
                                  context,
                                  instrument: instrument,
                                  side: TransactionType.BUY,
                                ),
                                onSell: () => OrderEntrySheet.show(
                                  context,
                                  instrument: instrument,
                                  side: TransactionType.SELL,
                                ),
                                onLongPress: () {
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                    ),
                                    builder: (_) => WatchlistRowActions(
                                      instrument: instrument,
                                      quote: quote,
                                      onBuy: () => OrderEntrySheet.show(
                                        context,
                                        instrument: instrument,
                                        side: TransactionType.BUY,
                                      ),
                                      onSell: () => OrderEntrySheet.show(
                                        context,
                                        instrument: instrument,
                                        side: TransactionType.SELL,
                                      ),
                                      onRemove: () => ref
                                          .read(watchlistControllerProvider.notifier)
                                          .removeInstrument(instrument.token),
                                    ),
                                  );
                                },
                              ),
                              const Divider(height: 1),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/search'),
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Stock'),
      ),
    );
  }
}
