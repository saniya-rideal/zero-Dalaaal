import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme/trading_colors.dart';
import 'zero_nav_icons.dart';

class ZeroBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onCenterToggle;
  final bool isExpanded;

  const ZeroBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onCenterToggle,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;

    return Container(
      height: 62,
      color: colors.background,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Background Custom Paint with the smooth downward curved grey dip
          Positioned.fill(
            child: CustomPaint(
              painter: _ZeroNavBackgroundPainter(
                dockColor: colors.dockBackground,
                navBgColor: colors.background,
                borderColor: colors.divider.withValues(alpha: 0.3),
              ),
            ),
          ),

          // 4 Tab Items Row
          Positioned.fill(
            child: Row(
              children: [
                // Tab 0: Quotes
                Expanded(
                  child: _buildItem(
                    index: 0,
                    label: 'Quotes',
                    icon: ZeroNavIcons.quotesIcon(
                      color: currentIndex == 0 ? colors.primary : colors.textPrimary,
                      size: 22,
                    ),
                    isSelected: currentIndex == 0,
                    colors: colors,
                  ),
                ),
                // Tab 1: Deals
                Expanded(
                  child: _buildItem(
                    index: 1,
                    label: 'Deals',
                    icon: ZeroNavIcons.dealsIcon(
                      color: currentIndex == 1 ? colors.primary : colors.textPrimary,
                      size: 22,
                    ),
                    isSelected: currentIndex == 1,
                    colors: colors,
                  ),
                ),

                // Center Spacer for the pink button & curved dip
                const SizedBox(width: 60),

                // Tab 2: Net Deals
                Expanded(
                  child: _buildItem(
                    index: 2,
                    label: 'Net Deals',
                    icon: ZeroNavIcons.netDealsIcon(
                      color: currentIndex == 2 ? colors.primary : colors.textPrimary,
                      size: 22,
                    ),
                    isSelected: currentIndex == 2,
                    colors: colors,
                  ),
                ),
                // Tab 3: History
                Expanded(
                  child: _buildItem(
                    index: 3,
                    label: 'History',
                    icon: ZeroNavIcons.historyIcon(
                      color: currentIndex == 3 ? colors.primary : colors.textPrimary,
                      size: 22,
                    ),
                    isSelected: currentIndex == 3,
                    colors: colors,
                  ),
                ),
              ],
            ),
          ),

          // Center Pink Floating Button inside the grey downward curved dip
          Positioned(
            top: 4,
            child: Tooltip(
              message: isExpanded ? 'Hide Margin Dock' : 'Show Margin Dock',
              child: Semantics(
                button: true,
                label: isExpanded ? 'Hide Margin Dock' : 'Show Margin Dock',
                child: GestureDetector(
                  onTap: onCenterToggle,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.30),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: AnimatedRotation(
                        turns: isExpanded ? 0.0 : 0.5,
                        duration: const Duration(milliseconds: 250),
                        child: const Icon(
                          LucideIcons.chevronDown,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required int index,
    required String label,
    required Widget icon,
    required bool isSelected,
    required TradingColors colors,
  }) {
    final activeColor = colors.primary;
    final inactiveColor = colors.textSecondary;

    return InkWell(
      onTap: () => onTabSelected(index),
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 2),
          icon,
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              color: isSelected ? activeColor : inactiveColor,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ZeroNavBackgroundPainter extends CustomPainter {
  final Color dockColor;
  final Color navBgColor;
  final Color borderColor;

  _ZeroNavBackgroundPainter({
    required this.dockColor,
    required this.navBgColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // 1. Fill bottom nav with pure white
    final whitePaint = Paint()..color = navBgColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), whitePaint);

    // 2. Draw the smooth downward curved tongue in dockColor (#E8ECF2)
    final path = Path();
    const dipWidth = 32.0; // half-width of dip
    const dipDepth = 48.0; // depth of downward dip

    path.moveTo(cx - dipWidth - 24, 0);
    // Smooth transition from top line into downward dip
    path.cubicTo(
      cx - dipWidth, 0,
      cx - dipWidth + 2, dipDepth,
      cx, dipDepth,
    );
    path.cubicTo(
      cx + dipWidth - 2, dipDepth,
      cx + dipWidth, 0,
      cx + dipWidth + 24, 0,
    );
    path.close();

    final dockPaint = Paint()
      ..color = dockColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, dockPaint);

    // 3. Subtle top horizontal border line
    final linePaint = Paint()
      ..color = borderColor
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset.zero, Offset(cx - dipWidth - 24, 0), linePaint);
    canvas.drawLine(Offset(cx + dipWidth + 24, 0), Offset(w, 0), linePaint);
  }

  @override
  bool shouldRepaint(covariant _ZeroNavBackgroundPainter oldDelegate) =>
      oldDelegate.dockColor != dockColor ||
      oldDelegate.navBgColor != navBgColor ||
      oldDelegate.borderColor != borderColor;
}
