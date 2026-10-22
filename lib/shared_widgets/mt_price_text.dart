import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/trading_colors.dart';

enum PriceColorMode { normal, blue, red }

class MtPriceText extends StatelessWidget {
  final double price;
  final PriceColorMode colorMode;
  final int? decimals;
  final double fontSize;

  const MtPriceText({
    super.key,
    required this.price,
    this.colorMode = PriceColorMode.normal,
    this.decimals,
    this.fontSize = 16.5,
  });

  int get _resolvedDecimals {
    if (decimals != null) return decimals!;
    if (price > 0 && price < 10 && (price * 100).truncateToDouble() != price * 100) {
      return 4;
    }
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;

    Color textColor;
    switch (colorMode) {
      case PriceColorMode.blue:
        textColor = colors.marginValue;
        break;
      case PriceColorMode.red:
        textColor = colors.primary;
        break;
      case PriceColorMode.normal:
        textColor = colors.textPrimary;
        break;
    }

    if (price <= 0) {
      return Text(
        '—',
        style: GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: colors.textSecondary,
        ),
      );
    }

    final priceStr = price.toStringAsFixed(_resolvedDecimals);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        priceStr,
        style: GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: textColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
