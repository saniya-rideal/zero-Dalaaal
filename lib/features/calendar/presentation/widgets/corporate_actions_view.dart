import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/trading_colors.dart';
import '../../../../data/models/corporate_action.dart';
import '../../../quote_detail/data/fundamentals_repository.dart';
import '../../data/calendar_repository.dart';

class CorporateActionsView extends ConsumerStatefulWidget {
  const CorporateActionsView({super.key});

  @override
  ConsumerState<CorporateActionsView> createState() =>
      _CorporateActionsViewState();
}

class _CorporateActionsViewState extends ConsumerState<CorporateActionsView> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _expandedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final actions = ref.watch(filteredCorporateActionsProvider);
    final filter = ref.watch(corporateActionsFilterProvider);
    final allActionsAsync = ref.watch(corporateActionsProvider(null));
    final allActions = allActionsAsync.valueOrNull ?? const [];
    final counts = <CorporateActionType, int>{};
    for (final t in CorporateActionType.values) {
      counts[t] = allActions.where((a) => a.actionType == t).length;
    }

    return Column(
      children: [
        // 1. Search Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: colors.cardBackground,
          child: TextField(
            controller: _searchController,
            style: GoogleFonts.inter(color: colors.textPrimary, fontSize: 13.5),
            onChanged: (val) {
              ref
                  .read(corporateActionsFilterProvider.notifier)
                  .setSearchQuery(val);
            },
            decoration: InputDecoration(
              hintText: 'Search by symbol or company (e.g. RELIANCE, TCS)',
              hintStyle: GoogleFonts.inter(
                  color: colors.textSecondary, fontSize: 12.5),
              prefixIcon:
                  Icon(LucideIcons.search, size: 18, color: colors.textSecondary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(LucideIcons.x,
                          size: 16, color: colors.textSecondary),
                      onPressed: () {
                        _searchController.clear();
                        ref
                            .read(corporateActionsFilterProvider.notifier)
                            .setSearchQuery('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: colors.background,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: colors.divider.withValues(alpha: 0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: colors.divider.withValues(alpha: 0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.primary),
              ),
            ),
          ),
        ),

        // 2. Filter Chips Row
        Container(
          height: 48,
          color: colors.cardBackground,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _buildFilterChip(
                label: 'All (${allActions.length})',
                isSelected: filter.type == null,
                activeColor: colors.primary,
                onTap: () {
                  ref
                      .read(corporateActionsFilterProvider.notifier)
                      .setType(null);
                },
                colors: colors,
              ),
              ...CorporateActionType.values.map((type) => Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: _buildFilterChip(
                      label: '${type.pluralLabel} (${counts[type] ?? 0})',
                      isSelected: filter.type == type,
                      activeColor: _getTypeColor(type),
                      onTap: () {
                        ref
                            .read(corporateActionsFilterProvider.notifier)
                            .setType(type);
                      },
                      colors: colors,
                    ),
                  )),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: colors.divider),

        // 3. Actions List
        Expanded(
          child: actions.isEmpty
              ? _buildEmptyState(colors)
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: actions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = actions[index];
                    final isExpanded = _expandedIds.contains(item.id);
                    return _buildActionCard(item, isExpanded, colors);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
    required TradingColors colors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : colors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? activeColor
                : colors.divider.withValues(alpha: 0.8),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? activeColor : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
      CorporateAction item, bool isExpanded, TradingColors colors) {
    final typeColor = _getTypeColor(item.actionType);
    final typeIcon = _getTypeIcon(item.actionType);

    return Material(
      color: colors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colors.divider.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          setState(() {
            if (isExpanded) {
              _expandedIds.remove(item.id);
            } else {
              _expandedIds.add(item.id);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Symbol, Company, and Action Badge
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: typeColor.withValues(alpha: 0.15),
                    child: Icon(typeIcon, color: typeColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              item.symbol,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: colors.background,
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(
                                    color:
                                        colors.divider.withValues(alpha: 0.6)),
                              ),
                              child: Text(
                                'NSE',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.companyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.actionType.label.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: typeColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Details description
              Text(
                item.details,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              // Ex-Date Row with countdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.calendar,
                          size: 14, color: colors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Ex-Date: ${_formatDate(item.exDate)}',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.daysUntilExDate <= 7
                          ? const Color(0xFFE82B57).withValues(alpha: 0.12)
                          : colors.background,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: item.daysUntilExDate <= 7
                            ? const Color(0xFFE82B57).withValues(alpha: 0.4)
                            : colors.divider.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      item.relativeTimeDescription,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: item.daysUntilExDate <= 7
                            ? const Color(0xFFE82B57)
                            : colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),

              // Expandable content
              if (isExpanded) ...[
                const Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricCol('Record Date', _formatDate(item.recordDate),
                        colors),
                    _buildMetricCol('Current CMP',
                        '₹${item.currentPrice.toStringAsFixed(2)}', colors),
                    if (item.dividendYield != null)
                      _buildMetricCol(
                          'Yield', '${item.dividendYield}%', colors)
                    else if (item.ratio != null)
                      _buildMetricCol('Ratio', item.ratio!, colors)
                    else
                      _buildMetricCol('Ex-Date', _formatDate(item.exDate), colors),
                  ],
                ),
                if (item.remarks != null && item.remarks!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: colors.divider.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(LucideIcons.info, size: 15, color: typeColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.remarks!,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: colors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.shieldAlert,
                          size: 14, color: colors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Eligibility: Must hold or buy before Ex-Date ${_formatDate(item.exDate)}.',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, TradingColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: colors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(TradingColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.calendarX2, size: 40, color: colors.textSecondary),
          const SizedBox(height: 12),
          Text(
            'No corporate actions found',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try changing your search query or filter category.',
            style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(CorporateActionType type) {
    switch (type) {
      case CorporateActionType.dividend:
        return const Color(0xFF10B981); // Green
      case CorporateActionType.split:
        return const Color(0xFF0284C7); // Blue
      case CorporateActionType.bonus:
        return const Color(0xFF8B5CF6); // Purple
      case CorporateActionType.buyback:
        return const Color(0xFFF59E0B); // Amber
      case CorporateActionType.rights:
        return const Color(0xFF06B6D4); // Cyan
    }
  }

  IconData _getTypeIcon(CorporateActionType type) {
    switch (type) {
      case CorporateActionType.dividend:
        return LucideIcons.coins;
      case CorporateActionType.split:
        return LucideIcons.split;
      case CorporateActionType.bonus:
        return LucideIcons.gift;
      case CorporateActionType.buyback:
        return LucideIcons.tag;
      case CorporateActionType.rights:
        return LucideIcons.fileText;
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
