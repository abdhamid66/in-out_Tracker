import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/kategori_service.dart';
import 'providers/transaksi_provider.dart';
import 'package:out_tracker/theme/app_theme.dart';

void main() async {
  // Wajib dipanggil biar mesin Flutter siap menerima perintah mesin luar
  WidgetsFlutterBinding.ensureInitialized();
  
  // Menyalakan saklar utama Firebase!
  await Firebase.initializeApp();

  // Load pengaturan kategori custom
  await KategoriService.init();

  // Menjalankan aplikasimu
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransaksiProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'In-Out Tracker',
      theme: AppTheme.lightTheme.copyWith(
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme),
      ),
      home: const SplashScreen(),
    );
  }
}
