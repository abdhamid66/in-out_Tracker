import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaksi.dart';
import '../utils/formatters.dart';

class GrafikCard extends StatefulWidget {
  final List<Transaksi> daftarTransaksi;
  final VoidCallback onLihatSelengkapnya;

  const GrafikCard({
    super.key,
    required this.daftarTransaksi,
    required this.onLihatSelengkapnya,
  });

  @override
  State<GrafikCard> createState() => _GrafikCardState();
}

class _GrafikCardState extends State<GrafikCard> {
  bool _isExpanded = true;

  String _formatSingkat(double angka) {
    if (angka >= 1000000000) {
      double val = angka / 1000000000;
      return 'Rp ${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1).replaceAll('.', ',')} M';
    } else if (angka >= 1000000) {
      double val = angka / 1000000;
      return 'Rp ${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1).replaceAll('.', ',')} Jt';
    } else {
      return formatRupiah(angka);
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalPemasukan = 0;
    double totalPengeluaran = 0;

    for (var trx in widget.daftarTransaksi) {
      if (trx.isPemasukan) {
        totalPemasukan += trx.nominal;
      } else {
        totalPengeluaran += trx.nominal;
      }
    }

    double total = totalPemasukan + totalPengeluaran;

    List<PieChartSectionData> pieChartData = [];
    double pctPemasukan = 0;
    double pctPengeluaran = 0;
    
    if (total > 0) {
      pctPemasukan = (totalPemasukan / total) * 100;
      pctPengeluaran = (totalPengeluaran / total) * 100;

      if (totalPengeluaran > 0) {
        pieChartData.add(PieChartSectionData(
          color: const Color(0xFFEF5350), // Merah untuk Pengeluaran
          value: totalPengeluaran,
          title: '', // Teks disembunyikan di dalam chart
          radius: 20, // Ketebalan donut
        ));
      }
      if (totalPemasukan > 0) {
        pieChartData.add(PieChartSectionData(
          color: const Color(0xFF26C6DA), // Cyan untuk Pemasukan
          value: totalPemasukan,
          title: '',
          radius: 20, 
        ));
      }
    }

    return Container(
      padding: const EdgeInsets.all(20), 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08), 
            spreadRadius: 5, 
            blurRadius: 15, 
            offset: const Offset(0, 5)
          )
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.pie_chart, color: Color(0xFF006D5B), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text('Visualisasi Arus Kas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
              Row(
                children: [
                  // Tombol Lihat Selengkapnya (titik 3 di screenshot)
                  GestureDetector(
                    onTap: widget.onLihatSelengkapnya,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.more_horiz, color: Colors.grey, size: 20),
                    ),
                  ),
                  const SizedBox(width: 5),
                  // Tombol Tutup/Buka
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006D5B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: const Color(0xFF006D5B),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: !_isExpanded
                ? const SizedBox.shrink()
                : Column(
                    children: [
                      const SizedBox(height: 30),
                      if (total == 0)
                        const SizedBox(
                          height: 120,
                          child: Center(child: Text("Belum ada data transaksi.", style: TextStyle(color: Colors.grey))),
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Kiri: Pengeluaran
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const CircleAvatar(radius: 4, backgroundColor: Color(0xFFEF5350)),
                                      const SizedBox(width: 6),
                                      const Text('Pengeluaran', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text('${pctPengeluaran.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  const SizedBox(height: 2),
                                  Text(_formatSingkat(totalPengeluaran), style: const TextStyle(fontSize: 11, color: Color(0xFFEF5350))),
                                ],
                              ),
                            ),
                            
                            // Tengah: Grafik Donut
                            Expanded(
                              flex: 3,
                              child: SizedBox(
                                height: 110,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    PieChart(
                                      PieChartData(
                                        sectionsSpace: 0, // Dibuat menempel seperti screenshot
                                        centerSpaceRadius: 35, 
                                        startDegreeOffset: -90,
                                        sections: pieChartData,
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.show_chart, color: Color(0xFF006D5B), size: 16),
                                        Text('Arus Kas', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Kanan: Pemasukan
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      const CircleAvatar(radius: 4, backgroundColor: Color(0xFF26C6DA)),
                                      const SizedBox(width: 6),
                                      const Text('Pemasukan', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text('${pctPemasukan.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  const SizedBox(height: 2),
                                  Text(_formatSingkat(totalPemasukan), style: const TextStyle(fontSize: 11, color: Color(0xFF006D5B))),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
