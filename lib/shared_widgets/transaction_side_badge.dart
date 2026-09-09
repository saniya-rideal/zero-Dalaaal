import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/trading_colors.dart';
import '../data/models/enums.dart';

/// Clean, standardized transaction side badge (BUY / SELL) with semantic colors.
class TransactionSideBadge extends StatelessWidget {
  final TransactionType side;
  final EdgeInsets padding;
  final double fontSize;
  final double borderRadius;

  const TransactionSideBadge({
    super.key,
    required this.side,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    this.fontSize = 10,
    this.borderRadius = 3,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final isBuy = side == TransactionType.BUY;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isBuy ? colors.bullish : colors.bearish,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        side.name,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
