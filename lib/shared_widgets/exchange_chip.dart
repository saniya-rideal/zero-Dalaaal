import 'package:flutter/material.dart';
import '../core/theme/trading_colors.dart';
import '../core/theme/typography.dart';
import '../data/models/enums.dart';

class ExchangeChip extends StatelessWidget {
  final Exchange exchange;
  final InstrumentType? type;

  const ExchangeChip({
    super.key,
    required this.exchange,
    this.type,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    
    String label = exchange.name;
    if (type != null && type != InstrumentType.EQ) {
      label = '${exchange.name} • ${type!.name}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: colors.divider, width: 0.5),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall(
          color: colors.textSecondary,
          weight: FontWeight.w500,
        ),
      ),
    );
  }
}
