import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ZeroNavIcons {
  /// Tab 0: Quotes (Crisp dual vertical arrows: Up & Down)
  static Widget quotesIcon({required Color color, double size = 22}) {
    return Icon(
      LucideIcons.arrowUpDown,
      color: color,
      size: size,
    );
  }

  /// Tab 1: Deals (Sleek candlestick financial chart / trades)
  static Widget dealsIcon({required Color color, double size = 22}) {
    return Icon(
      LucideIcons.candlestickChart,
      color: color,
      size: size,
    );
  }

  /// Tab 2: Net Deals (Layered portfolio positions summary)
  static Widget netDealsIcon({required Color color, double size = 22}) {
    return Icon(
      LucideIcons.layers,
      color: color,
      size: size,
    );
  }

  /// Tab 3: History (Crisp timeline clock with reverse arrow)
  static Widget historyIcon({required Color color, double size = 22}) {
    return Icon(
      LucideIcons.history,
      color: color,
      size: size,
    );
  }
}
