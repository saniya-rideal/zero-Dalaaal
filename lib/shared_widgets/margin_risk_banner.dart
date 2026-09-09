import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../data/mock/order_simulation_engine.dart';
import '../data/models/enums.dart';
import '../data/models/funds.dart';

class MarginRiskBanner extends ConsumerWidget {
  final Segment segment;
  final EdgeInsetsGeometry margin;

  const MarginRiskBanner({
    super.key,
    this.segment = Segment.EQUITY,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(orderSimulationEngineProvider);
    final funds = engine.getFundsSummary(segment);
    final risk = funds.riskLevel;

    if (risk == MarginRiskLevel.NORMAL) {
      return const SizedBox.shrink();
    }

    final Color bannerColor;
    final IconData bannerIcon;
    final String bannerTitle;
    final String bannerMessage;

    switch (risk) {
      case MarginRiskLevel.HIGH_MARGIN:
        bannerColor = const Color(0xFFFFA000); // Amber
        bannerIcon = LucideIcons.alertTriangle;
        bannerTitle = 'High Margin Utilization (${funds.marginUtilizationPercent.toStringAsFixed(0)}%)';
        bannerMessage =
            'You are currently using ${funds.marginUtilizationPercent.toStringAsFixed(1)}% of your available margin. Monitor open risk closely.';
        break;
      case MarginRiskLevel.MARGIN_CALL:
        bannerColor = const Color(0xFFE64A19); // Deep Orange
        bannerIcon = LucideIcons.alertCircle;
        bannerTitle = 'Margin Call Warning (${funds.marginUtilizationPercent.toStringAsFixed(0)}%)';
        bannerMessage =
            'Margin utilization exceeds 90%. Add funds or square off open positions immediately to prevent forced square-off.';
        break;
      case MarginRiskLevel.FORCED_LIQUIDATION:
        bannerColor = const Color(0xFFD32F2F); // Emergency Red
        bannerIcon = LucideIcons.alertOctagon;
        bannerTitle = 'Forced Liquidation Warning (RMS Auto Square-Off)';
        bannerMessage =
            'Margin deficit detected. Risk Management Systems (RMS) will auto-square off positions to cover shortfalls. Deposit funds now.';
        break;
      case MarginRiskLevel.NORMAL:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: margin,
      child: Container(
        decoration: BoxDecoration(
          color: bannerColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: bannerColor.withValues(alpha: 0.4), width: 1.2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(bannerIcon, color: bannerColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    bannerTitle,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: bannerColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    bannerMessage,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => context.push('/funds'),
              style: TextButton.styleFrom(
                backgroundColor: bannerColor.withValues(alpha: 0.2),
                foregroundColor: bannerColor,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              ),
              child: Text(
                'Add Funds',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
