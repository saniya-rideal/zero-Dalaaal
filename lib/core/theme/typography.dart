import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static const List<FontFeature> tabularFontFeatures = [
    FontFeature.tabularFigures(),
  ];

  static TextStyle display({
    Color? color,
    FontWeight weight = FontWeight.w600,
    bool tabular = true,
  }) {
    return GoogleFonts.inter(
      fontSize: 28,
      fontWeight: weight,
      color: color,
      fontFeatures: tabular ? tabularFontFeatures : null,
      letterSpacing: -0.5,
    );
  }

  static TextStyle h1({
    Color? color,
    FontWeight weight = FontWeight.w600,
    bool tabular = false,
  }) {
    return GoogleFonts.inter(
      fontSize: 20,
      fontWeight: weight,
      color: color,
      fontFeatures: tabular ? tabularFontFeatures : null,
      letterSpacing: -0.2,
    );
  }

  static TextStyle h2({
    Color? color,
    FontWeight weight = FontWeight.w600,
    bool tabular = false,
  }) {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: weight,
      color: color,
      fontFeatures: tabular ? tabularFontFeatures : null,
    );
  }

  static TextStyle body({
    Color? color,
    FontWeight weight = FontWeight.w400,
    bool tabular = false,
  }) {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: weight,
      color: color,
      fontFeatures: tabular ? tabularFontFeatures : null,
    );
  }

  static TextStyle caption({
    Color? color,
    FontWeight weight = FontWeight.w400,
    bool tabular = false,
  }) {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: weight,
      color: color,
      fontFeatures: tabular ? tabularFontFeatures : null,
    );
  }

  static TextStyle labelSmall({
    Color? color,
    FontWeight weight = FontWeight.w500,
    bool tabular = false,
  }) {
    return GoogleFonts.inter(
      fontSize: 11,
      fontWeight: weight,
      color: color,
      fontFeatures: tabular ? tabularFontFeatures : null,
    );
  }
}
