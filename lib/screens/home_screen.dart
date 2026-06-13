import 'package:flutter/material.dart';
import '../models/transaksi.dart';
import 'input_screen.dart'; 
import 'hystory_screen.dart';
import 'login_screen.dart';
import '../database/db_helper.dart'; 
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/kartu_saldo.dart';
import '../widgets/grafik_card.dart';
import '../services/auth_service.dart';
import '../widgets/tombol_menu_home.dart';
import '../screens/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Tambahan untuk ambil foto profil

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Mengingat tombol mana yang sedang dipencet (Mulai dari 0 = Beranda)
  int _currentIndex = 0;

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
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  @override
  void initState() {
    super.initState();
    _refreshData(); // panggil fungsi ambil data saat layar pertama dibuka
  }

  // fungsi untuk mengambil data dari SQLite dan menghitung saldo
  void _refreshData() async {
    List<Transaksi> data = [];

    if (bulanTerpilih == 'Bulan Ini') {
      data = await DBHelper().getTransaksiBulanIni();
    } else {
      int angkaBulan = daftarBulan.indexOf(bulanTerpilih);
      int tahunSekarang = DateTime.now().year;
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sedang membuat file Excel...'), backgroundColor: Color(0xFF138D75)),
    );

    try {
      final data = await DBHelper().getSemuaTransaksi();
      if (data.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Belum ada transaksi untuk diekspor!'), backgroundColor: Colors.redAccent),
        );
        return;
      }

      var excel = Excel.createExcel();
      Sheet sheet = excel['Laporan Keuangan'];
      excel.setDefaultSheet('Laporan Keuangan');

      sheet.appendRow([
        TextCellValue('Tanggal'), TextCellValue('Judul Transaksi'), TextCellValue('Jenis'), TextCellValue('Nominal (Rp)'),
      ]);

      for (var item in data) {
        String tanggalFormat = DateFormat('dd-MM-yyyy').format(item.tanggal);
        String jenis = item.isPemasukan ? 'Pemasukan' : 'Pengeluaran';
        sheet.appendRow([
          TextCellValue(tanggalFormat), TextCellValue(item.judul), TextCellValue(jenis), IntCellValue(item.nominal.toInt()),
        ]);
      }

      var fileBytes = excel.save();
      var directory = await getTemporaryDirectory();
      File file = File('${directory.path}/Laporan_InOutTracker.xlsx');
      await file.writeAsBytes(fileBytes!);

      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)], text: 'Ini laporan keuanganku dari aplikasi In-Out Tracker!');
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.remove('user_pin');
              if (!mounted) return;
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan buat PIN baru kamu'), backgroundColor: Color(0xFF138D75)));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006D5B)),
            child: const Text('Ya, Ubah PIN', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _tampilkanDialogTentang() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.info_outline, color: Color(0xFF006D5B)), SizedBox(width: 10),
            Text('Tentang Aplikasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.account_balance_wallet, size: 60, color: Color(0xFF138D75)), SizedBox(height: 15),
            Text('In-Out Tracker', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF006D5B))),
            Text('Versi 1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12)), SizedBox(height: 20),
            Text('Aplikasi catatan keuangan pribadi yang dirancang untuk membantu Anda melacak arus kas dengan mudah, aman, dan tanpa perlu koneksi internet.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, height: 1.5)),
            SizedBox(height: 20), Divider(), SizedBox(height: 10),
            Text('Dikembangkan oleh:', style: TextStyle(color: Colors.grey, fontSize: 11)),
            Text('Abd Hamid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text('Mahasiswa Semester 4', style: TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup', style: TextStyle(color: Color(0xFF006D5B), fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  // CETAKAN UNTUK 5 RIWAYAT TERAKHIR
  Widget _buildRiwayatTerakhir() {
    // 1. Ambil data transaksi yang ada, lalu urutkan dari yang paling baru
    List<Transaksi> riwayat = List.from(daftarTransaksi);
    riwayat.sort((a, b) => b.tanggal.compareTo(a.tanggal)); 
    
    // 2. Potong maksimal ambil 5 saja
    final limaTerbaru = riwayat.take(5).toList();

    // Kalau datanya kosong
    if (limaTerbaru.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 30.0),
          child: Text('Belum ada transaksi di bulan ini.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    // Kalau ada datanya, buatkan daftarnya
    return Column(
      children: limaTerbaru.map((trx) {
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: trx.isPemasukan ? Colors.green.shade50 : Colors.red.shade50,
              child: Icon(
                trx.isPemasukan ? Icons.arrow_downward : Icons.arrow_upward,
                color: trx.isPemasukan ? Colors.green : Colors.red,
              ),
            ),
            title: Text(
              trx.judul, 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              DateFormat('dd MMM yyyy').format(trx.tanggal),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Text(
              trx.isPemasukan ? '+ Rp ${trx.nominal.toInt()}' : '- Rp ${trx.nominal.toInt()}',
              style: TextStyle(
                color: trx.isPemasukan ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // KODINGAN DESAIN HALAMAN BERANDA
  Widget _buildBeranda() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: bulanTerpilih,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
                      style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold),
                      onChanged: (String? nilaiBaru) {
                        if (nilaiBaru != null) {
                          setState(() { bulanTerpilih = nilaiBaru; });
                          _refreshData();
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
            const SizedBox(height: 10),
            KartuSaldo(saldo: saldo, totalPemasukan: totalPemasukan, totalPengeluaran: totalPengeluaran, waktuUpdate: waktuUpdate),
            const SizedBox(height: 15),
            GrafikCard(totalPemasukan: totalPemasukan, totalPengeluaran: totalPengeluaran),
            const SizedBox(height: 15),
            TombolMenuHome(onRefresh: _refreshData),
            
            const SizedBox(height: 25), // Jarak sebelum riwayat

            // RIWAYAT TRANSAKSI 
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Riwayat Terakhir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                GestureDetector(
                  onTap: () {
                    // Pindah ke Halaman Riwayat Lengkap (history_screen)
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const HystoryScreen()));
                  },
                  child: const Text('Lihat Semua', style: TextStyle(color: Color(0xFF006D5B), fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            // Panggil cetakan 5 riwayat yang kita buat di atas
            _buildRiwayatTerakhir(),

            // Jarak paling bawah biar ga mentok navigasi
            const SizedBox(height: 40), 
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // KITA MASUKKAN HALAMAN BERANDA KE DALAM DAFTAR HALAMAN DI SINI
    final List<Widget> daftarHalaman = [
      _buildBeranda(), // Index 0: Halaman Beranda Utama
      const Center(child: Text('Ini Isi Halaman Pengaturan')), // Index 1: Halaman Pengaturan
      const ProfileScreen(), // Index 2: Halaman Login Profile
    ];

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
              onPressed: () { Scaffold.of(context).openDrawer(); },
            );
          },
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

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF138D75)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.account_balance_wallet, color: Colors.white, size: 40), SizedBox(height: 10),
                  Text('In-Out Tracker', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('Catatan Keuangan Pribadi', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.security, color: Color(0xFF006D5B)),
              title: const Text('Keamanan (Gembok)'), subtitle: const Text('Ubah PIN Aplikasi'),
              onTap: () { Navigator.pop(context); _tampilkanDialogUbahPin(); },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file, color: Color(0xFF006D5B)),
              title: const Text('Ekspor Laporan'), subtitle: const Text('Simpan ke Excel (.xlsx)'),
              onTap: () { Navigator.pop(context); _eksporKeExcel(); },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Color(0xFF006D5B)),
              title: const Text('Tentang Aplikasi'),
              onTap: () { Navigator.pop(context); _tampilkanDialogTentang(); },
            ),
          ],
        ),
      ),

      // BODY AKAN OTOMATIS BERUBAH BERDASARKAN TOMBOL YANG DIPENCET
      body: daftarHalaman[_currentIndex], 

      // NAVIGASI BAWAH YANG SUDAH DILENGKAPI 3 TOMBOL DAN CCTV FIREBASE
      bottomNavigationBar: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(), // Memantau status login
        builder: (context, snapshot) {
          final user = snapshot.data; // Ambil data user saat ini

          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            }, 
            type: BottomNavigationBarType.fixed, 
            selectedItemColor: const Color(0xFF006D5B), 
            unselectedItemColor: Colors.grey,
            items: [
              const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
              const BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Pengaturan'),
              BottomNavigationBarItem(
                // Jika user ada DAN fotonya ada ? Tampilkan foto : Tampilkan Ikon
                icon: user != null && user.photoURL != null
                    ? CircleAvatar(
                        radius: 12, // Ukuran disamakan dengan ikon biasa
                        backgroundImage: NetworkImage(user.photoURL!),
                      )
                    : const Icon(Icons.login),
                label: user != null ? 'Profil' : 'Login',
              ), 
            ],
          );
        }
      ),
    );
  }
}