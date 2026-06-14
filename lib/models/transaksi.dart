import 'package:flutter/material.dart';

class Transaksi {
  final String id;
  final String judul;
  final double nominal;
  final bool isPemasukan;
  final DateTime tanggal;
  final String kategori; // Tambahan field kategori

  Transaksi({
    required this.id,
    required this.judul,
    required this.nominal,
    required this.isPemasukan,
    required this.tanggal,
    required this.kategori,
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
      'kategori': kategori, // Simpan kategori
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
      kategori: map['kategori'] ?? 'Lainnya', // Ambil kategori, default 'Lainnya' jika null (misal dari data lama)
    );
  }

  // Helper untuk mendapatkan Icon berdasarkan Kategori
  static IconData getIconForKategori(String kategori) {
    switch (kategori) {
      case 'Makanan': return Icons.fastfood_rounded;
      case 'Transportasi': return Icons.directions_car_rounded;
      case 'Hiburan': return Icons.movie_creation_rounded;
      case 'Belanja': return Icons.shopping_bag_rounded;
      case 'Tagihan': return Icons.receipt_long_rounded;
      case 'Gaji': return Icons.account_balance_wallet_rounded;
      case 'Bonus': return Icons.card_giftcard_rounded;
      case 'Bisnis': return Icons.storefront_rounded;
      default: return Icons.category_rounded;
    }
  }
}