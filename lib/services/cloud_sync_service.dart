import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaksi.dart';
import '../database/db_helper.dart';

class CloudSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fungsi untuk mendapatkan UID pengguna yang sedang login
  String? get _uid => _auth.currentUser?.uid;

  /// Melakukan proses BACKUP: Menyalin semua data dari SQLite lokal ke Firestore (Cloud)
  Future<bool> backupKeCloud() async {
    if (_uid == null) {
      print("Gagal Backup: User belum login.");
      return false;
    }

    try {
      // 1. Ambil semua transaksi dari memori lokal (SQLite)
      List<Transaksi> daftarTransaksi = await DBHelper().getSemuaTransaksi();
      
      // 2. Siapkan antrean upload ke Firestore secara massal (Batch)
      WriteBatch batch = _firestore.batch();
      CollectionReference transaksiRef = _firestore.collection('users').doc(_uid).collection('transaksi');

      // 3. Masukkan data satu per satu ke antrean
      for (var trx in daftarTransaksi) {
        DocumentReference docRef = transaksiRef.doc(trx.id);
        
        // Kita ubah dulu Transaksi jadi Map
        Map<String, dynamic> data = trx.toMap();
        
        // Catatan: toMap() menyimpan tanggal dalam format ISO String (teks),
        // jadi aman di-upload langsung ke Firestore tanpa takut tipe data salah.
        batch.set(docRef, data);
      }

      // 4. Eksekusi antrean (Upload)
      await batch.commit();
      return true;
      
    } catch (e) {
      print("Error saat Backup ke Cloud: $e");
      return false;
    }
  }

  /// Melakukan proses RESTORE: Mengambil data dari Firestore (Cloud) ke SQLite lokal
  Future<bool> restoreDariCloud() async {
    if (_uid == null) {
      print("Gagal Restore: User belum login.");
      return false;
    }

    try {
      // 1. Ambil semua data transaksi dari Firestore
      QuerySnapshot snapshot = await _firestore.collection('users').doc(_uid).collection('transaksi').get();
      
      if (snapshot.docs.isEmpty) {
        // Berarti emang belum pernah backup
        return true; 
      }

      // 2. Hapus data lokal agar tidak duplikat saat ditarik dari Cloud
      await DBHelper().deleteAllTransaksi();

      // 3. Masukkan satu per satu data dari Cloud ke SQLite
      for (var doc in snapshot.docs) {
        // Ubah bentuk data Cloud (Map) menjadi objek Transaksi
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        Transaksi trx = Transaksi.fromMap(data);
        
        // Simpan ke SQLite
        await DBHelper().insertTransaksi(trx);
      }

      return true;
    } catch (e) {
      print("Error saat Restore dari Cloud: $e");
      return false;
    }
  }
}
