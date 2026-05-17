import 'package:flutter/material.dart';
import '../screens/input_screen.dart';
import '../screens/hystory_screen.dart';

class TombolMenuHome extends StatelessWidget {
  final VoidCallback onRefresh; // Kabel pemicu refresh data database

  const TombolMenuHome({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              // Jalankan navigasi ke Input Screen
              await Navigator.push(context, MaterialPageRoute(builder: (context) => const InputScreen()));
              onRefresh(); // Picu refresh data setelah pulang ke home
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
              // Jalankan navigasi ke History Screen
              await Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryScreen()));
              onRefresh(); // Picu refresh data setelah pulang ke home
            },
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.all(12), 
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.history_rounded, color: const Color(0xFF138D75), size: 24),
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
    );
  }
}