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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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

              TextField(
                controller: _judulController,
                decoration: InputDecoration(
                  labelText: 'Keterangan',
                  hintText: 'Contoh: Gaji Bulan Ini, Beli Makan, dll',
                  prefixIcon: Icon(Icons.description,color: Colors.teal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 20),

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

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _simpanData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
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
        