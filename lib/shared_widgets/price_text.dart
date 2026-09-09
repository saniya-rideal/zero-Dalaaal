import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme/trading_colors.dart';
import '../core/theme/typography.dart';
import '../core/utils/currency_formatter.dart';

class PriceText extends StatefulWidget {
  final double value;
  final double? change;
  final double? changePercent;
  final bool showCurrencySymbol;
  final bool showDirectionGlyph;
  final bool flashOnChange;
  final TextStyle? style;
  final int decimalDigits;

  const PriceText({
    super.key,
    required this.value,
    this.change,
    this.changePercent,
    this.showCurrencySymbol = true,
    this.showDirectionGlyph = false,
    this.flashOnChange = true,
    this.style,
    this.decimalDigits = 2,
  });

  @override
  State<PriceText> createState() => _PriceTextState();
}

class _PriceTextState extends State<PriceText> with SingleTickerProviderStateMixin {
  late AnimationController _flashController;
  late Animation<Color?> _flashAnimation;
  bool _isFlashing = false;
  Color _flashColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didUpdateWidget(covariant PriceText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flashOnChange && oldWidget.value != widget.value && mounted) {
      final tradingColors = context.tradingColors;
      final isUp = widget.value > oldWidget.value;
      _flashColor = isUp ? tradingColors.flashGreen : tradingColors.flashRed;
      
      _flashAnimation = ColorTween(
        begin: _flashColor,
        end: Colors.transparent,
      ).animate(CurvedAnimation(parent: _flashController, curve: Curves.easeOut));

      _isFlashing = true;
      _flashController.forward(from: 0.0).then((_) {
        if (mounted) {
          setState(() {
            _isFlashing = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    
    // Determine color based on change or value
    Color textColor = colors.textPrimary;
    if (widget.change != null) {
      if (widget.change! > 0) {
        textColor = colors.bullish;
      } else if (widget.change! < 0) {
        textColor = colors.bearish;
      } else {
        textColor = colors.neutral;
      }
    }

    final formattedPrice = CurrencyFormatter.format(
      widget.value,
      showSymbol: widget.showCurrencySymbol,
      decimalDigits: widget.decimalDigits,
    );

    final defaultStyle = AppTypography.body(
      color: textColor,
      weight: FontWeight.w600,
      tabular: true,
    );

    final textStyle = (widget.style ?? defaultStyle).copyWith(
      color: widget.style?.color ?? textColor,
      fontFeatures: AppTypography.tabularFontFeatures,
    );

    final Widget textWidget;
    if (widget.showDirectionGlyph && widget.change != null && widget.change != 0) {
      final iconSize = (widget.style?.fontSize ?? 14.0) * 0.85;
      textWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.change! > 0 ? LucideIcons.arrowUp : LucideIcons.arrowDown,
            size: iconSize,
            color: textColor,
          ),
          const SizedBox(width: 2),
          Text(formattedPrice, style: textStyle),
        ],
      );
    } else {
      textWidget = Text(
        formattedPrice,
        style: textStyle,
      );
    }

    if (_isFlashing) {
      return AnimatedBuilder(
        animation: _flashAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: _flashAnimation.value,
              borderRadius: BorderRadius.circular(4),
            ),
            child: child,
          );
        },
        child: textWidget,
      );
    }

    return textWidget;
  }
}
