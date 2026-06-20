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
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 8.0),
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
              rowHeight: 52,
              daysOfWeekHeight: 40,
              availableGestures: AvailableGestures.horizontalSwipe,
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return const SizedBox();
                  
                  bool hasPemasukan = false;
                  bool hasPengeluaran = false;
                  for (var event in events) {
                    final trx = event as Transaksi;
                    if (trx.isPemasukan) {
                      hasPemasukan = true;
                    } else {
                      hasPengeluaran = true;
                    }
                  }

                  return Positioned(
                    bottom: 4,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasPemasukan)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        if (hasPengeluaran)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: const BoxDecoration(
                  color: Color(0xFF006D5B),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                selectedDecoration: BoxDecoration(
                  color: const Color(0xFF006D5B).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(
                  color: Color(0xFF006D5B),
                  fontWeight: FontWeight.bold,
                ),
                outsideDaysVisible: true,
                defaultTextStyle: const TextStyle(color: Colors.black87),
                weekendTextStyle: const TextStyle(color: Colors.black87),
                cellMargin: const EdgeInsets.all(6),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: false,
                leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black54),
                rightChevronIcon: Icon(Icons.chevron_right, color: Colors.black54),
                titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
                headerPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500),
                weekendStyle: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500),
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
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
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
