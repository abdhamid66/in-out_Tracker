class Transaksi {
  final String id;
  final String judul;
  final double nominal;
  final bool isPemasukan;
  final DateTime tanggal;

  Transaksi({
    required this.id,
    required this.judul,
    required this.nominal,
    required this.isPemasukan,
    required this.tanggal,
  });
}