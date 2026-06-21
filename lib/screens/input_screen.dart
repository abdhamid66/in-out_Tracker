import 'package:flutter/material.dart';
import '../models/transaksi.dart';
import '../database/db_helper.dart';
import '../services/kategori_service.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/cloud_sync_service.dart';

class InputScreen extends StatefulWidget {
  final Transaksi? transaksiLama;
  const InputScreen({super.key, this.transaksiLama});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _nominalController = TextEditingController();
  // variabel untuk menyimpan jenis transaksi, defaultnya adalah pemasukan (true)
  bool _isPemasukan = true;
  String _kategori = 'Lainnya';

  List<String> kategoriPemasukan = [];
  List<String> kategoriPengeluaran = [];

  @override
  void initState() {
    super.initState();
    if (widget.transaksiLama != null) {
      _judulController.text = widget.transaksiLama!.judul;

      final formatter = NumberFormat('#,###', 'id_ID');
      _nominalController.text = formatter.format(widget.transaksiLama!.nominal);

      _isPemasukan = widget.transaksiLama!.isPemasukan;
      _kategori = widget.transaksiLama!.kategori;
    }

    _loadKategori();
  }

  void _loadKategori() {
    setState(() {
      kategoriPemasukan = KategoriService.getSemuaPemasukan().map((e) => e.nama).toList();
      kategoriPengeluaran = KategoriService.getSemuaPengeluaran().map((e) => e.nama).toList();
      
      // Jika kategori tidak ditemukan di list yang baru, set ke 'Lainnya' atau yang pertama
      final currentList = _isPemasukan ? kategoriPemasukan : kategoriPengeluaran;
      if (!currentList.contains(_kategori)) {
        _kategori = currentList.isNotEmpty ? currentList.first : 'Lainnya';
      }
    });
  }

  // menbhkan asyncronos karena proses menyimpan ke brngks buth sedikit waktu
void _simpanData() async {
  try {
    FocusScope.of(context).unfocus();

    if (_judulController.text.isEmpty || _nominalController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Keterangan dan Nominal Harus Diisi!', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    double nominal = double.parse(_nominalController.text.replaceAll('.', ''));
    if (nominal > 1000000000) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Maksimal nominal adalah Rp 1.000.000.000!'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    if (widget.transaksiLama == null) {
      final transaksiBaru = Transaksi(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        judul: _judulController.text,
        nominal: nominal,
        isPemasukan: _isPemasukan,
        tanggal: DateTime.now(),
        kategori: _kategori,
      );

      await DBHelper().insertTransaksi(transaksiBaru);

    } else {
      final transaksiUpdate = Transaksi(
        id: widget.transaksiLama!.id,
        judul: _judulController.text,
        nominal: nominal,
        isPemasukan: _isPemasukan,
        tanggal: widget.transaksiLama!.tanggal,
        kategori: _kategori,
      );

      await DBHelper().updateTransaksi(transaksiUpdate);
    }

    // Auto-sync ke Cloud (berjalan di background tanpa menghentikan layar)
    CloudSyncService().backupKeCloud();

    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text(widget.transaksiLama == null ? 'Data Berhasil Disimpan!!' : 'Data Berhasil Diperbarui'),
          ],
        ),
        backgroundColor: const Color(0xFF006D5B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );

    Navigator.pop(context, true);

  } catch (e) {
    print("Error simpan: $e");
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Catat Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF006D5B),
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
                color: const Color(0xFF006D5B).withValues(alpha: 0.1),
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
                  prefixIcon: Icon(Icons.description,color: const Color(0xFF006D5B)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF006D5B), width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 20),
                    // kolom nominaml dnbgn desain terbru dengan ikon uang dan warna yang lebih menarik
              TextField(
                controller: _nominalController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  CurrencyFormat(),
                ],
                decoration: InputDecoration(
                  labelText: 'Nominal (Rp)',
                  hintText: 'Contoh: 15.000',
                  prefixIcon: Icon(Icons.attach_money,color: const Color(0xFF006D5B)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF006D5B), width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
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
                          _loadKategori(); // Refresh kategori
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // KOLOM KATEGORI
              LayoutBuilder(
                builder: (context, constraints) {
                  return PopupMenuButton<String>(
                    initialValue: _kategori,
                    color: Colors.white,
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth,
                      maxWidth: constraints.maxWidth,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    offset: const Offset(0, 60), // Muncul ke bawah
                    onSelected: (nilaiBaru) {
                      setState(() {
                        _kategori = nilaiBaru;
                      });
                    },
                    itemBuilder: (context) {
                      return (_isPemasukan ? kategoriPemasukan : kategoriPengeluaran)
                          .map<PopupMenuEntry<String>>((String nilai) {
                        return PopupMenuItem<String>(
                          value: nilai,
                          child: Text(nilai, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList();
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        readOnly: true,
                        controller: TextEditingController(text: _kategori),
                        decoration: InputDecoration(
                          labelText: 'Kategori',
                          prefixIcon: const Icon(Icons.category, color: Color(0xFF006D5B)),
                          suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFF006D5B), width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                    ),
                  );
                }
              ),
              const SizedBox(height: 30),
              // tombol simpan dengan desain baru yang lebih lebar dab warna yang lebih menarik
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _simpanData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006D5B),
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

// Class khusus untuk mencegat ketikan dan menambahkan titik otomatis
class CurrencyFormat extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {

    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String angkaMurni = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    int value = int.parse(angkaMurni);

    // Batasi input maksimal 1 Miliar
    if (value > 1000000000) {
      return oldValue;
    }

    final formatter = NumberFormat('#,###', 'id_ID');
    String teksBaru = formatter.format(value);

    return newValue.copyWith(
      text: teksBaru,
      selection: TextSelection.collapsed(offset: teksBaru.length),
    );
  }
}
