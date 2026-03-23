import 'package:intl/intl.dart';

abstract final class PercentFormat {
  static String signedPercent(double value, String locale) {
    final digits = NumberFormat.decimalPattern(locale);
    final core = digits.format(value.abs());
    if (value > 0) {
      return '+$core%';
    }
    if (value < 0) {
      return '-$core%';
    }
    return '$core%';
  }
}
