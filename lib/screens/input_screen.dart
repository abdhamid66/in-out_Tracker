import 'package:flutter/material.dart';
import '../models/transaksi.dart';
import '../services/kategori_service.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/transaksi_provider.dart';
import 'package:out_tracker/theme/app_theme.dart';

class InputScreen extends StatefulWidget {
  final Transaksi? transaksiLama;
  const InputScreen({super.key, this.transaksiLama});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _nominalController = TextEditingController();
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
      
      final currentList = _isPemasukan ? kategoriPemasukan : kategoriPengeluaran;
      if (!currentList.contains(_kategori)) {
        _kategori = currentList.isNotEmpty ? currentList.first : 'Lainnya';
      }
    });
  }

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

    double nominal = 0;
    try {
      nominal = double.parse(_nominalController.text.replaceAll('.', ''));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Format angka tidak valid!'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    if (nominal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nominal harus lebih dari 0!'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

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

      await context.read<TransaksiProvider>().tambahTransaksi(transaksiBaru);

    } else {
      final transaksiUpdate = Transaksi(
        id: widget.transaksiLama!.id,
        judul: _judulController.text,
        nominal: nominal,
        isPemasukan: _isPemasukan,
        tanggal: widget.transaksiLama!.tanggal,
        kategori: _kategori,
      );

      await context.read<TransaksiProvider>().updateTransaksi(transaksiUpdate);
    }

    await Future.delayed(const Duration(milliseconds: 100));

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text(widget.transaksiLama == null ? 'Data Berhasil Disimpan!!' : 'Data Berhasil Diperbarui'),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );

    Navigator.pop(context, true);

  } catch (e) {
    // ignore
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Catat Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryColor,
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
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
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
                  prefixIcon: const Icon(Icons.description,color: AppTheme.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
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
              TextField(
                controller: _nominalController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  CurrencyFormat(),
                ],
                decoration: InputDecoration(
                  labelText: 'Nominal (Rp)',
                  hintText: 'Contoh: 15.000',
                  prefixIcon: const Icon(Icons.attach_money,color: AppTheme.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
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
                          _loadKategori();
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
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
                    offset: const Offset(0, 60),
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
                          prefixIcon: const Icon(Icons.category, color: AppTheme.primaryColor),
                          suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
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
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _simpanData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
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

class CurrencyFormat extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {

    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String angkaMurni = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (angkaMurni.isEmpty) return oldValue;
    
    int value = int.parse(angkaMurni);

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
