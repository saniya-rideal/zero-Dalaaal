import 'package:flutter/material.dart';
import '../core/theme/trading_colors.dart';
import '../core/theme/typography.dart';

class NewsTickerStrip extends StatelessWidget {
  final String publicNews;
  final String privateNews;
  final VoidCallback? onPublicNewsTap;
  final VoidCallback? onPrivateNewsTap;

  const NewsTickerStrip({
    super.key,
    this.publicNews = 'Welcome to Zero Life',
    this.privateNews =
        'Make Your First Deposit and Receive a 50% Bonus Instantly',
    this.onPublicNewsTap,
    this.onPrivateNewsTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(
          bottom: BorderSide(
              color: colors.divider.withValues(alpha: 0.5), width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Public News Line (Pink / Crimson)
          InkWell(
            onTap: onPublicNewsTap,
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Public News: ',
                    style: AppTypography.labelSmall(
                      color: colors.primary,
                      weight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: publicNews,
                    style: AppTypography.labelSmall(
                      color: colors.primary,
                      weight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 3),
          // Private News Line (Black / Slate)
          InkWell(
            onTap: onPrivateNewsTap,
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Private News: ',
                    style: AppTypography.labelSmall(
                      color: colors.textPrimary,
                      weight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: privateNews,
                    style: AppTypography.labelSmall(
                      color: colors.textPrimary,
                      weight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
