import 'package:intl/intl.dart';

String formatRupiah(double angka) {
  final formatBaru = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  return formatBaru.format(angka);
}
