import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/db_helper.dart';
import '../models/transaksi.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final Color primaryColor = const Color(0xFF006D5B);
  List<Transaksi> _transaksiBulanIni = [];
  Map<String, double> _pengeluaranPerKategori = {};
  Map<String, double> _pemasukanPerKategori = {};
  double _totalPengeluaran = 0;
  double _totalPemasukan = 0;
  bool _isLoading = true;

  final List<Color> _chartColors = [
    const Color(0xFFFF6384),
    const Color(0xFF36A2EB),
    const Color(0xFFFFCE56),
    const Color(0xFF4BC0C0),
    const Color(0xFF9966FF),
    const Color(0xFFFF9F40),
    Colors.teal,
    Colors.pinkAccent,
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await DBHelper().getTransaksiBulanIni();
    
    // Hitung pengeluaran dan pemasukan per kategori
    Map<String, double> hitungKategoriPengeluaran = {};
    Map<String, double> hitungKategoriPemasukan = {};
    double totalPengeluaran = 0;
    double totalPemasukan = 0;
    
    for (var trx in data) {
      if (!trx.isPemasukan) {
        hitungKategoriPengeluaran[trx.kategori] = (hitungKategoriPengeluaran[trx.kategori] ?? 0) + trx.nominal;
        totalPengeluaran += trx.nominal;
      } else {
        hitungKategoriPemasukan[trx.kategori] = (hitungKategoriPemasukan[trx.kategori] ?? 0) + trx.nominal;
        totalPemasukan += trx.nominal;
      }
    }
    
    // Urutkan dari terbesar ke terkecil
    var sortedPengeluaran = Map.fromEntries(
      hitungKategoriPengeluaran.entries.toList()..sort((e1, e2) => e2.value.compareTo(e1.value)),
    );
    var sortedPemasukan = Map.fromEntries(
      hitungKategoriPemasukan.entries.toList()..sort((e1, e2) => e2.value.compareTo(e1.value)),
    );

    setState(() {
      _transaksiBulanIni = data;
      _pengeluaranPerKategori = sortedPengeluaran;
      _pemasukanPerKategori = sortedPemasukan;
      _totalPengeluaran = totalPengeluaran;
      _totalPemasukan = totalPemasukan;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Statistik Cerdas', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: primaryColor))
        : _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatSection('Pemasukan Bulan Ini', _pemasukanPerKategori, _totalPemasukan, Colors.green, 'pemasukan'),
          const Divider(height: 40, thickness: 1.5, color: Colors.black12),
          _buildStatSection('Pengeluaran Bulan Ini', _pengeluaranPerKategori, _totalPengeluaran, Colors.red, 'pengeluaran'),
        ],
      ),
    );
  }

  Widget _buildStatSection(String title, Map<String, double> data, double total, Color valueColor, String typeText) {
    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pie_chart_outline_rounded, size: 60, color: Colors.grey.shade300),
              const SizedBox(height: 10),
              Text(
                'Belum ada data $typeText bulan ini',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 15),
        
        // Grafik Card
        Container(
          padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.grey.shade200, blurRadius: 15, spreadRadius: 2),
            ],
          ),
          child: SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 65,
                    sections: _generateChartSections(data, total),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Total', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    Text(
                      formatRupiah(total),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: valueColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 25),
        
        const Text(
          'Rincian per Kategori',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 10),
        
        // List Kategori
        ..._buildCategoryList(data, total, valueColor, typeText),
      ],
    );
  }

  List<PieChartSectionData> _generateChartSections(Map<String, double> data, double total) {
    List<PieChartSectionData> sections = [];
    int i = 0;
    data.forEach((kategori, nominal) {
      final double percentage = total > 0 ? (nominal / total) * 100 : 0;
      final color = _chartColors[i % _chartColors.length];
      
      sections.add(
        PieChartSectionData(
          color: color,
          value: nominal,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 50,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
      i++;
    });
    return sections;
  }

  List<Widget> _buildCategoryList(Map<String, double> data, double total, Color valueColor, String typeStr) {
    List<Widget> list = [];
    int i = 0;
    data.forEach((kategori, nominal) {
      final color = _chartColors[i % _chartColors.length];
      final double percentage = total > 0 ? (nominal / total) * 100 : 0;
      
      list.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            leading: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            title: Text(kategori, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: Text('${percentage.toStringAsFixed(1)}% dari total $typeStr'),
            trailing: Text(
              formatRupiah(nominal),
              style: TextStyle(fontWeight: FontWeight.bold, color: valueColor, fontSize: 14),
            ),
          ),
        )
      );
      i++;
    });
    return list;
  }
}
