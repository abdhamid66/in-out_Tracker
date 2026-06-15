import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/transaksi.dart';
import '../services/cloud_sync_service.dart';
import 'tos_screen.dart';
import 'privacy_screen.dart';
import 'profile_screen.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

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
            Text('Mahasiswa Semester 4', style: TextStyle(color: Colors.grey, fontSize: 11)),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Pengaturan', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- BAGIAN PROFIL & AKUN ---
                const Text(
                  'Akun Pengguna',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 15),
                _buildSettingCard(
                  icon: Icons.person_outline,
                  title: 'Profil & Akun',
                  subtitle: 'Kelola data Google dan status login',
                  iconColor: const Color(0xFF006D5B),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                  },
                ),
                const SizedBox(height: 30),

                // --- BAGIAN CLOUD SYNC ---
                const Text(
                  'Cadangan Cloud (Firebase)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 15),
                _buildSettingCard(
                  icon: Icons.cloud_upload_outlined,
                  title: 'Backup ke Cloud',
                  subtitle: 'Simpan data lokal ke internet',
                  iconColor: Colors.blue,
                  onTap: _prosesBackup,
                ),
                const SizedBox(height: 10),
                _buildSettingCard(
                  icon: Icons.cloud_download_outlined,
                  title: 'Pulihkan dari Cloud',
                  subtitle: 'Tarik data lama dari internet',
                  iconColor: Colors.green,
                  onTap: _prosesRestore,
                ),
                const SizedBox(height: 30),

                // --- BAGIAN LOKAL ---
                const Text(
                  'Manajemen Data Lokal',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 15),
                _buildSettingCard(
                  icon: Icons.insert_drive_file_outlined,
                  title: 'Export Laporan (Excel)',
                  subtitle: 'Download semua transaksi',
                  iconColor: Colors.orange,
                  onTap: _exportKeExcel,
                ),
                const SizedBox(height: 10),
                _buildSettingCard(
                  icon: Icons.delete_forever_outlined,
                  title: 'Hapus Semua Transaksi',
                  subtitle: 'Reset ulang data di HP ini',
                  iconColor: Colors.red,
                  onTap: _hapusSemuaData,
                ),
                const SizedBox(height: 30),

                // --- BAGIAN KEAMANAN ---
                const Text(
                  'Keamanan Aplikasi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 15),
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    title: const Text('Kunci Layar (Biometrik/PIN)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87)),
                    subtitle: Text('Gunakan sidik jari atau PIN saat membuka aplikasi', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    secondary: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.fingerprint, color: Colors.purple, size: 24),
                    ),
                    value: _isBiometricEnabled,
                    activeColor: const Color(0xFF006D5B),
                    onChanged: _toggleBiometric,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
                const SizedBox(height: 30),

                // --- BAGIAN INFORMASI ---
                const Text(
                  'Informasi & Bantuan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 15),
                _buildSettingCard(
                  icon: Icons.gavel_rounded,
                  title: 'Syarat & Ketentuan',
                  subtitle: 'Aturan penggunaan aplikasi',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TosScreen(isFromSettings: true))),
                ),
                const SizedBox(height: 10),
                _buildSettingCard(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Kebijakan Privasi',
                  subtitle: 'Bagaimana data Anda dilindungi',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyScreen())),
                ),
                const SizedBox(height: 10),
                _buildSettingCard(
                  icon: Icons.info_outline,
                  title: 'Tentang Aplikasi',
                  subtitle: 'Versi dan Info Developer',
                  onTap: _tampilkanDialogTentang,
                ),
                const SizedBox(height: 30),

                const SizedBox(height: 40),
              ],
            ),
          ),
          
          // --- LOADING OVERLAY ---
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF006D5B)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Color iconColor = const Color(0xFF006D5B),
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // Sudut lebih membulat ala Material 3
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle, // Ikon bulat
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onTap: onTap,
      ),
    );
  }
}
