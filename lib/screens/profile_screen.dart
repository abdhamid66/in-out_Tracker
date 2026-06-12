import 'package:flutter/material.dart';
import '../services/auth_service.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profil Pengguna', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle, size: 100, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              'Silakan Login',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Gunakan akun Google Anda untuk masuk.'),
            const SizedBox(height: 40),

            // Tombol Login Google
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.blueAccent, size: 40),
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Memproses Login Google...'), duration: Duration(seconds: 1)),
                  );

                  // Panggil mesin login
                  final user = await AuthService().signInWithGoogle();

                  if (user != null) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Selamat datang, ${user.displayName}!'), 
                        backgroundColor: const Color(0xFF138D75),
                      ),
                    );
                    
                    // Kembali ke halaman sebelumnya kalau sukses
                    Navigator.pop(context);
                    
                  } else {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Login dibatalkan atau gagal.'), 
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
            const Text("Pencet tombol di atas", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}