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
    const Color(0xFFE57373), // M3-friendly softer colors
    const Color(0xFF64B5F6),
    const Color(0xFFFFD54F),
    const Color(0xFF81C784),
    const Color(0xFFBA68C8),
    const Color(0xFFFFB74D),
    const Color(0xFF4DB6AC),
    const Color(0xFFF06292),
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
      _transaksiBulanIni = data;
      _pengeluaranPerKategori = sortedPengeluaran;
      _pemasukanPerKategori = sortedPemasukan;
      _totalPengeluaran = totalPengeluaran;
      _totalPemasukan = totalPemasukan;
      _isLoading = false;
    });
  }

  void _tampilkanPilihBulan() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 32, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Pilih Periode', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: primaryColor)),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: daftarBulan.length,
                  itemBuilder: (context, index) {
                    final bulan = daftarBulan[index];
                    final isSelected = bulan == bulanTerpilih;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                      title: Text(bulan, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? primaryColor : Colors.black87)),
                      trailing: isSelected ? Icon(Icons.check_circle_rounded, color: primaryColor) : null,
                      onTap: () {
                        Navigator.pop(context);
                        if (bulan != bulanTerpilih) {
                          setState(() { bulanTerpilih = bulan; });
                          _loadData();
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Statistik Cerdas', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: Colors.white,
        scrolledUnderElevation: 1, // Material 3 scroll effect
        centerTitle: true,
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: primaryColor))
        : _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
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
              ActionChip(
                backgroundColor: primaryColor.withOpacity(0.08),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_month_rounded, size: 16, color: primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      bulanTerpilih,
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down_rounded, size: 20, color: primaryColor),
                  ],
                ),
                onPressed: _tampilkanPilihBulan,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          _buildStatSection(
            bulanTerpilih == 'Bulan Ini' ? 'Pemasukan Bulan Ini' : 'Pemasukan $bulanTerpilih', 
            _pemasukanPerKategori, _totalPemasukan, const Color(0xFF388E3C), 'pemasukan'
          ),
          const SizedBox(height: 32),
          _buildStatSection(
            bulanTerpilih == 'Bulan Ini' ? 'Pengeluaran Bulan Ini' : 'Pengeluaran $bulanTerpilih', 
            _pengeluaranPerKategori, _totalPengeluaran, const Color(0xFFD32F2F), 'pengeluaran'
          ),
          const SizedBox(height: 48),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pie_chart_outline_rounded, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada data $typeText ${bulanTerpilih == 'Bulan Ini' ? 'bulan ini' : bulanTerpilih.toLowerCase()}',
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
        const SizedBox(height: 12),
        
        // Grafik Material 3 (Ringkas dan Bersih)
        Card(
          elevation: 0,
          color: valueColor.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: valueColor.withOpacity(0.1), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Row(
              children: [
                SizedBox(
                  height: 100,
                  width: 100,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 36, // Lebih kecil dan rapi
                      startDegreeOffset: -90,
                      sections: _generateChartSections(data, total),
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
        
        const SizedBox(height: 16),
        
        // List Kategori - Satu Card menyatu (Material 3 List)
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), 
            side: BorderSide(color: Colors.grey.shade200, width: 1)
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: _buildCategoryList(data, total, valueColor, typeText),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _generateChartSections(Map<String, double> data, double total) {
    List<PieChartSectionData> sections = [];
    int i = 0;
    data.forEach((kategori, nominal) {
      final color = _chartColors[i % _chartColors.length];
      
      sections.add(
        PieChartSectionData(
          color: color,
          value: nominal,
          title: '', // Kosongkan agar terlihat bersih seperti Donut Chart
          radius: 12, // Ketebalan donut chart yang elegan
        ),
      );
      i++;
    });
    return sections;
  }

  List<Widget> _buildCategoryList(Map<String, double> data, double total, Color valueColor, String typeStr) {
    List<Widget> list = [];
    int i = 0;
    final entries = data.entries.toList();
    
    for (var entry in entries) {
      final kategori = entry.key;
      final nominal = entry.value;
      final color = _chartColors[i % _chartColors.length];
      final double percentage = total > 0 ? (nominal / total) * 100 : 0;
      
      list.add(
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
        list.add(Divider(height: 1, thickness: 1, indent: 50, endIndent: 20, color: Colors.grey.shade100));
      }
      i++;
    }
    return list;
  }
}

