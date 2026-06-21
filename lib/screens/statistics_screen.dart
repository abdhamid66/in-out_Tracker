import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/db_helper.dart';
import '../models/transaksi.dart';
import '../services/kategori_service.dart';
import '../utils/formatters.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final Color primaryColor = const Color(0xFF006D5B);
  Map<String, double> _pengeluaranPerKategori = {};
  Map<String, double> _pemasukanPerKategori = {};
  double _totalPengeluaran = 0;
  double _totalPemasukan = 0;
  bool _isLoading = true;

  DateTime _periodeTerpilih = DateTime.now();
  final List<String> daftarBulan = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  String _getPeriodeLabel() {
    final now = DateTime.now();
    if (_periodeTerpilih.year == now.year && _periodeTerpilih.month == now.month) {
      return 'Bulan Ini';
    }
    return '${daftarBulan[_periodeTerpilih.month - 1]} ${_periodeTerpilih.year}';
  }

  void _periodeSebelumnya() {
    setState(() {
      _periodeTerpilih = DateTime(_periodeTerpilih.year, _periodeTerpilih.month - 1, 1);
    });
    _loadData();
  }

  void _periodeBerikutnya() {
    setState(() {
      _periodeTerpilih = DateTime(_periodeTerpilih.year, _periodeTerpilih.month + 1, 1);
    });
    _loadData();
  }


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    List<Transaksi> data = await DBHelper().getTransaksiBulan(_periodeTerpilih.month, _periodeTerpilih.year);
    
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
    
    var sortedPengeluaran = Map.fromEntries(
      hitungKategoriPengeluaran.entries.toList()..sort((e1, e2) => e2.value.compareTo(e1.value)),
    );
    var sortedPemasukan = Map.fromEntries(
      hitungKategoriPemasukan.entries.toList()..sort((e1, e2) => e2.value.compareTo(e1.value)),
    );

    setState(() {
      _pengeluaranPerKategori = sortedPengeluaran;
      _pemasukanPerKategori = sortedPemasukan;
      _totalPengeluaran = totalPengeluaran;
      _totalPemasukan = totalPemasukan;
      _isLoading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }
    return _buildBody();
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Bulan Material 3
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Periode Laporan',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: Colors.black87),
              ),
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.08), 
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: _periodeSebelumnya,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Icon(Icons.chevron_left_rounded, size: 20, color: primaryColor),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        _getPeriodeLabel(),
                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    InkWell(
                      onTap: _periodeBerikutnya,
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Icon(Icons.chevron_right_rounded, size: 20, color: primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          
          _buildStatSection(
            _getPeriodeLabel() == 'Bulan Ini' ? 'Pemasukan Bulan Ini' : 'Pemasukan ${_getPeriodeLabel()}', 
            _pemasukanPerKategori, _totalPemasukan, const Color(0xFF388E3C), 'pemasukan'
          ),
          const SizedBox(height: 20),
          _buildStatSection(
            _getPeriodeLabel() == 'Bulan Ini' ? 'Pengeluaran Bulan Ini' : 'Pengeluaran ${_getPeriodeLabel()}', 
            _pengeluaranPerKategori, _totalPengeluaran, const Color(0xFFD32F2F), 'pengeluaran'
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildStatSection(String title, Map<String, double> data, double total, Color valueColor, String typeText) {
    if (data.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: Colors.black87)),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: Colors.grey.shade100,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pie_chart_outline_rounded, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada data $typeText ${_getPeriodeLabel() == 'Bulan Ini' ? 'bulan ini' : _getPeriodeLabel().toLowerCase()}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: Colors.black87)),
        const SizedBox(height: 8),
        
        // Grafik Material 3 (Ringkas dan Bersih)
        Card(
          elevation: 0,
          color: valueColor.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: valueColor.withOpacity(0.1), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              children: [
                SizedBox(
                  height: 80,
                  width: 80,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 28, // Lebih kecil dan rapi
                      startDegreeOffset: -90,
                      sections: _generateChartSections(data, total, typeText == 'pemasukan'),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Total', style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(
                        formatRupiah(total),
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: valueColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 10),
        
        // List Kategori - Satu Card menyatu (Material 3 List)
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), 
            side: BorderSide(color: Colors.grey.shade200, width: 1)
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: _buildCategoryList(data, total, valueColor, typeText, typeText == 'pemasukan'),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _generateChartSections(Map<String, double> data, double total, bool isPemasukan) {
    List<PieChartSectionData> sections = [];
    data.forEach((kategori, nominal) {
      final color = KategoriService.getColor(kategori, isPemasukan);
      
      sections.add(
        PieChartSectionData(
          color: color,
          value: nominal,
          title: '', // Kosongkan agar terlihat bersih seperti Donut Chart
          radius: 10, // Ketebalan donut chart yang elegan
        ),
      );
    });
    return sections;
  }

  List<Widget> _buildCategoryList(Map<String, double> data, double total, Color valueColor, String typeStr, bool isPemasukan) {
    List<Widget> list = [];
    int i = 0;
    final entries = data.entries.toList();
    
    for (var entry in entries) {
      final kategori = entry.key;
      final nominal = entry.value;
      final color = KategoriService.getColor(kategori, isPemasukan);
      final double percentage = total > 0 ? (nominal / total) * 100 : 0;
      
      list.add(
        ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          leading: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          title: Text(kategori, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${percentage.toStringAsFixed(1)}%', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          trailing: Text(
            formatRupiah(nominal),
            style: TextStyle(fontWeight: FontWeight.bold, color: valueColor, fontSize: 14),
          ),
        )
      );
      
      // Tambahkan divider tipis kecuali di item terakhir
      if (i < entries.length - 1) {
        list.add(Divider(height: 1, thickness: 1, indent: 40, endIndent: 16, color: Colors.grey.shade100));
      }
      i++;
    }
    return list;
  }
}

