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
    if (decimalDigits != 2) {
      final formatter = NumberFormat.currency(
        locale: 'en_IN',
        symbol: showSymbol ? '₹' : '',
        decimalDigits: decimalDigits,
      );
      return formatter.format(value).trim();
    }
    return showSymbol ? _indianCurrencyFormat.format(value) : _indianNumberFormat.format(value).trim();
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

  static String formatSigned(double value, {bool showSymbol = true}) {
    final formatted = format(value.abs(), showSymbol: showSymbol);
    if (value > 0) {
      return '+$formatted';
    } else if (value < 0) {
      return '-$formatted';
    }
    return formatted;
  }

  static String formatPercent(double value, {bool showSign = true}) {
    final sign = value > 0 ? '+' : (value < 0 ? '-' : '');
    final absVal = value.abs().toStringAsFixed(2);
    return showSign ? '$sign$absVal%' : '$absVal%';
  }
}
