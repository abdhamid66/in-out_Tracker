import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class TosScreen extends StatefulWidget {
  final bool isFromSettings;
  const TosScreen({super.key, this.isFromSettings = false});

  @override
  State<TosScreen> createState() => _TosScreenState();
}

class _TosScreenState extends State<TosScreen> {
  // Variabel untuk mengecek apakah kotak sudah dicentang
  bool _isAgreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Syarat & Ketentuan',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: widget.isFromSettings, // Tampilkan tombol back jika dari settings
      ),
      body: SafeArea(
        child: Column(
          children: [
            // KOTAK TEKS PERATURAN (Bisa di-scroll)
            Expanded(
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
                        'Selamat datang di In-Out Tracker!',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 15),
                      Text(
                        'Dengan menggunakan aplikasi ini, Anda menyetujui persyaratan berikut:\n\n'
                        '1. Privasi & Keamanan Data\n'
                        'Aplikasi ini dirancang mengutamakan privasi Anda. Seluruh data transaksi keuangan, termasuk nominal dan riwayat, disimpan secara LOKAL di dalam perangkat (HP) Anda menggunakan SQLite. Kami tidak mengirim, menyalin, atau menyimpan data keuangan Anda di server luar mana pun.\n\n'
                        '2. Penggunaan Akun Google\n'
                        'Fitur Login Google hanya digunakan sebagai identitas profil (Nama dan Foto) untuk personalisasi tampilan aplikasi, bukan untuk menyinkronkan data transaksi ke cloud.\n\n'
                        '3. Tanggung Jawab Kehilangan Data\n'
                        'Karena data disimpan secara offline di perangkat, kehilangan data akibat penghapusan aplikasi (uninstall) atau kerusakan perangkat adalah tanggung jawab pengguna. Kami telah menyediakan fitur "Ekspor ke Excel" agar Anda dapat melakukan pencadangan (backup) secara mandiri.\n\n'
                        '4. Perubahan Syarat & Ketentuan\n'
                        'Kami berhak mengubah syarat dan ketentuan ini di masa mendatang untuk menyesuaikan dengan pembaruan fitur aplikasi.',
                        style: TextStyle(height: 1.6, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // BAGIAN CHECKBOX DAN TOMBOL (Hanya tampil saat Onboarding)
            if (!widget.isFromSettings)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _isAgreed,
                        activeColor: const Color(0xFF006D5B),
                        onChanged: (bool? value) {
                          setState(() {
                            _isAgreed = value ?? false;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'Saya telah membaca dan menyetujui Syarat & Ketentuan di atas.',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isAgreed
                          ? () async {
                              // SIMPAN MEMORI BAHWA USER SUDAH MELEWATI ONBOARDING & TOS
                              SharedPreferences prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('sudah_onboarding', true);

                              if (!context.mounted) return;
                              // Lempar ke Beranda
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const HomeScreen()),
                              );
                            }
                          : null, // Kalau belum centang, tombol mati (null)
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006D5B),
                        disabledBackgroundColor: Colors.grey.shade300, // Warna saat tombol mati
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Setuju & Lanjutkan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
