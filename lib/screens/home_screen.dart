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

    // Perbarui layar dengan data terbaru
    setState(() {
      daftarTransaksi = data;
      totalPemasukan = hitungMasuk;
      totalPengeluaran = hitungKeluar;
      saldo = hitungMasuk - hitungKeluar;
    });
  }

  Widget _buildGrafikCard() {
    // 1. Rumus Otomatis Menghitung Persentase
    double total = totalPemasukan + totalPengeluaran;
    double persenMasuk = total == 0 ? 0 : (totalPemasukan / total) * 100;
    double persenKeluar = total == 0 ? 0 : (totalPengeluaran / total) * 100;

    return Container(
      padding: const EdgeInsets.all(15),
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
                    child: const Icon(
                      Icons.pie_chart,
                      color: Color(0xFF006D5B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Visualisasi Arus Kas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.more_horiz, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 10),

          // --- KONTEN GRAFIK & PERSENTASE ---
          if (total == 0)
            const SizedBox(
              height: 130,
              child: Center(
                child: Text(
                  "Belum ada transaksi",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // BAGIAN KIRI: Pengeluaran (Merah)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          CircleAvatar(
                            radius: 4,
                            backgroundColor: Color(0xFFFF5252),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Pengeluaran',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${persenKeluar.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatRupiah(totalPengeluaran),
                        style: const TextStyle(
                          color: Color(0xFFFF5252),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // BAGIAN TENGAH: Donut Chart
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 130,
                    child: Stack(
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 0,
                            centerSpaceRadius: 40, // Besarnya lubang tengah
                            startDegreeOffset:
                                180, // Mengatur merah ada di posisi atas
                            sections: [
                              PieChartSectionData(
                                color: const Color(0xFFFF5252), // Merah
                                value: totalPengeluaran,
                                title: '', // Teks di dalam dihilangkan
                                radius: 25, // Ketebalan donat
                              ),
                              PieChartSectionData(
                                color: const Color(0xFF26C6DA), // Tosca terang
                                value: totalPemasukan,
                                title: '',
                                radius: 25,
                              ),
                            ],
                          ),
                        ),
                        // Teks & Ikon di tengah lubang donat
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.show_chart,
                                color: Colors.teal,
                                size: 18,
                              ),
                              Text(
                                'Arus Kas',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // BAGIAN KANAN: Pemasukan (Hijau)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
                          CircleAvatar(
                            radius: 4,
                            backgroundColor: Color(0xFF26C6DA),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Pemasukan',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${persenMasuk.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatRupiah(totalPemasukan),
                        style: const TextStyle(
                          color: Color(0xFF006D5B),
                          fontSize: 12,
                        ),
                      ),
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

      // 2. Rombak total AppBar-nya
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        toolbarHeight: 70,

        // Ikon menu di kiri (sekarang cuma hiasan dulu)
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF006D5B), size: 28),
          onPressed: () {},
        ),

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'In-Out Tracker',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF006D5B),
                fontSize: 22,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Kelola keuanganmu dengan cerdas',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),

        // Ikon Logout
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout_outlined,
              color: Color(0xFF006D5B),
              size: 26,
            ),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, //tulisan rata kiri
          children: [
            //HEADER RINGKASAN KEUANGAN
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9), // Hijau sangat muda
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.bar_chart,
                        color: Color(0xFF006D5B),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Ringkasan Keuangan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                // Tombol "Bulan Ini"
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Bulan Ini',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // KARTU SALDO UTAMA
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF138D75), Color(0xFF045C4A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF045C4A).withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Saldo Saat Ini',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    formatRupiah(saldo),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Label "Update terakhir"
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.access_time,
                          color: Colors.white70,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Update terakhir: Hari ini',
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  //BARIS PEMASUKAN & PENGELUARAN
                  Row(
                    children: [
                      // Kolom Pemasukan
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              radius: 18,
                              child: const Icon(
                                Icons.arrow_downward,
                                color: Colors.greenAccent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pemasukan',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  formatRupiah(totalPemasukan),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Garis Vertikal Pemisah
                      Container(
                        height: 35,
                        width: 1,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(width: 15),

                      // Kolom Pengeluaran
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              radius: 18,
                              child: const Icon(
                                Icons.arrow_upward,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pengeluaran',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  formatRupiah(totalPengeluaran),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
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
            const SizedBox(height: 30),
            const SizedBox(
              height: 25,
            ), // Jarak dari kartu saldo ke kartu grafik
            _buildGrafikCard(), // Memanggil desain UI yang baru
            const SizedBox(height: 15), // Jarak sebelum tombol bawah
            const SizedBox(height: 20),
            // dua tombol utama untuk mencatat transaksi baru dan melihat riwayat transaksi, dengan desain yang lebih menarik menggunakan ElevatedButton.icon untuk memberikan ikon yang jelas pada setiap tombol, serta menggunakan
            // --- TOMBOL NAVIGASI BAWAH MODERN ---
            Row(
              children: [
                // Tombol Catat Transaksi
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const InputScreen()));
                      _refreshData();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF138D75), // Hijau senada kartu saldo
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF138D75).withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.add_box_rounded, color: Colors.white, size: 30),
                          const SizedBox(height: 15),
                          const Text(
                            'Catat Transaksi',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tambah pemasukan atau pengeluaran',
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10),
                          ),
                          const SizedBox(height: 10),
                          const Icon(Icons.arrow_forward, color: Colors.white70, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                // Tombol Lihat Riwayat
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryScreen()));
                      _refreshData();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.history_rounded, color: Color(0xFF138D75), size: 30),
                          const SizedBox(height: 8),
                          const Text(
                            'Lihat Riwayat',
                            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lihat semua transaksi sebelumnya',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                          ),
                          const SizedBox(height: 5),
                          const Icon(Icons.arrow_forward, color: Colors.grey, size: 16),
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
