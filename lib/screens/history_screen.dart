import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/transaksi.dart';
import '../screens/input_screen.dart';
import '../services/cloud_sync_service.dart';
import '../services/kategori_service.dart';
import '../utils/formatters.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Transaksi> riwayat = [];
  DateTime _bulanDipilih = DateTime.now(); 
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

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
    final keyword = _searchController.text.trim();
    List<Transaksi> data;
    if (keyword.isNotEmpty) {
      data = await DBHelper().cariTransaksi(keyword);
    } else {
      data = await DBHelper().getTransaksiBulan(_bulanDipilih.month, _bulanDipilih.year);
    }
    if (!mounted) return;
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
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Cari transaksi...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (value) => _refreshRiwayat(),
              )
            : const Text('Riwayat Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF006D5B),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _refreshRiwayat();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_isSearching)
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
                        Text(
                          _isSearching ? 'Tidak ada transaksi yang cocok dengan pencarian' : 'Tidak ada transaksi di bulan ${namaBulan[_bulanDipilih.month - 1]}', 
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(15.0),
                    itemCount: riwayat.length,
                    itemBuilder: (context, index) {
                      final item = riwayat[index];
                      final nominalRupiah = formatRupiah(item.nominal);

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
                            SnackBar(
                              content: const Text('Transaksi berhasil dihapus'),
                              backgroundColor: const Color(0xFF006D5B),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.all(16),
                            ),
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
                              backgroundColor: KategoriService.getColor(item.kategori, item.isPemasukan).withValues(alpha: 0.1),
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
                                    '${item.tanggal.day} ${namaBulan[item.tanggal.month - 1]} ${item.tanggal.year}',
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
