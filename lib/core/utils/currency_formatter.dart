import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _indianCurrencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _indianNumberFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '',
    decimalDigits: 2,
  );

  static String format(double value, {bool showSymbol = true, int decimalDigits = 2}) {
    // Sanitize floating point negative zero (-0.0)
    final sanitizedValue = value.abs() < 1e-9 ? 0.0 : value;
    if (decimalDigits != 2) {
      final formatter = NumberFormat.currency(
        locale: 'en_IN',
        symbol: showSymbol ? '₹' : '',
        decimalDigits: decimalDigits,
      );
      return formatter.format(sanitizedValue).trim();
    }
    return showSymbol
        ? _indianCurrencyFormat.format(sanitizedValue)
        : _indianNumberFormat.format(sanitizedValue).trim();
  }

  static String formatCompact(double value) {
    final abs = value.abs();
    final sign = value < 0 ? '-' : '';
    if (abs >= 10000000) {
      return '$sign₹${(abs / 10000000).toStringAsFixed(2)} Cr';
    } else if (abs >= 100000) {
      return '$sign₹${(abs / 100000).toStringAsFixed(2)} L';
    } else if (abs >= 1000) {
      return '$sign₹${(abs / 1000).toStringAsFixed(2)} k';
    }
    return format(value);
  }

  static String formatSigned(double value, {bool showSymbol = true, int decimalDigits = 2}) {
    // Zero P&L: clean neutral format without '+' or '-' or '-₹0.00'
    if (value.abs() < 1e-9) {
      return format(0.0, showSymbol: showSymbol, decimalDigits: decimalDigits);
    }
    final formatted = format(value.abs(), showSymbol: showSymbol, decimalDigits: decimalDigits);
    if (value > 0) {
      return '+$formatted';
    } else {
      return '-$formatted';
    }
  }

  /// Preserves required precision for micro-prices (e.g. penny stocks, forex, crypto)
  static String formatPrice(
    double value, {
    bool showSymbol = false,
    int minDecimals = 2,
    int maxDecimals = 4,
  }) {
    final sanitized = value.abs() < 1e-9 ? 0.0 : value;
    // Check if value has significant digits beyond 2 decimals
    final strVal = sanitized.toString();
    int decimals = 2;
    if (strVal.contains('.')) {
      final fractional = strVal.split('.')[1];
      decimals = fractional.length.clamp(minDecimals, maxDecimals);
      // If trailing zeros only, keep at least minDecimals
      if (decimals < minDecimals) decimals = minDecimals;
    }
    return format(sanitized, showSymbol: showSymbol, decimalDigits: decimals);
  }

  /// Validates order quantity precision against exchange rules
  static bool validateQuantityPrecision(double quantity, {bool allowFractional = false}) {
    if (quantity <= 0) return false;
    if (!allowFractional) {
      return quantity == quantity.roundToDouble();
    }
    final str = quantity.toString();
    if (!str.contains('.')) return true;
    final decimalPart = str.split('.')[1];
    return decimalPart.length <= 4;
  }

  static String formatPercent(double value, {bool showSign = true}) {
    if (value.abs() < 1e-9) {
      return '0.00%';
    }
    final sign = value > 0 ? '+' : '-';
    final absVal = value.abs().toStringAsFixed(2);
    return showSign ? '$sign$absVal%' : '$absVal%';
  }
}
