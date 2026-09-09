import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme/trading_colors.dart';
import '../core/theme/typography.dart';
import 'adaptive_leading_button.dart';

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
  final Widget? trailingAction;
  final Widget? leading;
  final bool? showBackButton;

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
    this.trailingAction,
    this.leading,
    this.showBackButton,
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
      leading: leading ??
          (showBackButton != null
              ? IconButton(
                  icon: Icon(
                    showBackButton! ? LucideIcons.arrowLeft : LucideIcons.menu,
                    color: colors.textPrimary,
                    size: 22,
                  ),
                  onPressed: () {
                    if (showBackButton!) {
                      Navigator.of(context).pop();
                    } else {
                      final root =
                          context.findRootAncestorStateOfType<ScaffoldState>();
                      if (root != null && root.hasDrawer) {
                        root.openDrawer();
                      } else {
                        Scaffold.of(context).openDrawer();
                      }
                    }
                  },
                )
              : const AdaptiveLeadingButton()),
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
            icon: Icon(LucideIcons.filter, color: colors.textPrimary, size: 20),
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
                    isSortAscending ? LucideIcons.arrowDown : LucideIcons.arrowUp,
                    size: 14,
                    color: colors.textPrimary,
                  ),
                ],
              ),
            ),
          ),
        if (showCalendarAction)
          PopupMenuButton<HistoryDateFilter>(
            icon: Icon(LucideIcons.calendar, color: colors.textPrimary, size: 20),
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
        if (trailingAction != null) trailingAction!,
        const SizedBox(width: 8),
      ],
    );
  }
}
