import 'package:flutter/material.dart';

@immutable
class TradingColors extends ThemeExtension<TradingColors> {
  final Color primary; // Zero Rose Pink #E82B57
  final Color secondary; // Accent Blue #2F80ED
  final Color marginValue; // Blue stats text #2D88C8
  final Color background;
  final Color surface;
  final Color cardBackground;
  final Color dockBackground; // #E8ECF2
  final Color scriptBarBackground; // #DCE3EC
  final Color bullish; // Green #00A854
  final Color bearish; // Red #E82B57
  final Color neutral;
  final Color warning;
  final Color chartGrid;
  final Color chartBackground;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color flashGreen;
  final Color flashRed;

  const TradingColors({
    required this.primary,
    required this.secondary,
    required this.marginValue,
    required this.background,
    required this.surface,
    required this.cardBackground,
    required this.dockBackground,
    required this.scriptBarBackground,
    required this.bullish,
    required this.bearish,
    required this.neutral,
    required this.warning,
    required this.chartGrid,
    required this.chartBackground,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.flashGreen,
    required this.flashRed,
  });

  static const light = TradingColors(
    primary: Color(0xFFE82B57), // Zero signature Rose Pink
    secondary: Color(0xFF2F80ED), // Script button blue
    marginValue: Color(0xFF2D88C8), // Margin card numbers
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF0F3F7),
    cardBackground: Color(0xFFFFFFFF),
    dockBackground: Color(0xFFE8ECF2), // Bottom docked margin card
    scriptBarBackground: Color(0xFFDCE3EC), // Dual script bar background
    bullish: Color(0xFF00A854),
    bearish: Color(0xFFE82B57),
    neutral: Color(0xFF787878),
    warning: Color(0xFFF5A623),
    chartGrid: Color(0xFFE8E8E8),
    chartBackground: Color(0xFFFFFFFF),
    divider: Color(0xFFE0E0E0),
    textPrimary: Color(0xFF1E232A),
    textSecondary: Color(0xFF757F8C),
    flashGreen: Color(0x3300A854),
    flashRed: Color(0x33E82B57),
  );

  static const dark = TradingColors(
    primary: Color(0xFFE82B57),
    secondary: Color(0xFF3B82F6),
    marginValue: Color(0xFF3E99D6),
    background: Color(0xFF000000), // Pure OLED Black
    surface: Color(0xFF121212), // Neutral Dark Surface (No blue tint)
    cardBackground: Color(0xFF181818), // Neutral Dark Card (No blue tint)
    dockBackground: Color(0xFF121212), // Neutral Dark Dock (No blue tint)
    scriptBarBackground: Color(0xFF181818), // Neutral Dark Script Bar (No blue tint)
    bullish: Color(0xFF26A69A),
    bearish: Color(0xFFFF4D6D),
    neutral: Color(0xFF8B949E),
    warning: Color(0xFFF5A623),
    chartGrid: Color(0xFF222222), // Neutral Dark Grid (No blue tint)
    chartBackground: Color(0xFF000000), // Pure Black Chart Background
    divider: Color(0xFF262626), // Neutral Dark Divider (No blue tint)
    textPrimary: Color(0xFFF5F5F5), // High-contrast Crisp White
    textSecondary: Color(0xFF9E9E9E), // Neutral Silver Gray
    flashGreen: Color(0x3326A69A),
    flashRed: Color(0x33FF4D6D),
  );

  @override
  ThemeExtension<TradingColors> copyWith({
    Color? primary,
    Color? secondary,
    Color? marginValue,
    Color? background,
    Color? surface,
    Color? cardBackground,
    Color? dockBackground,
    Color? scriptBarBackground,
    Color? bullish,
    Color? bearish,
    Color? neutral,
    Color? warning,
    Color? chartGrid,
    Color? chartBackground,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? flashGreen,
    Color? flashRed,
  }) {
    return TradingColors(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      marginValue: marginValue ?? this.marginValue,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      cardBackground: cardBackground ?? this.cardBackground,
      dockBackground: dockBackground ?? this.dockBackground,
      scriptBarBackground: scriptBarBackground ?? this.scriptBarBackground,
      bullish: bullish ?? this.bullish,
      bearish: bearish ?? this.bearish,
      neutral: neutral ?? this.neutral,
      warning: warning ?? this.warning,
      chartGrid: chartGrid ?? this.chartGrid,
      chartBackground: chartBackground ?? this.chartBackground,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      flashGreen: flashGreen ?? this.flashGreen,
      flashRed: flashRed ?? this.flashRed,
    );
  }

  @override
  ThemeExtension<TradingColors> lerp(
    covariant ThemeExtension<TradingColors>? other,
    double t,
  ) {
    if (other is! TradingColors) {
      return this;
    }
    return TradingColors(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      marginValue: Color.lerp(marginValue, other.marginValue, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      dockBackground: Color.lerp(dockBackground, other.dockBackground, t)!,
      scriptBarBackground:
          Color.lerp(scriptBarBackground, other.scriptBarBackground, t)!,
      bullish: Color.lerp(bullish, other.bullish, t)!,
      bearish: Color.lerp(bearish, other.bearish, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      chartGrid: Color.lerp(chartGrid, other.chartGrid, t)!,
      chartBackground: Color.lerp(chartBackground, other.chartBackground, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      flashGreen: Color.lerp(flashGreen, other.flashGreen, t)!,
      flashRed: Color.lerp(flashRed, other.flashRed, t)!,
    );
  }
}

extension TradingColorsExtension on BuildContext {
  TradingColors get tradingColors {
    return Theme.of(this).extension<TradingColors>() ?? TradingColors.light;
  }
}
