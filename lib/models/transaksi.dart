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

  // PENERJEMAH 1: Dari Aplikasi ke Database (Menyimpan)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'judul': judul,
      'nominal': nominal,
      // Jika isPemasukan itu true, maka simpan 1. Jika false, simpan 0.
      'isPemasukan': isPemasukan ? 1 : 0, 
      // Ubah format waktu menjadi Teks (String) agar bisa disimpan
      'tanggal': tanggal.toIso8601String(), 
    };
  }

  // PENERJEMAH 2: Dari Database ke Aplikasi (Membaca)
  factory Transaksi.fromMap(Map<String, dynamic> map) {
    return Transaksi(
      id: map['id'],
      judul: map['judul'],
      nominal: (map['nominal'] as num).toDouble(),
      // Jika angka di database adalah 1, maka kembalikan jadi true.
      isPemasukan: map['isPemasukan'] == 1, 
      // Ubah kembali Teks menjadi format Waktu (DateTime)
      tanggal: DateTime.parse(map['tanggal']), 
    );
  }
}