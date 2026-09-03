import 'package:flutter/material.dart';
import '../core/theme/trading_colors.dart';
import '../core/theme/typography.dart';
import '../core/utils/currency_formatter.dart';

class MarginSummaryBar extends StatelessWidget {
  final double requiredMargin;
  final double availableMargin;
  final double charges;
  final VoidCallback? onChargesDetailsTap;

  const MarginSummaryBar({
    super.key,
    required this.requiredMargin,
    required this.availableMargin,
    this.charges = 0.0,
    this.onChargesDetailsTap,
  });

  bool get hasSufficientMargin => availableMargin >= requiredMargin;

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.divider, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Margin req: ',
                    style: AppTypography.caption(color: colors.textSecondary),
                  ),
                  Text(
                    CurrencyFormatter.format(requiredMargin),
                    style: AppTypography.body(
                      color: hasSufficientMargin ? colors.textPrimary : colors.bearish,
                      weight: FontWeight.w600,
                      tabular: true,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    'Avail: ',
                    style: AppTypography.caption(color: colors.textSecondary),
                  ),
                  Text(
                    CurrencyFormatter.format(availableMargin),
                    style: AppTypography.body(
                      color: colors.textPrimary,
                      weight: FontWeight.w600,
                      tabular: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (charges > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: onChargesDetailsTap,
                  child: Row(
                    children: [
                      Text(
                        'Charges approx: ',
                        style: AppTypography.caption(color: colors.textSecondary),
                      ),
                      Text(
                        CurrencyFormatter.format(charges),
                        style: AppTypography.caption(
                          color: colors.primary,
                          weight: FontWeight.w600,
                          tabular: true,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.info_outline,
                        size: 12,
                        color: colors.primary,
                      ),
                    ],
                  ),
                ),
                if (!hasSufficientMargin)
                  Text(
                    'Insufficient Funds',
                    style: AppTypography.caption(
                      color: colors.bearish,
                      weight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
