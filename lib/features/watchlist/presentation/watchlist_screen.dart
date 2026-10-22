import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/services/market_status_service.dart';
import '../../../core/services/realtime_quote_service.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/models.dart';
import '../../market/data/real_market_repository.dart';
import '../../../shared_widgets/shared_widgets.dart';
import '../../../shared_widgets/zero_drawer.dart';
import '../../order_entry/presentation/order_entry_sheet.dart';
import 'watchlist_controller.dart';
import 'watchlist_row_actions.dart';
import '../../../core/services/notification_service.dart';

class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.tradingColors;
    final state = ref.watch(watchlistControllerProvider);
    final activeGroup = state.watchlist;
    final tickerService = ref.watch(tickerServiceProvider);
    final repo = ref.watch(marketRepositoryProvider);

    // Subscribe visible tokens to ticker
    if (activeGroup != null && activeGroup.instrumentTokens.isNotEmpty) {
      tickerService.subscribeAll(activeGroup.instrumentTokens);
    }

    // Watch stream of quotes for real-time ticking
    final quotesAsync = ref.watch(quotesStreamProvider);
    final quotesMap = quotesAsync.valueOrNull ?? tickerService.getAllQuotes();

    final nseStatus = MarketStatusService.getStatusForExchange('NSE');
    final isMarketClosed = nseStatus.state == MarketSessionState.closed;

    return Scaffold(
      drawer: const ZeroDrawer(activeRoute: '/watchlist'),
      appBar: AppBar(
        leading: const AdaptiveLeadingButton(),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Watchlist',
              style: AppTypography.h1(color: colors.textPrimary, weight: FontWeight.w700),
            ),
            Text(
              '${activeGroup?.instrumentTokens.length ?? 0} / 50 symbols',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search, size: 20),
            onPressed: () => context.push('/search'),
          ),
          Consumer(
            builder: (context, ref, child) {
              final unreadCount = ref.watch(unreadNotificationsCountProvider);
              return IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(LucideIcons.bell, size: 20),
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
          if (isMarketClosed)
            const MarketClosedBanner(),

          // Main List View
          Expanded(
            child: state.isLoading
                ? const ListSkeletonView(count: 10)
                : activeGroup == null || activeGroup.instrumentTokens.isEmpty
                    ? EmptyStateView(
                        icon: LucideIcons.bookmark,
                        title: 'Your watchlist is empty',
                        subtitle: 'Add equities, commodities, forex, or crypto scripts to track live prices.',
                        buttonText: 'Add script',
                        onButtonPressed: () => context.push('/add-script'),
                      )
                    : ReorderableListView.builder(
                        itemCount: activeGroup.instrumentTokens.length,
                        onReorder: (oldIdx, newIdx) =>
                            ref.read(watchlistControllerProvider.notifier).reorder(oldIdx, newIdx),
                        itemBuilder: (context, index) {
                          final token = activeGroup.instrumentTokens[index];
                          final instrument = repo.findBySymbol(token) ??
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
                              Dismissible(
                                key: ValueKey('dismiss_wl_$token'),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  color: colors.bearish,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: const Icon(LucideIcons.trash2, color: Colors.white, size: 20),
                                ),
                                confirmDismiss: (direction) async {
                                  final notifier = ref.read(watchlistControllerProvider.notifier);
                                  final success = await notifier.removeInstrument(token);
                                  if (context.mounted && success) {
                                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Removed ${instrument.symbol} from Watchlist'),
                                        action: SnackBarAction(
                                          label: 'UNDO',
                                          textColor: Colors.white,
                                          onPressed: () => notifier.addInstrument(token),
                                        ),
                                      ),
                                    );
                                  }
                                  return success;
                                },
                                child: InstrumentRow(
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
                                        onRemove: () async {
                                          final notifier = ref.read(watchlistControllerProvider.notifier);
                                          final success = await notifier.removeInstrument(instrument.token);
                                          if (context.mounted && success) {
                                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Removed ${instrument.symbol} from Watchlist'),
                                                action: SnackBarAction(
                                                  label: 'UNDO',
                                                  textColor: Colors.white,
                                                  onPressed: () => notifier.addInstrument(instrument.token),
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    );
                                  },
                                ),
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
        onPressed: () => context.push('/add-script'),
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus, size: 20),
        label: const Text('Add script'),
      ),
    );
  }
}
