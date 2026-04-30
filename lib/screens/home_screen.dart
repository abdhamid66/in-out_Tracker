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
  double get _totalPemasukan => daftarTransaksi.where((t) => t.isPemasukan).fold(0, (sum, item) => sum + item.nominal);
  double get _totalPengeluaran => daftarTransaksi.where((t) => !t.isPemasukan).fold(0, (sum, item) => sum + item.nominal);
  double get _saldo => _totalPemasukan - _totalPengeluaran;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('In-Out Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan Keuangan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87,),
              ),
              const SizedBox(height: 15),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.teal, Color(0xff004D40)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Saldo Saat ini', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 5),
                    Text(
                      'Rp $_saldo',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.arrow_circle_down, color: Colors.greenAccent, size: 24),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Pemasukan', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                Text('RP $_totalPemasukan', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.arrow_circle_up, color: Colors.redAccent, size: 24),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Pengeluaran', style: TextStyle(color: Colors.white70, fontSize: 12 )),
                                Text('Rp $_totalPengeluaran', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],                        
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final hasil = await Navigator.push(context, MaterialPageRoute(builder: (context) => const InputScreen()));
                        if (hasil != null && hasil is Transaksi) {
                          setState(() { daftarTransaksi.add(hasil); });
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Catat\nTransaksi', textAlign: TextAlign.center),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15,),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryScreen(riwayat: daftarTransaksi)));
                      },
                      icon: const Icon(Icons.history),
                      label: const Text('Lihat\nRiwayat', textAlign: TextAlign.center),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.teal,
                        side: const BorderSide(color: Colors.teal, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}