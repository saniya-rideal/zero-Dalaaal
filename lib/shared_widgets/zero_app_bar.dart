import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/trading_colors.dart';
import '../core/theme/typography.dart';

enum HistoryDateFilter {
  lastDay('Last Day'),
  lastWeek('Last Week'),
  lastMonth('Last Month'),
  custom('Custom'),
  all('All');

  final String label;
  const HistoryDateFilter(this.label);
}

class ZeroAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onFilterTap;
  final VoidCallback? onSortTap;
  final bool isSortAscending;
  final ValueChanged<HistoryDateFilter>? onDateFilterSelected;
  final HistoryDateFilter selectedDateFilter;
  final bool showCalendarAction;
  final bool showFilterAction;
  final bool showSortAction;

  const ZeroAppBar({
    super.key,
    required this.title,
    this.onFilterTap,
    this.onSortTap,
    this.isSortAscending = true,
    this.onDateFilterSelected,
    this.selectedDateFilter = HistoryDateFilter.all,
    this.showCalendarAction = true,
    this.showFilterAction = true,
    this.showSortAction = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56.0);

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;

    return AppBar(
      backgroundColor: colors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Builder(
        builder: (innerContext) => IconButton(
          icon: Icon(Icons.menu, color: colors.textPrimary, size: 26),
          onPressed: () {
            final rootScaffold = innerContext.findRootAncestorStateOfType<ScaffoldState>();
            if (rootScaffold != null && rootScaffold.hasDrawer) {
              rootScaffold.openDrawer();
            } else {
              Scaffold.of(innerContext).openDrawer();
            }
          },
          tooltip: 'Menu',
        ),
      ),
      centerTitle: true,
      title: Text(
        title,
        style: AppTypography.h1(
          color: colors.textPrimary,
          weight: FontWeight.w600,
        ),
      ),
      actions: [
        if (showFilterAction)
          IconButton(
            icon: Icon(Icons.filter_alt_outlined, color: colors.textPrimary, size: 22),
            onPressed: onFilterTap ?? () {},
            tooltip: 'Filter',
          ),
        if (showSortAction)
          InkWell(
            onTap: onSortTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'A',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'z',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    isSortAscending ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 15,
                    color: colors.textPrimary,
                  ),
                ],
              ),
            ),
          ),
        if (showCalendarAction)
          PopupMenuButton<HistoryDateFilter>(
            icon: Icon(Icons.event_note_outlined, color: colors.textPrimary, size: 24),
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            color: colors.cardBackground,
            elevation: 4,
            initialValue: selectedDateFilter,
            onSelected: onDateFilterSelected,
            itemBuilder: (context) => HistoryDateFilter.values.map((filter) {
              final isSelected = filter == selectedDateFilter;
              return PopupMenuItem<HistoryDateFilter>(
                value: filter,
                child: Text(
                  filter.label,
                  style: AppTypography.body(
                    color: isSelected ? colors.primary : colors.textPrimary,
                    weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(width: 8),
      ],
    );
  }
}
