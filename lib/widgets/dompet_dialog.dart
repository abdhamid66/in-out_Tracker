import 'package:flutter/material.dart';
import '../models/dompet.dart';
import '../database/db_helper.dart';

class DompetDialog extends StatefulWidget {
  final Function() onDompetAdded;

  const DompetDialog({super.key, required this.onDompetAdded});

  @override
  State<DompetDialog> createState() => _DompetDialogState();
}

class _DompetDialogState extends State<DompetDialog> {
  final _namaController = TextEditingController();
  bool _isLoading = false;

  void _simpanDompet() async {
    if (_namaController.text.trim().isEmpty) return;
    
    setState(() => _isLoading = true);
    
    final dompetBaru = Dompet(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nama: _namaController.text.trim(),
      saldo: 0.0,
    );

    await DBHelper().insertDompet(dompetBaru);
    
    widget.onDompetAdded();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: const Text('Tambah Dompet Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      content: TextField(
        controller: _namaController,
        decoration: InputDecoration(
          labelText: 'Nama Dompet',
          hintText: 'Misal: Dana Darurat',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _simpanDompet,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF006D5B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Simpan', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
