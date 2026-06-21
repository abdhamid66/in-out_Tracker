import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/kategori.dart';

class KategoriService {
  static const String _key = 'kategori_kustom_data';

  // Daftar icon yang didukung (harus direferensikan secara statis agar tidak di-tree-shake)
  static const List<IconData> availableIcons = [
    Icons.account_balance_wallet_rounded,
    Icons.card_giftcard_rounded,
    Icons.storefront_rounded,
    Icons.fastfood_rounded,
    Icons.directions_car_rounded,
    Icons.movie_creation_rounded,
    Icons.shopping_bag_rounded,
    Icons.receipt_long_rounded,
    Icons.category_rounded,
    Icons.pets_rounded,
    Icons.flight_takeoff_rounded,
    Icons.favorite_rounded,
    Icons.local_hospital_rounded,
    Icons.school_rounded,
    Icons.sports_esports_rounded,
    Icons.home_rounded,
    Icons.laptop_chromebook_rounded,
    Icons.fitness_center_rounded,
  ];

  // Menyimpan daftar kategori di memori saat aplikasi jalan
  static List<KategoriItem> _kategoriCache = [];

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dataJson = prefs.getString(_key);

    if (dataJson != null) {
      final List<dynamic> decoded = jsonDecode(dataJson);
      _kategoriCache = decoded.map((e) => KategoriItem.fromMap(e)).toList();
    } else {
      // Jika belum ada, isi dengan default
      _kategoriCache = _getDefaultKategori();
      await _saveToStorage();
    }
  }

  static Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String dataJson = jsonEncode(_kategoriCache.map((e) => e.toMap()).toList());
    await prefs.setString(_key, dataJson);
  }

  static List<KategoriItem> getSemuaPemasukan() {
    return _kategoriCache.where((k) => k.isPemasukan).toList();
  }

  static List<KategoriItem> getSemuaPengeluaran() {
    return _kategoriCache.where((k) => !k.isPemasukan).toList();
  }

  static Future<void> tambahKategori(KategoriItem kategori) async {
    _kategoriCache.add(kategori);
    await _saveToStorage();
  }

  static Future<void> updateKategori(KategoriItem kategori) async {
    final index = _kategoriCache.indexWhere((k) => k.id == kategori.id);
    if (index != -1) {
      _kategoriCache[index] = kategori;
      await _saveToStorage();
    }
  }

  static Future<void> hapusKategori(String id) async {
    _kategoriCache.removeWhere((k) => k.id == id);
    await _saveToStorage();
  }

  // Mendapatkan warna berdasarkan nama kategori
  static Color getColor(String nama, bool isPemasukan) {
    try {
      final item = _kategoriCache.firstWhere(
        (k) => k.nama == nama && k.isPemasukan == isPemasukan
      );
      return Color(item.colorValue);
    } catch (e) {
      // Fallback color
      return isPemasukan ? Colors.green : Colors.red;
    }
  }

  // Mendapatkan IconData berdasarkan nama kategori
  static IconData getIcon(String nama, bool isPemasukan) {
    try {
      final item = _kategoriCache.firstWhere(
        (k) => k.nama == nama && k.isPemasukan == isPemasukan
      );
      return availableIcons.firstWhere(
        (icon) => icon.codePoint == item.iconCode,
        orElse: () => Icons.category_rounded,
      );
    } catch (e) {
      // Fallback icon
      return Icons.category_rounded;
    }
  }

  static List<KategoriItem> _getDefaultKategori() {
    return [
      // PEMASUKAN
      KategoriItem(id: 'p_gaji', nama: 'Gaji', isPemasukan: true, iconCode: Icons.account_balance_wallet_rounded.codePoint, colorValue: Colors.green.value),
      KategoriItem(id: 'p_bonus', nama: 'Bonus', isPemasukan: true, iconCode: Icons.card_giftcard_rounded.codePoint, colorValue: Colors.teal.value),
      KategoriItem(id: 'p_bisnis', nama: 'Bisnis', isPemasukan: true, iconCode: Icons.storefront_rounded.codePoint, colorValue: Colors.blue.value),
      KategoriItem(id: 'p_lainnya', nama: 'Lainnya', isPemasukan: true, iconCode: Icons.category_rounded.codePoint, colorValue: Colors.green.value),
      // PENGELUARAN
      KategoriItem(id: 'k_makanan', nama: 'Makanan', isPemasukan: false, iconCode: Icons.fastfood_rounded.codePoint, colorValue: Colors.orange.value),
      KategoriItem(id: 'k_transportasi', nama: 'Transportasi', isPemasukan: false, iconCode: Icons.directions_car_rounded.codePoint, colorValue: Colors.blue.value),
      KategoriItem(id: 'k_hiburan', nama: 'Hiburan', isPemasukan: false, iconCode: Icons.movie_creation_rounded.codePoint, colorValue: Colors.purple.value),
      KategoriItem(id: 'k_belanja', nama: 'Belanja', isPemasukan: false, iconCode: Icons.shopping_bag_rounded.codePoint, colorValue: Colors.pink.value),
      KategoriItem(id: 'k_tagihan', nama: 'Tagihan', isPemasukan: false, iconCode: Icons.receipt_long_rounded.codePoint, colorValue: Colors.red.value),
      KategoriItem(id: 'k_lainnya', nama: 'Lainnya', isPemasukan: false, iconCode: Icons.category_rounded.codePoint, colorValue: Colors.grey.value),
    ];
  }
}
