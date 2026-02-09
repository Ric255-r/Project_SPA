import 'package:intl/intl.dart';

String formatRupiah(double amount) {
  final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
  return formatter.format(amount);
}

String formatRupiahShort(double amount) {
  if (amount >= 1000000) {
    final double juta = amount / 1000000;
    final bool isWhole = (juta - juta.truncateToDouble()).abs() < 0.000001;
    if (isWhole) {
      return 'Rp${juta.toInt()}Jt';
    }
    final String jutaStr = juta.toStringAsFixed(1);
    return 'Rp${jutaStr}Jt';
  } else if (amount >= 1000) {
    return 'Rp${(amount / 1000).toInt()}Rb';
  } else {
    return formatRupiah(amount);
  }
}
