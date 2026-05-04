import 'package:flutter/material.dart';
import 'package:out_tracker/database/db_helper.dart';
import '../models/transaksi.dart'; // untuk mengimpor model transaksi yang sudah dibuat untuk menampilkan daftar transaksi yang sudah di inputkan di halaman ini

class HistoryScreen extends StatefulWidget {

    const HistoryScreen({super.key});

    @override
    State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>{
  List<Transaksi> riwayat = [];

  @override
  void initState() {
    super.initState();
    _refreshRiwayat();
  }

  void _refreshRiwayat() async{
    final data = await DBHelper().getSemuaTransaksi();
    setState((){
      riwayat = data;
    });
  }

  void _konfirmasiHapus(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: const Text('Data yang dihapus tidak bisa di kembalikan Lho.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await DBHelper().deleteTransaksi(id);
              if(!mounted) return;
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
      appBar: AppBar (
        title: const Text('Riwayat Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: riwayat.isEmpty
          ? const Center(child: Text('Belum ada Transaksi'))
          : ListView.builder(
            padding: const EdgeInsets.all(15.0),
            itemCount: riwayat.length,
            itemBuilder: (context, index) {

              final item = riwayat[index];

              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  onLongPress: () {
                    _konfirmasiHapus(item.id);
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.isPemasukan ? Colors.green[50]:Colors.red [50],
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
                  "${item.isPemasukan ? '+' : '-'} ${formatRupiah(item.nominal)}",
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
}