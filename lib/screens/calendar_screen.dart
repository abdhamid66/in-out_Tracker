import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/transaksi.dart';
import '../database/db_helper.dart';
import 'package:intl/intl.dart';
import '../services/kategori_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Transaksi>> _groupedTransactions = {};
  List<Transaksi> _selectedTransactions = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final allTransactions = await DBHelper().getSemuaTransaksi();
    Map<DateTime, List<Transaksi>> grouped = {};
    for (var trx in allTransactions) {
      final date = DateTime(trx.tanggal.year, trx.tanggal.month, trx.tanggal.day);
      if (grouped[date] == null) {
        grouped[date] = [];
      }
      grouped[date]!.add(trx);
    }
    setState(() {
      _groupedTransactions = grouped;
      _selectedTransactions = _getTransactionsForDay(_selectedDay!);
    });
  }

  List<Transaksi> _getTransactionsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _groupedTransactions[date] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Kalender Transaksi', style: TextStyle(color: Color(0xFF006D5B), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF006D5B)),
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TableCalendar<Transaksi>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _selectedTransactions = _getTransactionsForDay(selectedDay);
                  });
                },
                eventLoader: _getTransactionsForDay,
                rowHeight: 60,
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) return const SizedBox();
                    
                    double pemasukan = 0;
                    double pengeluaran = 0;
                    for (var event in events) {
                      final trx = event as Transaksi;
                      if (trx.isPemasukan) {
                        pemasukan += trx.nominal;
                      } else {
                        pengeluaran += trx.nominal;
                      }
                    }

                    return Positioned(
                      bottom: 2,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (pemasukan > 0)
                            Text(
                              '+${NumberFormat.compact().format(pemasukan)}',
                              style: const TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          if (pemasukan > 0 && pengeluaran > 0)
                            const SizedBox(width: 2),
                          if (pengeluaran > 0)
                            Text(
                              '-${NumberFormat.compact().format(pengeluaran)}',
                              style: const TextStyle(color: Colors.red, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: const Color(0xFF006D5B).withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Color(0xFF006D5B),
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _selectedDay != null ? 'Transaksi pada ${DateFormat('dd MMM yyyy').format(_selectedDay!)}' : 'Transaksi',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _selectedTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_rounded, size: 50, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        const Text('Tidak ada transaksi', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _selectedTransactions.length,
                    itemBuilder: (context, index) {
                      final trx = _selectedTransactions[index];
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: KategoriService.getColor(trx.kategori, trx.isPemasukan).withOpacity(0.15),
                            child: Icon(
                              KategoriService.getIcon(trx.kategori, trx.isPemasukan),
                              color: KategoriService.getColor(trx.kategori, trx.isPemasukan),
                            ),
                          ),
                          title: Text(
                            trx.judul,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            trx.kategori,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            trx.isPemasukan ? '+ Rp ${trx.nominal.toInt()}' : '- Rp ${trx.nominal.toInt()}',
                            style: TextStyle(
                              color: trx.isPemasukan ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
