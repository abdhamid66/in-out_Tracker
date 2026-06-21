import 'package:flutter/material.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../database/db_helper.dart';
import '../models/transaksi.dart';

class ExportService {
  static Future<void> exportKeExcel(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Sedang menyiapkan data Excel...'),
        backgroundColor: const Color(0xFF138D75),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );

    try {
      final List<Transaksi> data = await DBHelper().getSemuaTransaksi();
      
      if (data.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tidak ada data transaksi untuk diexport.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }

      var excel = Excel.createExcel();
      Sheet sheet = excel['Laporan Keuangan'];
      excel.setDefaultSheet('Laporan Keuangan');

      sheet.appendRow([
        TextCellValue('Tanggal'), 
        TextCellValue('Judul Transaksi'), 
        TextCellValue('Kategori'),
        TextCellValue('Jenis'), 
        TextCellValue('Nominal (Rp)'),
      ]);

      final formatTanggal = DateFormat('dd MMM yyyy');
      for (var item in data) {
        String jenis = item.isPemasukan ? 'Pemasukan' : 'Pengeluaran';
        sheet.appendRow([
          TextCellValue(formatTanggal.format(item.tanggal)), 
          TextCellValue(item.judul), 
          TextCellValue(item.kategori),
          TextCellValue(jenis), 
          IntCellValue(item.nominal.toInt()),
        ]);
      }

      var fileBytes = excel.save();
      var directory = await getTemporaryDirectory();
      File file = File('${directory.path}/Laporan_Keuangan_InOut.xlsx');
      await file.writeAsBytes(fileBytes!);

      if (!context.mounted) return;
      await Share.shareXFiles([XFile(file.path)], text: 'Ini laporan keuangan bulanan In-Out Tracker.');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengekspor: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}
