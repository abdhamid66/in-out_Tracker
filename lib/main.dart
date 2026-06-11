import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  // Wajib dipanggil pertama kali
  WidgetsFlutterBinding.ensureInitialized();
  
  // Kita pasang CCTV (Try-Catch) biar kalau Firebase gagal, aplikasi tetap mau jalan
  try {
    print("⏳ Sedang mencoba menyalakan mesin Firebase...");
    await Firebase.initializeApp();
    print("✅ MANTAP! Firebase berhasil nyala!");
  } catch (e) {
    print("❌ WADUH! Gagal menyalakan Firebase. Error-nya: $e");
  }

  // Paksa aplikasi untuk tetap me-render tampilan UI
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'In-Out Tracker',
      theme: ThemeData(
        // menggunakan warna teal sebagai warna utama aplikasi dengan menggunakan ColorScheme.fromSeed untuk menghasilkan skema warna yang konsisten berdasarkan warna utama yang dipilih, serta mengaktifkan penggunaan Material3 untuk mendapatkan tampilan yang lebih modern dan sesuai dengan desain terbaru dari Google.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,// menggunakan Material3 untuk mendapatkan tampilan yang lebih modern dan sesuai dengan desain terbaru dari Google.
      ),
        home: const LoginScreen(),
      );
  }
}