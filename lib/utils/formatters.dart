import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _numberFormat = NumberFormat('#,##0', 'en');

  /// يعرض الأرقام بفواصل الآلاف مع "د.ع" (دينار عراقي)
  static String currency(num value) {
    return '${_numberFormat.format(value)} د.ع';
  }

  static String number(num value) => _numberFormat.format(value);

  static String date(String isoDate) {
    try {
      final d = DateTime.parse(isoDate);
      return DateFormat('yyyy/MM/dd').format(d);
    } catch (_) {
      return isoDate;
    }
  }

  static String todayIso() => DateTime.now().toIso8601String().split('T').first;
}
