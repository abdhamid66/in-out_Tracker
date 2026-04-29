import 'package:flutter/material.dart';
import '../models/transaksi.dart'; //memanggil model transaksi yang sudah dibuat untuk menyimpan data transaksi baru yang di inputkan di halaman ini

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

  // fungsi untuk menyimpan data transaksi baru yang di inputkan, jika judul atau nominal
  void _simpanData() {
    // cek dullu apakh kolomnya kosong
    if (_judulController.text.isEmpty || _nominalController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan Nominal Harus Diisi!')),
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
// kembali ke halaman home dengan membawa data transaksi baru yang sudah di buat, data ini akan di tangkap oleh halaman home untuk di tambahkan ke daftar transaksi
    Navigator.pop(context, transaksiBaru);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catat Transaksi'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _judulController,
              decoration: const InputDecoration(
                labelText: 'Keterangan (contoh: jual pop ice/ beli gula)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
// kolom nominal uangg
            TextField(
              controller: _nominalController,
              keyboardType: TextInputType.number, //supaya keyboard yang muncul hanya angkaa
              decoration: const InputDecoration(
                labelText: 'Nominal (Rp)',
                border: OutlineInputBorder(),
              )
            ),
            const SizedBox(height: 15),
            // widget untuk memilih jenis transaksi, menggunakan switch untuk mengganti antara pemasukan dan pengeluaran
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Jenis Transaksi:', style: TextStyle(fontSize: 16)),
                Row(
                  children: [
                    Text(_isPemasukan ? 'Pemasukan (Masuk)' : 'Pengeluaran (Keluar)',
                    style: TextStyle
                    (color: _isPemasukan ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold)),
                    Switch(
                      value: _isPemasukan,
                      activeColor: Colors.green, // warna saat on(pemasukan)
                      inactiveThumbColor: Colors.red,// warna saaat off(pengeluaran)
                      onChanged: (nilaiBaru) {
                        setState(() {
                          _isPemasukan = nilaiBaru;//mrengubah satatus tombol
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
//tombvol simpan
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _simpanData,
                child: const Text('SIMPAN TRANSAKSI', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}