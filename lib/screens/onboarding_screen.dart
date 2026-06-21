import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'tos_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _halamanSekarang = 0;

  // Daftar konten untuk tiap slide onboarding
  final List<Map<String, dynamic>> _dataOnboarding = [
    {
      "icon": Icons.account_balance_wallet_outlined,
      "judul": "Catat dengan Mudah",
      "deskripsi": "Lacak setiap pemasukan dan pengeluaranmu hanya dalam beberapa ketukan."
    },
    {
      "icon": Icons.bar_chart_rounded,
      "judul": "Pantau Arus Kas",
      "deskripsi": "Grafik interaktif untuk melihat ke mana uangmu pergi setiap bulannya."
    },
    {
      "icon": Icons.security,
      "judul": "Aman & Offline",
      "deskripsi": "Data keuanganmu tersimpan aman secara lokal di dalam HP-mu sendiri."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _halamanSekarang = index;
                  });
                },
                itemCount: _dataOnboarding.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _dataOnboarding[index]["icon"],
                          size: 150,
                          color: const Color(0xFF006D5B),
                        ),
                        const SizedBox(height: 50),
                        Text(
                          _dataOnboarding[index]["judul"],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF006D5B),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _dataOnboarding[index]["deskripsi"],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // BAGIAN BAWAH: Titik indikator dan Tombol
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Titik-titik indikator halaman
                  Row(
                    children: List.generate(
                      _dataOnboarding.length,
                      (index) => Container(
                        margin: const EdgeInsets.only(right: 5),
                        height: 10,
                        width: _halamanSekarang == index ? 25 : 10,
                        decoration: BoxDecoration(
                          color: _halamanSekarang == index
                              ? const Color(0xFF006D5B)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),

                  // Tombol Lanjut / Mulai
                  ElevatedButton(
                    onPressed: () async {
                      // Kalau sudah di slide terakhir
                      if (_halamanSekarang == _dataOnboarding.length - 1) {
                        // SIMPAN MEMORI BAHWA USER SUDAH PERNAH LIHAT ONBOARDING
                        if (!context.mounted) return;
                        // Pindah ke Halaman Syarat dan Ketentuan (ToS)
                        Navigator.pushReplacement(
                          context,  
                          MaterialPageRoute(builder: (context) => const TosScreen()),
                        );
                      } else {
                        // Kalau belum terakhir, geser ke slide berikutnya
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006D5B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    child: Text(
                      _halamanSekarang == _dataOnboarding.length - 1 ? "Mulai" : "Lanjut",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
