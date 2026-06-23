import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/transaksi.dart';
import 'input_screen.dart'; 
import 'history_screen.dart';
import '../database/db_helper.dart'; 
import 'dart:io';
import 'package:intl/intl.dart';
import '../widgets/kartu_saldo.dart';
import '../widgets/grafik_card.dart';
import '../services/cloud_sync_service.dart';
import '../services/kategori_service.dart';
import '../widgets/tombol_menu_home.dart';
import '../screens/statistics_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/tos_screen.dart';
import '../screens/privacy_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/auth_screen.dart';

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
  double anggaranBulanan = 0;

  String waktuUpdate = "Memuat...";
  DateTime _periodeTerpilih = DateTime.now();
  final List<String> daftarBulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  String _getPeriodeLabel() {
    final now = DateTime.now();
    if (_periodeTerpilih.year == now.year && _periodeTerpilih.month == now.month) {
      return 'Bulan Ini';
    }
    return '${daftarBulan[_periodeTerpilih.month - 1]} ${_periodeTerpilih.year}';
  }

  void _periodeSebelumnya() {
    setState(() {
      _periodeTerpilih = DateTime(_periodeTerpilih.year, _periodeTerpilih.month - 1, 1);
    });
    _refreshData();
  }

  void _periodeBerikutnya() {
    setState(() {
      _periodeTerpilih = DateTime(_periodeTerpilih.year, _periodeTerpilih.month + 1, 1);
    });
    _refreshData();
  }

  @override
  void initState() {
    super.initState();
    _refreshData(); // panggil fungsi ambil data saat layar pertama dibuka
  }

  // fungsi untuk mengambil data dari SQLite dan menghitung saldo
  void _refreshData() async {
    List<Transaksi> data = [];

    // Ambil data berdasarkan bulan dan tahun pada _periodeTerpilih
    data = await DBHelper().getTransaksiBulan(_periodeTerpilih.month, _periodeTerpilih.year);

    double hitungMasuk = 0;
    double hitungKeluar = 0;

    for (var item in data) {
      if (item.isPemasukan) {
        hitungMasuk += item.nominal;
      } else {
        hitungKeluar += item.nominal;
      }
    }

    if (!context.mounted) return;

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

  // void _refreshData() async ...
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
            Text('Mahasiswa Universitas Islam Madura', style: TextStyle(color: Colors.grey, fontSize: 11)),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_rounded, size: 60, color: Colors.grey.shade300),
              const SizedBox(height: 15),
              const Text('Belum ada transaksi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 16)),
              const SizedBox(height: 5),
              const Text('Yuk, catat pengeluaran pertamamu!', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    // Kalau ada datanya, buatkan daftarnya
    return Column(
      children: limaTerbaru.map((trx) {
        return Dismissible(
          key: Key(trx.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(12),
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
            await DBHelper().deleteTransaksi(trx.id);
            _refreshData(); // Refresh data beranda
            
            // Auto-sync ke Cloud (berjalan di background tanpa menghentikan layar)
            CloudSyncService().backupKeCloud();

            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Transaksi berhasil dihapus'), backgroundColor: Color(0xFF006D5B)),
            );
          },
          child: Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              onTap: () async {
                final hasilEdit = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => InputScreen(transaksiLama: trx)),
                );
                if (hasilEdit == true) {
                  _refreshData();
                }
              },
              leading: CircleAvatar(
                backgroundColor: KategoriService.getColor(trx.kategori, trx.isPemasukan).withValues(alpha: 0.15),
                child: Icon(
                  KategoriService.getIcon(trx.kategori, trx.isPemasukan),
                  color: KategoriService.getColor(trx.kategori, trx.isPemasukan),
                ),
              ),
              title: Text(
                trx.judul, 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(
                '${trx.kategori} • ${DateFormat('dd MMM yyyy').format(trx.tanggal)}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  trx.isPemasukan ? '+ Rp ${trx.nominal.toInt()}' : '- Rp ${trx.nominal.toInt()}',
                  style: TextStyle(
                    color: trx.isPemasukan ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
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
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.bar_chart, color: Color(0xFF006D5B), size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Ringkasan Keuangan', 
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    border: Border.all(color: Colors.grey.shade300), 
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: _periodeSebelumnya,
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Icon(Icons.chevron_left_rounded, size: 20, color: Color(0xFF006D5B)),
                        ),
                      ),
                      Container(width: 1, height: 16, color: Colors.grey.shade300),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          _getPeriodeLabel(),
                          style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(width: 1, height: 16, color: Colors.grey.shade300),
                      InkWell(
                        onTap: _periodeBerikutnya,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF006D5B)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            KartuSaldo(saldo: saldo, totalPemasukan: totalPemasukan, totalPengeluaran: totalPengeluaran, waktuUpdate: waktuUpdate),
            const SizedBox(height: 15),
            if (anggaranBulanan > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Anggaran Bulanan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        Text(
                          'Sisa: ', 
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: (totalPengeluaran >= anggaranBulanan) ? Colors.red : AppTheme.primaryColor
                          )
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (totalPengeluaran / anggaranBulanan).clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          (totalPengeluaran >= anggaranBulanan) ? Colors.red : 
                          (totalPengeluaran >= anggaranBulanan * 0.8) ? Colors.orange : AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Terpakai \ dari ',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 15),
            ],
            GrafikCard(
              daftarTransaksi: daftarTransaksi,
              onLihatSelengkapnya: () {
                setState(() {
                  _currentIndex = 1; // Pindah ke tab Statistik
                });
              },
            ),
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
                    Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryScreen()));
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
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final isLoggedIn = snapshot.hasData && snapshot.data != null;
        
        // Handle _currentIndex bounds if we just logged in
        if (isLoggedIn && _currentIndex == 3) {
           WidgetsBinding.instance.addPostFrameCallback((_) {
             if (mounted && _currentIndex == 3) {
               setState(() => _currentIndex = 0);
             }
           });
        }

        final List<Widget> daftarHalaman = [
          _buildBeranda(), // Index 0: Halaman Beranda Utama
          const StatisticsScreen(), // Index 1: Halaman Statistik
          SettingsScreen(onDataChanged: _refreshData), // Index 2: Halaman Pengaturan
        ];
        
        if (!isLoggedIn) {
          daftarHalaman.add(const AuthScreen()); // Index 3: Login
        }

        int displayIndex = _currentIndex;
        if (displayIndex >= daftarHalaman.length) {
          displayIndex = 0; // fallback jika index out of range
        }

        final List<BottomNavigationBarItem> bottomNavItems = [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          const BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Statistik'),
          const BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Pengaturan'),
        ];
        
        if (!isLoggedIn) {
          bottomNavItems.add(const BottomNavigationBarItem(icon: Icon(Icons.door_front_door), label: 'Login'));
        }

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
                icon: const Icon(Icons.calendar_month, color: Color(0xFF006D5B), size: 24),
                tooltip: 'Kalender Transaksi',
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CalendarScreen()));
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
                  leading: const Icon(Icons.gavel_rounded, color: Color(0xFF006D5B)),
                  title: const Text('Syarat & Ketentuan'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const TosScreen(isFromSettings: true)));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_rounded, color: Color(0xFF006D5B)),
                  title: const Text('Kebijakan Privasi'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyScreen()));
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info_rounded, color: Color(0xFF006D5B)),
                  title: const Text('Tentang Aplikasi'),
                  onTap: () { Navigator.pop(context); _tampilkanDialogTentang(); },
                ),
              ],
            ),
          ),

          // BODY AKAN OTOMATIS BERUBAH BERDASARKAN TOMBOL YANG DIPENCET
          body: daftarHalaman[displayIndex], 

          // NAVIGASI BAWAH
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: displayIndex,
            onTap: (index) {
              if (index == 0 && _currentIndex != 0) {
                _refreshData();
              }
              setState(() {
                _currentIndex = index;
              });
            }, 
            type: BottomNavigationBarType.fixed, 
            selectedItemColor: const Color(0xFF006D5B), 
            unselectedItemColor: Colors.grey,
            items: bottomNavItems,
          ),
        );
      }
    );
  }
}
