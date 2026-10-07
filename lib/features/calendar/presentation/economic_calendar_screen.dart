import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../shared_widgets/news_ticker_strip.dart';
import '../../../shared_widgets/script_selector_bar.dart';
import '../../../shared_widgets/zero_bottom_nav_bar.dart';
import '../../../shared_widgets/zero_drawer.dart';
import 'widgets/corporate_actions_view.dart';

class EconomicCalendarScreen extends StatefulWidget {
  const EconomicCalendarScreen({super.key});

  @override
  State<EconomicCalendarScreen> createState() => _EconomicCalendarScreenState();
}

class _EconomicCalendarScreenState extends State<EconomicCalendarScreen> {
  final Set<int> _expandedIndices = {};
  int _selectedTabIndex = 0; // 0: Macro Events, 1: Corporate Actions

  final List<Map<String, dynamic>> _events = [
    {
      'time': '',
      'isBadge': false,
      'flag': '🇦🇪',
      'signal': 2,
      'title': '',
      'actual': '56.9',
      'actualUnit': 'Index (diffusion)',
      'forecast': '—',
      'forecastUnit': '',
      'previous': '53.6',
      'previousUnit': 'Index (diffusion)',
      'country': 'United Arab Emirates',
      'description': 'Measures the performance of the non-oil private sector economy.',
    },
    {
      'time': '10:30',
      'isBadge': true,
      'flag': '🇮🇳',
      'signal': 3,
      'title': 'HSBC Composite Final PMI',
      'actual': '',
      'actualUnit': '',
      'forecast': '',
      'forecastUnit': '',
      'previous': '54.3',
      'previousUnit': 'Index (diffusion)',
      'country': 'India',
      'description': 'Composite purchasing managers index tracking manufacturing and services output in India.',
    },
    {
      'time': '10:30',
      'isBadge': true,
      'flag': '🇮🇳',
      'signal': 3,
      'title': 'HSBC: SERVICES - BUSINESS ACTIVITY',
      'actual': '',
      'actualUnit': '',
      'forecast': '54.5',
      'forecastUnit': 'Index (diffusion)',
      'previous': '53.3',
      'previousUnit': 'Index (diffusion)',
      'country': 'India',
      'description': 'Measures business activity and new orders in Indian services sector.',
    },
    {
      'time': '11:30',
      'isBadge': false,
      'flag': '🇷🇺',
      'signal': 2,
      'title': 'S&P Global Services PMI',
      'actual': '',
      'actualUnit': '',
      'forecast': '',
      'forecastUnit': '',
      'previous': '49',
      'previousUnit': 'Index (diffusion)',
      'country': 'Russia',
      'description': 'Survey of executive sentiment across private services firms in Russia.',
    },
    {
      'time': '12:00',
      'isBadge': false,
      'flag': '🇨🇭',
      'signal': 3,
      'title': 'CPI MM',
      'actual': '',
      'actualUnit': '',
      'forecast': '0%',
      'forecastUnit': '',
      'previous': '-0.1%',
      'previousUnit': '',
      'country': 'Switzerland',
      'description': 'Month-over-month consumer price index measuring changes in Swiss retail prices.',
    },
    {
      'time': '12:00',
      'isBadge': false,
      'flag': '🇨🇭',
      'signal': 3,
      'title': 'CPI NSA*',
      'actual': '',
      'actualUnit': '',
      'forecast': '',
      'forecastUnit': '',
      'previous': '101.1',
      'previousUnit': 'Index',
      'country': 'Switzerland',
      'description': 'Non-seasonally adjusted consumer price index headline level.',
    },
    {
      'time': '12:00',
      'isBadge': false,
      'flag': '🇨🇭',
      'signal': 3,
      'title': 'CPI YY',
      'actual': '',
      'actualUnit': '',
      'forecast': '0.5%',
      'forecastUnit': '',
      'previous': '0.4%',
      'previousUnit': '',
      'country': 'Switzerland',
      'description': 'Year-over-year Swiss inflation rate benchmark.',
    },
    {
      'time': '12:00',
      'isBadge': false,
      'flag': '🇸🇪',
      'signal': 2,
      'title': 'PMI Services*',
      'actual': '',
      'actualUnit': '',
      'forecast': '',
      'forecastUnit': '',
      'previous': '54.2',
      'previousUnit': 'Index (diffusion)',
      'country': 'Sweden',
      'description': 'Purchasing managers index indicating Swedish services sector growth above 50.',
    },
    {
      'time': '12:30',
      'isBadge': false,
      'flag': '🇹🇷',
      'signal': 3,
      'title': 'Core Inflation*',
      'actual': '',
      'actualUnit': '',
      'forecast': '',
      'forecastUnit': '',
      'previous': '130.97',
      'previousUnit': 'Index',
      'country': 'Turkey',
      'description': 'Core inflation index excluding volatile food and energy components.',
    },
    {
      'time': '12:30',
      'isBadge': false,
      'flag': '🇹🇷',
      'signal': 3,
      'title': 'CPI Ex E,F,B,T&G MM *',
      'actual': '',
      'actualUnit': '',
      'forecast': '',
      'forecastUnit': '',
      'previous': '1.9%',
      'previousUnit': '',
      'country': 'Turkey',
      'description': 'Turkish CPI month-on-month index excluding energy, food, beverages and tobacco.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;

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
            // Filter Header Icons Row (Globe + Bar Chart)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: colors.cardBackground,
                border: Border(
                  bottom: BorderSide(color: colors.divider, width: 1),
                ),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Filter by country/region')),
                      );
                    },
                    child: Icon(Icons.language, size: 22, color: colors.textPrimary),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Filter by volatility impact')),
                      );
                    },
                    child: Icon(Icons.bar_chart, size: 22, color: colors.textPrimary),
                  ),
                ],
              ),
            ),
          ],

          if (_selectedTabIndex == 0)
            Expanded(
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                itemCount: _events.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, thickness: 0.8, color: colors.divider),
              itemBuilder: (context, index) {
                final e = _events[index];
                final isExpanded = _expandedIndices.contains(index);

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedIndices.remove(index);
                      } else {
                        _expandedIndices.add(index);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 10.0),
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
                                  if (e['time'].toString().isNotEmpty) ...[
                                    if (e['isBadge'] == true)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE82B57),
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          e['time'],
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            fontFeatures: const [
                                              FontFeature.tabularFigures()
                                            ],
                                          ),
                                        ),
                                      )
                                    else
                                      Text(
                                        e['time'],
                                        style: GoogleFonts.inter(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: colors.textSecondary,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures()
                                          ],
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                  ],

                                  // Flag & Signal Bars
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        e['flag'],
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                      const SizedBox(width: 4),
                                      _buildSignalBars(e['signal'] as int, colors),
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
                                  if (e['title'].toString().isNotEmpty)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            e['title'],
                                            style: GoogleFonts.inter(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: colors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          isExpanded
                                              ? Icons.keyboard_arrow_up
                                              : Icons.keyboard_arrow_down,
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
                                      // Actual
                                      if (e['actual'].toString().isNotEmpty)
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
                                              e['actual'],
                                              style: GoogleFonts.inter(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w800,
                                                color: colors.textPrimary,
                                              ),
                                            ),
                                            if (e['actualUnit'].toString().isNotEmpty)
                                              Text(
                                                ' ${e['actualUnit']}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  color: colors.textSecondary,
                                                ),
                                              ),
                                          ],
                                        ),

                                      // Forecast
                                      if (e['forecast'].toString().isNotEmpty)
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
                                              e['forecast'],
                                              style: GoogleFonts.inter(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: colors.textPrimary,
                                              ),
                                            ),
                                            if (e['forecastUnit'].toString().isNotEmpty)
                                              Text(
                                                ' ${e['forecastUnit']}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  color: colors.textSecondary,
                                                ),
                                              ),
                                          ],
                                        ),

                                      // Previous
                                      if (e['previous'].toString().isNotEmpty)
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
                                              e['previous'],
                                              style: GoogleFonts.inter(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: colors.textPrimary,
                                              ),
                                            ),
                                            if (e['previousUnit'].toString().isNotEmpty)
                                              Text(
                                                ' ${e['previousUnit']}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  color: colors.textSecondary,
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
                              border: Border.all(
                                  color: colors.divider, width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Country: ${e['country']}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  e['description'],
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: colors.textSecondary,
                                    height: 1.3,
                                  ),
                                ),
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
          ),

          // Bottom Action & Attribution Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: colors.cardBackground,
              border: Border(
                top: BorderSide(color: colors.divider, width: 1),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Loading more economic events...')),
                        );
                      },
                      child: Row(
                        children: [
                          Text(
                            'More events',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF1E88E5),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right,
                              size: 16, color: Color(0xFF1E88E5)),
                        ],
                      ),
                    ),

                    // TV Watermark Badge
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: colors.cardBackground,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'TV',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // TradingView Attribution Text Link
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Economic Calendar powered by TradingView')),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'Economic Calendar ',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1E88E5),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        TextSpan(
                          text: 'by TradingView',
                          style: GoogleFonts.inter(
                            color: colors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
