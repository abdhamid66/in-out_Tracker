import 'package:flutter/material.dart';
import '../models/transaksi.dart';
import '../database/db_helper.dart';
import '../services/cloud_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransaksiProvider with ChangeNotifier {
  List<Transaksi> _daftarTransaksi = [];
  double _totalPemasukan = 0;
  double _totalPengeluaran = 0;
  double _anggaranBulanan = 0;
  bool _isSyncing = false;

  DateTime _periodeTerpilih = DateTime.now();

  // Getters
  List<Transaksi> get daftarTransaksi => _daftarTransaksi;
  double get totalPemasukan => _totalPemasukan;
  double get totalPengeluaran => _totalPengeluaran;
  double get saldo => _totalPemasukan - _totalPengeluaran;
  double get anggaranBulanan => _anggaranBulanan;
  DateTime get periodeTerpilih => _periodeTerpilih;
  bool get isSyncing => _isSyncing;

  TransaksiProvider() {
    _loadAnggaran();
    refreshData();
  }

  Future<void> _loadAnggaran() async {
    final prefs = await SharedPreferences.getInstance();
    _anggaranBulanan = prefs.getDouble('anggaranBulanan') ?? 0;
    notifyListeners();
  }

  Future<void> setAnggaran(double nominal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('anggaranBulanan', nominal);
    _anggaranBulanan = nominal;
    notifyListeners();
  }

  void setPeriode(DateTime periodeBaru) {
    _periodeTerpilih = periodeBaru;
    refreshData();
  }

  void periodeBerikutnya() {
    _periodeTerpilih = DateTime(_periodeTerpilih.year, _periodeTerpilih.month + 1, 1);
    refreshData();
  }

  void periodeSebelumnya() {
    _periodeTerpilih = DateTime(_periodeTerpilih.year, _periodeTerpilih.month - 1, 1);
    refreshData();
  }

  Future<void> refreshData() async {
    // 1. Ambil data transaksi bulan yang dipilih
    _daftarTransaksi = await DBHelper().getTransaksiBulan(
      _periodeTerpilih.month, 
      _periodeTerpilih.year
    );

    // 2. Ambil ringkasan (total pemasukan & pengeluaran) langsung dari database
    final ringkasan = await DBHelper().getRingkasanBulan(
      _periodeTerpilih.month, 
      _periodeTerpilih.year
    );

    _totalPemasukan = ringkasan['pemasukan'] ?? 0;
    _totalPengeluaran = ringkasan['pengeluaran'] ?? 0;

    // Memberitahu UI (layar) bahwa ada data baru, tolong diperbarui
    notifyListeners();
  }

  // --- FUNGSI SINKRONISASI ---
  Future<void> syncKeCloud() async {
    _isSyncing = true;
    notifyListeners();
    
    try {
      await CloudSyncService().backupKeCloud();
    } catch (e) {
      // Error bisa ditangkap lewat menu Settings, untuk backup otomatis biarkan gagal senyap
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // --- FUNGSI CRUD (Tambah, Edit, Hapus) ---

  Future<void> tambahTransaksi(Transaksi transaksi) async {
    await DBHelper().insertTransaksi(transaksi);
    await refreshData();
    // Jalankan backup cloud dengan indikator
    syncKeCloud();
  }

  Future<void> updateTransaksi(Transaksi transaksi) async {
    await DBHelper().updateTransaksi(transaksi);
    await refreshData();
    syncKeCloud();
  }

  Future<void> hapusTransaksi(String id) async {
    await DBHelper().deleteTransaksi(id);
    await refreshData();
    syncKeCloud();
  }

  Future<void> hapusSemuaTransaksi() async {
    await DBHelper().deleteAllTransaksi();
    await refreshData();
  }
}
