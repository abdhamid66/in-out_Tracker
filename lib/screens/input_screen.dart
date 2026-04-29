import 'package:flutter/material.dart';
import '../models/transaksi.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _nominalController = TextEditingController();

  bool _isPemasukan = true;

  void _simpanData() {
    if (_judulController.text.isEmpty || _nominalController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan Nominal Harus Diisi!')),
      );
      return;
    }
    final transaksiBaru = Transaksi(
      id : DateTime.now().toString(),
      judul: _judulController.text,
      nominal: double.parse(_nominalController.text),
      isPemasukan: _isPemasukan,
      tanggal: DateTime.now(),
    );

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

            TextField(
              controller: _nominalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nominal (Rp)',
                border: OutlineInputBorder(),
              )
            ),
            const SizedBox(height: 15),
            
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
              ],
            ),
            const SizedBox(height: 30),

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