import 'package:flutter/material.dart';
import '../core/theme/trading_colors.dart';

class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final VoidCallback? onTap;
  final double borderRadius;

  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.onTap,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;

    return Padding(
      padding: margin,
      child: Material(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(borderRadius),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(color: colors.divider, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
