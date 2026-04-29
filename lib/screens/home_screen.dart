import 'package:flutter/material.dart';
import '../models/transaksi.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Transaksi> daftarTransaksi = [];

  double get _totalPemasukan {
    double total = 0;
    for (var item in daftarTransaksi) {
      if (item.isPemasukan) {
        total += item.nominal;
      }
    }
    return total;
  }

  double get _totalPengeluaran {
    double total = 0;
    for (var item in daftarTransaksi) {
      if (!item.isPemasukan) {
        total += item.nominal;
      }
    }
    return total;
  }

  double get _saldo => _totalPemasukan - _totalPengeluaran;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard In-Out Tracker'),
        backgroundColor: Colors.blue,

        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {

              Navigator.pushReplacementNamed(context, '/');
            },
          )
        ],
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [

          Card(
            color: Colors.blue[50],
            elevation: 4,
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
                        Column(
                          children: [
                            const Text('pemasukan', style: TextStyle(color: Colors.green)),
                            Text('Rp $_totalPemasukan', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ]
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
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

            ElevatedButton.icon(
              onPressed: () {

                print('Ke Halaman Input');
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Catat Transaksi Baru'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: () {

                  print('Ke Hlaman Riwayat');
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