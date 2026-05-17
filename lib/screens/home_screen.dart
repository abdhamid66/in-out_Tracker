import 'package:flutter/material.dart';
import '../models/transaksi.dart';
import 'input_screen.dart'; // untuk mengimporr model transakssii yang sudahh dibuat
import 'hystory_screen.dart';
import 'login_screen.dart';
import '../database/db_helper.dart'; // untuk mengimpor fungsi-fungsi database yang sudah dibuat untuk menyimpan dan mengambil data transaksi dari database di halaman home
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import '../widgets/kartu_saldo.dart';

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
  String bulanTerpilih = 'Bulan Ini';
  final List<String> daftarBulan = [
    'Bulan Ini', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    _refreshData(); // panggil fungsi ambil data saat layar pertama dibuka
  }

  // fungsi untuk mengambil data dari SQLite dan menghitung saldo
  void _refreshData() async {
    List<Transaksi> data = [];

    // CEK BULAN APA YANG SEDANG DIPILIH DI DROPDOWN
    if (bulanTerpilih == 'Bulan Ini') {
      // Kalau pilihannya 'Bulan Ini', pakai fungsi default
      data = await DBHelper().getTransaksiBulanIni();
    } else {
      // Kalau pilihannya nama bulan, kita ubah namanya jadi angka
      // Karena 'Bulan Ini' ada di index 0, 'Januari' otomatis index 1, 'Februari' index 2, dst.
      int angkaBulan = daftarBulan.indexOf(bulanTerpilih); 
      int tahunSekarang = DateTime.now().year; // Kita asumsikan pakai tahun saat ini
      
      // Panggil fungsi buatanmu di DBHelper
      data = await DBHelper().getTransaksiBulan(angkaBulan, tahunSekarang);
    }

    double hitungMasuk = 0;
    double hitungKeluar = 0;

    for (var item in data) {
      if (item.isPemasukan) {
        hitungMasuk += item.nominal;
      } else {
        hitungKeluar += item.nominal;
      }
    }

    if (!mounted) return;

    DateTime sekarang = DateTime.now();
    String jam = sekarang.hour.toString().padLeft(2, '0');
    String menit = sekarang.minute.toString().padLeft(2, '0');
    String formatWaktu = "Hari ini, $jam:$menit";

    setState(() {
      daftarTransaksi = data;
      totalPemasukan = hitungMasuk;
      totalPengeluaran = hitungKeluar;
      saldo = hitungMasuk - hitungKeluar;
      waktuUpdate = formatWaktu;
    });
  }
  Future<void> _eksporKeExcel() async {
    // 1. Munculkan pesan loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sedang membuat file Excel...'), backgroundColor: Color(0xFF138D75)),
    );

    try {
      // 2. Ambil semua data dari database
      final data = await DBHelper().getSemuaTransaksi();
      
      if (data.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Belum ada transaksi untuk diekspor!'), backgroundColor: Colors.redAccent),
        );
        return;
      }

      // 3. Buat file Excel baru
      var excel = Excel.createExcel();
      Sheet sheet = excel['Laporan Keuangan'];
      excel.setDefaultSheet('Laporan Keuangan');

      // 4. Buat Baris Header (Judul Kolom)
      sheet.appendRow([
        TextCellValue('Tanggal'),
        TextCellValue('Judul Transaksi'),
        TextCellValue('Jenis'),
        TextCellValue('Nominal (Rp)'),
      ]);

      // 5. Masukkan data dari database satu per satu ke dalam baris Excel
      for (var item in data) {
        String tanggalFormat = DateFormat('dd-MM-yyyy').format(item.tanggal);
        String jenis = item.isPemasukan ? 'Pemasukan' : 'Pengeluaran';
        
        sheet.appendRow([
          TextCellValue(tanggalFormat),
          TextCellValue(item.judul),
          TextCellValue(jenis),
          IntCellValue(item.nominal.toInt()), // Angka murni biar bisa dijumlah pakai rumus di Excel
        ]);
      }

      // 6. Simpan file ke penyimpanan sementara di HP
      var fileBytes = excel.save();
      var directory = await getTemporaryDirectory();
      File file = File('${directory.path}/Laporan_InOutTracker.xlsx');
      await file.writeAsBytes(fileBytes!);

      // 7. Munculkan menu Share bawaan HP
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)], 
        text: 'Ini laporan keuanganku dari aplikasi In-Out Tracker!',
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengekspor: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _tampilkanDialogUbahPin() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah PIN Keamanan'),
        content: const Text('Apakah kamu yakin ingin mengatur ulang (mengubah) PIN aplikasi? Kamu akan diminta membuat 4 digit PIN baru.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              // 1. Buka lemari penyimpanan HP
              SharedPreferences prefs = await SharedPreferences.getInstance();
              
              // 2. Hapus memori PIN lama
              await prefs.remove('user_pin'); 

              if (!mounted) return;
              Navigator.pop(context); // Tutup dialog pop-up
              
              // 3. Lempar paksa ke layar PIN untuk bikin PIN baru
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
              
              // 4. Kasih notifikasi kecil
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Silakan buat PIN baru kamu'), backgroundColor: Color(0xFF138D75)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006D5B)),
            child: const Text('Ya, Ubah PIN', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildGrafikCard() {
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

          //  KONTEN GRAFIK & PERSENTASE 
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
                    height: 100, 
                    child: Stack(
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 0,
                            centerSpaceRadius: 30, 
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
        toolbarHeight: 60, 
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
                color: Color(0xFF138D75), 
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
            
            // Gembok
            ListTile(
              leading: const Icon(Icons.security, color: Color(0xFF006D5B)),
              title: const Text('Keamanan (Gembok)'),
              subtitle: const Text('Ubah PIN Aplikasi'), 
              onTap: () {
                Navigator.pop(context); // Tutup drawer dulu
                _tampilkanDialogUbahPin(); // Panggil dialog konfirmasi
              },
            ),
            
            // Ekspor Data
            ListTile(
              leading: const Icon(Icons.insert_drive_file, color: Color(0xFF006D5B)),
              title: const Text('Ekspor Laporan'),
              subtitle: const Text('Simpan ke Excel (.xlsx)'),
              onTap: () {
                Navigator.pop(context); // Tutup drawer dulu
                _eksporKeExcel();       // Panggil fungsi pembuat Excel
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
                  height: 30, // Biar tingginya pas dan rapi
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: bulanTerpilih,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
                      style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold),
                      onChanged: (String? nilaiBaru) {
                        if (nilaiBaru != null) {
                          setState(() {
                            bulanTerpilih = nilaiBaru; // Ubah teks di layar
                          });

                          _refreshData();
                          // Memunculkan notifikasi kecil saat bulan diganti
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Menyiapkan data bulan: $nilaiBaru...'), 
                              duration: const Duration(seconds: 1),
                              backgroundColor: const Color(0xFF138D75),
                            ),
                          );
                          // NANTI KITA MASUKKAN LOGIKA FILTER DATABASE DI SINI
                        }
                      },
                      items: daftarBulan.map<DropdownMenuItem<String>>((String namaBulan) {
                        return DropdownMenuItem<String>(
                          value: namaBulan,
                          child: Row(
                            children: [
                              if (namaBulan == 'Bulan Ini') const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey),
                              if (namaBulan == 'Bulan Ini') const SizedBox(width: 4),
                              Text(namaBulan),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10), // Jarak dipangkas

            // MENGHUBUNGKAN KE RUANGAN KARTU SALDO
            KartuSaldo(
              saldo: saldo, // Kata kiri: nama pintu masuk | Kata kanan: data yang dikirim dari home
              totalPemasukan: totalPemasukan,
              totalPengeluaran: totalPengeluaran,
              waktuUpdate: waktuUpdate,
            ),
            
            const SizedBox(height: 15), 
            _buildGrafikCard(),
            const SizedBox(height: 15), 
            
            // TOMBOL NAVIGASI BAWAH 
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
                      padding: const EdgeInsets.all(12), 
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
