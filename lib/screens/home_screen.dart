import 'package:flutter/material.dart';
import '../models/transaksi.dart';
import 'input_screen.dart'; // untuk mengimporr model transakssii yang sudahh dibuat
import 'hystory_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // daftar transaksi yang akan di tammpilkann di halamann home, ini masih kosong karena belum ada input transaksi baru
  List<Transaksi> daftarTransaksi = [];

  // fungsii otomatis untuk menghitung total uang masuk
  double get _totalPemasukan {
    double total = 0;
    for (var item in daftarTransaksi) {
      if (item.isPemasukan) {
        total += item.nominal;
      }
    }
    return total;
  }

  // fungsii otomatis untuk menghitung total uang keluar
  double get _totalPengeluaran {
    double total = 0;
    for (var item in daftarTransaksi) {
      if (!item.isPemasukan) {
        total += item.nominal;
      }
    }
    return total;
  }

  // fungsii otomatis untuk menghitungg sisa saldo berdasarkan total pemasukan dan pengeluaran
  double get _saldo => _totalPemasukan - _totalPengeluaran;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard In-Out Tracker'),
        backgroundColor: Colors.blue,
        // tomboll logout di pojok kanan atass
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // ketika tomboll di tekanm maka akan kemabali ke ahlaman login dna hapus riwayat sebvelumnya
              Navigator.pushReplacementNamed(context, '/');
            },
          )
        ],
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // kotak ringkasann keuangan (card)
          Card(
            color: Colors.blue[50],
            elevation: 4, //bayagan
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text('Total Saldo', style: TextStyle(fontSize: 16)),
                  Text(
                    'Rp $_saldo',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // kolom utk pmasukan
                        Column(
                          children: [
                            const Text('pemasukan', style: TextStyle(color: Colors.green)),
                            Text('Rp $_totalPemasukan', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ]
                        ),
                        // kolom untuk pengeluaran
                        Column(
                          children: [
                            const Text('Pengeluaran', style: TextStyle(color: Colors.red)),
                            Text('Rp $_totalPengeluaran', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // tombol tombol menu utama untuk mencatat transaksi baru dan melihat riwayat transaksi
            ElevatedButton.icon(
              onPressed: () async {
                // kita menunggu (await) layar inputscreen di tutup dan membawa hasil
                final hasil = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InputScreen()),
                );

                // jika hasilnya ada (tidak null) dan bentuknya adalah transaksi 
                if (hasil != null && hasil is Transaksi){
                  // setState() memberi tahu layar home untuk mengmbar ulangg tampilannya
                  setState(() {
                    daftarTransaksi.add(hasil); // masukan data baru ke dalam list yang ad di home
                  });
                }
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Catat Transaksi Baru'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),// membuat tombol memenuhi lebar layar
              ),
            ),
            const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HistoryScreen(riwayat: daftarTransaksi), )
                  );
                },
                icon: const Icon(Icons.history),
                label: const Text('Lihat Riwayat Transaksi'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
    );
  }
}