import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:out_tracker/database/db_helper.dart';
import '../models/transaksi.dart'; // untuk mengimpor model transaksi yang sudah dibuat untuk menampilkan daftar transaksi yang sudah di inputkan di halaman ini
import '../screens/input_screen.dart';
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Transaksi> riwayat = [];

  DateTime _bulanDipilih = DateTime.now(); 

  // Daftar nama bulan biar tampilannya bahasa Indonesia
  final List<String> namaBulan = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    _refreshRiwayat();
  }

  void _refreshRiwayat() async {
    // 2. Minta data ke database sesuai bulan yang dipilih
    final data = await DBHelper().getTransaksiBulan(_bulanDipilih.month, _bulanDipilih.year);
    setState(() {
      riwayat = data;
    });
  }

  // 3. Fungsi untuk menggeser bulan saat panah ditekan
  void _gantiBulan(int tambahBulan) {
    setState(() {
      // Dart sangat pintar: jika bulan dikurangi 1 dari Januari, dia otomatis mundur ke Desember tahun lalu!
      _bulanDipilih = DateTime(_bulanDipilih.year, _bulanDipilih.month + tambahBulan, 1);
    });
    _refreshRiwayat(); // Jangan lupa panggil data lagi setelah ganti bulan
  }

  void _konfirmasiHapus(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: const Text('Data yang dihapus tidak bisa dikembalikan lho.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await DBHelper().deleteTransaksi(id);
              if (!mounted) return;
              Navigator.pop(context);
              _refreshRiwayat();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Riwayat Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- KOTAK PEMILIH BULAN (NAVIGASI PANAH) ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tombol Panah Kiri (Mundur 1 Bulan)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.teal, size: 20),
                  onPressed: () => _gantiBulan(-1), 
                ),
                
                // Teks Penunjuk Bulan dan Tahun
                Text(
                  "${namaBulan[_bulanDipilih.month - 1]} ${_bulanDipilih.year}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
                
                // Tombol Panah Kanan (Maju 1 Bulan)
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.teal, size: 20),
                  onPressed: () => _gantiBulan(1), 
                ),
              ],
            ),
          ),
          
          // --- DAFTAR TRANSAKSI ---
          Expanded(
            child: riwayat.isEmpty
                ? const Center(child: Text('Belum ada transaksi di bulan ini'))
                : ListView.builder(
                    padding: const EdgeInsets.all(15.0),
                    itemCount: riwayat.length,
                    itemBuilder: (context, index) {
                      final item = riwayat[index];
                      
                      // Format rupiah
                      final formatter = NumberFormat('#,###', 'id_ID');
                      final nominalRupiah = formatter.format(item.nominal);

                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          onTap: () async {
                            final hasilEdit = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => InputScreen(transaksiLama: item)),
                            );
                            if (hasilEdit == true) {
                              _refreshRiwayat();
                            }
                          },
                          onLongPress: () => _konfirmasiHapus(item.id),
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
                          title: Text(item.judul, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Text(
                            "${item.tanggal.day} ${namaBulan[item.tanggal.month - 1]} ${item.tanggal.year}",
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                          trailing: Text(
                            "${item.isPemasukan ? '+' : '-'} $nominalRupiah",
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
          ),
        ],
      ),
    );
  }
}
