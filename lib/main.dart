import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  // Wajib dipanggil biar mesin Flutter siap menerima perintah mesin luar
  WidgetsFlutterBinding.ensureInitialized();
  
  // Menyalakan saklar utama Firebase!
  await Firebase.initializeApp();

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
        // menggunakan warna teal sebagai warna utama aplikasi dengan menggunakan ColorScheme.fromSeed untuk menghasilkan skema warna yang konsisten berdasarkan warna utama yang dipilih, serta mengaktifkan penggunaan Material3 untuk mendapatkan tampilan yang lebih modern dan sesuai dengan desain terbaru dari Google.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,// menggunakan Material3 untuk mendapatkan tampilan yang lebih modern dan sesuai dengan desain terbaru dari Google.
      ),
        home: const LoginScreen(),
      );
  }
}