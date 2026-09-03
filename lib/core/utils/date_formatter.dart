import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _orderTimeFormat = DateFormat('HH:mm:ss');
  static final DateFormat _orderDateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _orderFullDateTimeFormat = DateFormat('dd MMM yyyy, HH:mm:ss');
  static final DateFormat _expiryFormat = DateFormat('dd MMM');
  static final DateFormat _chartTimeFormat = DateFormat('HH:mm');
  static final DateFormat _chartDateFormat = DateFormat('dd/MM');

  static String formatOrderTime(DateTime dt) => _orderTimeFormat.format(dt);
  static String formatOrderDate(DateTime dt) => _orderDateFormat.format(dt);
  static String formatOrderDateTime(DateTime dt) => _orderFullDateTimeFormat.format(dt);
  static String formatExpiry(DateTime dt) => _expiryFormat.format(dt);
  static String formatChartTime(DateTime dt) => _chartTimeFormat.format(dt);
  static String formatChartDate(DateTime dt) => _chartDateFormat.format(dt);
}
