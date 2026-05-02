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
      version: 1, // versi database, bisa diubah jika ada perubahan struktur tabel
      onCreate: _onCreate,
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
        tanggal TEXT
      )
    ''');
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
    List<Map<String, dynamic>> dataDariDb = await db.query('transaksi', orderBy: 'tanggal DESC');

    // Ubah hasil dari database menjadi bentuk List aplikasi menggunakan fungsi penerjemah fromMap()
    return List.generate(dataDariDb.length, (index) {
      return Transaksi.fromMap(dataDariDb[index]);
    });
  }
}
String formatRupiah(double angka) {
  final formatBaru = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  return formatBaru.format(angka);
}