import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/trading_colors.dart';
import '../core/theme/typography.dart';
import '../features/news/data/news_repository.dart';
import '../features/notifications/data/notifications_repository.dart';

class NewsTickerStrip extends ConsumerWidget {
  final String? publicNews;
  final String? privateNews;
  final VoidCallback? onPublicNewsTap;
  final VoidCallback? onPrivateNewsTap;

  const NewsTickerStrip({
    super.key,
    this.publicNews,
    this.privateNews,
    this.onPublicNewsTap,
    this.onPrivateNewsTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.tradingColors;
    final liveHeadline = ref.watch(latestNewsHeadlineProvider).valueOrNull;
    final liveAlert = ref.watch(latestNotificationSummaryProvider).valueOrNull;

    final displayPublic = (publicNews != null && publicNews != 'Welcome to Zero Life')
        ? publicNews!
        : (liveHeadline != null && liveHeadline.isNotEmpty ? liveHeadline : 'Welcome to Zero Life');

    final displayPrivate = (privateNews != null &&
            privateNews != 'Make Your First Deposit and Receive a 50% Bonus Instantly')
        ? privateNews!
        : (liveAlert != null && liveAlert.isNotEmpty
            ? liveAlert
            : 'Make Your First Deposit and Receive a 50% Bonus Instantly');

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
            onTap: onPublicNewsTap ?? () {
              try {
                context.push('/news');
              } catch (_) {}
            },
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
                    text: displayPublic,
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
            onTap: onPrivateNewsTap ?? () {
              try {
                context.push('/mails');
              } catch (_) {}
            },
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
                    text: displayPrivate,
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
