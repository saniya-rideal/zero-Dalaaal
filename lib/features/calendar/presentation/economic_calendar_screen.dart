import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../shared_widgets/news_ticker_strip.dart';
import '../../../shared_widgets/script_selector_bar.dart';
import '../../../shared_widgets/zero_bottom_nav_bar.dart';
import '../../../shared_widgets/zero_drawer.dart';
import '../data/calendar_repository.dart';
import 'widgets/corporate_actions_view.dart';

class EconomicCalendarScreen extends ConsumerStatefulWidget {
  const EconomicCalendarScreen({super.key});

  @override
  ConsumerState<EconomicCalendarScreen> createState() => _EconomicCalendarScreenState();
}

class _EconomicCalendarScreenState extends ConsumerState<EconomicCalendarScreen> {
  final Set<String> _expandedEventIds = {};
  int _selectedTabIndex = 0; // 0: Macro Events, 1: Corporate Actions
  String _impactFilter = 'ALL'; // ALL, HIGH, MEDIUM, LOW

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final eventsAsync = ref.watch(calendarEventsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const ZeroDrawer(activeRoute: '/economic-calendar'),
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (ctx) {
            final canPop = Navigator.of(ctx).canPop();
            if (canPop) {
              return IconButton(
                icon: Icon(Icons.arrow_back, color: colors.textPrimary, size: 24),
                onPressed: () => Navigator.of(ctx).pop(),
                tooltip: 'Back',
              );
            }
            return IconButton(
              icon: Icon(Icons.menu, color: colors.textPrimary, size: 26),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
              tooltip: 'Menu',
            );
          },
        ),
        title: Text(
          'Economic Calendar',
          style: GoogleFonts.inter(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Public News & Private News Strip
          const NewsTickerStrip(),

          // Dual Script Selector Bar
          const ScriptSelectorBar(),

          // Segmented Tab Selector (Macro vs Corporate Actions)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: colors.cardBackground,
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    title: 'Macro Events',
                    subtitle: 'RBI, Fed, CPI, GDP',
                    icon: LucideIcons.globe,
                    isSelected: _selectedTabIndex == 0,
                    onTap: () => setState(() => _selectedTabIndex = 0),
                    colors: colors,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTabButton(
                    title: 'Corporate Actions',
                    subtitle: 'Dividends, Splits, Bonus',
                    icon: LucideIcons.calendarCheck,
                    isSelected: _selectedTabIndex == 1,
                    onTap: () => setState(() => _selectedTabIndex = 1),
                    colors: colors,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: colors.divider),

          if (_selectedTabIndex == 0) ...[
            // Filter Header Icons Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: colors.cardBackground,
                border: Border(
                  bottom: BorderSide(color: colors.divider, width: 1),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Icon(Icons.filter_list, size: 18, color: colors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Impact:',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip('ALL', colors),
                    const SizedBox(width: 6),
                    _buildFilterChip('HIGH', colors),
                    const SizedBox(width: 6),
                    _buildFilterChip('MEDIUM', colors),
                    const SizedBox(width: 6),
                    _buildFilterChip('LOW', colors),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: Icon(Icons.refresh, size: 18, color: colors.textSecondary),
                      onPressed: () => ref.refresh(calendarEventsProvider),
                      tooltip: 'Refresh calendar',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (_selectedTabIndex == 0)
            Expanded(
              child: eventsAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: colors.primary),
                ),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.alertTriangle, size: 40, color: colors.bearish),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load economic events',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          err.toString(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => ref.refresh(calendarEventsProvider),
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (events) {
                  final filtered = _impactFilter == 'ALL'
                      ? events
                      : events.where((e) => e.impact == _impactFilter).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.calendar, size: 48, color: colors.textSecondary.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'No economic events scheduled',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Check back later for upcoming macro announcements',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => ref.refresh(calendarEventsProvider),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, thickness: 0.8, color: colors.divider),
                      itemBuilder: (context, index) {
                        final e = filtered[index];
                        final isExpanded = _expandedEventIds.contains(e.id);
                        final signalLevel = e.impact == 'HIGH' ? 3 : (e.impact == 'MEDIUM' ? 2 : 1);

                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (isExpanded) {
                                _expandedEventIds.remove(e.id);
                              } else {
                                _expandedEventIds.add(e.id);
                              }
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 1. Left Time / Badge Area
                                    SizedBox(
                                      width: 64,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (e.time.isNotEmpty) ...[
                                            if (e.impact == 'HIGH')
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE82B57),
                                                  borderRadius: BorderRadius.circular(5),
                                                ),
                                                child: Text(
                                                  e.time,
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white,
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w700,
                                                    fontFeatures: const [FontFeature.tabularFigures()],
                                                  ),
                                                ),
                                              )
                                            else
                                              Text(
                                                e.time,
                                                style: GoogleFonts.inter(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: colors.textSecondary,
                                                  fontFeatures: const [FontFeature.tabularFigures()],
                                                ),
                                              ),
                                            const SizedBox(height: 4),
                                          ],

                                          // Flag & Signal Bars
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(e.flag, style: const TextStyle(fontSize: 15)),
                                              const SizedBox(width: 4),
                                              _buildSignalBars(signalLevel, colors),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    // 2. Center/Right Title & Economic Metrics
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (e.title.isNotEmpty)
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    e.title,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: colors.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                                Icon(
                                                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                                  size: 16,
                                                  color: colors.textSecondary,
                                                ),
                                              ],
                                            ),

