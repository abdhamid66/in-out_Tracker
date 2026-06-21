import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaksi.dart';
import 'package:intl/intl.dart';

class DBHelper {
  // Membuat singleton untuk memastikan hanya ada satu instance DBHelper yang digunakan di seluruh aplikasi
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();
  // Variabel untuk menyimpan instance database, awalnya null, nanti akan diinisialisasi saat pertama kali dipanggil
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!; // Jika database sudah diinisialisasi, langsung kembalikan instance-nya
    // Jika belum, inisialisasi database terlebih dahulu
    _database = await _initDB();
    return _database!;
  }
  // fungsii utk mbmbuat filee database di dalam hp
  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'in_out_tracker.db');
    // mmbuka dtabase, dan jika belum ada filenya jalankan fungsi _onCreate
    return await openDatabase(
      path,
      version: 2, // versi database diubah menjadi 2 karena ada tambahan kolom kategori
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  // fungsi untuk membuat tabel transaksi di dalam database, dengan kolom id, judul, nominal, isPemasukan, dan tanggal
  Future<void> _onCreate(Database db, int version) async {
  // mengunakan bahasa sql sederhana untuk mbuat kolomnya
    await db.execute('''
      CREATE TABLE transaksi (
        id TEXT PRIMARY KEY,
        judul TEXT,
        nominal REAL,
        isPemasukan INTEGER,
        tanggal TEXT,
        kategori TEXT
      )
    ''');
  }

  // Fungsi untuk meng-upgrade database dari versi lama ke versi baru
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Jika versi lama kurang dari 2, tambahkan kolom kategori
      await db.execute("ALTER TABLE transaksi ADD COLUMN kategori TEXT DEFAULT 'Lainnya'");
    }
  }
  // --- FUNGSI UNTUK MENYIMPAN DATA TRANSAKSI ---
  Future<int> insertTransaksi(Transaksi transaksi) async {
    // Panggil database-nya
    Database db = await database;
    // Masukkan data ke tabel 'transaksi', dengan menggunakan fungsi penerjemah toMap()
    return await db.insert('transaksi', transaksi.toMap());
  }

  // fungsi untuk mnyimpan dat atransaksi
  Future<List<Transaksi>> getSemuaTransaksi() async {
    Database db = await database;
    // Minta semua data dari tabel 'transaksi', urutkan dari tanggal terbaru ke terlama (DESC)
    final List<Map<String, dynamic>> dataDariDb = await db.query(
      'transaksi',
      orderBy: 'id DESC',
    );

    // Ubah hasil dari database menjadi bentuk List aplikasi menggunakan fungsi penerjemah fromMap()
    return List.generate(dataDariDb.length, (index) {
      return Transaksi.fromMap(dataDariDb[index]);
    });
  }

  Future<List<Transaksi>> getTransaksiBulanIni() async {
    final sekarang = DateTime.now();
    return await getTransaksiBulan(sekarang.month, sekarang.year);
  }

  Future<List<Transaksi>> getTransaksiBulan(int bulan, int tahun) async {
    Database db = await database;
    
    // Format bulan menjadi 2 digit (misal: 06)
    String bulanStr = bulan.toString().padLeft(2, '0');
    // Format pencarian untuk SQL LIKE (misal: '2026-06-%')
    String searchPattern = '$tahun-$bulanStr-%';

    final List<Map<String, dynamic>> dataDariDb = await db.query(
      'transaksi',
      where: 'tanggal LIKE ?',
      whereArgs: [searchPattern],
      orderBy: 'tanggal DESC, id DESC',
    );

    return List.generate(dataDariDb.length, (index) {
      return Transaksi.fromMap(dataDariDb[index]);
    });
  }

  Future<int> deleteTransaksi(String id) async {
    Database db = await database;
    return await db.delete(
      'transaksi',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllTransaksi() async {
    Database db = await database;
    return await db.delete('transaksi');
  }

// fungsi untuk menghapus data
  Future<int> updateTransaksi(Transaksi transaksi) async {
    Database db = await database;
    // menghapus data dari table trnsakksi yng id ny cocook dg yg d pilih
    return await db.update(
      'transaksi',
      transaksi.toMap(), 
      where: 'id = ?',
      whereArgs: [transaksi.id],
    );
  }
}
}