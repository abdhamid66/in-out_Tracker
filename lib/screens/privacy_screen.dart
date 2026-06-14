import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Kebijakan Privasi',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Kebijakan Privasi In-Out Tracker',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 15),
                Text(
                  'Terakhir diperbarui: 14 Juni 2026\n\n'
                  'Kami sangat menghargai privasi Anda. Kebijakan ini menjelaskan bagaimana kami mengumpulkan, menggunakan, dan melindungi informasi Anda.\n\n'
                  '1. Pengumpulan Data\n'
                  'Kami hanya mengumpulkan informasi profil dasar (Nama, Email, dan Foto Profil) saat Anda melakukan login menggunakan akun Google. Kami TIDAK mengumpulkan data transaksi keuangan Anda. Semua data transaksi disimpan murni di memori lokal HP Anda (SQLite).\n\n'
                  '2. Penggunaan Data\n'
                  'Data profil (Nama & Foto) hanya digunakan semata-mata untuk ditampilkan di Halaman Profil dalam aplikasi ini, guna memberikan pengalaman personalisasi.\n\n'
                  '3. Berbagi Data\n'
                  'Kami TIDAK PERNAH menjual, menyewakan, atau membagikan data profil maupun transaksi Anda kepada pihak ketiga mana pun.\n\n'
                  '4. Hak Akses (Izin Perangkat)\n'
                  'Aplikasi ini mungkin meminta izin penyimpanan (storage) HANYA untuk fitur ekspor data transaksi ke file Excel.\n\n'
                  '5. Keamanan\n'
                  'Karena data keuangan berada di perangkat Anda sendiri, keamanan dari peretasan jaringan eksternal terjamin. Namun, Anda bertanggung jawab untuk menjaga keamanan fisik perangkat (HP) Anda.\n\n'
                  'Dengan menggunakan In-Out Tracker, Anda menyetujui Kebijakan Privasi ini.',
                  style: TextStyle(height: 1.6, color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