                                          const SizedBox(height: 4),

                                          // Metrics Row (A: Actual, F: Forecast, P: Previous)
                                          Wrap(
                                            spacing: 10,
                                            runSpacing: 4,
                                            children: [
                                              if (e.actual.isNotEmpty)
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'A: ',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11,
                                                        color: colors.textSecondary,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    Text(
                                                      e.actual,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11.5,
                                                        fontWeight: FontWeight.w800,
                                                        color: colors.textPrimary,
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                              if (e.forecast.isNotEmpty)
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'F: ',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11,
                                                        color: colors.textSecondary,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    Text(
                                                      e.forecast,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11.5,
                                                        fontWeight: FontWeight.w700,
                                                        color: colors.textPrimary,
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                              if (e.previous.isNotEmpty)
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'P: ',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11,
                                                        color: colors.textSecondary,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    Text(
                                                      e.previous,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11.5,
                                                        fontWeight: FontWeight.w700,
                                                        color: colors.textPrimary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                // Expanded Information
                                if (isExpanded) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: colors.surface,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: colors.divider, width: 1),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Country: ${e.country}',
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                        if (e.description.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            e.description,
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: colors.textSecondary,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

          if (_selectedTabIndex == 1)
            const Expanded(
              child: CorporateActionsView(),
            ),
        ],
      ),
      bottomNavigationBar: ZeroBottomNavBar(
        currentIndex: 0,
        isExpanded: false,
        onCenterToggle: () {},
        onTabSelected: (index) {
          if (index == 0) context.go('/quotes');
          if (index == 1) context.go('/deals');
          if (index == 2) context.go('/net-deals');
          if (index == 3) context.go('/history');
        },
      ),
    );
  }

  Widget _buildFilterChip(String impact, TradingColors colors) {
    final isSelected = _impactFilter == impact;
    return InkWell(
      onTap: () => setState(() => _impactFilter = impact),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? colors.primary : colors.divider,
            width: 1,
          ),
        ),
        child: Text(
          impact,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? colors.primary : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSignalBars(int level, TradingColors colors) {
    final inactiveBarColor = colors.divider;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 2.2,
          height: 4,
          decoration: BoxDecoration(
            color: level >= 1 ? const Color(0xFF1E88E5) : inactiveBarColor,
            borderRadius: BorderRadius.circular(0.5),
          ),
        ),
        const SizedBox(width: 1.5),
        Container(
          width: 2.2,
          height: 7,
          decoration: BoxDecoration(
            color: level >= 2 ? const Color(0xFF1E88E5) : inactiveBarColor,
            borderRadius: BorderRadius.circular(0.5),
          ),
        ),
        const SizedBox(width: 1.5),
        Container(
          width: 2.2,
          height: 10,
          decoration: BoxDecoration(
            color: level >= 3 ? const Color(0xFF1E88E5) : inactiveBarColor,
            borderRadius: BorderRadius.circular(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required TradingColors colors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.12)
              : colors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? colors.primary
                : colors.divider.withValues(alpha: 0.6),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? colors.primary : colors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? colors.primary : colors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
