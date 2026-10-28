import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/services/realtime_quote_service.dart';
import '../../../core/utils/app_snack_bar.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/exchange_chip.dart';
import '../../../shared_widgets/price_text.dart';
import '../../watchlist/presentation/watchlist_controller.dart';
import 'search_controller.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final state = ref.watch(searchControllerProvider);
    final searchNotifier = ref.read(searchControllerProvider.notifier);
    final tickerService = ref.watch(tickerServiceProvider);
    final watchlistState = ref.watch(watchlistControllerProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: AppTypography.body(color: colors.textPrimary, weight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Search eg: infy bse, nifty fut, reliance...',
            hintStyle: AppTypography.body(color: colors.textSecondary),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(LucideIcons.x, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      searchNotifier.onQueryChanged('');
                    },
                  )
                : null,
          ),
          onChanged: (val) => searchNotifier.onQueryChanged(val),
        ),
      ),
      body: Column(
        children: [
          // Segment Filter Chips
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(bottom: BorderSide(color: colors.divider, width: 0.5)),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip(
                  label: 'ALL',
                  isSelected: state.selectedExchange == null,
                  onTap: () => searchNotifier.setExchangeFilter(null),
                ),
                _buildFilterChip(
                  label: 'NSE',
                  isSelected: state.selectedExchange == Exchange.NSE,
                  onTap: () => searchNotifier.setExchangeFilter(Exchange.NSE),
                ),
                _buildFilterChip(
                  label: 'BSE',
                  isSelected: state.selectedExchange == Exchange.BSE,
                  onTap: () => searchNotifier.setExchangeFilter(Exchange.BSE),
                ),
                _buildFilterChip(
                  label: 'NFO',
                  isSelected: state.selectedExchange == Exchange.NFO,
                  onTap: () => searchNotifier.setExchangeFilter(Exchange.NFO),
                ),
                _buildFilterChip(
                  label: 'MCX',
                  isSelected: state.selectedExchange == Exchange.MCX,
                  onTap: () => searchNotifier.setExchangeFilter(Exchange.MCX),
                ),
              ],
            ),
          ),

          // Main Results / Recent Searches Area
          Expanded(
            child: state.query.isEmpty
                ? _buildEmptyQuerySuggestions(state, colors, searchNotifier)
                : state.results.isEmpty
                    ? Center(
                        child: Text(
                          'No instruments found matching "${state.query}"',
                          style: AppTypography.body(color: colors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        itemCount: state.results.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final instrument = state.results[index];
                          final quote = tickerService.getQuote(instrument.token);
                          final tokenUpper = instrument.token.toUpperCase();
                          final symUpper = instrument.symbol.toUpperCase();
                          final isInWatchlist = watchlistState.watchlist?.instrumentTokens
                                  .any((t) => t.toUpperCase() == tokenUpper || t.toUpperCase() == symUpper) ??
                              false;

                          return ListTile(
                            onTap: () {
                              searchNotifier.recordSearch(instrument.symbol);
                              context.push('/quote/${instrument.token}');
                            },
                            title: Row(
                              children: [
                                Text(
                                  instrument.symbol,
                                  style: AppTypography.body(
                                    color: colors.textPrimary,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ExchangeChip(exchange: instrument.exchange, type: instrument.type),
                              ],
                            ),
                            subtitle: Text(
                              instrument.name,
                              style: AppTypography.caption(color: colors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PriceText(
                                  value: quote.ltp,
                                  change: quote.change,
                                  style: AppTypography.body(tabular: true, weight: FontWeight.w600),
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  icon: Icon(
                                    isInWatchlist ? LucideIcons.check : LucideIcons.plus,
                                    color: isInWatchlist ? colors.bullish : colors.primary,
                                    size: 22,
                                  ),
                                  tooltip: isInWatchlist ? 'In Watchlist' : 'Add to Watchlist',
                                  onPressed: () async {
                                    final notifier = ref.read(watchlistControllerProvider.notifier);
                                    if (isInWatchlist) {
                                      final success = await notifier.removeInstrument(instrument.symbol);
                                      if (context.mounted && success) {
                                        showAppSnackBar(
                                          context,
                                          message: 'Removed ${instrument.symbol} from Watchlist',
                                          actionLabel: 'UNDO',
                                          onAction: () => notifier.addInstrument(instrument.symbol),
                                        );
                                      }
                                    } else {
                                      final success = await notifier.addInstrument(instrument.symbol);
                                      if (context.mounted) {
                                        if (success) {
                                          showAppSnackBar(
                                            context,
                                            message: 'Added ${instrument.symbol} to Watchlist',
                                            actionLabel: 'UNDO',
                                            onAction: () => notifier.removeInstrument(instrument.symbol),
                                          );
                                        } else {
                                          final err = ref.read(watchlistControllerProvider).errorMessage;
                                          showAppSnackBar(
                                            context,
                                            message: err == 'MAX_SYMBOLS_EXCEEDED'
                                                ? 'Watchlist limit reached: Maximum 50 symbols allowed.'
                                                : (err ?? 'Failed to add ${instrument.symbol}'),
                                            backgroundColor: const Color(0xFFC62828),
                                          );
                                        }
                                      }
                                    }
                                  },
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

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = context.tradingColors;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0, top: 6, bottom: 6),
      child: ChoiceChip(
        label: Text(label, style: AppTypography.labelSmall(color: isSelected ? Colors.white : colors.textSecondary, weight: FontWeight.w600)),
        selected: isSelected,
        selectedColor: colors.primary,
        backgroundColor: colors.surface,
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  Widget _buildEmptyQuerySuggestions(
    SearchState state,
    TradingColors colors,
    InstrumentSearchController searchNotifier,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.recent.isNotEmpty) ...[
            Text('RECENT SEARCHES', style: AppTypography.caption(color: colors.textSecondary, weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.recent.map((symbol) {
                return ActionChip(
                  label: Text(symbol, style: AppTypography.caption(color: colors.textPrimary, weight: FontWeight.w500)),
                  backgroundColor: colors.surface,
                  onPressed: () {
                    _searchController.text = symbol;
                    searchNotifier.onQueryChanged(symbol);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          Text('TRENDING INSTRUMENTS', style: AppTypography.caption(color: colors.textSecondary, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.trending.map((instrument) {
              return ActionChip(
                avatar: Icon(LucideIcons.trendingUp, color: colors.bullish, size: 16),
                label: Text(instrument.symbol, style: AppTypography.caption(color: colors.textPrimary, weight: FontWeight.w600)),
                backgroundColor: colors.surface,
                onPressed: () {
                  _searchController.text = instrument.symbol;
                  searchNotifier.onQueryChanged(instrument.symbol);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
