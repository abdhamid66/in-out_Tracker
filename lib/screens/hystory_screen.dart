import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:out_tracker/database/db_helper.dart';
import '../models/transaksi.dart';
import '../screens/input_screen.dart';
import '../services/cloud_sync_service.dart';
import '../services/kategori_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Transaksi> riwayat = [];

  DateTime _bulanDipilih = DateTime.now(); 

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
    final data = await DBHelper().getTransaksiBulan(_bulanDipilih.month, _bulanDipilih.year);
    setState(() {
      riwayat = data;
    });
  }

  void _gantiBulan(int tambahBulan) {
    setState(() {
      _bulanDipilih = DateTime(_bulanDipilih.year, _bulanDipilih.month + tambahBulan, 1);
    });
    _refreshRiwayat();
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
        backgroundColor: const Color(0xFF006D5B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF006D5B), size: 20),
                  onPressed: () => _gantiBulan(-1), 
                ),
                
                Text(
                  "${namaBulan[_bulanDipilih.month - 1]} ${_bulanDipilih.year}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF006D5B)),
                ),
                
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, color: Color(0xFF006D5B), size: 20),
                  onPressed: () => _gantiBulan(1), 
                ),
              ],
            ),
          ),
          
          Expanded(
            child: riwayat.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off_rounded, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 15),
                        const Text('Belum ada riwayat', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 18)),
                        const SizedBox(height: 5),
                        Text('Tidak ada transaksi di bulan ${namaBulan[_bulanDipilih.month - 1]}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(15.0),
                    itemCount: riwayat.length,
                    itemBuilder: (context, index) {
                      final item = riwayat[index];
                      
                      final formatter = NumberFormat('#,###', 'id_ID');
                      final nominalRupiah = formatter.format(item.nominal);

                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white, size: 30),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Hapus Transaksi?'),
                              content: const Text('Data yang dihapus tidak bisa dikembalikan lho.'),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) async {
                          await DBHelper().deleteTransaksi(item.id);
                          _refreshRiwayat();
                          CloudSyncService().backupKeCloud();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Transaksi berhasil dihapus'), backgroundColor: Color(0xFF006D5B)),
                          );
                        },
                        child: Card(
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: KategoriService.getColor(item.kategori, item.isPemasukan).withOpacity(0.1),
                              child: Icon(
                                KategoriService.getIcon(item.kategori, item.isPemasukan),
                                color: KategoriService.getColor(item.kategori, item.isPemasukan),
                              ),
                            ),
                            title: Text(item.judul, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            subtitle: Text(item.kategori, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            trailing: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 120),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${item.isPemasukan ? '+' : '-'} Rp $nominalRupiah',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: item.isPemasukan ? Colors.green : Colors.red,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(item.tanggal),
                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                ],
                              ),
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
