import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaksi.dart';
import '../models/dompet.dart';

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
      version: 3, // versi database diubah menjadi 3 karena ada tambahan tabel dompet
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
        kategori TEXT,
        dompetId TEXT DEFAULT 'default'
      )
    ''');

    await db.execute('''
      CREATE TABLE dompet (
        id TEXT PRIMARY KEY,
        nama TEXT,
        saldo REAL
      )
    ''');

    await db.insert('dompet', {
      'id': 'default',
      'nama': 'Dompet Utama',
      'saldo': 0.0,
    });
  }

  // Fungsi untuk meng-upgrade database dari versi lama ke versi baru
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Jika versi lama kurang dari 2, tambahkan kolom kategori
      await db.execute("ALTER TABLE transaksi ADD COLUMN kategori TEXT DEFAULT 'Lainnya'");
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE dompet (
          id TEXT PRIMARY KEY,
          nama TEXT,
          saldo REAL
        )
      ''');
      await db.insert('dompet', {
        'id': 'default',
        'nama': 'Dompet Utama',
        'saldo': 0.0,
      });
      await db.execute("ALTER TABLE transaksi ADD COLUMN dompetId TEXT DEFAULT 'default'");
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

  Future<List<Transaksi>> getTransaksiBulan(int bulan, int tahun, {String? dompetId}) async {
    Database db = await database;
    
    // Format bulan menjadi 2 digit (misal: 06)
    String bulanStr = bulan.toString().padLeft(2, '0');
    // Format pencarian untuk SQL LIKE (misal: '2026-06-%')
    String searchPattern = '$tahun-$bulanStr-%';

    String whereClause = 'tanggal LIKE ?';
    List<dynamic> whereArgs = [searchPattern];

    if (dompetId != null) {
      whereClause += ' AND dompetId = ?';
      whereArgs.add(dompetId);
    }

    final List<Map<String, dynamic>> dataDariDb = await db.query(
      'transaksi',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'tanggal DESC, id DESC',
    );

    return List.generate(dataDariDb.length, (index) {
      return Transaksi.fromMap(dataDariDb[index]);
    });
  }

  // Fungsi untuk mendapatkan total pemasukan dan pengeluaran secara optimal (langsung dari DB)
  Future<Map<String, double>> getRingkasanBulan(int bulan, int tahun, {String? dompetId}) async {
    Database db = await database;
    
    String bulanStr = bulan.toString().padLeft(2, '0');
    String searchPattern = '$tahun-$bulanStr-%';

    String whereClause = 'tanggal LIKE ?';
    List<dynamic> whereArgs = [searchPattern];

    if (dompetId != null) {
      whereClause += ' AND dompetId = ?';
      whereArgs.add(dompetId);
    }

    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      SELECT isPemasukan, SUM(nominal) as total 
      FROM transaksi 
      WHERE $whereClause
      GROUP BY isPemasukan
      ''',
      whereArgs,
    );

    double totalPemasukan = 0;
    double totalPengeluaran = 0;

    for (var row in result) {
      double total = (row['total'] as num?)?.toDouble() ?? 0.0;
      if (row['isPemasukan'] == 1) {
        totalPemasukan = total;
      } else {
        totalPengeluaran = total;
      }
    }

    return {
      'pemasukan': totalPemasukan,
      'pengeluaran': totalPengeluaran,
    };
  }

  // Fungsi untuk mencari transaksi berdasarkan kata kunci (judul atau kategori)
  Future<List<Transaksi>> cariTransaksi(String keyword) async {
    Database db = await database;
    String searchPattern = '%$keyword%';

    final List<Map<String, dynamic>> dataDariDb = await db.query(
      'transaksi',
      where: 'judul LIKE ? OR kategori LIKE ?',
      whereArgs: [searchPattern, searchPattern],
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

  Future<void> deleteSemuaKecuali(List<String> idsYangDisimpan) async {
    Database db = await database;
    if (idsYangDisimpan.isEmpty) {
      await db.delete('transaksi');
    } else {
      String idList = idsYangDisimpan.map((id) => "'$id'").join(',');
      await db.delete('transaksi', where: 'id NOT IN ($idList)');
    }
  }

  // Fungsi aman untuk mengembalikan data dari Cloud (Restore)
  // Menggunakan SQLite Transaction agar jika gagal, data lama dikembalikan (Rollback)
  Future<void> restoreDataLokal(List<Transaksi> dataCloud) async {
    Database db = await database;
    
    await db.transaction((txn) async {
      // 1. Hapus semua data lokal dalam sesi transaksi ini
      await txn.delete('transaksi');
      
      // 2. Masukkan data cloud ke database lokal
      for (var trx in dataCloud) {
        await txn.insert(
          'transaksi',
          trx.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
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

  // --- FUNGSI UNTUK DOMPET ---
  Future<int> insertDompet(Dompet dompet) async {
    Database db = await database;
    return await db.insert('dompet', dompet.toMap());
  }

  Future<List<Dompet>> getSemuaDompet() async {
    Database db = await database;
    final List<Map<String, dynamic>> dataDariDb = await db.query('dompet');
    return List.generate(dataDariDb.length, (index) {
      return Dompet.fromMap(dataDariDb[index]);
    });
  }

  Future<int> updateDompet(Dompet dompet) async {
    Database db = await database;
    return await db.update(
      'dompet',
      dompet.toMap(),
      where: 'id = ?',
      whereArgs: [dompet.id],
    );
  }

  Future<int> deleteDompet(String id) async {
    Database db = await database;
    return await db.delete(
      'dompet',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
