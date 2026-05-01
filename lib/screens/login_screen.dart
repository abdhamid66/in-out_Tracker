import 'package:flutter/material.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller untuk mengambil input dari TextField
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

// fungsinya utk mengcek loginn
  void _cekLogin() {
    String username = _usernameController.text;
    String password = _passwordController.text;
// cek apakah username dan password benar
    if (username == 'admin' && password == '12345') {
      // Jika login berhasil, tampilkan pesan sukses di bawah layarr (Snackbar)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login Berhasil!')),
      );
      // Setelah menampilkan pesan sukses, navigasi ke halaman HomeScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );

    } else {
      //jika salah,munculkaann pesann erorr
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username atau Password salah!'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login In-Out Tracker'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),// memberikan jarak dari tepi layarr
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,// pposisi widget di tengah layar
          children: [
            const Icon(Icons.account_balance_wallet, size: 80, color: Colors.teal),
            const SizedBox(height: 15),// spasii antar widget
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(), // menmberikan border pada TextField
              ),
            ),
            const SizedBox(height: 15),// memberikan jarak antar widget

            // widget untuk memasukkan password
            TextField(
              controller: _passwordController,
              obscureText: true, // menyembunyikan teks yang dimasukkan (untuk password)
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(), // menmberikan border pada TextField
              ),
            ),

            SizedBox(
              width: double.infinity, // membuat tombol memenuhi lebar layar
              height: 50,
              child: ElevatedButton(
                onPressed: _cekLogin, // memanggil fungsi cekLogin saat tombol ditekan
                child: const Text('MASUK', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}