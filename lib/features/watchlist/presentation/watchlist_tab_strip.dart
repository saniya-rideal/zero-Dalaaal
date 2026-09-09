import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/models.dart';

class WatchlistTabStrip extends StatelessWidget {
  final List<WatchlistGroup> watchlists;
  final int activeIndex;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onAddWatchlist;

  const WatchlistTabStrip({
    super.key,
    required this.watchlists,
    required this.activeIndex,
    required this.onSelectTab,
    required this.onAddWatchlist,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        border: Border(
          bottom: BorderSide(color: colors.divider, width: 0.5),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: watchlists.length + 1,
        itemBuilder: (context, index) {
          if (index == watchlists.length) {
            // "+" Add Watchlist Button
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: InkWell(
                  onTap: onAddWatchlist,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.plus, size: 16, color: colors.primary),
                  ),
                ),
              ),
            );
          }

          final isSelected = activeIndex == index;
          final group = watchlists[index];

          return GestureDetector(
            onTap: () => onSelectTab(index),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? colors.primary : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    group.name,
                    style: AppTypography.body(
                      color: isSelected ? colors.primary : colors.textSecondary,
                      weight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primary.withValues(alpha: 0.12)
                          : colors.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${group.instrumentTokens.length}',
                      style: AppTypography.labelSmall(
                        color: isSelected ? colors.primary : colors.textSecondary,
                        weight: FontWeight.w600,
                        tabular: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
