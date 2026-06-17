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

  String bulanTerpilih = 'Bulan Ini';
  final List<String> daftarBulan = [
    'Bulan Ini', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

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
    setState(() {
      _isLoading = true;
    });

    List<Transaksi> data = [];
    if (bulanTerpilih == 'Bulan Ini') {
      data = await DBHelper().getTransaksiBulanIni();
    } else {
      int angkaBulan = daftarBulan.indexOf(bulanTerpilih);
      int tahunSekarang = DateTime.now().year;
      data = await DBHelper().getTransaksiBulan(angkaBulan, tahunSekarang);
    }
    
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
        title: const Text('Statistik Cerdas', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 22)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFF8F9FA)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: primaryColor))
        : _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Bulan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Periode Laporan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: bulanTerpilih,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Colors.grey),
                    style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w700),
                    onChanged: (String? nilaiBaru) {
                      if (nilaiBaru != null && nilaiBaru != bulanTerpilih) {
                        setState(() { bulanTerpilih = nilaiBaru; });
                        _loadData();
                      }
                    },
                    items: daftarBulan.map<DropdownMenuItem<String>>((String namaBulan) {
                      return DropdownMenuItem<String>(
                        value: namaBulan,
                        child: Row(
                          children: [
                            if (namaBulan == 'Bulan Ini') const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                            if (namaBulan == 'Bulan Ini') const SizedBox(width: 6),
                            Text(namaBulan),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          
          _buildStatSection(
            bulanTerpilih == 'Bulan Ini' ? 'Pemasukan Bulan Ini' : 'Pemasukan $bulanTerpilih', 
            _pemasukanPerKategori, _totalPemasukan, Colors.green.shade600, 'pemasukan'
          ),
          const SizedBox(height: 20),
          const Divider(height: 40, thickness: 1, color: Colors.black12),
          const SizedBox(height: 10),
          _buildStatSection(
            bulanTerpilih == 'Bulan Ini' ? 'Pengeluaran Bulan Ini' : 'Pengeluaran $bulanTerpilih', 
            _pengeluaranPerKategori, _totalPengeluaran, Colors.red.shade500, 'pengeluaran'
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatSection(String title, Map<String, double> data, double total, Color valueColor, String typeText) {
    if (data.isEmpty) {
      return TweenAnimationBuilder(
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.pie_chart_outline_rounded, size: 60, color: Colors.grey.shade400),
                ),
                const SizedBox(height: 15),
                Text(
                  'Belum ada data $typeText ${bulanTerpilih == 'Bulan Ini' ? 'bulan ini' : bulanTerpilih.toLowerCase()}',
                  style: const TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return TweenAnimationBuilder(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: valueColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Grafik Card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.grey.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: valueColor.withOpacity(0.08), 
                  blurRadius: 20, 
                  offset: const Offset(0, 10),
                  spreadRadius: 2
                ),
              ],
            ),
            child: SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 65,
                      startDegreeOffset: 180,
                      sections: _generateChartSections(data, total),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Total', style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(
                        formatRupiah(total),
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: valueColor),
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
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 15),
          
          // List Kategori
          ..._buildCategoryList(data, total, valueColor, typeText),
        ],
      ),
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
          radius: 55,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(color: Colors.black26, blurRadius: 2)]),
          badgeWidget: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Icon(Icons.circle, size: 10, color: color),
          ),
          badgePositionPercentageOffset: 1.1,
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
        TweenAnimationBuilder(
          duration: Duration(milliseconds: 400 + (i * 100)),
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, double value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(20 * (1 - value), 0),
                child: child,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.category_rounded, color: color, size: 20),
              ),
              title: Text(kategori, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${percentage.toStringAsFixed(1)}%', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatRupiah(nominal),
                    style: TextStyle(fontWeight: FontWeight.w800, color: valueColor, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        )
      );
      i++;
    });
    return list;
  }
}
