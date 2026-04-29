import 'package:flutter/material.dart';
import '../models/transaksi.dart'; // untuk mengimpor model transaksi yang sudah dibuat untuk menampilkan daftar transaksi yang sudah di inputkan di halaman ini

class HistoryScreen extends StatelessWidget {
  final List<Transaksi> riwayat;

  const HistoryScreen({super.key, required this.riwayat});

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        backgroundColor: Colors.blue,
      ),
      body: riwayat.isEmpty
          ? const Center(child: Text('Belum ada transaksi.'))
          : ListView.builder(
              itemCount: riwayat.length,
              itemBuilder: (context, index) {
                final item = riwayat.reversed.toList()[index];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item.isPemasukan ? Colors.green[100] : Colors.red[100],
                    child: Icon(
                      item.isPemasukan ? Icons.arrow_upward : Icons.arrow_downward,
                      color: item.isPemasukan ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(item.judul, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    "${item.tanggal.day}/${item.tanggal.month}/${item.tanggal.year} - ${item.tanggal.hour}:${item.tanggal.minute}",
                  ),
                  trailing: Text(
                    "${item.isPemasukan ? '+' : '-'} Rp ${item.nominal}",
                    style: TextStyle(
                      color: item.isPemasukan ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                );
              }
          )
    );
  }
}