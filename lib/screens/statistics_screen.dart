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
  double _totalPengeluaran = 0;
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
    
    // Hitung pengeluaran per kategori
    Map<String, double> hitungKategori = {};
    double total = 0;
    
    for (var trx in data) {
      if (!trx.isPemasukan) {
        hitungKategori[trx.kategori] = (hitungKategori[trx.kategori] ?? 0) + trx.nominal;
        total += trx.nominal;
      }
    }
    
    // Urutkan dari pengeluaran terbesar ke terkecil
    var sortedKategori = Map.fromEntries(
      hitungKategori.entries.toList()..sort((e1, e2) => e2.value.compareTo(e1.value)),
    );

    setState(() {
      _transaksiBulanIni = data;
      _pengeluaranPerKategori = sortedKategori;
      _totalPengeluaran = total;
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
    if (_pengeluaranPerKategori.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline_rounded, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Belum ada data pengeluaran bulan ini',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pengeluaran Bulan Ini',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 20),
          
          // Grafik Card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.grey.shade200, blurRadius: 15, spreadRadius: 2),
              ],
            ),
            child: SizedBox(
              height: 250,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 70,
                      sections: _generateChartSections(),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Total', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      Text(
                        formatRupiah(_totalPengeluaran),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          const Text(
            'Rincian per Kategori',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 15),
          
          // List Kategori
          ..._buildCategoryList(),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generateChartSections() {
    List<PieChartSectionData> sections = [];
    int i = 0;
    _pengeluaranPerKategori.forEach((kategori, nominal) {
      final double percentage = (nominal / _totalPengeluaran) * 100;
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

  List<Widget> _buildCategoryList() {
    List<Widget> list = [];
    int i = 0;
    _pengeluaranPerKategori.forEach((kategori, nominal) {
      final color = _chartColors[i % _chartColors.length];
      final double percentage = (nominal / _totalPengeluaran) * 100;
      
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
            subtitle: Text('${percentage.toStringAsFixed(1)}% dari total pengeluaran'),
            trailing: Text(
              formatRupiah(nominal),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14),
            ),
          ),
        )
      );
      i++;
    });
    return list;
  }
}
