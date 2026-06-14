import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _cekArahTujuan(); // Jalankan fungsi pengecekan saat layar dibuka
  }

  // Fungsi untuk mengecek lemari memori HP
  Future<void> _cekArahTujuan() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Cek apakah ada catatan 'sudah_onboarding'? Kalau kosong, anggap false (belum)
    bool sudahOnboarding = prefs.getBool('sudah_onboarding') ?? false;

    // Timer 3 detik biar logonya kelihatan dulu
    Timer(const Duration(seconds: 3), () {
      if (sudahOnboarding) {
        // Kalau SUDAH, lempar langsung ke Beranda
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // Kalau BELUM, lempar ke Onboarding Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF006D5B), 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.account_balance_wallet,
              size: 100,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              'In-Out Tracker',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Kelola Keuanganmu dengan Cerdas',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}