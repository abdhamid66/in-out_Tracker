import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/db_helper.dart';
import '../services/cloud_sync_service.dart';
import '../services/auth_service.dart';
import 'tos_screen.dart';
import 'privacy_screen.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final CloudSyncService _cloudSync = CloudSyncService();

  bool _isLoading = false;

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

  Future<void> _prosesLogout() async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      (route) => false,
    );
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
                // --- BAGIAN PROFIL ---
                if (user != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF006D5B), Color(0xFF138D75)]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: const Color(0xFF006D5B).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          backgroundImage: user!.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                          child: user!.photoURL == null ? const Icon(Icons.person, size: 30, color: Colors.grey) : null,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user!.displayName ?? 'Pengguna', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              Text(user!.email ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],

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
                  icon: Icons.delete_forever_outlined,
                  title: 'Hapus Semua Transaksi',
                  subtitle: 'Reset ulang data di HP ini',
                  iconColor: Colors.red,
                  onTap: _hapusSemuaData,
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

                // --- TOMBOL KELUAR ---
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _prosesLogout,
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('Keluar (Logout)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
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
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
