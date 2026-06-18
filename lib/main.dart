import 'package:flutter/material.dart';
import 'screens/splash_screen.dart'; // 👇 INI YANG DITAMBAH
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/kategori_service.dart';
void main() async {
  // Wajib dipanggil biar mesin Flutter siap menerima perintah mesin luar
  WidgetsFlutterBinding.ensureInitialized();
  
  // Menyalakan saklar utama Firebase!
  await Firebase.initializeApp();

  // Load pengaturan kategori custom
  await KategoriService.init();

  // Menjalankan aplikasimu
  runApp(const MyApp()); // Pastikan nama MyApp() sesuai dengan nama class utama aplikasimu
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'In-Out Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006D5B)),
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F9FA),
          foregroundColor: Color(0xFF006D5B),
          elevation: 0,
        ),
      ),
      home: const SplashScreen(), // 👇 INI YANG DIGANTI
    );
  }
}