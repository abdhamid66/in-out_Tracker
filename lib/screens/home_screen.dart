import 'package:flutter/material.dart';
import '../models/transaksi.dart';
import 'input_screen.dart'; // untuk mengimporr model transakssii yang sudahh dibuat
import 'hystory_screen.dart';
import 'login_screen.dart';
import '../database/db_helper.dart'; // untuk mengimpor fungsi-fungsi database yang sudah dibuat untuk menyimpan dan mengambil data transaksi dari database di halaman home
import 'package:fl_chart/fl_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // daftar transaksi yang akan ditampilkan di halaman home
  List<Transaksi> daftarTransaksi = [];

  // Tambahkan variabel ini untuk menyimpan hasil hitungan secara statis
  double totalPemasukan = 0;
  double totalPengeluaran = 0;
  double saldo = 0;

  String waktuUpdate = "Memuat...";

  @override
  void initState() {
    super.initState();
    _refreshData(); // panggil fungsi ambil data saat layar pertama dibuka
  }

  // fungsi untuk mengambil data dari SQLite dan menghitung saldo
  void _refreshData() async {
    // PANGGIL FUNGSI getTransaksiBulanIni() UNTUK PILIHAN B (RESET TIAP BULAN)
    final data = await DBHelper().getTransaksiBulanIni();

    // Variabel penampung sementara
    double hitungMasuk = 0;
    double hitungKeluar = 0;

    // Hitung manual satu per satu dari data yang baru diambil
    for (var item in data) {
      if (item.isPemasukan) {
        hitungMasuk += item.nominal;
      } else {
        hitungKeluar += item.nominal;
      }
    }

    // Pastikan layar belum tertutup sebelum memperbarui UI
    if (!mounted) return;

    DateTime sekarang = DateTime.now();
    String jam = sekarang.hour.toString().padLeft(2, '0');
    String menit = sekarang.minute.toString().padLeft(2, '0');
    String formatWaktu = "Hari ini, $jam:$menit";

    // Perbarui layar dengan data terbaru
    setState(() {
      daftarTransaksi = data;
      totalPemasukan = hitungMasuk;
      totalPengeluaran = hitungKeluar;
      saldo = hitungMasuk - hitungKeluar;
    });
  }

  Widget _buildGrafikCard() {
    double total = totalPemasukan + totalPengeluaran;
    double persenMasuk = total == 0 ? 0 : (totalPemasukan / total) * 100;
    double persenKeluar = total == 0 ? 0 : (totalPengeluaran / total) * 100;

    return Container(
      padding: const EdgeInsets.all(15), // Diperkecil dari 20
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 5,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // --- HEADER GRAFIK ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.pie_chart, color: Color(0xFF006D5B), size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Visualisasi Arus Kas',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87), // Font diperkecil
                  ),
                ],
              ),
              const Icon(Icons.more_horiz, color: Colors.grey, size: 18),
            ],
          ),
          const SizedBox(height: 15), // Diperkecil dari 25

          // --- KONTEN GRAFIK & PERSENTASE ---
          if (total == 0)
            const SizedBox(
              height: 100,
              child: Center(child: Text("Belum ada transaksi", style: TextStyle(color: Colors.grey))),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // BAGIAN KIRI: Pengeluaran
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          CircleAvatar(radius: 4, backgroundColor: Color(0xFFFF5252)),
                          SizedBox(width: 6),
                          Text('Pengeluaran', style: TextStyle(color: Colors.grey, fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('${persenKeluar.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                      Text(formatRupiah(totalPengeluaran), style: const TextStyle(color: Color(0xFFFF5252), fontSize: 10)),
                    ],
                  ),
                ),

                // BAGIAN TENGAH: Donut Chart
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 100, // Diperkecil dari 130
                    child: Stack(
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 0,
                            centerSpaceRadius: 30, // Diperkecil agar muat
                            startDegreeOffset: 180,
                            sections: [
                              PieChartSectionData(color: const Color(0xFFFF5252), value: totalPengeluaran, title: '', radius: 20),
                              PieChartSectionData(color: const Color(0xFF26C6DA), value: totalPemasukan, title: '', radius: 20),
                            ],
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.show_chart, color: Colors.teal, size: 16),
                              Text('Arus Kas', style: TextStyle(fontSize: 9, color: Colors.grey)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),

                // BAGIAN KANAN: Pemasukan
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
                          CircleAvatar(radius: 4, backgroundColor: Color(0xFF26C6DA)),
                          SizedBox(width: 6),
                          Text('Pemasukan', style: TextStyle(color: Colors.grey, fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('${persenMasuk.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                      Text(formatRupiah(totalPemasukan), style: const TextStyle(color: Color(0xFF006D5B), fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        toolbarHeight: 60, // Diperkecil sedikit dari 70
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF006D5B), size: 24),
              onPressed: () {
                Scaffold.of(context).openDrawer(); // Perintah untuk membuka laci
              },
            );
          }
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('In-Out Tracker', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF006D5B), fontSize: 20)),
            Text('Kelola keuanganmu dengan cerdas', style: TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: Color(0xFF006D5B), size: 24),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      // --- TAMBAHKAN KODE DRAWER INI ---
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Bagian Header (Atas)
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF138D75), // Warna hijau khas aplikasi kamu
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.account_balance_wallet, color: Colors.white, size: 40),
                  SizedBox(height: 10),
                  Text(
                    'In-Out Tracker', 
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
                  ),
                  Text(
                    'Catatan Keuangan Pribadi', 
                    style: TextStyle(color: Colors.white70, fontSize: 12)
                  ),
                ],
              ),
            ),
            
            // Menu 1: Gembok
            ListTile(
              leading: const Icon(Icons.security, color: Color(0xFF006D5B)),
              title: const Text('Keamanan (Gembok)'),
              subtitle: const Text('Aktifkan PIN / Sidik Jari'),
              onTap: () {
                Navigator.pop(context); // Tutup drawer saat dipencet
                // Nanti kita tambahkan logika navigasi ke layar pengaturan gembok di sini
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur Gembok segera hadir!')));
              },
            ),
            
            // Menu 2: Ekspor Data
            ListTile(
              leading: const Icon(Icons.insert_drive_file, color: Color(0xFF006D5B)),
              title: const Text('Ekspor Laporan'),
              subtitle: const Text('Simpan ke Excel / PDF'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur Ekspor segera hadir!')));
              },
            ),
            
            const Divider(), // Garis pemisah
            
            // Menu 3: Tentang
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.grey),
              title: const Text('Tentang Aplikasi'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),

      // SCROLL DIHILANGKAN, GANTI PADDING BIASA
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0), // Padding atas-bawah ditipiskan
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER RINGKASAN KEUANGAN
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.bar_chart, color: Color(0xFF006D5B), size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text('Ringkasan Keuangan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: const [
                      Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('Bulan Ini', style: TextStyle(fontSize: 11, color: Colors.black87)),
                      Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.grey),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10), // Jarak dipangkas

            // KARTU SALDO UTAMA
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15), // Padding dalam diperkecil
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF138D75), Color(0xFF045C4A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: const Color(0xFF045C4A).withOpacity(0.3), spreadRadius: 2, blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Saldo Saat Ini', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(formatRupiah(saldo), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, color: Colors.white70, size: 10),
                        const SizedBox(width: 4),
                        Text('Update terakhir: $waktuUpdate', style: const TextStyle(color: Colors.white70, fontSize: 9)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15), // Jarak dipangkas
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(backgroundColor: Colors.white.withOpacity(0.2), radius: 14, child: const Icon(Icons.arrow_downward, color: Colors.greenAccent, size: 16)),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Pemasukan', style: TextStyle(color: Colors.white70, fontSize: 10)),
                                Text(formatRupiah(totalPemasukan), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(height: 25, width: 1, color: Colors.white.withOpacity(0.3)),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(backgroundColor: Colors.white.withOpacity(0.2), radius: 14, child: const Icon(Icons.arrow_upward, color: Colors.redAccent, size: 16)),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Pengeluaran', style: TextStyle(color: Colors.white70, fontSize: 10)),
                                Text(formatRupiah(totalPengeluaran), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 15), // JARAK DOUBLE DIHAPUS, SISA 15 AJA
            _buildGrafikCard(),
            const SizedBox(height: 15), // JARAK DOUBLE DIHAPUS, SISA 15 AJA
            
            // --- TOMBOL NAVIGASI BAWAH MODERN ---
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const InputScreen()));
                      _refreshData();
                    },
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      padding: const EdgeInsets.all(12), // Diperkecil dari 20
                      decoration: BoxDecoration(
                        color: const Color(0xFF138D75),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: const Color(0xFF138D75).withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.add_box_rounded, color: Colors.white, size: 24),
                          const SizedBox(height: 8),
                          const Text('Catat Transaksi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text('Tambah data baru', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 9)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryScreen()));
                      _refreshData();
                    },
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      padding: const EdgeInsets.all(12), // Diperkecil dari 20
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.history_rounded, color: Color(0xFF138D75), size: 24),
                          const SizedBox(height: 8),
                          const Text('Lihat Riwayat', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text('Semua transaksimu', style: TextStyle(color: Colors.grey.shade600, fontSize: 9)),
                        ],
                      ),
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
