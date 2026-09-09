import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/mock/sector_heatmap_repository.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/shared_widgets.dart';
import '../../../shared_widgets/zero_drawer.dart';
import 'widgets/stock_quick_action_sheet.dart';

class SectorHeatmapScreen extends ConsumerWidget {
  const SectorHeatmapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.tradingColors;
    final payload = ref.watch(sectorHeatmapDataProvider);
    final filterState = ref.watch(sectorHeatmapFilterProvider);
    final filterNotifier = ref.read(sectorHeatmapFilterProvider.notifier);

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const ZeroDrawer(activeRoute: '/heatmap'),
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AdaptiveLeadingButton(),
        title: Text(
          'Market Heatmap',
          style: GoogleFonts.inter(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // View Mode Toggle (Treemap vs Sector Grid)
          IconButton(
            icon: Icon(
              filterState.viewMode == HeatmapViewMode.treemap
                  ? LucideIcons.layoutGrid
                  : LucideIcons.columns3,
              color: colors.textPrimary,
              size: 20,
            ),
            onPressed: () {
              filterNotifier.setViewMode(
                filterState.viewMode == HeatmapViewMode.treemap
                    ? HeatmapViewMode.sectorGrid
                    : HeatmapViewMode.treemap,
              );
            },
            tooltip: filterState.viewMode == HeatmapViewMode.treemap
                ? 'Switch to Sector Grid'
                : 'Switch to Treemap',
          ),
          // Reset filters if modified
          if (filterState.scope != HeatmapScope.allSectors ||
              filterState.selectedSectorName != null ||
              filterState.timeframe != HeatmapTimeframe.oneDay)
            IconButton(
              icon: Icon(LucideIcons.rotateCcw,
                  color: colors.textSecondary, size: 18),
              onPressed: filterNotifier.resetFilters,
              tooltip: 'Reset Filters',
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // 1. Market Breadth Summary Bar
          _buildMarketBreadthBanner(context, payload.summary, colors, filterNotifier),

          // 2. Filter Controls (Timeframe & Scope)
          _buildFilterBar(context, filterState, filterNotifier, colors),

          // 3. Main Content: Treemap or Sector Grid
          Expanded(
            child: payload.sectors.isEmpty
                ? _buildEmptyState(context, colors, filterNotifier)
                : filterState.viewMode == HeatmapViewMode.treemap
                    ? _buildTreemapView(context, payload, colors)
                    : _buildSectorGridView(context, payload, colors, filterNotifier),
          ),
        ],
      ),
    );
  }

  // --- Market Breadth Summary Banner ---
  Widget _buildMarketBreadthBanner(
    BuildContext context,
    MarketBreadthSummary summary,
    TradingColors colors,
    SectorHeatmapFilterNotifier notifier,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // Advance / Decline Count
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '${summary.totalAdvances} Adv',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '|',
                style: TextStyle(color: colors.divider, fontSize: 12),
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '${summary.totalDeclines} Dec',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Top Performer Pill
          Flexible(
            child: InkWell(
              onTap: () => notifier.selectSector(summary.topSectorName),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.trendingUp,
                        size: 13, color: Color(0xFF10B981)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${summary.topSectorName} +${summary.topSectorChange.toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF10B981),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Filter Bar (Timeframe & Scope Pills) ---
  Widget _buildFilterBar(
    BuildContext context,
    SectorHeatmapFilterState filter,
    SectorHeatmapFilterNotifier notifier,
    TradingColors colors,
  ) {
    return Column(
      children: [
        // Timeframe Selector Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              // Segmented Timeframe Switch
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: HeatmapTimeframe.values.map((tf) {
                    final isSelected = filter.timeframe == tf;
                    return GestureDetector(
                      onTap: () => notifier.setTimeframe(tf),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.cardBackground
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          tf.label,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? colors.textPrimary
                                : colors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(width: 8),

              // Active Sector Filter Chip (if selected)
              if (filter.selectedSectorName != null)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            filter.selectedSectorName!,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => notifier.selectSector(null),
                          child: Icon(LucideIcons.x,
                              size: 14, color: colors.primary),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Spacer(),
            ],
          ),
        ),

        // Scope Filter Chips Row (All, Nifty 50, Gainers, Losers)
        SizedBox(
          height: 38,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: HeatmapScope.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final scope = HeatmapScope.values[i];
              final isSelected = filter.scope == scope;
              return ChoiceChip(
                label: Text(scope.label),
                selected: isSelected,
                onSelected: (_) => notifier.setScope(scope),
                selectedColor: colors.primary.withValues(alpha: 0.15),
                backgroundColor: colors.cardBackground,
                labelStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? colors.primary : colors.textSecondary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected
                        ? colors.primary.withValues(alpha: 0.5)
                        : colors.divider.withValues(alpha: 0.5),
                  ),
                ),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              );
            },
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  // --- Treemap View Mode ---
  Widget _buildTreemapView(
    BuildContext context,
    SectorHeatmapPayload payload,
    TradingColors colors,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: payload.sectors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (ctx, i) {
        final sector = payload.sectors[i];
        final isPositive = sector.avgChangePercent >= 0;
        final sign = isPositive ? '+' : '';

        return Container(
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.divider.withValues(alpha: 0.5)),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sector Title Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      sector.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${sector.weight.toStringAsFixed(1)}% wt',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$sign${sector.avgChangePercent.toStringAsFixed(2)}%',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isPositive
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Stock Tiles Grid / Flow Layout
              _buildStockTilesGrid(context, sector.stocks, payload.timeframe, colors),
            ],
          ),
        );
      },
    );
  }

  // Stock Tiles Grid within a Sector
  Widget _buildStockTilesGrid(
    BuildContext context,
    List<HeatmapStockItem> stocks,
    HeatmapTimeframe timeframe,
    TradingColors colors,
  ) {
    if (stocks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'No stocks match current filter',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: colors.textSecondary,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: stocks.map((stock) {
            // Proportional tile width calculation based on weight
            double tileWidth;
            if (stock.weight >= 6.0) {
              tileWidth = maxWidth; // Large heavyweight full width
            } else if (stock.weight >= 2.5) {
              tileWidth = (maxWidth - 6) / 2; // Medium half width
            } else {
              tileWidth = (maxWidth - 12) / 3; // Smaller 1/3 width
            }

            final change = stock.getEffectiveChange(timeframe);
            final tileColor = _getHeatmapColor(change);
            final sign = change >= 0 ? '+' : '';

            return SizedBox(
              width: tileWidth,
              height: stock.weight >= 6.0 ? 56 : 64,
              child: Material(
                color: tileColor,
                borderRadius: BorderRadius.circular(8),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    StockQuickActionSheet.show(
                      context,
                      stock: stock,
                      timeframe: timeframe,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    child: stock.weight >= 6.0
                        ? Row(
                            children: [
                              Text(
                                stock.symbol,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyFormatter.format(stock.ltp),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '$sign${change.toStringAsFixed(2)}%',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                stock.symbol,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      CurrencyFormatter.format(stock.ltp),
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '$sign${change.toStringAsFixed(1)}%',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // --- Sector Grid View Mode ---
  Widget _buildSectorGridView(
    BuildContext context,
    SectorHeatmapPayload payload,
    TradingColors colors,
    SectorHeatmapFilterNotifier notifier,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: payload.sectors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final sector = payload.sectors[i];
        final isPositive = sector.avgChangePercent >= 0;
        final sign = isPositive ? '+' : '';
        final totalConstituents =
            sector.advancesCount + sector.declinesCount + sector.unchangedCount;
        final advanceRatio = totalConstituents > 0
            ? sector.advancesCount / totalConstituents
            : 0.5;

        return Material(
          color: colors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: colors.divider.withValues(alpha: 0.5)),
          ),
          child: InkWell(
            onTap: () => notifier.selectSector(sector.name),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Sector Title & Average Return
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sector.name,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${sector.indexSymbol} • Weight: ${sector.weight.toStringAsFixed(1)}%',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPositive
                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                              : const Color(0xFFEF4444).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$sign${sector.avgChangePercent.toStringAsFixed(2)}%',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isPositive
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Advance / Decline Progress Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '🟢 ${sector.advancesCount} Advances',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      Text(
                        '🔴 ${sector.declinesCount} Declines',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: SizedBox(
                      height: 5,
                      child: LinearProgressIndicator(
                        value: advanceRatio,
                        backgroundColor: const Color(0xFFEF4444),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Top Movers Chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: sector.stocks.take(4).map((stock) {
                      final change = stock.getEffectiveChange(payload.timeframe);
                      final isGainer = change >= 0;
                      final sSign = isGainer ? '+' : '';

                      return GestureDetector(
                        onTap: () {
                          StockQuickActionSheet.show(
                            context,
                            stock: stock,
                            timeframe: payload.timeframe,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: colors.divider.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            '${stock.symbol} $sSign${change.toStringAsFixed(1)}%',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isGainer
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Empty State View
  Widget _buildEmptyState(
    BuildContext context,
    TradingColors colors,
    SectorHeatmapFilterNotifier notifier,
  ) {
    return EmptyStateView(
      icon: LucideIcons.filterX,
      title: 'No matching stocks found',
      subtitle: 'Try changing your scope or selected sector.',
      buttonText: 'Reset All Filters',
      onButtonPressed: notifier.resetFilters,
    );
  }

  // Heatmap Color Gradient Function
  Color _getHeatmapColor(double changePercent) {
    if (changePercent >= 2.5) {
      return const Color(0xFF047857); // Deep intense emerald
    } else if (changePercent >= 1.0) {
      return const Color(0xFF10B981); // Bright emerald
    } else if (changePercent >= 0.05) {
      return const Color(0xFF059669).withValues(alpha: 0.85); // Moderate green
    } else if (changePercent > -0.05) {
      return const Color(0xFF475569); // Neutral slate
    } else if (changePercent > -1.0) {
      return const Color(0xFFE11D48).withValues(alpha: 0.85); // Moderate crimson
    } else if (changePercent > -2.5) {
      return const Color(0xFFEF4444); // Bright red
    } else {
      return const Color(0xFFB91C1C); // Deep intense crimson
    }
  }
}
