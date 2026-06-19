import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/transaksi.dart';
import '../services/cloud_sync_service.dart';
import 'profile_screen.dart';
import 'kategori_screen.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onDataChanged;
  const SettingsScreen({super.key, this.onDataChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final CloudSyncService _cloudSync = CloudSyncService();

  bool _isLoading = false;
  bool _isBiometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricSettings();
  }

  Future<void> _loadBiometricSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Cek apakah device support biometrik sebelum mengaktifkan
      final localAuth = LocalAuthentication();
      final bool canAuthenticateWithBiometrics = await localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await localAuth.isDeviceSupported();
      
      if (!canAuthenticate) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perangkat ini tidak mendukung fitur biometrik/kunci layar.'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', value);
    setState(() {
      _isBiometricEnabled = value;
    });
  }

  void _hapusSemuaData() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Semua Data?'),
        content: const Text('Peringatan: Semua data transaksi akan dihapus permanen dari HP ini.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await DBHelper().deleteAllTransaksi();
              widget.onDataChanged?.call();
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Semua data berhasil dihapus dari HP.'), backgroundColor: Color(0xFF006D5B)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus Data', style: TextStyle(color: Colors.white)),
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
            Text('Mahasiswa Universitas Islam Madura', style: TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup', style: TextStyle(color: Color(0xFF006D5B), fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Future<void> _prosesBackup() async {
    setState(() => _isLoading = true);
    bool sukses = await _cloudSync.backupKeCloud();
    setState(() => _isLoading = false);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(sukses ? 'Berhasil mencadangkan data ke Cloud! ☁️' : 'Gagal mencadangkan data.'),
        backgroundColor: sukses ? const Color(0xFF006D5B) : Colors.red,
      ),
    );
  }

  Future<void> _prosesRestore() async {
    setState(() => _isLoading = true);
    bool sukses = await _cloudSync.restoreDariCloud();
    setState(() => _isLoading = false);
    
    if (sukses) {
      widget.onDataChanged?.call();
    }
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(sukses ? 'Berhasil memulihkan data dari Cloud! 🎉' : 'Gagal memulihkan data.'),
        backgroundColor: sukses ? const Color(0xFF006D5B) : Colors.red,
      ),
    );
  }

  Future<void> _exportKeExcel() async {
    setState(() => _isLoading = true);
    try {
      // 1. Ambil data dari SQLite
      List<Transaksi> daftarTransaksi = await DBHelper().getSemuaTransaksi();
      
      if (daftarTransaksi.isEmpty) {
        setState(() => _isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada data transaksi untuk diexport.')),
        );
        return;
      }

      // 2. Buat file Excel baru
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      // Header kolom
      sheetObject.appendRow([
        TextCellValue('Tanggal'),
        TextCellValue('Judul'),
        TextCellValue('Kategori'),
        TextCellValue('Jenis'),
        TextCellValue('Nominal (Rp)')
      ]);

      // Isi data
      final formatTanggal = DateFormat('dd MMM yyyy');
      for (var trx in daftarTransaksi) {
        sheetObject.appendRow([
          TextCellValue(formatTanggal.format(trx.tanggal)),
          TextCellValue(trx.judul),
          TextCellValue(trx.kategori),
          TextCellValue(trx.isPemasukan ? 'Pemasukan' : 'Pengeluaran'),
          IntCellValue(trx.nominal.toInt()),
        ]);
      }

      // 3. Simpan file sementara (Temporary)
      var fileBytes = excel.save();
      final directory = await getTemporaryDirectory();
      final String filePath = '${directory.path}/Laporan_Keuangan_InOut.xlsx';
      
      File file = File(filePath);
      await file.writeAsBytes(fileBytes!);

      setState(() => _isLoading = false);

      // 4. Munculkan dialog share
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Ini laporan keuangan bulanan In-Out Tracker.',
      );

    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal export: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: const Color(0xFFF8F9FA),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF006D5B)),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- BAGIAN PENGATURAN UMUM ---
          _buildSectionTitle('Pengaturan Umum'),
          _buildSettingCard(
            icon: Icons.person_rounded,
            title: 'Profil & Akun',
            subtitle: 'Kelola data Google dan status login',
            iconColor: const Color(0xFF006D5B),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
            },
            delay: 0,
          ),

          _buildSettingCard(
            icon: Icons.category_rounded,
            title: 'Kelola Kategori',
            subtitle: 'Tambah atau ubah ikon & warna kategori',
            iconColor: const Color(0xFF006D5B),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const KategoriScreen())).then((_) {
                widget.onDataChanged?.call();
              });
            },
            delay: 0,
          ),
          const SizedBox(height: 20),

          // --- BAGIAN CLOUD SYNC ---
          _buildSectionTitle('Cadangan Cloud (Firebase)'),
          _buildSettingCard(
            icon: Icons.cloud_upload_rounded,
            title: 'Backup ke Cloud',
            subtitle: 'Simpan data lokal ke internet',
            iconColor: Colors.blue.shade600,
            onTap: _prosesBackup,
            delay: 100,
          ),
          _buildSettingCard(
            icon: Icons.cloud_download_rounded,
            title: 'Pulihkan dari Cloud',
            subtitle: 'Tarik data lama dari internet',
            iconColor: Colors.green.shade600,
            onTap: _prosesRestore,
            delay: 200,
          ),
          const SizedBox(height: 20),

          // --- BAGIAN LOKAL ---
          _buildSectionTitle('Manajemen Data Lokal'),
          _buildSettingCard(
            icon: Icons.insert_drive_file_rounded,
            title: 'Export Laporan (Excel)',
            subtitle: 'Download semua transaksi',
            iconColor: Colors.orange.shade600,
            onTap: _exportKeExcel,
            delay: 300,
          ),
          _buildSettingCard(
            icon: Icons.delete_sweep_rounded,
            title: 'Hapus Semua Transaksi',
            subtitle: 'Reset ulang data Transaksi di HP ini',
            iconColor: Colors.red.shade600,
            onTap: _hapusSemuaData,
            delay: 400,
          ),
          const SizedBox(height: 20),

          // --- BAGIAN KEAMANAN ---
          _buildSectionTitle('Keamanan Aplikasi'),
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 600),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, double value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                title: const Text('Kunci Layar (Biometrik/PIN)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black87)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text('Gunakan sidik jari atau PIN saat membuka aplikasi', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ),
                secondary: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.fingerprint_rounded, color: Colors.purple, size: 26),
                ),
                value: _isBiometricEnabled,
                activeColor: const Color(0xFF006D5B),
                activeTrackColor: const Color(0xFF006D5B).withOpacity(0.3),
                onChanged: _toggleBiometric,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          const SizedBox(height: 40),
        ],
      ),
    );
          
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: Colors.black54,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Color iconColor = const Color(0xFF006D5B),
    required VoidCallback onTap,
    int delay = 0,
  }) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 500 + delay),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            splashColor: iconColor.withOpacity(0.1),
            highlightColor: iconColor.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: iconColor, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black87)),
                        const SizedBox(height: 4),
                        Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black38),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
