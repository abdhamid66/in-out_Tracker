import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'tos_screen.dart';
import 'privacy_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  void _hapusSemuaData() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Semua Data?'),
        content: const Text('Peringatan: Semua data transaksi akan dihapus permanen dan tidak bisa dikembalikan.'),
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
                const SnackBar(content: Text('Semua data berhasil dihapus.'), backgroundColor: Color(0xFF006D5B)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            const Text(
              'Manajemen Data',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 15),
            _buildSettingCard(
              icon: Icons.delete_forever_outlined,
              title: 'Hapus Semua Transaksi',
              subtitle: 'Reset ulang data keuangan',
              iconColor: Colors.red,
              onTap: _hapusSemuaData,
            ),
            
            const SizedBox(height: 30),
            const Text(
              'Informasi & Bantuan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 15),
            _buildSettingCard(
              icon: Icons.gavel_rounded,
              title: 'Syarat & Ketentuan',
              subtitle: 'Aturan penggunaan aplikasi',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const TosScreen(isFromSettings: true)));
              },
            ),
            const SizedBox(height: 10),
            _buildSettingCard(
              icon: Icons.privacy_tip_outlined,
              title: 'Kebijakan Privasi',
              subtitle: 'Bagaimana data Anda dilindungi',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyScreen()));
              },
            ),
            const SizedBox(height: 10),
            _buildSettingCard(
              icon: Icons.info_outline,
              title: 'Tentang Aplikasi',
              subtitle: 'Versi dan Info Developer',
              onTap: _tampilkanDialogTentang,
            ),
          ],
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
