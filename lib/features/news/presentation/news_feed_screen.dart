import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';

class NewsArticle {
  final String title;
  final String summary;
  final String fullContent;
  final String timestamp;
  final String source;

  const NewsArticle({
    required this.title,
    required this.summary,
    required this.fullContent,
    required this.timestamp,
    required this.source,
  });
}

class NewsFeedScreen extends StatelessWidget {
  final String sourceTitle;

  const NewsFeedScreen({
    super.key,
    this.sourceTitle = 'FXStreet News',
  });

  static final List<NewsArticle> defaultArticles = [
    const NewsArticle(
      title: 'Indian Rupee hits fresh two-month high against US Dollar',
      summary:
          'The Indian Rupee (INR) opens strongly against the US Dollar (USD) on Thursday, extending the rally to near 94.28.',
      fullContent:
          'The Indian Rupee (INR) opens strongly against the US Dollar (USD) on Thursday, extending the rally to near 94.28 as foreign institutional inflows and softening crude oil benchmarks support domestic currency sentiment. Reserve Bank of India market operations continue to stabilize volatility across forward premiums.',
      timestamp: 'Thu, 03 Sep 2026 05:22:14 Z',
      source: 'FXStreet',
    ),
    const NewsArticle(
      title:
          'Indonesian Rupiah strengthens as US Dollar declines on...',
      summary:
          'USD/IDR loses ground for the second successive day, trading around 17,730 during the Asian hours on Thursday. The currency pair experiences downward pressure as a sharp rally in the Japane...',
      fullContent:
          'USD/IDR loses ground for the second successive day, trading around 17,730 during the Asian hours on Thursday. The currency pair experiences downward pressure as a sharp rally in the Japanese Yen and broad-based cooling of US Treasury yields weigh heavily on the Greenback across Southeast Asian FX pairs.',
      timestamp: 'Thu, 03 Sep 2026 05:16:15 Z',
      source: 'FXStreet',
    ),
    const NewsArticle(
      title:
          'United States Dollar Index weakens below 99.50 as yiel...',
      summary:
          'The US Dollar Index (DXY), an index of the value of the US Dollar (USD) measured against a basket of six world currencies, currently trades near 99.40 in the early European trading hours on Thursday....',
      fullContent:
          'The US Dollar Index (DXY), an index of the value of the US Dollar (USD) measured against a basket of six world currencies, currently trades near 99.40 in the early European trading hours on Thursday. Dismal non-manufacturing ISM indicators and expectations of upcoming monetary easing have triggered broad dollar unwinding.',
      timestamp: 'Thu, 03 Sep 2026 05:10:26 Z',
      source: 'FXStreet',
    ),
    const NewsArticle(
      title:
          'Gold bulls eye \$4,450 as sliding bond yields counter Fe...',
      summary:
          'Gold (XAU/USD) builds on the previous day\'s goodish recovery from a nearly four-week low, and attracts some follow-through buyers for the second straight day on Thursday.',
      fullContent:
          'Gold (XAU/USD) builds on the previous day\'s goodish recovery from a nearly four-week low, and attracts some follow-through buyers for the second straight day on Thursday. Safe-haven inflows and aggressive central bank gold reserve accumulations provide robust support at critical technical moving averages.',
      timestamp: 'Thu, 03 Sep 2026 04:52:35 Z',
      source: 'FXStreet',
    ),
    const NewsArticle(
      title:
          'WTI Price Forecast: Consolidates above \$89.00; bullish...',
      summary:
          'West Texas Intermediate (WTI) – the benchmark US Crude Oil price – struggles to capitalize on a modest Asian session uptick and currently trades just above the \$89.00 mark, unchanged for the day.',
      fullContent:
          'West Texas Intermediate (WTI) – the benchmark US Crude Oil price – struggles to capitalize on a modest Asian session uptick and currently trades just above the \$89.00 mark, unchanged for the day. Traders weigh OPEC+ quota adherence and refining utilization rates ahead of official inventory datasets.',
      timestamp: 'Thu, 03 Sep 2026 04:40:21 Z',
      source: 'FXStreet',
    ),
    const NewsArticle(
      title:
          'India Gold price today: Gold rises, according to FXStree...',
      summary:
          'Gold prices rose in India on Thursday, according to data compiled by FXStreet.',
      fullContent:
          'Gold prices rose in India on Thursday, according to data compiled by FXStreet. Standard 24-carat gold recorded fresh retail gains in major bullion markets like Mumbai and Delhi following international spot price momentum.',
      timestamp: 'Thu, 03 Sep 2026 04:35:06 Z',
      source: 'FXStreet',
    ),
    const NewsArticle(
      title:
          'EUR/JPY Price Forecast: Falls to near 183.00 near sym...',
      summary:
          'EUR/JPY extends its losses for the second successive day, trading around 183.00 during the Asian hours on Thursday. Technical analysis of the daily chart indicates the currency cross remains wit...',
      fullContent:
          'EUR/JPY extends its losses for the second successive day, trading around 183.00 during the Asian hours on Thursday. Technical analysis of the daily chart indicates the currency cross remains within a descending channel as Bank of Japan hawkish rhetoric strengthens the Yen across European crosses.',
      timestamp: 'Thu, 03 Sep 2026 04:30:44 Z',
      source: 'FXStreet',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          sourceTitle,
          style: GoogleFonts.inter(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView.separated(
          itemCount: defaultArticles.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, thickness: 0.8, color: colors.divider),
          itemBuilder: (context, index) {
            final article = defaultArticles[index];

            return InkWell(
              onTap: () => _showArticleDetails(context, article, colors),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Headline Title
                    Text(
                      article.title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Summary Text
                    Text(
                      article.summary,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        color: colors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Timestamp
                    Text(
                      article.timestamp,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w400,
                        color: colors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showArticleDetails(
      BuildContext context, NewsArticle article, TradingColors colors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E88E5).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      article.source,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1E88E5),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    article.timestamp,
                    style: GoogleFonts.inter(
                      color: colors.textSecondary,
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                article.title,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                article.fullContent,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: colors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Close Article',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
