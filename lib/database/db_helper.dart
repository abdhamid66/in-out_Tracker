import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaksi.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'in_out_tracker.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {

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

  // --- FUNGSI UNTUK MEMBACA SEMUA DATA TRANSAKSI ---
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