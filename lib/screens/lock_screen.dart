import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'home_screen.dart';
import 'package:flutter/services.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) {
        // Jika tidak mendukung biometrik, langsung masuk
        _goToHome();
        return;
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Gunakan sidik jari atau PIN/Pola untuk masuk ke aplikasi In-Out Tracker',
        persistAcrossBackgrounding: true,
        biometricOnly: false,
      );

      if (didAuthenticate) {
        setState(() {
          _isAuthenticated = true;
        });
        _goToHome();
      }
    } on PlatformException catch (e) {
      debugPrint("Error saat autentikasi biometrik: $e");
    }
  }

  void _goToHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF006D5B).withValues(alpha: 0.1),
                ),
                child: const Icon(Icons.lock_outline_rounded, size: 80, color: Color(0xFF006D5B)),
              ),
              const SizedBox(height: 30),
              const Text(
                'Aplikasi Terkunci',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              const Text(
                'Harap verifikasi identitas Anda untuk melanjutkan',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 50),
              if (!_isAuthenticated)
                ElevatedButton.icon(
                  onPressed: _authenticate,
                  icon: const Icon(Icons.fingerprint_rounded, size: 28),
                  label: const Text('Buka Kunci', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006D5B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
