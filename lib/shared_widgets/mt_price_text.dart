import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/trading_colors.dart';

enum PriceColorMode { normal, blue, red }

class MtPriceText extends StatelessWidget {
  final double price;
  final PriceColorMode colorMode;
  final int decimals;

  const MtPriceText({
    super.key,
    required this.price,
    this.colorMode = PriceColorMode.normal,
    this.decimals = 2,
  });

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

    final str = price.toStringAsFixed(decimals);
    final dotIndex = str.indexOf('.');

    String prefix = '';
    String core = '';
    String superscript = '';

    if (dotIndex != -1) {
      final whole = str.substring(0, dotIndex);
      final fractional = str.substring(dotIndex + 1);

      if (fractional.length >= 2) {
        prefix = whole.length > 1 ? whole.substring(0, whole.length - 1) : '';
        final lastWhole = whole.isNotEmpty ? whole.substring(whole.length - 1) : '0';
        core = '$lastWhole.${fractional.substring(0, fractional.length - 1)}';
        superscript = fractional.substring(fractional.length - 1);
      } else {
        prefix = whole;
        core = '.$fractional';
        superscript = '0';
      }
    } else {
      if (str.length > 2) {
        prefix = str.substring(0, str.length - 2);
        core = str.substring(str.length - 2, str.length - 1);
        superscript = str.substring(str.length - 1);
      } else {
        core = str;
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        if (prefix.isNotEmpty)
          Text(
            prefix,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        Text(
          core,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: -0.5,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (superscript.isNotEmpty)
          Transform.translate(
            offset: const Offset(1, -6),
            child: Text(
              superscript,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: textColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
      ],
    );
  }
}
