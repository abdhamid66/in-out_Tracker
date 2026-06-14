import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaksi.dart';
import '../database/db_helper.dart'; // Jika butuh fungsi formatRupiah()

class GrafikCard extends StatefulWidget {
  final List<Transaksi> daftarTransaksi;

  const GrafikCard({
    super.key,
    required this.daftarTransaksi,
  });

  @override
  State<GrafikCard> createState() => _GrafikCardState();
}

class _GrafikCardState extends State<GrafikCard> {
  // Secara default menampilkan Pengeluaran
  bool _isMelihatPengeluaran = true;

  // Fungsi untuk mendapatkan warna berdasarkan kategori
  Color _getColorForKategori(String kategori) {
    switch (kategori) {
      case 'Makanan': return Colors.orange;
      case 'Transportasi': return Colors.blue;
      case 'Hiburan': return Colors.purple;
      case 'Belanja': return Colors.pink;
      case 'Tagihan': return Colors.red;
      case 'Gaji': return Colors.green;
      case 'Bonus': return Colors.teal;
      case 'Bisnis': return Colors.blueAccent;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Filter transaksi berdasarkan tipe yang sedang dilihat (Pengeluaran vs Pemasukan)
    List<Transaksi> transaksiTerkait = widget.daftarTransaksi
        .where((trx) => trx.isPemasukan == !_isMelihatPengeluaran)
        .toList();

    // 2. Hitung total per kategori
    Map<String, double> kategoriTotal = {};
    double totalNominal = 0;
    
    for (var trx in transaksiTerkait) {
      kategoriTotal[trx.kategori] = (kategoriTotal[trx.kategori] ?? 0) + trx.nominal;
      totalNominal += trx.nominal;
    }

    // 3. Siapkan data untuk PieChart dan daftar Legenda
    List<PieChartSectionData> pieChartData = [];
    List<Widget> legendaWidgets = [];

    if (totalNominal > 0) {
      kategoriTotal.forEach((kategori, jumlah) {
        double persentase = (jumlah / totalNominal) * 100;
        Color warna = _getColorForKategori(kategori);
        
        // Data irisan grafik
        pieChartData.add(PieChartSectionData(
          color: warna,
          value: jumlah,
          title: '${persentase.toStringAsFixed(1)}%',
          radius: 50,
          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
        ));

        // Data teks legenda di sebelah grafik
        legendaWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                CircleAvatar(radius: 5, backgroundColor: warna),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    kategori,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  formatRupiah(jumlah),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
          )
        );
      });
    }

    return Container(
      padding: const EdgeInsets.all(15), 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 5, blurRadius: 15, offset: const Offset(0, 5))],
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
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.pie_chart, color: Color(0xFF006D5B), size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Text('Analisis Kategori', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
              const Icon(Icons.more_horiz, color: Colors.grey, size: 18),
            ],
          ),
          const SizedBox(height: 15),
          
          // Tombol Sakelar (Toggle) Pengeluaran / Pemasukan
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isMelihatPengeluaran = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _isMelihatPengeluaran ? Colors.red.shade400 : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'Pengeluaran',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isMelihatPengeluaran ? Colors.white : Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isMelihatPengeluaran = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_isMelihatPengeluaran ? Colors.green.shade400 : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'Pemasukan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: !_isMelihatPengeluaran ? Colors.white : Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 25),

          // Area Grafik dan Legenda
          if (totalNominal == 0)
            const SizedBox(
              height: 150,
              child: Center(child: Text("Belum ada data di kategori ini.", style: TextStyle(color: Colors.grey))),
            )
          else
            Row(
              children: [
                // Bagian Kiri: Grafik Pie Chart
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 150,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2, // Jarak antar irisan
                        centerSpaceRadius: 25, // Lubang di tengah
                        sections: pieChartData,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                // Bagian Kanan: Daftar Legenda Kategori
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: legendaWidgets,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
