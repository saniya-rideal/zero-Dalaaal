import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme/trading_colors.dart';

/// An adaptive leading button that automatically pops if the Navigator can pop,
/// or opens the drawer (including nested shells) if at root level.
class AdaptiveLeadingButton extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onDrawer;
  final Color? color;
  final double size;

  const AdaptiveLeadingButton({
    super.key,
    this.onBack,
    this.onDrawer,
    this.color,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final iconColor = color ?? colors.textPrimary;

    final canPop = Navigator.of(context).canPop();
    if (canPop) {
      return IconButton(
        icon: Icon(LucideIcons.arrowLeft, color: iconColor, size: size),
        onPressed: onBack ?? () => Navigator.of(context).pop(),
        tooltip: 'Back',
      );
    }

    return IconButton(
      icon: Icon(LucideIcons.menu, color: iconColor, size: size + 2),
      onPressed: onDrawer ??
          () {
            final rootScaffold =
                context.findRootAncestorStateOfType<ScaffoldState>();
            if (rootScaffold != null && rootScaffold.hasDrawer) {
              rootScaffold.openDrawer();
            } else {
              Scaffold.of(context).openDrawer();
            }
          },
      tooltip: 'Menu',
    );
  }
}
