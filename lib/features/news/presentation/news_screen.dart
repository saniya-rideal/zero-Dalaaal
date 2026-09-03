import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../shared_widgets/zero_drawer.dart';
import 'news_feed_screen.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;

    final newsSources = [
      {
        'title': 'FXStreet News',
        'desc': 'Real-time Forex & Commodities market breaking news',
        'badge': 'LIVE',
      },
      {
        'title': 'DailyForex News',
        'desc': 'Daily market analysis, central bank outlook, and forecasts',
        'badge': 'DAILY',
      },
      {
        'title': 'MarketWatch News',
        'desc': 'Global equity indices, earnings reports, and economic pulse',
        'badge': 'STOCKS',
      },
      {
        'title': 'ForexLive News',
        'desc': 'Live fast-breaking financial news wire and trader commentary',
        'badge': 'FAST',
      },
      {
        'title': 'FXMarkets News',
        'desc': 'Institutional foreign exchange market intelligence',
        'badge': 'FOREX',
      },
    ];

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const ZeroDrawer(activeRoute: '/news'),
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu, color: colors.textPrimary, size: 26),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          'News',
          style: GoogleFonts.inter(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView.separated(
        itemCount: newsSources.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, thickness: 0.8, color: colors.divider),
        itemBuilder: (context, index) {
          final source = newsSources[index];

          return Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              title: Row(
                children: [
                  Text(
                    source['title']!,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E88E5).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      source['badge']!,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E88E5),
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  source['desc']!,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: colors.textSecondary,
                  ),
                ),
              ),
              trailing: Icon(Icons.chevron_right,
                  color: colors.textSecondary, size: 22),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        NewsFeedScreen(sourceTitle: source['title']!),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
