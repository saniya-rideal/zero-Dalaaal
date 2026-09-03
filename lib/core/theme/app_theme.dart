import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'trading_colors.dart';
import 'typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    const tradingColors = TradingColors.light;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: tradingColors.primary,
      scaffoldBackgroundColor: tradingColors.background,
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      colorScheme: ColorScheme.light(
        primary: tradingColors.primary,
        secondary: tradingColors.secondary,
        surface: tradingColors.surface,
        error: tradingColors.bearish,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: tradingColors.textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: tradingColors.background,
        foregroundColor: tradingColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        centerTitle: false,
        titleTextStyle: AppTypography.h1(
          color: tradingColors.textPrimary,
          weight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: tradingColors.background,
        selectedItemColor: tradingColors.primary,
        unselectedItemColor: tradingColors.textSecondary,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: DividerThemeData(
        color: tradingColors.divider,
        thickness: 0.5,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: tradingColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: tradingColors.divider, width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tradingColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: AppTypography.body(weight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tradingColors.primary,
          side: BorderSide(color: tradingColors.primary, width: 1.0),
          textStyle: AppTypography.body(weight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tradingColors.primary,
          textStyle: AppTypography.body(weight: FontWeight.w600),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: tradingColors.primary,
        unselectedLabelColor: tradingColors.textSecondary,
        indicatorColor: tradingColors.primary,
        labelStyle: AppTypography.body(weight: FontWeight.w600),
        unselectedLabelStyle: AppTypography.body(weight: FontWeight.w400),
      ),
      extensions: const [
        TradingColors.light,
      ],
    );
  }

  static ThemeData get darkTheme {
    const tradingColors = TradingColors.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: tradingColors.primary,
      scaffoldBackgroundColor: tradingColors.background,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      colorScheme: ColorScheme.dark(
        primary: tradingColors.primary,
        secondary: tradingColors.secondary,
        surface: tradingColors.surface,
        error: tradingColors.bearish,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: tradingColors.textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: tradingColors.background,
        foregroundColor: tradingColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        centerTitle: false,
        titleTextStyle: AppTypography.h1(
          color: tradingColors.textPrimary,
          weight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: tradingColors.surface,
        selectedItemColor: tradingColors.primary,
        unselectedItemColor: tradingColors.textSecondary,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: DividerThemeData(
        color: tradingColors.divider,
        thickness: 0.5,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: tradingColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: tradingColors.divider, width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tradingColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: AppTypography.body(weight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tradingColors.primary,
          side: BorderSide(color: tradingColors.primary, width: 1.0),
          textStyle: AppTypography.body(weight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tradingColors.primary,
          textStyle: AppTypography.body(weight: FontWeight.w600),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: tradingColors.primary,
        unselectedLabelColor: tradingColors.textSecondary,
        indicatorColor: tradingColors.primary,
        labelStyle: AppTypography.body(weight: FontWeight.w600),
        unselectedLabelStyle: AppTypography.body(weight: FontWeight.w400),
      ),
      extensions: const [
        TradingColors.dark,
      ],
    );
  }
}
