import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/db_helper.dart'; // Jika butuh fungsi formatRupiah()

class GrafikCard extends StatelessWidget {
  final double totalPemasukan;
  final double totalPengeluaran;

  const GrafikCard({
    super.key,
    required this.totalPemasukan,
    required this.totalPengeluaran,
  });

  @override
  Widget build(BuildContext context) {
    double total = totalPemasukan + totalPengeluaran;
    double persenMasuk = total == 0 ? 0 : (totalPemasukan / total) * 100;
    double persenKeluar = total == 0 ? 0 : (totalPengeluaran / total) * 100;

    return Container(
      padding: const EdgeInsets.all(15), 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 5, blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.pie_chart, color: Color(0xFF006D5B), size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Text('Visualisasi Arus Kas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
              const Icon(Icons.more_horiz, color: Colors.grey, size: 18),
            ],
          ),
          const SizedBox(height: 15),
          if (total == 0)
            const SizedBox(
              height: 100,
              child: Center(child: Text("Belum ada transaksi", style: TextStyle(color: Colors.grey))),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
}