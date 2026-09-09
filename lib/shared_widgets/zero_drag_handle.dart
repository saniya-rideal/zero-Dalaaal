import 'package:flutter/material.dart';
import '../core/theme/trading_colors.dart';

/// Standard drag indicator handle for bottom sheets and draggable modals.
class ZeroDragHandle extends StatelessWidget {
  final double width;
  final double height;
  final EdgeInsets padding;
  final Color? color;

  const ZeroDragHandle({
    super.key,
    this.width = 40,
    this.height = 4,
    this.padding = const EdgeInsets.only(top: 10, bottom: 12),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    return Padding(
      padding: padding,
      child: Center(
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color ?? colors.divider,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}
