import 'package:flutter/material.dart';
import '../models/transaksi.dart'; //memanggil model transaksi yang sudah dibuat untuk menyimpan data transaksi baru yang di inputkan di halaman ini
import '../database/db_helper.dart'; // untuk menyimpan data transaksi baru ke database setelah di inputkan di halaman ini

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _nominalController = TextEditingController();
  // variabel untuk menyimpan jenis transaksi, defaultnya adalah pemasukan (true)
  bool _isPemasukan = true;

  // menbhkan asyncronos karena proses menyimpan ke brngks buth sedikit waktu
  void _simpanData() async {

    FocusScope.of(context).unfocus();
    // cek dullu apakh kolomnya kosong
    if (_judulController.text.isEmpty || _nominalController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keterangan dan Nominal Harus Diisi!')),
      );
      return; // hentikan jika koosong
    }

    // memmbungkus data yang di ketikk ke dalam cetakan trnsksi
    final transaksiBaru = Transaksi(
      id : DateTime.now().toString(), // bikinm id acak pakai waktu saat ini
      judul: _judulController.text,
      nominal: double.parse(_nominalController.text), // konversi string ke double
      isPemasukan: _isPemasukan,
      tanggal: DateTime.now(),
    );
    // menyuruh mandor mnyimpan data ke SQLite
    await DBHelper().insertTransaksi(transaksiBaru); // simpan data transaksi baru ke database menggunakan fungsi insertTransaksi dari DBHelper

    // setelah tersimpan tutup halaman ini(kembali ke home)
    if (!mounted) return;  // di gunakan agar flutter tidk eror saat menutup halman
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data Berhasil Disimpan!'),
      ),
    );
    Navigator.pop(context);
// kembali ke halaman home dengan membawa data transaksi baru yang sudah di buat, data ini akan di tangkap oleh halaman home untuk di tambahkan ke daftar transaksi
    Navigator.pop(context, transaksiBaru);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Catat Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // SingleChildScrollView berguna agar layar bisa di geser (scroll) saat keyboard muncul
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),// form bersudut bulatt
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Detail Transaksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              // KOlom judull dengan desain baru
              TextField(
                controller: _judulController,
                decoration: InputDecoration(
                  labelText: 'Keterangan',
                  hintText: 'Contoh: Gaji Bulan Ini, Beli Makan, dll',
                  prefixIcon: Icon(Icons.description,color: Colors.teal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),// kolom input bersudut bulattt
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 20),
                    // kolom nominaml dnbgn desain terbru dengan ikon uang dan warna yang lebih menarik
              TextField(
                controller: _nominalController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nominal (Rp)',
                  hintText: 'Contoh: 15000',
                  prefixIcon: Icon(Icons.attach_money,color: Colors.teal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 20),
              // tombol pilihsn pemasukan/pengeluaran dalam kotakk
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_isPemasukan ? 'Pemasukan (Masuk)' : 'Pengeluaran (Keluar)',
                    style: TextStyle(
                      fontSize: 15,
                      color: _isPemasukan ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    )),
                    Switch(
                      value: _isPemasukan,
                      activeColor: Colors.green,
                      inactiveThumbColor: Colors.red,
                      onChanged: (nilaiBaru) {
                        setState(() {
                          _isPemasukan = nilaiBaru;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // tombol simpan dengan desain baru yang lebih lebar dab warna yang lebih menarik
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _simpanData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),// tombol simpan bersudut bulattt
                    ),
                    elevation: 2,
                  ),
                  child: const Text('SIMPAN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        )
      )
    );
  }
}
        