import 'package:flutter/material.dart';
import '../models/transaksi.dart'; // untuk mengimpor model transaksi yang sudah dibuat untuk menampilkan daftar transaksi yang sudah di inputkan di halaman ini

class HistoryScreen extends StatelessWidget {
  // membuat variabel untuk menampung daftar transaksi yang akan di tampilkan di halaman ini, data ini akan di bawa dari halaman home
  final List<Transaksi> riwayat;

  const HistoryScreen({super.key, required this.riwayat});

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Riwayat Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: riwayat.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(15.0),
              itemCount: riwayat.length,
              itemBuilder: (context, index) {
                // membalik urutan daftar transaksi agar yang terbaru tampil di atas, dengan menggunakan reversed dan toList untuk mengubahnya menjadi list kembali
                final item = riwayat.reversed.toList()[index];

                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: item.isPemasukan ? Colors.green[50] : Colors.red[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.isPemasukan ? Icons.arrow_downward : Icons.arrow_upward,
                        color: item.isPemasukan ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(
                      item.judul, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                    subtitle: Text(
                      "${item.tanggal.day}/${item.tanggal.month}/${item.tanggal.year}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    trailing: Text(
                      "${item.isPemasukan ? '+' : '-'} Rp ${item.nominal.toStringAsFixed(0)}",
                      style: TextStyle(
                        color: item.isPemasukan ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              },
            ),             
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            'Belum ada transaksi',
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Catat pemasukan atau pengeluaran pertamamu!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}