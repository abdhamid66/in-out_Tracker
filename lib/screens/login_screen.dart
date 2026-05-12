import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String enteredPin = "";
  String? savedPin; // Menyimpan PIN dari memori HP
  bool isLoading = true; // Indikator loading saat ngecek PIN

  @override
  void initState() {
    super.initState();
    _checkSavedPin(); // Cek PIN saat layar dibuka
  }

  // Fungsi untuk ngecek apakah user sudah pernah bikin PIN atau belum
  Future<void> _checkSavedPin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      savedPin = prefs.getString('user_pin');
      isLoading = false;
    });
  }

  // Fungsi saat angka ditekan
  void _onPinPadTapped(String number) {
    if (enteredPin.length < 4) {
      setState(() {
        enteredPin += number;
      });

      // Cek otomatis kalau sudah 4 digit
      if (enteredPin.length == 4) {
        Future.delayed(const Duration(milliseconds: 200), () async {
          
          if (savedPin == null) {
            // SKENARIO 1: USER BARU PERTAMA KALI BUKA APLIKASI
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_pin', enteredPin); // Simpan PIN ke memori HP
            
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PIN Berhasil Dibuat!'), backgroundColor: Color(0xFF138D75)),
            );
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
            
          } else {
            // SKENARIO 2: USER SUDAH PUNYA PIN
            if (enteredPin == savedPin) {
              // PIN Benar
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
            } else {
              // PIN Salah
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PIN Salah! Silakan coba lagi.'), backgroundColor: Colors.redAccent, duration: Duration(seconds: 1)),
              );
              setState(() {
                enteredPin = ""; // Reset isian
              });
            }
          }
        });
      }
    }
  }

  void _onBackspaceTapped() {
    if (enteredPin.isNotEmpty) {
      setState(() {
        enteredPin = enteredPin.substring(0, enteredPin.length - 1);
      });
    }
  }

  Widget _buildPinDot(int index) {
    bool isFilled = index < enteredPin.length;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isFilled ? const Color(0xFF006D5B) : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return GestureDetector(
      onTap: () => _onPinPadTapped(number),
      child: Container(
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          shape: BoxShape.circle, color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Center(child: Text(number, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF006D5B)))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Kalau masih loading ngecek lemari memori, tampilkan layar kosong sebentar
    if (isLoading) return const Scaffold(backgroundColor: Color(0xFFF8F9FA));

    // Menentukan teks berdasarkan status PIN
    bool isNewUser = savedPin == null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Icon(isNewUser ? Icons.lock_person_rounded : Icons.lock_outline_rounded, size: 60, color: const Color(0xFF006D5B)),
            const SizedBox(height: 20),
            Text(
              isNewUser ? 'Buat PIN Baru' : 'Masukkan PIN',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              isNewUser ? 'Buat 4 digit PIN untuk mengamankan aplikasimu' : 'Masukkan 4 digit PIN In-Out Tracker kamu',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 40),

            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (index) => _buildPinDot(index))),
            
            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildNumberButton('1'), _buildNumberButton('2'), _buildNumberButton('3')]),
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildNumberButton('4'), _buildNumberButton('5'), _buildNumberButton('6')]),
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildNumberButton('7'), _buildNumberButton('8'), _buildNumberButton('9')]),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 75, height: 75), // Tombol sidik jari dihilangkan dulu biar rapi
                      _buildNumberButton('0'),
                      SizedBox(width: 75, height: 75, child: IconButton(icon: const Icon(Icons.backspace_outlined, size: 28, color: Colors.grey), onPressed: _onBackspaceTapped)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}