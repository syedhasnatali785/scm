import 'package:intl/intl.dart';

class Formatters {
  static final _currencyFormat = NumberFormat('#,##0', 'en_US');
  static final _decimalFormat = NumberFormat('#,##0.0', 'en_US');

  /// Formats currency with Pakistani Rupee prefix (e.g. ₨ 18,450,000)
  static String pkr(double amount) {
    return '₨ ${_currencyFormat.format(amount.round())}';
  }

  /// Compact representation (e.g. ₨ 18.5M)
  static String pkrCompact(double amount) {
    if (amount >= 10000000) {
      // 1 Crore = 10M
      return '₨ ${_decimalFormat.format(amount / 10000000)} Cr';
    } else if (amount >= 1000000) {
      return '₨ ${_decimalFormat.format(amount / 1000000)} M';
    } else if (amount >= 100000) {
      // 1 Lakh = 100k
      return '₨ ${_decimalFormat.format(amount / 100000)} Lakh';
    } else {
      return '₨ ${_currencyFormat.format(amount.round())}';
    }
  }

  static String number(num value) {
    return _currencyFormat.format(value);
  }

  static String decimal(double value, {int decimals = 1}) {
    return value.toStringAsFixed(decimals);
  }

  static String percent(double value) {
    return '${value.toStringAsFixed(1)}%';
  }
}
