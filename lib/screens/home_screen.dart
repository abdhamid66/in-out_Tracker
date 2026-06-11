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
import '../widgets/grafik_card.dart';
import '../services/auth_service.dart';
import '../widgets/tombol_menu_home.dart';

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
  void _tampilkanDialogTentang() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.info_outline, color: Color(0xFF006D5B)),
            SizedBox(width: 10),
            Text('Tentang Aplikasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min, // Biar kotaknya nggak kepanjangan
          children: [
            const Icon(Icons.account_balance_wallet, size: 60, color: Color(0xFF138D75)),
            const SizedBox(height: 15),
            const Text('In-Out Tracker', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF006D5B))),
            const Text('Versi 1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 20),
            const Text(
              'Aplikasi catatan keuangan pribadi yang dirancang untuk membantu Anda melacak arus kas dengan mudah, aman, dan tanpa perlu koneksi internet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            // Nah, bagian ini pas banget buat mejeng pas presentasi project tugas akhir!
            const Text('Dikembangkan oleh:', style: TextStyle(color: Colors.grey, fontSize: 11)),
            const Text('Abd Hamid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const Text('Mahasiswa Semester 4', style: TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(color: Color(0xFF006D5B), fontWeight: FontWeight.bold)),
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
      
      // --- DRAWER (LACI SAMPING) ---
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
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
            ListTile(
              leading: const Icon(Icons.security, color: Color(0xFF006D5B)),
              title: const Text('Keamanan (Gembok)'),
              subtitle: const Text('Ubah PIN Aplikasi'), 
              onTap: () {
                Navigator.pop(context); 
                _tampilkanDialogUbahPin(); 
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file, color: Color(0xFF006D5B)),
              title: const Text('Ekspor Laporan'),
              subtitle: const Text('Simpan ke Excel (.xlsx)'),
              onTap: () {
                Navigator.pop(context); 
                _eksporKeExcel(); 
              },
            ),
            const Divider(), 
            ListTile(
              leading: const Icon(Icons.info_outline, color: Color(0xFF006D5B)),
              title: const Text('Tentang Aplikasi'),
              onTap: () {
                Navigator.pop(context); // 1. Tutup laci dulu
                
                // 2. Munculin info bawaan Flutter yang super bersih & simpel
                showAboutDialog(
                  context: context,
                  applicationName: 'In-Out Tracker',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(Icons.account_balance_wallet, color: Color(0xFF138D75), size: 42),
                  children: const [
                    Text('Aplikasi catatan keuangan pribadi untuk melacak pemasukan dan pengeluaran secara lokal dan aman.'),
                  ],
                );
              },
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER RINGKASAN KEUANGAN & DROPDOWN BULAN
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
                              bulanTerpilih = nilaiBaru;
                            });
                            _refreshData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Menyiapkan data bulan: $nilaiBaru...'), 
                                duration: const Duration(seconds: 1),
                                backgroundColor: const Color(0xFF138D75),
                              ),
                            );
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

              // KARTU SALDO UTAMA
              KartuSaldo(
                saldo: saldo, 
                totalPemasukan: totalPemasukan,
                totalPengeluaran: totalPengeluaran,
                waktuUpdate: waktuUpdate,
              ),
              
              const SizedBox(height: 15), 

              // GRAFIK ARUS KAS
              GrafikCard(
                totalPemasukan: totalPemasukan,
                totalPengeluaran: totalPengeluaran,
              ),

              const SizedBox(height: 15), 
              
              // TOMBOL AKSI UTAMA (CATAT TRANSAKSI & RIWAYAT)
              TombolMenuHome(
                onRefresh: _refreshData, 
              ),
              
              // Jarak tambahan di paling bawah agar konten tidak terpotong navigasi
              const SizedBox(height: 25),
            ],
          ),
        ),
      ),

      // NAVIGASI BAWAH  
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 10,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Tombol Beranda (Aktif)
              IconButton(
                icon: const Icon(Icons.home, color: Color(0xFF138D75), size: 30),
                onPressed: () {
                  // Kita sudah di halaman Home
                }, 
              ),
              // Tombol Profil / Buka Laci
              IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.grey, size: 30),
                onPressed: () async {
                  // Munculkan tulisan loading kecil di bawah
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Memproses Login Google...'), duration: Duration(seconds: 1)),
                  );

                  // Panggil mesin login yang udah kita buat tadi
                  final user = await AuthService().signInWithGoogle();

                  // Cek apakah berhasil login atau tidak
                  if (user != null) {
                    // Kalau berhasil, sapa namanya!
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Selamat datang, ${user.displayName}!'), 
                        backgroundColor: const Color(0xFF138D75),
                      ),
                    );
                  } else {
                    // Kalau gagal atau dibatalkan
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Login dibatalkan atau gagal.'), 
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    ); 
  } 
} 